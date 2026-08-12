class_name VehicleActiveWeaponDefinition
extends Resource

## Immutable authored values for one equipped active weapon.

@export var id: StringName
@export var upgrade_id: StringName
@export var name_key := ""
@export var startup_seconds := 0.0
@export var cooldown_seconds := 0.0
@export var damage_by_level: Array[float] = []
@export var size_by_level: Array[float] = []
@export var active_seconds := 0.0
@export var auxiliary_size := 0.0


func damage(level: int) -> float:
	return damage_by_level[clampi(level - 1, 0, damage_by_level.size() - 1)] if not damage_by_level.is_empty() else 0.0


func size(level: int) -> float:
	return size_by_level[clampi(level - 1, 0, size_by_level.size() - 1)] if not size_by_level.is_empty() else 0.0
