class_name VehicleActiveWeaponDefinition
extends Resource

## Immutable authored values for one equipped active weapon.

@export var id: StringName
@export var upgrade_id: StringName
@export var name_key := ""
@export var startup_seconds := 0.0
@export var cooldown_by_level: Array[float] = []
@export var size_by_level: Array[float] = []
@export var duration_by_level: Array[float] = []
@export var strength_by_level: Array[float] = []
@export var auxiliary_size_by_level: Array[float] = []


func duration(level: int) -> float:
	return duration_by_level[clampi(level - 1, 0, duration_by_level.size() - 1)] if not duration_by_level.is_empty() else 0.0


func strength(level: int) -> float:
	return strength_by_level[clampi(level - 1, 0, strength_by_level.size() - 1)] if not strength_by_level.is_empty() else 0.0


func size(level: int) -> float:
	return size_by_level[clampi(level - 1, 0, size_by_level.size() - 1)] if not size_by_level.is_empty() else 0.0


func cooldown(level: int) -> float:
	return cooldown_by_level[clampi(level - 1, 0, cooldown_by_level.size() - 1)] if not cooldown_by_level.is_empty() else 0.0


func auxiliary_size(level: int) -> float:
	return auxiliary_size_by_level[clampi(level - 1, 0, auxiliary_size_by_level.size() - 1)] if not auxiliary_size_by_level.is_empty() else 0.0
