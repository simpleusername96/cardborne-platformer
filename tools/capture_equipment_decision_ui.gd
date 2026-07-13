extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/equipment_decisions"
const CHARACTER_SELECT_SCENE := "res://scenes/ui/production/CharacterSelect.tscn"
const REST_FORGE_SCENE := "res://scenes/ui/production/RestForge.tscn"
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")

const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _failed: bool = false
var _rest_snapshot: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Equipment UI capture requires a rendering driver; run without --headless.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var profile_state := root.get_node_or_null("/root/ProfileState")
	var run_state := root.get_node_or_null("/root/RunState")
	if profile_state == null or run_state == null:
		push_error("Equipment UI capture requires profile and run autoloads.")
		quit(1)
		return
	profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	if not run_state.start_new_run(0, 73021):
		push_error("Equipment UI capture could not start its fixed fixture run.")
		quit(1)
		return
	run_state.coins = 60
	run_state.damage_player(2)
	run_state.begin_rest_forge()
	_rest_snapshot = run_state.get_rest_forge_snapshot()
	var items: Array = _rest_snapshot.get("items", [])
	if not items.is_empty():
		run_state.begin_forge_offer(StringName(items[0].get("id", "")))
		_rest_snapshot = run_state.get_rest_forge_snapshot()

	for viewport_size in VIEWPORTS:
		await _capture_character_select(viewport_size)
		await _capture_rest_forge(viewport_size)
	quit(1 if _failed else 0)


func _capture_character_select(viewport_size: Vector2i) -> void:
	var screen := (load(CHARACTER_SELECT_SCENE) as PackedScene).instantiate() as Control
	await _capture(
		screen,
		"character_select_%dx%d" % [viewport_size.x, viewport_size.y],
		viewport_size,
		true
	)


func _capture_rest_forge(viewport_size: Vector2i) -> void:
	var screen := (load(REST_FORGE_SCENE) as PackedScene).instantiate() as Control
	screen.call("configure", _rest_snapshot)
	await _capture(screen, "rest_forge_%dx%d" % [viewport_size.x, viewport_size.y], viewport_size)


func _capture(
	screen: Control,
	output_name: String,
	viewport_size: Vector2i,
	select_loadout_candidate: bool = false
) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	root.add_child(screen)
	for _frame in 2:
		await process_frame
	if select_loadout_candidate:
		var armor_picker := screen.find_child("Slot_armor", true, false) as OptionButton
		if armor_picker != null and armor_picker.item_count > 1:
			armor_picker.select(1)
			armor_picker.item_selected.emit(1)
	for _frame in 3:
		await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	RenderingServer.force_draw(false)
	var viewport_texture := root.get_texture()
	var image := viewport_texture.get_image() if viewport_texture != null else null
	var output_path := "%s/%s.png" % [OUTPUT_DIR, output_name]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to capture %s." % output_name)
		_failed = true
	screen.queue_free()
	await process_frame
