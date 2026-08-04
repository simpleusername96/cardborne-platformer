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
const CODE_NATIVE_UI_STATE_OWNERS := [
	"res://scripts/ui/vehicle_gameplay_hud.gd",
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

var _failures: Array[String] = []


func _initialize() -> void:
	var gameplay_manifest := _read_json(GAMEPLAY_MANIFEST_PATH)
	_expect(
		int(gameplay_manifest.get("final_asset_count", 0)) == 59,
		"gameplay manifest declares the final 59 authored rasters"
	)
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
		authored_effects.size() == 1
			and StringName(Dictionary(authored_effects[0]).get("id", &""))
				== &"effect/emp_release",
		"EMP is the only authored raster effect"
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


func _validate_event_catalog() -> void:
	var catalog_ids := VisualEventCatalog.event_ids()
	var expected_mode_counts := {
		&"direct_feedback":17,
		&"suppressed":16,
		&"hull_afterimage":1,
		&"live_emp_radius":1,
		&"authored_emp":1,
		&"floating_damage":1,
		&"directed_transfer":1,
		&"hud_only":1,
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
		if mode == &"authored_emp":
			_expect(
				event_id == &"player_emp_release"
					and StringName(event.get("asset", &""))
						== &"effect/emp_release",
				"only EMP release requests the authored EMP raster"
			)
		else:
			_expect(
				not event.has("asset"),
				"non-EMP event does not request an authored raster: %s" % event_id
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
		"animation_frame_asset",
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
