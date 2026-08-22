class_name VehicleRunEnemyUpgradeDevices
extends "res://scripts/vehicle/vehicle_run.gd"

## Default run layer for the enemy upgrade-device map-movement system. The base run and
## retired neutral-facility implementation remain intact for compatibility and history.

const EnemyUpgradeRuntime = preload(
	"res://scripts/vehicle/vehicle_enemy_upgrade_device_runtime.gd"
)
const EnemyUpgradeRenderer = preload(
	"res://scripts/presentation/vehicle_enemy_upgrade_combat_renderer.gd"
)
const UpgradeStatusRuntime = preload("res://scripts/combat/vehicle_status_runtime.gd")
const UpgradeArt = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const OBJECTIVE_STOP_RATIO := 0.64

var enemy_upgrade_health_bonus := 0.0
var enemy_upgrade_damage_multiplier := 0.0
var enemy_upgrade_speed_bonus := 0.0
var enemy_upgrade_activations := 0

var _enemy_upgrade_runtime
var _enemy_damage_multiplier_by_id: Dictionary = {}
var _enemy_applied_multiplier_by_id: Dictionary = {}


func _ready() -> void:
	_enemy_upgrade_runtime = EnemyUpgradeRuntime.new()
	mystery_device_runtime = _enemy_upgrade_runtime
	super._ready()


func _build_combat_renderer() -> void:
	_combat_renderer = EnemyUpgradeRenderer.new()
	_combat_renderer.name = "VehicleCombatRenderer"
	add_child(_combat_renderer)


func _reset_run(
	increment_index: bool = true,
	preserve_stage: bool = false,
	preserve_upgrades: bool = false,
	_preserve_field_state: bool = false
) -> void:
	_enemy_damage_multiplier_by_id.clear()
	_enemy_applied_multiplier_by_id.clear()
	if not preserve_upgrades:
		enemy_upgrade_health_bonus = 0.0
		enemy_upgrade_damage_multiplier = 0.0
		enemy_upgrade_speed_bonus = 0.0
		enemy_upgrade_activations = 0
		if _enemy_upgrade_runtime != null:
			_enemy_upgrade_runtime.reset()
	super._reset_run(
		increment_index,
		preserve_stage,
		preserve_upgrades,
		_preserve_field_state
	)


func _physics_process(delta: float) -> void:
	if _enemy_upgrade_runtime != null:
		_enemy_upgrade_runtime.set_context(enemies, current_stage_index)
	super._physics_process(delta)


func _make_enemy(spec: Dictionary) -> EnemyState:
	var enemy: EnemyState = super._make_enemy(spec)
	if (
		enemy == null
		or enemy.archetype == &"boss_actor"
		or enemy.role == &"boss"
		or enemy.summoned
	):
		return enemy
	enemy.health += enemy_upgrade_health_bonus
	enemy.max_health += enemy_upgrade_health_bonus
	if enemy.speed > 0.0:
		enemy.speed += enemy_upgrade_speed_bonus
	_enemy_damage_multiplier_by_id[enemy.id] = enemy_upgrade_damage_multiplier
	_enemy_applied_multiplier_by_id[enemy.id] = 1.0
	return enemy


func _update_ordinary_enemy(
	enemy: EnemyState,
	delta: float,
	can_commit: bool,
	decision_due: bool = true,
	motion_delta: float = -1.0
) -> bool:
	_apply_upgrade_damage_multiplier(enemy)
	if _enemy_upgrade_runtime != null and _enemy_upgrade_runtime.is_enemy_assigned(enemy.id):
		var movement_delta := delta if motion_delta < 0.0 else motion_delta
		_prepare_enemy_for_upgrade_objective(enemy)
		_move_enemy_role(enemy, movement_delta, false, true)
		return false
	return super._update_ordinary_enemy(
		enemy, delta, can_commit, decision_due, motion_delta
	)


func _update_motion_only_ordinary_enemy(
	enemy: EnemyState,
	motion_delta: float
) -> void:
	_apply_upgrade_damage_multiplier(enemy)
	if _enemy_upgrade_runtime != null and _enemy_upgrade_runtime.is_enemy_assigned(enemy.id):
		var previous_position := enemy.pos
		var previous_active := enemy.active
		_prepare_enemy_for_upgrade_objective(enemy)
		_move_enemy_role(enemy, motion_delta, false, true)
		_record_motion_only_enemy_change(
			enemy, previous_position, previous_active
		)
		return
	super._update_motion_only_ordinary_enemy(enemy, motion_delta)


func _desired_enemy_velocity(enemy: EnemyState, recovering: bool) -> Vector2:
	if (
		_enemy_upgrade_runtime != null
		and _enemy_upgrade_runtime.is_enemy_assigned(enemy.id)
		and not recovering
	):
		var offset: Vector2 = _enemy_upgrade_runtime.active_position() - enemy.pos
		if offset.length() <= EnemyUpgradeRuntime.CAPTURE_RADIUS * OBJECTIVE_STOP_RATIO:
			return Vector2.ZERO
		return (
			offset.normalized()
			* _effective_enemy_speed(enemy)
			* UpgradeStatusRuntime.speed_multiplier(enemy)
		)
	return super._desired_enemy_velocity(enemy, recovering)


func _apply_engagement_gap_steering(
	enemy: EnemyState,
	delta: float,
	update_spatial_grid: bool
) -> void:
	if _enemy_upgrade_runtime != null and _enemy_upgrade_runtime.is_enemy_assigned(enemy.id):
		return
	super._apply_engagement_gap_steering(enemy, delta, update_spatial_grid)


func _refresh_enemy_presentation_facing(enemy: EnemyState) -> void:
	if _enemy_upgrade_runtime != null and _enemy_upgrade_runtime.is_enemy_assigned(enemy.id):
		var facing: Vector2 = _enemy_upgrade_runtime.active_position() - enemy.pos
		if not facing.is_zero_approx():
			enemy.presentation_facing = facing.normalized()
		return
	super._refresh_enemy_presentation_facing(enemy)


func _prepare_enemy_for_upgrade_objective(enemy: EnemyState) -> void:
	enemy.movement_reason = &"enemy_upgrade_device"
	enemy.phase = &"move"
	enemy.phase_time = 0.0
	enemy.attack_cooldown = maxf(enemy.attack_cooldown, 0.35)
	enemy.mechanic_state = &""
	enemy.mechanic_cue_active = false
	enemy.attack_telegraphs.clear()


func _apply_upgrade_damage_multiplier(enemy: EnemyState) -> void:
	var bonus := float(_enemy_damage_multiplier_by_id.get(enemy.id, 0.0))
	var target_multiplier := 1.0 + maxf(0.0, bonus)
	var previous_multiplier := float(
		_enemy_applied_multiplier_by_id.get(enemy.id, 1.0)
	)
	var pack_multiplier := maxf(0.0, enemy.pack_damage_multiplier)
	if previous_multiplier > 1.0 and pack_multiplier >= previous_multiplier - 0.001:
		pack_multiplier /= previous_multiplier
	enemy.pack_damage_multiplier = pack_multiplier * target_multiplier
	_enemy_applied_multiplier_by_id[enemy.id] = target_multiplier


func _handle_mystery_device_break(event: Dictionary) -> Dictionary:
	var device_id := StringName(event.get("device_id", &""))
	_ui.notify(
		tr("NOTIFY_ENEMY_UPGRADE_DEVICE_DESTROYED"),
		1.8,
		UpgradeArt.SYSTEM,
		1,
		&"enemy_upgrade_device_destroyed"
	)
	_play_sound(&"destroy_priority", 1.02)
	_mystery_device_result_receipt.clear()
	_mystery_device_result_receipt["device_id"] = device_id
	_session_diagnostics.emit_event("enemy_upgrade_device_destroyed", {
		"device_id":device_id,
		"stage_index":current_stage_index,
	})
	return _mystery_device_result_receipt


func _handle_mystery_device_event(event: Dictionary) -> void:
	if StringName(event.get("kind", &"")) != &"enemy_upgrade_device_activated":
		return
	enemy_upgrade_health_bonus += float(event.get(
		"health_bonus", EnemyUpgradeRuntime.HEALTH_BONUS_PER_ACTIVATION
	))
	enemy_upgrade_damage_multiplier += float(event.get(
		"damage_multiplier", EnemyUpgradeRuntime.DAMAGE_MULTIPLIER_PER_ACTIVATION
	))
	enemy_upgrade_speed_bonus += float(event.get(
		"speed_bonus", EnemyUpgradeRuntime.SPEED_BONUS_PER_ACTIVATION
	))
	enemy_upgrade_activations += 1
	_ui.notify(
		tr("NOTIFY_ENEMY_UPGRADE_DEVICE_ACTIVATED"),
		2.4,
		UpgradeArt.DANGER,
		2,
		&"enemy_upgrade_device_activated"
	)
	_play_sound(&"destroy_priority", 0.82)
	_session_diagnostics.emit_event("enemy_upgrade_device_activated", {
		"device_id":StringName(event.get("device_id", &"")),
		"stage_index":current_stage_index,
		"activation_count":enemy_upgrade_activations,
		"health_bonus_total":enemy_upgrade_health_bonus,
		"damage_multiplier_total":enemy_upgrade_damage_multiplier,
		"speed_bonus_total":enemy_upgrade_speed_bonus,
	})
