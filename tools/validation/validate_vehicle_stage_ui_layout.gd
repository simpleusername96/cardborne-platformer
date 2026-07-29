extends SceneTree

const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const MinimapMeshBuilder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")
const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var ui := StageUI.new()
	get_root().add_child(ui)
	await process_frame
	for width in [960.0, 1280.0, 1920.0]:
		var viewport_size := Vector2i(roundi(width), roundi(width * 9.0 / 16.0))
		get_root().content_scale_size = viewport_size
		get_root().size = viewport_size
		await process_frame
		var contract := ui.debug_ui_contract(width)
		var chrome := Dictionary(contract["ui_chrome"])
		_expect(bool(chrome["loaded"]), "published UI chrome recipe loads at %d" % width)
		_expect(int(chrome["style_count"]) == 17, "all 17 UI chrome assets load at %d" % width)
		_expect(Array(chrome["errors"]).is_empty(), "UI chrome has no asset contract errors at %d" % width)
		var image_backed := Dictionary(contract["image_backed_chrome"])
		for surface in ["modal", "hud", "button", "upgrade_card", "tab"]:
			_expect(
				bool(image_backed[surface]),
				"%s chrome is image-backed at %d" % [surface, width]
			)
		var action_rail_size := Vector2(contract["action_rail_size"])
		var action_rail_position := Vector2(contract["action_rail_position"])
		_expect(action_rail_size == Vector2(148.0, 44.0), "action rail size is fixed at %d" % width)
		_expect(
			is_equal_approx(action_rail_position.x, (width - action_rail_size.x) * 0.5)
				and is_equal_approx(action_rail_position.y, width * 9.0 / 16.0 - 64.0),
			"action rail stays centered at the bottom at %d" % width
		)
		_expect(bool(contract["action_rail_icon_only"]), "action rail contains icons only at %d" % width)
		_expect(int(contract["action_slot_count"]) == 3, "action rail contains three auxiliary actions at %d" % width)
		_expect(not bool(contract["shows_primary_slot"]), "primary fire is omitted from the action rail at %d" % width)
		_expect(Vector2(contract["secondary_slot_size"]) == Vector2(44.0, 44.0), "action icons remain readable at %d" % width)
		_expect(bool(contract["top_clusters_do_not_overlap"]), "top clusters do not overlap at %d" % width)
		_expect(bool(contract["central_safe_clear"]), "central play space remains clear at %d" % width)
		var upgrade_contract := Dictionary(contract["upgrade_choice"])
		_expect(bool(upgrade_contract["structured_cards"]), "upgrade choices use structured card components at %d" % width)
		_expect(int(upgrade_contract["card_count"]) == 3, "upgrade choice keeps exactly three card slots at %d" % width)
		_expect(
			Vector2(upgrade_contract["confirm_size"]) == (
				Vector2(260.0, 42.0) if width < 1100.0 else Vector2(300.0, 48.0)
			),
			"upgrade confirmation uses the supported command contract at %d" % width
		)
		for card_variant in upgrade_contract["cards"]:
			var card := Dictionary(card_variant)
			var card_size := Vector2(card["minimum_size"])
			_expect(
				(
					card_size == Vector2(276.0, 290.0)
					if width < 1100.0
					else card_size.x >= 280.0 and card_size.y >= 330.0
				),
				"upgrade cards use the supported hierarchy at %d" % width
			)
		_expect(bool(contract["has_upgrade_card_theme"]), "upgrade cards use dedicated shared theme states at %d" % width)
		_expect(bool(contract["has_tertiary_danger_theme"]), "tertiary danger uses a shared theme state at %d" % width)
		_expect(int(contract["display_font_size"]) >= 40, "display typography remains legible at %d" % width)
		_expect(Vector2(contract["deployment_primary_size"]) == Vector2(300.0, 48.0), "deployment uses one compact primary action at %d" % width)
		var deployment_surface := Vector2(contract["deployment_surface_size"])
		_expect(
			deployment_surface.x <= width - 48.0
				and deployment_surface.y <= width * 9.0 / 16.0 - 24.0,
			"deployment surface stays inside the supported viewport at %d" % width
		)
		if is_equal_approx(width, 1280.0):
			_expect(
				deployment_surface == Vector2(1176.0, 636.0),
				"deployment uses the approved broad 1280x720 composition"
			)
			var modal_minimums := Dictionary(contract["modal_minimums"])
			_expect(Vector2(modal_minimums["upgrade"]) == Vector2(960.0, 626.0), "upgrade modal keeps approved scale")
			_expect(Vector2(modal_minimums["pause"]) == Vector2(640.0, 380.0), "pause modal avoids the old empty panel")
			_expect(Vector2(modal_minimums["settings"]) == Vector2(920.0, 570.0), "settings modal keeps approved scale")
			_expect(Vector2(modal_minimums["guidebook"]) == Vector2(1160.0, 636.0), "guidebook modal keeps approved scale")
		_expect(
			StringName(contract["pause_abort_variation"]) == &"TertiaryDangerButton",
			"pause abort remains a restrained tertiary action at %d" % width
		)
		var minimap_size := Vector2(contract["minimap_size"])
		_expect(minimap_size.x >= 160.0 and minimap_size.y >= 98.0, "minimap keeps tactical area at %d" % width)
	ui.update_hud({
		"dash_available":false,
		"dash_ratio":0.75,
		"passive_available":false,
		"passive_ratio":0.5,
		"skill_available":false,
		"skill_ratio":1.0,
	})
	var cooldown_contract := ui.debug_ui_contract(1280.0)
	for slot_variant in cooldown_contract["action_slot_contracts"]:
		var slot := Dictionary(slot_variant)
		_expect(not bool(slot["interior_filled"]), "cooldown action circles keep an empty interior")
		_expect(not bool(slot["has_text"]), "action circles do not render labels")
	ui.update_hud({
		"dash_available":true,
		"dash_ratio":0.0,
		"passive_available":true,
		"passive_ratio":0.0,
		"skill_available":true,
		"skill_ratio":0.0,
	})
	var ready_contract := ui.debug_ui_contract(1280.0)
	for slot_variant in ready_contract["action_slot_contracts"]:
		_expect(bool(Dictionary(slot_variant)["interior_filled"]), "ready action circles use the filled state")
	await _validate_upgrade_matrix(ui)
	var tactical_mesh := MinimapMeshBuilder.build({
		"cols":13,
		"rows":6,
		"visited":[Vector2i(6, 3)],
		"world_size":Vector2(5200.0, 2200.0),
		"player":Vector2(2600.0, 1100.0),
		"player_facing":Vector2.RIGHT,
		"markers":[
			{"kind":"elite", "position":Vector2(2300.0, 1000.0), "discovered":true, "color":Color.RED},
			{"kind":"pickup", "position":Vector2(2800.0, 1200.0), "discovered":true, "color":Color.GREEN},
		],
		"enemy_clusters":[{
			"cell":Vector2i(5, 3),
			"count":5,
			"average_velocity":Vector2(100.0, 0.0),
		}],
		"support_fields":[{
			"state":&"active",
			"position":Vector2(3000.0, 1000.0),
			"kind":&"repair",
			"phase_progress":0.5,
		}],
	}, Vector2(176.0, 108.0))
	_expect(tactical_mesh != null, "tactical minimap compiles a dynamic marker mesh")
	_expect(
		tactical_mesh != null and tactical_mesh.get_surface_count() == 1,
		"tactical minimap publishes all dynamic markers through one mesh surface"
	)
	ui.queue_free()
	await process_frame
	_finish()


func _validate_upgrade_matrix(ui: VehicleStageUI) -> void:
	var catalog := Catalog.new()
	var snapshots: Array[Dictionary] = []
	for definition in catalog.all_definitions():
		for current_level in definition.max_level:
			snapshots.append(OfferPresenter.snapshot(definition, current_level))
	_expect(snapshots.size() == 91, "layout matrix contains all 91 card/level states")
	var safe_card := snapshots[0]
	var original_locale := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for viewport in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
			get_root().content_scale_size = viewport
			get_root().size = viewport
			await process_frame
			for snapshot in snapshots:
				for slot in 3:
					var offer: Array[Dictionary] = [
						safe_card.duplicate(true),
						safe_card.duplicate(true),
						safe_card.duplicate(true),
					]
					offer[slot] = snapshot
					ui.show_upgrade(offer)
					await process_frame
					_expect_upgrade_geometry(
						ui.debug_upgrade_geometry(),
						"%s %s slot %d unselected" % [locale, snapshot["id"], slot + 1]
					)
					ui.debug_select_upgrade(slot)
					await process_frame
					_expect_upgrade_geometry(
						ui.debug_upgrade_geometry(),
						"%s %s slot %d selected" % [locale, snapshot["id"], slot + 1]
					)
	TranslationServer.set_locale(original_locale)


func _expect_upgrade_geometry(contract: Dictionary, context: String) -> void:
	var viewport_rect := Rect2(contract["viewport_rect"]).grow(0.5)
	var surface_rect := Rect2(contract["surface_rect"])
	_expect(viewport_rect.encloses(surface_rect), "%s modal stays inside viewport" % context)
	var panel := Dictionary(contract["panel"])
	var panel_rect := Rect2(panel["rect"]).grow(0.5)
	_expect(surface_rect.grow(0.5).encloses(panel_rect), "%s content stays inside modal" % context)
	_expect(
		int(panel["detail_visible_lines"]) == int(panel["detail_lines"]),
		"%s selected detail keeps every wrapped line visible" % context
	)
	var prior_card := Rect2()
	for card_variant in panel["cards"]:
		var card := Dictionary(card_variant)
		var card_rect := Rect2(card["rect"])
		_expect(panel_rect.encloses(card_rect), "%s card stays inside panel" % context)
		if prior_card.has_area():
			_expect(not prior_card.intersects(card_rect), "%s cards do not overlap" % context)
		prior_card = card_rect
		for label_variant in card["labels"]:
			var label := Dictionary(label_variant)
			var label_rect := Rect2(label["rect"])
			_expect(
				card_rect.grow(0.5).encloses(label_rect),
				"%s card text stays inside card: %s" % [context, label["text"]]
			)
			_expect(
				int(label["visible_line_count"]) == int(label["line_count"]),
				"%s card keeps every wrapped line visible: %s" % [context, label["text"]]
			)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STAGE_UI_LAYOUT_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
