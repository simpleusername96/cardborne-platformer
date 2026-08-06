extends SceneTree

## Compatibility entrypoint for the retired wear-collapse-tile validator.
## Broad, traversable hazard zones now own immediate, ticking, and linger damage.

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	_validate_authored_fields()
	_validate_crossing_damage_and_linger()
	_finish()


func _validate_authored_fields() -> void:
	for field_id in FieldRegistry.FIELD_IDS:
		var layout := Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
		_expect(layout != null, "%s compiles the hazard compatibility fixture" % field_id)
		if layout == null:
			continue
		var hazards := 0
		for value in layout.run_feature_blueprint():
			var feature := Dictionary(value)
			var kind := StringName(feature.get("kind", &""))
			_expect(kind != &"wear_collapse_tile", "%s has no wear-collapse tile" % field_id)
			if kind != &"hazard_zone":
				continue
			hazards += 1
			var rect := Rect2(feature["rect"])
			_expect(
				rect.size.x >= 480.0 and rect.size.y >= 480.0,
				"%s hazard zone is a broad area, not a thin pass-through wall" % field_id
			)
		_expect(hazards == Generator.HAZARD_ZONE_COUNT, "%s has four run-fixed hazard zones" % field_id)
		var runtime := TerrainRuntime.new()
		runtime.configure(layout.run_feature_blueprint())
		var snapshot := runtime.snapshot()
		_expect(
			not snapshot.has("wear") and not snapshot.has("wear_runtime") and not snapshot.has("wear_tiles"),
			"%s exposes no retired wear state" % field_id
		)


func _validate_crossing_damage_and_linger() -> void:
	var runtime := TerrainRuntime.new()
	runtime.configure([{
		"id":&"bog", "kind":&"hazard_zone", "variant":&"toxic_bog",
		"affinity":&"toxin", "rect":Rect2(100, 100, 768, 576),
	}])
	_expect(
		runtime.structural_wall_rects().is_empty(),
		"hazard zones do not become movement blockers"
	)
	_expect(
		runtime.hazard_damage_for_actor("player", Vector2(0, 200), Vector2(150, 200), 0.0, &"player", 0.1)
		== TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"hazard entry deals immediate player damage"
	)
	_expect(
		runtime.hazard_damage_for_actor("player", Vector2(150, 200), Vector2(150, 200), 0.0, &"player", 0.75)
		== TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"hazard contact deals its scheduled tick"
	)
	_expect(
		runtime.hazard_damage_for_actor("player", Vector2(150, 200), Vector2(1000, 200), 0.0, &"player", 0.75)
		== TerrainRuntime.HAZARD_PLAYER_DAMAGE,
		"hazard damage lingers after exit"
	)
	_expect(
		runtime.hazard_damage_for_actor("ordinary", Vector2(0, 300), Vector2(150, 300), 0.0, &"ordinary", 0.1)
		== TerrainRuntime.HAZARD_ORDINARY_DAMAGE,
		"ordinary enemies receive neutral hazard damage"
	)


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
