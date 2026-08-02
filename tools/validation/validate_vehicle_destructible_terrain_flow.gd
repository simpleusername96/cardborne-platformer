extends SceneTree

const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldRegistry = preload("res://scripts/vehicle/vehicle_field_registry.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")

const FIXED_SEED := 0xC4A2B0

var failures: Array[String] = []


func _initialize() -> void:
	for field_id in FieldRegistry.FIELD_IDS:
		_validate_field(field_id)
	_finish()


func _validate_field(field_id: StringName) -> void:
	var definition := FieldRegistry.definition(field_id)
	var layout = Generator.generate(FIXED_SEED, Catalog.STAGE_IDS, field_id)
	_expect(layout != null, "%s compiles reward enclosures" % field_id)
	if layout == null:
		return
	Catalog.activate_field(field_id)
	var walls: Array[Rect2] = []
	var bulkheads: Array[Dictionary] = []
	for value in Array(definition["features"]):
		var feature := Dictionary(value)
		match StringName(feature["kind"]):
			&"structural_wall":
				walls.append(Rect2(feature["rect"]))
			&"breakable_bulkhead":
				bulkheads.append(feature)
	_expect(walls.size() == 6, "%s authors three structural walls per enclosure" % field_id)
	_expect(bulkheads.size() == 2, "%s authors exactly two breakable entrances" % field_id)

	for stage_id in Catalog.STAGE_IDS:
		var tactical = layout.tactical_layout(stage_id)
		var guarded_crates := layout.crate_blueprint(stage_id).filter(
			func(spec: Dictionary) -> bool: return spec.has("guarded_by")
		)
		_expect(layout.crate_blueprint(stage_id).size() == 8, "%s/%s keeps eight crates" % [field_id, stage_id])
		_expect(guarded_crates.size() == 2, "%s/%s relocates exactly two crates" % [field_id, stage_id])
		var closed_blockers: Array = Array(tactical.cover_rects).duplicate()
		closed_blockers.append_array(walls)
		var open_blockers := closed_blockers.duplicate()
		for bulkhead in bulkheads:
			closed_blockers.append(Rect2(bulkhead["rect"]))
			_validate_entrance_flow(
				field_id,
				stage_id,
				bulkhead,
				closed_blockers,
				open_blockers,
				guarded_crates
			)

	var persistent := {}
	var runtime := TerrainRuntime.new()
	runtime.configure(definition["features"], persistent, false)
	_expect(runtime.structural_wall_rects() == walls, "%s runtime preserves exact structural-wall rectangles" % field_id)
	for bulkhead in bulkheads:
		var bulkhead_id := StringName(bulkhead["id"])
		for hit_index in 4:
			_expect(
				runtime.damage_bulkhead(bulkhead_id, 18.0) == (hit_index == 3),
				"%s/%s opens on the fourth base primary hit" % [field_id, bulkhead_id]
			)
	_expect(runtime.live_bulkhead_rects().is_empty(), "%s both opened entrances leave runtime blockers" % field_id)
	var next_stage := TerrainRuntime.new()
	next_stage.configure(definition["features"], persistent, true)
	_expect(next_stage.live_bulkhead_rects().is_empty(), "%s opened entrances persist across stages" % field_id)


func _validate_entrance_flow(
	field_id: StringName,
	stage_id: StringName,
	bulkhead: Dictionary,
	closed_blockers: Array,
	open_blockers: Array,
	guarded_crates: Array
) -> void:
	var bulkhead_id := StringName(bulkhead["id"])
	var reward_pos := Vector2(bulkhead["reward_pos"])
	var matching := guarded_crates.filter(
		func(spec: Dictionary) -> bool:
			return StringName(spec["guarded_by"]) == bulkhead_id
	)
	_expect(
		matching.size() == 1 and Vector2(matching[0]["pos"]) == reward_pos,
		"%s/%s/%s places its guarded crate at authored reward_pos" % [field_id, stage_id, bulkhead_id]
	)
	var start := Catalog.player_start(stage_id)
	_expect(
		not Rules.grid_reachable_with_extra(
			start, reward_pos, Rules.PLAYER_RADIUS, 48.0, false, stage_id, closed_blockers
		),
		"%s/%s/%s is movement-sealed while intact" % [field_id, stage_id, bulkhead_id]
	)
	_expect(
		Rules.grid_reachable_with_extra(
			start, reward_pos, Rules.PLAYER_RADIUS, 48.0, false, stage_id, open_blockers
		),
		"%s/%s/%s becomes movement-reachable after opening" % [field_id, stage_id, bulkhead_id]
	)
	var bulkhead_rect := Rect2(bulkhead["rect"])
	var outward := (bulkhead_rect.get_center() - reward_pos).normalized()
	var approach := bulkhead_rect.get_center() + outward * 260.0
	_expect(
		not Rules.has_line_of_sight_with_extra(
			approach, reward_pos, 5.0, false, stage_id, closed_blockers
		),
		"%s/%s/%s blocks LOS while intact" % [field_id, stage_id, bulkhead_id]
	)
	_expect(
		Rules.has_line_of_sight_with_extra(
			approach, reward_pos, 5.0, false, stage_id, open_blockers
		),
		"%s/%s/%s opens the same LOS boundary" % [field_id, stage_id, bulkhead_id]
	)
	var closed_hit := Rules.first_cover_hit_with_extra(
		approach, reward_pos, 7.0, false, stage_id, closed_blockers
	)
	var open_hit := Rules.first_cover_hit_with_extra(
		approach, reward_pos, 7.0, false, stage_id, open_blockers
	)
	_expect(
		bool(closed_hit.get("hit", false))
		and Rect2(closed_hit.get("rect", Rect2())) == bulkhead_rect,
		"%s/%s/%s is the projectile entrance blocker" % [field_id, stage_id, bulkhead_id]
	)
	_expect(
		not bool(open_hit.get("hit", false)),
		"%s/%s/%s removal opens the projectile path" % [field_id, stage_id, bulkhead_id]
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
