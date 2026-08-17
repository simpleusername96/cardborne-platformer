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
	for error in UiGlyphCatalog.validate_status_recipes():
		failures.append("shared status glyph recipe: %s" % error)
	for error in UiGlyphCatalog.validate_semantic_ownership():
		failures.append("glyph semantic ownership: %s" % error)
	for status_id in UiGlyphCatalog.status_ids():
		_expect(status_id not in UiGlyphCatalog.action_ids(), "%s owns one glyph meaning" % status_id)
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
			int(foundation["modal_surface_count"]) >= 7,
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
			"full-width HP and EXP remain code-native and panel-free at %d" % width
		)
		var expected_meter_heights := (
			Vector2(28.0, 18.0)
			if width < 1100.0
			else (Vector2(40.0, 26.0) if width >= 1600.0 else Vector2(32.0, 22.0))
		)
		_expect(
			is_equal_approx(
				float(health_meter["experience_track_width"]),
				width
			)
				and Vector2(contract["meter_heights"]) == expected_meter_heights
				and is_equal_approx(float(contract["meter_top"]), 0.0)
				and is_equal_approx(float(contract["meter_gap"]), 0.0)
				and int(contract["live_upgrade_icon_count"]) == 0
				and not bool(contract["has_live_upgrade_rail"]),
			"HP/EXP fill viewport width, stack without a gap, and keep the upgrade rail absent at %d"
			% width
		)
		_expect(
			int(contract["zone_surface_count"]) == 2
				and Array(contract["zone_surface_variations"]) == [
					&"HudSurface", &"HudSurface",
				]
				and StringName(contract["toast_surface_variation"]) == &"HudSurface"
				and bool(contract["toast_below_minimap"])
				and bool(contract["toast_right_aligned"])
				and bool(contract["toast_reticle_clear"]),
			"minimap and its auxiliary-AI announcement use two aligned shared surfaces at %d" % width
		)
		_expect(
			bool(contract["status_cluster_panel_free"])
				and int(contract["status_cluster_background_geometry_count"]) == 0
				and not bool(contract["edge_boss_health_visible"])
				and not bool(contract["edge_target_health_visible"])
				and bool(contract["toast_below_minimap"])
				and not bool(contract["raster_chrome_consumer"]),
			"status cluster is panel-free and minimap announcement/edge health contracts remain coherent at %d" % width
		)
		var expected_status_size := (
			Vector2(172.0, 36.0)
			if width < 1100.0
			else (Vector2(212.0, 44.0) if width >= 1600.0 else Vector2(190.0, 40.0))
		)
		var expected_status_x := 16.0 if width < 1100.0 else (32.0 if width >= 1600.0 else 24.0)
		_expect(
			Vector2(contract["status_cluster_size"]) == expected_status_size
				and is_equal_approx(Vector2(contract["status_cluster_position"]).x, expected_status_x)
				and bool(contract["status_cluster_one_line"])
				and int(contract["visible_status_label_count"]) == 0,
			"four compact icon/value items keep the locked top-left footprint at %d" % width
		)
		var status_items := Array(contract["status_item_contracts"])
		var expected_ids := [&"stage_progress", &"total_defeats", &"dash", &"active"]
		_expect(
			status_items.size() == 4
				and int(contract["action_slot_count"]) == 2
				and not bool(contract["shows_primary_slot"]),
			"HUD owns four status items and exactly two action slots at %d" % width
		)
		for item_index in status_items.size():
			var item := Dictionary(status_items[item_index])
			_expect(
				StringName(item["glyph_id"]) == expected_ids[item_index]
					and bool(item["panel_free"])
					and int(item["background_geometry_count"]) == 0
					and int(item["cooldown_progress_geometry_count"]) == 0
					and bool(item["value_centered"]),
				"status item %d has one meaning, centered value, and no backing/progress geometry at %d"
				% [item_index, width]
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
			String(upgrade_contract["row_type"]) == "VBoxContainer"
				and int(upgrade_contract["row_separation"]) == (
					6 if width < 1100.0 else (10 if width < 1600.0 else 12)
				),
			"upgrade offers use the approved vertical row flow and gap at %d" % width
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
					card_size == Vector2(540.0, 112.0)
					if width < 1100.0
					else (
						card_size == Vector2(820.0, 140.0)
						if width < 1600.0
						else card_size == Vector2(900.0, 152.0)
					)
				),
				"upgrade cards use the supported hierarchy at %d" % width
			)
			_expect(
				Dictionary(card["type_sizes"]) == (
					{
						"category":12,
						"level":14,
						"title":18,
						"summary":13,
					}
					if width < 1100.0
					else (
						{
							"category":13,
							"level":16,
							"title":22,
							"summary":15,
						}
						if width < 1600.0
						else {
							"category":15,
							"level":18,
							"title":25,
							"summary":17,
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
					and not bool(card["vertical_dossier"])
					and int(card["body_divider_count"]) == 0,
				"upgrade offer uses one horizontal row without separator lines"
			)
			_expect(
				not bool(card["footer_visible"])
					and not bool(card["description_in_comparison"])
					and bool(card["description_visible"])
					and int(card["summary_max_lines"]) == 1,
				"upgrade row keeps one short explanatory line outside stat comparison"
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
		var expected_deployment_actions := ["DeployButton"]
		_expect(
			String(contract["deployment_action_row_type"]) == "HBoxContainer"
				and int(contract["deployment_action_count"])
					== expected_deployment_actions.size()
				and deployment_action_order == expected_deployment_actions
				and deployment_action_variations[0] == "PrimaryButton"
				and bool(contract["deployment_settings_in_header"])
				and Vector2(contract["deployment_settings_size"])
					== Vector2(48.0, 48.0)
				and not String(
					contract["deployment_settings_accessibility_name"]
				).is_empty(),
			"deployment keeps only Deploy in the footer and Settings in the header at %d"
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
			_expect(Vector2(modal_minimums["pause"]) == Vector2(520.0, 330.0), "pause modal fits the reduced command stack")
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
					"PAUSE_ABORT",
				]
				and Array(contract["pause_header_actions"]) == [
					"GuideButton", "SettingsButton",
				]
				and bool(contract["pause_settings_in_header"])
				and Vector2(contract["pause_settings_size"])
					== Vector2(48.0, 48.0)
				and not String(
					contract["pause_settings_accessibility_name"]
				).is_empty(),
			"pause keeps Resume/Abort in the stack and Settings in the header at %d"
			% width
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
		"dash_remaining":0.8,
		"skill_owned":true,
		"active_weapon_id":&"emp",
		"skill_available":false,
		"skill_remaining":11.4,
	})
	var cooldown_contract := ui.debug_ui_contract(1280.0)
	var cooldown_glyph_ids: Array[StringName] = []
	var cooldown_values: Array[String] = []
	for slot_variant in cooldown_contract["action_slot_contracts"]:
		var slot := Dictionary(slot_variant)
		cooldown_glyph_ids.append(StringName(slot["glyph_id"]))
		cooldown_values.append(String(slot["value"]))
		_expect(
			not bool(slot["image_backed"])
				and bool(slot["code_native_glyph"])
				and bool(slot["panel_free"])
				and int(slot["background_geometry_count"]) == 0
				and int(slot["cooldown_progress_geometry_count"]) == 0
				and bool(slot["has_text"])
				and not bool(slot["available"]),
			"cooldown action items use only a glyph and exact remaining-time text"
		)
	_expect(
		cooldown_glyph_ids == [&"dash", &"emp"]
			and cooldown_values == ["0.8s", "11.4s"],
		"top-left action items preserve Dash and acquired Active order with exact cooldown text"
	)
	ui.update_hud({
		"dash_available":true,
		"dash_remaining":0.0,
		"skill_owned":true,
		"active_weapon_id":&"emp",
		"skill_available":true,
		"skill_remaining":0.0,
	})
	var ready_contract := ui.debug_ui_contract(1280.0)
	for slot_variant in ready_contract["action_slot_contracts"]:
		var slot := Dictionary(slot_variant)
		_expect(
			not bool(slot["image_backed"])
				and bool(slot["code_native_glyph"])
				and bool(slot["panel_free"])
				and int(slot["background_geometry_count"]) == 0
				and int(slot["cooldown_progress_geometry_count"]) == 0
				and bool(slot["available"])
				and String(slot["value"]) == "READY",
			"ready action items use one code-native glyph plus READY without backing"
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
			{"kind":&"mystery_device", "position":Vector2(2100.0, 650.0), "discovered":true},
			{"kind":&"mobile_enemy", "position":Vector2(2700.0, 650.0), "discovered":true},
			{"kind":&"priority_enemy", "position":Vector2(3300.0, 650.0), "discovered":true},
			{"kind":&"boss", "position":Vector2(3900.0, 650.0), "discovered":true},
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
			and is_equal_approx(float(marker_sizes["mystery_device_scale"]), 1.20),
		"minimap preserves the locked role and world-object size hierarchy"
	)
	_expect(
		UiGlyphCatalog.minimap_ids() == [
			&"player", &"field_pickup", &"mystery_device",
			&"mobile_enemy", &"priority_enemy", &"boss",
		],
		"minimap exposes exactly six bounded semantic roles"
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
			{"kind":&"mystery_device", "position":Vector2(2100.0, 700.0), "discovered":true},
			{"kind":&"mobile_enemy", "position":Vector2(2700.0, 700.0), "discovered":true},
			{"kind":&"priority_enemy", "position":Vector2(3300.0, 700.0), "discovered":true},
			{"kind":&"boss", "position":Vector2(3900.0, 700.0), "discovered":true},
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
			and int(cleared_counts.get(Art.BOSS_COMMAND.to_rgba32(), 0)) == 0,
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
	var announcement_receipts: Array[Dictionary] = []
	ui.gameplay_announcement_receipt.connect(
		func(receipt: Dictionary) -> void:
			announcement_receipts.append(receipt.duplicate(true))
	)
	ui.clear_notifications()
	ui.notify("System message", 10.0, Art.SYSTEM, 1, &"system_message")
	for index in 5:
		ui.notify(
			"Queued warning %d" % index,
			10.0,
			Art.DANGER,
			1,
			StringName("queued_warning_%d" % index)
		)
	ui.notify_immediate("Immediate danger", 10.0, Art.DANGER, &"danger")
	var receipt_kinds: Array[StringName] = []
	var semantic_only := true
	for receipt in announcement_receipts:
		receipt_kinds.append(StringName(receipt.get("status", &"")))
		semantic_only = semantic_only and not receipt.has("message")
	_expect(
		&"queued" in receipt_kinds
			and &"shown" in receipt_kinds
			and &"interrupted" in receipt_kinds
			and &"dropped" in receipt_kinds
			and semantic_only,
		"announcement priority flow emits semantic-only queue receipts"
	)
	var hud := ui.get_node("VehicleStageUIRoot/GameplayHUD") as VehicleGameplayHud
	ui.notify("Localized transient", 10.0, Art.SYSTEM, 1, &"localized_transient")
	hud.refresh_localized_content()
	var refreshed_notifications := hud.debug_notification_contract()
	_expect(
			not bool(refreshed_notifications["active"])
			and int(refreshed_notifications["queue_size"]) == 0
			and bool(refreshed_notifications["auxiliary_ai"])
			and String(refreshed_notifications["sender_label"]) == "CONTROL"
			and StringName(refreshed_notifications["surface_variation"])
				== &"HudSurface"
			and int(refreshed_notifications["autowrap_mode"])
				== TextServer.AUTOWRAP_WORD_SMART
			and int(refreshed_notifications["text_overrun_behavior"])
				== TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
			and int(refreshed_notifications["max_lines_visible"]) == 2
			and bool(refreshed_notifications["clip_text"])
			and bool(refreshed_notifications["panel_clips_contents"]),
		"locale refresh discards localized transient announcements instead of retaining stale copy"
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
					"%s has no untranslated visible copy: %s"
					% [context, host.get("missing_copy_nodes", [])]
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
	_expect(
		Vector2(contract["meter_heights"]) == Vector2(52.0, 32.0)
			and Vector2(contract["status_cluster_size"]) == Vector2(354.0, 64.0)
			and bool(contract["top_clusters_do_not_overlap"]),
		"200% probe preserves full-width meters and a single unclipped status row"
	)
	var hud := ui.get_node("VehicleStageUIRoot/GameplayHUD") as VehicleGameplayHud
	var announcement := hud.debug_contract(1280.0)
	_expect(
		Vector2(announcement["toast_size"]) == Vector2(320.0, 148.0)
			and bool(announcement["toast_below_minimap"])
			and bool(announcement["toast_right_aligned"])
			and bool(announcement["toast_reticle_clear"]),
		"200% announcement stays below the minimap in a bounded two-line surface"
	)
	for item_variant in Array(contract["status_item_contracts"]):
		var item := Dictionary(item_variant)
		var expected_minimum_width := (
			48.0 if StringName(item["glyph_id"]) == &"total_defeats" else 72.0
		)
		_expect(
			int(item["value_font_size"]) == 28
				and Vector2(item["minimum_size"]).y == 64.0
				and Vector2(item["minimum_size"]).x >= expected_minimum_width,
			"200%% probe keeps each compact HUD value legible without adding a panel"
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
			Dictionary(card_variant)["type_sizes"]
				== {"category":36, "level":44, "title":60, "summary":44},
			"200%% probe doubles dynamically created offer-row typography; got %s"
			% Dictionary(card_variant)["type_sizes"]
		)
		_expect(
			bool(Dictionary(card_variant)["vertical_dossier"])
				and int(Dictionary(card_variant)["summary_max_lines"]) == 2,
			"200%% probe stacks each offer vertically and preserves two summary lines"
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
	ui.update_hud({
		"stage_number":1,
		"stage_total":8,
		"stage_quota_remaining":0,
		"cumulative_defeated":0,
		"dash_available":false,
		"dash_remaining":0.9,
		"skill_owned":false,
		"active_weapon_id":&"",
		"conditional_statuses":[
			{"id":&"last_stand", "value":"+35%"},
			{"id":&"overflow_barrier", "value":"2.4s"},
			{"id":&"dash_overdrive", "value":"1.8s"},
			{"id":&"braced_fire", "value":"3·1.2s"},
			{"id":&"hit_chain", "value":"×4"},
		],
	})
	await _settle_ui()
	announcement = hud.debug_contract(960.0)
	_expect(
		Vector2(announcement["toast_size"]) == Vector2(320.0, 148.0)
			and bool(announcement["toast_below_minimap"])
			and bool(announcement["toast_right_aligned"])
			and bool(announcement["toast_reticle_clear"]),
		"200% announcement stays below the compact minimap without covering the reticle"
	)
	_expect(
		bool(announcement["status_cluster_one_line"])
			and bool(announcement["top_clusters_do_not_overlap"])
			and int(announcement["conditional_status_count"]) == 5,
		"960x540 200% keeps all five conditional states in one row before the minimap"
	)
	var status_right := 0.0
	for item_variant in Array(announcement["status_item_contracts"]):
		var item := Dictionary(item_variant)
		status_right = maxf(
			status_right,
			Vector2(item["position"]).x + Vector2(item["size"]).x
		)
	_expect(
		status_right <= Vector2(announcement["status_cluster_size"]).x
			and status_right > 700.0,
		"960x540 200%% lays out every visible status slot inside the one-line cluster; right=%.1f cluster=%.1f"
		% [status_right, Vector2(announcement["status_cluster_size"]).x]
	)
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
	_expect(
		snapshots.size() == Catalog.EXPECTED_LEVEL_STATES,
		"layout matrix contains all catalog card/level states"
	)
	var safe_card := snapshots[0]
	var original_locale := TranslationServer.get_locale()
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for viewport in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
			get_root().content_scale_size = viewport
			get_root().size = viewport
			await process_frame
			for snapshot_index in snapshots.size():
				var snapshot := snapshots[snapshot_index]
				# Every state still renders in every locale and viewport. Rotating the
				# occupied slot removes three equivalent full-layout passes.
				var slot := snapshot_index % 3
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
		var expected_height := (
			600.0 if allow_vertical_scroll
			else (112.0 if card_rect.size.y < 120.0 else (152.0 if card_rect.size.y > 145.0 else 140.0))
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
			is_equal_approx(card_rect.size.y, expected_height)
				and card_rect.size.x >= 540.0,
			"%s row uses approved responsive geometry: %s"
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
