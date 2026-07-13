extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/reward-choice-f3"
const LEVEL_SCENE := "res://scenes/ui/production/LevelReward.tscn"
const CARD_SCENE := "res://scenes/ui/production/CardReward.tscn"
const TREASURE_SCENE := "res://scenes/ui/production/TreasureChoice.tscn"
const BackdropScene = preload("res://scripts/ui/production/ProductionBackdrop.gd")
const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _failed := false
var _profile_state: Node
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	if _profile_state == null or _run_state == null:
		push_error("Reward choice capture needs production autoloads.")
		quit(1)
		return
	_profile_state.call("initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	for viewport in VIEWPORTS:
		await _capture_level_reward(viewport)
		await _capture_card_reward(viewport)
		await _capture_treasure_choice(viewport)
	quit(1 if _failed else 0)


func _capture_level_reward(viewport: Vector2i) -> void:
	_run_state.call("start_new_run", 0, 73021)
	RewardService.apply(
		RewardTransaction.new(&"capture_reward_choice_level", &"fixture", {"xp": 20}),
		_run_state
	)
	var screen := _mount(LEVEL_SCENE)
	await _save(screen, "level_reward", viewport)


func _capture_card_reward(viewport: Vector2i) -> void:
	_run_state.call("start_new_run", 0, 73021)
	RewardService.apply(
		RewardTransaction.new(&"capture_reward_choice_coins", &"fixture", {"coin": 20}),
		_run_state
	)
	_run_state.call("begin_stage_card_reward")
	var screen := _mount(CARD_SCENE)
	await _save(screen, "card_reward", viewport)


func _capture_treasure_choice(viewport: Vector2i) -> void:
	var backdrop := BackdropScene.new() as Control
	root.add_child(backdrop)
	var screen := _mount(TREASURE_SCENE)
	if screen != null:
		screen.configure(_treasure_snapshot())
	await _save(screen, "treasure_choice", viewport, backdrop)


func _mount(path: String) -> Control:
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Unable to load %s" % path)
		_failed = true
		return null
	var screen := packed.instantiate() as Control
	root.add_child(screen)
	return screen


func _save(
	screen: Control,
	name: String,
	viewport: Vector2i,
	backdrop: Control = null
) -> void:
	root.size = viewport
	DisplayServer.window_set_size(viewport)
	for _frame in 5:
		await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	var texture := root.get_texture()
	var image := texture.get_image() if texture != null else null
	if image == null or image.get_size() != viewport:
		push_error("Invalid %s capture at %dx%d" % [name, viewport.x, viewport.y])
		_failed = true
	else:
		var output := "%s/%s_%dx%d.png" % [OUTPUT_DIR, name, viewport.x, viewport.y]
		if image.save_png(output) != OK:
			push_error("Unable to save %s" % output)
			_failed = true
	if screen != null:
		screen.queue_free()
	if backdrop != null:
		backdrop.queue_free()
	await process_frame


func _treasure_snapshot() -> Dictionary:
	return {
		"request_id": &"optional_cache_capture",
		"title": "Treasure Instinct",
		"instruction": "Choose one reward. The other is discarded.",
		"options": [
			{
				"id": TreasureChoiceService.NORMAL_CHOICE_ID,
				"label": "KEEP CACHE",
				"title": "Resolved Chest Reward",
				"description": "+5 Coins\nDiscover Bell Hammer",
				"kind": &"normal",
			},
			{
				"id": TreasureChoiceService.REPLACEMENT_CHOICE_ID,
				"label": "TAKE EQUIPMENT",
				"title": "Runner Cloak",
				"description": (
					"Adds 16 move speed and reduces dash cooldown by 0.03 seconds.\n"
					+ "Maximum health is reduced by 1 but cannot fall below 3."
				),
				"kind": &"equipment",
			},
		],
	}
