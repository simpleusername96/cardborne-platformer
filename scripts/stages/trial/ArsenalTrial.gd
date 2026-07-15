class_name ArsenalTrial
extends StageBase

const Text = preload("res://scripts/ui/localization/LocalizedText.gd")

signal beat_changed(index: int, room_id: StringName, title: String, prompt: String)
signal beat_completed(room_id: StringName)
signal resolution_requested(outcome: StringName, transaction_id: StringName)
signal baseline_resolution_failed(outcome: StringName, code: StringName)
signal trial_completed
signal trial_skipped
signal trial_resolved(outcome: StringName)

const OUTCOME_COMPLETED := &"completed"
const OUTCOME_SKIPPED := &"skipped"
const ROOM_IDS: Array[StringName] = [
	&"movement",
	&"context_attack",
	&"guard",
	&"pickup_interaction",
	&"exit",
]
const BEAT_TITLES := [
	"GET MOVING",
	"READ THE RANGE",
	"HOLD THE LINE",
	"CLAIM THE CACHE",
	"LEAVE READY",
]
const BEAT_PROMPTS := [
	"Arrows move · Space jumps",
	"X attacks · range changes weapon",
	"Hold C to guard",
	"Take token · E opens cache",
	"E opens the exit",
]

@export var baseline_resolution_target_path: NodePath
@export var baseline_resolution_method: StringName = &"resolve_tutorial"
@export var baseline_transaction_id: StringName = &"tutorial:baseline"
@export var world_bounds := Rect2(0.0, 0.0, 3440.0, 720.0)

@onready var _near_target: ArsenalTrialIntentTarget = get_node(
	"Rooms/02ContextAttack/NearTarget"
) as ArsenalTrialIntentTarget
@onready var _far_target: ArsenalTrialIntentTarget = get_node(
	"Rooms/02ContextAttack/FarTarget"
) as ArsenalTrialIntentTarget
@onready var _guard_check: ArsenalTrialGuardCheck = get_node(
	"Rooms/03Guard/GuardCheck"
) as ArsenalTrialGuardCheck
@onready var _beat_label: Label = get_node("TrialUI/PromptPanel/Margin/VBox/BeatLabel") as Label
@onready var _prompt_label: Label = get_node(
	"TrialUI/PromptPanel/Margin/VBox/PromptLabel"
) as Label
@onready var _progress_label: Label = get_node(
	"TrialUI/PromptPanel/Margin/VBox/ProgressLabel"
) as Label
@onready var _skip_button: Button = get_node("TrialUI/SkipButton") as Button

var _active_beat_index: int = 0
var _completed_beats: Dictionary = {}
var _pickup_collected: bool = false
var _cache_interacted: bool = false
var _baseline_callback: Callable
var _baseline_target: Object
var _resolution_in_flight: bool = false
var _resolution_committed: bool = false
var _resolved_outcome: StringName = &""
var _gates: Array[StaticBody2D] = []


func _ready() -> void:
	_gates.assign([
		get_node("Rooms/01Movement/ExitGate") as StaticBody2D,
		get_node("Rooms/02ContextAttack/ExitGate") as StaticBody2D,
		get_node("Rooms/03Guard/ExitGate") as StaticBody2D,
		get_node("Rooms/04PickupInteraction/ExitGate") as StaticBody2D,
	])
	_guard_check.set_trial_enabled(false)
	super._ready()
	var localization := get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.connect(&"locale_changed", _on_locale_changed)
	_skip_button.text = _t("Skip Trial")
	_set_active_beat(0)


func _process(_delta: float) -> void:
	if _active_room_id() == &"context_attack":
		_observe_context_attack()


func configure_baseline_resolution_callback(callback: Callable) -> void:
	## The callback contract is `(completed: bool, transaction_id: StringName) -> Dictionary`.
	_baseline_callback = callback
	_baseline_target = null


func configure_baseline_resolution_target(
	target: Object,
	method_name: StringName = &"resolve_tutorial"
) -> void:
	_baseline_target = target
	baseline_resolution_method = method_name
	_baseline_callback = Callable()


func request_complete() -> Dictionary:
	return _request_resolution(OUTCOME_COMPLETED)


func request_skip() -> Dictionary:
	return _request_resolution(OUTCOME_SKIPPED)


func complete_stage() -> void:
	request_complete()


func get_room_ids() -> Array[StringName]:
	return ROOM_IDS.duplicate()


func get_layout_bounds() -> Rect2:
	return world_bounds


func get_resolution_snapshot() -> Dictionary:
	return {
		"resolved": _resolution_committed,
		"in_flight": _resolution_in_flight,
		"outcome": _resolved_outcome,
		"transaction_id": baseline_transaction_id,
	}


func _after_player_respawned() -> void:
	if player == null:
		return
	player.set_camera_limits(world_bounds)
	_configure_trial_combat()


func _configure_trial_combat() -> void:
	var combat := player.get_node_or_null("CombatController")
	if combat == null or not combat.has_method("configure_shared_hero"):
		return
	var loadout: Dictionary = RunState.get_hero_combat_loadout_snapshot().duplicate(true)
	if not bool(loadout.get("ok", false)):
		return

	# Practice confirms the real intent without spending persistent ranged supply.
	var ranged: Dictionary = (loadout.get("ranged", {}) as Dictionary).duplicate(true)
	var intent_policy: Dictionary = (
		(ranged.get("intent_policy", {}) as Dictionary).duplicate(true)
	)
	intent_policy["resource_cost"] = 0
	ranged["intent_policy"] = intent_policy
	loadout["ranged"] = ranged
	combat.call("configure_shared_hero", loadout, RunState.get_effective_stats())


func _observe_context_attack() -> void:
	if player == null or not is_instance_valid(player):
		return
	var combat := player.get_node_or_null("CombatController")
	if combat == null or not combat.has_method("get_state_snapshot"):
		return
	var state: Dictionary = combat.call("get_state_snapshot")
	var intent: Dictionary = state.get("committed_intent", {})
	if intent.is_empty():
		return
	var mode := StringName(intent.get("mode", &""))
	var target_id := StringName(intent.get("target_id", &""))
	if not _near_target.is_confirmed() and target_id == _near_target.get_intent_target_id():
		_near_target.confirm_intent(mode)
	elif not _far_target.is_confirmed() and target_id == _far_target.get_intent_target_id():
		_far_target.confirm_intent(mode)
	if _near_target.is_confirmed() and _far_target.is_confirmed():
		_complete_beat(&"context_attack")


func _request_resolution(outcome: StringName) -> Dictionary:
	if _resolution_committed:
		return _resolution_result(true, false, true, _resolved_outcome, {}, &"already_resolved")
	if _resolution_in_flight:
		return _resolution_result(false, false, false, outcome, {}, &"resolution_in_flight")
	if outcome not in [OUTCOME_COMPLETED, OUTCOME_SKIPPED]:
		return _resolution_result(false, false, false, outcome, {}, &"invalid_outcome")
	if outcome == OUTCOME_COMPLETED and _active_room_id() != &"exit":
		return _resolution_result(false, false, false, outcome, {}, &"trial_incomplete")
	if baseline_transaction_id == &"":
		return _resolution_result(false, false, false, outcome, {}, &"missing_transaction")

	var resolver := _baseline_resolver()
	if not resolver.is_valid():
		return _fail_resolution(outcome, &"missing_baseline_resolver")

	_resolution_in_flight = true
	resolution_requested.emit(outcome, baseline_transaction_id)
	var raw_result: Variant = resolver.call(
		outcome == OUTCOME_COMPLETED,
		baseline_transaction_id
	)
	_resolution_in_flight = false
	if not raw_result is Dictionary:
		return _fail_resolution(outcome, &"invalid_baseline_result")
	var baseline_result := raw_result as Dictionary
	if not bool(baseline_result.get("ok", false)):
		return _fail_resolution(
			outcome,
			StringName(baseline_result.get("code", &"baseline_rejected")),
			baseline_result
		)

	_resolution_committed = true
	_resolved_outcome = outcome
	_skip_button.disabled = true
	if outcome == OUTCOME_COMPLETED:
		if _active_room_id() == &"exit":
			_complete_beat(&"exit")
		trial_completed.emit()
		super.complete_stage()
	else:
		trial_skipped.emit()
	trial_resolved.emit(outcome)
	return _resolution_result(
		true,
		bool(baseline_result.get("changed", true)),
		bool(baseline_result.get("duplicate", false)),
		outcome,
		baseline_result,
		StringName(baseline_result.get("code", &"resolved"))
	)


func _baseline_resolver() -> Callable:
	if _baseline_callback.is_valid():
		return _baseline_callback
	var target: Object = _baseline_target
	if target == null and not baseline_resolution_target_path.is_empty():
		target = get_node_or_null(baseline_resolution_target_path)
	if target == null or not is_instance_valid(target):
		return Callable()
	if not target.has_method(baseline_resolution_method):
		return Callable()
	return Callable(target, baseline_resolution_method)


func _fail_resolution(
	outcome: StringName,
	code: StringName,
	baseline_result: Dictionary = {}
) -> Dictionary:
	_resolution_in_flight = false
	_prompt_label.text = _t("Try again")
	baseline_resolution_failed.emit(outcome, code)
	return _resolution_result(false, false, false, outcome, baseline_result, code)


func _resolution_result(
	ok: bool,
	changed: bool,
	duplicate: bool,
	outcome: StringName,
	baseline_result: Dictionary,
	code: StringName
) -> Dictionary:
	return {
		"ok": ok,
		"changed": changed,
		"duplicate": duplicate,
		"outcome": outcome,
		"transaction_id": baseline_transaction_id,
		"code": code,
		"baseline": baseline_result.duplicate(true),
	}


func _complete_beat(room_id: StringName) -> void:
	if _active_room_id() != room_id or bool(_completed_beats.get(room_id, false)):
		return
	_completed_beats[room_id] = true
	beat_completed.emit(room_id)
	if _active_beat_index < _gates.size():
		_open_gate(_active_beat_index)
	_active_beat_index += 1
	if _active_beat_index < ROOM_IDS.size():
		_set_active_beat(_active_beat_index)


func _open_gate(gate_index: int) -> void:
	if gate_index < 0 or gate_index >= _gates.size():
		return
	var gate := _gates[gate_index]
	var collision := gate.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var visual := gate.get_node_or_null("Visual") as CanvasItem
	if collision != null:
		collision.set_deferred("disabled", true)
	if visual != null:
		visual.visible = false


func _set_active_beat(index: int) -> void:
	if index < 0 or index >= ROOM_IDS.size():
		return
	_active_beat_index = index
	_render_active_beat(true)


func _render_active_beat(publish_change: bool) -> void:
	var index := _active_beat_index
	var title := _t(BEAT_TITLES[index])
	var prompt := _t(BEAT_PROMPTS[index])
	_beat_label.text = title
	_prompt_label.text = prompt
	_progress_label.text = "%d / %d" % [index + 1, ROOM_IDS.size()]
	_guard_check.set_trial_enabled(ROOM_IDS[index] == &"guard")
	if publish_change:
		beat_changed.emit(index + 1, ROOM_IDS[index], title, prompt)


func _active_room_id() -> StringName:
	if _active_beat_index < 0 or _active_beat_index >= ROOM_IDS.size():
		return &""
	return ROOM_IDS[_active_beat_index]


func _on_movement_goal_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_complete_beat(&"movement")


func _on_guard_succeeded() -> void:
	_complete_beat(&"guard")


func _on_training_pickup_collected(_player: Node) -> void:
	_pickup_collected = true
	if _cache_interacted:
		_complete_beat(&"pickup_interaction")
	else:
		_prompt_label.text = _t("Inspect the cache")


func _on_training_cache_interacted(_player: Node) -> void:
	_cache_interacted = true
	if _pickup_collected:
		_complete_beat(&"pickup_interaction")
	else:
		_prompt_label.text = _t("Collect the token")


func _on_fall_reset_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		reset_player_after_fall("trial_fall")


func _on_skip_button_pressed() -> void:
	request_skip()


func _on_locale_changed(_locale: String) -> void:
	_skip_button.text = _t("Skip Trial")
	_render_active_beat(false)


func _t(source: Variant, values: Array = []) -> String:
	return Text.resolve(self, source, values)
