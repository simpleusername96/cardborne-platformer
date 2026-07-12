class_name SlimeKingActor
extends CharacterBody2D

signal snapshot_changed(snapshot: Dictionary)
signal pattern_started(pattern_id: StringName, snapshot: Dictionary)
signal pattern_state_changed(pattern_id: StringName, state: StringName, snapshot: Dictionary)
signal phase_changed(phase: int, snapshot: Dictionary)
signal stagger_started(duration: float, snapshot: Dictionary)
signal stagger_finished(snapshot: Dictionary)
signal defeated(reward_table_id: StringName, snapshot: Dictionary)

const REVIEWED_STAGGER_CAPACITY := 100
const PHASE_TRANSITION_DURATION := 0.75
const DEFEAT_REWARD_TABLE_ID := &"boss_clear_slime_king"
const DEFAULT_SCHEDULER_SEED := 804018
const PATTERN_PATHS: Array[String] = [
	"res://data/bosses/jump_slam.tres",
	"res://data/bosses/body_bump.tres",
	"res://data/bosses/poison_bands.tres",
	"res://data/bosses/small_slime_summon.tres",
]

const ACTOR_ACTIVE := &"active"
const ACTOR_PHASE_TRANSITION := &"phase_transition"
const ACTOR_STAGGERED := &"staggered"
const ACTOR_DEFEATED := &"defeated"
const ACTOR_CANCELLED := &"cancelled"
const ACTOR_DORMANT := &"dormant"

@export var arena_ground_rect := Rect2(100.0, 612.0, 1080.0, 28.0)
@export var arena_platform_rects: Array[Rect2] = [
	Rect2(200.0, 500.0, 260.0, 14.0),
	Rect2(830.0, 410.0, 240.0, 14.0),
]
@export var summon_spawn_candidates := PackedVector2Array([
	Vector2(400.0, 640.0),
	Vector2(570.0, 640.0),
	Vector2(940.0, 640.0),
	Vector2(1100.0, 640.0),
])

@onready var visual: Node2D = $Visual
@onready var body_visual: Polygon2D = $Visual/Body
@onready var crown_visual: Polygon2D = $Visual/Crown
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var pattern_runtime: SlimeKingPatternRuntime = $PatternRuntime

var health_model: SlimeKing
var scheduler: BossPatternScheduler
var current_health: int = 0

var _patterns: Array[BossPatternDefinition] = []
var _patterns_by_id: Dictionary = {}
var _configuration_errors := PackedStringArray()
var _target_override: Node2D
var _actor_state: StringName = ACTOR_DORMANT
var _encounter_active: bool = false
var _scheduler_enabled: bool = true
var _external_clock: bool = false
var _phase_transition_remaining: float = 0.0
var _phase_transition_pending: bool = false
var _defeat_emitted: bool = false
var _scheduler_seed: int = DEFAULT_SCHEDULER_SEED
var _flash_serial: int = 0
var _base_body_color := Color(0.42, 0.82, 0.28, 1.0)
var _base_crown_color := Color(0.96, 0.72, 0.20, 1.0)


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	health_model = SlimeKing.new(REVIEWED_STAGGER_CAPACITY)
	current_health = health_model.health
	_load_patterns()
	scheduler = BossPatternScheduler.new(_patterns, _scheduler_seed)
	for error in scheduler.validate_configuration():
		_configuration_errors.append(error)
	pattern_runtime.configure(
		self,
		arena_ground_rect,
		arena_platform_rects,
		summon_spawn_candidates
	)
	pattern_runtime.pattern_started.connect(_on_runtime_pattern_started)
	pattern_runtime.state_changed.connect(_on_runtime_state_changed)
	pattern_runtime.damage_committed.connect(_on_runtime_damage_committed)
	pattern_runtime.add_count_changed.connect(_on_runtime_add_count_changed)
	_set_hurtbox_enabled(false)
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null and not bus.player_died.is_connected(_on_player_died):
		bus.player_died.connect(_on_player_died)
	_base_body_color = body_visual.color
	_base_crown_color = crown_visual.color
	reset_pattern_pose()
	_publish_snapshot()


func _exit_tree() -> void:
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null and bus.player_died.is_connected(_on_player_died):
		bus.player_died.disconnect(_on_player_died)
	if pattern_runtime != null:
		pattern_runtime.shutdown()


func _physics_process(delta: float) -> void:
	if not _external_clock:
		advance_runtime(delta)


func activate_encounter(seed: int = DEFAULT_SCHEDULER_SEED) -> bool:
	if (
		not is_runtime_ready()
		or _encounter_active
		or health_model.state != BossBase.STATE_DORMANT
	):
		return false
	_scheduler_seed = seed
	scheduler.reset(seed)
	if not health_model.activate():
		return false
	current_health = health_model.health
	_actor_state = ACTOR_ACTIVE
	_encounter_active = true
	_phase_transition_pending = false
	_set_hurtbox_enabled(true)
	pattern_runtime.prepare_for_schedule()
	_schedule_next_if_ready()
	_publish_snapshot()
	return true


func advance_runtime(delta: float) -> void:
	if not _encounter_active or not is_finite(delta) or delta <= 0.0:
		return
	if _actor_state == ACTOR_PHASE_TRANSITION:
		_phase_transition_remaining = maxf(_phase_transition_remaining - delta, 0.0)
		if is_zero_approx(_phase_transition_remaining):
			_actor_state = ACTOR_ACTIVE
			_set_hurtbox_enabled(true)
			reset_pattern_pose()
			pattern_runtime.prepare_for_schedule()
			_schedule_next_if_ready()
			_publish_snapshot()
		return
	if health_model.state == BossBase.STATE_STAGGERED:
		if health_model.advance_time(delta):
			current_health = health_model.health
			stagger_finished.emit(get_runtime_snapshot())
			if _phase_transition_pending:
				_begin_phase_transition()
			else:
				_actor_state = ACTOR_ACTIVE
				reset_pattern_pose()
				pattern_runtime.prepare_for_schedule()
				_schedule_next_if_ready()
				_publish_snapshot()
		return
	if _actor_state != ACTOR_ACTIVE:
		return
	pattern_runtime.advance_time(delta)
	_schedule_next_if_ready()


func receive_damage(damage_info: DamageInfo) -> void:
	if (
		damage_info == null
		or not _encounter_active
		or _actor_state in [ACTOR_DORMANT, ACTOR_PHASE_TRANSITION, ACTOR_DEFEATED, ACTOR_CANCELLED]
	):
		return
	var result := health_model.apply_hit(damage_info.amount, damage_info.stagger)
	if not bool(result.get("accepted", false)):
		return
	current_health = health_model.health
	_flash(damage_info.critical)
	if bool(result.get("phase_changed", false)):
		_phase_transition_pending = true
		phase_changed.emit(health_model.phase, get_runtime_snapshot())
	if bool(result.get("defeated", false)):
		_handle_defeat()
		return
	if bool(result.get("staggered", false)):
		_begin_stagger()
	elif _phase_transition_pending and health_model.state != BossBase.STATE_STAGGERED:
		_begin_phase_transition()
	else:
		_publish_snapshot()


func execute_pattern(pattern_id: StringName, spawn_count: int = -1) -> bool:
	var pattern := get_pattern_definition(pattern_id)
	if pattern == null or not _can_begin_authored_schedule():
		return false
	var resolved_spawn_count := spawn_count
	if resolved_spawn_count < 0:
		resolved_spawn_count = (
			maxi(2 - pattern_runtime.get_active_add_count(), 0)
			if pattern.active_semantics == BossPatternDefinition.ACTIVE_SUMMON_ACTIVATION
			else 0
		)
	return execute_schedule(BossPatternSchedule.new(
		[pattern],
		0.0,
		0.0,
		PackedInt32Array([resolved_spawn_count])
	))


func execute_schedule(schedule: BossPatternSchedule) -> bool:
	if not _can_begin_authored_schedule() or schedule == null:
		return false
	return pattern_runtime.begin_schedule(schedule)


func set_scheduler_enabled(enabled: bool) -> void:
	_scheduler_enabled = enabled
	if not enabled and pattern_runtime != null:
		pattern_runtime.cancel_execution(false)
		pattern_runtime.prepare_for_schedule()
	elif enabled:
		_schedule_next_if_ready()
	_publish_snapshot()


func set_external_clock(enabled: bool) -> void:
	_external_clock = enabled


func set_target_actor(target: Node2D) -> void:
	_target_override = target


func get_target_actor() -> Node2D:
	if _target_override != null and is_instance_valid(_target_override):
		return _target_override
	return get_tree().get_first_node_in_group("player") as Node2D if is_inside_tree() else null


func cancel_encounter(_reason: StringName = &"cancelled") -> void:
	if _actor_state in [ACTOR_DEFEATED, ACTOR_CANCELLED]:
		return
	_encounter_active = false
	_actor_state = ACTOR_CANCELLED
	_phase_transition_pending = false
	_phase_transition_remaining = 0.0
	_set_hurtbox_enabled(false)
	pattern_runtime.cancel_execution(true)
	velocity = Vector2.ZERO
	reset_pattern_pose()
	_publish_snapshot()


func is_runtime_ready() -> bool:
	return (
		health_model != null
		and pattern_runtime != null
		and _patterns.size() == 4
		and _configuration_errors.is_empty()
		and health_model.validate_slime_king_contract().is_empty()
		and health_model.stagger_capacity == REVIEWED_STAGGER_CAPACITY
	)


func get_configuration_errors() -> PackedStringArray:
	return _configuration_errors.duplicate()


func get_pattern_definition(pattern_id: StringName) -> BossPatternDefinition:
	return _patterns_by_id.get(pattern_id) as BossPatternDefinition


func get_scheduler_history() -> Array[StringName]:
	return scheduler.get_history() if scheduler != null else []


func get_runtime_snapshot() -> Dictionary:
	var model_snapshot := health_model.snapshot() if health_model != null else {}
	return {
		"id": SlimeKing.BOSS_ID,
		"actor_state": _actor_state,
		"encounter_active": _encounter_active,
		"health": current_health,
		"max_health": SlimeKing.MAX_HEALTH,
		"phase": int(model_snapshot.get("phase", BossPatternDefinition.PHASE_ONE)),
		"phase_two_health": SlimeKing.PHASE_TWO_HEALTH,
		"stagger_capacity": REVIEWED_STAGGER_CAPACITY,
		"stagger_meter": int(model_snapshot.get("stagger_meter", 0)),
		"stagger_duration": SlimeKing.STAGGER_DURATION,
		"stagger_time_remaining": float(model_snapshot.get("stagger_time_remaining", 0.0)),
		"phase_transition_time_remaining": _phase_transition_remaining,
		"scheduler_enabled": _scheduler_enabled,
		"scheduler_seed": _scheduler_seed,
		"scheduler_history": get_scheduler_history(),
		"pattern": pattern_runtime.snapshot() if pattern_runtime != null else {},
		"defeat_emitted": _defeat_emitted,
	}


func get_combat_snapshot() -> Dictionary:
	return {
		"staggered": health_model != null and health_model.state == BossBase.STATE_STAGGERED,
		"mitigation": 0.0,
		"lightweight": false,
		"facing_direction": int(pattern_runtime.snapshot().get("locked_direction", -1)),
		"boss_phase": health_model.phase if health_model != null else 1,
	}


func set_pattern_pose(pose: StringName, progress: float, direction: int) -> void:
	if visual == null or _actor_state == ACTOR_DEFEATED:
		return
	var clamped_progress := clampf(progress, 0.0, 1.0)
	match pose:
		&"jump_slam_startup":
			visual.scale = Vector2(
				1.0 - sin(clamped_progress * PI) * 0.10,
				1.0 + sin(clamped_progress * PI) * 0.16
			)
			body_visual.color = Color(0.62, 0.94, 0.36, 1.0)
		&"jump_slam_active":
			visual.scale = Vector2(1.22, 0.78)
			body_visual.color = Color(0.92, 0.34, 0.24, 1.0)
		&"body_bump_startup":
			visual.rotation = float(direction) * -0.16 * clamped_progress
			visual.scale = Vector2(1.0 + clamped_progress * 0.12, 1.0 - clamped_progress * 0.08)
			body_visual.color = Color(0.92, 0.76, 0.24, 1.0)
		&"body_bump_active":
			visual.rotation = float(direction) * -0.10
			visual.scale = Vector2(1.24, 0.86)
			body_visual.color = Color(0.94, 0.28, 0.22, 1.0)
		&"recovery":
			visual.rotation = 0.0
			visual.scale = Vector2(1.12, 0.88)
			body_visual.color = Color(0.48, 0.62, 0.34, 1.0)


func reset_pattern_pose() -> void:
	if visual == null:
		return
	visual.position = Vector2.ZERO
	visual.rotation = 0.0
	visual.scale = Vector2.ONE
	if _actor_state == ACTOR_STAGGERED:
		body_visual.color = Color(0.34, 0.90, 0.96, 1.0)
		crown_visual.color = Color(0.72, 0.96, 1.0, 1.0)
	elif _actor_state == ACTOR_PHASE_TRANSITION:
		body_visual.color = Color(0.76, 0.36, 0.92, 1.0)
		crown_visual.color = Color.WHITE
	elif _actor_state != ACTOR_DEFEATED:
		body_visual.color = _base_body_color
		crown_visual.color = _base_crown_color


func _load_patterns() -> void:
	_patterns.clear()
	_patterns_by_id.clear()
	_configuration_errors.clear()
	for path in PATTERN_PATHS:
		var pattern := load(path) as BossPatternDefinition
		if pattern == null:
			_configuration_errors.append("Slime King pattern failed to load: %s" % path)
			continue
		_patterns.append(pattern)
		_patterns_by_id[pattern.id] = pattern
		for error in pattern.validate_definition():
			_configuration_errors.append("%s: %s" % [pattern.id, error])


func _schedule_next_if_ready() -> void:
	if (
		not _scheduler_enabled
		or _actor_state != ACTOR_ACTIVE
		or health_model.state != BossBase.STATE_ACTIVE
		or not pattern_runtime.is_idle()
	):
		return
	var add_count := pattern_runtime.get_active_add_count()
	var side_response_open := add_count < 2
	var context := BossPatternContext.new(
		health_model.phase,
		add_count,
		2,
		1.0,
		true,
		false,
		side_response_open,
		side_response_open,
		summon_spawn_candidates.size() >= 2,
		false
	)
	var schedule := scheduler.choose_next(context)
	if schedule != null:
		pattern_runtime.begin_schedule(schedule)


func _can_begin_authored_schedule() -> bool:
	return (
		_encounter_active
		and _actor_state == ACTOR_ACTIVE
		and health_model.state == BossBase.STATE_ACTIVE
	)


func _begin_stagger() -> void:
	pattern_runtime.cancel_execution(false)
	_actor_state = ACTOR_STAGGERED
	reset_pattern_pose()
	stagger_started.emit(SlimeKing.STAGGER_DURATION, get_runtime_snapshot())
	_publish_snapshot()


func _begin_phase_transition() -> void:
	pattern_runtime.cancel_execution(false)
	_phase_transition_pending = false
	_actor_state = ACTOR_PHASE_TRANSITION
	_phase_transition_remaining = PHASE_TRANSITION_DURATION
	_set_hurtbox_enabled(false)
	reset_pattern_pose()
	_publish_snapshot()


func _handle_defeat() -> void:
	if _defeat_emitted:
		return
	_defeat_emitted = true
	_encounter_active = false
	_actor_state = ACTOR_DEFEATED
	_phase_transition_pending = false
	_phase_transition_remaining = 0.0
	pattern_runtime.cancel_execution(true)
	_set_hurtbox_enabled(false)
	body_shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	visual.rotation = 0.0
	visual.scale = Vector2(1.25, 0.28)
	visual.position.y = 4.0
	visual.modulate = Color.WHITE
	body_visual.color = Color(0.30, 0.38, 0.24, 0.78)
	crown_visual.color = Color(0.48, 0.42, 0.28, 0.82)
	var final_snapshot := get_runtime_snapshot()
	defeated.emit(DEFEAT_REWARD_TABLE_ID, final_snapshot)
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.boss_defeated.emit(DEFEAT_REWARD_TABLE_ID)
	snapshot_changed.emit(final_snapshot)


func _set_hurtbox_enabled(enabled: bool) -> void:
	if hurtbox == null:
		return
	hurtbox.collision_layer = 8 if enabled else 0
	hurtbox.collision_mask = 16 if enabled else 0
	hurtbox.set_deferred("monitorable", enabled)
	hurtbox.set_deferred("monitoring", enabled)
	if hurtbox_shape != null:
		hurtbox_shape.set_deferred("disabled", not enabled)


func _on_player_died() -> void:
	cancel_encounter(&"player_defeated")


func _on_runtime_pattern_started(pattern_id: StringName, _snapshot: Dictionary) -> void:
	pattern_started.emit(pattern_id, get_runtime_snapshot())
	_publish_snapshot()


func _on_runtime_state_changed(
	pattern_id: StringName,
	state: StringName,
	_snapshot: Dictionary
) -> void:
	pattern_state_changed.emit(pattern_id, state, get_runtime_snapshot())
	_publish_snapshot()


func _on_runtime_damage_committed(
	_pattern_id: StringName,
	_target: Node,
	_damage_info: DamageInfo
) -> void:
	_publish_snapshot()


func _on_runtime_add_count_changed(_active_count: int) -> void:
	_publish_snapshot()


func _publish_snapshot() -> void:
	if health_model != null and pattern_runtime != null:
		snapshot_changed.emit(get_runtime_snapshot())


func _flash(critical: bool) -> void:
	if visual == null:
		return
	_flash_serial += 1
	var active_serial := _flash_serial
	visual.modulate = Color(1.0, 0.76, 0.30, 1.0) if critical else Color(1.0, 0.58, 0.58, 1.0)
	await get_tree().create_timer(0.12 if critical else 0.07).timeout
	if is_instance_valid(self) and active_serial == _flash_serial:
		visual.modulate = Color.WHITE
