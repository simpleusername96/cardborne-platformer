class_name VehicleSecondaryRuntime
extends RefCounted

## Bounded simulation for the canonical secondary-weapon family. The built-in
## seeker and optional weapons share one runtime; VehicleRun remains the sole
## projectile-store owner and consumes the borrowed projectile intents.

const ION_TICK := 0.25
const ORBIT_HIT_COOLDOWN := 0.55
const ORBIT_RADIUS := 112.0
const ORBIT_BLADE_RADIUS := 52.0
const MINE_LIFETIME := 8.0
const MINE_MAX_RADIUS := 240.0
const AUTO_LASER_LENGTH := 760.0
const AUTO_LASER_HALF_WIDTH := 18.0
const AUTO_LASER_DURATION := 0.14
const AUTO_LASER_COOLDOWN := 0.9
const AUTO_LASER_CANDIDATE_LIMIT := 24
const STORM_MIN_DISTANCE := 480.0
const STORM_MAX_DISTANCE := 960.0
const STORM_TARGET_LIMIT := 12
const STORM_WARNING_DURATION := 0.55
const STORM_RADIUS := 280.0
const STORM_IMPACT_DURATION := 0.18
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")
const OutgoingDamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)

var catalog: RefCounted
var timers: Dictionary = {}
var orbit_angle := 0.0
var orbit_target_cooldowns: Dictionary = {}
var mines: Array[Dictionary] = []
var seeker_cooldown := 0.0
var auto_laser_cooldown := 0.0
var auto_laser_active_remaining := 0.0
var auto_laser_active_origin := Vector2.ZERO
var auto_laser_active_end := Vector2.ZERO
var storm_cooldown := 0.0
var storm_warning_remaining := 0.0
var storm_impact_remaining := 0.0
var storm_pending := false
var storm_position := Vector2.ZERO
var storm_pending_damage := 0.0
var storm_pending_level := 0
var storm_pending_attack_serial := 0
var _candidate_buffer: Array[EnemyState] = []
var _storm_selected_buffer: Array[EnemyState] = []
var _beam_target_buffer: Array[EnemyState] = []
var _auto_laser_candidate_buffer: Array[EnemyState] = []
var _expired_cooldown_ids: Array[String] = []
var _damage_output: Array[Dictionary] = []
var _projectile_output: Array[Dictionary] = []
var _detonation_output: Array[Dictionary] = []
var _beam_output: Array[Dictionary] = []
var _warning_output: Array[Dictionary] = []
var _impact_output: Array[Dictionary] = []
var _damage_intent_pool: Array[Dictionary] = []
var _detonation_receipt_pool: Array[Dictionary] = []
var _beam_intent_pool: Array[Dictionary] = []
var _warning_receipt_pool: Array[Dictionary] = []
var _impact_receipt_pool: Array[Dictionary] = []
var _damage_intent_count := 0
var _detonation_receipt_count := 0
var _beam_intent_count := 0
var _warning_receipt_count := 0
var _impact_receipt_count := 0
var _attack_serial := 0
var _primary_success_pending := false
var _primary_success_origin := Vector2.ZERO
var _primary_success_direction := Vector2.RIGHT
var _result: Dictionary = {}


func _init() -> void:
	catalog = SecondaryCatalog.new()
	_result = {
		"damage":_damage_output,
		"projectiles":_projectile_output,
		"detonations":_detonation_output,
		"beams":_beam_output,
		"warnings":_warning_output,
		"impacts":_impact_output,
	}
func reset(player_position: Vector2) -> void:
	timers.clear()
	orbit_target_cooldowns.clear()
	mines.clear()
	_storm_selected_buffer.clear()
	_beam_target_buffer.clear()
	orbit_angle = 0.0
	seeker_cooldown = 0.0
	auto_laser_cooldown = 0.0
	auto_laser_active_remaining = 0.0
	auto_laser_active_origin = player_position
	auto_laser_active_end = player_position
	storm_cooldown = 0.0
	storm_warning_remaining = 0.0
	storm_impact_remaining = 0.0
	storm_pending = false
	storm_position = player_position
	storm_pending_damage = 0.0
	storm_pending_level = 0
	storm_pending_attack_serial = 0
	_primary_success_pending = false
	_primary_success_origin = player_position
	_primary_success_direction = Vector2.RIGHT
	_attack_serial = 0


func record_primary_success(origin: Vector2, aim_direction: Vector2) -> void:
	## Queue one successful primary event for the next secondary update.
	_primary_success_pending = true
	_primary_success_origin = origin
	_primary_success_direction = (
		aim_direction.normalized()
		if not aim_direction.is_zero_approx()
		else Vector2.RIGHT
	)


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
	seeker_cooldown_multiplier: float = 1.0,
	attack_path_end: Callable = Callable(),
	aim_direction: Vector2 = Vector2.RIGHT
) -> Dictionary:
	# The returned result and damage intents are borrowed scratch storage and
	# remain valid only until the next update call.
	_damage_output.clear()
	_projectile_output.clear()
	_detonation_output.clear()
	_beam_output.clear()
	_warning_output.clear()
	_impact_output.clear()
	_damage_intent_count = 0
	_detonation_receipt_count = 0
	_beam_intent_count = 0
	_warning_receipt_count = 0
	_impact_receipt_count = 0
	var shared_cooldown_multiplier := build.stat(&"secondary_cooldown_multiplier", 1.0)
	var shared_damage_multiplier := build.stat(&"secondary_damage_multiplier", 1.0)
	seeker_cooldown = maxf(0.0, seeker_cooldown - delta)
	auto_laser_cooldown = maxf(0.0, auto_laser_cooldown - delta)
	auto_laser_active_remaining = maxf(
		0.0, auto_laser_active_remaining - delta
	)
	storm_cooldown = maxf(0.0, storm_cooldown - delta)
	storm_impact_remaining = maxf(0.0, storm_impact_remaining - delta)
	_update_auto_laser(
		player_position,
		build,
		enemies,
		line_of_sight,
		query_radius,
		attack_path_end,
		shared_cooldown_multiplier,
		shared_damage_multiplier
	)
	_update_storm_barrage(
		delta,
		player_position,
		aim_direction,
		build,
		enemies,
		query_radius,
		shared_cooldown_multiplier,
		shared_damage_multiplier
	)
	_update_seeker(
		delta,
		player_position,
		build,
		find_seeker_targets,
		seeker_blocked,
		_projectile_output,
		seeker_cooldown_multiplier * shared_cooldown_multiplier,
		shared_damage_multiplier
	)
	orbit_angle = fmod(orbit_angle + delta * 3.4, TAU)
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
		_damage_output,
		shared_cooldown_multiplier,
		shared_damage_multiplier
	)
	_update_orbit(
		player_position,
		build,
		enemies,
		line_of_sight,
		query_radius,
		_damage_output,
		shared_cooldown_multiplier,
		shared_damage_multiplier
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
		_detonation_output,
		shared_cooldown_multiplier,
		shared_damage_multiplier
	)
	_primary_success_pending = false
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
		"auto_laser_cooldown":auto_laser_cooldown,
		"auto_laser_active_remaining":auto_laser_active_remaining,
		"auto_laser_origin":auto_laser_active_origin,
		"auto_laser_end":auto_laser_active_end,
		"storm_cooldown":storm_cooldown,
		"storm_pending":storm_pending,
		"storm_position":storm_position,
		"storm_radius":STORM_RADIUS,
		"storm_warning_remaining":storm_warning_remaining,
		"storm_impact_remaining":storm_impact_remaining,
		"electric_field_radius":_electric_field_radius(build),
		"orbit_radius":ORBIT_RADIUS,
		"blade_radius":ORBIT_BLADE_RADIUS,
		"blade_count":_orbit_blade_count(build),
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
	output["auto_laser_cooldown"] = auto_laser_cooldown
	output["auto_laser_active_remaining"] = auto_laser_active_remaining
	output["auto_laser_origin"] = auto_laser_active_origin
	output["auto_laser_end"] = auto_laser_active_end
	output["orbit_radius"] = ORBIT_RADIUS
	output["blade_radius"] = ORBIT_BLADE_RADIUS
	output["blade_count"] = _orbit_blade_count(build)
	output["storm_pending"] = storm_pending
	output["storm_position"] = storm_position
	output["storm_radius"] = STORM_RADIUS
	output["storm_warning_remaining"] = storm_warning_remaining
	output["storm_impact_remaining"] = storm_impact_remaining
	return output


func _electric_field_radius(build: VehicleRunBuild) -> float:
	var definition := _definition(&"electric_field")
	if definition == null:
		return 0.0
	var level := build.level_of(definition.upgrade_id)
	return definition.auxiliary(level) if level > 0 else 0.0


func _orbit_blade_count(build: VehicleRunBuild) -> int:
	var definition := _definition(&"orbiting_blades")
	var level := build.level_of(&"orbiting_blades") if definition != null else 0
	return definition.cap(level) if level > 0 else 0


func equipped_families(build: VehicleRunBuild) -> Array[Dictionary]:
	var seeker := _definition(&"seeker")
	var result: Array[Dictionary] = [{
		"id":&"seeker",
		"level":1,
		"name_key":seeker.name_key if seeker != null else "SECONDARY_HOMING_MISSILES_NAME",
		"slot_kind":&"built_in",
	}]
	for secondary_id in [
		&"electric_field", &"orbiting_blades", &"drop_mines",
		&"auto_laser", &"storm_barrage",
	]:
		var definition := _definition(secondary_id)
		if definition == null:
			continue
		var level := build.level_of(definition.upgrade_id)
		if level > 0:
			result.append({"id":secondary_id, "level":level, "name_key":definition.name_key, "slot_kind":&"optional"})
	return result


func _update_auto_laser(
	origin: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable,
	attack_path_end: Callable,
	cooldown_multiplier: float,
	damage_multiplier: float
) -> void:
	if not _primary_success_pending:
		return
	var definition := _definition(&"auto_laser")
	var level := build.level_of(&"auto_laser") if definition != null else 0
	if level <= 0 or auto_laser_cooldown > 0.0:
		return
	var beam_origin := (
		_primary_success_origin if _primary_success_pending else origin
	)
	_query_candidates(beam_origin, AUTO_LASER_LENGTH, enemies, query_radius)
	_auto_laser_candidate_buffer.clear()
	for enemy in _candidate_buffer:
		if _eligible(enemy):
			_auto_laser_candidate_buffer.append(enemy)
	_auto_laser_candidate_buffer.sort_custom(
		func(a: EnemyState, b: EnemyState) -> bool:
			var a_distance := beam_origin.distance_squared_to(a.pos)
			var b_distance := beam_origin.distance_squared_to(b.pos)
			return a_distance < b_distance or (
				is_equal_approx(a_distance, b_distance) and String(a.id) < String(b.id)
			)
	)
	if _auto_laser_candidate_buffer.size() > AUTO_LASER_CANDIDATE_LIMIT:
		_auto_laser_candidate_buffer.resize(AUTO_LASER_CANDIDATE_LIMIT)
	if _auto_laser_candidate_buffer.is_empty():
		return
	var direction := Vector2.ZERO
	var beam_end := beam_origin
	var best_count := 0
	var best_priority := -1.0
	var best_nearest := INF
	var best_id := ""
	for candidate in _auto_laser_candidate_buffer:
		var candidate_direction := (candidate.pos - beam_origin).normalized()
		if candidate_direction.is_zero_approx():
			continue
		var candidate_end := beam_origin + candidate_direction * AUTO_LASER_LENGTH
		if attack_path_end.is_valid():
			var candidate_end_variant: Variant = attack_path_end.call(
				beam_origin, candidate_direction, AUTO_LASER_LENGTH, AUTO_LASER_HALF_WIDTH
			)
			if candidate_end_variant is Vector2:
				candidate_end = candidate_end_variant
		var candidate_length := beam_origin.distance_to(candidate_end)
		var hit_count := 0
		var priority_sum := 0.0
		var nearest := INF
		var nearest_id := ""
		for scored_enemy in _auto_laser_candidate_buffer:
			if not _beam_target_is_in_corridor(
				scored_enemy, beam_origin, candidate_direction, candidate_length, line_of_sight
			):
				continue
			hit_count += 1
			priority_sum += _storm_role_priority(scored_enemy.role)
			var distance := beam_origin.distance_squared_to(scored_enemy.pos)
			if distance < nearest or (is_equal_approx(distance, nearest) and String(scored_enemy.id) < nearest_id):
				nearest = distance
				nearest_id = String(scored_enemy.id)
		var better := (
			hit_count > best_count
			or (hit_count == best_count and priority_sum > best_priority)
			or (hit_count == best_count and is_equal_approx(priority_sum, best_priority) and nearest < best_nearest)
			or (hit_count == best_count and is_equal_approx(priority_sum, best_priority) and is_equal_approx(nearest, best_nearest) and nearest_id < best_id)
		)
		if better:
			best_count = hit_count
			best_priority = priority_sum
			best_nearest = nearest
			best_id = nearest_id
			direction = candidate_direction
			beam_end = candidate_end
	if best_count <= 0 or direction.is_zero_approx():
		return
	var beam_length := beam_origin.distance_to(beam_end)
	var attack_serial := _next_attack_serial()
	auto_laser_active_origin = beam_origin
	auto_laser_active_end = beam_end
	auto_laser_active_remaining = AUTO_LASER_DURATION
	auto_laser_cooldown = maxf(AUTO_LASER_COOLDOWN, definition.auxiliary(level)) * cooldown_multiplier
	_append_beam_intent(
		beam_origin,
		beam_end,
		direction,
		beam_length,
		definition.value(level) * damage_multiplier,
		attack_serial
	)
	_beam_target_buffer.clear()
	if beam_length <= 0.001:
		return
	_query_candidates(
		(beam_origin + beam_end) * 0.5,
		beam_length * 0.5 + AUTO_LASER_HALF_WIDTH,
		enemies,
		query_radius
	)
	for enemy in _candidate_buffer:
		if not _beam_target_is_in_corridor(
			enemy, beam_origin, direction, beam_length, line_of_sight
		):
			continue
		_beam_target_buffer.append(enemy)
	for enemy in _beam_target_buffer:
		_append_damage_intent(
			_damage_output,
			enemy,
			definition.value(level) * damage_multiplier,
			"Auto Laser",
			OutgoingDamagePolicy.DAMAGE_DIRECT,
			attack_serial
		)


func _beam_target_is_in_corridor(
	enemy: EnemyState,
	origin: Vector2,
	direction: Vector2,
	beam_length: float,
	line_of_sight: Callable
) -> bool:
	if not _eligible(enemy):
		return false
	var offset := enemy.pos - origin
	var along := offset.dot(direction)
	if along < -enemy.radius or along > beam_length + enemy.radius:
		return false
	var closest := origin + direction * clampf(along, 0.0, beam_length)
	var corridor_radius := AUTO_LASER_HALF_WIDTH + enemy.radius
	if enemy.pos.distance_squared_to(closest) > corridor_radius * corridor_radius:
		return false
	return (
		not line_of_sight.is_valid()
		or line_of_sight.call(origin, enemy.pos, AUTO_LASER_HALF_WIDTH)
	)


func _update_storm_barrage(
	delta: float,
	origin: Vector2,
	aim_direction: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	query_radius: Callable,
	cooldown_multiplier: float,
	damage_multiplier: float
) -> void:
	var definition := _definition(&"storm_barrage")
	var level := build.level_of(&"storm_barrage") if definition != null else 0
	if level <= 0:
		return
	if storm_pending:
		storm_warning_remaining = maxf(0.0, storm_warning_remaining - delta)
		if storm_warning_remaining > 0.000001:
			return
		_resolve_storm_barrage(enemies, query_radius)
		storm_pending = false
		storm_warning_remaining = 0.0
		_storm_selected_buffer.clear()
		return
	if storm_cooldown > 0.0:
		return
	_query_candidates(origin, STORM_MAX_DISTANCE, enemies, query_radius)
	_storm_selected_buffer.clear()
	var normalized_aim := (
		aim_direction.normalized()
		if not aim_direction.is_zero_approx()
		else Vector2.RIGHT
	)
	for enemy in _candidate_buffer:
		if not _storm_candidate_is_eligible(enemy, origin):
			continue
		enemy.target_score = _storm_candidate_score(
			enemy, origin, normalized_aim
		)
		_insert_storm_candidate(enemy)
	if _storm_selected_buffer.is_empty():
		return
	storm_position = _storm_selected_buffer[0].pos
	storm_pending = true
	storm_warning_remaining = STORM_WARNING_DURATION
	storm_cooldown = maxf(STORM_WARNING_DURATION, definition.auxiliary(level) * cooldown_multiplier)
	storm_pending_damage = definition.value(level) * damage_multiplier
	storm_pending_level = level
	storm_pending_attack_serial = _next_attack_serial()
	_append_warning_receipt(
		storm_position,
		STORM_RADIUS,
		STORM_WARNING_DURATION,
		storm_pending_attack_serial
	)


func _resolve_storm_barrage(
	enemies: Array[EnemyState],
	query_radius: Callable
) -> void:
	_query_candidates(storm_position, STORM_RADIUS, enemies, query_radius)
	_storm_selected_buffer.clear()
	for enemy in _candidate_buffer:
		if not _storm_impact_target_is_eligible(enemy, storm_position):
			continue
		enemy.target_score = _storm_impact_score(enemy, storm_position)
		_insert_storm_candidate(enemy)
	for enemy in _storm_selected_buffer:
		_append_damage_intent(
			_damage_output,
			enemy,
			storm_pending_damage,
			"Storm Barrage",
			OutgoingDamagePolicy.DAMAGE_DIRECT,
			storm_pending_attack_serial
		)
	_append_impact_receipt(
		storm_position,
		STORM_RADIUS,
		storm_pending_level,
		storm_pending_damage,
		storm_pending_attack_serial
	)
	storm_impact_remaining = STORM_IMPACT_DURATION


func _storm_candidate_is_eligible(enemy: EnemyState, origin: Vector2) -> bool:
	if not _eligible(enemy) or enemy.role == &"stage_boss":
		return false
	var distance := origin.distance_to(enemy.pos)
	return distance >= STORM_MIN_DISTANCE and distance <= STORM_MAX_DISTANCE


func _storm_impact_target_is_eligible(enemy: EnemyState, center: Vector2) -> bool:
	return (
		_eligible(enemy)
		and enemy.role != &"stage_boss"
		and enemy.pos.distance_to(center) <= STORM_RADIUS + enemy.radius
	)


func _storm_impact_score(enemy: EnemyState, center: Vector2) -> float:
	var role_priority := _storm_role_priority(enemy.role)
	var distance := center.distance_to(enemy.pos)
	return role_priority * 1000.0 - distance


func _storm_candidate_score(
	enemy: EnemyState,
	origin: Vector2,
	aim_direction: Vector2
) -> float:
	var cluster_count := 0
	var cluster_radius_squared := STORM_RADIUS * STORM_RADIUS
	for neighbor in _candidate_buffer:
		if neighbor == enemy or not _storm_candidate_is_eligible(neighbor, origin):
			continue
		if enemy.pos.distance_squared_to(neighbor.pos) <= cluster_radius_squared:
			cluster_count += 1
	var offset := enemy.pos - origin
	var alignment := 0.0
	if not offset.is_zero_approx():
		alignment = maxf(0.0, aim_direction.dot(offset.normalized()))
	var distance := origin.distance_to(enemy.pos)
	return (
		float(cluster_count) * 100000.0
		+ _storm_role_priority(enemy.role) * 1000.0
		+ alignment * 100.0
		- distance * 0.001
	)


func _storm_role_priority(role: StringName) -> float:
	match role:
		&"controller", &"artillery_spotter", &"shooter":
			return 4.0
		&"repair_tender", &"drone_carrier":
			return 3.0
		&"generator", &"turret", &"mine", &"interceptor_tower", &"beam_sentinel":
			return 2.0
	return 1.0


func _insert_storm_candidate(enemy: EnemyState) -> void:
	var insert_at := _storm_selected_buffer.size()
	for index in _storm_selected_buffer.size():
		var existing := _storm_selected_buffer[index]
		if _storm_candidate_precedes(enemy, existing):
			insert_at = index
			break
	if insert_at >= STORM_TARGET_LIMIT and _storm_selected_buffer.size() >= STORM_TARGET_LIMIT:
		return
	_storm_selected_buffer.insert(insert_at, enemy)
	if _storm_selected_buffer.size() > STORM_TARGET_LIMIT:
		_storm_selected_buffer.pop_back()


func _storm_candidate_precedes(first: EnemyState, second: EnemyState) -> bool:
	if not is_equal_approx(first.target_score, second.target_score):
		return first.target_score > second.target_score
	return String(first.id) < String(second.id)


func _update_seeker(
	delta: float,
	origin: Vector2,
	build: VehicleRunBuild,
	find_targets: Callable,
	blocked: bool,
	output: Array[Dictionary],
	cooldown_multiplier: float,
	damage_multiplier: float
) -> void:
	if blocked or seeker_cooldown > 0.0 or not find_targets.is_valid():
		return
	var definition := _definition(&"seeker")
	if definition == null:
		return
	var missile_level := clampi(build.level_of(&"homing_missiles"), 0, 3)
	var definition_level := missile_level + 1
	var seeker_count := definition.cap(definition_level)
	var targets_variant: Variant = find_targets.call(seeker_count)
	if not targets_variant is Array or targets_variant.is_empty():
		return
	seeker_cooldown = definition.auxiliary(definition_level) * cooldown_multiplier
	var seeker_damage := definition.value(definition_level) * damage_multiplier
	var attack_serial := _next_attack_serial()
	for target_variant in targets_variant:
		var target := target_variant as EnemyState
		if target == null:
			continue
		var direction := (target.pos - origin).normalized()
		output.append({
			"pos": origin + direction * 33.0,
			"spawn_origin": origin,
			"velocity": direction * 490.0,
			"radius": 8.0,
			"damage": seeker_damage,
			"damage_flags": OutgoingDamagePolicy.DAMAGE_DIRECT,
			"attack_serial": attack_serial,
			"combat_action_family": &"secondary",
			"combat_action_serial": attack_serial,
			"life": 1.8,
			"color": Color("8ae9dc"),
			"owner": "seeker",
			"pierce": 0,
			"bounces": 0,
			"homing": true,
			"target_id": target.id,
			"explosive": true,
			"structure_damage": 25.0 * damage_multiplier,
			"primary_payload": null,
			"wall_piercing": false,
		})


func _update_electric_field(delta: float, origin: Vector2, build: VehicleRunBuild, enemies: Array[EnemyState], line_of_sight: Callable, query_radius: Callable, output: Array[Dictionary], cooldown_multiplier: float, damage_multiplier: float) -> void:
	var definition := _definition(&"electric_field")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	if not _timer_ready(&"electric_field", delta, ION_TICK * cooldown_multiplier):
		return
	var radius := definition.auxiliary(level)
	_query_candidates(origin, radius, enemies, query_radius)
	var attack_serial := _next_attack_serial()
	for enemy in _candidate_buffer:
		var contact_radius := radius + enemy.radius
		if _eligible(enemy) and origin.distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(origin, enemy.pos, 3.0):
			_append_damage_intent(
				output,
				enemy,
				definition.value(level) * ION_TICK * damage_multiplier,
				"Electric Field",
				OutgoingDamagePolicy.DAMAGE_PERIODIC,
				attack_serial
			)


func _update_orbit(
	origin: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable,
	output: Array[Dictionary],
	cooldown_multiplier: float,
	damage_multiplier: float
) -> void:
	var definition := _definition(&"orbiting_blades")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	var count := definition.cap(level)
	for blade_index in count:
		var blade_position := origin + Vector2.RIGHT.rotated(orbit_angle + TAU * float(blade_index) / float(count)) * ORBIT_RADIUS
		_query_candidates(blade_position, ORBIT_BLADE_RADIUS, enemies, query_radius)
		var blade_attack_serial := 0
		for enemy in _candidate_buffer:
			var enemy_id := enemy.id
			if not _eligible(enemy) or float(orbit_target_cooldowns.get(enemy_id, 0.0)) > 0.0:
				continue
			var contact_radius := ORBIT_BLADE_RADIUS + enemy.radius
			if blade_position.distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(blade_position, enemy.pos, 2.0):
				orbit_target_cooldowns[enemy_id] = ORBIT_HIT_COOLDOWN * cooldown_multiplier
				if blade_attack_serial <= 0:
					blade_attack_serial = _next_attack_serial()
				_append_damage_intent(
					output,
					enemy,
					definition.value(level) * damage_multiplier,
					"Orbiting Blades",
					OutgoingDamagePolicy.DAMAGE_DIRECT,
					blade_attack_serial
				)


func _update_mines(
	delta: float,
	origin: Vector2,
	direction: Vector2,
	build: VehicleRunBuild,
	enemies: Array[EnemyState],
	line_of_sight: Callable,
	query_radius: Callable,
	damage_output: Array[Dictionary],
	detonation_output: Array[Dictionary],
	cooldown_multiplier: float,
	damage_multiplier: float
) -> void:
	var definition := _definition(&"drop_mines")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		mines.clear()
		return
	if _timer_ready(&"drop_mines", delta, definition.auxiliary(level) * cooldown_multiplier):
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
		var radius := minf(MINE_MAX_RADIUS, 168.0 + float(level) * 24.0)
		_query_candidates(Vector2(mine["pos"]), radius, enemies, query_radius)
		var attack_serial := _next_attack_serial()
		for enemy in _candidate_buffer:
			var contact_radius := radius + enemy.radius
			if _eligible(enemy) and Vector2(mine["pos"]).distance_squared_to(enemy.pos) <= contact_radius * contact_radius and line_of_sight.call(Vector2(mine["pos"]), enemy.pos, 3.0):
				_append_damage_intent(
					damage_output,
					enemy,
					definition.value(level) * damage_multiplier,
					"Drop Mine",
					OutgoingDamagePolicy.DAMAGE_DIRECT,
					attack_serial
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


func _next_attack_serial() -> int:
	_attack_serial += 1
	return _attack_serial


func _append_damage_intent(
	output: Array[Dictionary],
	enemy: EnemyState,
	damage: float,
	source: String,
	damage_flags: int,
	attack_serial: int
) -> void:
	if _damage_intent_count >= _damage_intent_pool.size():
		_damage_intent_pool.append({})
	var intent := _damage_intent_pool[_damage_intent_count]
	_damage_intent_count += 1
	intent["enemy"] = enemy
	intent["enemy_id"] = enemy.id
	intent["damage"] = damage
	intent["source"] = source
	intent["damage_flags"] = damage_flags
	intent["attack_serial"] = attack_serial
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


func _append_beam_intent(
	origin: Vector2,
	beam_end: Vector2,
	direction: Vector2,
	beam_length: float,
	damage: float,
	attack_serial: int
) -> void:
	if _beam_intent_count >= _beam_intent_pool.size():
		_beam_intent_pool.append({})
	var intent := _beam_intent_pool[_beam_intent_count]
	_beam_intent_count += 1
	intent["origin"] = origin
	intent["end"] = beam_end
	intent["direction"] = direction
	intent["length"] = beam_length
	intent["max_length"] = AUTO_LASER_LENGTH
	intent["half_width"] = AUTO_LASER_HALF_WIDTH
	intent["duration"] = AUTO_LASER_DURATION
	intent["damage"] = damage
	intent["source"] = "Auto Laser"
	intent["damage_flags"] = OutgoingDamagePolicy.DAMAGE_DIRECT
	intent["attack_serial"] = attack_serial
	intent["stop_at_cover"] = true
	_beam_output.append(intent)


func _append_warning_receipt(
	position: Vector2,
	radius: float,
	duration: float,
	attack_serial: int
) -> void:
	if _warning_receipt_count >= _warning_receipt_pool.size():
		_warning_receipt_pool.append({})
	var receipt := _warning_receipt_pool[_warning_receipt_count]
	_warning_receipt_count += 1
	receipt["kind"] = &"storm_barrage"
	receipt["position"] = position
	receipt["radius"] = radius
	receipt["duration"] = duration
	receipt["remaining"] = duration
	receipt["attack_serial"] = attack_serial
	_warning_output.append(receipt)


func _append_impact_receipt(
	position: Vector2,
	radius: float,
	level: int,
	damage: float,
	attack_serial: int
) -> void:
	if _impact_receipt_count >= _impact_receipt_pool.size():
		_impact_receipt_pool.append({})
	var receipt := _impact_receipt_pool[_impact_receipt_count]
	_impact_receipt_count += 1
	receipt["kind"] = &"storm_barrage"
	receipt["position"] = position
	receipt["radius"] = radius
	receipt["level"] = level
	receipt["damage"] = damage
	receipt["attack_serial"] = attack_serial
	_impact_output.append(receipt)


func _query_candidates(center: Vector2, radius: float, enemies: Array[EnemyState], query_radius: Callable) -> void:
	_candidate_buffer.clear()
	if query_radius.is_valid():
		query_radius.call(center, radius, _candidate_buffer)
		return
	for enemy in enemies:
		if _eligible(enemy):
			_candidate_buffer.append(enemy)
