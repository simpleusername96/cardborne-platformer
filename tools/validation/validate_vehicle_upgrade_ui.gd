extends SceneTree

const THEME_PATH := "res://art/visuals/production/ui/vehicle_stage_theme.tres"
const FONT_PATH := (
	"res://art/visuals/production/ui/fonts/NotoSansKR-Variable.ttf"
)
const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const OfferPresenter = preload(
	"res://scripts/cards/vehicle_upgrade_offer_presenter.gd"
)
const UpgradeChoiceCard = preload(
	"res://scripts/ui/vehicle_upgrade_choice_card.gd"
)
const UpgradeChoicePanel = preload(
	"res://scripts/ui/vehicle_upgrade_choice_panel.gd"
)
const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const WORST_TEXT_TRIPLETS := {
	"ko":[
		{"id":&"twin_seekers", "current_level":1},
		{"id":&"marked_salvo", "current_level":0},
		{"id":&"static_aegis", "current_level":1},
	],
	"en":[
		{"id":&"marked_salvo", "current_level":0},
		{"id":&"twin_seekers", "current_level":1},
		{"id":&"phase_lance", "current_level":1},
	],
}
const DENSE_STAT_TRIPLET := [
	{"id":&"kinetic_rounds", "current_level":2},
	{"id":&"pickup_magnet", "current_level":2},
	{"id":&"reinforced_hull", "current_level":2},
]
const VIEWPORTS := [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var failures: Array[String] = []
var _theme: Theme


func _initialize() -> void:
	_theme = load(THEME_PATH) as Theme
	_validate_theme_contract()
	_validate_authored_artwork()
	var catalog := Catalog.new()
	await _validate_intent_contract(catalog)
	await _validate_category_body_art(catalog)
	await _validate_triplet_matrix(catalog)
	_finish()


func _validate_theme_contract() -> void:
	_expect(_theme != null, "vehicle stage theme loads")
	if _theme == null:
		return
	var body_font := _theme.default_font as FontVariation
	var strong_font := _theme.get_font(&"font", &"TitleLabel") as FontVariation
	_expect(body_font != null, "body typography uses one font variation")
	_expect(strong_font != null, "title typography uses one font variation")
	if body_font != null:
		_expect(
			is_equal_approx(
				float(body_font.variation_opentype.get("weight", 0.0)),
				650.0
			),
			"body typography uses weight 650"
		)
		_expect(
			body_font.base_font != null
				and body_font.base_font.resource_path == FONT_PATH,
			"body typography keeps the project Noto Sans KR variable font"
		)
	if strong_font != null:
		_expect(
			is_equal_approx(
				float(strong_font.variation_opentype.get("weight", 0.0)),
				800.0
			),
			"strong/title typography uses weight 800"
		)
		_expect(
			strong_font.base_font != null
				and strong_font.base_font.resource_path == FONT_PATH,
			"strong typography keeps the project Noto Sans KR variable font"
		)
	for variation in [&"MetricLabel", &"SectionLabel", &"DisplayLabel"]:
		_expect(
			_theme.get_font(&"font", variation) == strong_font,
			"%s reuses the strong Noto Sans KR variation" % variation
		)
	var normal := _theme.get_stylebox(
		&"normal",
		&"SelectableButton"
	) as StyleBoxFlat
	var focus := _theme.get_stylebox(
		&"focus",
		&"SelectableButton"
	) as StyleBoxFlat
	var selected := _theme.get_stylebox(
		&"normal",
		&"SelectedSelectableButton"
	) as StyleBoxFlat
	var disabled := _theme.get_stylebox(
		&"disabled",
		&"SelectableButton"
	) as StyleBoxFlat
	_expect(
		normal != null,
		"normal upgrade card uses the shared code-native Selectable state"
	)
	_expect(
		focus != null and focus != normal,
		"focused upgrade card uses the shared code-native focus outline"
	)
	_expect(
		selected != null and selected != normal,
		"selected upgrade card uses the shared code-native selected rail"
	)
	_expect(
		disabled != null and disabled != normal,
		"disabled/pending upgrade card uses a distinct non-color shared state"
	)


func _validate_authored_artwork() -> void:
	for asset_id in [
		&"upgrade/ion_field",
		&"upgrade/element_thermal",
		&"upgrade/element_toxin",
		&"upgrade/element_cryo",
		&"upgrade/dash_wake",
		&"upgrade/defense_matrix",
		&"upgrade/system_relay",
		&"upgrade/mobility_thruster",
		&"upgrade/pickup_magnet",
		&"upgrade/hull_reinforcement",
	]:
		_expect(SemanticAssets.has_asset(asset_id), "%s authored upgrade art is indexed" % asset_id)
		_expect(SemanticAssets.texture(asset_id) != null, "%s authored upgrade art loads" % asset_id)


func _validate_category_body_art(catalog: VehicleUpgradeCatalog) -> void:
	var card := UpgradeChoiceCard.new()
	card.theme = _theme
	get_root().add_child(card)
	await process_frame
	card.set_compact_mode(true)
	card.size = card.custom_minimum_size
	for definition in catalog.all_definitions():
		var category := definition.category
		_expect(definition != null, "%s has a live upgrade card fixture" % category)
		if definition == null:
			continue
		card.set_offer(OfferPresenter.snapshot(definition, 0))
		await process_frame
		var contract := card.debug_contract()
		_expect(
			int(contract["header_art_count"]) == 0
				and int(contract["body_art_count"]) == 1
				and int(contract["category_badge_count"]) == 0
				and int(contract["stage_pip_count"]) == 0,
			"%s renders exactly one lower artwork and no header art/badge"
			% category
		)
		_expect(
			Vector2(contract["body_art_size"]) == Vector2(88.0, 88.0)
				and StringName(contract["body_art_asset_id"])
					!= &""
				and Array(contract["body_order"]) == [
					"category",
					"title",
					"dossier:art/divider/level/effects",
					"description",
				]
				and bool(contract["dossier_split"])
				and int(contract["body_divider_count"]) == 1,
			"%s uses the compact split-dossier artwork contract" % category
		)
		_expect(
			int(Dictionary(contract["type_sizes"])["summary"]) >= 14,
			"%s keeps compact description copy at the 14 px body-text minimum"
			% category
		)
		var geometry := card.debug_geometry_contract()
		_expect_card_geometry(geometry, "%s compact category" % category)
		var artwork := Dictionary(geometry["artwork"])
		_expect(
			StringName(artwork["asset_id"]) != &""
				and bool(artwork["texture_loaded"]),
			"%s body art uses one authored semantic texture" % category
		)
	card.queue_free()
	await process_frame


func _validate_intent_contract(catalog: VehicleUpgradeCatalog) -> void:
	var definitions := catalog.all_definitions()
	var offers: Array[Dictionary] = []
	for index in 3:
		offers.append(OfferPresenter.snapshot(definitions[index], 0))
	var panel := UpgradeChoicePanel.new()
	panel.theme = _theme
	get_root().add_child(panel)
	await process_frame
	var selected_ids: Array[StringName] = []
	var confirmed_ids: Array[StringName] = []
	panel.selected.connect(
		func(upgrade_id: StringName) -> void:
			selected_ids.append(upgrade_id)
	)
	panel.confirmed.connect(
		func(upgrade_id: StringName) -> void:
			confirmed_ids.append(upgrade_id)
	)
	panel.open(offers)
	var initial_contract := panel.debug_contract()
	_expect(
		bool(initial_contract["confirm_disabled"])
			and int(initial_contract["command_count"]) == 1
			and int(initial_contract["exit_action_count"]) == 0
			and int(initial_contract["header_text_count"]) == 0,
		"mandatory upgrade opens directly on cards with one disabled Equip command"
	)
	panel.call("_select", 0)
	_expect(
		selected_ids.is_empty(),
		"upgrade input guard rejects carried selection"
	)
	panel.call("_process", 0.36)
	_expect(
		panel.buttons()[0].has_focus(),
		"first visible card receives focus after the input guard"
	)
	panel.call("_select", 0)
	var selected_contract := panel.debug_contract()
	_expect(
		not bool(selected_contract["confirm_disabled"])
			and StringName(panel.buttons()[0].theme_type_variation)
				== &"SelectedSelectableButton",
		"selection enables Equip and uses the shared selected state"
	)
	panel.call("_confirm_selected")
	panel.call("_confirm_selected")
	_expect(
		selected_ids == [StringName(offers[0]["id"])]
			and confirmed_ids == [StringName(offers[0]["id"])],
		"upgrade panel emits one selection and one confirmation intent"
	)
	var pending_contract := panel.debug_contract()
	_expect(
		bool(pending_contract["pending"])
			and bool(pending_contract["confirm_disabled"])
			and panel.buttons().all(func(button: Button) -> bool: return button.disabled),
		"pending state disables cards and Equip against duplicate application"
	)
	panel.apply_failed("retry")
	var failed_contract := panel.debug_contract()
	_expect(
		not bool(failed_contract["pending"])
			and not bool(failed_contract["confirm_disabled"])
			and String(failed_contract["message_text"]) == "retry",
		"apply failure restores the selected Equip path and exposes its message"
	)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	panel.call("_unhandled_input", escape)
	_expect(
		String(panel.debug_contract()["message_text"])
			== TranslationServer.translate("UPGRADE_MANDATORY_NOTICE"),
		"Escape shows only the mandatory-choice notice"
	)
	_expect(
		is_equal_approx(
			float(panel.debug_contract()["guard_seconds"]),
			0.35
		),
		"upgrade input guard remains 0.35 seconds"
	)
	var panel_source := FileAccess.get_file_as_string(
		"res://scripts/ui/vehicle_upgrade_choice_panel.gd"
	)
	var card_source := FileAccess.get_file_as_string(
		"res://scripts/ui/vehicle_upgrade_choice_card.gd"
	)
	for forbidden_panel_token in [
		"signal declined",
		"_decline",
		"_request_decline",
		"UPGRADE_LEAVE_REWARD",
		"UPGRADE_OPTIONAL_NOTICE",
	]:
		_expect(
			not panel_source.contains(forbidden_panel_token),
			"mandatory upgrade panel removes %s" % forbidden_panel_token
		)
	for forbidden_card_token in ["_header", "_family_badge", "FamilyBadge"]:
		_expect(
			not card_source.contains(forbidden_card_token),
			"upgrade card removes %s" % forbidden_card_token
		)
	for source_record in [
		{"name":"panel", "source":panel_source},
		{"name":"card", "source":card_source},
	]:
		_expect(
			not String(source_record["source"]).contains("run_build")
				and not String(source_record["source"]).contains(".apply("),
			"upgrade %s remains presentation/intent-only"
			% source_record["name"]
		)
	panel.queue_free()
	await process_frame


func _validate_triplet_matrix(catalog: VehicleUpgradeCatalog) -> void:
	var original_locale := TranslationServer.get_locale()
	var snapshot_count := 0
	for definition in catalog.all_definitions():
		snapshot_count += definition.max_level
	_expect(snapshot_count == 39, "worst-case fixture is grounded in all 39 card states")
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		_validate_longest_fixture(catalog, locale)
		for viewport in VIEWPORTS:
			for fixture_record in [
				{
					"name":"worst-text",
					"records":WORST_TEXT_TRIPLETS[locale],
				},
				{
					"name":"dense-stat",
					"records":DENSE_STAT_TRIPLET,
				},
			]:
				var offers := _offers_from_fixture(
					catalog,
					Array(fixture_record["records"])
				)
				await _validate_panel(
					viewport,
					offers,
					"%s %dx%d %s" % [
						locale,
						viewport.x,
						viewport.y,
						fixture_record["name"],
					]
				)
	TranslationServer.set_locale(original_locale)


func _validate_panel(
	viewport: Vector2i,
	offers: Array[Dictionary],
	context: String
) -> void:
	get_root().content_scale_size = viewport
	get_root().size = viewport
	var center := CenterContainer.new()
	center.theme = _theme
	center.position = Vector2.ZERO
	center.size = Vector2(viewport)
	get_root().add_child(center)
	var surface := PanelContainer.new()
	surface.theme_type_variation = &"ModalSurface"
	surface.custom_minimum_size = Vector2(
		minf(1160.0, float(viewport.x) - 48.0),
		minf(580.0, float(viewport.y) - 24.0)
	)
	center.add_child(surface)
	var panel := UpgradeChoicePanel.new()
	surface.add_child(panel)
	await _settle_ui()
	var compact := viewport.x < Art.BREAKPOINT_WIDE or viewport.y < 650
	panel.set_compact_mode(compact)
	panel.open(offers)
	await _settle_ui()
	var geometry := panel.debug_geometry_contract()
	var panel_rect := Rect2(geometry["rect"]).grow(0.75)
	var row_rect := Rect2(geometry["row_rect"]).grow(0.75)
	var surface_rect := surface.get_global_rect().grow(0.75)
	_expect(surface_rect.encloses(panel_rect), "%s panel stays inside its surface" % context)
	var expected_size := (
		Vector2(280.0, 378.0)
		if compact
		else Vector2(360.0, 456.0)
	)
	var expected_gap := 12.0 if compact else 16.0
	var prior_card := Rect2()
	var card_count := 0
	for card_variant in geometry["cards"]:
		var card := Dictionary(card_variant)
		var card_rect := Rect2(card["rect"])
		_expect(
			card_rect.size.is_equal_approx(expected_size),
			"%s card uses %s geometry, got %s"
			% [context, expected_size, card_rect.size]
		)
		_expect(row_rect.encloses(card_rect), "%s card stays inside the choice row" % context)
		if prior_card.has_area():
			_expect(
				is_equal_approx(
					card_rect.position.x - prior_card.end.x,
					expected_gap
				),
				"%s cards keep the %d px gap" % [context, int(expected_gap)]
			)
		prior_card = card_rect
		card_count += 1
		_expect_card_geometry(card, context)
	_expect(card_count == 3, "%s renders exactly three complete cards" % context)
	var contract := panel.debug_contract()
	var unique_offer_ids := {}
	for offer_id in Array(contract["offer_ids"]):
		unique_offer_ids[StringName(offer_id)] = true
	_expect(
		int(contract["visible_card_count"]) == 3
			and unique_offer_ids.size() == 3
			and int(contract["command_count"]) == 1
			and int(contract["exit_action_count"]) == 0,
		"%s shows three unique frozen offers and one Equip command" % context
	)
	_expect(
		String(contract["row_type"]) == "HFlowContainer",
		"%s uses one responsive non-scrolling card flow" % context
	)
	for card_contract_variant in Array(contract["cards"]):
		var card_contract := Dictionary(card_contract_variant)
		_expect(
			int(card_contract["header_art_count"]) == 0
				and int(card_contract["body_art_count"]) == 1
				and int(card_contract["category_badge_count"]) == 0
				and Vector2(card_contract["body_art_size"]) == (
					Vector2(88.0, 88.0)
					if compact
					else Vector2(128.0, 128.0)
				),
			"%s card keeps one correctly sized lower artwork" % context
		)
		_expect(
			bool(card_contract["level_visible"])
				and int(card_contract["current_level"])
					< int(card_contract["next_level"])
				and int(card_contract["next_level"])
					<= int(card_contract["max_level"])
				and String(card_contract["level_text"]).contains("→")
				and int(card_contract["value_rows"]) >= 1,
			"%s card always exposes its real current-to-next level" % context
		)
	var expected_panel_scale := (
		{"message":15, "confirm":22}
		if compact
		else {"message":16, "confirm":24}
	)
	_expect(
		Dictionary(contract["type_sizes"]) == expected_panel_scale,
		"%s panel uses the approved type scale" % context
	)
	panel.apply_failed(
		TranslationServer.translate("UPGRADE_MANDATORY_NOTICE")
	)
	await _settle_ui()
	var warning_geometry := panel.debug_geometry_contract()
	var warning_contract := panel.debug_contract()
	var modal_style := _theme.get_stylebox(
		&"panel",
		&"ModalSurface"
	) as StyleBoxFlat
	_expect(
		modal_style != null,
		"%s warning/message uses the shared code-native modal surface"
		% context
	)
	_expect(
		Color(warning_contract["message_color"]).is_equal_approx(Art.DANGER),
		"%s warning/message text uses the semantic danger color" % context
	)
	_expect(
		int(warning_geometry["message_visible_lines"])
			== int(warning_geometry["message_lines"]),
		"%s warning/message keeps every line visible" % context
	)
	center.queue_free()
	await process_frame


func _expect_card_geometry(card: Dictionary, context: String) -> void:
	var card_rect := Rect2(card["rect"]).grow(0.75)
	var content_rect := Rect2(card["content_rect"])
	_expect(card_rect.encloses(content_rect), "%s card content stays inside its frame" % context)
	for label_variant in card["labels"]:
		var label := Dictionary(label_variant)
		var label_rect := Rect2(label["rect"]).grow(0.75)
		var glyph_rect := Rect2(label["glyph_rect"])
		_expect(
			card_rect.encloses(label_rect),
			"%s label stays inside card: %s" % [context, label["text"]]
		)
		_expect(
			label_rect.encloses(glyph_rect),
			"%s shaped glyph bounds stay inside label: %s"
			% [context, label["text"]]
		)
		_expect(
			int(label["visible_line_count"]) == int(label["line_count"]),
			"%s keeps every shaped line visible: %s" % [context, label["text"]]
		)
		if String(label["name"]) == "TitleLabel":
			_expect(
				int(label["line_count"]) <= 2,
				"%s title stays within two lines: %s" % [context, label["text"]]
			)
		elif String(label["name"]) == "SummaryLabel":
			_expect(
				int(label["line_count"])
					<= int(card["summary_max_lines"]),
				"%s summary stays within its %d-line density budget: %s"
				% [
					context,
					int(card["summary_max_lines"]),
					label["text"],
				]
			)
func _offers_from_fixture(
	catalog: VehicleUpgradeCatalog,
	records: Array
) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for record_variant in records:
		var record := Dictionary(record_variant)
		var definition := catalog.get_definition(StringName(record["id"]))
		_expect(definition != null, "fixture upgrade exists: %s" % record["id"])
		if definition == null:
			continue
		offers.append(
			OfferPresenter.snapshot(
				definition,
				int(record["current_level"])
			)
		)
	return offers


func _validate_longest_fixture(
	catalog: VehicleUpgradeCatalog,
	locale: String
) -> void:
	var highest_by_id := {}
	for definition in catalog.all_definitions():
		for current_level in definition.max_level:
			var snapshot := OfferPresenter.snapshot(definition, current_level)
			var score := (
				TranslationServer.translate(String(snapshot["title_key"])).length()
				+ TranslationServer.translate(
					String(snapshot["description_key"])
				).length()
			)
			var prior_score := int(highest_by_id.get(definition.id, -1))
			highest_by_id[definition.id] = maxi(prior_score, score)
	var ranked: Array[Dictionary] = []
	for id_variant in highest_by_id:
		ranked.append({
			"id":StringName(id_variant),
			"score":int(highest_by_id[id_variant]),
		})
	ranked.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["score"]) != int(b["score"]):
				return int(a["score"]) > int(b["score"])
			return String(a["id"]) < String(b["id"])
	)
	var expected_ids := {}
	for index in 3:
		expected_ids[StringName(ranked[index]["id"])] = true
	var fixture_ids := {}
	for record_variant in Array(WORST_TEXT_TRIPLETS[locale]):
		fixture_ids[StringName(Dictionary(record_variant)["id"])] = true
	_expect(
		fixture_ids.size() == 3 and fixture_ids == expected_ids,
		"%s worst-text fixture keeps the three independent longest offers together"
		% locale
	)


func _settle_ui() -> void:
	for _frame in 3:
		await process_frame


func _contrast_ratio(foreground: Color, background: Color) -> float:
	var light := _relative_luminance(foreground)
	var dark := _relative_luminance(background)
	if light < dark:
		var swap := light
		light = dark
		dark = swap
	return (light + 0.05) / (dark + 0.05)


func _relative_luminance(color: Color) -> float:
	return (
		0.2126 * _linear_channel(color.r)
		+ 0.7152 * _linear_channel(color.g)
		+ 0.0722 * _linear_channel(color.b)
	)


func _linear_channel(value: float) -> float:
	return (
		value / 12.92
		if value <= 0.04045
		else pow((value + 0.055) / 1.055, 2.4)
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_UPGRADE_UI_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
