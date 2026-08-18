class_name VehicleFieldRegistry
extends RefCounted

## Immutable field registry. Runtime selection is stored by VehicleFieldLayout.

const Field01 = preload("res://scripts/vehicle/stages/field_01.gd")
const Field02 = preload("res://scripts/vehicle/stages/field_02.gd")
const Field03 = preload("res://scripts/vehicle/stages/field_03.gd")

const FIELD_IDS: Array[StringName] = [
	Field01.FIELD_ID,
	Field02.FIELD_ID,
	Field03.FIELD_ID,
]


static func normalized_id(field_id: StringName) -> StringName:
	return field_id if field_id in FIELD_IDS else FIELD_IDS[0]


static func definition(field_id: StringName) -> Dictionary:
	match normalized_id(field_id):
		Field02.FIELD_ID:
			return Field02.definition()
		Field03.FIELD_ID:
			return Field03.definition()
		_:
			return Field01.definition()


static func select_id(layout_seed: int) -> StringName:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:field:v1" % layout_seed)
	return FIELD_IDS[rng.randi_range(0, FIELD_IDS.size() - 1)]
