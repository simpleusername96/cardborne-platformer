extends SceneTree

## Compatibility entrypoint for the retired repair/overdrive field scheduler.
## Terrain owns only structural-wall records and player-operated transit gates.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	_validate_no_support_schedule()
	_validate_transit_gate()
	_finish()


func _validate_no_support_schedule() -> void:
	for field_id in FieldRegistry.FIELD_IDS:
		var layout := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
		_expect(layout != null, "%s compiles the retired-support compatibility fixture" % field_id)
		if layout == null:
			continue
		for feature_value in layout.run_feature_blueprint():
			var feature := Dictionary(feature_value)
			var kind := StringName(feature.get("kind", &""))
			_expect(kind != &"support_field", "%s has no support-field feature" % field_id)
			_expect(kind != &"overdrive_field", "%s has no overdrive-field feature" % field_id)
		var runtime := TerrainRuntime.new()
		runtime.configure(layout.run_feature_blueprint())
		var first := runtime.snapshot()
		var second := runtime.snapshot()
		_expect(
			not first.has("support_fields") and not first.has("overdrive_active"),
			"%s exposes no support scheduler state" % field_id
		)
		_expect(var_to_str(first) == var_to_str(second), "%s cold terrain snapshot is stable" % field_id)


func _validate_transit_gate() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure([
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2.ZERO},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(1600.0, 0.0)},
	])
	var events: Array[Dictionary] = []
	for _step in 4:
		events.append_array(runtime.advance(0.1, Vector2.ZERO))
	_expect(
		events.size() == 1
		and StringName(events[0]["kind"]) == &"transit"
		and Vector2(events[0]["destination"]) == Vector2(1600.0, 0.0),
		"transit gate remains an unscheduled player-operated terrain utility"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_SUPPORT_FIELD_SCHEDULE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
