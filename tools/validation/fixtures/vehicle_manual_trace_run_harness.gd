extends "res://scripts/vehicle/vehicle_run.gd"

## Runs only the manual-trace orchestration boundary without initializing gameplay.


func _ready() -> void:
	set_process(false)
	set_physics_process(false)
