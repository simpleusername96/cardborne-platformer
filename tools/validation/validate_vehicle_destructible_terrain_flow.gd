extends SceneTree

## Compatibility entrypoint for the retired breakable-bulkhead validator.
## Structural walls are now immutable; Mystery Devices are the sole neutral
## destructible map interaction.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const MysteryDeviceRuntime = preload("res://scripts/vehicle/vehicle_mystery_device_runtime.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	for field_id in FieldRegistry.FIELD_IDS:
		_validate_field(field_id)
	_validate_mystery_device_authority()
	_finish()


func _validate_field(field_id: StringName) -> void:
	var layout := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
	_expect(layout != null, "%s compiles the retired-terrain compatibility fixture" % field_id)
	if layout == null:
		return
	var blueprint := layout.run_feature_blueprint()
	var walls: Array[Rect2] = []
	for value in blueprint:
		var feature := Dictionary(value)
		var kind := StringName(feature.get("kind", &""))
		_expect(kind != &"breakable_bulkhead", "%s has no breakable bulkhead" % field_id)
		_expect(not feature.has("guarded_by"), "%s has no guarded terrain reward" % field_id)
		if kind == &"structural_wall":
			walls.append(Rect2(feature["rect"]))
	_expect(not walls.is_empty(), "%s keeps structural walls as blockers" % field_id)
	var runtime := TerrainRuntime.new()
	runtime.configure(blueprint)
	_expect(
		runtime.structural_wall_rects() == walls,
		"%s runtime preserves immutable structural-wall rectangles" % field_id
	)
	_expect(
		not runtime.has_method("damage_bulkhead") and not runtime.has_method("live_bulkhead_rects"),
		"%s runtime exposes no mutable bulkhead API" % field_id
	)
	for stage_id in Catalog.STAGE_IDS:
		var pickups := layout.pickup_blueprint(stage_id)
		_expect(pickups.size() == 14, "%s/%s exposes fourteen direct pickups" % [field_id, stage_id])
		for pickup in pickups:
			_expect(not Dictionary(pickup).has("guarded_by"), "%s/%s pickup has no terrain guard" % [field_id, stage_id])


func _validate_mystery_device_authority() -> void:
	var runtime := MysteryDeviceRuntime.new()
	runtime.configure([{"id":&"device", "pos":Vector2.ZERO, "outcome":&"gravity_pull"}], 1, &"stage_1")
	var ignored := runtime.receive_damage(&"device", 90.0, &"hostile", &"direct")
	_expect(not bool(ignored["accepted"]), "neutral device ignores hostile damage")
	var resolved := runtime.receive_damage(&"device", 90.0, &"player", &"direct")
	_expect(
		bool(resolved["accepted"]) and bool(resolved["broken"]),
		"player direct damage is the neutral map destructible interaction"
	)
	var event := Dictionary(resolved["break_event"])
	_expect(
		not bool(event["device_counts_for_quota"]) and not bool(event["grants_experience"]),
		"destroying a neutral device grants neither quota nor XP"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition and failures.size() < 64:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_DESTRUCTIBLE_TERRAIN_FLOW_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
