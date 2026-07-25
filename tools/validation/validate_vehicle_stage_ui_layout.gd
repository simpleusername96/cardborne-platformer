extends SceneTree

const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const MinimapMeshBuilder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var ui := StageUI.new()
	get_root().add_child(ui)
	await process_frame
	for width in [960.0, 1280.0, 1920.0]:
		var contract := ui.debug_ui_contract(width)
		_expect(Vector2(contract["action_rail_size"]) == Vector2(154.0, 34.0), "action rail size is fixed at %d" % width)
		_expect(Vector2(contract["action_rail_position"]) == Vector2(18.0, 76.0), "action rail stays below hull at %d" % width)
		_expect(bool(contract["action_rail_icon_only"]), "action rail contains icons only at %d" % width)
		_expect(bool(contract["top_clusters_do_not_overlap"]), "top clusters do not overlap at %d" % width)
		_expect(bool(contract["central_safe_clear"]), "central play space remains clear at %d" % width)
		var upgrade_contract := Dictionary(contract["upgrade_choice"])
		_expect(bool(upgrade_contract["structured_cards"]), "upgrade choices use structured card components at %d" % width)
		_expect(int(upgrade_contract["card_count"]) == 3, "upgrade choice keeps exactly three card slots at %d" % width)
		_expect(Vector2(upgrade_contract["confirm_size"]) == Vector2(300.0, 48.0), "upgrade confirmation uses the compact command contract at %d" % width)
		for card_variant in upgrade_contract["cards"]:
			var card := Dictionary(card_variant)
			var card_size := Vector2(card["minimum_size"])
			_expect(
				card_size.x >= 280.0 and card_size.y >= 330.0,
				"upgrade cards preserve the selected large-card hierarchy at %d" % width
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
