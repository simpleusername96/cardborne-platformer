extends StageBase

const WORLD_WIDTH := 2240.0
const WORLD_HEIGHT := 720.0
const PATROL_ROOM_DATA := preload("res://data/rooms/lower_ruins/lr_patrol_gallery.tres")
const CHARGE_ROOM_DATA := preload("res://data/rooms/lower_ruins/lr_charge_lane.tres")
const WALKER_SCENE := preload("res://scenes/enemies/WalkerRuin.tscn")
const CHARGER_SCENE := preload("res://scenes/enemies/ChargerRuin.tscn")

@onready var rooms_root: Node2D = $Rooms

var _room_hosts: Dictionary = {}
var _required_enemies: Array[EnemyBase] = []
var _defeated_enemy_ids: Dictionary = {}
var _exit_portal: ExitPortal


func _ready() -> void:
	if not _assemble_curated_rooms():
		_abort_setup("Production route room assembly failed.")
		return
	if not _spawn_required_enemy(WALKER_SCENE, &"lr_patrol_gallery", &"WalkerA"):
		_abort_setup("Production route Walker spawn failed.")
		return
	if not _spawn_required_enemy(CHARGER_SCENE, &"lr_charge_lane", &"ChargerA"):
		_abort_setup("Production route Charger spawn failed.")
		return
	if not _configure_exit():
		_abort_setup("Production route exit setup failed.")
		return
	super._ready()
	_publish_encounter_state()


func get_room_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for room_id in _room_hosts:
		ids.append(StringName(room_id))
	ids.sort()
	return ids


func get_room_host(room_id: StringName) -> RoomTemplateHost:
	return _room_hosts.get(String(room_id)) as RoomTemplateHost


func get_critical_surface_contract() -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	for room_id in _room_hosts:
		var room := _room_hosts[room_id] as RoomTemplateHost
		for local_surface in room.get_support_surfaces():
			var surface := local_surface.duplicate(true)
			surface["id"] = "%s/%s" % [room_id, local_surface["id"]]
			surface["x"] = float(local_surface["x"]) + room.position.x
			surfaces.append(surface)
	surfaces.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left["x"] < right["x"])
	return surfaces


func get_required_enemies() -> Array[EnemyBase]:
	return _required_enemies.duplicate()


func get_remaining_enemy_count() -> int:
	return maxi(_required_enemies.size() - _defeated_enemy_ids.size(), 0)


func is_exit_enabled() -> bool:
	return _exit_portal != null and _exit_portal.interaction_enabled


func _assemble_curated_rooms() -> bool:
	var room_offset := 0.0
	for data in [PATROL_ROOM_DATA, CHARGE_ROOM_DATA]:
		var room_data := data as RoomTemplateData
		var data_errors := room_data.validate_definition()
		if not data_errors.is_empty():
			for error in data_errors:
				push_error("Room data '%s' is invalid: %s" % [room_data.id, error])
			return false
		var room := room_data.scene.instantiate() as RoomTemplateHost
		if room == null:
			push_error("Room '%s' did not instantiate as RoomTemplateHost." % room_data.id)
			return false
		room.position.x = room_offset
		rooms_root.add_child(room)
		var host_errors := room.configure(room_data)
		if not host_errors.is_empty():
			for error in host_errors:
				push_error("Room host '%s' is invalid: %s" % [room_data.id, error])
			room.queue_free()
			return false
		_room_hosts[String(room_data.id)] = room
		room_offset += room_data.bounds.size.x
	return true


func _spawn_required_enemy(
	enemy_scene: PackedScene,
	room_id: StringName,
	anchor_id: StringName
) -> bool:
	var room := get_room_host(room_id)
	if room == null:
		push_error("Cannot spawn enemy: room '%s' is unavailable." % room_id)
		return false
	var anchor := room.get_anchor(&"Enemy", anchor_id)
	if anchor == null:
		push_error("Cannot spawn enemy: room '%s' has no anchor '%s'." % [room_id, anchor_id])
		return false
	var enemy := enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		push_error("Enemy scene for '%s/%s' is invalid." % [room_id, anchor_id])
		return false
	enemy.position = actors_container.to_local(anchor.global_position)
	actors_container.add_child(enemy)
	if enemy.resolved_spec == null:
		push_error("Enemy scene for '%s/%s' did not resolve its typed specification." % [room_id, anchor_id])
		enemy.queue_free()
		return false
	enemy.defeated.connect(_on_required_enemy_defeated)
	_required_enemies.append(enemy)
	return true


func _configure_exit() -> bool:
	var charge_room := get_room_host(&"lr_charge_lane")
	if charge_room == null:
		return false
	_exit_portal = charge_room.get_exit_portal()
	if _exit_portal == null:
		return false
	_set_exit_enabled(false)
	return true


func _abort_setup(message: String) -> void:
	push_error(message)
	SignalBus.status_message_changed.emit("Stage setup failed")
	for enemy in _required_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_required_enemies.clear()
	_defeated_enemy_ids.clear()
	_exit_portal = null
	for room in _room_hosts.values():
		if is_instance_valid(room):
			room.queue_free()
	_room_hosts.clear()


func _on_required_enemy_defeated(enemy: EnemyBase) -> void:
	var instance_id := enemy.get_instance_id()
	if _defeated_enemy_ids.has(instance_id):
		return
	_defeated_enemy_ids[instance_id] = true
	if get_remaining_enemy_count() == 0:
		_set_exit_enabled(true)
	_publish_encounter_state()


func _set_exit_enabled(enabled: bool) -> void:
	if _exit_portal == null:
		return
	_exit_portal.set_interaction_enabled(enabled)
	var frame := _exit_portal.get_node_or_null("Frame") as Polygon2D
	if frame != null:
		frame.color = Color("d4a33f") if enabled else Color("6b7378")


func _publish_encounter_state() -> void:
	var remaining := get_remaining_enemy_count()
	SignalBus.encounter_state_changed.emit({
		"remaining": remaining,
		"total": _required_enemies.size(),
		"objective": "enter_gate" if remaining == 0 else "defeat_enemies",
		"exit_enabled": is_exit_enabled(),
	})


func _after_player_respawned() -> void:
	if player == null:
		return
	player.set_camera_limits(Rect2(0.0, 0.0, WORLD_WIDTH, WORLD_HEIGHT))
	if player.camera != null:
		player.camera.reset_smoothing()
