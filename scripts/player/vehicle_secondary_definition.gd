class_name VehicleSecondaryDefinition
extends Resource

@export var id: StringName
@export var upgrade_id: StringName
@export var name_key := ""
@export var description_key := ""
@export var behavior: StringName
@export var values_by_level: Array[float] = []
@export var auxiliary_by_level: Array[float] = []
@export var cap_by_level: Array[int] = []


func value(level: int) -> float:
	return values_by_level[clampi(level - 1, 0, values_by_level.size() - 1)] if not values_by_level.is_empty() else 0.0


func auxiliary(level: int) -> float:
	return auxiliary_by_level[clampi(level - 1, 0, auxiliary_by_level.size() - 1)] if not auxiliary_by_level.is_empty() else 0.0


func cap(level: int) -> int:
	return cap_by_level[clampi(level - 1, 0, cap_by_level.size() - 1)] if not cap_by_level.is_empty() else 0
