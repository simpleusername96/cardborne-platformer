class_name VehicleFieldLayout
extends RefCounted

## Run-scoped field aggregate. Immutable tactical placement lives in stage children.

const TacticalLayout = preload("res://scripts/vehicle/vehicle_stage_tactical_layout.gd")

var seed := 0
var fingerprint := 0
var field_id: StringName = &""
var field_definition: Dictionary = {}

var _tactical_layouts: Dictionary = {}


func configure(
	layout_seed: int,
	selected_field_id: StringName,
	selected_field_definition: Dictionary,
	layouts_by_stage: Dictionary
) -> void:
	seed = layout_seed
	field_id = selected_field_id
	field_definition = selected_field_definition.duplicate(true)
	_tactical_layouts = layouts_by_stage.duplicate()
	fingerprint = hash(var_to_str(canonical_blueprint()))


func tactical_layout(stage_id: StringName) -> TacticalLayout:
	return _tactical_layouts.get(stage_id) as TacticalLayout


func stage_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for value in _tactical_layouts.keys():
		result.append(StringName(value))
	result.sort_custom(
		func(a: StringName, b: StringName) -> bool:
			return String(a) < String(b)
	)
	return result


func pickup_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var layout := tactical_layout(stage_id)
	return layout.pickup_blueprint() if layout != null else []


func mystery_device_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var layout := tactical_layout(stage_id)
	return layout.mystery_device_blueprint() if layout != null else []


func run_feature_blueprint() -> Array[Dictionary]:
	return Array(field_definition.get("features", [])).duplicate(true)


func encounter_seed(stage_id: StringName) -> int:
	var layout := tactical_layout(stage_id)
	return layout.encounter_seed if layout != null else seed


func canonical_blueprint() -> Dictionary:
	var stages: Array[Dictionary] = []
	for stage_id in stage_ids():
		var layout := tactical_layout(stage_id)
		if layout != null:
			stages.append(layout.canonical_blueprint())
	return {
		"seed":seed,
		"field_id":String(field_id),
		"run_features":Array(field_definition.get("features", [])).duplicate(true),
		"stages":stages,
	}


func debug_snapshot(active_stage_id: StringName = &"") -> Dictionary:
	var stages: Array[Dictionary] = []
	for stage_id in stage_ids():
		var layout := tactical_layout(stage_id)
		if layout != null:
			stages.append(layout.debug_snapshot())
	var active := tactical_layout(active_stage_id)
	return {
		"seed":seed,
		"fingerprint":fingerprint,
		"field_id":field_id,
		"stage_count":stages.size(),
		"active_stage":active.debug_snapshot() if active != null else {},
		"stages":stages,
	}
