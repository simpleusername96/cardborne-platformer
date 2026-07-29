class_name VehicleBossRuntime
extends RefCounted

## Owns boss phase sequencing and independent system cadence.
## VehicleRun supplies collision and spawn services but does not choose state.

const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")

const PHASE_THRESHOLDS := [0.65, 0.30]
const PHASE_GAPS := [0.55, 0.42, 0.32]
const AUTONOMOUS_INTERVALS := [6.0, 4.9, 3.9]

var stage_id: StringName = &"stage_1"
var autonomous_timer := 3.2
var autonomous_index := 0
var autonomous_serial := 0


func configure(next_stage_id: StringName) -> void:
	stage_id = next_stage_id
	autonomous_timer = 3.2
	autonomous_index = 0
	autonomous_serial = 0


func phase_for_health(health_ratio: float) -> int:
	if health_ratio <= PHASE_THRESHOLDS[1]:
		return 3
	if health_ratio <= PHASE_THRESHOLDS[0]:
		return 2
	return 1


func update_phase_transition(boss: VehicleEnemyState) -> bool:
	var next_phase := phase_for_health(boss.health / maxf(1.0, boss.max_health))
	if next_phase <= boss.boss_phase:
		return false
	boss.boss_phase = next_phase
	boss.phase = &"boss_read"
	boss.phase_time = 0.90
	boss.pattern = &"phase_transition"
	boss.pattern_index = 0
	boss.attack_telegraphs.clear()
	return true


func read_gap(phase: int) -> float:
	return float(PHASE_GAPS[clampi(phase - 1, 0, PHASE_GAPS.size() - 1)])


func select_direct(boss: VehicleEnemyState) -> String:
	var sequence := Patterns.sequence(stage_id, boss.boss_phase)
	var candidate := String(sequence[boss.pattern_index % sequence.size()])
	boss.pattern_index += 1
	if candidate == String(boss.last_pattern):
		for offset in sequence.size():
			var alternate := String(sequence[(boss.pattern_index + offset) % sequence.size()])
			if alternate != String(boss.last_pattern):
				candidate = alternate
				boss.pattern_index += offset + 1
				break
	return candidate


func begin_active(boss: VehicleEnemyState, services: Variant) -> void:
	boss.phase = &"boss_active"
	boss.pattern_tick = 0.0
	var pattern := String(boss.pattern)
	boss.phase_time = Patterns.active_seconds(pattern)
	boss.pattern_volleys = 0
	var kind := Patterns.kind(pattern)
	if kind == &"pylons":
		services.call("_spawn_boss_pylons")
	elif kind == &"summon":
		for _child_index in 3:
			services.call("_spawn_carrier_child", boss)


func update_active(
	boss: VehicleEnemyState,
	delta: float,
	services: Variant
) -> void:
	boss.phase_time = maxf(0.0, boss.phase_time - delta)
	boss.pattern_tick -= delta
	var pattern := String(boss.pattern)
	var kind := Patterns.kind(pattern)
	var damage := Patterns.damage(pattern)
	var escalated := boss.boss_phase >= 2
	if damage <= 0.0:
		services.call("_boss_combat_move", boss, delta, Patterns.ACTIVE_MOVE_SCALE)
	if (
		kind in [&"lanes", &"fan", &"cross"]
		and boss.pattern_tick <= 0.0
		and boss.pattern_volleys < Patterns.volley_limit(pattern, escalated)
	):
		boss.pattern_tick = Patterns.volley_interval(pattern)
		boss.pattern_volleys += 1
		var aimed_direction := boss.committed_dir
		if kind == &"lanes":
			var lane_tangent := aimed_direction.rotated(PI * 0.5)
			for lane_offset in boss.lane_centers:
				var origin := boss.pos + aimed_direction * 86.0 + lane_tangent * float(lane_offset)
				services.call(
					"_spawn_hostile_projectile", origin, aimed_direction, damage,
					Patterns.projectile_speed(pattern), pattern,
					Patterns.affinity(pattern), true
				)
		else:
			var offsets := (
				[-0.34, -0.17, 0.0, 0.17, 0.34]
				if kind == &"fan"
				else [0.0, PI * 0.5, PI, PI * 1.5]
			)
			for offset in offsets:
				var direction := aimed_direction.rotated(float(offset))
				services.call(
					"_spawn_hostile_projectile",
					boss.pos + direction * 72.0,
					direction,
					damage,
					Patterns.projectile_speed(pattern),
					pattern,
					Patterns.affinity(pattern),
					true
				)
	elif kind == &"charge":
		if boss.pattern_volleys == 0:
			services.call("_boss_fire_aimed_burst", boss, pattern, damage * 0.55)
		var before := boss.pos
		var requested := (
			boss.committed_dir
			* Patterns.BOSS_CHARGE_SPEED
			* EncounterDirector.ENEMY_SPEED_MULTIPLIER
			* delta
		)
		boss.pos = services.call(
			"_runtime_charge_path_end",
			before,
			boss.committed_dir,
			requested.length(),
			boss.radius
		)
		if (
			not boss.hit_committed
			and services.player_position.distance_to(boss.pos)
				<= AttackContract.contact_danger_half_width(
					boss.radius, Patterns.BOSS_CONTACT_PADDING
				)
		):
			boss.hit_committed = true
			services.call("_damage_player", damage, pattern, true, true, true)
		if before.distance_to(boss.pos) + 1.0 < requested.length():
			boss.phase_time = 0.0
	elif kind == &"beam":
		if (
			not boss.hit_committed
			and Rules.point_segment_distance(
				services.player_position, boss.pos, boss.beam_end
			) <= Rules.PLAYER_RADIUS + Patterns.width(pattern) * 0.5
		):
			boss.hit_committed = true
			services.call("_damage_player", damage, pattern, true, true, true)
	elif kind in [&"area", &"pylons", &"summon"]:
		if boss.pattern_volleys == 0:
			services.call(
				"_boss_fire_aimed_burst",
				boss,
				pattern,
				maxf(12.0, damage * 0.55)
			)
		var area_damage := AttackContract.radial_damage(
			damage,
			services.player_position.distance_to(boss.committed_target),
			Patterns.radius(pattern)
		)
		if area_damage > 0.0 and not boss.hit_committed:
			boss.hit_committed = true
			services.call("_damage_player", area_damage, pattern, false, true, true)
	if boss.phase_time <= 0.0:
		boss.phase = &"boss_recovery"
		boss.phase_time = Patterns.recovery_seconds(pattern)
		boss.vulnerable = 1.55 if kind in [&"charge", &"area"] else 0.65
		boss.last_pattern = pattern
		boss.pattern = &"recovery_window"


func advance_autonomous(
	delta: float,
	boss: VehicleEnemyState,
	player_position: Vector2
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	autonomous_timer -= delta
	if autonomous_timer > 0.0:
		return events
	var sequence := Patterns.autonomous_sequence(stage_id)
	var pattern := String(sequence[autonomous_index % sequence.size()])
	autonomous_index += 1
	autonomous_serial += 1
	autonomous_timer = float(
		AUTONOMOUS_INTERVALS[clampi(boss.boss_phase - 1, 0, 2)]
	)
	var offset := Vector2.RIGHT.rotated(
		float(autonomous_serial * 2 + boss.boss_phase) * 1.17
	) * (180.0 + 35.0 * float(boss.boss_phase))
	events.append({
		"id":"boss_system_%d" % autonomous_serial,
		"pattern":pattern,
		"origin":boss.pos,
		"target":player_position + offset,
		"startup":Patterns.startup_seconds(pattern),
		"duration":Patterns.active_seconds(pattern),
		"damage":Patterns.damage(pattern),
		"radius":Patterns.radius(pattern),
		"affinity":Patterns.affinity(pattern),
		"commit_mode":&"autonomous",
	})
	return events


func snapshot() -> Dictionary:
	return {
		"stage_id":stage_id,
		"autonomous_timer":autonomous_timer,
		"autonomous_index":autonomous_index,
	}
