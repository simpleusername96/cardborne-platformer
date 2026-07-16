extends SceneTree

const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"
const OUTPUT_DIR := "res://.codex-runtime/uiux/gameplay_hud"
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const SETTLE_FRAMES := 8
const CLEANUP_FRAMES := 4
const CAPTURES: Array[Dictionary] = [
	{"name": "compact_low_health", "size": Vector2i(960, 540), "state": &"low_health"},
	{"name": "compact_minimap_initial", "size": Vector2i(960, 540), "state": &"minimap_initial"},
	{"name": "compact_field_pickup", "size": Vector2i(960, 540), "state": &"field_pickup"},
	{"name": "compact_boss", "size": Vector2i(960, 540), "state": &"boss"},
	{"name": "desktop_interaction", "size": Vector2i(1280, 720), "state": &"interaction"},
	{"name": "desktop_minimap_explored", "size": Vector2i(1280, 720), "state": &"minimap_explored"},
	{"name": "desktop_guard_start", "size": Vector2i(1280, 720), "state": &"guard_start"},
	{"name": "desktop_guard_block", "size": Vector2i(1280, 720), "state": &"normal_block"},
	{"name": "desktop_precise_guard", "size": Vector2i(1280, 720), "state": &"precise_block"},
	{"name": "desktop_guard_break", "size": Vector2i(1280, 720), "state": &"guard_break"},
	{"name": "desktop_guard_recovery", "size": Vector2i(1280, 720), "state": &"guard_recovery"},
	{"name": "hd_boss", "size": Vector2i(1920, 1080), "state": &"boss"},
]

var _failed := false
var _localization: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packed := load(HUD_SCENE) as PackedScene
	if packed == null:
		push_error("Gameplay HUD capture scene is unavailable.")
		quit(1)
		return
	_localization = root.get_node_or_null("/root/UILocalization")
	if _localization == null:
		push_error("Gameplay HUD capture needs UILocalization.")
		quit(1)
		return
	var requested := OS.get_environment("GAMEPLAY_HUD_CAPTURE").strip_edges()
	var matched := false
	for locale in ["en", "ko"]:
		_localization.call("set_locale", locale)
		for capture in CAPTURES:
			if not requested.is_empty() and capture["name"] != requested:
				continue
			matched = true
			await _capture(packed, capture, locale)
	if not requested.is_empty() and not matched:
		push_error("Unknown gameplay HUD capture: %s" % requested)
		_failed = true
	if not _failed:
		print("GAMEPLAY_HUD_CAPTURE_OK target=%s" % (requested if not requested.is_empty() else "all"))
	quit(1 if _failed else 0)


func _capture(packed: PackedScene, capture: Dictionary, locale: String) -> void:
	var viewport_size := capture["size"] as Vector2i
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.gui_disable_input = true
	root.add_child(viewport)
	var backdrop := _build_backdrop(Vector2(viewport_size))
	viewport.add_child(backdrop)
	var hud := packed.instantiate() as Control
	viewport.add_child(hud)
	await _wait_frames(2)
	_configure_state(hud, StringName(capture["state"]))
	await _wait_frames(SETTLE_FRAMES)
	for _pass in 3:
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		await process_frame
	var image := viewport.get_texture().get_image()
	var output_path := "%s/%s_%s.png" % [OUTPUT_DIR, capture["name"], locale]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save gameplay HUD capture: %s" % output_path)
		_failed = true
	viewport.queue_free()
	await _wait_frames(CLEANUP_FRAMES)


func _build_backdrop(viewport_size: Vector2) -> Control:
	var backdrop := Control.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = viewport_size
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_add_rect(backdrop, Rect2(Vector2.ZERO, viewport_size), Color("11191b"))
	_add_rect(
		backdrop,
		Rect2(0.0, viewport_size.y * 0.76, viewport_size.x, viewport_size.y * 0.24),
		Color("344046")
	)
	_add_rect(backdrop, Rect2(viewport_size.x * 0.10, viewport_size.y * 0.58, viewport_size.x * 0.22, 24.0), Color("52635f"))
	_add_rect(backdrop, Rect2(viewport_size.x * 0.42, viewport_size.y * 0.49, viewport_size.x * 0.18, 22.0), Color("52635f"))
	_add_rect(backdrop, Rect2(viewport_size.x * 0.71, viewport_size.y * 0.62, viewport_size.x * 0.20, 22.0), Color("52635f"))
	_add_rect(backdrop, Rect2(viewport_size.x * 0.48, viewport_size.y * 0.68, 24.0, viewport_size.y * 0.08), Styles.CYAN)
	return backdrop


func _add_rect(parent: Control, rect: Rect2, color: Color) -> void:
	var color_rect := ColorRect.new()
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)


func _configure_state(hud: Control, state: StringName) -> void:
	var health := 6
	var potion_charges := 1
	if state == &"low_health":
		health = 2
		potion_charges = 0
	hud.call("_on_run_state_changed", _run_snapshot(health, potion_charges))
	hud.call("_on_combat_state_changed", _combat_snapshot(state))
	hud.call("_on_stage_started", "ruin_approach", "Ruin Approach")
	var explored := state == &"minimap_explored"
	hud.call("_on_stage_map_changed", _map_snapshot(explored))
	hud.call("_on_encounter_state_changed", {
		"objective": &"terminal_objective" if explored else &"navigate_to_exit",
		"exit_ready": false,
		"terminal_policy": &"terminal_encounter",
		"terminal_remaining": 1 if explored else 2,
	})
	match state:
		&"interaction":
			hud.call("_on_interaction_prompt_changed", "Open cache", true)
		&"field_pickup":
			root.get_node("/root/SignalBus").emit_signal("field_pickup_collected", {
				"applied": true,
				"effect_type": "grant_ranged_supply",
				"amount": 4.0,
				"supply_id": "arrows",
				"display_name": "Arrow Bundle",
				"message": "Arrow Bundle collected.",
			})
		&"low_health":
			var receipt: RewardReceiptPresenter = hud.get("reward_receipt")
			receipt.present({
				"applied": true,
				"reward_role": &"cache_reward",
				"grants": {"coin": 7, "xp": 3, "rusted_scrap": 1},
				"equipment_discoveries": [],
			})
		&"boss":
			hud.call("_on_stage_started", "slime_court", "Slime Court")
			hud.call("_on_boss_snapshot", {
				"actor_state": &"active",
				"health": 64,
				"max_health": 80,
				"phase": 2,
				"stagger_capacity": 100,
				"stagger_meter": 35,
				"pattern": {"pattern_id": &"jump_slam", "state": &"startup"},
			})


func _map_snapshot(explored: bool) -> Dictionary:
	return {
		"stage_id": "ruin_approach",
		"stage_index": 0,
		"content_signature": "capture-fixture",
		"revision": 2 if explored else 1,
		"world_bounds": Rect2(0.0, 0.0, 1600.0, 900.0),
		"current_room_id": "exit" if explored else "start",
		"player_position": Vector2(1460.0, 220.0) if explored else Vector2(120.0, 700.0),
		"has_player_position": true,
		"rooms": [
			{"id": "start", "bounds": Rect2(0.0, 540.0, 360.0, 360.0), "required_route": true, "visited": true, "current": not explored, "state": "visited" if explored else "current"},
			{"id": "rise", "bounds": Rect2(360.0, 360.0, 360.0, 360.0), "required_route": true, "visited": explored, "current": false, "state": "visited" if explored else "unvisited"},
			{"id": "cache", "bounds": Rect2(720.0, 540.0, 300.0, 360.0), "required_route": false, "visited": explored, "current": false, "state": "visited" if explored else "unvisited"},
			{"id": "exit", "bounds": Rect2(1180.0, 0.0, 420.0, 360.0), "required_route": true, "visited": explored, "current": explored, "state": "current" if explored else "unvisited"},
		],
		"connections": [
			{"id": "critical_0", "from_room_id": "start", "to_room_id": "rise", "route_role": "critical"},
			{"id": "critical_1", "from_room_id": "rise", "to_room_id": "exit", "route_role": "critical"},
			{"id": "optional", "from_room_id": "rise", "to_room_id": "cache", "route_role": "optional"},
			{"id": "return", "from_room_id": "cache", "to_room_id": "exit", "route_role": "return"},
		],
		"markers": [
			{"id": "start:start", "type": "start", "room_id": "start", "position": Vector2(120.0, 700.0), "state": "known", "visible": true},
			{"id": "exit:exit", "type": "exit", "room_id": "exit", "position": Vector2(1480.0, 220.0), "state": "locked", "visible": true},
			{"id": "reward:cache", "type": "reward", "room_id": "cache", "position": Vector2(850.0, 700.0), "state": "claimed" if explored else "available", "visible": explored},
			{"id": "checkpoint:exit", "type": "checkpoint", "room_id": "exit", "position": Vector2(1300.0, 260.0), "state": "active" if explored else "inactive", "visible": explored},
			{"id": "gate:loop", "type": "gate", "room_id": "exit", "position": Vector2(1380.0, 220.0), "state": "open" if explored else "closed", "visible": explored},
		],
	}


func _run_snapshot(health: int, potion_charges: int) -> Dictionary:
	return {
		"profile_id": "traveler",
		"profile_display_name": "Traveler",
		"level": 5,
		"xp": 158,
		"coins": 25,
		"health": health,
		"max_health": 7,
		"materials": {"rusted_scrap": 8, "sky_thread": 3, "slime_residue": 2},
		"consumable_id": "small_potion",
		"consumable_charges": potion_charges,
	}


func _combat_snapshot(state: StringName = &"") -> Dictionary:
	var snapshot := {
		"phase": "idle",
		"shared_hero_mode": true,
		"committed_intent": {"mode": "ranged", "tool_id": "hunting_bow"},
		"guard": {"stability_fraction": 0.65, "guarding": false},
		"spirit": {
			"spirit_stone_id": "ember_spirit_stone",
			"trigger": "direct_attack_sequence",
			"direct_attack_count": 3,
		},
		"loadout": {
			"melee_display_name": "Traveler Sword",
			"melee_condition": 72,
			"melee_maximum_condition": 100,
			"ranged_display_name": "Hunting Bow",
			"ranged_resource_id": "arrows",
			"ranged_resource_count": 7,
			"ranged_resource_maximum": 20,
			"shield_display_name": "Round Shield",
			"shield_condition": 84,
			"shield_maximum_condition": 100,
			"armor_display_name": "Traveler Coat",
			"armor_health_bonus": 0,
			"spirit_stone_display_name": "Ember Spirit Stone",
		},
	}
	var guard: Dictionary = snapshot["guard"]
	var feedback := {
		"event_id": 1,
		"active": true,
		"remaining": 0.8,
		"stability_cost": 0,
		"condition_cost": 0,
		"damage": 0,
	}
	match state:
		&"guard_start":
			guard.merge({"phase": &"startup", "guarding": true}, true)
			feedback.merge({
				"outcome": &"guard_start",
				"reason": &"guard_start",
				"label": "GUARD RAISED",
			}, true)
		&"normal_block":
			guard.merge({"phase": &"active", "guarding": true, "stability_fraction": 0.45}, true)
			feedback.merge({
				"outcome": &"normal_block",
				"reason": &"blocked",
				"label": "BLOCKED",
				"stability_cost": 20,
				"condition_cost": 1,
			}, true)
		&"precise_block":
			guard.merge({"phase": &"active", "guarding": true}, true)
			feedback.merge({
				"outcome": &"precise_block",
				"reason": &"precise_block",
				"label": "PRECISE GUARD",
			}, true)
		&"guard_break":
			guard.merge({"phase": &"recovery", "guarding": false, "stability_fraction": 0.0}, true)
			feedback.merge({
				"outcome": &"guard_break",
				"reason": &"guard_broken",
				"label": "GUARD BROKEN",
				"stability_cost": 100,
				"condition_cost": 1,
				"damage": 2,
			}, true)
		&"guard_recovery":
			guard.merge({"phase": &"recovery", "guarding": false}, true)
			feedback.merge({
				"outcome": &"guard_recovery",
				"reason": &"guard_recovery",
				"label": "GUARD RECOVERY",
			}, true)
		_:
			feedback.clear()
	if not feedback.is_empty():
		snapshot["defense_feedback"] = feedback
	return snapshot


func _wait_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame
