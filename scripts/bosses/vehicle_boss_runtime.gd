class_name VehicleBossRuntime
extends RefCounted

## Owns direct-pattern sequencing and independent system cadence.
## Semantic phase floors and objectives belong to VehicleBossExamRuntime.

const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const PhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const LateBossMechanics = preload("res://scripts/bosses/vehicle_late_boss_mechanics.gd")

const MAX_PENDING_RADIAL_VOLLEYS := 4
const MAX_PENDING_DISTANCE_GROWTH_PAIRS := 5
const DISTANCE_GROWTH_PAIR_INTERVAL := 0.22
const COMMON_ATTACKS_BEFORE_SIGNATURE := 2
const SQUAD_INTERVAL_SECONDS := 10.0
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
const DIRECT_PATTERN_KINDS: Array[StringName] = [
	&"lanes", &"fan", &"cross", &"broad_barrage", &"cross_corridors",
	&"crossing_weave", &"compression", &"radial_volley", &"charge", &"beam",
	&"switch_sweep", &"area", &"pylons", &"summon", &"long_banks",
]
const AUTONOMOUS_PATTERN_KINDS: Array[StringName] = [
	&"area", &"lanes", &"beam", &"summon", &"long_banks",
	&"crossing_weave", &"radial_volley", &"compression",
]

var stage_id: StringName = &"stage_1"
var stage_index := 0
var autonomous_timer := 3.2
var autonomous_index := 0
var autonomous_serial := 0
var common_index := 0
var signature_index := 0
var common_attacks_since_signature := 0
var squad_timer := SQUAD_INTERVAL_SECONDS
var squad_serial := 0
var finite_summons_remaining := 6
var _pending_radial_volleys: Array[Dictionary] = []
var _pending_distance_growth_pairs: Array[Dictionary] = []


func configure(next_stage_id: StringName) -> void:
	stage_id = next_stage_id
	stage_index = (
		BossProfiles.stage_index_from_id(stage_id)
		if CombatStages.has_boss(stage_id) else -1
	)
	autonomous_timer = (
		float(BossProfiles.profile(stage_index).get("initial_autonomous_delay", 0.0))
		if not Patterns.autonomous_sequence(stage_id).is_empty()
		else INF
	)
	autonomous_index = 0
	autonomous_serial = 0
	common_index = 0
	signature_index = 0
	common_attacks_since_signature = 0
	squad_timer = SQUAD_INTERVAL_SECONDS
	squad_serial = 0
	finite_summons_remaining = 6
	_pending_radial_volleys.clear()
	_pending_distance_growth_pairs.clear()


func schedule_radial_volley(event: Dictionary) -> bool:
	if _pending_radial_volleys.size() >= MAX_PENDING_RADIAL_VOLLEYS:
		return false
	var turn := -1.0 if String(event["pattern"]) == "radial_volley_b" else 1.0
	_pending_radial_volleys.append({
		"id":String(event["id"]),
		"remaining":maxf(0.0, float(event["startup"]) + 0.55),
		"origin":Vector2(event["origin"]),
		"count":12,
		"rotation":turn * 0.18,
		"damage":float(event["damage"]),
		"source":String(event["pattern"]),
		"affinity":StringName(event["affinity"]),
	})
	return true


func schedule_distance_growth_pairs(event: Dictionary) -> bool:
	if not _pending_distance_growth_pairs.is_empty():
		return false
	for pair_index in MAX_PENDING_DISTANCE_GROWTH_PAIRS:
		_pending_distance_growth_pairs.append({
			"remaining":float(pair_index) * DISTANCE_GROWTH_PAIR_INTERVAL,
			"origin":Vector2(event["origin"]),
			"axis":Vector2(event["axis"]),
			"damage":float(event["damage"]),
			"pattern":String(event["pattern"]),
			"affinity":StringName(event["affinity"]),
		})
	return true


func advance_pending_attacks(delta: float, services: Variant) -> void:
	for index in range(_pending_radial_volleys.size() - 1, -1, -1):
		var volley := _pending_radial_volleys[index]
		volley["remaining"] = float(volley["remaining"]) - maxf(0.0, delta)
		if float(volley["remaining"]) > 0.0:
			continue
		services.call("_fire_boss_radial_volley", volley)
		_pending_radial_volleys.remove_at(index)
	for index in range(_pending_distance_growth_pairs.size() - 1, -1, -1):
		var pair := _pending_distance_growth_pairs[index]
		pair["remaining"] = float(pair["remaining"]) - maxf(0.0, delta)
		if float(pair["remaining"]) > 0.00001:
			continue
		services.call("_fire_distance_growth_pair", pair)
		_pending_distance_growth_pairs.remove_at(index)


func clear_pending_attacks() -> void:
	_pending_radial_volleys.clear()
	_pending_distance_growth_pairs.clear()


func pending_radial_volley_count() -> int:
	return _pending_radial_volleys.size()


func pending_distance_growth_pair_count() -> int:
	return _pending_distance_growth_pairs.size()


func read_gap(phase: int) -> float:
	return BossProfiles.read_gap(stage_index, phase)


func select_direct(boss: VehicleEnemyState) -> String:
	var common := Patterns.common_sequence(stage_id, boss.boss_phase)
	var signatures := Patterns.signature_sequence(stage_id, boss.boss_phase)
	if common.is_empty() and signatures.is_empty():
		return ""
	var choose_signature := (
		not signatures.is_empty()
		and common_attacks_since_signature >= COMMON_ATTACKS_BEFORE_SIGNATURE
	)
	var sequence: Array[String] = signatures if choose_signature else common
	if sequence.is_empty():
		sequence = signatures
		choose_signature = true
	var cursor := signature_index if choose_signature else common_index
	var candidate := String(sequence[cursor % sequence.size()])
	cursor += 1
	if candidate == String(boss.last_pattern) and sequence.size() > 1:
		candidate = String(sequence[cursor % sequence.size()])
		cursor += 1
	if choose_signature:
		signature_index = cursor
		common_attacks_since_signature = 0
	else:
		common_index = cursor
		common_attacks_since_signature += 1
	boss.pattern_index += 1
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


static func supports_direct_pattern(pattern: String) -> bool:
	return Patterns.kind(pattern) in DIRECT_PATTERN_KINDS


static func supports_autonomous_pattern(pattern: String) -> bool:
	return Patterns.kind(pattern) in AUTONOMOUS_PATTERN_KINDS


func begin_active(boss: VehicleEnemyState, services: Variant) -> void:
	boss.phase = &"boss_active"
	boss.pattern_tick = 0.0
	var pattern := String(boss.pattern)
	boss.phase_time = Patterns.active_seconds(pattern, stage_index)
	boss.pattern_volleys = 0
	var kind := Patterns.kind(pattern)
	if kind == &"summon":
		var spawn_count := mini(3, finite_summons_remaining)
		finite_summons_remaining -= spawn_count
		for _child_index in spawn_count:
			services.call("_spawn_carrier_child", boss)
	elif kind == &"long_banks":
		boss.pattern_volleys = 1
		services.call("_spawn_boss_long_banks", {
			"origin":Vector2(boss.pos),
			"target":Vector2(boss.committed_target),
			"damage":Patterns.damage(pattern, stage_index)
				* boss.boss_attack_damage_multiplier,
			"pattern":pattern,
			"affinity":Patterns.affinity(pattern),
		})


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
		services.call(
			"_boss_combat_move",
			boss,
			delta,
			BossProfiles.attack_move_speed(stage_index)
		)
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
	elif kind in [&"crossing_weave", &"compression"]:
		if boss.pattern_volleys == 0:
			boss.pattern_volleys = 1
			services.call("_activate_boss_identity_pattern", boss, pattern)
	elif kind == &"radial_volley":
		# VehicleRun scheduled the projectile-only volley when the pattern was
		# selected. The active phase owns no hidden area damage or warning zone.
		boss.pattern_volleys = 1
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
			and bool(services.call(
				"_boss_charge_contact_hits",
				before,
				boss.pos,
				boss.radius,
				Patterns.BOSS_CONTACT_PADDING
			))
		):
			boss.hit_committed = true
			services.call("_damage_player", damage, pattern, true, true, true)
		if before.distance_to(boss.pos) + 1.0 < requested.length():
			boss.phase_time = 0.0
	elif kind in [&"beam", &"switch_sweep"]:
		var active_total := Patterns.active_seconds(pattern, stage_index)
		var elapsed := active_total - boss.phase_time
		for telegraph in boss.attack_telegraphs:
			if StringName(telegraph.get("delivery", &"")) != &"beam":
				continue
			var release_delay := float(telegraph.get("beam_release_delay", 0.0))
			if elapsed < release_delay:
				continue
			var growth_ratio := clampf(
				(elapsed - release_delay)
					/ maxf(0.001, float(telegraph.get(
						"beam_growth_seconds", AttackContract.EMITTED_BEAM_GROWTH_SECONDS
					))),
				0.0,
				1.0
			)
			var emitter := Vector2(telegraph.get("beam_emitter", boss.pos))
			var endpoints: Array[Vector2] = [Vector2(telegraph["to"])]
			if StringName(telegraph.get("beam_emission_mode", &"")) == AttackContract.EMITTED_BEAM_BIDIRECTIONAL:
				endpoints.push_front(Vector2(telegraph["from"]))
			for endpoint in endpoints:
				var live_end := AttackContract.emitted_beam_live_endpoint(
					emitter, endpoint, growth_ratio
				)
				if (
					not boss.hit_committed
					and bool(services.call(
						"_player_sweep_hits_corridor",
						emitter,
						live_end,
						Patterns.width(pattern, stage_index) * 0.5
					))
				):
					boss.hit_committed = true
					services.call("_damage_player", damage, pattern, true, true, true)
					break
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
			float(services.call(
				"_player_sweep_distance_to_point", boss.committed_target
			)),
			Patterns.radius(pattern, stage_index)
		)
		if area_damage > 0.0 and not boss.hit_committed:
			boss.hit_committed = true
			services.call("_damage_player", area_damage, pattern, false, true, true)
	if boss.phase_time <= 0.0:
		services.call("_on_boss_direct_attack_complete", boss)
		boss.phase = &"boss_recovery"
		boss.phase_time = Patterns.recovery_seconds(pattern, stage_index)
		boss.vulnerable = 1.55 if kind in [&"charge", &"area"] else 0.65
		boss.last_pattern = pattern
		boss.pattern = &"recovery_window"


func advance_autonomous(
	delta: float,
	boss: VehicleEnemyState,
	player_position: Vector2
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var sequence := Patterns.autonomous_sequence(stage_id)
	if sequence.is_empty():
		autonomous_timer = INF
		return events
	autonomous_timer -= maxf(0.0, delta)
	if autonomous_timer > 0.0:
		return events
	var pattern := String(sequence[autonomous_index % sequence.size()])
	autonomous_index += 1
	autonomous_serial += 1
	autonomous_timer = BossProfiles.autonomous_interval(stage_index, boss.boss_phase)
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
		"startup":Patterns.startup_seconds(pattern, stage_index),
		"duration":Patterns.active_seconds(pattern, stage_index),
		"damage":Patterns.damage(pattern, stage_index) * (
			LateBossMechanics.OVERLOAD_DEALT_DAMAGE_SCALE
			if stage_index == 11 and LateBossMechanics.overload_active(boss.pattern_timer)
			else 1.0
		),
		"radius":Patterns.radius(pattern, stage_index),
		"width":Patterns.width(pattern, stage_index),
		"lane_spacing":Patterns.lane_spacing(stage_index),
		"affinity":Patterns.affinity(pattern),
		"commit_mode":&"autonomous",
		"emitter_radius":boss.visual_radius,
		"beam_topology":AttackContract.HOSTILE_BEAM_TOPOLOGIES[
			posmod(autonomous_serial - 1, AttackContract.HOSTILE_BEAM_TOPOLOGIES.size())
		],
	})
	return events


func advance_squad(
	delta: float,
	boss: VehicleEnemyState,
	major_signature_active: bool = false
) -> Dictionary:
	squad_timer = maxf(0.0, squad_timer - maxf(0.0, delta))
	if squad_timer > 0.0 or major_signature_active:
		return {}
	var roles := PhaseCatalog.squad_roles(stage_id, boss.boss_phase)
	if roles.is_empty():
		squad_timer = SQUAD_INTERVAL_SECONDS
		return {}
	squad_serial += 1
	squad_timer = SQUAD_INTERVAL_SECONDS
	return {
		"id":"boss_squad_%d" % squad_serial,
		"pattern":&"common_squad_call",
		"roles":roles,
		"tactic_id":PhaseCatalog.squad_tactic_id(stage_id, boss.boss_phase),
		"phase":boss.boss_phase,
	}


func snapshot() -> Dictionary:
	return {
		"stage_id":stage_id,
		"stage_index":stage_index,
		"profile":BossProfiles.profile(stage_index).duplicate(true),
		"autonomous_timer":autonomous_timer,
		"autonomous_index":autonomous_index,
		"common_index":common_index,
		"signature_index":signature_index,
		"common_attacks_since_signature":common_attacks_since_signature,
		"squad_timer":squad_timer,
		"squad_serial":squad_serial,
		"finite_summons_remaining":finite_summons_remaining,
		"pending_radial_volley_count":_pending_radial_volleys.size(),
	}
