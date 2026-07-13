extends SceneTree

const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"
const OUTPUT_DIR := "res://.codex-runtime/uiux/gameplay_hud"
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const SETTLE_FRAMES := 8
const CLEANUP_FRAMES := 4
const CAPTURES: Array[Dictionary] = [
	{"name": "compact_low_health", "size": Vector2i(960, 540), "state": &"warrior"},
	{"name": "compact_field_pickup", "size": Vector2i(960, 540), "state": &"field_pickup"},
	{"name": "compact_boss_archer", "size": Vector2i(960, 540), "state": &"boss_archer"},
	{"name": "desktop_assassin_prompt", "size": Vector2i(1280, 720), "state": &"assassin"},
	{"name": "hd_boss_archer", "size": Vector2i(1920, 1080), "state": &"boss_archer"},
]

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packed := load(HUD_SCENE) as PackedScene
	if packed == null:
		push_error("Gameplay HUD capture scene is unavailable.")
		quit(1)
		return
	var requested_capture := OS.get_environment("GAMEPLAY_HUD_CAPTURE").strip_edges()
	var matched_capture := false
	for capture in CAPTURES:
		if not requested_capture.is_empty() and capture["name"] != requested_capture:
			continue
		matched_capture = true
		await _capture(packed, capture)
	if not requested_capture.is_empty() and not matched_capture:
		push_error("Unknown gameplay HUD capture: %s" % requested_capture)
		_failed = true
	if not _failed:
		print("GAMEPLAY_HUD_CAPTURE_OK target=%s" % (
			requested_capture if not requested_capture.is_empty() else "all"
		))
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
	RenderingServer.force_draw(false)
	await _wait_frames(2)
	RenderingServer.force_draw(false)
	await process_frame
	var image := root.get_texture().get_image()
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture["name"]]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save gameplay HUD capture: %s" % output_path)
		_failed = true
	hud.queue_free()
	backdrop.queue_free()
	await _wait_frames(CLEANUP_FRAMES)
	RenderingServer.force_draw(false)
	await process_frame


func _wait_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame


func _build_backdrop(viewport_size: Vector2) -> Control:
	var root_control := Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := ColorRect.new()
	background.color = Color("11191b")
	background.position = Vector2.ZERO
	background.size = viewport_size
	root_control.add_child(background)
	_add_rect(root_control, Rect2(0.0, viewport_size.y * 0.76, viewport_size.x, viewport_size.y * 0.24), Color("344046"))
	_add_rect(root_control, Rect2(viewport_size.x * 0.10, viewport_size.y * 0.58, viewport_size.x * 0.22, 24.0), Color("52635f"))
	_add_rect(root_control, Rect2(viewport_size.x * 0.42, viewport_size.y * 0.49, viewport_size.x * 0.18, 22.0), Color("52635f"))
	_add_rect(root_control, Rect2(viewport_size.x * 0.71, viewport_size.y * 0.62, viewport_size.x * 0.20, 22.0), Color("52635f"))
	_add_rect(root_control, Rect2(viewport_size.x * 0.48, viewport_size.y * 0.68, 24.0, viewport_size.y * 0.08), Styles.CYAN)
	return root_control


func _add_rect(parent: Control, rect: Rect2, color: Color) -> void:
	var color_rect := ColorRect.new()
	color_rect.position = rect.position
	color_rect.size = rect.size
	color_rect.color = color
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(color_rect)


func _configure_state(hud: Control, state: StringName) -> void:
	var profile_id := &"warrior"
	var health := 2
	var consumable_charges := 0
	var combat_overrides: Dictionary = {}
	match state:
		&"assassin":
			profile_id = &"assassin"
			health = 6
			consumable_charges = 1
			combat_overrides = {"flow_stacks": 3, "flow_time": 2.4, "death_mark_count": 1}
		&"boss_archer":
			profile_id = &"archer"
			health = 5
			consumable_charges = 1
			combat_overrides = {
				"current_attack_id": "archer_power_shot",
				"charge_fraction": 0.84,
				"hunter_mark_count": 2,
			}
		_:
			combat_overrides = {
				"current_attack_id": "warrior_guard_breaker",
				"guarded_time": 1.4,
				"charge_fraction": 0.68,
			}
	var combat := _combat_actions(profile_id)
	combat.merge(combat_overrides, true)
	hud.call("_on_run_state_changed", {
		"profile_id": String(profile_id),
		"level": 5,
		"xp": 158,
		"coins": 25,
		"health": health,
		"max_health": 7,
		"materials": {
			"rusted_scrap": 8,
			"sky_thread": 3,
			"slime_residue": 2,
			"boss_core": 1,
		},
		"consumable_id": "small_potion",
		"consumable_charges": consumable_charges,
	})
	hud.call("_on_combat_state_changed", combat)
	if state == &"assassin":
		hud.call("_on_interaction_prompt_changed", "Open cache", true)
	elif state == &"field_pickup":
		var signal_bus := root.get_node("/root/SignalBus")
		signal_bus.emit_signal("field_pickup_collected", {
			"applied": true,
			"effect_type": "reduce_skill_cooldowns",
			"amount": 1.25,
			"currency_id": "",
			"display_name": "Focus Shard",
			"message": "Focus Shard collected.",
		})
	elif state == &"warrior":
		var receipt: RewardReceiptPresenter = hud.get("reward_receipt")
		receipt.present({
			"applied": true,
			"reward_role": &"cache_reward",
			"grants": {"coin": 7, "xp": 3, "rusted_scrap": 1},
			"equipment_discoveries": [],
		})
	elif state == &"boss_archer":
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


func _combat_actions(profile_id: StringName) -> Dictionary:
	var actions: Array[Dictionary]
	match profile_id:
		&"assassin":
			actions = [
				{"id": "assassin_twin_cut", "label": "Twin Cut", "input_action": "attack", "cooldown": 1.2},
				{"id": "assassin_shadow_lunge", "label": "Shadow Lunge", "input_action": "heavy_attack", "cooldown": 0.0},
				{"id": "assassin_smoke_step", "label": "Smoke Step", "input_action": "skill_1", "cooldown": 0.0},
				{"id": "assassin_kunai_fan", "label": "Kunai Fan", "input_action": "skill_2", "cooldown": 0.0},
				{"id": "assassin_death_mark", "label": "Death Mark", "input_action": "skill_3", "cooldown": 0.0},
			]
		&"archer":
			actions = [
				{"id": "archer_quick_shot", "label": "Quick Shot", "input_action": "attack", "cooldown": 1.2},
				{"id": "archer_power_shot", "label": "Power Shot", "input_action": "heavy_attack", "cooldown": 0.0},
				{"id": "archer_vault_shot", "label": "Vault Shot", "input_action": "skill_1", "cooldown": 0.0},
				{"id": "archer_rain_field", "label": "Rain Field", "input_action": "skill_2", "cooldown": 0.0},
				{"id": "archer_threadline", "label": "Threadline", "input_action": "skill_3", "cooldown": 0.0},
			]
		_:
			actions = [
				{"id": "warrior_cleave", "label": "Cleave", "input_action": "attack", "cooldown": 1.2},
				{"id": "warrior_guard_breaker", "label": "Guard Breaker", "input_action": "heavy_attack", "cooldown": 0.0},
				{"id": "warrior_shield_rush", "label": "Shield Rush", "input_action": "skill_1", "cooldown": 0.0},
				{"id": "warrior_ground_splitter", "label": "Ground Splitter", "input_action": "skill_2", "cooldown": 0.0},
				{"id": "warrior_rally", "label": "Rally", "input_action": "skill_3", "cooldown": 0.0},
			]
	return {
		"phase": "idle",
		"current_attack_id": "",
		"guarded_time": 0.0,
		"guarded_rearm_time": 0.0,
		"charge_fraction": 0.0,
		"actions": actions,
	}
