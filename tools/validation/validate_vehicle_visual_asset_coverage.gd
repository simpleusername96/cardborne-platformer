extends SceneTree

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const EXPECTED_CATEGORY_COUNTS := {
	&"attachment":1,
	&"actor":19,
	&"boss":5,
	&"boss_module":10,
	&"secondaries":4,
	&"projectiles":9,
	&"states":7,
	&"pickups":6,
	&"world_feature":10,
	&"hud":21,
	&"combat_cue":22,
	&"effect_frame":101,
}
const LIVE_CONSUMER_PATHS := [
	"res://scripts/presentation/vehicle_combat_renderer.gd",
	"res://scripts/vehicle/vehicle_run.gd",
	"res://scripts/ui/vehicle_gameplay_hud.gd",
	"res://scripts/ui/vehicle_guidebook_preview.gd",
	"res://scripts/ui/vehicle_combat_mesh_icon.gd",
	"res://scripts/ui/vehicle_stage_report_panel.gd",
]

var _failures: Array[String] = []


func _initialize() -> void:
	var category_counts := {}
	for asset_id in AssetProvider.asset_ids():
		var descriptor := AssetProvider.descriptor(asset_id)
		var category := StringName(descriptor.get("category", &""))
		category_counts[category] = int(category_counts.get(category, 0)) + 1
	for category in EXPECTED_CATEGORY_COUNTS:
		_expect(
			int(category_counts.get(category, 0))
				== int(EXPECTED_CATEGORY_COUNTS[category]),
			"%s coverage is %d, expected %d"
			% [
				category,
				int(category_counts.get(category, 0)),
				int(EXPECTED_CATEGORY_COUNTS[category]),
			]
		)
	_expect(
		AssetProvider.asset_ids().size() == 215,
		"semantic-v2 production coverage totals 215 runtime images"
	)
	for path in LIVE_CONSUMER_PATHS:
		var source := FileAccess.get_file_as_string(path)
		_expect(
			source.contains("vehicle_semantic_asset_provider.gd"),
			"%s consumes the semantic-v2 provider" % path
		)
		if path.ends_with("vehicle_guidebook_preview.gd") or path.ends_with(
			"vehicle_combat_mesh_icon.gd"
		):
			_expect(
				not source.contains("vehicle_combat_visual_library.gd"),
				"%s no longer consumes the superseded procedural actor provider"
				% path
			)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_VISUAL_ASSET_COVERAGE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
