class_name PressureVaultEncounter3D
extends Node

const DURATION := 45.0
const LIVING_CAP := 6
const ENEMY_SCENES := {
	"pursuer": preload("res://scenes/enemies/flooded_works/Pursuer3D.tscn"),
	"shooter": preload("res://scenes/enemies/flooded_works/Shooter3D.tscn"),
	"controller": preload("res://scenes/enemies/flooded_works/Controller3D.tscn"),
}
const VENT_SCENE := preload("res://scenes/rooms/components/PressureVent3D.tscn")
const POTION_SCENE := preload("res://scenes/rooms/components/PotionPickup3D.tscn")

var room: FloodedWorksRoom3D
var traveler: Traveler3D
var coordinator := ThreatCoordinator3D.new()
var enemies: Array[EnemyActor3D] = []
var vents: Array[PressureVent3D] = []
var elapsed := 0.0
var spawned_15 := false
var spawned_30 := false
var encounter_completed := false


func configure(next_room: FloodedWorksRoom3D, next_traveler: Traveler3D, snapshot: Dictionary) -> void:
	room = next_room
	traveler = next_traveler
	elapsed = float(snapshot.get("elapsed", 0.0))
	spawned_15 = bool(snapshot.get("spawned_15", false))
	spawned_30 = bool(snapshot.get("spawned_30", false))
	encounter_completed = bool(snapshot.get("completed", false))
	_build_components(snapshot)
	_set_exit_locked(not encounter_completed)
	if not encounter_completed:
		_spawn_group("start")
	else:
		_make_vents_inert()


func _physics_process(delta: float) -> void:
	if encounter_completed:
		return
	elapsed += delta
	if elapsed >= 15.0 and not spawned_15:
		spawned_15 = true
		_spawn_group("wave_15")
	if elapsed >= 30.0 and not spawned_30:
		spawned_30 = true
		_spawn_group("wave_30")
	if elapsed >= DURATION:
		_complete()
	else:
		_set_objective("SURVIVE PRESSURE · %02d" % ceili(DURATION - elapsed))


func get_snapshot() -> Dictionary:
	return {
		"elapsed": elapsed,
		"spawned_15": spawned_15,
		"spawned_30": spawned_30,
		"completed": encounter_completed,
	}


func _build_components(snapshot: Dictionary) -> void:
	for marker_node in room.get_node("Props").get_children():
		var marker := marker_node as Marker3D
		if marker == null:
			continue
		var component_id := String(marker.get_meta("component_id", ""))
		if component_id == "pressure_vent":
			var vent := VENT_SCENE.instantiate() as PressureVent3D
			vent.name = marker.name
			room.add_child(vent)
			vent.global_position = marker.global_position
			vents.append(vent)
		elif component_id == "potion_if_low" and not bool(snapshot.get("pressure_potion", false)):
			var potion := POTION_SCENE.instantiate() as PotionPickup3D
			potion.name = "pressure_potion"
			room.add_child(potion)
			potion.global_position = marker.global_position


func _spawn_group(group_id: String) -> void:
	_prune_enemies()
	for marker_node in room.get_node("Spawns").get_children():
		if enemies.size() >= LIVING_CAP:
			break
		var marker := marker_node as Marker3D
		if marker == null or String(marker.get_meta("spawn_group", "")) != group_id:
			continue
		var role := String(marker.get_meta("enemy_role", ""))
		if not ENEMY_SCENES.has(role):
			continue
		var enemy := (ENEMY_SCENES[role] as PackedScene).instantiate() as EnemyActor3D
		room.add_child(enemy)
		enemy.global_position = marker.global_position
		enemy.configure(traveler, coordinator)
		enemies.append(enemy)


func _prune_enemies() -> void:
	enemies = enemies.filter(func(enemy: EnemyActor3D) -> bool: return is_instance_valid(enemy) and enemy.is_targetable())


func _complete() -> void:
	encounter_completed = true
	elapsed = DURATION
	_make_vents_inert()
	_set_exit_locked(false)
	_set_objective("PRESSURE STABILIZED · EXIT OPEN")
	traveler.action_traced.emit("Reservoir gate open")


func _make_vents_inert() -> void:
	for vent in vents:
		vent.make_inert()


func _set_exit_locked(value: bool) -> void:
	for gate in room.get_gates():
		if gate.target_room_id == &"slime_king_reservoir":
			gate.set_locked(value)


func _set_objective(text: String) -> void:
	var runtime := traveler.get_parent()
	if runtime.has_method("set_objective_text"):
		runtime.set_objective_text(text)
