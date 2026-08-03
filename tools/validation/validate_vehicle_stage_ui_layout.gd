extends SceneTree

const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const MinimapMeshBuilder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")
const RetainedMinimapMesh = preload("res://scripts/ui/vehicle_retained_minimap_mesh.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const VehicleRun = preload("res://scripts/vehicle/vehicle_run.gd")
const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const OfferPresenter = preload("res://scripts/cards/vehicle_upgrade_offer_presenter.gd")
const UiGlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	for error in UiGlyphCatalog.validate_action_recipes():
		failures.append("shared action glyph recipe: %s" % error)
	_validate_action_glyph_meshes()
	var ui := StageUI.new()
	get_root().add_child(ui)
	await process_frame
	for width in [960.0, 1280.0, 1920.0]:
		var viewport_size := Vector2i(roundi(width), roundi(width * 9.0 / 16.0))
		get_root().content_scale_size = viewport_size
		get_root().size = viewport_size
		await process_frame
		var contract := ui.debug_ui_contract(width)
		var foundation := Dictionary(contract["ui_foundation"])
		_expect(bool(foundation["loaded"]), "shared UI foundation loads at %d" % width)
		_expect(
			int(foundation["modal_surface_count"]) >= 8,
			"all modals use the shared root surface at %d" % width
		)
		var modal_frame := Dictionary(foundation["modal_frame"])
		_expect(
			not bool(modal_frame.get("layered_depth", true))
				and not bool(modal_frame.get("image_backed", true))
				and is_equal_approx(
					float(modal_frame.get("corner_cut", 0.0)),
					3.0
				)
				and int(modal_frame.get("root_surface_count", 0)) == 1,
			"modal surfaces keep one simple code-native frame at %d"
			% width
		)
		_expect(
			int(foundation["texture_filter"]) == CanvasItem.TEXTURE_FILTER_LINEAR,
			"UI foundation uses antialiased linear filtering at %d" % width
		)
		var shared_styles := Dictionary(contract["shared_style_foundation"])
		for surface in ["modal", "hud", "button", "upgrade_card", "tab"]:
			_expect(
				bool(shared_styles[surface]),
				"%s uses shared code-native chrome at %d"
				% [surface, width]
			)
		_expect(
			int(shared_styles["non_code_native_style_count"]) == 0,
			"shared Theme uses only code-native StyleBox types at %d" % width
		)
		var action_rail_size := Vector2(contract["action_rail_size"])
		var action_rail_position := Vector2(contract["action_rail_position"])
		_expect(action_rail_size == Vector2(168.0, 60.0), "action rail contains three 44 px targets plus shared surface margins at %d" % width)
		_expect(
			is_equal_approx(action_rail_position.x, (width - action_rail_size.x) * 0.5)
				and is_equal_approx(action_rail_position.y, width * 9.0 / 16.0 - 80.0),
			"action rail stays centered at the bottom at %d" % width
		)
		var health_meter := Dictionary(contract["health_meter"])
		_expect(
			bool(health_meter["code_drawn"])
				and not bool(health_meter["image_backed"])
				and bool(health_meter["has_background_geometry"])
				and bool(health_meter["has_trailing_health_geometry"])
				and bool(health_meter["has_health_geometry"])
				and bool(health_meter["has_experience_geometry"]),
			"health and XP meters use complete code-native geometry at %d" % width
		)
		_expect(
			int(contract["zone_surface_count"]) == 4
				and Array(contract["zone_surface_variations"]) == [
					&"HudSurface", &"HudSurface", &"HudSurface", &"HudSurface",
				]
				and StringName(contract["toast_surface_variation"]) == &"ToastSurface",
			"HUD uses four shared zones and one shared toast at %d" % width
		)
		_expect(
			not bool(contract["conditional_clusters_have_backing"])
				and bool(contract["boss_inside_objective_zone"])
				and bool(contract["target_inside_minimap_zone"])
				and not bool(contract["raster_chrome_consumer"]),
			"boss and target reuse their owning zones without raster or nested backing at %d" % width
		)
		_expect(bool(contract["action_rail_icon_only"]), "action rail contains icons only at %d" % width)
		_expect(int(contract["action_slot_count"]) == 3, "action rail contains three auxiliary actions at %d" % width)
		_expect(not bool(contract["shows_primary_slot"]), "primary fire is omitted from the action rail at %d" % width)
		_expect(Vector2(contract["secondary_slot_size"]) == Vector2(44.0, 44.0), "action icons remain readable at %d" % width)
		for status_name in Dictionary(contract["status_font_sizes"]):
			_expect(
				int(contract["status_font_sizes"][status_name]) >= 14,
				"%s HUD status typography stays at or above 14 px at %d"
				% [status_name, width]
			)
		_expect(bool(contract["top_clusters_do_not_overlap"]), "top clusters do not overlap at %d" % width)
		_expect(bool(contract["central_safe_clear"]), "central play space remains clear at %d" % width)
		var upgrade_contract := Dictionary(contract["upgrade_choice"])
		_expect(bool(upgrade_contract["structured_cards"]), "upgrade choices use structured card components at %d" % width)
		_expect(int(upgrade_contract["card_count"]) == 3, "upgrade choice keeps exactly three card slots at %d" % width)
		_expect(
			Vector2(upgrade_contract["confirm_size"]) == (
				Vector2(300.0, 48.0) if width < 1100.0 else Vector2(360.0, 56.0)
			),
			"upgrade confirmation uses the supported command contract at %d" % width
		)
		_expect(
			String(upgrade_contract["row_type"]) == "HFlowContainer"
				and int(upgrade_contract["row_separation"]) == (
					12 if width < 1100.0 else 20
				),
			"upgrade cards use the approved responsive flow and gap at %d" % width
		)
		var panel_type_sizes := Dictionary(upgrade_contract["type_sizes"])
		_expect(
			panel_type_sizes == (
				{
					"message":15,
					"confirm":22,
				}
				if width < 1100.0
				else {
					"message":16,
					"confirm":24,
				}
			),
			"upgrade panel uses the approved responsive type scale at %d"
			% width
		)
		for card_variant in upgrade_contract["cards"]:
			var card := Dictionary(card_variant)
			var card_size := Vector2(card["minimum_size"])
			_expect(
				(
					card_size == Vector2(280.0, 378.0)
					if width < 1100.0
					else card_size == Vector2(352.0, 432.0)
				),
				"upgrade cards use the supported hierarchy at %d" % width
			)
			_expect(
				Dictionary(card["type_sizes"]) == (
					{
						"family":13,
						"level":15,
						"title":22,
						"summary":14,
						"behavior":13,
					}
					if width < 1100.0
					else {
						"family":16,
						"level":18,
						"title":28,
						"summary":16,
						"behavior":15,
					}
				),
				"upgrade card uses the approved responsive type scale at %d"
				% width
			)
			var state_cues := Dictionary(card["state_cues"])
			_expect(
				bool(state_cues["normal_flat"])
					and bool(state_cues["focus_flat"])
					and bool(state_cues["selected_corner"])
					and bool(state_cues["focus_corner"])
					and bool(state_cues["disabled_corner"]),
				"upgrade card uses shared code-native non-color states at %d"
				% width
			)
			_expect(int(card["effect_rows"]) <= 2, "upgrade card has at most two effect rows")
			_expect(
				bool(card["dossier_split"])
					and int(card["body_divider_count"]) == 1,
				"upgrade card uses one split dossier and one body divider"
			)
			_expect(
				bool(card["level_visible"])
					and int(card["current_level"]) < int(card["next_level"])
					and int(card["next_level"]) <= int(card["max_level"])
					and int(card["value_rows"]) >= 1,
				"upgrade card always shows a real current-to-next level at %d" % width
			)
			_expect(not bool(card["has_scroll"]), "upgrade card never scrolls")
		_expect(bool(contract["has_selectable_theme"]), "upgrade cards use the public shared Selectable states at %d" % width)
		_expect(bool(contract["has_danger_theme"]), "garage exit uses the public shared danger state at %d" % width)
		_expect(
			is_equal_approx(float(contract["body_font_weight"]), 650.0),
			"shared UI body typography uses weight 650 at %d" % width
		)
		_expect(int(contract["display_font_size"]) >= 40, "display typography remains legible at %d" % width)
		_expect(
			Vector2(contract["deployment_primary_size"]) == (
				Vector2(260.0, 44.0)
				if width < 1100.0
				else Vector2(300.0, 48.0)
			),
			"deployment uses one responsive primary action at %d; got %s compact=%s"
			% [
				width,
				contract["deployment_primary_size"],
				contract["deployment_compact"],
			]
		)
		_expect(
			not bool(contract["deployment_has_difficulty_ui"]),
			"deployment exposes no difficulty UI at %d" % width
		)
		_expect(
			int(contract["deployment_control_rows"]) == 4,
			"deployment preserves four complete control rows at %d" % width
		)
		_expect(
			StringName(contract["deployment_preview_asset_id"])
				== &"attachment/player_craft_body"
				and is_equal_approx(
					float(contract["deployment_preview_rotation"]),
					-PI / 2.0
				),
			"deployment reuses the craft body with presentation-only nose-up rotation at %d"
			% width
		)
		_expect(
			is_equal_approx(
				float(Array(contract["deployment_body_ratios"])[0]),
				0.4
			)
				and is_equal_approx(
					float(Array(contract["deployment_body_ratios"])[1]),
					0.6
				),
			"deployment body keeps the approved 40/60 columns at %d; got %s"
			% [width, contract["deployment_body_ratios"]]
		)
		_expect(
			bool(contract["deployment_fixed_header"])
				and bool(contract["deployment_fixed_footer"])
				and int(contract["deployment_body_scroll"]) == (
					ScrollContainer.SCROLL_MODE_AUTO
					if width < 1100.0
					else ScrollContainer.SCROLL_MODE_DISABLED
				),
			"deployment keeps a fixed header/footer and body-only compact scrolling at %d; got %s/%s mode=%s compact=%s"
			% [
				width,
				contract["deployment_fixed_header"],
				contract["deployment_fixed_footer"],
				contract["deployment_body_scroll"],
				contract["deployment_compact"],
			]
		)
		var deployment_action_order := Array(contract["deployment_action_order"])
		var deployment_action_variations := Array(
			contract["deployment_action_variations"]
		)
		var expected_deployment_actions := ["DeployButton", "SettingsButton"]
		if OS.is_debug_build():
			expected_deployment_actions.append("BossPracticeButton")
		var secondary_roles_only := true
		for variation in deployment_action_variations.slice(1):
			secondary_roles_only = (
				secondary_roles_only and String(variation) == "SecondaryButton"
			)
		_expect(
			String(contract["deployment_action_row_type"]) == "HBoxContainer"
				and int(contract["deployment_action_count"])
					== expected_deployment_actions.size()
				and deployment_action_order == expected_deployment_actions
				and deployment_action_variations[0] == "PrimaryButton"
				and secondary_roles_only,
			"deployment flattens all visible actions into one ordered row at %d"
			% width
		)
		_expect(
			int(contract["garage_columns"]) == 2
				and int(contract["garage_rows"]) == 5
				and not bool(contract["garage_nested_summary_panel"]),
			"garage uses two unboxed shared-row columns at %d" % width
		)
		_expect(
			String(contract["garage_primary_action"]) == "GARAGE_LAUNCH"
				and String(contract["garage_secondary_action"])
					== "GARAGE_SETTINGS",
			"garage exposes only Deployment Setup and Settings at %d" % width
		)
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
			_expect(Vector2(modal_minimums["upgrade"]) == Vector2(1160.0, 580.0), "upgrade modal fits the selected wide dossier card flow without a header")
			_expect(Vector2(modal_minimums["pause"]) == Vector2(520.0, 430.0), "pause modal uses the compact vertical-stack contract")
			_expect(Vector2(modal_minimums["settings"]) == Vector2(920.0, 570.0), "settings modal keeps approved scale")
			_expect(Vector2(modal_minimums["guidebook"]) == Vector2(1160.0, 636.0), "guidebook modal keeps approved scale")
			_expect(Vector2(modal_minimums["report"]) == Vector2(1200.0, 640.0), "report modal keeps all three metric columns visible")
		_expect(
			StringName(contract["pause_abort_variation"]) == &"DangerButton",
			"pause abort uses the shared restrained danger role at %d" % width
		)
		_expect(
			String(contract["pause_command_stack_type"]) == "VBoxContainer"
				and Array(contract["pause_command_order"]) == [
					"PAUSE_RESUME",
					"PAUSE_RESTART",
					"PAUSE_SETTINGS",
					"PAUSE_ABORT",
				],
			"pause commands keep the required vertical order at %d" % width
		)
		for command_width in Array(contract["pause_command_widths"]):
			_expect(
				is_equal_approx(float(command_width), 360.0),
				"pause commands share one width at %d" % width
			)
		var minimap_size := Vector2(contract["minimap_size"])
		_expect(minimap_size.x >= 160.0 and minimap_size.y >= 98.0, "minimap keeps tactical area at %d" % width)
	ui.update_hud({
		"dash_available":false,
		"dash_ratio":0.75,
		"seeker_available":false,
		"seeker_ratio":0.5,
		"skill_available":false,
		"skill_ratio":1.0,
	})
	var cooldown_contract := ui.debug_ui_contract(1280.0)
	var cooldown_glyph_ids: Array[StringName] = []
	for slot_variant in cooldown_contract["action_slot_contracts"]:
		var slot := Dictionary(slot_variant)
		cooldown_glyph_ids.append(StringName(slot["glyph_id"]))
		_expect(not bool(slot["interior_filled"]), "cooldown action circles keep an empty interior")
		_expect(not bool(slot["has_text"]), "action circles do not render labels")
		_expect(
			not bool(slot["image_backed"])
				and bool(slot["state_code_drawn"])
				and bool(slot["disabled_not_color_only"])
				and bool(slot["disabled_has_structural_slash"]),
			"disabled action slots use code-native non-color structural cues"
		)
		_expect(
			bool(slot["cooldown_has_structural_arc"])
				== (float(slot["cooldown_ratio"]) < 0.9999),
			"cooldown arc visibility matches the authored ratio"
		)
		_expect(int(slot["draw_batches"]) <= 2, "each action glyph uses one retained mesh plus at most one cooldown arc")
		_expect(
			bool(slot["shared_glyph_recipe"])
				and int(slot["glyph_command_count"]) >= 3,
			"action identity uses a complete shared glyph recipe"
		)
	_expect(
		cooldown_glyph_ids == [&"seeker", &"dash", &"emp"],
		"action rail keeps seeker, dash, and EMP in their authored order"
	)
	ui.update_hud({
		"dash_available":true,
		"dash_ratio":0.0,
		"seeker_available":true,
		"seeker_ratio":0.0,
		"skill_available":true,
		"skill_ratio":0.0,
	})
	var ready_contract := ui.debug_ui_contract(1280.0)
	for slot_variant in ready_contract["action_slot_contracts"]:
		var slot := Dictionary(slot_variant)
		_expect(
			not bool(slot["image_backed"])
				and bool(slot["state_code_drawn"])
				and bool(slot["semantic_icon_image_retained"])
				and bool(slot["available_has_structural_rail"])
				and not bool(slot["disabled_has_structural_slash"])
				and not bool(slot["interior_filled"]),
			"ready action slots use code-native structure around semantic icons"
		)
	await _validate_modal_matrix(ui)
	await _validate_upgrade_matrix(ui)
	await _validate_text_scale_probe(ui)
	_validate_owner_boundaries()
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
	var minimap_palette := MinimapMeshBuilder.dynamic_colors()
	var palette_markers: Array[Dictionary] = []
	for index in minimap_palette.size():
		palette_markers.append({
			"kind":"point",
			"position":Vector2(400.0 + index * 420.0, 900.0),
			"discovered":true,
			"color":minimap_palette[index],
		})
	var retained_snapshot := {
		"cols":13,
		"rows":6,
		"visited":[Vector2i(6, 3)],
		"world_size":Vector2(5200.0, 2200.0),
		"player":Vector2(2600.0, 1100.0),
		"player_facing":Vector2.RIGHT,
		"markers":palette_markers,
		"enemy_clusters":[],
		"support_fields":[],
	}
	var retained_map := RetainedMinimapMesh.new(Vector2(176.0, 108.0))
	var retained_mesh_id := retained_map.mesh.get_instance_id()
	retained_map.update(retained_snapshot)
	var palette_contract := retained_map.debug_snapshot()
	var palette_counts := Dictionary(palette_contract["visible_vertices_by_color"])
	for color in minimap_palette:
		_expect(
			int(palette_counts.get(color.to_rgba32(), 0)) > 0,
			"retained minimap supports palette channel %s"
			% color.to_html(true)
		)
	retained_snapshot["markers"] = []
	retained_map.update(retained_snapshot)
	var cleared_counts := Dictionary(
		retained_map.debug_snapshot()["visible_vertices_by_color"]
	)
	_expect(
		int(cleared_counts.get(minimap_palette[5].to_rgba32(), 0)) == 0,
		"retained minimap clears channels that leave the snapshot"
	)
	var pressure_markers: Array[Dictionary] = []
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		pressure_markers.append({
			"kind":"elite",
			"position":Vector2(
				300.0 + float(index % 32) * 140.0,
				300.0 + float(index / 32) * 140.0
			),
			"discovered":true,
			"color":minimap_palette[5],
		})
	retained_snapshot["cols"] = VehicleRun.MINIMAP_COLS
	retained_snapshot["rows"] = VehicleRun.MINIMAP_ROWS
	retained_snapshot["markers"] = pressure_markers
	retained_snapshot["enemy_clusters"] = []
	var danger_key := minimap_palette[5].to_rgba32()
	var all_marker_channels := MinimapMeshBuilder.build_triangle_channels(
		retained_snapshot,
		Vector2(176.0, 108.0)
	)
	var all_marker_compiled: PackedVector3Array = all_marker_channels.get(
		danger_key,
		PackedVector3Array()
	)
	retained_map.update(retained_snapshot)
	var all_marker_contract := retained_map.debug_snapshot()
	var all_marker_counts := Dictionary(
		all_marker_contract["visible_vertices_by_color"]
	)
	var all_marker_retained := int(all_marker_counts.get(danger_key, 0))
	_expect(
		pressure_markers.size() == EnemyStore.MAX_LIVE_HOSTILES
			and all_marker_compiled.size() > 3500
			and all_marker_compiled.size()
				<= int(all_marker_contract["vertices_per_color"])
			and all_marker_retained == all_marker_compiled.size(),
		"retained minimap preserves every marker at the 320-hostile capacity"
	)
	var pressure_clusters: Array[Dictionary] = []
	for row in VehicleRun.MINIMAP_ROWS:
		for column in VehicleRun.MINIMAP_COLS:
			pressure_clusters.append({
				"cell":Vector2i(column, row),
				"count":1,
				"average_velocity":Vector2(100.0, 0.0),
			})
	var mixed_marker_count := (
		EnemyStore.MAX_LIVE_HOSTILES - pressure_clusters.size()
	)
	var mixed_pressure_markers: Array[Dictionary] = []
	mixed_pressure_markers.assign(
		pressure_markers.slice(0, mixed_marker_count)
	)
	retained_snapshot["markers"] = mixed_pressure_markers
	retained_snapshot["enemy_clusters"] = pressure_clusters
	var mixed_channels := MinimapMeshBuilder.build_triangle_channels(
		retained_snapshot,
		Vector2(176.0, 108.0)
	)
	var mixed_compiled: PackedVector3Array = mixed_channels.get(
		danger_key,
		PackedVector3Array()
	)
	retained_map.update(retained_snapshot)
	var mixed_contract := retained_map.debug_snapshot()
	var mixed_counts := Dictionary(
		mixed_contract["visible_vertices_by_color"]
	)
	var mixed_retained := int(mixed_counts.get(danger_key, 0))
	_expect(
		pressure_clusters.size()
				== VehicleRun.MINIMAP_COLS * VehicleRun.MINIMAP_ROWS
			and mixed_pressure_markers.size() + pressure_clusters.size()
				== EnemyStore.MAX_LIVE_HOSTILES
			and mixed_compiled.size() > 3500
			and mixed_compiled.size()
				<= int(mixed_contract["vertices_per_color"])
			and mixed_retained == mixed_compiled.size(),
		"retained minimap preserves a full 20x12 cluster grid inside 320 hostile slots"
	)
	retained_snapshot["player"] = Vector2(2800.0, 1200.0)
	retained_map.update(retained_snapshot)
	var retained_contract := retained_map.debug_snapshot()
	_expect(
		retained_map.mesh.get_instance_id() == retained_mesh_id,
		"tactical minimap updates one retained GPU resource"
	)
	_expect(
		int(retained_contract["surface_count"]) == 1
			and int(retained_contract["visible_vertices"]) > 0
			and int(retained_contract["vertices_per_color"]) % 3 == 0,
		"retained minimap publishes aligned bounded triangle channels"
	)
	ui.queue_free()
	await process_frame
	_finish()


func _validate_action_glyph_meshes() -> void:
	for action_id in UiGlyphCatalog.action_ids():
		var vertices := PackedVector3Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		var command_count := UiGlyphCatalog.append_action_mesh_geometry(
			vertices,
			colors,
			indices,
			action_id,
			Vector2(22.0, 22.0),
			10.5,
			{
				&"primary":Color.WHITE,
				&"secondary":Color.GRAY,
				&"highlight":Color.LIGHT_GRAY,
			}
		)
		var recipe_commands := Array(
			UiGlyphCatalog.action_descriptor(action_id).get("commands", [])
		)
		_expect(
			command_count == recipe_commands.size()
				and not vertices.is_empty()
				and colors.size() == vertices.size()
				and indices.size() >= 3
				and indices.size() % 3 == 0,
			"%s action recipe compiles into retained triangle geometry"
			% action_id
		)
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_expect(
			mesh.get_surface_count() == 1,
			"%s action identity stays inside one retained mesh surface"
			% action_id
		)


func _validate_modal_matrix(ui: VehicleStageUI) -> void:
	var original_locale := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for viewport in [
			Vector2i(960, 540),
			Vector2i(1280, 720),
			Vector2i(1920, 1080),
		]:
			get_root().content_scale_size = viewport
			get_root().size = viewport
			await _settle_ui()
			for surface in [
				"deployment",
				"upgrade",
				"pause",
				"result",
				"report",
				"garage",
				"settings",
				"guidebook",
				"practice",
			]:
				var modal := ui.debug_modal_contract(surface)
				await _settle_ui()
				var geometry := ui.debug_modal_geometry(surface)
				var context := "%s %dx%d %s" % [
					locale,
					viewport.x,
					viewport.y,
					surface,
				]
				var viewport_rect := Rect2(
					geometry["viewport_rect"]
				).grow(0.75)
				var surface_rect := Rect2(geometry["surface_rect"])
				var content_rect := Rect2(geometry["content_rect"])
				var content_minimum := Vector2(
					geometry["content_minimum"]
				)
				_expect(
					viewport_rect.encloses(surface_rect),
					"%s surface stays inside viewport; viewport=%s surface=%s"
					% [context, viewport_rect, surface_rect]
				)
				_expect(
					surface_rect.grow(0.75).encloses(content_rect),
					"%s content stays inside surface" % context
				)
				_expect(
					content_minimum.x <= content_rect.size.x + 0.75
						and content_minimum.y <= content_rect.size.y + 0.75,
					"%s combined minimum fits content rect" % context
				)
				var host := Dictionary(geometry["host"])
				_expect(
					int(host["focusables"]) > 0,
					"%s exposes reachable keyboard/controller focus"
					% context
				)
				_expect(
					int(host["primary_actions"]) <= 1,
					"%s exposes at most one emphasized primary action"
					% context
				)
				_expect(
					int(host["overflow_count"]) == 0,
					"%s has no visible non-scroll overflow (%s): %s"
					% [
						context,
						{
							"viewport":geometry["viewport_rect"],
							"host":geometry["host_rect"],
							"surface":surface_rect,
							"content":content_rect,
						},
						host["overflow_nodes"],
					]
				)
				_expect(
					int(host["missing_copy_count"]) == 0,
					"%s has no untranslated visible copy" % context
				)
				_expect(
					bool(modal["hud_hidden"])
						and bool(modal["dim_visible"]),
					"%s blocks HUD and gameplay attention" % context
				)
	TranslationServer.set_locale(original_locale)


func _settle_ui() -> void:
	for _frame in 3:
		await process_frame


func _validate_text_scale_probe(ui: VehicleStageUI) -> void:
	get_root().content_scale_size = Vector2i(1280, 720)
	get_root().size = Vector2i(1280, 720)
	await _settle_ui()
	ui.debug_modal_contract("upgrade")
	await _settle_ui()
	ui.debug_set_text_scale(2.0)
	await _settle_ui()
	var contract := ui.debug_ui_contract(1280.0)
	for status_name in Dictionary(contract["status_font_sizes"]):
		_expect(
			int(contract["status_font_sizes"][status_name]) >= 28,
			"200%% probe doubles local HUD typography for %s" % status_name
		)
	var upgrade := Dictionary(contract["upgrade_choice"])
	_expect(
		int(upgrade["header_text_count"]) == 0
			and Dictionary(upgrade["type_sizes"])
				== {"message":32, "confirm":48},
		"200%% probe keeps the upgrade screen header-free; got %s"
		% upgrade["type_sizes"]
	)
	for card_variant in upgrade["cards"]:
		_expect(
			int(Dictionary(card_variant)["type_sizes"]["title"]) == 56
				and int(Dictionary(card_variant)["type_sizes"]["level"]) == 36,
			"200%% probe doubles dynamically created card typography; got %s"
			% Dictionary(card_variant)["type_sizes"]
		)
	_expect_upgrade_geometry(
		ui.debug_upgrade_geometry(),
		"ko 1280x720 200% text"
	)
	ui.debug_set_text_scale(1.0)
	await _settle_ui()
	get_root().content_scale_size = Vector2i(960, 540)
	get_root().size = Vector2i(960, 540)
	ui.debug_modal_contract("upgrade")
	await _settle_ui()
	ui.debug_set_text_scale(2.0)
	await _settle_ui()
	_expect_upgrade_geometry(
		ui.debug_upgrade_geometry(),
		"ko 960x540 200% text",
		true
	)
	ui.debug_set_text_scale(1.0)
	await _settle_ui()


func _validate_owner_boundaries() -> void:
	var source := FileAccess.get_file_as_string(
		"res://scripts/ui/vehicle_stage_ui.gd"
	)
	_expect(
		not source.contains("func _build_"),
		"stage UI router contains no direct screen construction blocks"
	)
	for forbidden in [
		"_deployment_control_row",
		"func _practice_option",
		"_result_metric_labels",
		"_garage_primary_label",
		"HealthPips",
		"StageMinimap",
	]:
		_expect(
			not source.contains(forbidden),
			"stage UI router does not retain %s layout ownership"
			% forbidden
		)
	var guide_source := FileAccess.get_file_as_string(
		"res://scripts/ui/vehicle_guidebook_preview.gd"
	)
	_expect(
		guide_source.contains("vehicle_semantic_asset_provider.gd")
			and not guide_source.contains("vehicle_combat_visual_library.gd"),
		"guidebook preview consumes the semantic-v2 runtime provider only"
	)


func _validate_upgrade_matrix(ui: VehicleStageUI) -> void:
	var catalog := Catalog.new()
	var snapshots: Array[Dictionary] = []
	for definition in catalog.all_definitions():
		for current_level in definition.max_level:
			snapshots.append(OfferPresenter.snapshot(definition, current_level))
	_expect(snapshots.size() == 83, "layout matrix contains all 83 card/level states")
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


func _expect_upgrade_geometry(
	contract: Dictionary,
	context: String,
	allow_vertical_scroll := false
) -> void:
	var viewport_rect := Rect2(contract["viewport_rect"]).grow(0.5)
	var surface_rect := Rect2(contract["surface_rect"])
	_expect(viewport_rect.encloses(surface_rect), "%s modal stays inside viewport" % context)
	var panel := Dictionary(contract["panel"])
	var panel_rect := Rect2(panel["rect"]).grow(0.5)
	_expect(surface_rect.grow(0.5).encloses(panel_rect), "%s content stays inside modal" % context)
	var row_rect := Rect2(panel["row_rect"]).grow(0.5)
	var row_scroll_rect := Rect2(panel["row_scroll_rect"]).grow(0.5)
	if allow_vertical_scroll:
		_expect(
			not bool(panel["horizontal_scroll_visible"])
				and bool(panel["vertical_scroll_visible"]),
			"%s uses only the outer vertical card-flow scroll" % context
		)
		_expect(
			panel_rect.encloses(row_scroll_rect)
				and panel_rect.encloses(Rect2(panel["command_rect"])),
			"%s keeps the card viewport and Equip action inside the modal"
			% context
		)
	var prior_card := Rect2()
	for card_variant in panel["cards"]:
		var card := Dictionary(card_variant)
		var card_rect := Rect2(card["rect"])
		var expected_card_size := (
			Vector2(520.0, 920.0)
			if card_rect.size.x > 400.0
			else (
				Vector2(280.0, 378.0)
				if card_rect.size.x < 300.0
				else Vector2(352.0, 432.0)
			)
		)
		_expect(
			(
				row_rect.encloses(card_rect)
					and card_rect.position.x >= row_scroll_rect.position.x
					and card_rect.end.x <= row_scroll_rect.end.x
			)
			if allow_vertical_scroll
			else panel_rect.encloses(card_rect),
			"%s card stays inside its available flow bounds" % context
		)
		_expect(
			card_rect.size.is_equal_approx(expected_card_size),
			"%s card uses approved compact/wide geometry: %s"
			% [context, card_rect.size]
		)
		if prior_card.has_area():
			_expect(not prior_card.intersects(card_rect), "%s cards do not overlap" % context)
		prior_card = card_rect
		var glyph := Dictionary(card["glyph"])
		var glyph_control_rect := Rect2(glyph["control_rect"]).grow(0.5)
		var glyph_content_rect := Rect2(glyph["content_rect"])
		_expect(
			int(glyph["command_count"]) >= 3
				and glyph_control_rect.encloses(glyph_content_rect)
				and card_rect.grow(0.5).encloses(glyph_content_rect),
			"%s card glyph has complete visible bounds" % context
		)
		for label_variant in card["labels"]:
			var label := Dictionary(label_variant)
			var label_rect := Rect2(label["rect"])
			var glyph_rect := Rect2(label["glyph_rect"])
			_expect(
				card_rect.grow(0.5).encloses(label_rect),
				"%s card text stays inside card: %s" % [context, label["text"]]
			)
			_expect(
				label_rect.grow(0.5).encloses(glyph_rect),
				"%s shaped text stays inside its label: %s"
				% [context, label["text"]]
			)
			_expect(
				int(label["visible_line_count"]) == int(label["line_count"]),
				"%s card keeps every wrapped line visible: %s" % [context, label["text"]]
			)
			if String(label["name"]) == "TitleLabel":
				_expect(
					int(label["line_count"]) <= 2,
					"%s card title stays within two lines: %s"
					% [context, label["text"]]
				)
			elif String(label["name"]) == "SummaryLabel":
				_expect(
					int(label["line_count"])
						<= int(card["summary_max_lines"]),
					"%s card summary stays within its %d-line density budget: %s"
					% [
						context,
						int(card["summary_max_lines"]),
						label["text"],
					]
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
