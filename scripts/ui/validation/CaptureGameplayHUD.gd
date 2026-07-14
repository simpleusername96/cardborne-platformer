extends SceneTree

const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"
const OUTPUT_DIR := "res://.codex-runtime/uiux/gameplay_hud"
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const SETTLE_FRAMES := 8
const CLEANUP_FRAMES := 4
const CAPTURES: Array[Dictionary] = [
	{"name": "compact_low_health", "size": Vector2i(960, 540), "state": &"low_health"},
	{"name": "compact_field_pickup", "size": Vector2i(960, 540), "state": &"field_pickup"},
	{"name": "compact_boss", "size": Vector2i(960, 540), "state": &"boss"},
	{"name": "desktop_interaction", "size": Vector2i(1280, 720), "state": &"interaction"},
	{"name": "hd_boss", "size": Vector2i(1920, 1080), "state": &"boss"},
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packed := load(HUD_SCENE) as PackedScene
	if packed == null:
		push_error("Gameplay HUD capture scene is unavailable.")
		quit(1)
		return
	var requested := OS.get_environment("GAMEPLAY_HUD_CAPTURE").strip_edges()
	var matched := false
	for capture in CAPTURES:
		if not requested.is_empty() and capture["name"] != requested:
			continue
		matched = true
		await _capture(packed, capture)
	if not requested.is_empty() and not matched:
		push_error("Unknown gameplay HUD capture: %s" % requested)
		_failed = true
	if not _failed:
		print("GAMEPLAY_HUD_CAPTURE_OK target=%s" % (requested if not requested.is_empty() else "all"))
	quit(1 if _failed else 0)


func _capture(packed: PackedScene, capture: Dictionary) -> void:
	var viewport_size := capture["size"] as Vector2i
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	var backdrop := _build_backdrop(Vector2(viewport_size))
	root.add_child(backdrop)
	var hud := packed.instantiate() as Control
	root.add_child(hud)
	await _wait_frames(2)
	_configure_state(hud, StringName(capture["state"]))
	await _wait_frames(SETTLE_FRAMES)
	for _pass in 3:
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		await process_frame
	var image := root.get_texture().get_image()
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save gameplay HUD capture: %s" % output_path)
		_failed = true
	hud.queue_free()
	backdrop.queue_free()
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
	hud.call("_on_combat_state_changed", _combat_snapshot())
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


func _combat_snapshot() -> Dictionary:
	return {
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


func _wait_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame
