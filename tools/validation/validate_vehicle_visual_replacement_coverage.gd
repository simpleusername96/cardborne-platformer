extends SceneTree

## Completeness gate for gameplay visual replacement and the temporary UI
## rollback pack. Runtime UI chrome is code-native while the 54-file pack stays
## catalogued until its separately approved retirement.

const GAMEPLAY_MANIFEST_PATH := (
	"res://art/visuals/production/gameplay/asset-manifest.json"
)
const UI_MANIFEST_PATH := (
	"res://art/visuals/production/ui/ui-asset-manifest.json"
)
const EVENT_CATALOG_PATH := (
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)
const THEME_PATH := "res://art/visuals/production/ui/vehicle_stage_theme.tres"
const RUN_PATH := "res://scripts/vehicle/vehicle_run.gd"
const SECONDARY_PATH := "res://scripts/player/vehicle_secondary_runtime.gd"
const RENDERER_PATH := (
	"res://scripts/presentation/vehicle_combat_renderer.gd"
)
const VisualEventCatalog = preload(
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)
const UiAssets = preload("res://scripts/ui/vehicle_ui_asset_provider.gd")
const EventCaptureFixture = preload(
	"res://scripts/presentation/components/vehicle_visual_event_capture_fixture.gd"
)
const EXPECTED_UI_STATE_COUNT := 54
const DIRECT_UI_STATE_CONSUMERS := {
	"res://scripts/ui/vehicle_gameplay_hud.gd": [
		'&"small_state"',
		'&"pip_available" if available else &"disabled"',
	],
	"res://scripts/ui/vehicle_status_orbit.gd": [
		'&"small_state"',
		'&"pip_filled" if active else &"pip_available"',
	],
}

const EXPECTED_ANIMATIONS := [
	"muzzle_player_primary",
	"dash_start",
	"emp_release",
	"wake_mine_detonation",
	"boss_module_disabled",
	"hostile_summon_arrival",
	"bulkhead_destroy",
	"impact_damage",
	"reflect_deflection",
	"barrier_contact",
	"hull_hit",
	"seeker_impact",
	"escort_drone_impact",
	"orbit_blade_impact",
	"enemy_destroy_light",
	"enemy_destroy_heavy",
	"crate_destroy",
	"pickup_intake",
	"support_heal",
	"lifesteal_pulse",
	"transit_shift",
	"boss_reduced_hit",
]

const EXPECTED_EVENT_IDS := [
	"player_primary_muzzle",
	"player_dash_start",
	"player_dash_afterimage",
	"player_hull_hit",
	"player_barrier_hit",
	"player_barrier_activate",
	"player_emp_charge",
	"player_emp_release",
	"player_emp_aftershock",
	"player_ram_pulse",
	"player_phase_shear_hit",
	"player_ram_impact",
	"secondary_seeker_impact",
	"secondary_seeker_burst",
	"secondary_escort_impact",
	"secondary_orbit_blade_impact",
	"secondary_wake_mine_detonation",
	"enemy_mine_detonation",
	"hostile_projectile_impact",
	"projectile_cover_impact",
	"projectile_damage_impact",
	"projectile_reflected",
	"projectile_intercepted",
	"enemy_barrier_hit",
	"hostile_arrival",
	"hostile_summon_arrival",
	"enemy_destroy_light",
	"enemy_destroy_heavy",
	"boss_core_reduced_hit",
	"boss_module_resolved",
	"pickup_experience",
	"pickup_repair",
	"pickup_reward",
	"support_heal",
	"lifesteal_transfer",
	"transit_complete",
	"bulkhead_destroy",
	"crate_destroy",
	"group_clear",
]

const EXPECTED_UI_COMPONENT_STATES := {
	"modal_master": ["normal", "compact_safe"],
	"content_plate": ["normal", "inset", "summary"],
	"hud_plate": [
		"health_resource",
		"objective_boss",
		"minimap_target",
		"action_rail",
		"toast",
	],
	"upgrade_card": [
		"normal",
		"hover",
		"pressed",
		"focus",
		"selected",
		"disabled",
	],
	"button_primary": [
		"normal", "hover", "pressed", "focus", "disabled",
	],
	"button_secondary": [
		"normal", "hover", "pressed", "focus", "disabled",
	],
	"button_danger": [
		"normal", "hover", "pressed", "focus", "disabled",
	],
	"tab_option": [
		"normal", "hover", "selected", "focus", "disabled",
	],
	"toggle": ["off", "on", "focus"],
	"slider": ["lane", "fill", "grabber"],
	"meter": [
		"background", "health", "boss", "resource", "cooldown", "support",
	],
	"preview": ["normal", "locked", "focused"],
	"small_state": [
		"pip_available",
		"pip_filled",
		"disabled",
	],
}

var _failures: Array[String] = []


func _initialize() -> void:
	var gameplay_manifest := _read_json(GAMEPLAY_MANIFEST_PATH)
	var animations := Dictionary(gameplay_manifest.get("animations", {}))
	for animation_id in EXPECTED_ANIMATIONS:
		if not animations.has(animation_id):
			_failures.append("missing gameplay animation: %s" % animation_id)
			continue
		_validate_animation(animation_id, Dictionary(animations[animation_id]))

	if not FileAccess.file_exists(EVENT_CATALOG_PATH):
		_failures.append("missing visual event catalog: %s" % EVENT_CATALOG_PATH)
	else:
		for event_id in EXPECTED_EVENT_IDS:
			_expect(
				VisualEventCatalog.has_event(StringName(event_id)),
				"missing visual event mapping: %s" % event_id
			)
		_validate_event_catalog(animations)
		_validate_event_producers()
		for error in EventCaptureFixture.validate():
			_failures.append(String(error))

	if not FileAccess.file_exists(UI_MANIFEST_PATH):
		_failures.append("missing UI asset manifest: %s" % UI_MANIFEST_PATH)
	else:
		_validate_ui_manifest(_read_json(UI_MANIFEST_PATH))
		for error in UiAssets.validate_pack():
			_failures.append(String(error))
	_validate_ui_runtime_contract()
	_finish()


func _validate_animation(animation_id: String, animation: Dictionary) -> void:
	var frame_count := int(animation.get("frame_count", 0))
	var frame_pattern := String(animation.get("frames", ""))
	_expect(frame_count > 0, "%s has no animation frames" % animation_id)
	_expect(
		not frame_pattern.is_empty(),
		"%s has no animation frame path" % animation_id
	)
	_expect(
		int(animation.get("fps", 0)) > 0,
		"%s has no animation FPS" % animation_id
	)
	_expect(
		not bool(animation.get("loop", true)),
		"%s must be a non-looping semantic effect" % animation_id
	)
	for index in frame_count:
		var path := frame_pattern.replace("{index:02}", "%02d" % index)
		if not path.begins_with("res://"):
			path = "res://art/visuals/production/gameplay/%s" % path
		_expect(
			FileAccess.file_exists(path),
			"missing %s frame: %s" % [animation_id, path]
		)


func _validate_ui_manifest(manifest: Dictionary) -> void:
	var components := Dictionary(manifest.get("components", {}))
	_expect(
		components.size() == EXPECTED_UI_COMPONENT_STATES.size(),
		"UI manifest declares %d components, expected %d"
		% [components.size(), EXPECTED_UI_COMPONENT_STATES.size()]
	)
	var state_count := 0
	for component_id in EXPECTED_UI_COMPONENT_STATES:
		var required_states := Array(EXPECTED_UI_COMPONENT_STATES[component_id])
		if not components.has(component_id):
			_failures.append("missing UI component: %s" % component_id)
			continue
		var component := Dictionary(components[component_id])
		var states := Dictionary(component.get("states", {}))
		state_count += states.size()
		_expect(
			_vector2i(component.get("canvas", [])) != Vector2i.ZERO,
			"%s has no canvas metadata" % component_id
		)
		_expect(
			int(component.get("patch_margin", 0)) > 0,
			"%s has no 9-slice patch margin" % component_id
		)
		var safe_inset := Array(component.get("safe_inset", []))
		_expect(safe_inset.size() == 4, "%s has no text-safe inset" % component_id)
		for state_id in required_states:
			if not states.has(state_id):
				_failures.append(
					"missing UI state: %s/%s" % [component_id, state_id]
				)
				continue
			var path := String(states[state_id])
			if not path.begins_with("res://"):
				path = "res://art/visuals/production/ui/%s" % path
			_expect(
				FileAccess.file_exists(path),
				"missing UI state image: %s/%s -> %s"
				% [component_id, state_id, path]
			)
	_expect(
		state_count == EXPECTED_UI_STATE_COUNT,
		"UI manifest declares %d states, expected %d"
		% [state_count, EXPECTED_UI_STATE_COUNT]
	)


func _validate_event_catalog(animations: Dictionary) -> void:
	var catalog_ids := VisualEventCatalog.event_ids()
	_expect(
		catalog_ids.size() == EXPECTED_EVENT_IDS.size(),
		"event catalog and reviewed production event inventory must stay in sync"
	)
	for event_id in catalog_ids:
		var event := VisualEventCatalog.descriptor(event_id)
		var mode := StringName(event.get("mode", &"animation"))
		var animation_id := StringName(event.get("animation", &""))
		_expect(
			mode in [
				&"animation",
				&"hull_afterimage",
				&"live_emp_radius",
				&"pickup_intake",
				&"directed_transfer",
				&"hud_only",
			],
			"unsupported visual event mode: %s -> %s" % [event_id, mode]
		)
		if animation_id != &"":
			_expect(
				animations.has(String(animation_id)),
				"event references missing animation: %s -> %s"
				% [event_id, animation_id]
			)
		elif mode == &"animation":
			_failures.append(
				"animation event has no animation: %s" % event_id
			)


func _validate_event_producers() -> void:
	var run_source := FileAccess.get_file_as_string(RUN_PATH)
	var direct_event_pattern := RegEx.new()
	direct_event_pattern.compile('_add_effect\\(\\s*&"([^"]+)"')
	for result in direct_event_pattern.search_all(run_source):
		var event_id := StringName(result.get_string(1))
		_expect(
			VisualEventCatalog.has_event(event_id),
			"VehicleRun emits an unmapped visual event: %s" % event_id
		)
	for prohibited_id in [
		"spawn",
		"shock",
		"secondary",
		"destroy",
		"support",
		"impact",
		"reflect",
		"barrier_hit",
		"afterimage",
		"muzzle",
	]:
		_expect(
			not run_source.contains(
				'_add_effect(&"%s"' % prohibited_id
			),
			"VehicleRun still emits broad visual event: %s" % prohibited_id
		)
	var secondary_source := FileAccess.get_file_as_string(SECONDARY_PATH)
	var secondary_event_pattern := RegEx.new()
	secondary_event_pattern.compile('"event_id"\\s*:\\s*&"([^"]+)"')
	for result in secondary_event_pattern.search_all(secondary_source):
		var event_id := StringName(result.get_string(1))
		_expect(
			VisualEventCatalog.has_event(event_id),
			"secondary runtime emits an unmapped visual event: %s" % event_id
		)
	var renderer_source := FileAccess.get_file_as_string(RENDERER_PATH)
	for obsolete_path in [
		"_effect_batches",
		"impact_reflect",
		'family := &"ring"',
	]:
		_expect(
			not renderer_source.contains(obsolete_path),
			"renderer still contains generic effect fallback: %s"
			% obsolete_path
		)


func _validate_ui_runtime_contract() -> void:
	var theme_source := FileAccess.get_file_as_string(THEME_PATH)
	_expect(
		theme_source.contains("StyleBoxFlat")
			and not theme_source.contains("StyleBoxTexture")
			and not theme_source.contains("res://art/visuals/production/ui/controls/")
			and not theme_source.contains("res://art/visuals/production/ui/surfaces/")
			and not theme_source.contains("res://art/visuals/production/ui/glyphs/"),
		"production UI theme uses only code-native chrome"
	)
	for required_reference in [
		'[sub_resource type="StyleBoxFlat"',
		'ContentSurface/styles/panel',
		'HudSurface/styles/panel',
		'ToastSurface/styles/panel',
		'SelectableButton/styles/normal',
		'SelectedSelectableButton/styles/normal',
		'HudHealthResource/styles/panel',
		'HudObjectiveBoss/styles/panel',
		'HudMinimapTarget/styles/panel',
		'HudActionRail/styles/panel',
		'HudToast/styles/panel',
		'PreviewFrame/styles/panel',
		'CheckButton/styles/focus',
		'TabContainer/styles/tab_disabled',
		'TabBar/styles/tab_disabled',
		'ModalSurfaceCompact/styles/panel',
	]:
		_expect(
			theme_source.contains(required_reference),
			"production UI theme is missing shared contract: %s"
			% required_reference
		)
	for source_path in DIRECT_UI_STATE_CONSUMERS:
		var source := FileAccess.get_file_as_string(source_path)
		for state_reference in DIRECT_UI_STATE_CONSUMERS[source_path]:
			_expect(
				source.contains(state_reference),
				"UI consumer is missing state reference: %s -> %s"
				% [source_path, state_reference]
			)
	for source_path in [
		"res://scripts/ui/vehicle_modal_surface.gd",
		"res://scripts/ui/vehicle_upgrade_choice_card.gd",
		"res://scripts/ui/vehicle_guidebook_preview.gd",
		"res://scripts/ui/vehicle_deployment_panel.gd",
	]:
		var source := FileAccess.get_file_as_string(source_path)
		_expect(
			not source.contains("func _draw()"),
			"replaceable decorative primitive draw remains: %s"
			% source_path
		)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(path))
	_expect(error == OK, "invalid JSON manifest: %s" % path)
	if error != OK or not parser.data is Dictionary:
		return {}
	return Dictionary(parser.data)


func _vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	return Vector2i.ZERO


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_VISUAL_REPLACEMENT_COVERAGE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
