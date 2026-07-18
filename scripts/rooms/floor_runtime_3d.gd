class_name FloorRuntime3D
extends Node3D

const ROOM_SCENES := {
	&"movement_check": preload("res://scenes/rooms/flooded_works/generated/MovementCheck3D.tscn"),
	&"foundry_approach": preload("res://scenes/rooms/flooded_works/generated/FoundryApproach3D.tscn"),
	&"pump_gallery": preload("res://scenes/rooms/flooded_works/generated/PumpGallery3D.tscn"),
	&"pressure_vault": preload("res://scenes/rooms/flooded_works/generated/PressureVault3D.tscn"),
	&"slime_king_reservoir": preload("res://scenes/rooms/flooded_works/generated/SlimeKingReservoir3D.tscn"),
}

@export var initial_room_id: StringName = &"movement_check"

var current_room: FloodedWorksRoom3D
var current_room_id: StringName
var transitioning := false
var room_snapshots: Dictionary = {}

@onready var room_host: Node3D = $RoomHost
@onready var traveler: Traveler3D = $Traveler
@onready var camera_rig: IsometricCameraRig3D = $CameraRig
@onready var fade: ColorRect = $HUD/Root/RoomFade


func _ready() -> void:
	fade.modulate.a = 1.0
	_load_room(initial_room_id, &"")
	await get_tree().process_frame
	await _fade_to(0.0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_training") and not transitioning:
		traveler.reset_training()


func _load_room(room_id: StringName, entry_socket_id: StringName) -> void:
	if not ROOM_SCENES.has(room_id):
		push_error("Unknown Floor 1 room: %s" % room_id)
		return
	if current_room != null:
		_snapshot_room()
		current_room.queue_free()
		current_room = null
	current_room = (ROOM_SCENES[room_id] as PackedScene).instantiate() as FloodedWorksRoom3D
	room_host.add_child(current_room)
	current_room_id = room_id
	_restore_room_snapshot()
	for gate in current_room.get_gates():
		gate.transition_requested.connect(_on_transition_requested)
	_attach_room_content()
	if entry_socket_id.is_empty():
		var spawn := current_room.get_node_or_null("Spawns/player_start") as Marker3D
		if spawn != null:
			traveler.global_position = spawn.global_position
	else:
		var entry := current_room.get_entry_marker(entry_socket_id)
		if entry != null:
			traveler.global_position = entry.global_position
	traveler.spawn_position = traveler.global_position
	traveler.velocity = Vector3.ZERO
	camera_rig.set_room_bounds(current_room.camera_bounds)
	camera_rig.snap_to_target()


func _on_transition_requested(target_room_id: StringName, target_socket_id: StringName) -> void:
	if transitioning or not ROOM_SCENES.has(target_room_id):
		return
	transitioning = true
	traveler.set_physics_process(false)
	traveler.velocity = Vector3.ZERO
	await _fade_to(1.0)
	_cleanup_transient_combat_nodes()
	_load_room(target_room_id, target_socket_id)
	await get_tree().process_frame
	await _fade_to(0.0)
	traveler.set_physics_process(true)
	transitioning = false


func _snapshot_room() -> void:
	var snapshot := {"visited": true}
	for child in current_room.get_children():
		if child.has_method("get_snapshot"):
			snapshot.merge(child.call("get_snapshot"), true)
	room_snapshots[current_room_id] = snapshot


func _restore_room_snapshot() -> void:
	if not room_snapshots.has(current_room_id):
		room_snapshots[current_room_id] = {"visited": true}


func _attach_room_content() -> void:
	if current_room_id == &"foundry_approach":
		var encounter := FoundryEncounter3D.new()
		encounter.name = "FoundryEncounter3D"
		current_room.add_child(encounter)
		encounter.configure(current_room, traveler, room_snapshots.get(current_room_id, {}))
	elif current_room_id == &"pump_gallery":
		var encounter := PumpGalleryEncounter3D.new()
		encounter.name = "PumpGalleryEncounter3D"
		current_room.add_child(encounter)
		encounter.configure(current_room, traveler, room_snapshots.get(current_room_id, {}))
	elif current_room_id == &"pressure_vault":
		var encounter := PressureVaultEncounter3D.new()
		encounter.name = "PressureVaultEncounter3D"
		current_room.add_child(encounter)
		encounter.configure(current_room, traveler, room_snapshots.get(current_room_id, {}))
	elif current_room_id == &"slime_king_reservoir":
		var encounter := SlimeKingEncounter3D.new()
		encounter.name = "SlimeKingEncounter3D"
		current_room.add_child(encounter)
		encounter.configure(current_room, traveler, room_snapshots.get(current_room_id, {}))
	else:
		set_objective_text("EXPLORE THE FLOODED WORKS")


func set_objective_text(text: String) -> void:
	$HUD/Root/Objective.text = text


func _cleanup_transient_combat_nodes() -> void:
	for group_name: StringName in [&"combat_projectiles", &"combat_effects", &"traveler_dash_afterimages"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if is_ancestor_of(node):
				node.queue_free()


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade, "modulate:a", alpha, 0.18)
	await tween.finished
