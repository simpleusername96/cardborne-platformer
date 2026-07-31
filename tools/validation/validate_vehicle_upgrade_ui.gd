extends SceneTree

const THEME_PATH := "res://art/ui/production/vehicle_stage_theme.tres"
const FONT_PATH := (
	"res://art/ui/production/fonts/NotoSansKR-Variable.ttf"
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
const UpgradeGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const WORST_TEXT_TRIPLETS := {
	"ko":[
		{"id":&"siphon_matrix", "current_level":1},
		{"id":&"aegis_cycle", "current_level":1},
		{"id":&"marked_salvo", "current_level":0},
	],
	"en":[
		{"id":&"marked_salvo", "current_level":0},
		{"id":&"siphon_matrix", "current_level":1},
		{"id":&"aegis_cycle", "current_level":1},
	],
}
const DENSE_STAT_TRIPLET := [
	{"id":&"stabilizer", "current_level":1},
	{"id":&"emp_focus", "current_level":1},
	{"id":&"mass_driver", "current_level":2},
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
	_validate_glyph_recipes()
	var catalog := Catalog.new()
	await _validate_intent_contract(catalog)
	await _validate_family_badges(catalog)
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
		&"UpgradeChoiceCard"
	) as StyleBoxTexture
	var focus := _theme.get_stylebox(
		&"focus",
		&"UpgradeChoiceCard"
	) as StyleBoxTexture
	var selected := _theme.get_stylebox(
		&"normal",
		&"SelectedUpgradeChoiceCard"
	) as StyleBoxTexture
	_expect(
		normal != null
			and normal.texture.resource_path.ends_with(
				"upgrade_card_normal.png"
			),
		"normal upgrade card uses its authored image state"
	)
	_expect(
		normal != null
			and normal.texture_margin_left == 20.0
			and normal.texture_margin_top == 20.0,
		"upgrade card uses the manifest 9-slice margin"
	)
	_expect(
		focus != null
			and focus.texture.resource_path.ends_with(
				"upgrade_card_focus.png"
			),
		"focused upgrade card uses its authored image state"
	)
	_expect(
		selected != null
			and selected.texture.resource_path.ends_with(
				"upgrade_card_selected.png"
			),
		"selected upgrade card uses its authored image state"
	)


func _validate_glyph_recipes() -> void:
	for error in UpgradeGlyphRenderer.validate_recipes():
		failures.append(error)
	var ids := UpgradeGlyphRenderer.family_ids()
	_expect(ids.size() == 8, "shared renderer exposes all eight upgrade families")
	var seen := {}
	for family in ids:
		seen[family] = true
		var bounds := UpgradeGlyphRenderer.glyph_bounds(family)
		_expect(
			bounds.has_area()
				and bounds.position.x >= -1.1
				and bounds.position.y >= -1.1
				and bounds.end.x <= 1.1
				and bounds.end.y <= 1.1,
			"%s glyph commands stay inside normalized callable bounds" % family
		)
	_expect(seen.size() == 8, "upgrade glyph family IDs are unique")


func _validate_family_badges(catalog: VehicleUpgradeCatalog) -> void:
	var card := UpgradeChoiceCard.new()
	card.theme = _theme
	get_root().add_child(card)
	await process_frame
	card.set_compact_mode(true)
	card.size = card.custom_minimum_size
	for family in UpgradeGlyphRenderer.family_ids():
		var definition := _first_family_definition(catalog, family)
		_expect(definition != null, "%s has a live upgrade card fixture" % family)
		if definition == null:
			continue
		card.set_offer(OfferPresenter.snapshot(definition, 0))
		await process_frame
		var contract := card.debug_contract()
		var badge := Dictionary(contract["family_badge"])
		_expect(
			bool(badge["image_backed"]),
			"%s family badge uses image-backed chrome" % family
		)
		_expect(
			StringName(badge["semantic_accent_owner"]) == &"family_glyph"
				and bool(Dictionary(
					card.debug_geometry_contract()["glyph"]
				)["semantic_asset"]),
			"%s family badge keeps its semantic accent in the image glyph"
			% family
		)
		var geometry := card.debug_geometry_contract()
		_expect_glyph_geometry(
			Dictionary(geometry["glyph"]),
			card.get_global_rect(),
			"%s family badge" % family
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
	var decline_events: Array[bool] = []
	panel.selected.connect(
		func(upgrade_id: StringName) -> void:
			selected_ids.append(upgrade_id)
	)
	panel.confirmed.connect(
		func(upgrade_id: StringName) -> void:
			confirmed_ids.append(upgrade_id)
	)
	panel.declined.connect(func() -> void: decline_events.append(true))
	panel.open(offers, false)
	panel.call("_select", 0)
	_expect(
		selected_ids.is_empty(),
		"upgrade input guard rejects carried selection"
	)
	panel.call("_process", 0.36)
	panel.call("_select", 0)
	panel.call("_confirm_selected")
	_expect(
		selected_ids == [StringName(offers[0]["id"])]
			and confirmed_ids == [StringName(offers[0]["id"])],
		"upgrade panel emits selection and confirmation intent without applying"
	)
	panel.apply_failed("retry")
	panel.open(offers, true)
	panel.call("_process", 0.36)
	panel.call("_request_decline")
	_expect(decline_events.is_empty(), "optional decline keeps its confirmation guard")
	panel.call("_request_decline")
	_expect(decline_events.size() == 1, "optional decline emits intent after confirmation")
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
	_expect(snapshot_count == 83, "worst-case fixture is grounded in all 83 card states")
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
		minf(960.0, float(viewport.x) - 48.0),
		minf(626.0, float(viewport.y) - 24.0)
	)
	center.add_child(surface)
	var panel := UpgradeChoicePanel.new()
	surface.add_child(panel)
	await _settle_ui()
	var compact := viewport.x < Art.BREAKPOINT_WIDE or viewport.y < 650
	panel.set_compact_mode(compact)
	panel.open(offers, false)
	await _settle_ui()
	var geometry := panel.debug_geometry_contract()
	var panel_rect := Rect2(geometry["rect"]).grow(0.75)
	var row_rect := Rect2(geometry["row_rect"]).grow(0.75)
	var surface_rect := surface.get_global_rect().grow(0.75)
	_expect(surface_rect.encloses(panel_rect), "%s panel stays inside its surface" % context)
	var expected_size := (
		Vector2(244.0, 286.0)
		if compact
		else Vector2(304.0, 330.0)
	)
	var expected_gap := 12.0 if compact else 18.0
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
	_expect(
		int(geometry["detail_visible_lines"]) == int(geometry["detail_lines"]),
		"%s keeps every instruction line visible" % context
	)
	var contract := panel.debug_contract()
	var expected_panel_scale := (
		{"kicker":15, "title":30, "detail":15, "message":15, "confirm":22}
		if compact
		else {"kicker":16, "title":40, "detail":18, "message":16, "confirm":24}
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
	) as StyleBoxTexture
	_expect(
		modal_style != null
			and modal_style.texture.resource_path.ends_with(
				"modal_master_normal.png"
			),
		"%s warning/message uses the authored modal image surface"
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
	_expect_glyph_geometry(
		Dictionary(card["glyph"]),
		Rect2(card["rect"]),
		context
	)


func _expect_glyph_geometry(
	glyph: Dictionary,
	card_rect: Rect2,
	context: String
) -> void:
	var control_rect := Rect2(glyph["control_rect"]).grow(0.5)
	var content_rect := Rect2(glyph["content_rect"])
	_expect(
		int(glyph["command_count"]) >= 3,
		"%s glyph has a complete multi-plane recipe" % context
	)
	_expect(
		control_rect.encloses(content_rect),
		"%s glyph commands stay inside their control" % context
	)
	_expect(
		card_rect.grow(0.5).encloses(content_rect),
		"%s glyph commands stay inside the card" % context
	)


func _first_family_definition(
	catalog: VehicleUpgradeCatalog,
	family: StringName
) -> VehicleUpgradeDefinition:
	for definition in catalog.all_definitions():
		if definition.family == family:
			return definition
	return null


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
					String(snapshot["summary_key"])
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
