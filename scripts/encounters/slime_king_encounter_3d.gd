class_name SlimeKingEncounter3D
extends Node

signal result_ready(result_id: StringName)

const BOSS_SCENE := preload("res://scenes/bosses/SlimeKing3D.tscn")

var room: FloodedWorksRoom3D
var traveler: Traveler3D
var boss: SlimeKing3D
var encounter_completed := false
var result_emitted := false


func configure(next_room: FloodedWorksRoom3D, next_traveler: Traveler3D, snapshot: Dictionary) -> void:
	room = next_room
	traveler = next_traveler
	encounter_completed = bool(snapshot.get("completed", false))
	result_emitted = bool(snapshot.get("result_emitted", false))
	traveler.defeated.connect(_on_traveler_defeated)
	if encounter_completed:
		_set_objective("SLIME KING DEFEATED")
	else:
		_spawn_boss()


func get_snapshot() -> Dictionary:
	return {"completed": encounter_completed, "result_emitted": result_emitted}


func _spawn_boss() -> void:
	var marker := room.get_node_or_null("Spawns/slime_king_spawn") as Marker3D
	if marker == null:
		push_error("Reservoir has no slime_king_spawn")
		return
	boss = BOSS_SCENE.instantiate() as SlimeKing3D
	room.add_child(boss)
	boss.global_position = marker.global_position
	boss.configure(traveler)
	boss.defeated.connect(_on_boss_defeated)
	_set_objective("DEFEAT SLIME KING · 600")


func _on_boss_defeated() -> void:
	encounter_completed = true
	_set_objective("SLIME KING DEFEATED · FLOOR CLEAR")
	if not result_emitted:
		result_emitted = true
		result_ready.emit(&"floor1_boss_defeated")
	traveler.action_traced.emit("Floor clear")


func _on_traveler_defeated() -> void:
	if encounter_completed:
		return
	if boss != null and is_instance_valid(boss):
		boss.queue_free()
	for effect in get_tree().get_nodes_in_group(&"combat_effects"):
		if room.is_ancestor_of(effect):
			effect.queue_free()
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		_spawn_boss()


func _set_objective(text: String) -> void:
	var runtime := traveler.get_parent()
	if runtime.has_method("set_objective_text"):
		runtime.set_objective_text(text)
