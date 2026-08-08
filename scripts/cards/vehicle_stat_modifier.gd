class_name VehicleStatModifier
extends Resource

@export var stat_id: StringName
@export_enum("multiply", "add") var operation := "multiply"
## Presentation unit for the upgrade-card comparison row. Runtime values keep
## their domain unit; the UI only formats the already-authored number.
@export_enum("none", "percent") var display_unit := "none"
@export var values_by_level: Array[float] = []


func value_at(level: int) -> float:
	if values_by_level.is_empty() or level <= 0:
		return 1.0 if operation == "multiply" else 0.0
	return values_by_level[mini(level, values_by_level.size()) - 1]
