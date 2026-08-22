class_name VehicleEnemyUpgradeDeviceRuntime
extends "res://scripts/vehicle/vehicle_mystery_device_runtime.gd"

## Owns one continuously recurring run-level hostile objective, stable participant
## claims, capture, collision, and event receipts. Movement and upgrades stay with callers.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

const MAX_DEVICES := 6
const ACTIVE_DEVICE_LIMIT := 1
const MAX_RUN_UPGRADE_TIER := 6
const BASE_HEALTH := 360.0
const COLLISION_RADIUS := 58.8
const VISUAL_RADIUS := 100.8
const CAPTURE_RADIUS := 180.0
const INFLUENCE_RADIUS := 720.0
const REQUIRED_ENEMY_COUNT := 3
const CAPTURE_SECONDS := 5.0
const RESPAWN_DELAY_SECONDS := 9.0
const SPAWN_VISIBLE_MARGIN := 220.0
const SPAWN_MIN_PLAYER_DISTANCE := 960.0
const SPAWN_PREFERRED_DISTANCE := 1440.0
const SPAWN_MAX_PREFERRED_DISTANCE := 1920.0
const HEALTH_BONUS_PER_ACTIVATION := 30.0
const DAMAGE_MULTIPLIER_PER_ACTIVATION := 0.12
const SPEED_BONUS_PER_ACTIVATION := 3.0
const ASSIGNMENT_REFRESH_SECONDS := 0.25
const UPGRADE_HIT_FLASH_SECONDS := 0.14

var _layout_seed := -1
var _context_stage_id: StringName = &""
var _context_stage_index := 0
var _publication_enabled := true
var _publication_pending := false
var _respawn_delay := 0.0
var _last_published_index := -1
var _enemies: Array[EnemyState] = []
var _spatial_grid: Variant
var _assignment_refresh_remaining := 0.0
var _enemy_device_claims: Dictionary = {}
var _query_buffer: Array[EnemyState] = []
var _unique_candidates: Array[EnemyState] = []
var _unique_candidate_ids: Dictionary = {}


func reset() -> void:
	devices.clear()
	_layout_seed = -1
	_context_stage_id = &""
	_context_stage_index = 0
	_publication_enabled = true
	_publication_pending = false
	_respawn_delay = 0.0
	_last_published_index = -1
	_enemies = []
	_spatial_grid = null
	_assignment_refresh_remaining = 0.0
	_enemy_device_claims.clear()
	_query_buffer.clear()
	_unique_candidates.clear()
	_unique_candidate_ids.clear()


func set_context(
	enemies: Array[EnemyState],
	stage_index: int,
	spatial_grid: Variant = null
) -> void:
	_enemies = enemies
	_context_stage_index = maxi(0, stage_index)
	_spatial_grid = spatial_grid


func configure(
	device_blueprint: Array,
	layout_seed: int,
	next_stage_id: StringName
) -> void:
	var rebuild_sockets := devices.is_empty() or _layout_seed != layout_seed
	_context_stage_id = next_stage_id
	if not rebuild_sockets:
		return
	reset()
	_layout_seed = layout_seed
	_context_stage_id = next_stage_id
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
			"assigned_enemy_ids":{},
		})
	_publication_pending = not devices.is_empty()


func set_publication_enabled(enabled: bool) -> void:
	if _publication_enabled == enabled:
		return
	_publication_enabled = enabled
	if enabled:
		_publication_pending = not devices.is_empty() and _respawn_delay <= 0.0
		return
	var retired_active := false
	for device in devices:
		if not _device_is_active(device):
			continue
		_retire_device_for_suspension(device)
		retired_active = true
	if retired_active:
		_respawn_delay = RESPAWN_DELAY_SECONDS
	_publication_pending = false
	_enemy_device_claims.clear()
	_assignment_refresh_remaining = 0.0


func refresh_publication(
	visible_world: Rect2,
	player_position: Vector2
) -> void:
	if (
		not _publication_enabled
		or not _publication_pending
		or has_active_device()
	):
		return
	var device_index := _select_respawn_socket_index(visible_world, player_position)
	if device_index < 0:
		return
	var device := devices[device_index]
	device["health"] = BASE_HEALTH
	device["max_health"] = BASE_HEALTH
	device["state"] = &"dormant"
	device["published"] = true
	device["hit_flash_remaining"] = 0.0
	device["capture_elapsed"] = 0.0
	device["capture_count"] = 0
	Dictionary(device["assigned_enemy_ids"]).clear()
	_last_published_index = device_index
	_publication_pending = false
	_respawn_delay = 0.0
	_assignment_refresh_remaining = 0.0


func advance(delta: float, events: Array[Dictionary]) -> void:
	events.clear()
	var step := maxf(0.0, delta)
	for device in devices:
		device["hit_flash_remaining"] = maxf(
			0.0,
			float(device.get("hit_flash_remaining", 0.0)) - step
		)
	if not _publication_enabled:
		_enemy_device_claims.clear()
		return
	if not has_active_device():
		_enemy_device_claims.clear()
		_respawn_delay = maxf(0.0, _respawn_delay - step)
		if _respawn_delay <= 0.0 and not devices.is_empty():
			_publication_pending = true
		return
	_assignment_refresh_remaining -= step
	if _assignment_refresh_remaining <= 0.0:
		_assignment_refresh_remaining = ASSIGNMENT_REFRESH_SECONDS
		_refresh_assignments()
	for device_index in devices.size():
		var device := devices[device_index]
		if not _device_is_active(device):
			continue
		var assigned := Dictionary(device["assigned_enemy_ids"])
		var nearby_count := 0
		for enemy_id_variant in assigned.keys():
			var enemy := _enemy_by_id(String(enemy_id_variant))
			if (
				enemy != null
				and enemy.pos.distance_to(Vector2(device["position"])) <= CAPTURE_RADIUS
			):
				nearby_count += 1
		device["capture_count"] = nearby_count
		if assigned.size() >= REQUIRED_ENEMY_COUNT and nearby_count >= REQUIRED_ENEMY_COUNT:
			device["capture_elapsed"] = float(device["capture_elapsed"]) + step
		else:
			device["capture_elapsed"] = 0.0
		if float(device["capture_elapsed"]) < CAPTURE_SECONDS:
			continue
		var participant_ids: Array[String] = []
		for enemy_id_variant in assigned.keys():
			var participant := _enemy_by_id(String(enemy_id_variant))
			if participant != null:
				participant_ids.append(participant.id)
		participant_ids.sort()
		_resolve_device(device_index, &"activated")
		events.append({
			"kind":&"enemy_upgrade_device_activated",
			"device_id":StringName(device["id"]),
			"position":Vector2(device["position"]),
			"participant_ids":participant_ids,
			"health_bonus":HEALTH_BONUS_PER_ACTIVATION,
			"damage_multiplier":DAMAGE_MULTIPLIER_PER_ACTIVATION,
			"speed_bonus":SPEED_BONUS_PER_ACTIVATION,
		})


func is_enemy_assigned(enemy_id: String) -> bool:
	return _enemy_device_claims.has(enemy_id)


func claimed_device_id(enemy_id: String) -> StringName:
	return StringName(_enemy_device_claims.get(enemy_id, &""))


func claimed_device_position(enemy_id: String) -> Vector2:
	var device_index := _device_index_by_id(claimed_device_id(enemy_id))
	if device_index < 0 or not _device_is_active(devices[device_index]):
		return Vector2.ZERO
	return Vector2(devices[device_index]["position"])


func active_position() -> Vector2:
	for device in devices:
		if _device_is_active(device):
			return Vector2(device["position"])
	return Vector2.ZERO


func has_active_device() -> bool:
	for device in devices:
		if _device_is_active(device):
			return true
	return false


func fill_active_targets(output: Dictionary) -> Dictionary:
	output.clear()
	for device in devices:
		if _device_is_active(device):
			output[StringName(device["id"])] = Vector2(device["position"])
	return output


static func _accepts_upgrade_damage(
	source_team: StringName,
	attack_kind: StringName
) -> bool:
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
	if not _device_is_active(device):
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
	return []


func fill_modifiers_at(
	_position: Vector2,
	output: Array[Dictionary]
) -> Array[Dictionary]:
	output.clear()
	return output


func fill_device_snapshot(output: Array[Dictionary]) -> Array[Dictionary]:
	output.clear()
	for device in devices:
		if _device_is_active(device):
			output.append(_snapshot_record(device))
	return output


func snapshot() -> Dictionary:
	var records: Array[Dictionary] = []
	for device in devices:
		records.append(_snapshot_record(device))
	return {
		"stage_id":_context_stage_id,
		"stage_index":_context_stage_index,
		"publication_enabled":_publication_enabled,
		"publication_pending":_publication_pending,
		"respawn_delay":_respawn_delay,
		"devices":records,
		"claim_count":_enemy_device_claims.size(),
	}


static func _snapshot_record(device: Dictionary) -> Dictionary:
	var capture_elapsed := float(device.get("capture_elapsed", 0.0))
	return {
		"id":StringName(device["id"]),
		"position":Vector2(device["position"]),
		"radius":COLLISION_RADIUS,
		"visual_radius":VISUAL_RADIUS,
		"effect_radius":CAPTURE_RADIUS,
		"influence_radius":INFLUENCE_RADIUS,
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
		"assigned_count":Dictionary(device.get("assigned_enemy_ids", {})).size(),
		"required_enemy_count":REQUIRED_ENEMY_COUNT,
		"hit_flash_remaining":float(device.get("hit_flash_remaining", 0.0)),
		"projectiles_blocked":false,
		"player_primary_projectiles_blocked":true,
	}


func is_position_clear(position: Vector2, actor_radius: float) -> bool:
	for device in devices:
		if (
			_device_is_active(device)
			and position.distance_to(Vector2(device["position"]))
				< COLLISION_RADIUS + maxf(0.0, actor_radius)
		):
			return false
	return true


func first_intact_segment_hit(
	from: Vector2,
	to: Vector2,
	padding: float,
	receipt: Dictionary
) -> bool:
	# VehicleRun asks this blocking query only for player-primary projectiles.
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
	var best_index := -1
	var best_t := INF
	var best_id := ""
	for device_index in devices.size():
		var device := devices[device_index]
		if not _device_is_active(device):
			continue
		var hit_t := AttackContract.segment_circle_first_t(
			from,
			to,
			Vector2(device["position"]),
			COLLISION_RADIUS + maxf(0.0, padding)
		)
		var device_id := String(device["id"])
		if (
			hit_t < best_t
			or (is_equal_approx(hit_t, best_t) and (best_id.is_empty() or device_id < best_id))
		):
			best_index = device_index
			best_t = hit_t
			best_id = device_id
	if best_index < 0 or is_inf(best_t):
		return false
	receipt["device_id"] = StringName(devices[best_index]["id"])
	receipt["device_index"] = best_index
	receipt["position"] = from.lerp(to, best_t)
	receipt["t"] = best_t
	return true


func _refresh_assignments() -> void:
	for enemy_id_variant in _enemy_device_claims.keys():
		var enemy_id := String(enemy_id_variant)
		var device_index := _device_index_by_id(
			StringName(_enemy_device_claims[enemy_id_variant])
		)
		if device_index < 0 or not _device_is_active(devices[device_index]):
			_release_claim(enemy_id)
			continue
		if _enemy_by_id(enemy_id) == null:
			_release_claim(enemy_id)
	_collect_influence_candidates()
	_unique_candidates.sort_custom(func(left: EnemyState, right: EnemyState) -> bool:
		var left_distance := _nearest_active_device_distance_squared(left.pos)
		var right_distance := _nearest_active_device_distance_squared(right.pos)
		if not is_equal_approx(left_distance, right_distance):
			return left_distance < right_distance
		return left.id < right.id
	)
	for enemy in _unique_candidates:
		if _enemy_device_claims.has(enemy.id):
			continue
		var device_index := _best_available_device_index(enemy.pos)
		if device_index < 0:
			continue
		var device := devices[device_index]
		var assigned := Dictionary(device["assigned_enemy_ids"])
		assigned[enemy.id] = true
		_enemy_device_claims[enemy.id] = StringName(device["id"])


func _collect_influence_candidates() -> void:
	_unique_candidates.clear()
	_unique_candidate_ids.clear()
	if _spatial_grid != null and _spatial_grid.has_method("query_radius_into"):
		for device in devices:
			if not _device_is_active(device):
				continue
			_spatial_grid.query_radius_into(
				Vector2(device["position"]),
				INFLUENCE_RADIUS,
				_enemies,
				_query_buffer
			)
			for enemy in _query_buffer:
				_offer_influence_candidate(enemy)
		return
	for enemy in _enemies:
		_offer_influence_candidate(enemy)


func _offer_influence_candidate(enemy: EnemyState) -> void:
	if not _eligible_enemy(enemy) or _unique_candidate_ids.has(enemy.id):
		return
	if _nearest_active_device_distance_squared(enemy.pos) > INFLUENCE_RADIUS * INFLUENCE_RADIUS:
		return
	_unique_candidate_ids[enemy.id] = true
	_unique_candidates.append(enemy)


func _best_available_device_index(position: Vector2) -> int:
	var best_index := -1
	var best_distance := INF
	var best_id := ""
	for device_index in devices.size():
		var device := devices[device_index]
		if not _device_is_active(device):
			continue
		if Dictionary(device["assigned_enemy_ids"]).size() >= REQUIRED_ENEMY_COUNT:
			continue
		var distance := position.distance_squared_to(Vector2(device["position"]))
		if distance > INFLUENCE_RADIUS * INFLUENCE_RADIUS:
			continue
		var device_id := String(device["id"])
		if (
			distance < best_distance
			or (is_equal_approx(distance, best_distance) and (best_id.is_empty() or device_id < best_id))
		):
			best_index = device_index
			best_distance = distance
			best_id = device_id
	return best_index


func _nearest_active_device_distance_squared(position: Vector2) -> float:
	var result := INF
	for device in devices:
		if _device_is_active(device):
			result = minf(
				result,
				position.distance_squared_to(Vector2(device["position"]))
			)
	return result


static func _eligible_enemy(enemy: EnemyState) -> bool:
	if enemy == null or not enemy.alive or not enemy.active or enemy.speed <= 0.0:
		return false
	if enemy.role == &"boss" or enemy.archetype == &"boss_actor" or enemy.summoned:
		return false
	if String(enemy.role).begins_with("ordinary_fixed_"):
		return false
	return enemy.role != &"ordinary_area_01"


func _enemy_by_id(enemy_id: String) -> EnemyState:
	for enemy in _enemies:
		if enemy != null and enemy.id == enemy_id and _eligible_enemy(enemy):
			return enemy
	return null


func _select_respawn_socket_index(
	visible_world: Rect2,
	player_position: Vector2
) -> int:
	var best_index := -1
	var best_bucket := 999
	var best_repeat_penalty := 999
	var best_distance_error := INF
	var best_id := ""
	var expanded_visible := visible_world.grow(SPAWN_VISIBLE_MARGIN)
	var has_visible_world := visible_world.size.x > 0.0 and visible_world.size.y > 0.0
	for device_index in devices.size():
		var device := devices[device_index]
		var position := Vector2(device["position"])
		var distance := player_position.distance_to(position)
		var offscreen := not has_visible_world or not expanded_visible.has_point(position)
		var in_preferred_band := (
			distance >= SPAWN_MIN_PLAYER_DISTANCE
			and distance <= SPAWN_MAX_PREFERRED_DISTANCE
		)
		var bucket := 4
		if offscreen and in_preferred_band:
			bucket = 0
		elif offscreen and distance >= SPAWN_MIN_PLAYER_DISTANCE:
			bucket = 1
		elif in_preferred_band:
			bucket = 2
		elif distance >= SPAWN_MIN_PLAYER_DISTANCE:
			bucket = 3
		var repeat_penalty := 1 if device_index == _last_published_index else 0
		var distance_error := absf(distance - SPAWN_PREFERRED_DISTANCE)
		var device_id := String(device["id"])
		if (
			bucket < best_bucket
			or (bucket == best_bucket and repeat_penalty < best_repeat_penalty)
			or (
				bucket == best_bucket
				and repeat_penalty == best_repeat_penalty
				and distance_error < best_distance_error
			)
			or (
				bucket == best_bucket
				and repeat_penalty == best_repeat_penalty
				and is_equal_approx(distance_error, best_distance_error)
				and (best_id.is_empty() or device_id < best_id)
			)
		):
			best_index = device_index
			best_bucket = bucket
			best_repeat_penalty = repeat_penalty
			best_distance_error = distance_error
			best_id = device_id
	return best_index


func _retire_device_for_suspension(device: Dictionary) -> void:
	device["state"] = &"pending"
	device["published"] = false
	device["capture_elapsed"] = 0.0
	device["capture_count"] = 0
	device["hit_flash_remaining"] = 0.0
	Dictionary(device["assigned_enemy_ids"]).clear()


func _release_claim(enemy_id: String) -> void:
	var device_id := StringName(_enemy_device_claims.get(enemy_id, &""))
	var device_index := _device_index_by_id(device_id)
	if device_index >= 0:
		Dictionary(devices[device_index]["assigned_enemy_ids"]).erase(enemy_id)
	_enemy_device_claims.erase(enemy_id)


func _device_is_active(device: Dictionary) -> bool:
	return (
		StringName(device.get("state", &"resolved")) == &"dormant"
		and bool(device.get("published", false))
	)


func _device_index_by_id(device_id: StringName) -> int:
	for index in devices.size():
		if StringName(devices[index].get("id", &"")) == device_id:
			return index
	return -1


func _resolve_device(device_index: int, outcome: StringName) -> void:
	if device_index < 0 or device_index >= devices.size():
		return
	var device := devices[device_index]
	var assigned := Dictionary(device["assigned_enemy_ids"])
	for enemy_id_variant in assigned.keys():
		_enemy_device_claims.erase(String(enemy_id_variant))
	assigned.clear()
	device["state"] = outcome
	device["published"] = false
	device["capture_elapsed"] = 0.0
	device["capture_count"] = 0
	_publication_pending = false
	_respawn_delay = RESPAWN_DELAY_SECONDS
