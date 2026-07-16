class_name SafeIntermission
extends StageBase

signal continue_requested

const WORLD_BOUNDS := Rect2(0.0, 0.0, 1280.0, 720.0)

var _setup_succeeded := false
var _continue_committed := false

@onready var exit_gate: ExitPortal = $Geometry/Anchors/Objective/ExitGate


func _ready() -> void:
	if exit_gate == null:
		push_error("Safe Intermission has no Continue gate.")
		return
	exit_gate.prompt_text = "Continue"
	exit_gate.disabled_prompt_text = ""
	exit_gate.set_interaction_enabled(true)
	_setup_succeeded = true
	super._ready()
	if player != null:
		player.set_camera_limits(WORLD_BOUNDS)


func is_setup_complete() -> bool:
	return _setup_succeeded and player != null


func complete_stage() -> void:
	if _continue_committed:
		return
	_continue_committed = true
	continue_requested.emit()
	SignalBus.status_message_changed.emit("Leaving the safe intermission.")


func has_combat_content() -> bool:
	return false


func get_world_bounds() -> Rect2:
	return WORLD_BOUNDS
