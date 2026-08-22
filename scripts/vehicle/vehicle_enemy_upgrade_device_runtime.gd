class_name VehicleEnemyUpgradeDeviceRuntime
extends "res://scripts/vehicle/vehicle_mystery_device_runtime.gd"

## Publishes one run-level enemy upgrade device at a time.
## The three nearest eligible mobile enemies are assigned to the active device.
## Five uninterrupted seconds with all three inside the capture radius activates it.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

const MAX_DEVICES := 6
const BASE_HEALTH := 360.0
const COLLISION_RADIUS := 58.8
const VISUAL_RADIUS := 100.8
const CAPTURE_RADIUS := 180.0
const REQUIRED_ENEMY_COUNT := 3
const CAPTURE_SECONDS := 5.0
const RESPAWN_DELAY_SECONDS := 9.0
const HEALTH_SCALE_PER_STAGE := 0.12
const HEALTH_BONUS_PER_ACTIVATION := 30.0
const DAMAGE_MULTIPLIER_PER_ACTIVATION := 0.12
const SPEED_BONUS_PER_ACTIVATION := 3.0
const ASSIGNMENT_REFRESH_SECONDS := 0.25
const UPGRADE_HIT_FLASH_SECONDS := 0.14

var _layout_seed := -1
var _stage_index := 0
var _enemies: Array[EnemyState] = []
var _respawn_delay := 0.0
var _assignment_refresh_remaining := 0.0
var _assigned_enemy_ids: Dictionary = {}


func reset() -> void:
	devices.clear()
	_layout_seed = -1
	_stage_index = 0
	_enemies = []
	_respawn_delay = 0.0
	_assignment_refresh_remaining = 0.0
	_assigned_enemy_ids.clear()


func set_context(enemies: Array[EnemyState], stage_index: int) -> void:
	_enemies = enemies
	_stage_index = maxi(0, stage_index)


func configure(device_blueprint: Array, layout_seed: int, _stage_id: StringName) -> void:
	# Stage transitions reuse the same six run-level sockets. A new run calls
	# reset() before configure(), while repeated stage configuration is ignored.
	if not devices.is_empty() and _layout_seed == layout_seed:
		return
	reset()
	_layout_seed = layout_seed
	for index in mini(MAX_DEVICES, device_blueprint.size()):
		var blueprint := Dictionary(device_blueprint[index])
		devices.append({
			"id":StringName(blueprint.get("id", "enemy_upgrade_device_%d" % index)),
			"position":Vector2(blueprint.get("pos", blueprint.get("position", Vector2.ZERO))),
			"health":BASE_HEALTH,
			"max_health":BASE_HEALTH,
			"state":&"pending",
			"published":false,
			"hit_flash_remaining":0.0,
			"capture_elapsed":0.0,
			"capture_count":0,
		})


func refresh_publication(
	_visible_world: Rect2,
	player_position: Vector2
) -> void:
	if _active_device_index() >= 0 or _respawn_delay > 0.0:
		return
	var selected_index := -1
	var selected_distance := -1.0
	for index in devices.size():
		var device := devices[index]
		if StringName(device.get("state", &"resolved")) != &"pending":
			continue
		var distance := player_position.distance_squared_to(Vector2(device["position"]))
		if distance > selected_distance:
			selected_index = index
			selected_distance = distance
	if selected_index < 0:
		return
	var selected := devices[selected_index]
	var maximum_health := BASE_HEALTH * (
		1.0 + float(_stage_index) * HEALTH_SCALE_PER_STAGE
	)
	selected["health"] = maximum_health
	selected["max_health"] = maximum_health
	selected["state"] = &"dormant"
	selected["published"] = true
	selected["hit_flash_remaining"] = 0.0
	selected["capture_elapsed"] = 0.0
	selected["capture_count"] = 0
	_assigned_enemy_ids.clear()
	_assignment_refresh_remaining = 0.0


func advance(
	delta: float,
	events: Array[Dictionary]
) -> void:
	events.clear()
	var step := maxf(0.0, delta)
	for device in devices:
		device["hit_flash_remaining"] = maxf(
			0.0,
			float(device.get("hit_flash_remaining", 0.0)) - step
		)
	var active_index := _active_device_index()
	if active_index < 0:
		_respawn_delay = maxf(0.0, _respawn_delay - step)
		_assigned_enemy_ids.clear()
		return
	var device := devices[active_index]
	_assignment_refresh_remaining -= step
	if _assignment_refresh_remaining <= 0.0:
		_assignment_refresh_remaining = ASSIGNMENT_REFRESH_SECONDS
		_refresh_assignments(_enemies, Vector2(device["position"]))
	var nearby_count := 0
	for enemy_id in _assigned_enemy_ids.keys():
		var enemy := _enemy_by_id(_enemies, String(enemy_id))
		if enemy == null:
			continue
		if enemy.pos.distance_to(Vector2(device["position"])) <= CAPTURE_RADIUS:
			nearby_count += 1
	device["capture_count"] = nearby_count
	if _assigned_enemy_ids.size() >= REQUIRED_ENEMY_COUNT and nearby_count >= REQUIRED_ENEMY_COUNT:
		device["capture_elapsed"] = float(device["capture_elapsed"]) + step
	else:
		device["capture_elapsed"] = 0.0
	if float(device["capture_elapsed"]) < CAPTURE_SECONDS:
		return
	_resolve_device(active_index, &"activated")
	events.append({
		"kind":&"enemy_upgrade_device_activated",
		"device_id":StringName(device["id"]),
		"position":Vector2(device["position"]),
		"health_bonus":HEALTH_BONUS_PER_ACTIVATION,
		"damage_multiplier":DAMAGE_MULTIPLIER_PER_ACTIVATION,
		"speed_bonus":SPEED_BONUS_PER_ACTIVATION,
	})


func is_enemy_assigned(enemy_id: String) -> bool:
	return _active_device_index() >= 0 and _assigned_enemy_ids.has(enemy_id)


func active_position() -> Vector2:
	var active_index := _active_device_index()
	return Vector2(devices[active_index]["position"]) if active_index >= 0 else Vector2.ZERO


func has_active_device() -> bool:
	return _active_device_index() >= 0


static func _accepts_upgrade_damage(source_team: StringName, attack_kind: StringName) -> bool:
	return source_team == &"player" and attack_kind in [&"direct", &"area", &"projectile"]


func receive_damage(
	device_id: StringName,
	amount: float,
	source_team: StringName,
	attack_kind: StringName
) -> Dictionary:
	var device_index := _device_index_by_id(device_id)
	var remaining_health := (
		float(devices[device_index].get("health", 0.0))
		if device_index >= 0 else 0.0
	)
	var receipt := {
		"accepted":false,
		"broken":false,
		"device_id":device_id,
		"remaining_health":remaining_health,
		"break_event":{},
	}
	if device_index < 0 or amount <= 0.0 or not _accepts_upgrade_damage(source_team, attack_kind):
		return receipt
	var device := devices[device_index]
	if StringName(device.get("state", &"resolved")) != &"dormant" or not bool(device.get("published", false)):
		return receipt
	device["health"] = maxf(0.0, float(device["health"]) - amount)
	device["hit_flash_remaining"] = UPGRADE_HIT_FLASH_SECONDS
	receipt["accepted"] = true
	receipt["remaining_health"] = float(device["health"])
	if float(device["health"]) <= 0.0:
		_resolve_device(device_index, &"destroyed")
		receipt["broken"] = true
		receipt["break_event"] = {
			"kind":&"enemy_upgrade_device_destroyed",
			"device_id":device_id,
			"position":Vector2(device["position"]),
			"source":&"enemy_upgrade_device",
			"grants_experience":false,
			"drop":&"",
			"projectiles_blocked":false,
			"player_primary_projectiles_blocked":true,
		}
	return receipt


func modifiers_at(_position: Vector2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	return result


func fill_modifiers_at(_position: Vector2, output: Array[Dictionary]) -> Array[Dictionary]:
	output.clear()
	return output


func fill_device_snapshot(output: Array[Dictionary]) -> Array[Dictionary]:
	output.clear()
	var active_index := _active_device_index()
	if active_index < 0:
		return output
	output.append(_snapshot_record(devices[active_index]))
	return output


func snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for device in devices:
		records.append(_snapshot_record(device))
	return {"devices":records}


static func _snapshot_record(device: Dictionary) -> Dictionary:
	var capture_elapsed := float(device.get("capture_elapsed", 0.0))
	return {
		"id":StringName(device["id"]),
		"position":Vector2(device["position"]),
		"radius":COLLISION_RADIUS,
		"visual_radius":VISUAL_RADIUS,
		"effect_radius":CAPTURE_RADIUS,
		"health":float(device["health"]),
		"max_health":float(device["max_health"]),
		"outcome":&"weakpoint",
		"state":StringName(device.get("state", &"resolved")),
		"published":bool(device.get("published", false)),
		"active_remaining":0.0,
		"active_duration":0.0,
		"active_ratio":0.0,
		"capture_elapsed":capture_elapsed,
		"capture_ratio":clampf(capture_elapsed / CAPTURE_SECONDS, 0.0, 1.0),
		"capture_count":int(device.get("capture_count", 0)),
		"required_enemy_count":REQUIRED_ENEMY_COUNT,
		"hit_flash_remaining":float(device.get("hit_flash_remaining", 0.0)),
		"projectiles_blocked":false,
		"player_primary_projectiles_blocked":true,
	}


func is_position_clear(position: Vector2, actor_radius: float) -> bool:
	var active_index := _active_device_index()
	if active_index < 0:
		return true
	return (
		position.distance_to(Vector2(devices[active_index]["position"]))
		>= COLLISION_RADIUS + maxf(0.0, actor_radius)
	)


func first_intact_segment_hit(
	from: Vector2,
	to: Vector2,
	padding: float,
	receipt: Dictionary
) -> bool:
	# VehicleRun only asks this structure query for player-primary projectiles.
	# Hostile projectiles remain pass-through so the device cannot become cover.
	return _first_active_segment_hit(from, to, padding, receipt)


func first_damageable_segment_hit(
	from: Vector2,
	to: Vector2,
	padding: float,
	receipt: Dictionary
) -> bool:
	return _first_active_segment_hit(from, to, padding, receipt)


func _first_active_segment_hit(
	from: Vector2,
	to: Vector2,
	padding: float,
	receipt: Dictionary
) -> bool:
	receipt.clear()
	var active_index := _active_device_index()
	if active_index < 0:
		return false
	var device := devices[active_index]
	var position := Vector2(device["position"])
	var hit_t := AttackContract.segment_circle_first_t(
		from,
		to,
		position,
		COLLISION_RADIUS + maxf(0.0, padding)
	)
	if is_inf(hit_t):
		return false
	receipt["device_id"] = StringName(device["id"])
	receipt["device_index"] = active_index
	receipt["position"] = from.lerp(to, hit_t)
	receipt["t"] = hit_t
	return true


func _refresh_assignments(enemies: Array[EnemyState], device_position: Vector2) -> void:
	var candidates: Array[EnemyState] = []
	for enemy in enemies:
		if _eligible_enemy(enemy):
			candidates.append(enemy)
	candidates.sort_custom(func(left: EnemyState, right: EnemyState) -> bool:
		var left_distance := left.pos.distance_squared_to(device_position)
		var right_distance := right.pos.distance_squared_to(device_position)
		if not is_equal_approx(left_distance, right_distance):
			return left_distance < right_distance
		return left.id < right.id
	)
	_assigned_enemy_ids.clear()
	for index in mini(REQUIRED_ENEMY_COUNT, candidates.size()):
		_assigned_enemy_ids[candidates[index].id] = true


static func _eligible_enemy(enemy: EnemyState) -> bool:
	if enemy == null or not enemy.alive or not enemy.active or enemy.speed <= 0.0:
		return false
	if enemy.role == &"boss" or enemy.archetype == &"boss_actor":
		return false
	if enemy.summoned or enemy.leash_rect.has_area():
		return false
	return not String(enemy.role).begins_with("ordinary_fixed_")


static func _enemy_by_id(enemies: Array[EnemyState], enemy_id: String) -> EnemyState:
	for enemy in enemies:
		if enemy != null and enemy.id == enemy_id and _eligible_enemy(enemy):
			return enemy
	return null


func _active_device_index() -> int:
	for index in devices.size():
		var device := devices[index]
		if (
			StringName(device.get("state", &"resolved")) == &"dormant"
			and bool(device.get("published", false))
		):
			return index
	return -1


func _device_index_by_id(device_id: StringName) -> int:
	for index in devices.size():
		if StringName(devices[index].get("id", &"")) == device_id:
			return index
	return -1


func _resolve_device(device_index: int, outcome: StringName) -> void:
	if device_index < 0 or device_index >= devices.size():
		return
	var device := devices[device_index]
	device["state"] = outcome
	device["published"] = false
	device["capture_elapsed"] = 0.0
	device["capture_count"] = 0
	_assigned_enemy_ids.clear()
	_assignment_refresh_remaining = 0.0
	_respawn_delay = RESPAWN_DELAY_SECONDS
