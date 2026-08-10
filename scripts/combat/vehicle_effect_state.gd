class_name VehicleEffectState
extends RefCounted

## Reusable transient presentation state. Gameplay side effects remain with
## their originating runtime owner and are never dispatched from this value.

var kind: StringName = &""
var pos := Vector2.ZERO
var color := Color.WHITE
var time := 0.0
var duration := 0.0
var radius := 0.0
var secondary_radius := 0.0
var direction := Vector2.ZERO
var value := 0.0
var multiplier := 1.0


func configure(
	next_kind: StringName,
	position: Vector2,
	next_color: Color,
	next_duration: float,
	next_radius: float,
	next_direction: Vector2 = Vector2.ZERO,
	next_value: float = 0.0,
	next_multiplier: float = 1.0,
	next_secondary_radius: float = 0.0
) -> void:
	kind = next_kind
	pos = position
	color = next_color
	time = next_duration
	duration = next_duration
	radius = next_radius
	secondary_radius = next_secondary_radius
	direction = next_direction
	value = next_value
	multiplier = next_multiplier


func reset() -> void:
	kind = &""
	pos = Vector2.ZERO
	color = Color.WHITE
	time = 0.0
	duration = 0.0
	radius = 0.0
	secondary_radius = 0.0
	direction = Vector2.ZERO
	value = 0.0
	multiplier = 1.0
