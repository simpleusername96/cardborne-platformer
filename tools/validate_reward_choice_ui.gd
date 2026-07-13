extends SceneTree

const LEVEL_SCENE := "res://scenes/ui/production/LevelReward.tscn"
const CARD_SCENE := "res://scenes/ui/production/CardReward.tscn"
const TREASURE_SCENE := "res://scenes/ui/production/TreasureChoice.tscn"
const CHOICE_CARD_SCENE := "res://scenes/ui/production/components/RewardChoiceCard.tscn"
const ChoiceViewModel = preload(
	"res://scripts/ui/production/components/RewardChoiceViewModel.gd"
)
const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _failures: Array[String] = []
var _profile_state: Node
var _run_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_run_state = root.get_node_or_null("/root/RunState")
	_expect(_profile_state != null, "reward choice fixture needs ProfileState")
	_expect(_run_state != null, "reward choice fixture needs RunState")
	if _profile_state == null or _run_state == null:
		_finish()
		return
	_profile_state.call("initialize_for_tests",
		load("res://data/equipment/equipment_catalog.tres"),
		load("res://data/mastery/mastery_catalog.tres")
	)
	await _validate_level_reward()
	await _validate_card_reward()
	await _validate_treasure_choice()
	await _validate_catalog_choice_copy()
	_finish()


func _validate_level_reward() -> void:
	_expect(_run_state.call("start_new_run", 0, 73021), "level reward fixture should start a run")
	var applied := RewardService.apply(
		RewardTransaction.new(&"reward_choice_ui_level", &"fixture", {"xp": 20}),
		_run_state
	)
	_expect(applied.applied, "level reward fixture XP should apply")
	var screen := _instantiate_screen(LEVEL_SCENE)
	if screen == null:
		return
	for viewport in VIEWPORTS:
		await _resize_and_settle(viewport)
		_validate_choice_layout(screen, "UpgradeChoices", 3, "level reward", viewport)
	var offer: Array[StringName] = _run_state.call("get_pending_level_offer")
	var row := screen.find_child("UpgradeChoices", true, false) as HBoxContainer
	if row != null and row.get_child_count() == 3 and offer.size() == 3:
		for index in offer.size():
			var card := row.get_child(index) as Button
			var upgrade: MicroUpgradeDefinition = _run_state.call("get_micro_upgrade", offer[index])
			var copy := String(card.call("get_visible_copy"))
			_expect(copy.contains(upgrade.description), "level choice should retain exact upgrade mechanics")
			_expect(
				copy.contains("->") or upgrade.recovery_choice,
				"level choices should show current and resulting values"
			)
		var requests: Array[StringName] = []
		screen.choice_requested.connect(func(upgrade_id: StringName) -> void: requests.append(upgrade_id))
		(row.get_child(1) as Button).emit_signal("pressed")
		_expect(requests == [offer[1]], "level choice should preserve the requested upgrade signal")
		_expect(
			String((row.get_child(1) as Button).call("get_visible_copy")).contains("SELECTED"),
			"pressed level choice should expose a selected state"
		)
		_expect(
			String((row.get_child(0) as Button).call("get_visible_copy")).contains("WAITING"),
			"other level choices should expose a pending disabled state"
		)
	screen.queue_free()
	await process_frame


func _validate_card_reward() -> void:
	_expect(_run_state.call("start_new_run", 0, 73021), "card reward fixture should start a run")
	RewardService.apply(
		RewardTransaction.new(&"reward_choice_ui_coins", &"fixture", {"coin": 20}),
		_run_state
	)
	var begin: Dictionary = _run_state.call("begin_stage_card_reward")
	_expect(bool(begin.get("ok", false)), "card reward fixture should begin an offer")
	var screen := _instantiate_screen(CARD_SCENE)
	if screen == null:
		return
	for viewport in VIEWPORTS:
		await _resize_and_settle(viewport)
		_validate_choice_layout(screen, "CardChoices", 3, "card reward", viewport)
	var row := screen.find_child("CardChoices", true, false) as HBoxContainer
	var reroll := screen.find_child("Reroll", true, false) as Button
	var continue_button := screen.find_child("Continue", true, false) as Button
	var offer: Array[StringName] = _run_state.call("get_pending_card_offer")
	_expect(
		reroll != null and reroll.text.contains(str(_run_state.call("get_card_reroll_cost"))),
		"reroll action should show the exact live coin cost"
	)
	if row != null and row.get_child_count() == 3 and offer.size() == 3:
		for index in offer.size():
			var card_button := row.get_child(index) as Button
			var definition: CardDefinition = _run_state.call("get_card_definition", offer[index])
			var copy := String(card_button.call("get_visible_copy"))
			_expect(copy.contains(definition.description), "card choice should retain exact mechanics")
			_expect(copy.contains("Stack"), "card choice should show current and result stack")
			_expect(copy.contains(String(definition.rarity).to_upper()), "card rarity should be visible")
			var current_stack := int(_run_state.call("get_card_stack", offer[index]))
			var exact_view := RewardChoiceViewModel.for_card(
				definition,
				current_stack,
				current_stack + 1
			)
			_expect(
				copy.contains(String(exact_view.get("value", ""))),
				"card choice should show exact resource-backed effect values"
			)
		var requests: Array[StringName] = []
		screen.choice_requested.connect(func(card_id: StringName) -> void: requests.append(card_id))
		(row.get_child(0) as Button).emit_signal("pressed")
		_expect(requests == [offer[0]], "card choice should preserve the requested card signal")
		screen.set_commit_error("Fixture retry")
		_expect(not (row.get_child(0) as Button).disabled, "card commit error should restore choices")
		var definition: CardDefinition = _run_state.call("get_card_definition", offer[0])
		screen.show_commit_result({
			"card_id": String(offer[0]),
			"display_name": definition.display_name,
			"stack": int(_run_state.call("get_card_stack", offer[0])) + 1,
		})
		await process_frame
		_expect(continue_button != null and continue_button.visible, "committed card should reveal Continue")
		_expect(
			String((row.get_child(0) as Button).call("get_visible_copy")).contains("SELECTED"),
			"committed card should remain visibly selected"
		)
	screen.queue_free()
	await process_frame


func _validate_treasure_choice() -> void:
	var screen := _instantiate_screen(TREASURE_SCENE)
	if screen == null:
		return
	screen.configure(_treasure_snapshot())
	for viewport in VIEWPORTS:
		await _resize_and_settle(viewport)
		_validate_choice_layout(screen, "TreasureOptions", 2, "treasure choice", viewport)
	var row := screen.find_child("TreasureOptions", true, false) as HBoxContainer
	if row != null and row.get_child_count() == 2:
		var keep_copy := String((row.get_child(0) as Button).call("get_visible_copy"))
		var replacement_copy := String((row.get_child(1) as Button).call("get_visible_copy"))
		_expect(keep_copy.contains("+5 Coins"), "normal treasure choice should show exact cache grants")
		_expect(
			replacement_copy.contains("Maximum health is reduced by 1"),
			"equipment treasure choice should keep its tradeoff visible"
		)
		_expect(
			replacement_copy.contains("REPLACES CACHE REWARD"),
			"replacement choice should state what is forfeited"
		)
		var requests: Array[Dictionary] = []
		screen.choice_requested.connect(func(request_id: StringName, choice_id: StringName) -> void:
			requests.append({"request_id": request_id, "choice_id": choice_id})
		)
		(row.get_child(1) as Button).emit_signal("pressed")
		_expect(
			requests.size() == 1
			and requests[0]["request_id"] == &"optional_cache_fixture"
			and requests[0]["choice_id"] == TreasureChoiceService.REPLACEMENT_CHOICE_ID,
			"treasure choice should preserve request and replacement identity"
		)
	screen.queue_free()
	await process_frame


func _validate_catalog_choice_copy() -> void:
	root.size = Vector2i(960, 540)
	var card_catalog: CardCatalog = _run_state.get("card_catalog")
	_expect(card_catalog != null, "catalog copy fixture needs the card catalog")
	if card_catalog != null:
		for definition in card_catalog.cards:
			if definition == null:
				continue
			var view := ChoiceViewModel.for_card(definition, 0, 1)
			var copy := await _render_compact_choice(definition.id, view)
			_expect(
				copy.contains(definition.description),
				"%s compact choice should retain its exact card description" % definition.display_name
			)
			_expect(
				not copy.contains(String(definition.id)),
				"%s compact choice should not expose its raw card ID" % definition.display_name
			)
			for effect in definition.effects:
				if effect != null:
					_expect(
						not copy.contains(String(effect.effect_type)),
						"%s compact choice should not expose raw effect IDs" % definition.display_name
					)

	var progression: RunProgressionCatalog = _run_state.get("progression_catalog")
	_expect(progression != null, "catalog copy fixture needs the progression catalog")
	if progression == null:
		return
	var upgrades: Array[MicroUpgradeDefinition] = progression.micro_upgrades.duplicate()
	if progression.recovery_choice != null:
		upgrades.append(progression.recovery_choice)
	for upgrade in upgrades:
		var preview: Dictionary = _run_state.call("preview_micro_upgrade", upgrade.id)
		var view := ChoiceViewModel.for_level_upgrade(
			upgrade,
			preview,
			0,
			int(_run_state.get("current_health")),
			int(_run_state.get("max_health"))
		)
		var copy := await _render_compact_choice(upgrade.id, view)
		_expect(
			copy.contains(upgrade.description),
			"%s compact choice should retain its upgrade description" % upgrade.display_name
		)


func _render_compact_choice(choice_id: StringName, view: Dictionary) -> String:
	var packed := load(CHOICE_CARD_SCENE) as PackedScene
	if packed == null:
		_failures.append("shared compact choice scene should load")
		return ""
	var card := packed.instantiate() as Button
	root.add_child(card)
	card.position = Vector2.ZERO
	card.size = Vector2(300.0, 350.0)
	card.call("configure_choice", choice_id, view)
	await process_frame
	await process_frame
	_expect(
		not bool(card.call("has_visible_text_overflow")),
		"%s should fit the compact reward card" % view.get("title", "Reward")
	)
	var copy := String(card.call("get_visible_copy"))
	card.queue_free()
	await process_frame
	return copy


func _instantiate_screen(path: String) -> Control:
	var packed := load(path) as PackedScene
	_expect(packed != null, "%s should load" % path)
	if packed == null:
		return null
	var screen := packed.instantiate() as Control
	root.add_child(screen)
	return screen


func _resize_and_settle(viewport: Vector2i) -> void:
	root.size = viewport
	DisplayServer.window_set_size(viewport)
	for _frame in 3:
		await process_frame


func _validate_choice_layout(
	screen: Control,
	row_name: String,
	expected_count: int,
	context: String,
	viewport: Vector2i
) -> void:
	var row := screen.find_child(row_name, true, false) as HBoxContainer
	_expect(row != null, "%s should expose %s" % [context, row_name])
	if row == null:
		return
	_expect(
		row.get_child_count() == expected_count,
		"%s should show exactly %d choices" % [context, expected_count]
	)
	for child in row.get_children():
		var card := child as Button
		_expect(card != null, "%s choices should remain native buttons" % context)
		if card == null:
			continue
		_expect(card.focus_mode == Control.FOCUS_ALL, "%s choices should accept keyboard focus" % context)
		_expect(card.has_method("has_visible_text_overflow"), "%s should use the shared choice card" % context)
		if card.has_method("has_visible_text_overflow"):
			_expect(
				not bool(card.call("has_visible_text_overflow")),
				"%s choice text should fit at %dx%d" % [context, viewport.x, viewport.y]
			)
		var rect := card.get_global_rect()
		_expect(
			rect.position.x >= -0.5
			and rect.position.y >= -0.5
			and rect.end.x <= float(viewport.x) + 0.5
			and rect.end.y <= float(viewport.y) + 0.5,
			"%s choice should stay inside %dx%d" % [context, viewport.x, viewport.y]
		)
		var raw_id := String(card.get("choice_id"))
		var copy := String(card.call("get_visible_copy"))
		_expect(not raw_id.is_empty() and not copy.contains(raw_id), "%s should not expose raw IDs" % context)
		_expect(
			card.focus_neighbor_left != NodePath()
			and card.focus_neighbor_right != NodePath(),
			"%s choices should expose explicit gamepad navigation" % context
		)
	for left_index in row.get_child_count():
		for right_index in range(left_index + 1, row.get_child_count()):
			var left_card := row.get_child(left_index) as Control
			var right_card := row.get_child(right_index) as Control
			_expect(
				not left_card.get_global_rect().intersects(right_card.get_global_rect()),
				"%s choices should not overlap at %dx%d" % [context, viewport.x, viewport.y]
			)


func _treasure_snapshot() -> Dictionary:
	return {
		"request_id": &"optional_cache_fixture",
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("REWARD_CHOICE_UI_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
