class_name VehicleSecondaryRuntime
extends RefCounted

## Bounded simulation for optional automatic secondary families. Seeker appears
## in the equipment snapshot, while VehicleRun retains its projectile simulation.

const DEFINITION_PATH := "res://data/weapons/vehicle/secondary"
const ION_TICK := 0.25
const ORBIT_HIT_COOLDOWN := 0.55
const MINE_LIFETIME := 8.0
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")

var definitions: Dictionary = {}
var timers: Dictionary = {}
var orbit_angle := 0.0
var orbit_target_cooldowns: Dictionary = {}
var mines: Array[Dictionary] = []
var drone_position := Vector2.ZERO
var _candidate_buffer: Array[EnemyState] = []
var _expired_cooldown_ids: Array[String] = []
var _damage_output: Array[Dictionary] = []
var _effects_output: Array[Dictionary] = []
var _damage_intent_pool: Array[Dictionary] = []
var _damage_intent_count := 0
var _result: Dictionary = {}


func _init() -> void:
	_result = {"damage":_damage_output, "effects":_effects_output}
	for file_name in DirAccess.get_files_at(DEFINITION_PATH):
		var resource_name := _source_resource_name(file_name)
		if resource_name.is_empty():
			continue
		var definition := load(DEFINITION_PATH.path_join(resource_name)) as VehicleSecondaryDefinition
		if definition != null:
			definitions[definition.id] = definition


static func _source_resource_name(file_name: String) -> String:
	# Keep dynamic resource discovery identical in source trees and exported packs.
	if file_name.ends_with(".tres.remap"):
		return file_name.trim_suffix(".remap")
	return file_name if file_name.ends_with(".tres") else ""


func reset(player_position: Vector2) -> void:
	timers.clear()
	orbit_target_cooldowns.clear()
	mines.clear()
	orbit_angle = 0.0
	drone_position = player_position


func update(
	delta: float,
	player_position: Vector2,
	movement_direction: Vector2,
	hull_direction: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable = Callable()
) -> Dictionary:
	# The returned result and damage intents are borrowed scratch storage and
	# remain valid only until the next update call.
	_damage_output.clear()
	_effects_output.clear()
	_damage_intent_count = 0
	orbit_angle = fmod(orbit_angle + delta * 2.45, TAU)
	_expired_cooldown_ids.clear()
	for enemy_id_variant in orbit_target_cooldowns:
		var enemy_id := String(enemy_id_variant)
		var remaining := float(orbit_target_cooldowns[enemy_id]) - delta
		if remaining <= 0.0:
			_expired_cooldown_ids.append(enemy_id)
		else:
			orbit_target_cooldowns[enemy_id] = remaining
	for enemy_id in _expired_cooldown_ids:
		orbit_target_cooldowns.erase(enemy_id)
	_update_ion(delta, player_position, build, enemies, line_of_sight, query_radius, _damage_output)
	_update_orbit(
		player_position,
		build,
		enemies,
		line_of_sight,
		query_radius,
		_damage_output,
		_effects_output
	)
	_update_mines(
		delta,
		player_position,
		mine_placement_direction(movement_direction, hull_direction),
		build,
		enemies,
		line_of_sight,
		query_radius,
		_damage_output,
		_effects_output
	)
	_update_drone(delta, player_position, build, enemies, line_of_sight, query_radius, _damage_output, _effects_output)
	return _result


static func mine_placement_direction(
	movement_direction: Vector2,
	hull_direction: Vector2
) -> Vector2:
	if not movement_direction.is_zero_approx():
		return movement_direction.normalized()
	if not hull_direction.is_zero_approx():
		return hull_direction.normalized()
	return Vector2.RIGHT


func snapshot(build: VehicleRunBuild) -> Dictionary:
	return {
		"equipped":equipped_families(build),
		"orbit_angle":orbit_angle,
		"mines":mines.duplicate(true),
		"drone_position":drone_position,
	}


func equipped_families(build: VehicleRunBuild) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id":&"seeker", "level":1, "name_key":"SECONDARY_SEEKER_NAME"}]
	for secondary_id in [&"ion_field", &"orbit_blades", &"wake_mines", &"escort_drone"]:
		var definition: VehicleSecondaryDefinition = definitions.get(secondary_id)
		if definition == null:
			continue
		var level := build.level_of(definition.upgrade_id)
		if level > 0:
			result.append({"id":secondary_id, "level":level, "name_key":definition.name_key})
	return result


func _update_ion(delta: float, origin: Vector2, build: VehicleRunBuild, enemies: Array[EnemyState], line_of_sight: Callable, query_radius: Callable, output: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"ion_field")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	if not _timer_ready(&"ion_field", delta, ION_TICK):
		return
	var radius := definition.auxiliary(level)
	_query_candidates(origin, radius, enemies, query_radius)
	for enemy in _candidate_buffer:
		var contact_radius := radius + enemy.radius
		if _eligible(enemy) and origin.distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(origin, enemy.pos, 3.0):
			_append_damage_intent(output, enemy, definition.value(level) * ION_TICK, "Ion Field")


func _update_orbit(
	origin: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable,
	output: Array[Dictionary],
	effects: Array[Dictionary]
) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"orbit_blades")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	var count := definition.cap(level)
	for blade_index in count:
		var blade_position := origin + Vector2.RIGHT.rotated(orbit_angle + TAU * float(blade_index) / float(count)) * 78.0
		_query_candidates(blade_position, 22.0, enemies, query_radius)
		for enemy in _candidate_buffer:
			var enemy_id := enemy.id
			if not _eligible(enemy) or float(orbit_target_cooldowns.get(enemy_id, 0.0)) > 0.0:
				continue
			var contact_radius := 22.0 + enemy.radius
			if blade_position.distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(blade_position, enemy.pos, 2.0):
				orbit_target_cooldowns[enemy_id] = ORBIT_HIT_COOLDOWN
				_append_damage_intent(output, enemy, definition.value(level), "Orbit Blades")
				effects.append({
					"event_id": &"secondary_orbit_blade_impact",
					"pos": enemy.pos,
					"target": enemy.pos + (enemy.pos - blade_position).normalized(),
					"radius": 30.0,
				})


func _update_mines(delta: float, origin: Vector2, direction: Vector2, build: VehicleRunBuild, enemies: Array[EnemyState], line_of_sight: Callable, query_radius: Callable, output: Array[Dictionary], effects: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"wake_mines")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		mines.clear()
		return
	if _timer_ready(&"wake_mines", delta, definition.auxiliary(level)):
		mines.append({"pos":origin - direction.normalized() * 48.0, "life":MINE_LIFETIME})
		while mines.size() > definition.cap(level):
			mines.pop_front()
	for index in range(mines.size() - 1, -1, -1):
		var mine: Dictionary = mines[index]
		mine["life"] = float(mine["life"]) - delta
		var detonate := float(mine["life"]) <= 0.0
		if not detonate:
			_query_candidates(Vector2(mine["pos"]), 54.0, enemies, query_radius)
			for enemy in _candidate_buffer:
				var contact_radius := 54.0 + enemy.radius
				if _eligible(enemy) and Vector2(mine["pos"]).distance_squared_to(enemy.pos) <= contact_radius * contact_radius:
					detonate = true
					break
		if not detonate:
			continue
		var radius := 84.0 + float(level) * 12.0
		_query_candidates(Vector2(mine["pos"]), radius, enemies, query_radius)
		for enemy in _candidate_buffer:
			var contact_radius := radius + enemy.radius
			if _eligible(enemy) and Vector2(mine["pos"]).distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(Vector2(mine["pos"]), enemy.pos, 3.0):
				_append_damage_intent(output, enemy, definition.value(level), "Wake Mine")
		effects.append({
			"event_id": &"secondary_wake_mine_detonation",
			"pos": Vector2(mine["pos"]),
			"radius": radius,
		})
		mines.remove_at(index)


func _update_drone(delta: float, origin: Vector2, build: VehicleRunBuild, enemies: Array[EnemyState], line_of_sight: Callable, query_radius: Callable, output: Array[Dictionary], effects: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"escort_drone")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		drone_position = origin
		return
	var desired := origin + Vector2.RIGHT.rotated(orbit_angle * 0.42) * 92.0
	drone_position = drone_position.lerp(desired, clampf(delta * 8.0, 0.0, 1.0))
	if not _timer_ready(&"escort_drone", delta, definition.auxiliary(level)):
		return
	var best: EnemyState
	var best_distance := 480.0
	_query_candidates(drone_position, best_distance, enemies, query_radius)
	for enemy in _candidate_buffer:
		if not _eligible(enemy):
			continue
		var distance := drone_position.distance_to(enemy.pos)
		if distance < best_distance and line_of_sight.call(drone_position, enemy.pos, 3.0):
			best = enemy
			best_distance = distance
	if best != null:
		_append_damage_intent(output, best, definition.value(level), "Escort Drone")
		effects.append({
			"event_id": &"secondary_escort_impact",
			"pos": best.pos,
			"target": best.pos + (best.pos - drone_position).normalized(),
			"radius": 34.0,
		})


func _timer_ready(timer_id: StringName, delta: float, interval: float) -> bool:
	var remaining := maxf(0.0, float(timers.get(timer_id, 0.0)) - delta)
	timers[timer_id] = remaining
	if remaining > 0.0:
		return false
	timers[timer_id] = interval
	return true


func _eligible(enemy: EnemyState) -> bool:
	return enemy.alive and enemy.active


func _append_damage_intent(
	output: Array[Dictionary],
	enemy: EnemyState,
	damage: float,
	source: String
) -> void:
	if _damage_intent_count >= _damage_intent_pool.size():
		_damage_intent_pool.append({})
	var intent := _damage_intent_pool[_damage_intent_count]
	_damage_intent_count += 1
	intent["enemy"] = enemy
	intent["enemy_id"] = enemy.id
	intent["damage"] = damage
	intent["source"] = source
	output.append(intent)


func _query_candidates(center: Vector2, radius: float, enemies: Array[EnemyState], query_radius: Callable) -> void:
	_candidate_buffer.clear()
	if query_radius.is_valid():
		query_radius.call(center, radius, _candidate_buffer)
		return
	for enemy in enemies:
		if _eligible(enemy):
			_candidate_buffer.append(enemy)
