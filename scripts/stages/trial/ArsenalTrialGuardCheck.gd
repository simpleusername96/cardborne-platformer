class_name ArsenalTrialGuardCheck
extends Node2D

signal guard_succeeded

enum Phase {
	IDLE,
	TELEGRAPH,
	PULSE,
	RECOVERY,
}

@export_range(0.2, 2.0, 0.05) var telegraph_seconds: float = 0.75
@export_range(0.05, 0.5, 0.01) var pulse_seconds: float = 0.16
@export_range(0.2, 2.0, 0.05) var retry_seconds: float = 0.65

@onready var _trigger: Area2D = get_node("Trigger") as Area2D
@onready var _warning: CanvasItem = get_node("Warning") as CanvasItem
@onready var _pulse: CanvasItem = get_node("Pulse") as CanvasItem

var _player: Node
var _phase: Phase = Phase.IDLE
var _phase_time: float = 0.0
var _trial_enabled: bool = false
var _completed: bool = false


func _ready() -> void:
	_trigger.body_entered.connect(_on_body_entered)
	_trigger.body_exited.connect(_on_body_exited)
	_reset_cycle()


func _process(delta: float) -> void:
	if not _trial_enabled or _player == null:
		return
	if _completed:
		_phase_time = maxf(_phase_time - delta, 0.0)
		if is_zero_approx(_phase_time):
			_pulse.visible = false
		return

	_phase_time = maxf(_phase_time - delta, 0.0)
	match _phase:
		Phase.IDLE:
			_begin_telegraph()
		Phase.TELEGRAPH:
			if is_zero_approx(_phase_time):
				_fire_pulse()
		Phase.PULSE:
			if is_zero_approx(_phase_time):
				_begin_recovery()
		Phase.RECOVERY:
			if is_zero_approx(_phase_time):
				_begin_telegraph()


func set_trial_enabled(enabled: bool) -> void:
	_trial_enabled = enabled
	if not enabled:
		_reset_cycle()


func _begin_telegraph() -> void:
	_phase = Phase.TELEGRAPH
	_phase_time = telegraph_seconds
	_warning.visible = true
	_pulse.visible = false


func _fire_pulse() -> void:
	_phase = Phase.PULSE
	_phase_time = pulse_seconds
	_warning.visible = false
	_pulse.visible = true
	if _guard_is_active():
		_completed = true
		guard_succeeded.emit()


func _begin_recovery() -> void:
	_phase = Phase.RECOVERY
	_phase_time = retry_seconds
	_warning.visible = false
	_pulse.visible = false


func _guard_is_active() -> bool:
	var combat := _player.get_node_or_null("CombatController")
	if combat == null or not combat.has_method("get_state_snapshot"):
		return false
	var combat_state: Dictionary = combat.call("get_state_snapshot")
	var guard_state: Dictionary = combat_state.get("guard", {})
	return (
		bool(combat_state.get("shared_hero_mode", false))
		and StringName(guard_state.get("phase", &"")) == &"active"
	)


func _reset_cycle() -> void:
	_phase = Phase.IDLE
	_phase_time = 0.0
	_warning.visible = false
	_pulse.visible = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player = body


func _on_body_exited(body: Node) -> void:
	if body == _player:
		_player = null
		_reset_cycle()
