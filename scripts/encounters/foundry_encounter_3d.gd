class_name FoundryEncounter3D
extends Node

signal completed

const ENEMY_SCENES := {
	"pursuer": preload("res://scenes/enemies/flooded_works/Pursuer3D.tscn"),
	"shooter": preload("res://scenes/enemies/flooded_works/Shooter3D.tscn"),
	"controller": preload("res://scenes/enemies/flooded_works/Controller3D.tscn"),
}

var room: FloodedWorksRoom3D
var traveler: Traveler3D
var coordinator := ThreatCoordinator3D.new()
var active_enemies: Array[EnemyActor3D] = []
var current_wave := 0
var encounter_completed := false


func configure(next_room: FloodedWorksRoom3D, next_traveler: Traveler3D, snapshot: Dictionary) -> void:
	room = next_room
	traveler = next_traveler
	encounter_completed = bool(snapshot.get("completed", false))
	if not encounter_completed:
		call_deferred("_spawn_wave", "wave_1")
	_set_objective("FOUNDRY · WAVES OPTIONAL · EXIT OPEN" if not encounter_completed else "FOUNDRY CLEAR · EXIT OPEN")


func get_snapshot() -> Dictionary:
	return {
		"completed": encounter_completed,
	}


func _spawn_wave(wave_id: String) -> void:
	current_wave += 1
	for marker_node in room.get_node("Spawns").get_children():
		var marker := marker_node as Marker3D
		if marker == null or String(marker.get_meta("spawn_group", "")) != wave_id:
			continue
		var role := String(marker.get_meta("enemy_role", ""))
		if not ENEMY_SCENES.has(role):
			push_error("Unknown Foundry enemy role: %s" % role)
			continue
		var enemy := (ENEMY_SCENES[role] as PackedScene).instantiate() as EnemyActor3D
		room.add_child(enemy)
		enemy.global_position = marker.global_position
		enemy.configure(traveler, coordinator)
		enemy.defeated.connect(_on_enemy_defeated)
		active_enemies.append(enemy)
	traveler.action_traced.emit("Foundry wave %d" % current_wave)


func _on_enemy_defeated(enemy: EnemyActor3D) -> void:
	active_enemies.erase(enemy)
	if not active_enemies.is_empty():
		return
	if current_wave == 1:
		await get_tree().create_timer(0.8).timeout
		if is_inside_tree():
			_spawn_wave("wave_2")
	else:
		encounter_completed = true
		traveler.action_traced.emit("Foundry clear")
		_set_objective("FOUNDRY CLEAR · EXIT OPEN")
		completed.emit()


func _set_objective(text: String) -> void:
	var runtime := traveler.get_parent()
	if runtime.has_method("set_objective_text"):
		runtime.set_objective_text(text)
