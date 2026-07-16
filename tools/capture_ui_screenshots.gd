extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/progression"
const HERO_PREPARATION_SCENE := "res://scenes/ui/production/HeroPreparation.tscn"
const FORGE_SCENE := "res://scenes/ui/production/ForgeScreen.tscn"
const CARD_REWARD_SCENE := "res://scenes/ui/production/CardReward.tscn"
const RUN_RESULT_SCENE := "res://scenes/ui/production/RunResult.tscn"
const VIEWPORTS: Array[Dictionary] = [
	{"prefix": "compact", "size": Vector2i(960, 540)},
	{"prefix": "desktop", "size": Vector2i(1280, 720)},
	{"prefix": "hd", "size": Vector2i(1920, 1080)},
]
const STATES: Array[StringName] = [
	&"hero_preparation",
	&"forge",
	&"card_reward",
	&"run_result",
]
const LOCALES: PackedStringArray = ["en", "ko"]
const SETTLE_FRAMES := 10
const CLEANUP_FRAMES := 4

var _failed := false
var _requested := ""
var _profile_state: Node
var _run_state: Node
var _localization: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_requested = OS.get_environment("CAPTURE_NAME").strip_edges()
	if not _requested.is_empty() and not _is_known_capture(_requested):
		push_error("Unknown progression UI capture: %s" % _requested)
		quit(1)
		return
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_localization = root.get_node_or_null("/root/UILocalization")
	if _profile_state == null or _run_state == null or _localization == null:
		push_error("Progression UI capture requires production autoloads.")
		quit(1)
		return
	_initialize_profile_fixture()
	var original_locale := String(_localization.call("get_locale"))
	for locale in LOCALES:
		_localization.call("set_locale", locale)
		for viewport in VIEWPORTS:
			var prefix := String(viewport["prefix"])
			if not _requested.is_empty() and not _requested.begins_with("%s_" % prefix):
				continue
			for state in STATES:
				var legacy_name := "%s_%s" % [prefix, state]
				var capture_name := "%s_%s" % [legacy_name, locale]
				if not _requested.is_empty() and _requested != capture_name:
					if locale != "en" or _requested != legacy_name:
						continue
				await _capture(capture_name, viewport["size"] as Vector2i, state, locale == "en")
	_localization.call("set_locale", original_locale)
	if not _failed:
		print("PROGRESSION_UI_CAPTURE_OK target=%s" % (_requested if not _requested.is_empty() else "all"))
	quit(1 if _failed else 0)


func _initialize_profile_fixture() -> void:
	_profile_state.call(
		"initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres"),
		"",
		false,
		load("res://data/equipment/equipment_progression_catalog.tres")
	)
	for grant in [
		["rusted_scrap", 8],
		["common_timber", 8],
		["sky_thread", 5],
		["steel_fragment", 5],
		["hardwood", 5],
		["reinforced_fabric", 5],
	]:
		_profile_state.call("grant_material_command", String(grant[0]), int(grant[1]))
	_profile_state.call("unlock_blueprint", &"hunting_spear", &"capture:hunting_spear")


func _capture(
	capture_name: String,
	viewport_size: Vector2i,
	state: StringName,
	write_legacy_english: bool
) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	var screen := await _mount_state(state)
	if screen == null:
		_failed = true
		return
	await _wait_frames(SETTLE_FRAMES)
	for _pass in 3:
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		await process_frame
	var image := root.get_texture().get_image()
	var output_path := "%s/%s.png" % [OUTPUT_DIR, capture_name]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save progression UI capture: %s" % output_path)
		_failed = true
	elif write_legacy_english:
		var legacy_name := capture_name.trim_suffix("_en")
		var legacy_path := "%s/%s.png" % [OUTPUT_DIR, legacy_name]
		if image.save_png(legacy_path) != OK:
			push_error("Unable to save legacy progression UI capture: %s" % legacy_path)
			_failed = true
	screen.queue_free()
	await _wait_frames(CLEANUP_FRAMES)


func _mount_state(state: StringName) -> Control:
	var scene_path := ""
	match state:
		&"hero_preparation":
			scene_path = HERO_PREPARATION_SCENE
		&"forge":
			scene_path = FORGE_SCENE
		&"card_reward":
			if not bool(_run_state.call("start_new_run", 0, 73021)):
				push_error("Card reward capture could not start a Traveler run.")
				return null
			var begin_result: Dictionary = _run_state.call("begin_stage_card_reward")
			if not bool(begin_result.get("ok", false)):
				push_error("Card reward capture could not build an offer.")
				return null
			scene_path = CARD_REWARD_SCENE
		&"run_result":
			scene_path = RUN_RESULT_SCENE
		_:
			push_error("Unsupported progression UI state: %s" % state)
			return null
	var packed := load(scene_path) as PackedScene
	var screen := packed.instantiate() as Control if packed != null else null
	if screen == null:
		push_error("Progression UI scene is unavailable: %s" % scene_path)
		return null
	root.add_child(screen)
	await _wait_frames(2)
	if state == &"forge":
		(screen as ForgeScreen).configure(
			_profile_state.call("get_preparation_snapshot"),
			{},
			"TRAVELER FORGE"
		)
		(screen as ForgeScreen).select_slot(&"melee")
		screen.call("_select_model", "hunting_spear")
	elif state == &"run_result":
		screen.call("configure", true, "Traveler", _victory_settlement())
	return screen


func _victory_settlement() -> Dictionary:
	return {
		"victory": true,
		"terminal_reason": "boss_defeated",
		"stage_reached": 3,
		"boss_reached": true,
		"duration_seconds": 845.0,
		"profile": {"hero_loadout": ProfileData.DEFAULT_HERO_LOADOUT.duplicate(true)},
		"run_build": {
			"level": 6,
			"cards": {"dash_wake": 2, "perfect_punish": 1},
		},
		"persistent_material_delta": {
			"rusted_scrap": 5,
			"steel_fragment": 2,
			"boss_core": 1,
		},
	}


func _is_known_capture(capture_name: String) -> bool:
	for viewport in VIEWPORTS:
		for state in STATES:
			var legacy_name := "%s_%s" % [viewport["prefix"], state]
			if capture_name == legacy_name:
				return true
			for locale in LOCALES:
				if capture_name == "%s_%s" % [legacy_name, locale]:
					return true
	return false


func _wait_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame
