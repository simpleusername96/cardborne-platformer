class_name VehicleSecondaryRuntime
extends RefCounted

## Bounded simulation for the canonical secondary-weapon family. The built-in
## seeker and optional weapons share one runtime; VehicleRun remains the sole
## projectile-store owner and consumes the borrowed projectile intents.

const ION_TICK := 0.25
const ORBIT_HIT_COOLDOWN := 0.55
const MINE_LIFETIME := 8.0
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")

var catalog: RefCounted
var timers: Dictionary = {}
var orbit_angle := 0.0
var orbit_target_cooldowns: Dictionary = {}
var mines: Array[Dictionary] = []
var seeker_cooldown := 0.0
var _candidate_buffer: Array[EnemyState] = []
var _expired_cooldown_ids: Array[String] = []
var _damage_output: Array[Dictionary] = []
var _projectile_output: Array[Dictionary] = []
var _detonation_output: Array[Dictionary] = []
var _damage_intent_pool: Array[Dictionary] = []
var _detonation_receipt_pool: Array[Dictionary] = []
var _damage_intent_count := 0
var _detonation_receipt_count := 0
var _result: Dictionary = {}


func _init() -> void:
	catalog = SecondaryCatalog.new()
	_result = {
		"damage":_damage_output,
		"projectiles":_projectile_output,
		"detonations":_detonation_output,
	}
func reset(player_position: Vector2) -> void:
	timers.clear()
	orbit_target_cooldowns.clear()
	mines.clear()
	orbit_angle = 0.0
	seeker_cooldown = 0.0


func _definition(secondary_id: StringName) -> VehicleSecondaryDefinition:
	return catalog.call("get_definition", secondary_id) as VehicleSecondaryDefinition


func update(
	delta: float,
	player_position: Vector2,
	movement_direction: Vector2,
	hull_direction: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable = Callable(),
	find_seeker_targets: Callable = Callable(),
	seeker_blocked: bool = false,
	seeker_cooldown_multiplier: float = 1.0
) -> Dictionary:
	# The returned result and damage intents are borrowed scratch storage and
	# remain valid only until the next update call.
	_damage_output.clear()
	_projectile_output.clear()
	_detonation_output.clear()
	_damage_intent_count = 0
	_detonation_receipt_count = 0
	seeker_cooldown = maxf(0.0, seeker_cooldown - delta)
	_update_seeker(
		delta,
		player_position,
		build,
		find_seeker_targets,
		seeker_blocked,
		_projectile_output,
		seeker_cooldown_multiplier
	)
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
	_update_electric_field(
		delta,
		player_position,
		build,
		enemies,
		line_of_sight,
		query_radius,
		_damage_output
	)
	_update_orbit(
		player_position,
		build,
		enemies,
		line_of_sight,
		query_radius,
		_damage_output
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
		_detonation_output
	)
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
		"seeker_cooldown":seeker_cooldown,
		"electric_field_radius":_electric_field_radius(build),
	}


func fill_presentation_snapshot(
	output: Dictionary,
	build: VehicleRunBuild
) -> Dictionary:
	## Fills synchronous renderer scratch; mine state remains runtime-owned.
	output.clear()
	output["orbit_angle"] = orbit_angle
	output["mines"] = mines
	output["electric_field_radius"] = _electric_field_radius(build)
	return output


func _electric_field_radius(build: VehicleRunBuild) -> float:
	var definition := _definition(&"electric_field")
	if definition == null:
		return 0.0
	var level := build.level_of(definition.upgrade_id)
	return definition.auxiliary(level) if level > 0 else 0.0


func equipped_families(build: VehicleRunBuild) -> Array[Dictionary]:
	var seeker := _definition(&"seeker")
	var result: Array[Dictionary] = [{
		"id":&"seeker",
		"level":1,
		"name_key":seeker.name_key if seeker != null else "SECONDARY_HOMING_MISSILES_NAME",
		"slot_kind":&"built_in",
	}]
	for secondary_id in [&"electric_field", &"orbiting_blades", &"drop_mines"]:
		var definition := _definition(secondary_id)
		if definition == null:
			continue
		var level := build.level_of(definition.upgrade_id)
		if level > 0:
			result.append({"id":secondary_id, "level":level, "name_key":definition.name_key, "slot_kind":&"optional"})
	return result


func _update_seeker(
	delta: float,
	origin: Vector2,
	build: VehicleRunBuild,
	find_targets: Callable,
	blocked: bool,
	output: Array[Dictionary],
	cooldown_multiplier: float
) -> void:
	if blocked or seeker_cooldown > 0.0 or not find_targets.is_valid():
		return
	var definition := _definition(&"seeker")
	if definition == null:
		return
	var missile_level := clampi(build.level_of(&"homing_missiles"), 0, 2)
	var definition_level := missile_level + 1
	var seeker_count := definition.cap(definition_level)
	var targets_variant: Variant = find_targets.call(seeker_count)
	if not targets_variant is Array or targets_variant.is_empty():
		return
	seeker_cooldown = definition.auxiliary(definition_level) * cooldown_multiplier
	var seeker_damage := definition.value(definition_level)
	for target_variant in targets_variant:
		var target := target_variant as EnemyState
		if target == null:
			continue
		var direction := (target.pos - origin).normalized()
		output.append({
			"pos": origin + direction * 33.0,
			"velocity": direction * 490.0,
			"radius": 8.0,
			"damage": seeker_damage,
			"life": 1.8,
			"color": Color("8ae9dc"),
			"owner": "seeker",
			"pierce": 0,
			"bounces": 0,
			"homing": true,
			"target_id": target.id,
			"explosive": false,
			"structure_damage": 25.0,
			"element_profile": null,
			"wall_piercing": false,
		})


func _update_electric_field(delta: float, origin: Vector2, build: VehicleRunBuild, enemies: Array[EnemyState], line_of_sight: Callable, query_radius: Callable, output: Array[Dictionary]) -> void:
	var definition := _definition(&"electric_field")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	if not _timer_ready(&"electric_field", delta, ION_TICK):
		return
	var radius := definition.auxiliary(level)
	_query_candidates(origin, radius, enemies, query_radius)
	for enemy in _candidate_buffer:
		var contact_radius := radius + enemy.radius
		if _eligible(enemy) and origin.distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(origin, enemy.pos, 3.0):
			_append_damage_intent(output, enemy, definition.value(level) * ION_TICK, "Electric Field")


func _update_orbit(
	origin: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable,
	output: Array[Dictionary]
) -> void:
	var definition := _definition(&"orbiting_blades")
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
				_append_damage_intent(output, enemy, definition.value(level), "Orbiting Blades")


func _update_mines(
	delta: float,
	origin: Vector2,
	direction: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable,
	damage_output: Array[Dictionary],
	detonation_output: Array[Dictionary]
) -> void:
	var definition := _definition(&"drop_mines")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		mines.clear()
		return
	if _timer_ready(&"drop_mines", delta, definition.auxiliary(level)):
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
				_append_damage_intent(
					damage_output, enemy, definition.value(level), "Drop Mine"
				)
		_append_detonation_receipt(
			detonation_output, Vector2(mine["pos"]), radius, level
		)
		mines.remove_at(index)


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


func _append_detonation_receipt(
	output: Array[Dictionary],
	position: Vector2,
	radius: float,
	level: int
) -> void:
	if _detonation_receipt_count >= _detonation_receipt_pool.size():
		_detonation_receipt_pool.append({})
	var receipt := _detonation_receipt_pool[_detonation_receipt_count]
	_detonation_receipt_count += 1
	receipt["position"] = position
	receipt["radius"] = radius
	receipt["level"] = level
	output.append(receipt)


func _query_candidates(center: Vector2, radius: float, enemies: Array[EnemyState], query_radius: Callable) -> void:
	_candidate_buffer.clear()
	if query_radius.is_valid():
		query_radius.call(center, radius, _candidate_buffer)
		return
	for enemy in enemies:
		if _eligible(enemy):
			_candidate_buffer.append(enemy)
