extends StageBase

const ENEMY_CATALOG: EnemyCatalog = preload("res://data/enemies/enemy_catalog.tres")
const ENEMY_SCENES: EnemySceneCatalog = preload("res://data/enemies/enemy_scene_catalog.tres")
const HAZARD_CATALOG: HazardCatalog = preload("res://data/hazards/hazard_catalog.tres")
const TERRAIN_STYLER := preload("res://scripts/visuals/TerrainPresentationStyler.gd")
const FIXED_LAYOUT_VERSION := 3
# Changing this seed intentionally versions every approved stage-content signature.
const FIXED_LAYOUT_SEED_V1 := 0x43415244
const STAGE_CONFIGS: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"profile_path": "res://data/generation/ruin_approach_profile.tres",
		"room_catalog_path": "res://data/generation/lower_ruins_room_catalog.tres",
		"clear_reward_id": &"stage_clear_ruin_approach",
	},
	{
		"id": &"flooded_works",
		"profile_path": "res://data/generation/flooded_works_profile.tres",
		"room_catalog_path": "res://data/generation/flooded_works_room_catalog.tres",
		"clear_reward_id": &"stage_clear_flooded_works",
	},
	{
		"id": &"broken_sanctum",
		"profile_path": "res://data/generation/broken_sanctum_profile.tres",
		"room_catalog_path": "res://data/generation/broken_sanctum_room_catalog.tres",
		"clear_reward_id": &"stage_clear_broken_sanctum",
	},
]

@onready var rooms_root: Node2D = $Rooms
@onready var backdrop: ProductionStageBackdrop = $Backdrop

var _setup_succeeded: bool = false
var _room_catalog: RoomCatalog
var _stage_profile: StageProfile
var _clear_reward_id: StringName
var _stage_plan: StagePlan
var _generation_report: GenerationReport
var _assembly_result: StageAssemblyResult
var _runtime_content: StageRuntimeContentResult
var _room_hosts: Dictionary = {}
var _all_enemies: Array[EnemyBase] = []
var _required_enemies: Array[EnemyBase] = []
var _defeated_required_ids: Dictionary = {}
var _settled_enemy_ids: Dictionary = {}
var _required_encounter_room_ids: Dictionary = {}
var _required_room_encounter_ids: Dictionary = {}
var _started_required_rooms: Dictionary = {}
var _cleared_required_rooms: Dictionary = {}
var _exit_portal: ExitPortal
var _world_bounds := Rect2()
var _terrain_presentation: Dictionary = {}


func _ready() -> void:
	if not _setup_approved_stage():
		_abort_setup("Production stage setup failed.")
		return
	_setup_succeeded = true
	super._ready()
	if player == null:
		_abort_setup("Production stage player spawn failed.")
		return
	_publish_encounter_state()


func _physics_process(_delta: float) -> void:
	if _setup_succeeded and player != null:
		_publish_required_room_start_if_entered()


func is_setup_complete() -> bool:
	return _setup_succeeded


func get_stage_plan() -> StagePlan:
	return _stage_plan


func get_generation_report() -> GenerationReport:
	return _generation_report


func get_clear_reward_table_id() -> StringName:
	return _clear_reward_id


func get_world_bounds() -> Rect2:
	return _world_bounds


func get_terrain_presentation_snapshot() -> Dictionary:
	return _terrain_presentation.duplicate(true)


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
	if _stage_plan == null:
		return surfaces
	for planned_room in _stage_plan.get_rooms():
		if not planned_room.required_route:
			continue
		var room := get_room_host(planned_room.id)
		if room == null:
			continue
		for local_surface in room.get_support_surfaces():
			if not bool(local_surface.get("critical", false)):
				continue
			var surface := local_surface.duplicate(true)
			surface["id"] = "%s/%s" % [planned_room.id, local_surface["id"]]
			surface["room_id"] = String(planned_room.id)
			surface["x"] = float(local_surface["x"]) + room.position.x
			surface["top"] = float(local_surface["top"]) + room.position.y
			surfaces.append(surface)
	surfaces.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return float(left["x"]) < float(right["x"])
	)
	return surfaces


func get_required_enemies() -> Array[EnemyBase]:
	return _required_enemies.duplicate()


func get_all_enemies() -> Array[EnemyBase]:
	return _all_enemies.duplicate()


func get_spawned_hazards() -> Array[Node2D]:
	return _runtime_content.hazards.duplicate() if _runtime_content != null else []


func get_spawned_rewards() -> Array[StageRewardInteractable]:
	return _runtime_content.rewards.duplicate() if _runtime_content != null else []


func get_remaining_enemy_count() -> int:
	return maxi(_required_enemies.size() - _defeated_required_ids.size(), 0)


func is_exit_enabled() -> bool:
	return _exit_portal != null and _exit_portal.interaction_enabled


func _setup_approved_stage() -> bool:
	if not _load_stage_configuration():
		return false
	var scene_errors := ENEMY_SCENES.validate_catalog(ENEMY_CATALOG)
	if not scene_errors.is_empty():
		_publish_errors("Enemy scene catalog", scene_errors)
		return false
	var generation := StageGenerationService.new().generate_curated(
		_room_catalog,
		_stage_profile,
		ENEMY_CATALOG,
		HAZARD_CATALOG,
		RunState.reward_catalog,
		FIXED_LAYOUT_SEED_V1,
		FIXED_LAYOUT_VERSION,
		RunState.current_stage_index,
		RunState.get_required_route_limits()
	)
	_generation_report = generation.report
	if not generation.success or generation.plan == null:
		if _generation_report != null:
			_publish_errors("Stage generation", _report_messages(_generation_report))
		return false
	_stage_plan = generation.plan
	_index_required_room_encounters()
	_assembly_result = StageAssembler.assemble(_stage_plan, _room_catalog, rooms_root)
	if not _assembly_result.success:
		_publish_errors("Stage assembly", _assembly_result.get_errors())
		return false
	_room_hosts = _assembly_result.get_room_hosts()
	_world_bounds = _assembly_result.world_bounds
	var geometry_errors := StageGeometryValidator.validate_assembly(
		_stage_plan,
		_room_catalog,
		_assembly_result,
		RunState.get_required_route_limits()
	)
	if not geometry_errors.is_empty():
		_publish_errors("Stage geometry", geometry_errors)
		return false
	if not _configure_stage_endpoints():
		return false
	_runtime_content = StageRuntimeContentSpawner.spawn(
		_stage_plan,
		_room_hosts,
		actors_container,
		ENEMY_CATALOG,
		ENEMY_SCENES,
		HAZARD_CATALOG,
		_world_bounds,
		_stage_profile.terminal_room_role
	)
	if not _runtime_content.success:
		_publish_errors("Runtime content", _runtime_content.errors)
		return false
	_all_enemies = _runtime_content.all_enemies.duplicate()
	_required_enemies = _runtime_content.required_enemies.duplicate()
	for enemy in _all_enemies:
		enemy.defeated.connect(_on_enemy_defeated)
	_set_exit_enabled(_required_enemies.is_empty())
	_terrain_presentation = TERRAIN_STYLER.apply(_room_hosts, StringName(stage_id))
	backdrop.configure(_world_bounds, StringName(stage_id))
	return true


func _load_stage_configuration() -> bool:
	if RunState.current_stage_index < 0 or RunState.current_stage_index >= STAGE_CONFIGS.size():
		push_error("No production stage configuration exists for index %d." % RunState.current_stage_index)
		return false
	var config: Dictionary = STAGE_CONFIGS[RunState.current_stage_index]
	var loaded_profile := load(String(config["profile_path"]))
	var loaded_rooms := load(String(config["room_catalog_path"]))
	if not loaded_profile is StageProfile or not loaded_rooms is RoomCatalog:
		push_error("Production stage '%s' cannot load its profile or room catalog." % config["id"])
		return false
	_stage_profile = loaded_profile
	_room_catalog = loaded_rooms
	_clear_reward_id = StringName(config["clear_reward_id"])
	stage_id = String(config["id"])
	stage_display_name = _stage_profile.display_name
	return true


func _configure_stage_endpoints() -> bool:
	var start_host: RoomTemplateHost
	var terminal_host: RoomTemplateHost
	for room in _stage_plan.get_rooms():
		if room.role == &"start":
			start_host = get_room_host(room.id)
		elif room.role == _stage_profile.terminal_room_role:
			terminal_host = get_room_host(room.id)
	if start_host == null or terminal_host == null:
		push_error("Production stage has no start or terminal room.")
		return false
	var spawn_anchor := start_host.get_anchor(&"Objective", &"PlayerSpawn")
	if spawn_anchor == null:
		push_error("Production stage start room has no player spawn.")
		return false
	player_spawn.global_position = spawn_anchor.global_position
	_exit_portal = terminal_host.get_exit_portal()
	if _exit_portal == null:
		push_error("Production stage terminal room has no exit portal.")
		return false
	return true


func _abort_setup(message: String) -> void:
	_setup_succeeded = false
	remove_from_group("active_stage")
	push_error(message)
	SignalBus.status_message_changed.emit("Stage setup failed")
	_clear_children(actors_container)
	_clear_children(rooms_root)
	_room_hosts.clear()
	_all_enemies.clear()
	_required_enemies.clear()
	_defeated_required_ids.clear()
	_settled_enemy_ids.clear()
	_required_encounter_room_ids.clear()
	_required_room_encounter_ids.clear()
	_started_required_rooms.clear()
	_cleared_required_rooms.clear()
	_exit_portal = null


func _on_enemy_defeated(enemy: EnemyBase) -> void:
	var encounter_id := String(enemy.get_meta("planned_encounter_id", ""))
	if encounter_id.is_empty() or _settled_enemy_ids.has(encounter_id):
		return
	_settled_enemy_ids[encounter_id] = true
	_settle_enemy_reward(enemy, StringName(encounter_id))
	if _required_encounter_room_ids.has(encounter_id):
		_defeated_required_ids[encounter_id] = true
		_publish_required_room_clear_if_complete(
			StringName(_required_encounter_room_ids[encounter_id])
		)
		if get_remaining_enemy_count() == 0:
			_set_exit_enabled(true)
	_publish_encounter_state()


func _settle_enemy_reward(enemy: EnemyBase, encounter_id: StringName) -> void:
	if enemy.resolved_spec == null or RunState.reward_catalog == null:
		push_error("Enemy '%s' cannot settle a reward without typed data." % enemy.name)
		return
	var table := RunState.reward_catalog.get_table(enemy.resolved_spec.drop_source_id)
	if table == null:
		push_error(
			"Enemy '%s' references missing reward table '%s'."
			% [enemy.name, enemy.resolved_spec.drop_source_id]
		)
		return
	var transaction_id := StringName("%d:%d:%s" % [
		RunState.run_seed,
		RunState.current_stage_index,
		encounter_id,
	])
	var transaction := RewardService.resolve_with_context(
		table,
		transaction_id,
		RunState.run_seed,
		RunState.get_reward_resolution_context()
	)
	var result := RewardService.apply(transaction, RunState)
	if not result.applied and not result.duplicate:
		push_error("Enemy reward '%s' failed: %s" % [transaction_id, result.message])


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


func _index_required_room_encounters() -> void:
	_required_encounter_room_ids.clear()
	_required_room_encounter_ids.clear()
	_started_required_rooms.clear()
	_cleared_required_rooms.clear()
	if _stage_plan == null:
		return
	for encounter in _stage_plan.get_encounters():
		var room := _stage_plan.get_room(encounter.room_id)
		if room == null or not room.required_route:
			continue
		var room_key := String(encounter.room_id)
		var encounter_key := String(encounter.id)
		var room_encounters: Dictionary = _required_room_encounter_ids.get(room_key, {})
		room_encounters[encounter_key] = true
		_required_room_encounter_ids[room_key] = room_encounters
		_required_encounter_room_ids[encounter_key] = room_key


func _publish_required_room_start_if_entered() -> void:
	var room_ids := _required_room_encounter_ids.keys()
	room_ids.sort()
	for room_value in room_ids:
		var room_key := String(room_value)
		if _started_required_rooms.has(room_key) or _cleared_required_rooms.has(room_key):
			continue
		var host := get_room_host(StringName(room_key))
		if host == null or host.template_data == null:
			continue
		var room_bounds := Rect2(
			host.global_position + host.template_data.bounds.position,
			host.template_data.bounds.size
		)
		if not room_bounds.has_point(player.global_position):
			continue
		_started_required_rooms[room_key] = true
		SignalBus.required_room_encounter_started.emit(
			_required_room_event_context(StringName(room_key))
		)


func _publish_required_room_clear_if_complete(room_id: StringName) -> void:
	var room_key := String(room_id)
	if room_key.is_empty() or _cleared_required_rooms.has(room_key):
		return
	var encounter_ids := _required_room_encounter_ids.get(room_key, {}) as Dictionary
	if encounter_ids.is_empty():
		return
	for encounter_id in encounter_ids:
		if not _defeated_required_ids.has(String(encounter_id)):
			return
	_cleared_required_rooms[room_key] = true
	SignalBus.required_room_encounter_cleared.emit(
		_required_room_event_context(room_id)
	)


func _required_room_event_context(room_id: StringName) -> Dictionary:
	var encounter_ids: Array[String] = []
	for encounter_id in (_required_room_encounter_ids.get(String(room_id), {}) as Dictionary):
		encounter_ids.append(String(encounter_id))
	encounter_ids.sort()
	return {
		"stage_id": StringName(stage_id),
		"stage_index": RunState.current_stage_index,
		"room_id": room_id,
		"required_encounter_ids": encounter_ids,
		"required_encounter_count": encounter_ids.size(),
	}


func _after_player_respawned() -> void:
	if player == null or _world_bounds.size == Vector2.ZERO:
		return
	player.set_camera_limits(_world_bounds)
	if player.camera != null:
		player.camera.reset_smoothing()


func _clear_children(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


func _publish_errors(label: String, errors: PackedStringArray) -> void:
	for error in errors:
		push_error("%s: %s" % [label, error])


func _report_messages(report: GenerationReport) -> PackedStringArray:
	var messages := PackedStringArray()
	for failure in report.get_failures():
		messages.append(str(failure.get("message", "Generation failed.")))
	return messages
