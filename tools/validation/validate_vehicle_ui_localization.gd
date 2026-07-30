extends SceneTree

const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")
const UpgradeChoiceCard = preload("res://scripts/ui/vehicle_upgrade_choice_card.gd")
const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var original_locale := TranslationServer.get_locale()
	var catalog := Catalog.new()
	var snapshots: Array[Dictionary] = []
	for definition in catalog.all_definitions():
		for current_level in definition.max_level:
			snapshots.append(OfferPresenter.snapshot(definition, current_level))
	_expect(snapshots.size() == 83, "upgrade catalog produces 83 selectable level states")

	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		var field_stage_titles := {}
		for field_id in FieldRegistry.FIELD_IDS:
			for stage_id in CombatStages.STAGE_IDS:
				var title_key := String(
					CombatStages.profile(stage_id, field_id)["title_key"]
				)
				_expect_translated(title_key, locale)
				field_stage_titles[title_key] = true
		_expect(
			field_stage_titles.size() == 15,
			"%s resolves a distinct title for all three fields and five stages"
				% locale
		)
		for snapshot in snapshots:
			_expect_translated(String(snapshot["family_key"]), locale)
			_expect_translated(String(snapshot["title_key"]), locale)
			_expect_translated(String(snapshot["summary_key"]), locale)
			var behavior_key := String(snapshot["behavior_change_key"])
			if not behavior_key.is_empty():
				_expect_translated(behavior_key, locale)
			for preview_variant in snapshot["effect_rows"]:
				_expect_translated(
					String(Dictionary(preview_variant)["stat_key"]),
					locale
				)
		for pattern_key in BossPatterns.DISPLAY_KEYS.values():
			_expect_translated(String(pattern_key), locale)
		for mode_key in BossPatterns.COMMIT_MODE_KEYS.values():
			_expect_translated(String(mode_key), locale)
		var ui := StageUI.new()
		get_root().add_child(ui)
		await process_frame
		for stage_title_key in field_stage_titles:
			var result_contract := ui.debug_modal_contract(
				"result",
				String(stage_title_key)
			)
			_expect(
				String(result_contract["result_kicker"]).contains(
					TranslationServer.translate(String(stage_title_key))
				),
				"%s result summary uses current stage title %s" % [
					locale, stage_title_key,
				]
			)
		for option_text in ui.debug_practice_option_texts():
			_expect(
				not option_text.is_empty()
					and not option_text.contains("_")
					and option_text.to_lower() not in [
						"committed", "interruptible signature", "autonomous",
					],
				"%s boss-practice option uses localized presentation: %s" % [
					locale, option_text,
				]
			)
		ui.queue_free()
		await process_frame

	var card := UpgradeChoiceCard.new()
	get_root().add_child(card)
	await process_frame
	var additive_preview := {
		"stat_key":"UPGRADE_STAT_PICKUP_RADIUS_BONUS",
		"operation":&"add",
		"current":0.0,
		"next":18.0,
	}
	_expect(
		String(card.call("_preview_value", additive_preview)) == "+0 → +18",
		"additive card preview renders ordinary values directly"
	)
	additive_preview["current"] = 18.0
	additive_preview["next"] = 36.0
	_expect(
		String(card.call("_preview_value", additive_preview)) == "+18 → +36",
		"second additive level keeps the same preview semantics"
	)
	card.queue_free()
	TranslationServer.set_locale(original_locale)
	await process_frame
	_finish()


func _expect_translated(key: String, locale: String) -> void:
	var value := TranslationServer.translate(key)
	_expect(
		not key.is_empty() and not value.is_empty() and value != key,
		"%s resolves user-facing key %s" % [locale, key]
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_UI_LOCALIZATION_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
