extends SceneTree

const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
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
	_expect(snapshots.size() == 91, "upgrade catalog produces 91 selectable level states")

	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for snapshot in snapshots:
			_expect_translated(String(snapshot["family_key"]), locale)
			_expect_translated(String(snapshot["title_key"]), locale)
			_expect_translated(String(snapshot["description_key"]), locale)
			for preview_variant in snapshot["value_previews"]:
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
	var breach_preview := {
		"stat_key":"UPGRADE_STAT_BREACH_HEALTH_SCALE_BONUS",
		"operation":&"add",
		"current":0.0,
		"next":0.2,
	}
	_expect(
		String(card.call("_preview_value", breach_preview)) == "+0% → +20%",
		"breach bonus preview renders its fractional ratio as a percentage"
	)
	breach_preview["current"] = 0.2
	breach_preview["next"] = 0.4
	_expect(
		String(card.call("_preview_value", breach_preview)) == "+20% → +40%",
		"second breach bonus level keeps percentage semantics"
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
