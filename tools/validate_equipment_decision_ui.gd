extends SceneTree

const CHARACTER_SELECT_SCENE := "res://scenes/ui/production/CharacterSelect.tscn"
const REST_FORGE_SCENE := "res://scenes/ui/production/RestForge.tscn"
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")

const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _failures: Array[String] = []
var _profile_state: Node
var _run_state: Node
var _rest_snapshot: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_profile_state != null and _run_state != null, "equipment UI fixture needs autoloads")
	if _profile_state == null or _run_state == null:
		_finish()
		return
	_profile_state.initialize_for_tests(EQUIPMENT_CATALOG, MASTERY_CATALOG)
	_expect(_run_state.start_new_run(0, 73021), "equipment UI fixture run should start")
	_run_state.coins = 60
	_run_state.damage_player(2)
	_run_state.begin_rest_forge()
	_rest_snapshot = _run_state.get_rest_forge_snapshot()
	var items: Array = _rest_snapshot.get("items", [])
	_expect(not items.is_empty(), "rest fixture should expose equipped items")
	if not items.is_empty():
		_expect(
			bool(_run_state.begin_forge_offer(StringName(items[0].get("id", ""))).get("ok", false)),
			"rest fixture should open an affix offer"
		)
		_rest_snapshot = _run_state.get_rest_forge_snapshot()

	for viewport_size in VIEWPORTS:
		await _validate_character_select(viewport_size)
		await _validate_rest_forge(viewport_size)
	await _validate_live_resize()
	await _validate_invalid_forge_state()
	_finish()


func _validate_character_select(viewport_size: Vector2i) -> void:
	_set_viewport(viewport_size)
	var screen := (load(CHARACTER_SELECT_SCENE) as PackedScene).instantiate() as Control
	root.add_child(screen)
	await _settle()
	var detail := screen.find_child("SelectedEquipmentDetail", true, false) as Control
	_expect(detail != null, "%s character select should show equipment detail" % viewport_size)
	if detail != null:
		_expect(_label_text(detail, "TitleLabel") != "", "selected equipment should have a name")
		_expect(_label_text(detail, "DescriptionLabel") != "", "selected equipment should show mechanics")
		_expect(_label_text(detail, "TradeoffLabel").begins_with("LIMIT"), "selected equipment should show its limit")
		_expect(_label_text(detail, "StateLabel") == "EQUIPPED", "default item should visibly be equipped")
		_expect(_mechanics_text(detail) != "", "selected equipment should paint its mechanics summary")

	var picker := screen.find_child("Slot_armor", true, false) as OptionButton
	if picker != null and picker.item_count > 1:
		picker.select(1)
		picker.item_selected.emit(1)
		await process_frame
		_expect(
			_collect_text(detail).contains("->") or _collect_text(detail).contains("behavior"),
			"candidate equipment should show exact deltas or an honest behavior-only state"
		)
		picker.grab_focus()
		screen.call("_commit_slot_action", "armor")
		screen.call("show_profile_command_result", {"ok": true, "message": "Loadout updated."})
		await _settle()
		var refreshed_picker := screen.find_child("Slot_armor", true, false) as OptionButton
		_expect(
			refreshed_picker != null and root.gui_get_focus_owner() == refreshed_picker,
			"equipment refresh should restore focus to the edited slot"
		)
	var stat_grid := screen.find_child("StatGrid", true, false) as GridContainer
	_expect(stat_grid != null, "character select should keep effective stats visible")
	if stat_grid != null:
		_validate_jump_presentation(stat_grid)
	_validate_focus(screen, "character select %s" % viewport_size)
	_validate_bounds(screen, viewport_size, "character select")
	_validate_no_raw_ids(screen, "character select")
	screen.queue_free()
	await process_frame


func _validate_rest_forge(viewport_size: Vector2i) -> void:
	_set_viewport(viewport_size)
	var screen := (load(REST_FORGE_SCENE) as PackedScene).instantiate() as Control
	screen.call("configure", _rest_snapshot)
	root.add_child(screen)
	await _settle()
	var detail := screen.find_child("ForgeEquipmentDetail", true, false) as Control
	_expect(detail != null, "%s forge should show the selected item's baseline" % viewport_size)
	if detail != null:
		_expect(_label_text(detail, "StateLabel") == "EQUIPPED", "forge item should show equipped state")
		_expect(_label_text(detail, "DescriptionLabel") != "", "forge item should show base mechanics")
		_expect(_label_text(detail, "TradeoffLabel").begins_with("LIMIT"), "forge item should show tradeoff")
		_expect(
			_label_text(detail, "AffixLabel").contains("THIS RUN"),
			"current affix should state its run-only scope"
		)
		_expect(_mechanics_text(detail) != "", "forge item should paint its base mechanics summary")
	var choices := screen.find_children("Affix_*", "ForgeAffixChoice", true, false)
	_expect(choices.size() == 3, "forge should show exactly three affix choices")
	for choice_value in choices:
		var choice := choice_value as Control
		_expect(_label_text(choice, "ScopeLabel") == "THIS RUN", "affix choice should show run-only scope")
		_expect(_label_text(choice, "CostLabel").contains("COINS"), "affix choice should show final coins")
		_expect(_label_text(choice, "DeltaLabel") != "", "affix choice should show delta or behavior text")
	_validate_focus(screen, "rest forge %s" % viewport_size)
	_validate_bounds(screen, viewport_size, "rest forge")
	_validate_no_raw_ids(screen, "rest forge")
	screen.queue_free()
	await process_frame


func _validate_live_resize() -> void:
	_set_viewport(Vector2i(1280, 720))
	var character_select := (load(CHARACTER_SELECT_SCENE) as PackedScene).instantiate() as Control
	root.add_child(character_select)
	await _settle()
	await _assert_live_resize(character_select, "character select")
	character_select.queue_free()
	await process_frame

	_set_viewport(Vector2i(1280, 720))
	var rest_forge := (load(REST_FORGE_SCENE) as PackedScene).instantiate() as Control
	rest_forge.call("configure", _rest_snapshot)
	root.add_child(rest_forge)
	await _settle()
	await _assert_live_resize(rest_forge, "rest forge")
	rest_forge.queue_free()
	await process_frame


func _assert_live_resize(screen: Control, context: String) -> void:
	_set_viewport(Vector2i(960, 540))
	await _settle()
	_expect(bool(screen.get("_compact_layout")), "%s should enter compact mode after live resize" % context)
	_validate_bounds(screen, Vector2i(960, 540), "%s live compact" % context)
	_validate_focus(screen, "%s live compact" % context)

	_set_viewport(Vector2i(1920, 1080))
	await _settle()
	_expect(not bool(screen.get("_compact_layout")), "%s should leave compact mode after live resize" % context)
	_validate_bounds(screen, Vector2i(1920, 1080), "%s live regular" % context)
	_validate_focus(screen, "%s live regular" % context)


func _validate_invalid_forge_state() -> void:
	_set_viewport(Vector2i(960, 540))
	var invalid_snapshot := _rest_snapshot.duplicate(true)
	var offer: Array = invalid_snapshot.get("forge_offer", [])
	if offer.is_empty():
		_expect(false, "invalid forge fixture needs one offer")
		return
	var invalid_row: Dictionary = offer[0].duplicate(true)
	invalid_row["validation_errors"] = [{"code": "fixture_invalid"}]
	offer[0] = invalid_row
	invalid_snapshot["forge_offer"] = offer
	var screen := (load(REST_FORGE_SCENE) as PackedScene).instantiate() as Control
	screen.call("configure", invalid_snapshot)
	root.add_child(screen)
	await _settle()
	var invalid_choice := screen.find_child("Affix_%s" % invalid_row.get("id", ""), true, false) as BaseButton
	_expect(invalid_choice != null and invalid_choice.disabled, "invalid affix should be visibly disabled")
	if invalid_choice != null:
		_expect(
			_label_text(invalid_choice, "CostLabel").contains("INVALID BUILD"),
			"invalid affix should name its invalid state"
		)
		_expect(
			_label_text(invalid_choice, "CostLabel").contains("COINS STAY"),
			"invalid affix should show the truthful unchanged balance"
		)
	screen.queue_free()
	await process_frame


func _validate_jump_presentation(grid: GridContainer) -> void:
	var children := grid.get_children()
	for index in range(0, children.size() - 1, 2):
		var name_label := children[index] as Label
		var value_label := children[index + 1] as Label
		if name_label != null and name_label.text == "Jump strength":
			_expect(
				value_label != null and not value_label.text.begins_with("-"),
				"jump strength should not expose engine coordinates"
			)
			return
	_expect(false, "effective stats should include player-readable jump strength")


func _validate_focus(screen: Control, context: String) -> void:
	var enabled_count := 0
	for node in screen.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button != null and button.visible and not button.disabled:
			enabled_count += 1
			_expect(
				button.focus_mode != Control.FOCUS_NONE,
				"%s control %s should accept focus" % [context, button.name]
			)
	_expect(enabled_count > 0, "%s should expose at least one enabled action" % context)
	var focus_owner := root.gui_get_focus_owner()
	_expect(
		focus_owner != null and screen.is_ancestor_of(focus_owner),
		"%s should establish keyboard/gamepad focus" % context
	)


func _validate_bounds(screen: Control, viewport_size: Vector2i, context: String) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	for node in screen.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		_expect(
			viewport_rect.grow(1.0).encloses(rect),
			"%s %s exceeds %s: %s" % [context, control.name, viewport_size, rect]
		)


func _validate_no_raw_ids(screen: Control, context: String) -> void:
	var visible_text := _collect_text(screen).to_lower()
	for raw_id in ["runner_cloak", "patched_mail", "forge_force", "forge_tempo"]:
		_expect(not visible_text.contains(raw_id), "%s should not expose raw ID %s" % [context, raw_id])


func _collect_text(parent: Node) -> String:
	var lines: Array[String] = []
	if parent is Label:
		lines.append((parent as Label).text)
	elif parent is BaseButton:
		lines.append((parent as BaseButton).text)
	for child in parent.get_children():
		lines.append(_collect_text(child))
	return "\n".join(lines)


func _label_text(parent: Node, node_name: String) -> String:
	var label := parent.find_child(node_name, true, false) as Label
	return label.text if label != null else ""


func _mechanics_text(parent: Node) -> String:
	var grid := parent.find_child("MechanicsGrid", true, false) as GridContainer
	if grid == null:
		return ""
	return _collect_text(grid).strip_edges()


func _set_viewport(viewport_size: Vector2i) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)


func _settle() -> void:
	for _frame in 5:
		await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("EQUIPMENT_DECISION_UI_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
