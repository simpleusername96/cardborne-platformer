extends SceneTree

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const EXPECTED_CATEGORY_COUNTS := {
	&"attachment":1,
	&"actor":18,
	&"boss":5,
	&"secondary":4,
	&"projectile":2,
	&"pickup":4,
	&"world":18,
	&"upgrade":12,
}

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
		AssetProvider.asset_ids().size() == 64,
		"final production coverage totals 61 semantic PNGs plus three approved SVGs"
	)
	var unique_paths := {}
	for asset_id in AssetProvider.asset_ids():
		var path := String(AssetProvider.descriptor(asset_id).get("path", ""))
		_expect(not path.is_empty(), "%s has one production path" % asset_id)
		_expect(
			not unique_paths.has(path),
			"%s does not reuse the path owned by %s"
			% [asset_id, unique_paths.get(path, &"")]
		)
		unique_paths[path] = asset_id
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
