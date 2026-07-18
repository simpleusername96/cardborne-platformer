class_name PumpGalleryEncounter3D
extends Node

const ENEMY_SCENES := {
	"pursuer": preload("res://scenes/enemies/flooded_works/Pursuer3D.tscn"),
	"shooter": preload("res://scenes/enemies/flooded_works/Shooter3D.tscn"),
	"controller": preload("res://scenes/enemies/flooded_works/Controller3D.tscn"),
}
const CRATE_SCENE := preload("res://scenes/rooms/components/WaterloggedCrate3D.tscn")
const PUMP_SCENE := preload("res://scenes/rooms/components/PumpStation3D.tscn")
const POTION_SCENE := preload("res://scenes/rooms/components/PotionPickup3D.tscn")

var room: FloodedWorksRoom3D
var traveler: Traveler3D
var coordinator := ThreatCoordinator3D.new()
var pumps: Array[PumpStation3D] = []
var enemies: Array[EnemyActor3D] = []
var state: Dictionary = {}


func configure(next_room: FloodedWorksRoom3D, next_traveler: Traveler3D, snapshot: Dictionary) -> void:
	room = next_room
	traveler = next_traveler
	state = snapshot.duplicate(true)
	_build_props()
	_spawn_enemies()
	_update_objective()


func get_snapshot() -> Dictionary:
	for pump in pumps:
		state[pump.name] = pump.is_active
	for child in room.get_children():
		if child is WaterloggedCrate3D:
			state[child.name] = child.is_broken
		elif child is PotionPickup3D:
			state[child.name] = child.was_collected
	return state.duplicate(true)


func _build_props() -> void:
	for marker_node in room.get_node("Props").get_children():
		var marker := marker_node as Marker3D
		if marker == null:
			continue
		var component_id := String(marker.get_meta("component_id", ""))
		if component_id == "pump_station":
			var pump := PUMP_SCENE.instantiate() as PumpStation3D
			pump.name = marker.name
			room.add_child(pump)
			pump.global_position = marker.global_position
			pump.restore_active(bool(state.get(pump.name, false)))
			pump.activated.connect(_on_pump_activated)
			pumps.append(pump)
		elif component_id == "waterlogged_crate":
			var crate := CRATE_SCENE.instantiate() as WaterloggedCrate3D
			crate.name = marker.name
			crate.drop_id = StringName(marker.get_meta("drop_id", ""))
			room.add_child(crate)
			crate.global_position = marker.global_position
			crate.restore_broken(bool(state.get(crate.name, false)))
			crate.broken.connect(_on_crate_broken)


func _spawn_enemies() -> void:
	if bool(state.get("completed", false)):
		return
	for marker_node in room.get_node("Spawns").get_children():
		var marker := marker_node as Marker3D
		if marker == null:
			continue
		var role := String(marker.get_meta("enemy_role", ""))
		if not ENEMY_SCENES.has(role):
			continue
		var enemy := (ENEMY_SCENES[role] as PackedScene).instantiate() as EnemyActor3D
		room.add_child(enemy)
		enemy.global_position = marker.global_position
		enemy.configure(traveler, coordinator)
		enemies.append(enemy)


func _on_pump_activated(_pump: PumpStation3D) -> void:
	_update_objective()


func _on_crate_broken(crate: WaterloggedCrate3D) -> void:
	state[crate.name] = true
	if crate.drop_id != &"potion_if_low" or bool(state.get("%s_drop" % crate.name, false)):
		return
	state["%s_drop" % crate.name] = true
	var pickup := POTION_SCENE.instantiate() as PotionPickup3D
	pickup.name = "%s_potion" % crate.name
	room.add_child(pickup)
	pickup.global_position = crate.global_position
	pickup.restore_collected(bool(state.get(pickup.name, false)))


func _update_objective() -> void:
	var completed := pumps.size() == 2 and pumps.all(func(pump: PumpStation3D) -> bool: return pump.is_active)
	state["completed"] = completed
	for gate in room.get_gates():
		if gate.target_room_id == &"pressure_vault":
			gate.set_locked(not completed)
	if completed:
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.suspend_combat()
		traveler.action_traced.emit("Flow restored · exit open")
		_set_objective("FLOW RESTORED · EXIT OPEN")
	else:
		var active_count := pumps.filter(func(pump: PumpStation3D) -> bool: return pump.is_active).size()
		_set_objective("RESTORE PUMPS · %d / 2" % active_count)


func _set_objective(text: String) -> void:
	var runtime := traveler.get_parent()
	if runtime.has_method("set_objective_text"):
		runtime.set_objective_text(text)
