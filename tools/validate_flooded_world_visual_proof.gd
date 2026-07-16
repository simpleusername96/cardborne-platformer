extends SceneTree

const STAGE_PATH := "res://scenes/stages/production/ProductionStageHost.tscn"
const ROOM_PATH := "res://scenes/rooms/flooded_works/FwPoisonTiming.tscn"
const VENT_PATH := "res://scenes/hazards/TimedPoisonVent.tscn"
const CRUMBLE_PATH := "res://scenes/hazards/CrumblingPlatform.tscn"
const VISUAL_CATALOG: StageVisualCatalog = preload(
	"res://data/presentation/stage_visual_catalog.tres"
)
const FLOODED_SKIN := preload(
	"res://scripts/presentation/world/FloodedWorksRoomSkin.gd"
)
const MAXIMUM_VIEWPORT := Vector2i(1920, 1080)
const FLOODED_BOUNDS := Rect2(0.0, -760.0, 8960.0, 1600.0)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_panel_contract()
	_validate_room_skin_geometry()
	await _validate_component_state_overlays()
	await _validate_production_composition()
	_finish()


func _validate_panel_contract() -> void:
	var definition := VISUAL_CATALOG.get_definition(&"flooded_works")
	_expect(definition != null, "Flooded visual definition should resolve.")
	if definition == null:
		return
	_expect(definition.panel_size == Vector2i(2048, 1536), "Proof panel must remain 4:3.")
	_expect(definition.panel_overlap == 192, "Proof overlap must remain 192 px.")
	_expect(definition.overscan == Vector2i(192, 128), "Proof overscan should match contract.")
	_expect(definition.scroll_scale == Vector2(0.18, 0.18), "Proof scroll scale should be 0.18.")
	_expect(definition.panel_paths.size() == 2, "Only two Flooded proof panels should be authored.")
	_expect(
		definition.minimum_panel_count(FLOODED_BOUNDS, MAXIMUM_VIEWPORT) == 2,
		"Measured Flooded bounds should require exactly two panels."
	)
	var required := definition.required_coverage(FLOODED_BOUNDS, MAXIMUM_VIEWPORT)
	var composite := definition.composite_size(2)
	_expect(composite.x >= ceili(required.x), "Composite width should cover the camera sweep.")
	_expect(composite.y >= ceili(required.y), "Composite height should cover vertical sweep.")

	var first := _load_source_image(definition.panel_paths[0])
	var second := _load_source_image(definition.panel_paths[1])
	_expect(first != null and second != null, "Both normalized source panels should load.")
	if first == null or second == null:
		return
	_expect(first.get_size() == definition.panel_size, "Panel 1 size should match the contract.")
	_expect(second.get_size() == definition.panel_size, "Panel 2 size should match the contract.")
	var entry_delta := _column_mean_delta(first, 2048 - 192, second, 0)
	var exit_delta := _column_mean_delta(second, 191, second, 192)
	_expect(entry_delta <= 0.000001, "Sequential panel entry should be pixel-continuous.")
	_expect(exit_delta <= 0.02, "Overlap blend should not create an internal hard seam.")


func _validate_room_skin_geometry() -> void:
	var packed := load(ROOM_PATH) as PackedScene
	var baseline := packed.instantiate() as Node2D if packed != null else null
	var skinned := packed.instantiate() as Node2D if packed != null else null
	_expect(baseline != null and skinned != null, "Representative room should instantiate twice.")
	if baseline == null or skinned == null:
		return
	var before := _geometry_snapshot(baseline)
	var result := FLOODED_SKIN.apply({"fw_poison_timing": skinned})
	var after := _geometry_snapshot(skinned)
	_expect(before == after, "Room skin must not change collision or support geometry.")
	_expect(result["applied"], "Representative room skin should cover every authored surface.")
	_expect(result["surface_count"] == 6, "Five types should cover six surface instances.")
	_expect(result["unique_signature_count"] == 5, "Representative kit must derive five types.")
	_expect(not result["geometry_mutated"], "Skin report should declare presentation-only work.")
	baseline.free()
	skinned.free()


func _validate_component_state_overlays() -> void:
	var vent := (load(VENT_PATH) as PackedScene).instantiate() as TimedPoisonVent
	root.add_child(vent)
	await process_frame
	var vent_base := vent.get_visual_snapshot()
	_expect(vent_base["raster_visual_ready"], "Poison vent should use raster base/overlays.")
	_expect(vent_base["warning_overlay_visible"], "Warning state should show warning overlay.")
	vent.advance_time(vent.warning_time + 0.01)
	var vent_active := vent.get_visual_snapshot()
	_expect(vent_active["active_overlay_visible"], "Active state should show active overlay.")
	_expect(not vent_active["warning_overlay_visible"], "Active state should hide warning overlay.")
	_assert_same_base(vent_base, vent_active, "poison active")
	vent.advance_time(vent.active_time + 0.01)
	var vent_cooldown := vent.get_visual_snapshot()
	_expect(vent_cooldown["cooldown_overlay_visible"], "Cooldown should show cooldown overlay.")
	_assert_same_base(vent_base, vent_cooldown, "poison cooldown")
	vent.queue_free()
	await process_frame

	var crumble := (load(CRUMBLE_PATH) as PackedScene).instantiate() as CrumblingPlatform
	root.add_child(crumble)
	await process_frame
	var stable := crumble.get_visual_snapshot()
	_expect(stable["raster_visual_ready"], "Crumble platform should use raster base/overlays.")
	_expect(crumble.trigger_collapse(), "Stable platform should enter warning.")
	var warning := crumble.get_visual_snapshot()
	_expect(warning["warning_overlay_visible"], "Crumble warning should be an overlay.")
	_assert_same_base(stable, warning, "crumble warning")
	crumble.advance_time(crumble.warning_time + 0.01)
	await process_frame
	var disabled := crumble.get_visual_snapshot()
	_expect(disabled["disabled_overlay_visible"], "Disabled state should show debris overlay.")
	_assert_same_base(stable, disabled, "crumble disabled")
	crumble.advance_time(crumble.disabled_time + 0.01)
	var respawning := crumble.get_visual_snapshot()
	_expect(respawning["respawning_overlay_visible"], "Respawn should show respawn overlay.")
	_assert_same_base(stable, respawning, "crumble respawning")
	crumble.advance_time(crumble.respawn_time + 0.01)
	var restored := crumble.get_visual_snapshot()
	_expect(restored["state"] == &"stable", "Crumble cycle should return to stable.")
	_assert_same_base(stable, restored, "crumble restored")
	crumble.queue_free()
	await process_frame


func _validate_production_composition() -> void:
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	_expect(profile_state != null and run_state != null, "Production state autoloads should exist.")
	if profile_state == null or run_state == null:
		return
	profile_state.initialize_for_tests(
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	_expect(run_state.start_new_run(0, 2207), "Visual proof fixture should start a run.")
	run_state.current_stage_index = 1
	var stage := (load(STAGE_PATH) as PackedScene).instantiate()
	root.add_child(stage)
	await process_frame
	await physics_frame
	_expect(stage.is_setup_complete(), "Flooded production composition should initialize.")
	if stage.is_setup_complete():
		var room_proof: Dictionary = stage.get_world_visual_proof_snapshot()
		var backdrop: Dictionary = stage.get_stage_visual_snapshot()
		_expect(room_proof.get("applied", false), "Real stage should skin the representative room.")
		_expect(room_proof.get("unique_signature_count", 0) == 5, "Real room should use five types.")
		_expect(backdrop.get("loaded_panel_count", 0) == 2, "Real stage should load two panels only.")
		_expect(
			not backdrop.get("procedural_fallback_active", true),
			"Real Flooded stage should render normalized panels."
		)
		_expect(
			backdrop.get("estimated_loaded_rgba_bytes", 0) == 25165824,
			"Current-stage proof memory should measure 24 MiB RGBA."
		)
		var live_room: Node = stage.get_room_host(&"fw_poison_timing")
		var fresh: Node = (load(ROOM_PATH) as PackedScene).instantiate()
		_expect(
			_geometry_snapshot(live_room) == _geometry_snapshot(fresh),
			"Production room gameplay facts should match the unskinned source."
		)
		fresh.free()
	stage.queue_free()
	await process_frame


func _assert_same_base(first: Dictionary, later: Dictionary, label: String) -> void:
	_expect(first["base_instance_id"] == later["base_instance_id"], "%s should reuse one base node." % label)
	_expect(first["base_texture_path"] == later["base_texture_path"], "%s should reuse one base texture." % label)
	_expect(first["base_local_position"] == later["base_local_position"], "%s should retain base pivot." % label)
	_expect(later["visual_root_position"] == Vector2.ZERO, "%s should retain root pivot." % label)


func _geometry_snapshot(room: Node) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if room == null:
		return rows
	for candidate in room.find_children("*", "StaticBody2D", true, false):
		var body := candidate as StaticBody2D
		var path := String(room.get_path_to(body))
		if not path.begins_with("Terrain/") and not path.begins_with("OneWay/"):
			continue
		for child in body.find_children("*", "CollisionShape2D", true, false):
			var collision := child as CollisionShape2D
			if not collision.shape is RectangleShape2D:
				continue
			rows.append({
				"path": path,
				"body_position": body.position,
				"collision_layer": body.collision_layer,
				"shape_position": collision.position,
				"shape_size": (collision.shape as RectangleShape2D).size,
				"one_way": collision.one_way_collision,
				"support_top": body.get_meta("support_top", null),
				"support_width": body.get_meta("support_width", null),
			})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["path"]) < String(b["path"])
	)
	return rows


func _load_source_image(path: String) -> Image:
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


func _column_mean_delta(left: Image, left_x: int, right: Image, right_x: int) -> float:
	var total := 0.0
	for y in mini(left.get_height(), right.get_height()):
		var a := left.get_pixel(left_x, y)
		var b := right.get_pixel(right_x, y)
		total += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
	return total / float(mini(left.get_height(), right.get_height()) * 3)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_WORLD_VISUAL_PROOF_OK panels=2 terrain_types=5 state_bases=2 memory_mib=24")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
