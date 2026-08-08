extends SceneTree

## Compatibility entrypoint that prevents retired damage-floor mechanics from
## returning to generated fields or terrain snapshots.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	_validate_authored_fields()
	_finish()


func _validate_authored_fields() -> void:
	for field_id in FieldRegistry.FIELD_IDS:
		var layout := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
		_expect(layout != null, "%s compiles the terrain compatibility fixture" % field_id)
		if layout == null:
			continue
		for value in layout.run_feature_blueprint():
			var feature := Dictionary(value)
			var kind := StringName(feature.get("kind", &""))
			_expect(kind != &"wear_collapse_tile", "%s has no wear-collapse tile" % field_id)


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_WEAR_COLLAPSE_TILES_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
