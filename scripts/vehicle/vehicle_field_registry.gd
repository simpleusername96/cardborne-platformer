class_name VehicleFieldRegistry
extends RefCounted

## Immutable field registry. Runtime selection is stored by VehicleFieldLayout.

const Drowned = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")
const Archive = preload("res://scripts/vehicle/stages/tidal_archive_field.gd")
const Drydock = preload("res://scripts/vehicle/stages/storm_drydock_field.gd")

const FIELD_IDS: Array[StringName] = [
	Drowned.FIELD_ID,
	Archive.FIELD_ID,
	Drydock.FIELD_ID,
]


static func normalized_id(field_id: StringName) -> StringName:
	return field_id if field_id in FIELD_IDS else FIELD_IDS[0]


static func definition(field_id: StringName) -> Dictionary:
	match normalized_id(field_id):
		Archive.FIELD_ID:
			return Archive.definition()
		Drydock.FIELD_ID:
			return Drydock.definition()
		_:
			return Drowned.definition()


static func select_id(layout_seed: int) -> StringName:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:field:v1" % layout_seed)
	return FIELD_IDS[rng.randi_range(0, FIELD_IDS.size() - 1)]
