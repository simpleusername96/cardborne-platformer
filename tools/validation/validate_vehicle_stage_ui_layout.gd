extends SceneTree

const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")
const MinimapMeshBuilder = preload("res://scripts/ui/vehicle_minimap_mesh_builder.gd")
const RetainedMinimapMesh = preload("res://scripts/ui/vehicle_retained_minimap_mesh.gd")
const ThreatRadar = preload("res://scripts/ui/vehicle_threat_radar.gd")
const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const VehicleRun = preload("res://scripts/vehicle/vehicle_run.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
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
		_expect(action_rail_size == Vector2(88.0, 88.0), "EMP uses one enlarged round indicator at %d" % width)
		_expect(
			is_equal_approx(action_rail_position.x, (width - action_rail_size.x) * 0.5)
				and is_equal_approx(action_rail_position.y, width * 9.0 / 16.0 - 108.0),
			"EMP indicator stays centered at the bottom at %d" % width
		)
		var health_meter := Dictionary(contract["health_meter"])
		_expect(
			bool(health_meter["code_drawn"])
				and not bool(health_meter["image_backed"])
				and bool(health_meter["has_background_geometry"])
				and bool(health_meter["has_trailing_health_geometry"])
				and bool(health_meter["has_health_geometry"])
				and bool(health_meter["has_experience_geometry"])
				and int(health_meter["live_upgrade_icon_count"]) == 0
				and bool(health_meter["panel_free"]),
			"center hull and XP remain panel-free with zero live upgrade icons at %d" % width
		)
		_expect(
			is_equal_approx(
				float(health_meter["experience_track_width"]),
				Vector2(contract["health_cluster_size"]).x
			)
				and is_equal_approx(
					float(health_meter["experience_track_height"]),
					6.0 if width < 1100.0 else 8.0
				)
				and int(contract["live_upgrade_icon_count"]) == 0
				and not bool(contract["has_live_upgrade_rail"]),
			"XP shares the responsive hull width and the acquired rail is absent at %d"
			% width
		)
		_expect(
			int(contract["zone_surface_count"]) == 1
				and Array(contract["zone_surface_variations"]) == [
					&"HudSurface",
				]
				and StringName(contract["toast_surface_variation"]) == &"ToastSurface",
			"only the minimap keeps a backed HUD surface while stage progress stays panel-free at %d" % width
		)
		_expect(
			bool(contract["stage_progress_panel_free"])
				and not bool(contract["edge_boss_health_visible"])
				and not bool(contract["edge_target_health_visible"])
				and bool(contract["toast_center_attached"])
				and not bool(contract["raster_chrome_consumer"]),
			"B progress is panel-free, toast follows center status, and edge health panels are absent at %d" % width
		)
		var expected_label_size := 15 if width < 1100.0 else (18 if width >= 1600.0 else 16)
		var expected_value_size := 30 if width < 1100.0 else (40 if width >= 1600.0 else 32)
		var status_sizes := Dictionary(contract["status_font_sizes"])
		_expect(
			int(status_sizes["stage_label"]) == expected_label_size
				and int(status_sizes["defeated_label"]) == expected_label_size
				and int(status_sizes["stage_value"]) == expected_value_size
				and int(status_sizes["defeated_value"]) == expected_value_size,
			"B progress uses the locked responsive typography at %d" % width
		)
		_expect(bool(contract["action_rail_icon_only"]), "action rail contains icons only at %d" % width)
		_expect(
			int(contract["action_slot_count"]) == 1
				and bool(contract["action_rail_panel_free"]),
			"bottom HUD contains only one panel-free EMP action at %d" % width
		)
		_expect(not bool(contract["shows_primary_slot"]), "primary fire is omitted from the action rail at %d" % width)
		_expect(Vector2(contract["secondary_slot_size"]) == Vector2.ZERO, "dash and secondary slots are absent at %d" % width)
		for status_name in status_sizes:
			_expect(
				int(contract["status_font_sizes"][status_name]) >= 14,
				"%s HUD status typography stays at or above 14 px at %d"
				% [status_name, width]
			)
		_expect(bool(contract["top_clusters_do_not_overlap"]), "top clusters do not overlap at %d" % width)
		_expect(bool(contract["central_safe_clear"]), "central play space remains clear at %d" % width)
		var upgrade_contract := Dictionary(contract["upgrade_choice"])
		_expect(bool(upgrade_contract["structured_cards"]), "upgrade choices use structured card components at %d" % width)
		_expect(int(upgrade_contract["card_count"]) == 3, "upgrade choice keeps a fixed capacity of three card slots at %d" % width)
		_expect(
			Vector2(upgrade_contract["confirm_size"]) == (
				Vector2(300.0, 48.0)
				if width < 1100.0
				else (
					Vector2(360.0, 56.0)
					if width < 1600.0
					else Vector2(420.0, 64.0)
				)
			),
			"upgrade confirmation uses the supported command contract at %d" % width
		)
		_expect(
			String(upgrade_contract["row_type"]) == "HFlowContainer"
				and int(upgrade_contract["row_separation"]) == (
					12 if width < 1100.0 else (16 if width < 1600.0 else 24)
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
				else (
					{
						"message":16,
						"confirm":24,
					}
					if width < 1600.0
					else {
						"message":18,
						"confirm":26,
					}
				)
			),
			"upgrade panel uses the approved responsive type scale at %d"
			% width
		)
		for card_variant in upgrade_contract["cards"]:
			var card := Dictionary(card_variant)
			var card_size := Vector2(card["minimum_size"])
			_expect(
				(
					card_size == Vector2(280.0, 410.0)
					if width < 1100.0
					else (
						card_size == Vector2(360.0, 488.0)
						if width < 1600.0
						else card_size == Vector2(420.0, 512.0)
					)
				),
				"upgrade cards use the supported hierarchy at %d" % width
			)
			_expect(
				Dictionary(card["type_sizes"]) == (
					{
						"category":13,
						"level":15,
						"title":22,
						"summary":32,
					}
					if width < 1100.0
					else (
						{
							"category":16,
							"level":18,
							"title":28,
							"summary":34,
						}
						if width < 1600.0
						else {
							"category":18,
							"level":18,
							"title":32,
							"summary":36,
						}
					)
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
				not bool(card["dossier_split"])
					and bool(card["vertical_dossier"])
					and int(card["body_divider_count"]) == 0,
				"upgrade card uses one centered vertical dossier without separator lines"
			)
			_expect(
				not bool(card["footer_visible"])
					and not bool(card["description_in_comparison"])
					and bool(card["description_visible"])
					and int(card["summary_max_lines"]) == 2,
				"upgrade card shows one large two-line description outside stat comparison"
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
		_expect(bool(contract["has_danger_theme"]), "run abort uses the public shared danger state at %d" % width)
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
			_expect(Vector2(modal_minimums["upgrade"]) == Vector2(1376.0, 616.0), "upgrade modal fits the responsive dossier card flow without a header")
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
		"skill_available":false,
		"skill_ratio":0.5,
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
		cooldown_glyph_ids == [&"emp"],
		"bottom indicator exposes only EMP"
	)
	ui.update_hud({
		"skill_available":true,
		"skill_ratio":0.0,
	})
	var ready_contract := ui.debug_ui_contract(1280.0)
	for slot_variant in ready_contract["action_slot_contracts"]:
		var slot := Dictionary(slot_variant)
		_expect(
			not bool(slot["image_backed"])
				and bool(slot["state_code_drawn"])
				and not bool(slot["semantic_icon_image_retained"])
				and bool(slot["code_native_glyph"])
				and not bool(slot["semantic_texture"])
				and bool(slot["available_has_structural_ring"])
				and not bool(slot["disabled_has_structural_slash"])
				and not bool(slot["interior_filled"]),
			"ready action slots use shared code-native glyphs and state structure"
		)
	await _validate_modal_matrix(ui)
	await _validate_upgrade_matrix(ui)
	await _validate_text_scale_probe(ui)
	_validate_owner_boundaries()
	var radar_contract := ui.debug_threat_radar_contract()
	_expect(
		int(radar_contract["sector_count"]) == 12
			and bool(radar_contract["nearby_enemy_contact"])
			and not bool(radar_contract["nearby_enemy_triangle"])
			and bool(radar_contract["packed_rebase"])
			and int(radar_contract["sample_storage_count"]) == 12
			and int(radar_contract["display_storage_count"]) == 12
			and int(radar_contract["retained_mesh_recipes"]) > 1
			and not bool(radar_contract["mesh_recreated_per_anchor"])
			and Dictionary(radar_contract["contact_priorities"]) == {
				"incoming_attack":3, "boss_arrival":2, "nearby_enemy":1,
			},
		"threat radar keeps 12 sectors and the 3/2/1 contact hierarchy"
	)
	var radar := ThreatRadar.new()
	get_root().add_child(radar)
	await process_frame
	var shared_sector := radar.debug_aggregate_contacts([
		{"offset":Vector2(800.0, 20.0), "kind":CombatCuePolicy.CONTACT_NEARBY_ENEMY},
		{"offset":Vector2(850.0, 10.0), "kind":CombatCuePolicy.CONTACT_BOSS_ARRIVAL, "readiness":1.0},
		{"offset":Vector2(900.0, 0.0), "kind":CombatCuePolicy.CONTACT_INCOMING_ATTACK, "readiness":0.4},
	])
	_expect(
		shared_sector.size() == 1
			and StringName(shared_sector[0]["kind"])
				== CombatCuePolicy.CONTACT_INCOMING_ATTACK
			and int(shared_sector[0]["count"]) == 3
			and is_equal_approx(float(shared_sector[0]["readiness"]), 0.4),
		"the winning radar kind owns sector color/readiness while density still accumulates"
	)
	radar.set_live_anchor(
		Vector2(1000.0, 1000.0), Vector2(640.0, 360.0), true
	)
	radar.set_snapshot({
		"generation":1,
		"sample_origin":Vector2(1000.0, 1000.0),
		"max_distance":1200.0,
		"sectors":[{
			"active":true,
			"count":1,
			"world_position":Vector2(1800.0, 1000.0),
			"kind":CombatCuePolicy.CONTACT_NEARBY_ENEMY,
			"readiness":0.0,
		}],
	})
	var dash_start := radar.debug_contract()
	radar.set_live_anchor(
		Vector2(1244.0, 1100.0), Vector2(640.0, 360.0), true
	)
	var dash_middle := radar.debug_contract()
	radar.set_live_anchor(
		Vector2(1244.0, 1100.0), Vector2(700.0, 390.0), true
	)
	var dash_end := radar.debug_contract()
	_expect(
		Vector2(dash_start["live_anchor"]) == Vector2(640.0, 360.0)
			and Vector2(dash_middle["live_anchor"]) == Vector2(640.0, 360.0)
			and Vector2(dash_end["live_anchor"]) == Vector2(700.0, 390.0)
			and int(dash_middle["active_sector_count"]) == 1
			and not is_equal_approx(
				float(dash_start["first_active_angle"]),
				float(dash_middle["first_active_angle"])
			)
			and int(dash_end["retained_mesh_recipes"])
				== int(dash_start["retained_mesh_recipes"]),
		"dash live anchor follows the projected craft while sampled directions rebase without rebuilding mesh recipes"
	)
	radar.free()
	var tactical_mesh := MinimapMeshBuilder.build({
		"cols":13,
		"rows":6,
		"visited":[Vector2i(6, 3)],
		"world_size":Vector2(5200.0, 2200.0),
		"player":Vector2(2600.0, 1100.0),
		"player_facing":Vector2.RIGHT,
		"markers":[
			{"kind":&"field_pickup", "position":Vector2(900.0, 650.0), "discovered":true},
			{"kind":&"reward_crate", "position":Vector2(1500.0, 650.0), "discovered":true},
			{"kind":&"mystery_device", "position":Vector2(2100.0, 650.0), "discovered":true},
			{"kind":&"mobile_enemy", "position":Vector2(2700.0, 650.0), "discovered":true},
			{"kind":&"priority_enemy", "position":Vector2(3300.0, 650.0), "discovered":true},
			{"kind":&"boss", "position":Vector2(3900.0, 650.0), "discovered":true},
			{"kind":&"reinforcement_facility", "position":Vector2(4500.0, 1500.0), "discovered":true},
		],
	}, Vector2(176.0, 108.0))
	_expect(tactical_mesh != null, "tactical minimap compiles a dynamic marker mesh")
	_expect(
		tactical_mesh != null and tactical_mesh.get_surface_count() == 1,
		"tactical minimap publishes all dynamic markers through one mesh surface"
	)
	var minimap_palette := MinimapMeshBuilder.dynamic_colors()
	var marker_sizes := MinimapMeshBuilder.marker_size_contract()
	_expect(
		is_equal_approx(float(marker_sizes["mobile_enemy_outer"]), 4.0)
			and is_equal_approx(float(marker_sizes["mobile_enemy_inner"]), 2.6)
			and is_equal_approx(float(marker_sizes["priority_enemy_outer"]), 6.2)
			and is_equal_approx(float(marker_sizes["priority_enemy_inner"]), 4.3)
			and is_equal_approx(float(marker_sizes["boss_outer"]), 10.0)
			and is_equal_approx(float(marker_sizes["boss_inner"]), 7.6)
			and Vector2(marker_sizes["field_pickup_size"])
				== Vector2(12.0, 7.6)
			and Vector2(marker_sizes["reward_crate_size"])
				== Vector2(9.0, 9.0)
			and is_equal_approx(float(marker_sizes["mystery_device_scale"]), 1.20),
		"minimap preserves the locked role and world-object size hierarchy"
	)
	var pickup_area := float(marker_sizes["field_pickup_polygon_area"])
	var crate_area := float(marker_sizes["reward_crate_polygon_area"])
	_expect(
		absf(pickup_area - crate_area) / maxf(pickup_area, crate_area) <= 0.10,
		"pickup and reward-crate perceived polygon areas differ by at most ten percent"
	)
	_expect(
		UiGlyphCatalog.minimap_ids() == [
			&"player", &"field_pickup", &"reward_crate", &"mystery_device",
			&"mobile_enemy", &"priority_enemy", &"boss",
			&"reinforcement_facility",
		],
		"minimap exposes exactly eight bounded semantic roles"
	)
	var retained_snapshot := {
		"cols":13,
		"rows":6,
		"visited":[Vector2i(6, 3)],
		"world_size":Vector2(5200.0, 2200.0),
		"player":Vector2(2600.0, 1100.0),
		"player_facing":Vector2.RIGHT,
		"markers":[
			{"kind":&"field_pickup", "position":Vector2(900.0, 700.0), "discovered":true},
			{"kind":&"reward_crate", "position":Vector2(1500.0, 700.0), "discovered":true},
			{"kind":&"mystery_device", "position":Vector2(2100.0, 700.0), "discovered":true},
			{"kind":&"mobile_enemy", "position":Vector2(2700.0, 700.0), "discovered":true},
			{"kind":&"priority_enemy", "position":Vector2(3300.0, 700.0), "discovered":true},
			{"kind":&"boss", "position":Vector2(3900.0, 700.0), "discovered":true},
			{"kind":&"reinforcement_facility", "position":Vector2(4500.0, 1400.0), "discovered":true},
		],
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
		int(cleared_counts.get(Art.DANGER.to_rgba32(), 0)) == 0
			and int(cleared_counts.get(Art.SUPPORT.to_rgba32(), 0)) == 0
			and int(cleared_counts.get(Art.TEXT_MUTED.to_rgba32(), 0)) == 0
			and int(cleared_counts.get(Art.BOSS_COMMAND.to_rgba32(), 0)) == 0
			and int(cleared_counts.get(Art.MUSTARD_DARK.to_rgba32(), 0)) == 0,
		"retained minimap clears channels that leave the snapshot"
	)
	var pressure_markers: Array[Dictionary] = []
	for index in EnemyStore.MAX_LIVE_HOSTILES:
		pressure_markers.append({
			"kind":&"mobile_enemy",
			"position":Vector2(
				300.0 + float(index % 32) * 140.0,
				300.0 + float(index / 32) * 140.0
			),
			"discovered":true,
		})
	retained_snapshot["cols"] = VehicleRun.MINIMAP_COLS
	retained_snapshot["rows"] = VehicleRun.MINIMAP_ROWS
	retained_snapshot["markers"] = pressure_markers
	var danger_key := Art.DANGER.to_rgba32()
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
			and all_marker_compiled.size() > 1500
			and all_marker_compiled.size()
				<= int(all_marker_contract["vertices_per_color"])
			and all_marker_retained == all_marker_compiled.size(),
		"retained minimap preserves every marker at the 320-hostile capacity"
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
	_expect(snapshots.size() == 36, "layout matrix contains all 36 card/level states")
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
			if card_rect.size.x > 500.0
			else (
				Vector2(280.0, 410.0)
				if card_rect.size.x < 300.0
				else (
					Vector2(420.0, 512.0)
					if card_rect.size.x > 400.0
					else Vector2(360.0, 488.0)
				)
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
		var artwork := Dictionary(card["artwork"])
		var artwork_rect := Rect2(artwork["rect"])
		_expect(
			StringName(artwork["asset_id"]) != &""
				and bool(artwork["texture_loaded"])
				and card_rect.grow(0.5).encloses(artwork_rect),
			"%s card uses one resolved authored artwork texture inside its bounds" % context
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
