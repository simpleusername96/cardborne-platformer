extends SceneTree

const HERO_ID := &"traveler"
const LIVE_TRIGGERS: Array[StringName] = [
	&"dash_completed",
	&"first_attack_after_extra_jump",
	&"hit_target_in_recovery",
	&"required_room_encounter_cleared_without_damage",
	&"damage_left_one_health",
]
const LEVEL_REWARD_SCENE := "res://scenes/ui/production/LevelReward.tscn"
const CARD_REWARD_SCENE := "res://scenes/ui/production/CardReward.tscn"
const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]
const LOCALES := ["en", "ko"]
const CAPTURE_DIR := "user://reward_choice_ui_validation"
const LEVEL_ERROR_COPY := [
	"No level reward is pending.",
	"Upgrade is not in the current offer.",
	"Upgrade definition is unavailable.",
	"Upgrade is already capped.",
	"Upgrade produced an invalid build.",
	"Choice failed.",
]
const CARD_ERROR_COPY := [
	"No card reward is pending.",
	"The stage card reroll was already used.",
	"No different card choices are available.",
	"No different complete card offer is available.",
	"Card is not in the current offer.",
	"Card is unavailable for this character.",
	"Card is already at maximum stacks.",
	"Choose a card before continuing.",
	"Reroll failed.",
]

var _failures: Array[String] = []
var _run_state: Node
var _localization: Node
var _ui_events: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_localization = root.get_node_or_null("/root/UILocalization")
	_expect(_run_state != null, "card reward fixture needs RunState")
	_expect(_localization != null, "reward UI fixture needs UILocalization")
	if _run_state == null or _localization == null:
		_finish()
		return
	_validate_catalog_and_offer()
	_validate_reroll_and_commit()
	_validate_offer_reproduction()
	await _validate_reward_ui()
	_localization.call("set_locale", "en")
	_finish()


func _validate_reward_ui() -> void:
	_validate_keyboard_contract()
	for locale in LOCALES:
		_localization.call("set_locale", locale)
		_validate_error_copy(locale)
		for viewport_size in VIEWPORTS:
			await _validate_level_reward_ui(locale, viewport_size)
			await _validate_card_reward_ui(locale, viewport_size)


func _validate_level_reward_ui(locale: String, viewport_size: Vector2i) -> void:
	_set_viewport(viewport_size)
	_expect(_run_state.start_new_run(0, 71000 + viewport_size.x), "level UI run should start")
	var xp_result := RewardService.apply(
		RewardTransaction.new(
			StringName("reward_ui_level:%s:%d" % [locale, viewport_size.x]),
			&"fixture",
			{"xp": 30}
		),
		_run_state
	)
	_expect(xp_result.applied, "level UI fixture XP should apply")
	_expect(
		_run_state.get_pending_level_offer().size() == 3,
		"level UI fixture should expose three upgrades"
	)
	var screen := await _mount(LEVEL_REWARD_SCENE)
	if screen == null:
		return
	_ui_events.clear()
	screen.connect(&"choice_requested", func(_upgrade_id: StringName) -> void:
		_ui_events.append("level_choice")
	)
	var row := screen.find_child("UpgradeChoices", true, false) as HBoxContainer
	var buttons := _choice_buttons(row)
	_expect(buttons.size() == 3, "%s %s level reward should show three choices" % [locale, viewport_size])
	_validate_reward_surface(screen, buttons, locale, viewport_size, "level")
	var visible := _collect_visible_text(screen)
	_expect(
		visible.contains("LEVEL 2 REWARD") if locale == "en" else visible.contains("레벨 2 보상"),
		"%s %s level heading should use the selected locale" % [locale, viewport_size]
	)
	if locale == "ko":
		_expect(
			not visible.contains("Measured Force"),
			"%s Korean level cards should translate upgrade names" % viewport_size
		)
	await _capture_if_requested(screen, "level_offer", locale, viewport_size)
	await _validate_choice_keyboard(buttons, "level", viewport_size)
	screen.call("set_commit_error", "Upgrade is already capped.")
	await _settle()
	_validate_reward_surface(screen, buttons, locale, viewport_size, "level error")
	_expect(
		_collect_visible_text(screen).contains(_t("Upgrade is already capped.")),
		"%s level error should render in %s" % [locale, viewport_size]
	)
	await _capture_if_requested(screen, "level_error", locale, viewport_size)
	await _unmount(screen)


func _validate_card_reward_ui(locale: String, viewport_size: Vector2i) -> void:
	_set_viewport(viewport_size)
	_expect(_run_state.start_new_run(0, 72000 + viewport_size.x), "card UI run should start")
	RewardService.apply(
		RewardTransaction.new(
			StringName("reward_ui_coins:%s:%d" % [locale, viewport_size.x]),
			&"fixture",
			{"coin": 30}
		),
		_run_state
	)
	var begin: Dictionary = _run_state.begin_stage_card_reward()
	_expect(bool(begin.get("ok", false)), "card UI fixture should begin")
	var offer: Array[StringName] = _run_state.get_pending_card_offer()
	var screen := await _mount(CARD_REWARD_SCENE)
	if screen == null:
		return
	_ui_events.clear()
	screen.connect(&"choice_requested", func(_card_id: StringName) -> void:
		_ui_events.append("card_choice")
	)
	screen.connect(&"reroll_requested", func() -> void: _ui_events.append("reroll"))
	screen.connect(&"continue_requested", func() -> void: _ui_events.append("continue"))
	var row := screen.find_child("CardChoices", true, false) as HBoxContainer
	var buttons := _choice_buttons(row)
	_expect(buttons.size() == 3, "%s %s card reward should show three choices" % [locale, viewport_size])
	_validate_reward_surface(screen, buttons, locale, viewport_size, "card")
	var visible := _collect_visible_text(screen)
	_expect(
		visible.contains("CHOOSE A CARD") if locale == "en" else visible.contains("카드를 선택하세요"),
		"%s %s card heading should use the selected locale" % [locale, viewport_size]
	)
	if locale == "ko":
		for english_title in ["Dash Wake", "Aerial Opener", "Perfect Punish", "Second Wind", "Last Stand"]:
			_expect(
				not visible.contains(english_title),
				"%s Korean card offer should translate %s"
				% [viewport_size, english_title]
			)
	await _capture_if_requested(screen, "card_offer", locale, viewport_size)
	await _validate_card_keyboard(screen, buttons, viewport_size)
	_ui_events.clear()
	screen.call("refresh_offer")
	await _settle()
	screen.call("_request_reroll")
	var reroll_result: Dictionary = _run_state.reroll_card_offer()
	_expect(bool(reroll_result.get("ok", false)), "UI reroll fixture should settle")
	screen.call("refresh_offer")
	await _settle()
	_expect(_ui_events == ["reroll"], "mouse/confirm reroll command should emit once")
	offer = _run_state.get_pending_card_offer()
	row = screen.find_child("CardChoices", true, false) as HBoxContainer
	buttons = _choice_buttons(row)
	_validate_reward_surface(screen, buttons, locale, viewport_size, "card reroll")
	var reroll_copy := _collect_visible_text(screen)
	_expect(
		reroll_copy.contains("Reroll used.")
		if locale == "en"
		else reroll_copy.contains("새로 뽑기를 사용했습니다."),
		"%s reroll result should stay localized at %s" % [locale, viewport_size]
	)
	screen.call("set_commit_error", "Reroll needs 12 coins.")
	await _settle()
	_validate_reward_surface(screen, buttons, locale, viewport_size, "card error")
	_expect(
		_collect_visible_text(screen).contains(_t("Reroll needs %d coins.", [12])),
		"%s formatted reroll error should render in %s" % [locale, viewport_size]
	)
	await _capture_if_requested(screen, "card_error", locale, viewport_size)
	_ui_events.clear()
	if not offer.is_empty():
		var card := _run_state.get_card_definition(offer[0]) as CardDefinition
		screen.call("show_commit_result", {
			"card_id": offer[0],
			"display_name": card.display_name if card != null else "Card",
			"stack": 1,
		})
		await _settle()
		var continue_button := screen.find_child("Continue", true, false) as Button
		_expect(continue_button != null and continue_button.visible, "commit state should show Continue")
		if continue_button != null:
			_validate_button(continue_button, locale, viewport_size)
			_expect(root.gui_get_focus_owner() == continue_button, "commit state should focus Continue")
			await _press_ui_action(&"ui_accept")
			_expect(_ui_events.has("continue"), "Enter/Space confirm should continue after commit")
	await _capture_if_requested(screen, "card_committed", locale, viewport_size)
	await _unmount(screen)


func _validate_reward_surface(
	screen: Control,
	buttons: Array[Button],
	locale: String,
	viewport_size: Vector2i,
	surface: String
) -> void:
	var bounds := Rect2(Vector2.ZERO, Vector2(viewport_size)).grow(1.0)
	var page := screen.find_child("RewardPage", true, false) as Control
	_expect(
		page != null and bounds.encloses(page.get_global_rect()),
		"%s %s page must stay inside %s" % [locale, surface, viewport_size]
	)
	for button in buttons:
		_validate_button(button, locale, viewport_size)
		_expect(
			not bool(button.call("has_visible_text_overflow")),
			"%s %s choice copy must not clip at %s" % [locale, surface, viewport_size]
		)
	for node in screen.find_children("*", "Button", true, false):
		var interactive := node as Button
		if interactive != null and interactive.is_visible_in_tree():
			_validate_button(interactive, locale, viewport_size)
	for node in screen.find_children("*", "Label", true, false):
		var label := node as Label
		if label == null or not label.is_visible_in_tree() or label.text.is_empty():
			continue
		_expect(
			label.get_theme_font_size("font_size") >= 16,
			"%s %s uses sub-16px text in %s" % [locale, label.name, viewport_size]
		)
		_expect(
			label.get_visible_line_count() >= label.get_line_count(),
			"%s %s clips text at %s" % [locale, label.name, viewport_size]
		)
		_expect(bounds.encloses(label.get_global_rect()), "%s %s escapes %s" % [locale, label.name, viewport_size])
	var status := screen.find_child("Status", true, false) as Label
	var row := screen.find_child(
		"UpgradeChoices" if surface == "level" else "CardChoices",
		true,
		false
	) as Control
	if row != null:
		_expect(
			status == null or not row.get_global_rect().intersects(status.get_global_rect()),
			"%s %s choices must not overlap status" % [locale, viewport_size]
		)


func _validate_button(button: Button, locale: String, viewport_size: Vector2i) -> void:
	_expect(button.size.y >= 48.0, "%s %s target is under 48px at %s" % [locale, button.name, viewport_size])
	_expect(button.focus_mode != Control.FOCUS_NONE, "%s %s must accept keyboard focus" % [locale, button.name])
	_expect(
		button.mouse_filter != Control.MOUSE_FILTER_IGNORE,
		"%s %s must accept mouse input" % [locale, button.name]
	)
	var minimum := button.get_combined_minimum_size()
	_expect(
		minimum.x <= button.size.x + 1.0 and minimum.y <= button.size.y + 1.0,
		"%s %s clips its minimum size at %s" % [locale, button.name, viewport_size]
	)
	_expect(
		Rect2(Vector2.ZERO, Vector2(viewport_size)).grow(1.0).encloses(button.get_global_rect()),
		"%s %s escapes %s" % [locale, button.name, viewport_size]
	)


func _validate_choice_keyboard(
	buttons: Array[Button],
	surface: String,
	viewport_size: Vector2i
) -> void:
	if buttons.size() < 2:
		return
	buttons[0].grab_focus()
	await _press_ui_action(&"ui_right")
	_expect(
		root.gui_get_focus_owner() == buttons[1],
		"%s Right Arrow should move to the next choice at %s" % [surface, viewport_size]
	)
	await _press_ui_action(&"ui_cancel")
	_expect(_ui_events.is_empty(), "%s Escape must not commit or skip a mandatory reward" % surface)
	await _press_ui_action(&"ui_accept")
	_expect(_ui_events == ["level_choice"], "Enter/Space should activate the focused level choice")


func _validate_card_keyboard(
	screen: Control,
	buttons: Array[Button],
	viewport_size: Vector2i
) -> void:
	if buttons.size() < 2:
		return
	buttons[0].grab_focus()
	await _press_ui_action(&"ui_right")
	_expect(root.gui_get_focus_owner() == buttons[1], "card Right Arrow should move focus at %s" % viewport_size)
	await _press_ui_action(&"ui_down")
	var reroll := screen.find_child("Reroll", true, false) as Button
	_expect(root.gui_get_focus_owner() == reroll, "Down Arrow should reach reroll at %s" % viewport_size)
	await _press_ui_action(&"ui_cancel")
	_expect(_ui_events.is_empty(), "Escape must not commit, reroll, or skip a mandatory card reward")
	buttons[1].grab_focus()
	await _press_ui_action(&"ui_accept")
	_expect(_ui_events == ["card_choice"], "Enter/Space should activate the focused card")


func _validate_keyboard_contract() -> void:
	_expect(_action_has_key(&"ui_left", KEY_LEFT), "Left Arrow should drive menu focus")
	_expect(_action_has_key(&"ui_right", KEY_RIGHT), "Right Arrow should drive menu focus")
	_expect(_action_has_key(&"ui_up", KEY_UP), "Up Arrow should drive menu focus")
	_expect(_action_has_key(&"ui_down", KEY_DOWN), "Down Arrow should drive menu focus")
	_expect(_action_has_key(&"ui_accept", KEY_ENTER), "Enter should confirm focused menu actions")
	_expect(_action_has_key(&"ui_accept", KEY_SPACE), "Space should confirm focused menu actions")
	_expect(_action_has_key(&"pause", KEY_ESCAPE), "Escape should remain pause/back")


func _validate_error_copy(locale: String) -> void:
	if locale != "ko":
		return
	for source in LEVEL_ERROR_COPY + CARD_ERROR_COPY:
		_expect(_t(source) != source, "Korean reward error is missing: %s" % source)
	_expect(
		_t("Reroll needs %d coins.", [12]) != "Reroll needs 12 coins.",
		"Korean formatted reroll error should be translated"
	)


func _action_has_key(action: StringName, keycode: Key) -> bool:
	for input_event in InputMap.action_get_events(action):
		if input_event is InputEventKey:
			var key_event := input_event as InputEventKey
			if key_event.keycode == keycode or key_event.physical_keycode == keycode:
				return true
	return false


func _t(source: String, values: Array = []) -> String:
	return String(_localization.call("text", StringName(source), values))


func _choice_buttons(row: HBoxContainer) -> Array[Button]:
	var result: Array[Button] = []
	if row == null:
		return result
	for child in row.get_children():
		if child is Button:
			result.append(child as Button)
	return result


func _collect_visible_text(parent: Node) -> String:
	var lines: Array[String] = []
	if parent is Label and (parent as Label).is_visible_in_tree():
		lines.append((parent as Label).text)
	elif parent is BaseButton and (parent as BaseButton).is_visible_in_tree():
		lines.append((parent as BaseButton).text)
	for child in parent.get_children():
		lines.append(_collect_visible_text(child))
	return "\n".join(lines)


func _mount(scene_path: String) -> Control:
	var packed := load(scene_path) as PackedScene
	var screen := packed.instantiate() as Control if packed != null else null
	_expect(screen != null, "%s should instantiate" % scene_path)
	if screen == null:
		return null
	root.add_child(screen)
	await _settle()
	return screen


func _unmount(screen: Control) -> void:
	screen.queue_free()
	await process_frame


func _set_viewport(viewport_size: Vector2i) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)


func _settle() -> void:
	for _frame in 6:
		await process_frame


func _press_ui_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame


func _capture_if_requested(
	screen: Control,
	surface: String,
	locale: String,
	viewport_size: Vector2i
) -> void:
	if OS.get_environment("CAPTURE_REWARD_UI") != "1":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var output_path := "%s/%s_%s_%dx%d.png" % [
		CAPTURE_DIR,
		surface,
		locale,
		viewport_size.x,
		viewport_size.y,
	]
	var error := image.save_png(output_path) if image != null else ERR_CANT_CREATE
	_expect(error == OK, "%s capture should save" % surface)
	if error == OK:
		print("REWARD_UI_CAPTURE %s" % ProjectSettings.globalize_path(output_path))


func _validate_catalog_and_offer() -> void:
	var catalog := _run_state.get("card_catalog") as CardCatalog
	_expect(catalog != null, "production card catalog should load")
	if catalog == null:
		return
	_expect(catalog.validate_catalog().is_empty(), "production card catalog should validate")
	_expect(catalog.cards.size() == 5, "production should expose exactly five live cards")
	for card in catalog.cards:
		_expect(card.compatibility == [&"shared"], "%s should be shared by the Traveler" % card.id)
		_expect(LIVE_TRIGGERS.has(card.trigger), "%s should use a live Traveler trigger" % card.id)

	var first := CardOfferService.build_offer(catalog, HERO_ID, {}, 93117, 0, 0, [], LIVE_TRIGGERS)
	var repeat := CardOfferService.build_offer(catalog, HERO_ID, {}, 93117, 0, 0, [], LIVE_TRIGGERS)
	_expect(first == repeat, "identical card offer inputs should reproduce exactly")
	_expect(first.size() == 3 and _all_unique(first), "offers should contain three unique cards")
	var seen: Dictionary = {}
	for seed in 256:
		for card_id in CardOfferService.build_offer(
			catalog, HERO_ID, {}, seed, seed % 3, 0, [], LIVE_TRIGGERS
		):
			seen[String(card_id)] = true
	for card in catalog.cards:
		_expect(seen.has(String(card.id)), "%s should be reachable from production offers" % card.id)


func _validate_reroll_and_commit() -> void:
	_expect(_run_state.start_new_run(0, 93117), "fixed-seed Traveler run should start")
	var begin: Dictionary = _run_state.begin_stage_card_reward()
	_expect(bool(begin.get("ok", false)), "stage card reward should begin")
	var original: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(original.size() == 3 and _all_unique(original), "pending offer should be complete")

	var invalid: Dictionary = _run_state.choose_card(&"not_offered")
	_expect(not bool(invalid.get("ok", false)), "an unoffered card should fail closed")
	_expect(_run_state.get_card_stacks().is_empty(), "failed choice must not mutate stacks")

	var funded := RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins", &"fixture", {"coin": 30}),
		_run_state
	)
	_expect(funded.applied and int(_run_state.get("coins")) == 30, "fixture coins should apply once")
	var rerolled: Dictionary = _run_state.reroll_card_offer()
	var next_offer: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(bool(rerolled.get("ok", false)), "first affordable reroll should succeed")
	_expect(next_offer.size() == 3 and not _same_choice_set(next_offer, original), "reroll should visibly change the offer")
	_expect(int(_run_state.get("coins")) == 18, "reroll should deduct exactly 12 coins")
	_expect(not bool(_run_state.reroll_card_offer().get("ok", false)), "one stage allows one reroll")

	var selected := next_offer[0]
	var committed: Dictionary = _run_state.choose_card(selected)
	_expect(bool(committed.get("ok", false)), "an offered card should commit")
	_expect(int(_run_state.get_card_stack(selected)) == 1, "card commit should add one stack")
	_expect(not bool(_run_state.choose_card(selected).get("ok", false)), "one reward cannot commit twice")
	_expect(_run_state.advance_stage_after_card_reward(), "a committed reward should unlock the next stage")
	_expect(int(_run_state.get("current_stage_index")) == 1, "card continuation should advance one stage")


func _validate_offer_reproduction() -> void:
	_expect(_run_state.start_new_run(0, 93117), "reproduction run should restart")
	_run_state.begin_stage_card_reward()
	var original: Array[StringName] = _run_state.get_pending_card_offer()
	RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins_repeat", &"fixture", {"coin": 30}),
		_run_state
	)
	_run_state.reroll_card_offer()
	var rerolled: Array[StringName] = _run_state.get_pending_card_offer()

	_expect(_run_state.start_new_run(0, 93117), "second reproduction run should restart")
	_run_state.begin_stage_card_reward()
	var repeated_original: Array[StringName] = _run_state.get_pending_card_offer()
	RewardService.apply(
		RewardTransaction.new(&"card_fixture_coins_repeat", &"fixture", {"coin": 30}),
		_run_state
	)
	_run_state.reroll_card_offer()
	var repeated_reroll: Array[StringName] = _run_state.get_pending_card_offer()
	_expect(original == repeated_original, "initial offer should reproduce after restart")
	_expect(rerolled == repeated_reroll, "rerolled offer should reproduce after restart")
	_expect(not _run_state.start_new_run(1, 77), "retired class profile indexes should fail closed")


func _all_unique(values: Array[StringName]) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(String(value)):
			return false
		seen[String(value)] = true
	return true


func _same_choice_set(first: Array[StringName], second: Array[StringName]) -> bool:
	if first.size() != second.size():
		return false
	for card_id in first:
		if not second.has(card_id):
			return false
	return true


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"CARD_REWARD_VALIDATION_OK hero=traveler catalog=5 offer=3 "
			+ "ui_locales=2 ui_viewports=3 targets=48px focus=arrows>accept cancel=safe"
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
