extends SceneTree

## Completeness gate for gameplay visual replacement and code-native UI chrome.

const GAMEPLAY_MANIFEST_PATH := (
	"res://art/visuals/production/gameplay/asset-manifest.json"
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
const EventCaptureFixture = preload(
	"res://scripts/presentation/components/vehicle_visual_event_capture_fixture.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const CODE_NATIVE_UI_STATE_OWNERS := [
	"res://scripts/ui/vehicle_gameplay_hud.gd",
	"res://scripts/ui/vehicle_upgrade_choice_row.gd",
]

const EXPECTED_EVENT_IDS := [
	"player_dash_afterimage",
	"player_emp_charge",
	"player_emp_release",
	"thermal_burst_impact",
	"drop_mine_detonation",
	"explosive_seeker_impact",
	"mystery_projectile_purge",
]

var _failures: Array[String] = []


func _initialize() -> void:
	var gameplay_manifest := _read_json(GAMEPLAY_MANIFEST_PATH)
	_expect(
		int(gameplay_manifest.get("final_asset_count", 0)) == 80,
		"gameplay manifest declares 77 semantic PNGs plus three approved SurfaceDetail SVGs"
	)
	var family_counts := Dictionary(gameplay_manifest.get("family_counts", {}))
	_expect(
		int(family_counts.get("upgrade", 0)) == 28,
		"gameplay manifest declares one raster per live upgrade card"
	)
	var world_asset_count := 0
	for asset_variant in Array(gameplay_manifest.get("assets", [])):
		if StringName(Dictionary(asset_variant).get("category", &"")) == &"world":
			world_asset_count += 1
	_expect(world_asset_count == 18, "gameplay manifest declares fifteen world PNGs and three SurfaceDetail SVGs")
	_validate_active_world_catalog()
	_expect(
		not gameplay_manifest.has("animations"),
		"gameplay manifest contains no raster frame animations"
	)
	var authored_effects := []
	for asset_variant in Array(gameplay_manifest.get("assets", [])):
		var asset := Dictionary(asset_variant)
		if StringName(asset.get("category", &"")) == &"effect":
			authored_effects.append(asset)
	_expect(
		authored_effects.is_empty(),
		"transient area effects use no authored raster identities"
	)

	if not FileAccess.file_exists(EVENT_CATALOG_PATH):
		_failures.append("missing visual event catalog: %s" % EVENT_CATALOG_PATH)
	else:
		for event_id in EXPECTED_EVENT_IDS:
			_expect(
				VisualEventCatalog.has_event(StringName(event_id)),
				"missing visual event mapping: %s" % event_id
			)
		_validate_event_catalog()
		_validate_event_producers()
		for error in EventCaptureFixture.validate():
			_failures.append(String(error))

	_validate_ui_runtime_contract()
	_finish()


func _validate_active_world_catalog() -> void:
	var active_ids := WorldCatalog.WORLD_OBJECT_DESCRIPTORS.keys()
	var expected := [
		&"mystery_device_intact", &"mystery_device_resolved",
		&"transit_gate",
	]
	var matches := active_ids.size() == expected.size()
	for expected_id in expected:
		matches = matches and active_ids.has(expected_id)
	_expect(
		matches,
		"runtime world catalog switches the transit gate and both Anomaly Device states"
	)


func _validate_event_catalog() -> void:
	var catalog_ids := VisualEventCatalog.event_ids()
	var expected_mode_counts := {
		&"hull_afterimage":1,
		&"live_emp_radius":1,
		&"emp_area":1,
		&"thermal_area":1,
		&"drop_mine_area":1,
		&"explosive_seeker_area":1,
		&"mystery_purge_pulse":1,
	}
	var mode_counts := {}
	_expect(
		catalog_ids.size() == EXPECTED_EVENT_IDS.size(),
		"event catalog and reviewed production event inventory must stay in sync"
	)
	for event_id in catalog_ids:
		var event := VisualEventCatalog.descriptor(event_id)
		var mode := StringName(event.get("mode", &""))
		mode_counts[mode] = int(mode_counts.get(mode, 0)) + 1
		_expect(
			expected_mode_counts.has(mode),
			"unsupported visual event mode: %s -> %s" % [event_id, mode]
		)
		_expect(
			not event.has("animation"),
			"event no longer references raster animation frames: %s" % event_id
		)
		_expect(
			not event.has("asset"),
			"transient event does not request an authored raster: %s" % event_id
		)
	for mode in expected_mode_counts:
		_expect(
			int(mode_counts.get(mode, 0)) == int(expected_mode_counts[mode]),
			"%s event coverage is %d, expected %d"
			% [mode, int(mode_counts.get(mode, 0)), int(expected_mode_counts[mode])]
		)


func _validate_event_producers() -> void:
	var run_source := FileAccess.get_file_as_string(RUN_PATH)
	var direct_event_pattern := RegEx.new()
	direct_event_pattern.compile('_add_effect\\(\\s*&"([^"]+)"')
	var produced := {}
	for result in direct_event_pattern.search_all(run_source):
		var event_id := StringName(result.get_string(1))
		produced[event_id] = true
		_expect(
			VisualEventCatalog.has_event(event_id),
			"VehicleRun emits an unmapped visual event: %s" % event_id
		)
	for event_id in EXPECTED_EVENT_IDS:
		var constant_events := {
			"player_emp_charge":"EMP_CHARGE_KIND",
			"player_emp_release":"EMP_RELEASE_KIND",
			"drop_mine_detonation":"DROP_MINE_DETONATION_KIND",
			"explosive_seeker_impact":"EXPLOSIVE_SEEKER_IMPACT_KIND",
			"mystery_projectile_purge":"MYSTERY_PURGE_PULSE_KIND",
		}
		if constant_events.has(event_id):
			var constant_name := String(constant_events[event_id])
			_expect(
				run_source.contains("EffectStore.%s" % constant_name),
				"VehicleRun does not emit the constant-owned event: %s" % event_id
			)
			continue
		_expect(
			produced.has(StringName(event_id)),
			"VehicleRun does not emit required transient event: %s" % event_id
		)
	_expect(
		produced.size() == EXPECTED_EVENT_IDS.size() - 5,
		"VehicleRun emits exactly the two reviewed direct transient event IDs"
	)
	var secondary_source := FileAccess.get_file_as_string(SECONDARY_PATH)
	_expect(
		not secondary_source.contains("_effects_output")
			and not secondary_source.contains('"effects"')
			and not secondary_source.contains('"event_id"'),
		"secondary runtime returns gameplay intents without cosmetic event payloads"
	)
	var renderer_source := FileAccess.get_file_as_string(RENDERER_PATH)
	for obsolete_path in [
		"_effect_batches",
		"impact_reflect",
		'family := &"ring"',
		"animation_frame_asset",
		"directed_transfer",
		"effect.target",
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
	for source_path in CODE_NATIVE_UI_STATE_OWNERS:
		var source := FileAccess.get_file_as_string(source_path)
		for forbidden_reference in [
			"VehicleUiAssetProvider",
			"UiAssets.texture",
			'&"small_state"',
			'&"pip_available"',
			'&"pip_filled"',
		]:
			_expect(
				not source.contains(forbidden_reference),
				"code-native UI state owner still references raster chrome: %s -> %s"
				% [source_path, forbidden_reference]
			)
	for source_path in [
		"res://scripts/ui/vehicle_modal_surface.gd",
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
