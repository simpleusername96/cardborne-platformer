extends SceneTree

const HERO_PREPARATION_SCENE := "res://scenes/ui/production/HeroPreparation.tscn"
const EQUIPMENT_CATALOG := preload("res://data/equipment/equipment_catalog.tres")
const MASTERY_CATALOG := preload("res://data/mastery/mastery_catalog.tres")
const PROGRESSION_CATALOG := preload("res://data/equipment/equipment_progression_catalog.tres")
const CAPTURE_DIR := "user://hero_preparation_ui_validation"
const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]
const REQUIRED_SLOT_BUTTONS: Array[String] = [
	"MeleeButton",
	"RangedButton",
	"ShieldButton",
	"ArmorButton",
	"SpiritStoneButton",
	"ConsumableButton",
]
const FORBIDDEN_VISIBLE_TEXT: Array[String] = [
	"warrior",
	"archer",
	"assassin",
	"mastery",
	"skill_1",
	"skill 1",
	"spirit art",
	"resonance",
	"traveler_sword",
	"hunting_bow",
	"round_shield",
	"rusted_scrap",
	"debug",
]

var _failures: Array[String] = []
var _profile_state: Node
var _localization: Node
var _last_equipment_signal: Dictionary = {}
var _last_stone_signal: StringName
var _top_events: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_localization = root.get_node_or_null("/root/UILocalization")
	_expect(_profile_state != null, "Hero Preparation validation needs ProfileState")
	_expect(_localization != null, "Hero Preparation validation needs UILocalization")
	if _profile_state == null or _localization == null:
		_finish()
		return
	_localization.call("set_locale", "en")
	_profile_state.initialize_for_tests(
		EQUIPMENT_CATALOG,
		MASTERY_CATALOG,
		"",
		false,
		PROGRESSION_CATALOG
	)

	var baseline: Dictionary = _profile_state.get_preparation_snapshot()
	for viewport_size in VIEWPORTS:
		await _validate_viewport(viewport_size)
	_expect(
		baseline == _profile_state.get_preparation_snapshot(),
		"rendering and selection must not mutate the preparation snapshot"
	)
	await _validate_action_and_signal_contracts()
	await _validate_korean_rendering()
	_localization.call("set_locale", "en")
	_finish()


func _validate_viewport(viewport_size: Vector2i) -> void:
	_set_viewport(viewport_size)
	var screen := (load(HERO_PREPARATION_SCENE) as PackedScene).instantiate() as Control
	_expect(screen != null, "%s should instantiate Hero Preparation" % viewport_size)
	if screen == null:
		return
	root.add_child(screen)
	await _settle()
	_validate_backdrop(screen, viewport_size)

	var visible_text := _collect_text(screen)
	var compact := viewport_size.x <= 1050 or viewport_size.y <= 600
	_expect(visible_text.contains("Traveler"), "%s should show the single Traveler" % viewport_size)
	_expect(visible_text.contains("STAGE 1"), "%s should show the next stage" % viewport_size)
	_expect(visible_text.contains("Spirit Stone"), "%s should show the Spirit Stone slot" % viewport_size)
	if compact:
		_expect(not visible_text.contains("MATERIALS"), "%s should hide secondary balances" % viewport_size)
	else:
		_expect(visible_text.contains("Healing Potion"), "%s should summarize the consumable" % viewport_size)
		_expect(visible_text.contains("MATERIALS"), "%s should show material balances" % viewport_size)
		_expect(
			visible_text.contains("Arrows") and visible_text.contains("Cartridges"),
			"%s should show supply balances" % viewport_size
		)
	_expect(visible_text.contains("Saved locally"), "%s should show persistence status" % viewport_size)

	for button_name in REQUIRED_SLOT_BUTTONS:
		_expect(
			screen.find_child(button_name, true, false) is Button,
			"%s should expose %s" % [viewport_size, button_name]
		)
	var detail := screen.find_child("HeroPreparationDetail", true, false) as Control
	_expect(detail != null, "%s should show equipment detail" % viewport_size)
	if detail != null:
		_expect(_label_text(detail, "TitleLabel") == "Traveler Sword", "default detail should show Traveler Sword")
		_expect(not _label_text(detail, "BehaviorLabel").is_empty(), "equipment behavior should be visible")
		_expect(not _label_text(detail, "WeaknessLabel").is_empty(), "equipment weakness should be visible")
		_expect(_label_text(detail, "StateLabel").contains("Grade 1"), "equipment grade should be visible")
		_expect(_label_text(detail, "ConditionLabel").contains("Condition"), "equipment condition should be visible")
		var action := detail.find_child("PrimaryActionButton", true, false) as Button
		_expect(action != null and action.text == "Recraft to Grade 2", "full Grade 1 equipment should offer recraft")
		if compact:
			var consumable := screen.find_child("ConsumableButton", true, false) as Button
			var melee := screen.find_child("MeleeButton", true, false) as Button
			if consumable != null:
				consumable.pressed.emit()
				await _settle()
				_expect(
					_label_text(detail, "TitleLabel") == "Healing Potion",
					"%s should reveal the compact consumable summary on selection" % viewport_size
				)
			if melee != null:
				melee.pressed.emit()
				await _settle()

	_validate_no_forbidden_text(screen, viewport_size)
	_validate_targets(screen, viewport_size)
	_validate_type_scale(screen, viewport_size)
	await _validate_focus(screen, viewport_size)
	_validate_rects(screen, viewport_size)
	_validate_major_layout(screen, viewport_size)
	_validate_text_fit(screen, viewport_size)
	await _capture_if_requested(viewport_size, "en")

	screen.queue_free()
	await process_frame


func _validate_backdrop(screen: Control, viewport_size: Vector2i) -> void:
	var backdrop := screen.get_node_or_null("Backdrop") as Control
	_expect(backdrop != null, "%s should expose the production backdrop" % viewport_size)
	if backdrop == null:
		return
	var texture := backdrop.get("backdrop_texture") as Texture2D
	_expect(
		texture != null
		and texture.resource_path == "res://art/ui/production/backgrounds/hero_preparation.png",
		"%s should use the Hero Preparation background" % viewport_size
	)
	var image := backdrop.get_node_or_null("Image") as TextureRect
	_expect(
		image != null
		and image.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED
		and image.texture == texture
		and image.visible,
		"%s background should preserve aspect and cover" % viewport_size
	)


func _validate_action_and_signal_contracts() -> void:
	_profile_state.initialize_for_tests(
		EQUIPMENT_CATALOG,
		MASTERY_CATALOG,
		"",
		false,
		PROGRESSION_CATALOG
	)
	_set_viewport(Vector2i(1280, 720))
	var screen := (load(HERO_PREPARATION_SCENE) as PackedScene).instantiate() as Control
	root.add_child(screen)
	screen.connect("equipment_command_requested", _record_equipment_signal)
	screen.connect("spirit_stone_equip_requested", _record_stone_signal)
	screen.connect("start_requested", func() -> void: _top_events.append("start"))
	screen.connect("tutorial_requested", func() -> void: _top_events.append("tutorial"))
	screen.connect("settings_requested", func() -> void: _top_events.append("settings"))
	screen.connect("back_requested", func() -> void: _top_events.append("back"))
	await _settle()

	for material_id in ["steel_fragment", "hardwood", "reinforced_fabric"]:
		_profile_state.grant_material(material_id, 99)
	await _settle()
	var action := screen.find_child("PrimaryActionButton", true, false) as Button
	_expect(
		action != null and action.text == "Recraft to Grade 2" and not action.disabled,
		"available Grade 2 materials should enable recraft"
	)
	if action != null:
		action.pressed.emit()
	_expect(
		_last_equipment_signal == {
			"action": &"recraft",
			"model_id": &"traveler_sword",
			"slot": &"melee",
		},
		"recraft affordance should emit action, model, and slot without mutating profile state"
	)

	_profile_state.unlock_blueprint(&"hunting_spear", &"fixture:hero_preparation:spear")
	_profile_state.grant_material("rusted_scrap", 3)
	_profile_state.grant_material("common_timber", 5)
	await _settle()
	_press_model_with_text(screen, "Hunting Spear")
	await _settle()
	action = screen.find_child("PrimaryActionButton", true, false) as Button
	_expect(
		action != null and action.text == "Craft" and not action.disabled,
		"unlocked affordable model should offer deterministic craft"
	)
	if action != null:
		action.pressed.emit()
	_expect(_last_equipment_signal.get("action") == &"craft", "craft button should emit craft")
	_expect(
		_last_equipment_signal.get("model_id") == &"hunting_spear",
		"craft should identify the inspected model"
	)

	var crafted: Dictionary = _profile_state.craft_equipment(&"hunting_spear")
	_expect(bool(crafted.get("ok", false)), "action fixture should craft Hunting Spear")
	await _settle()
	action = screen.find_child("PrimaryActionButton", true, false) as Button
	_expect(
		action != null and action.text == "Equip" and not action.disabled,
		"owned unequipped model should offer equip"
	)
	if action != null:
		action.pressed.emit()
	_expect(_last_equipment_signal.get("action") == &"equip", "equip button should emit equip")
	_expect(_last_equipment_signal.get("slot") == &"melee", "equip should preserve the selected slot")

	var equipped: Dictionary = _profile_state.equip_hero_item(&"melee", &"hunting_spear")
	_expect(bool(equipped.get("ok", false)), "action fixture should equip Hunting Spear")
	_profile_state.consume_equipment_condition(&"hunting_spear", 60.0)
	await _settle()
	action = screen.find_child("PrimaryActionButton", true, false) as Button
	_expect(
		action != null and action.text == "Repair" and not action.disabled,
		"damaged equipped model should offer repair"
	)
	if action != null:
		action.pressed.emit()
	_expect(_last_equipment_signal.get("action") == &"repair", "repair button should emit repair")

	_profile_state.unlock_spirit_stone(&"frost_spirit_stone", &"fixture:hero_preparation:frost")
	await _settle()
	var stone_slot := screen.find_child("SpiritStoneButton", true, false) as Button
	_expect(stone_slot != null, "Spirit Stone slot should remain available")
	if stone_slot != null:
		stone_slot.pressed.emit()
	await _settle()
	_press_model_with_text(screen, "Frost Spirit Stone")
	await _settle()
	action = screen.find_child("PrimaryActionButton", true, false) as Button
	_expect(
		action != null and action.text == "Equip Spirit Stone" and not action.disabled,
		"owned passive Stone should offer equip"
	)
	if action != null:
		action.pressed.emit()
	_expect(_last_stone_signal == &"frost_spirit_stone", "Spirit Stone equip should emit only the selected Stone")

	for event_fixture in [
		["StartButton", "start"],
		["TutorialButton", "tutorial"],
		["SettingsButton", "settings"],
		["BackButton", "back"],
	]:
		var event_button := screen.find_child(String(event_fixture[0]), true, false) as Button
		_expect(event_button != null, "Hero Preparation should expose %s" % event_fixture[0])
		if event_button != null:
			event_button.pressed.emit()
	for expected_event in ["start", "tutorial", "settings", "back"]:
		_expect(_top_events.has(expected_event), "Hero Preparation should emit %s" % expected_event)

	screen.call("show_command_result", {
		"ok": false,
		"persisted": false,
		"code": "persistence_failed",
	})
	await _settle()
	_expect(
		_label_text(screen, "PersistenceLabel").contains("Save failed"),
		"persistence failure should remain visible with a text cue"
	)
	_validate_rects(screen, Vector2i(1280, 720))
	await _validate_focus(screen, Vector2i(1280, 720))

	screen.queue_free()
	await process_frame


func _record_equipment_signal(
	action: StringName,
	model_id: StringName,
	slot: StringName
) -> void:
	_last_equipment_signal = {
		"action": action,
		"model_id": model_id,
		"slot": slot,
	}


func _record_stone_signal(stone_id: StringName) -> void:
	_last_stone_signal = stone_id


func _press_model_with_text(screen: Control, needle: String) -> void:
	for node in screen.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text.contains(needle):
			button.pressed.emit()
			return
	_expect(false, "model list should expose %s" % needle)


func _validate_targets(screen: Control, viewport_size: Vector2i) -> void:
	var visible_buttons := 0
	for node in screen.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button == null or not button.is_visible_in_tree():
			continue
		visible_buttons += 1
		_expect(
			button.size.y >= 48.0,
			"%s target %s is shorter than 48px: %.1f" % [viewport_size, button.name, button.size.y]
		)
		_expect(
			button.focus_mode != Control.FOCUS_NONE,
			"%s target %s should accept keyboard focus" % [viewport_size, button.name]
		)
		var minimum := button.get_combined_minimum_size()
		_expect(
			minimum.x <= button.size.x + 1.0 and minimum.y <= button.size.y + 1.0,
			"%s target %s clips its text: min=%s size=%s"
			% [viewport_size, button.name, minimum, button.size]
		)
	_expect(visible_buttons >= 12, "%s should expose the complete preparation action path" % viewport_size)


func _validate_focus(screen: Control, viewport_size: Vector2i) -> void:
	var focus_owner := root.gui_get_focus_owner()
	_expect(
		focus_owner != null and screen.is_ancestor_of(focus_owner),
		"%s should establish focus inside Hero Preparation" % viewport_size
	)
	var visited: Dictionary = {}
	for _step in 10:
		if focus_owner == null:
			break
		var next_focus := focus_owner.find_next_valid_focus()
		if next_focus == null:
			break
		next_focus.grab_focus()
		await process_frame
		focus_owner = root.gui_get_focus_owner()
		if focus_owner != null and screen.is_ancestor_of(focus_owner):
			visited[focus_owner.get_instance_id()] = true
		else:
			_expect(false, "%s focus traversal left Hero Preparation" % viewport_size)
			break
	_expect(visited.size() >= 3, "%s focus traversal should reach several controls" % viewport_size)


func _validate_rects(screen: Control, viewport_size: Vector2i) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size)).grow(1.0)
	for node in screen.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if _is_scroll_descendant(control, screen):
			continue
		_expect(
			viewport_rect.encloses(rect),
			"%s %s exceeds the viewport: %s" % [viewport_size, control.name, rect]
		)


func _validate_major_layout(screen: Control, viewport_size: Vector2i) -> void:
	var loadout := screen.find_child("LoadoutPanel", true, false) as Control
	var models := screen.find_child("ModelPanel", true, false) as Control
	var detail := screen.find_child("HeroPreparationDetail", true, false) as Control
	var footer := screen.find_child("Footer", true, false) as Control
	for pair in [[loadout, models], [models, detail]]:
		if pair[0] == null or pair[1] == null:
			continue
		_expect(
			not (pair[0] as Control).get_global_rect().intersects((pair[1] as Control).get_global_rect()),
			"%s primary preparation panes should not overlap" % viewport_size
		)
	if detail != null and footer != null:
		_expect(
			not detail.get_global_rect().intersects(footer.get_global_rect()),
			"%s detail and footer should not overlap" % viewport_size
		)


func _validate_text_fit(screen: Control, viewport_size: Vector2i) -> void:
	for node in screen.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null or not label.is_visible_in_tree() or label.text.is_empty():
			continue
		if label.has_method("get_line_count") and label.has_method("get_visible_line_count"):
			_expect(
				int(label.call("get_visible_line_count")) >= int(label.call("get_line_count")),
				"%s label %s clips wrapped text" % [viewport_size, label.name]
			)


func _is_scroll_descendant(control: Control, screen: Control) -> bool:
	var parent := control.get_parent()
	while parent != null and parent != screen:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false


func _validate_type_scale(screen: Control, viewport_size: Vector2i) -> void:
	for node in screen.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or not control.is_visible_in_tree():
			continue
		if control is Label or control is BaseButton:
			_expect(
				control.get_theme_font_size("font_size") >= 16,
				"%s %s uses text smaller than 16px" % [viewport_size, control.name]
			)


func _validate_korean_rendering() -> void:
	_localization.call("set_locale", "ko")
	for viewport_size in VIEWPORTS:
		_set_viewport(viewport_size)
		var screen := (load(HERO_PREPARATION_SCENE) as PackedScene).instantiate() as Control
		root.add_child(screen)
		await _settle()
		var visible_text := _collect_text(screen)
		_expect(visible_text.contains("여행자"), "%s Korean preparation should localize the hero" % viewport_size)
		_expect(visible_text.contains("저장"), "%s Korean preparation should localize save status" % viewport_size)
		_expect(visible_text.contains("공격") or visible_text.contains("근접"), "%s Korean preparation should localize loadout copy" % viewport_size)
		_validate_targets(screen, viewport_size)
		_validate_type_scale(screen, viewport_size)
		_validate_rects(screen, viewport_size)
		_validate_major_layout(screen, viewport_size)
		_validate_text_fit(screen, viewport_size)
		await _capture_if_requested(viewport_size, "ko")
		screen.queue_free()
		await process_frame


func _validate_no_forbidden_text(screen: Control, viewport_size: Vector2i) -> void:
	var visible_text := _collect_text(screen).to_lower()
	for forbidden in FORBIDDEN_VISIBLE_TEXT:
		_expect(
			not visible_text.contains(forbidden),
			"%s should not expose '%s'" % [viewport_size, forbidden]
		)
	_expect(not visible_text.contains("_"), "%s should not expose raw identifiers" % viewport_size)


func _collect_text(parent: Node) -> String:
	var lines: Array[String] = []
	if parent is Label and (parent as Label).is_visible_in_tree():
		lines.append((parent as Label).text)
	elif parent is BaseButton and (parent as BaseButton).is_visible_in_tree():
		lines.append((parent as BaseButton).text)
	for child in parent.get_children():
		lines.append(_collect_text(child))
	return "\n".join(lines)


func _label_text(parent: Node, node_name: String) -> String:
	var label := parent.find_child(node_name, true, false) as Label
	return label.text if label != null else ""


func _set_viewport(viewport_size: Vector2i) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)


func _settle() -> void:
	for _frame in 6:
		await process_frame


func _capture_if_requested(viewport_size: Vector2i, locale: String) -> void:
	if OS.get_environment("CAPTURE_HERO_PREPARATION_UI") != "1":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_path := "%s/hero_preparation_%s_%dx%d.png" % [
		CAPTURE_DIR,
		locale,
		viewport_size.x,
		viewport_size.y,
	]
	var error := image.save_png(output_path) if image != null else ERR_CANT_CREATE
	_expect(error == OK, "%s capture should save" % viewport_size)
	if error == OK:
		print("HERO_PREPARATION_CAPTURE %s" % ProjectSettings.globalize_path(output_path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("HERO_PREPARATION_UI_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
