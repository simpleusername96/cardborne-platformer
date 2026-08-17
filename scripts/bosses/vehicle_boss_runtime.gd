class_name VehicleBossRuntime
extends RefCounted

## Owns direct-pattern sequencing and independent system cadence.
## Semantic phase floors and objectives belong to VehicleBossExamRuntime.

const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

const PHASE_GAPS := [0.45, 0.34, 0.26]
const AUTONOMOUS_INTERVALS := [5.4, 4.4, 3.5]
const DIRECT_RECOVERY_SCALE := 0.80
const ACTION_NONE: StringName = &""
const ACTION_REPOSITION: StringName = &"reposition"
const ACTION_SELECT_DIRECT: StringName = &"select_direct"
const ACTION_REFRESH_STARTUP: StringName = &"refresh_startup"
const ACTION_BEGIN_ACTIVE: StringName = &"begin_active"
const ACTION_UPDATE_ACTIVE: StringName = &"update_active"
const PHASE_ACTIONS: Array[StringName] = [
	ACTION_NONE,
	ACTION_REPOSITION,
	ACTION_SELECT_DIRECT,
	ACTION_REFRESH_STARTUP,
	ACTION_BEGIN_ACTIVE,
	ACTION_UPDATE_ACTIVE,
]

var stage_id: StringName = &"stage_1"
var stage_index := 0
var autonomous_timer := 3.2
var autonomous_index := 0
var autonomous_serial := 0
var finite_summons_remaining := 6


func configure(next_stage_id: StringName) -> void:
	stage_id = next_stage_id
	stage_index = (
		StageDifficulty.stage_index_from_id(stage_id)
		if CombatStages.has_boss(stage_id) else -1
	)
	autonomous_timer = 3.2 * StageDifficulty.boss_cadence_scale(stage_index)
	autonomous_index = 0
	autonomous_serial = 0
	finite_summons_remaining = 6


func read_gap(phase: int) -> float:
	return (
		float(PHASE_GAPS[clampi(phase - 1, 0, PHASE_GAPS.size() - 1)])
		* StageDifficulty.boss_cadence_scale(stage_index)
	)


func select_direct(boss: VehicleEnemyState) -> String:
	var sequence := Patterns.sequence(stage_id, boss.boss_phase)
	if sequence.is_empty():
		return ""
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


func advance_direct_phase(
	boss: VehicleEnemyState,
	delta: float,
	attack_commit_blocked: bool
) -> Dictionary:
	var action := ACTION_NONE
	match StringName(boss.phase):
		&"boss_read":
			boss.phase_time = maxf(0.0, float(boss.phase_time) - delta)
			action = (
				ACTION_SELECT_DIRECT
				if boss.phase_time <= 0.0 and not attack_commit_blocked
				else ACTION_REPOSITION
			)
		&"boss_startup":
			boss.phase_time = maxf(0.0, float(boss.phase_time) - delta)
			action = (
				ACTION_BEGIN_ACTIVE
				if boss.phase_time <= 0.0
				else ACTION_REFRESH_STARTUP
			)
		&"boss_active":
			action = ACTION_UPDATE_ACTIVE
		&"boss_recovery":
			boss.phase_time = maxf(0.0, float(boss.phase_time) - delta)
			if boss.phase_time <= 0.0:
				boss.phase = &"boss_read"
				boss.phase_time = read_gap(boss.boss_phase)
				boss.pattern = &"reading_arena"
			action = ACTION_REPOSITION
	return {
		"action":action,
		"phase":StringName(boss.phase),
		"attack_commit_blocked":attack_commit_blocked,
	}


static func valid_phase_receipt(receipt: Dictionary) -> bool:
	return (
		receipt.has("action")
		and receipt.has("phase")
		and receipt.has("attack_commit_blocked")
		and StringName(receipt["action"]) in PHASE_ACTIONS
	)


func begin_active(boss: VehicleEnemyState, services: Variant) -> void:
	boss.phase = &"boss_active"
	boss.pattern_tick = 0.0
	var pattern := String(boss.pattern)
	boss.phase_time = Patterns.active_seconds(pattern)
	boss.pattern_volleys = 0
	var kind := Patterns.kind(pattern)
	if kind == &"summon":
		var spawn_count := mini(3, finite_summons_remaining)
		finite_summons_remaining -= spawn_count
		for _child_index in spawn_count:
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
	var damage := Patterns.damage(pattern, stage_index) * boss.boss_attack_damage_multiplier
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
					Patterns.affinity(pattern), true, false,
					AttackContract.THREAT_BOSS
				)
		else:
			var offsets: Array = (
				Patterns.fan_offsets(stage_index)
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
					true,
					false,
					AttackContract.THREAT_BOSS
				)
	elif kind == &"broad_barrage":
		if boss.pattern_volleys == 0:
			boss.pattern_volleys = 1
			# VehicleRun owns projectile allocation; this receipt keeps the three
			# simultaneous rows outside this state machine and under the fixed cap.
			services.call(
				"_spawn_boss_broad_barrage",
				boss,
				Patterns.broad_barrage_rows(
					stage_index,
					boss.committed_dir,
					Patterns.barrage_mode(stage_id)
				)
			)
	elif kind == &"cross_corridors":
		if boss.pattern_volleys == 0:
			boss.pattern_volleys = 1
			services.call(
				"_append_boss_cross_corridors",
				boss,
				pattern,
				damage
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
		var growth_ratio := AttackContract.emitted_beam_growth_ratio(
			boss.phase_time,
			Patterns.active_seconds(pattern)
		)
		var live_beam_end := AttackContract.emitted_beam_live_endpoint(
			boss.pos, boss.beam_end, growth_ratio
		)
		if (
			not boss.hit_committed
			and Rules.point_segment_distance(
				services.player_position, boss.pos, live_beam_end
			) <= Rules.PLAYER_RADIUS + Patterns.width(pattern, stage_index) * 0.5
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
			Patterns.radius(pattern, stage_index)
		)
		if area_damage > 0.0 and not boss.hit_committed:
			boss.hit_committed = true
			services.call("_damage_player", area_damage, pattern, false, true, true)
	if boss.phase_time <= 0.0:
		services.call("_on_boss_direct_attack_complete", boss)
		boss.phase = &"boss_recovery"
		boss.phase_time = (
			Patterns.recovery_seconds(pattern)
			* DIRECT_RECOVERY_SCALE
			* StageDifficulty.boss_cadence_scale(stage_index)
		)
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
	if sequence.is_empty():
		return events
	var pattern := String(sequence[autonomous_index % sequence.size()])
	autonomous_index += 1
	autonomous_serial += 1
	autonomous_timer = float(
		AUTONOMOUS_INTERVALS[clampi(boss.boss_phase - 1, 0, 2)]
	) * StageDifficulty.boss_cadence_scale(stage_index)
	if Patterns.kind(pattern) == &"summon":
		if finite_summons_remaining <= 0:
			return events
		finite_summons_remaining -= 1
	var offset := Vector2.RIGHT.rotated(
		float(autonomous_serial * 2 + boss.boss_phase) * 1.17
	) * (180.0 + 35.0 * float(boss.boss_phase))
	events.append({
		"id":"boss_system_%d" % autonomous_serial,
		"pattern":pattern,
		"kind":Patterns.kind(pattern),
		"origin":boss.pos,
		"target":player_position + offset,
		"startup":Patterns.startup_seconds(pattern),
		"duration":Patterns.active_seconds(pattern),
		"damage":Patterns.damage(pattern, stage_index),
		"radius":Patterns.radius(pattern, stage_index),
		"width":Patterns.width(pattern, stage_index),
		"lane_spacing":Patterns.lane_spacing(stage_index),
		"affinity":Patterns.affinity(pattern),
		"commit_mode":&"autonomous",
		"emitter_radius":boss.visual_radius,
	})
	return events


func snapshot() -> Dictionary:
	return {
		"stage_id":stage_id,
		"stage_index":stage_index,
		"cadence_scale":StageDifficulty.boss_cadence_scale(stage_index),
		"autonomous_timer":autonomous_timer,
		"autonomous_index":autonomous_index,
		"finite_summons_remaining":finite_summons_remaining,
	}
