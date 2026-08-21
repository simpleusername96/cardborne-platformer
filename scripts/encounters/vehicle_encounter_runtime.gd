class_name VehicleEncounterRuntime
extends RefCounted

## Deterministic authored-packet scheduler. Timing windows own cue/admission;
## the allocator owns unit birth positions and combat actors remain external.

const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const SpawnAllocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const EngagementDirector = preload("res://scripts/encounters/vehicle_engagement_director.gd")
const MovementPolicy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const TargetingPolicy = preload("res://scripts/enemies/vehicle_enemy_targeting_policy.gd")
const SpeedProfile = preload("res://scripts/enemies/vehicle_enemy_speed_profile.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const FamilyTraits = preload(
	"res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd"
)
const Field = preload("res://scripts/vehicle/stages/field_01.gd")

const CUE_LEAD := 0.9
const WINDOW_GAP := 1.20
const REFILL_WINDOW_GAP := 0.35
const RETRY_INTERVAL := 0.25
const RECENT_BIRTH_SECONDS := 2.0
const METRIC_SAMPLE_INTERVAL := 0.10
const MAX_ACTIVE_COUNT_SAMPLES := 4096
const MAX_SPAWNS_PER_TICK := 4
const BOSS_MAINTENANCE_LOW_WATERMARK := 8
const BOSS_MAINTENANCE_HIGH_WATERMARK := 12
const BOSS_MAINTENANCE_MAX_GROUP := 4
const BOSS_MAINTENANCE_INTERVAL := 4.0
const BOSS_VISIBILITY_GAP_INTERVAL := 0.75

var stage_id: StringName = &"stage_1"
var difficulty: StringName = RunDifficulty.DEFAULT
var elapsed := 0.0
var current_beat := 0

var _packets: Array[Dictionary] = []
var _activated_packets: Dictionary = {}
var _events: Dictionary = {}
var _window_queue: Array[Dictionary] = []
var _spawn_queue: Array[Dictionary] = []
var _timeline: Array[Dictionary] = []
var _spawned_by_squad: Dictionary = {}
var _recent_births: Array[Dictionary] = []
var _packet_inflight := false
var _reserved_arrival_slots := 0
var _last_cue_at := -INF
var _first_cue_time := -1.0
var _first_spawn_time := -1.0
var _first_attack_preparation_time := -1.0
var _first_damage_time := -1.0
var _first_reward_time := -1.0
var _active_count_samples: Array[int] = []
var _max_attack_family_overlap := 0
var _damage_source_families: Dictionary = {}
var _capacity_blocked_seconds := 0.0
var _packet_fence_blocked_seconds := 0.0
var _birth_capacity_blocked := 0
var _scheduler_starvation := 0
var _spawn_materialization_failures := 0
var _authored_population := 0
var _virtual_reserve_units := 0
var _materialized_spawned := 0
var _next_metric_sample := 0.0
var _spawning_enabled := true
var _quota_sealed := false
var _quota_canceled_reserve := 0
var _boss_maintenance_active := false
var _last_boss_maintenance_cue_at := -INF
var _maintenance_roles: Array[StringName] = []
var _maintenance_roster: Array[StringName] = []
var _spawn_allocator := SpawnAllocator.new()
var _engagement_director := EngagementDirector.new()
var _geometry_snapshot: Variant
var _stage_index := 0
var _allocation_debug: Array[Dictionary] = []
var _pressure_snapshot := {}
var _pressure_observation_enabled := false
var _pressure_scan_happened := false
var _engagement_telemetry_enabled := false
var _telemetry_births := 0
var _telemetry_gate_completions := 0
var _telemetry_expiries := 0
var _telemetry_cancellations := 0
var _telemetry_director_cpu_us := 0
var _diagnostic_gap_reason: StringName = &"none"
var _diagnostic_gap_started_at := -1.0


func configure(
	next_stage_id: StringName,
	packets: Array[Dictionary],
	_run_difficulty: StringName,
	spawn_anchors: Array[Vector2] = Field.ORDINARY_SPAWN_CANDIDATES,
	encounter_seed: int = 0,
	geometry_snapshot: Variant = null,
	stage_index: int = -1
) -> void:
	stage_id = next_stage_id
	# The argument is retained temporarily for fixture compatibility; encounters
	# always use the single fixed Hard profile.
	difficulty = RunDifficulty.HARD
	elapsed = 0.0
	current_beat = 0
	_packets.clear()
	for packet_index in packets.size():
		var packet := packets[packet_index].duplicate(true)
		packet["_packet_index"] = packet_index
		# Every stage entry uses the first authored packet as its real opening
		# reserve. Continuations supply a derived opening packet through the same
		# configure boundary, so this keeps its approach just beyond the camera too.
		if packet_index == 0 and StringName(Dictionary(packet.get("trigger", {})).get("kind", &"")) == &"time":
			packet["nearest_safe_offscreen"] = true
		_packets.append(packet)
	_authored_population = 0
	for packet in _packets:
		_authored_population += _packet_unit_count(packet)
	_virtual_reserve_units = _authored_population
	_activated_packets.clear()
	_events.clear()
	_window_queue.clear()
	_cancel_queued_engagements()
	_spawn_queue.clear()
	_timeline.clear()
	_spawned_by_squad.clear()
	_recent_births.clear()
	_packet_inflight = false
	_reserved_arrival_slots = 0
	_last_cue_at = -INF
	_first_cue_time = -1.0
	_first_spawn_time = -1.0
	_first_attack_preparation_time = -1.0
	_first_damage_time = -1.0
	_first_reward_time = -1.0
	_active_count_samples.clear()
	_max_attack_family_overlap = 0
	_damage_source_families.clear()
	_capacity_blocked_seconds = 0.0
	_packet_fence_blocked_seconds = 0.0
	_birth_capacity_blocked = 0
	_scheduler_starvation = 0
	_spawn_materialization_failures = 0
	_materialized_spawned = 0
	_next_metric_sample = 0.0
	_spawning_enabled = true
	_quota_sealed = false
	_quota_canceled_reserve = 0
	_boss_maintenance_active = false
	_last_boss_maintenance_cue_at = -INF
	_maintenance_roles.clear()
	_maintenance_roster.clear()
	_allocation_debug.clear()
	_pressure_snapshot = _empty_pressure_snapshot()
	_pressure_observation_enabled = false
	_pressure_scan_happened = false
	_geometry_snapshot = geometry_snapshot
	_stage_index = CombatStages.index_of(next_stage_id) if stage_index < 0 else stage_index
	_telemetry_births = 0
	_telemetry_gate_completions = 0
	_telemetry_expiries = 0
	_telemetry_cancellations = 0
	_telemetry_director_cpu_us = 0
	_diagnostic_gap_reason = &"none"
	_diagnostic_gap_started_at = -1.0
	_spawn_allocator.configure(encounter_seed, spawn_anchors, geometry_snapshot)
	_engagement_director.configure(encounter_seed)
	_spawn_allocator.prewarm_for_packets(_packets)


func stop_spawning() -> void:
	_spawning_enabled = false
	_window_queue.clear()
	_cancel_queued_engagements()
	_spawn_queue.clear()
	var unclaimed := _engagement_director.cancel_all_reserved()
	for _index in unclaimed:
		note_engagement_cancellation()
	_reserved_arrival_slots = 0
	_virtual_reserve_units = 0
	_packet_inflight = false


func seal_for_quota() -> void:
	## Quota seals progression but not ordinary presence. Cued rounds drain;
	## maintenance admits only identities still held by later authored packets.
	if _quota_sealed:
		return
	_quota_sealed = true
	for request_variant in _window_queue:
		_append_maintenance_window_roles(Dictionary(request_variant))
	_window_queue.clear()
	_boss_maintenance_active = true
	# The authored reserve is already available at quota seal. Let the first
	# low-watermark group cue on the next scheduler tick instead of waiting a
	# full maintenance interval while the boss is entering.
	_last_boss_maintenance_cue_at = elapsed - BOSS_MAINTENANCE_INTERVAL
	for packet in _packets:
		for squad in Array(packet.get("squads", [])):
			for role in Array(squad):
				var role_id := StringName(role)
				if role_id not in _maintenance_roster and _maintenance_roster.size() < 3:
					_maintenance_roster.append(role_id)
				if not _activated_packets.has(String(packet["id"])):
					_maintenance_roles.append(role_id)
	_packet_inflight = not _spawn_queue.is_empty()
	_timeline.append({
		"kind":&"quota_seal",
		"time":elapsed,
		"canceled_reserve":0,
		"admitted_units":_queued_spawn_count(),
	})


func stop_boss_maintenance() -> void:
	_boss_maintenance_active = false
	_maintenance_roles.clear()
	_maintenance_roster.clear()


func _append_maintenance_window_roles(request: Dictionary) -> void:
	var packet := Dictionary(request.get("packet", {}))
	var squads: Array = packet.get("squads", [])
	var squads_per_window := int(packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW))
	var first := int(request.get("arrival_window", 0)) * squads_per_window
	var end := mini(first + squads_per_window, squads.size())
	for squad_index in range(first, end):
		for role in Array(squads[squad_index]):
			_maintenance_roles.append(StringName(role))


func quota_sealed() -> bool:
	return _quota_sealed


func spawning_enabled() -> bool:
	return _spawning_enabled


func set_engagement_telemetry_enabled(enabled: bool) -> void:
	_engagement_telemetry_enabled = enabled
	if not enabled:
		_telemetry_births = 0
		_telemetry_gate_completions = 0
		_telemetry_expiries = 0
		_telemetry_cancellations = 0
		_telemetry_director_cpu_us = 0


func set_pressure_observation_enabled(enabled: bool) -> void:
	## Pressure sectors are diagnostic-only. Admission and attack decisions never use them.
	_pressure_observation_enabled = enabled
	if not enabled:
		_pressure_snapshot = _empty_pressure_snapshot()
		_pressure_scan_happened = false
		_diagnostic_gap_reason = &"none"
		_diagnostic_gap_started_at = -1.0


func pressure_observation_enabled() -> bool:
	return _pressure_observation_enabled


func pressure_scan_happened() -> bool:
	return _pressure_scan_happened


func pressure_visible_count() -> int:
	return int(_pressure_snapshot.get("visible", 0))


func consume_engagement_telemetry(output: Dictionary) -> void:
	## Diagnostic counters are consumed only by an explicitly active recorder/trace.
	output.clear()
	output["births"] = _telemetry_births
	output["gate_completions"] = _telemetry_gate_completions
	var director_debug := {}
	_engagement_director.fill_debug(director_debug)
	output["active_reservations"] = int(director_debug.get("live_count", 0))
	output["expiries"] = _telemetry_expiries
	output["cancellations"] = _telemetry_cancellations
	output["director_cpu_ms"] = float(_telemetry_director_cpu_us) / 1000.0
	_telemetry_births = 0
	_telemetry_gate_completions = 0
	_telemetry_expiries = 0
	_telemetry_cancellations = 0
	_telemetry_director_cpu_us = 0


func note_engagement_gate_completion() -> void:
	if _engagement_telemetry_enabled:
		_telemetry_gate_completions += 1


func note_engagement_expiry() -> void:
	if _engagement_telemetry_enabled:
		_telemetry_expiries += 1


func note_engagement_cancellation() -> void:
	if _engagement_telemetry_enabled:
		_telemetry_cancellations += 1


func note_engagement_director_cpu_usec(cpu_us: int) -> void:
	## Phase 2 calls this around the dedicated director only; Phase 0 remains zero.
	if _engagement_telemetry_enabled:
		_telemetry_director_cpu_us += maxi(0, cpu_us)


func signal_event(event_id: StringName) -> void:
	if event_id.is_empty():
		return
	_events[event_id] = elapsed
	_timeline.append({"kind":&"event", "id":event_id, "time":elapsed})


func has_event(event_id: StringName) -> bool:
	return _events.has(event_id)


func tick(
	delta: float,
	active_mobile_count: int,
	active_attack_families: Array[StringName] = [],
	player_position: Vector2 = Field.CENTER,
	visible_world: Rect2 = Rect2(),
	active_enemies: Array = [],
	hostile_projectile_count: int = 0,
	player_velocity: Vector2 = Vector2.ZERO,
	visible_ordinary_threat: bool = true,
	visible_ordinary_count: int = -1
) -> Dictionary:
	var step := maxf(0.0, delta)
	_pressure_scan_happened = false
	elapsed += step
	_prune_recent_births()
	_record_active_count_sample(active_mobile_count)
	if _pressure_observation_enabled:
		_pressure_scan_happened = true
		_pressure_snapshot = build_pressure_snapshot(
			active_mobile_count,
			active_enemies,
			player_position,
			visible_world,
			hostile_projectile_count
		)
	_max_attack_family_overlap = maxi(_max_attack_family_overlap, active_attack_families.size())
	var cues: Array[Dictionary] = []
	var spawns: Array[Dictionary] = []
	_process_due_round(active_mobile_count, step, spawns)
	if _spawning_enabled and not _quota_sealed:
		_complete_inflight_packet_if_ready()
		if _packet_inflight and _has_ready_unactivated_packet():
			_packet_fence_blocked_seconds += step
		if not _packet_inflight:
			_activate_next_ready_packet()
		_admit_due_window(
			active_mobile_count + spawns.size(),
			step,
			player_position,
			player_velocity,
			visible_world,
			cues,
			active_mobile_count if visible_ordinary_count < 0 else visible_ordinary_count
		)
		_complete_inflight_packet_if_ready()
	else:
		_complete_inflight_packet_if_ready()
		_admit_boss_maintenance(
			active_mobile_count, player_position, player_velocity,
			visible_world, cues, visible_ordinary_threat
		)
	if _pressure_observation_enabled:
		_update_diagnostic_gap_reason(active_mobile_count)
	return {"cues":cues, "spawns":spawns}


func active_cap() -> int:
	return materialized_active_cap()


func materialized_active_cap() -> int:
	return RunDifficulty.scaled_active_cap(Director.stage_materialized_active_cap(_stage_index), difficulty)


func refill_floor() -> int:
	## Refill is reserve-backed and never creates unauthored identities. The
	## scheduler keeps admitting ready windows below this stage pressure floor.
	return mini(
		materialized_active_cap(),
		RunDifficulty.scaled_active_cap(Director.stage_refill_floor(_stage_index), difficulty)
	)


func admission_gap_seconds(active_mobile_count: int, visible_ordinary_count: int = -1) -> float:
	var observed_visible := active_mobile_count if visible_ordinary_count < 0 else visible_ordinary_count
	return REFILL_WINDOW_GAP if observed_visible < refill_floor() else WINDOW_GAP


func authored_pressure_cap() -> int:
	return RunDifficulty.scaled_active_cap(Director.authored_pressure_cap_for(current_beat), difficulty)


func reserved_active_slots() -> int:
	return _reserved_arrival_slots


func available_active_slots(active_mobile_count: int) -> int:
	return maxi(0, active_cap() - maxi(0, active_mobile_count) - _reserved_arrival_slots)


func threat_budget() -> float:
	return Director.stage_threat_budget(_stage_index)


func ranged_commit_cap() -> int:
	return 2 if current_beat < 4 else Director.stage_ranged_commit_cap(_stage_index)


func denial_commit_cap() -> int:
	return 1 if current_beat < 4 else Director.stage_denial_commit_cap(_stage_index)


func record_player_damage(source_family: StringName = &"unknown") -> void:
	if _first_damage_time < 0.0:
		_first_damage_time = elapsed
	_damage_source_families[source_family] = int(_damage_source_families.get(source_family, 0)) + 1


func record_attack_preparation() -> void:
	## The ordinary attack owner calls this when startup commits its target and geometry.
	if _first_attack_preparation_time < 0.0:
		_first_attack_preparation_time = elapsed


func first_attack_preparation_time() -> float:
	return _first_attack_preparation_time


func record_reward() -> void:
	if _first_reward_time < 0.0:
		_first_reward_time = elapsed


func debug_snapshot() -> Dictionary:
	var engagement_debug := {}
	_engagement_director.fill_debug(engagement_debug)
	return {
		"stage_id":stage_id,
		"difficulty":difficulty,
		"elapsed":elapsed,
		"beat":current_beat,
		"active_cap":active_cap(),
		"materialized_cap":materialized_active_cap(),
		"materialized_active_cap":materialized_active_cap(),
		"authored_pressure_cap":authored_pressure_cap(),
		"authored_population":_authored_population,
		"materialized_spawned":_materialized_spawned,
		"virtual_reserve":_authored_reserve_count(),
		"quota_sealed":_quota_sealed,
		"quota_canceled_reserve":_quota_canceled_reserve,
		"boss_maintenance_active":_boss_maintenance_active,
		"boss_maintenance_reserve":_maintenance_roles.size(),
		"boss_maintenance_roster":_maintenance_roster.duplicate(),
		"last_boss_maintenance_cue_at":_last_boss_maintenance_cue_at,
		"materialized_active_count":int(_pressure_snapshot.get("active", 0)),
		"authored_reserve_units":_authored_reserve_count(),
		"threat_budget":threat_budget(),
		"queued_spawns":_queued_spawn_count(),
		"queued_windows":_window_queue.size(),
		"next_window_units":(
			_window_unit_count(_window_queue[0]) if not _window_queue.is_empty() else 0
		),
		"reserved_arrival_slots":_reserved_arrival_slots,
		"capacity_blocked_seconds":_capacity_blocked_seconds,
		"packet_fence_blocked_seconds":_packet_fence_blocked_seconds,
		"birth_capacity_blocked":_birth_capacity_blocked,
		"scheduler_starvation":_scheduler_starvation,
		"spawn_materialization_failures":_spawn_materialization_failures,
		"activated_packets":_activated_packets.keys(),
		"events":_events.duplicate(true),
		"first_cue_time":_first_cue_time,
		"first_spawn_time":_first_spawn_time,
		"first_attack_preparation_time":_first_attack_preparation_time,
		"first_damage_time":_first_damage_time,
		"first_reward_time":_first_reward_time,
		"active_count_p90":_active_count_percentile(0.90),
		"max_attack_family_overlap":_max_attack_family_overlap,
		"damage_source_families":_damage_source_families.duplicate(true),
		"spawned_by_squad":_spawned_by_squad.duplicate(true),
		"timeline":_timeline.duplicate(true),
		"schedule_delay":_capacity_blocked_seconds,
		"active_count_samples":_active_count_samples.size(),
		"spawning_enabled":_spawning_enabled,
		"allocations":_allocation_debug.duplicate(true),
		"pressure":_pressure_snapshot.duplicate(true),
		"engagement":engagement_debug,
		"scheduler_gap_reason":_diagnostic_gap_reason,
		"scheduler_gap_seconds":_diagnostic_gap_seconds(),
	}


func fill_performance_state(output: Dictionary) -> void:
	## Publishes only the bounded scheduler/pressure fields sampled by performance
	## replay. Unlike debug_snapshot(), this never duplicates authored timelines,
	## allocation histories, or event records inside a measured physics tick.
	output.clear()
	output["stage_id"] = stage_id
	output["difficulty"] = difficulty
	output["beat"] = current_beat
	output["active_cap"] = active_cap()
	output["materialized_cap"] = materialized_active_cap()
	output["authored_population"] = _authored_population
	output["materialized_spawned"] = _materialized_spawned
	output["virtual_reserve"] = _authored_reserve_count()
	output["spawning_enabled"] = _spawning_enabled
	output["queued_spawns"] = _queued_spawn_count()
	output["queued_windows"] = _window_queue.size()
	output["next_window_units"] = (
		_window_unit_count(_window_queue[0]) if not _window_queue.is_empty() else 0
	)
	output["reserved_arrival_slots"] = _reserved_arrival_slots
	output["pressure_active"] = int(_pressure_snapshot.get("active", 0))
	output["pressure_visible"] = int(_pressure_snapshot.get("visible", 0))
	output["pressure_near_900"] = int(_pressure_snapshot.get("near_900", 0))
	output["pressure_sector_histogram"] = PackedInt32Array(
		_pressure_snapshot.get("sector_histogram", PackedInt32Array())
	)
	output["pressure_ranged_commits"] = int(
		_pressure_snapshot.get("ranged_commits", 0)
	)
	output["pressure_denial_commits"] = int(
		_pressure_snapshot.get("denial_commits", 0)
	)


func fill_current_pressure(output: Dictionary) -> void:
	## Copies the already-computed pressure scalars into caller-owned diagnostic storage.
	## This must stay scan-free so observing a slow frame does not add another enemy pass.
	output.clear()
	var active := int(_pressure_snapshot.get("active", 0))
	var center_in_viewport := int(_pressure_snapshot.get("visible", 0))
	output["ordinary_active"] = active
	output["ordinary_authored_pressure_cap"] = authored_pressure_cap()
	output["ordinary_materialized_cap"] = materialized_active_cap()
	output["ordinary_refill_floor"] = refill_floor()
	output["ordinary_virtual_reserve"] = _authored_reserve_count()
	output["ordinary_quota_canceled_reserve"] = _quota_canceled_reserve
	output["ordinary_reserved_arrival_slots"] = _reserved_arrival_slots
	output["ordinary_materialized"] = active
	# Existing probes still use these names; the explicit fields above are the
	# release telemetry contract.
	output["ordinary_materialized_active"] = active
	output["ordinary_materialized_active_cap"] = materialized_active_cap()
	output["ordinary_authored_reserve"] = _authored_reserve_count()
	output["ordinary_active_cap"] = materialized_active_cap()
	output["ordinary_center_in_viewport"] = center_in_viewport
	output["ordinary_offscreen_active"] = maxi(0, active - center_in_viewport)
	output["ordinary_near_600"] = int(_pressure_snapshot.get("near_600", 0))
	output["ordinary_near_900"] = int(_pressure_snapshot.get("near_900", 0))
	output["ranged_commits"] = int(_pressure_snapshot.get("ranged_commits", 0))
	output["denial_commits"] = int(_pressure_snapshot.get("denial_commits", 0))


static func build_pressure_snapshot(
	active_mobile_count: int,
	active_enemies: Array,
	player_position: Vector2,
	visible_world: Rect2,
	hostile_projectile_count: int
) -> Dictionary:
	var visible := 0
	var near_600 := 0
	var near_900 := 0
	var ranged_commits := 0
	var denial_commits := 0
	var sectors := PackedInt32Array()
	sectors.resize(8)
	for enemy in active_enemies:
		if enemy == null or not bool(enemy.alive) or not bool(enemy.active):
			continue
		if not bool(enemy.counts_active_cap):
			continue
		var position := Vector2(enemy.pos)
		var offset := position - player_position
		var distance_squared := offset.length_squared()
		if visible_world.has_point(position):
			visible += 1
		if distance_squared <= 600.0 * 600.0:
			near_600 += 1
		if distance_squared <= 900.0 * 900.0:
			near_900 += 1
		sectors[_sector_for_offset(offset)] += 1
		if StringName(enemy.phase) in [&"startup", &"active"]:
			match StringName(enemy.threat_kind):
				&"ranged":
					ranged_commits += 1
				&"denial":
					denial_commits += 1
	return {
		"active":active_mobile_count,
		"visible":visible,
		"near_600":near_600,
		"near_900":near_900,
		"sector_histogram":sectors,
		"ranged_commits":ranged_commits,
		"denial_commits":denial_commits,
		"hostile_projectiles":maxi(0, hostile_projectile_count),
	}


static func _empty_pressure_snapshot() -> Dictionary:
	var sectors := PackedInt32Array()
	sectors.resize(8)
	return {
		"active":0,
		"visible":0,
		"near_600":0,
		"near_900":0,
		"sector_histogram":sectors,
		"ranged_commits":0,
		"denial_commits":0,
		"hostile_projectiles":0,
	}


static func _sector_for_offset(offset: Vector2) -> int:
	if offset.length_squared() <= 0.0001:
		return 0
	var raw := floori((offset.angle() + PI) / (TAU / 8.0))
	return (raw % 8 + 8) % 8


func _active_count_percentile(percentile: float) -> int:
	if _active_count_samples.is_empty():
		return 0
	var sorted := _active_count_samples.duplicate()
	sorted.sort()
	var index := clampi(int(ceil(percentile * float(sorted.size()))) - 1, 0, sorted.size() - 1)
	return sorted[index]


func _record_active_count_sample(active_mobile_count: int) -> void:
	if elapsed + 0.0001 < _next_metric_sample:
		return
	_active_count_samples.append(active_mobile_count)
	if _active_count_samples.size() > MAX_ACTIVE_COUNT_SAMPLES:
		_active_count_samples.pop_front()
	_next_metric_sample = elapsed + METRIC_SAMPLE_INTERVAL


func _activate_next_ready_packet() -> void:
	for packet in _packets:
		var packet_id := String(packet["id"])
		if _activated_packets.has(packet_id) or not _trigger_ready(packet["trigger"]):
			continue
		_activated_packets[packet_id] = elapsed
		current_beat = maxi(current_beat, int(packet["beat"]))
		_schedule_packet(packet)
		return


func _has_ready_unactivated_packet() -> bool:
	for packet in _packets:
		if not _activated_packets.has(String(packet["id"])) and _trigger_ready(packet["trigger"]):
			return true
	return false


func _trigger_ready(trigger: Dictionary) -> bool:
	match StringName(trigger.get("kind", &"event")):
		&"time":
			return elapsed >= float(trigger.get("at", INF))
		&"event":
			return _events.has(StringName(trigger.get("id", &"")))
	return false


func _schedule_packet(packet: Dictionary) -> void:
	var squads: Array = packet["squads"]
	var window_count := 1 if squads.size() <= 1 else int(packet.get("arrival_windows", SpawnAllocator.ARRIVAL_WINDOWS))
	var window_gap := float(packet.get("window_gap", WINDOW_GAP))
	_packet_inflight = true
	for arrival_window in window_count:
		_window_queue.append({
			"packet":packet,
			"arrival_window":arrival_window,
			"requested_cue_at":elapsed + float(arrival_window) * window_gap,
			"retry_at":elapsed + float(arrival_window) * window_gap,
		})


func _update_diagnostic_gap_reason(active_mobile_count: int) -> void:
	## Diagnostic only: this reports why the scheduler has no immediately
	## materialized pressure. It never changes admission, allocation, or combat.
	var next_reason: StringName = &"none"
	if not _spawn_queue.is_empty():
		next_reason = &"awaiting_birth"
	elif not _window_queue.is_empty():
		var request: Dictionary = _window_queue[0]
		if elapsed + 0.0001 < float(request.get("retry_at", elapsed)):
			next_reason = &"allocator_retry"
		elif available_active_slots(active_mobile_count) < _window_unit_count(request):
			next_reason = &"arrival_capacity"
		else:
			next_reason = &"awaiting_cue"
	elif _boss_maintenance_active:
		if _maintenance_roles.is_empty() and _maintenance_roster.is_empty():
			next_reason = &"authored_reserve_exhausted"
		elif active_mobile_count >= BOSS_MAINTENANCE_LOW_WATERMARK:
			next_reason = &"maintenance_low_watermark"
		elif elapsed + 0.0001 < _last_boss_maintenance_cue_at + BOSS_MAINTENANCE_INTERVAL:
			next_reason = &"maintenance_interval"
	elif _packet_inflight:
		next_reason = &"packet_fence"
	elif not _spawning_enabled:
		next_reason = &"spawning_stopped"
	elif _authored_reserve_count() <= 0:
		next_reason = &"authored_reserve_exhausted"
	else:
		next_reason = &"awaiting_packet_trigger"
	if next_reason == _diagnostic_gap_reason:
		return
	_diagnostic_gap_reason = next_reason
	_diagnostic_gap_started_at = elapsed if next_reason != &"none" else -1.0


func _diagnostic_gap_seconds() -> float:
	if _diagnostic_gap_started_at < 0.0:
		return 0.0
	return maxf(0.0, elapsed - _diagnostic_gap_started_at)


func _admit_boss_maintenance(
	active_mobile_count: int,
	player_position: Vector2,
	player_velocity: Vector2,
	visible_world: Rect2,
	cues: Array[Dictionary],
	visible_ordinary_threat: bool
) -> void:
	if not _boss_maintenance_active or not _spawn_queue.is_empty() or not _window_queue.is_empty():
		return
	if active_mobile_count >= BOSS_MAINTENANCE_HIGH_WATERMARK:
		return
	if _maintenance_roles.is_empty():
		_maintenance_roles.append_array(_maintenance_roster)
	if _maintenance_roles.is_empty():
		return
	if visible_ordinary_threat and active_mobile_count >= BOSS_MAINTENANCE_LOW_WATERMARK:
		return
	var interval := (
		BOSS_MAINTENANCE_INTERVAL
		if visible_ordinary_threat
		else BOSS_VISIBILITY_GAP_INTERVAL
	)
	if elapsed + 0.0001 < _last_boss_maintenance_cue_at + interval:
		return
	var count := mini(
		BOSS_MAINTENANCE_MAX_GROUP,
		mini(BOSS_MAINTENANCE_HIGH_WATERMARK - active_mobile_count, _maintenance_roles.size())
	)
	var roles: Array[StringName] = []
	for _index in count:
		roles.append(_maintenance_roles.pop_front())
	var packet := {
		"id":"%s_boss_maintenance_%03d" % [String(stage_id), floori(elapsed)],
		"_packet_index":_packets.size(), "beat":current_beat, "squads":[roles],
		"cue_lead":CUE_LEAD, "unit_spacing":0.16, "nearest_safe_offscreen":true,
		"zone":"field", "leash":Rect2(Field.WORLD_RECT),
	}
	_window_queue.append({"packet":packet, "arrival_window":0, "requested_cue_at":elapsed, "retry_at":elapsed})
	_packet_inflight = true
	_last_boss_maintenance_cue_at = elapsed
	_admit_due_window(active_mobile_count, 0.0, player_position, player_velocity, visible_world, cues)


func _admit_due_window(
	active_mobile_count: int,
	delta: float,
	player_position: Vector2,
	player_velocity: Vector2,
	visible_world: Rect2,
	cues: Array[Dictionary],
	visible_ordinary_count: int = -1
) -> void:
	if _window_queue.is_empty():
		return
	var request: Dictionary = _window_queue[0]
	if elapsed + 0.0001 < float(request["retry_at"]):
		return
	if not _spawn_queue.is_empty() and float(_spawn_queue[0]["nominal_due"]) <= elapsed + 0.0001:
		return
	var cue_gap := admission_gap_seconds(active_mobile_count, visible_ordinary_count)
	if elapsed + 0.0001 < _last_cue_at + cue_gap:
		return
	var packet: Dictionary = request["packet"]
	var requested_window_units := _window_unit_count(request)
	if available_active_slots(active_mobile_count) < requested_window_units:
		_capacity_blocked_seconds += delta
		return
	var recent_positions := _recent_birth_positions()
	var allocations := _spawn_allocator.allocate_window(
		packet,
		int(request["arrival_window"]),
		player_position,
		visible_world,
		[],
		recent_positions,
		player_velocity
	)
	if allocations.is_empty():
		_birth_capacity_blocked += 1
		request["retry_at"] = elapsed + RETRY_INTERVAL
		_window_queue[0] = request
		return
	var window_unit_count := 0
	for allocation in allocations:
		window_unit_count += Array(allocation["roles"]).size()
	if available_active_slots(active_mobile_count) < window_unit_count:
		_capacity_blocked_seconds += delta
		return
	_window_queue.pop_front()
	var cue_at := elapsed
	var cue_lead := float(packet.get("cue_lead", CUE_LEAD))
	var unit_spacing := float(packet.get("unit_spacing", 0.16))
	_last_cue_at = cue_at
	# A cue promises this entire window. Reserve every future birth now so no
	# later round waits for capacity after the player has seen that warning.
	_reserved_arrival_slots += window_unit_count
	var maximum_size := 0
	for allocation in allocations:
		maximum_size = maxi(maximum_size, Array(allocation["roles"]).size())
		var squad_index := int(request["arrival_window"]) * int(packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW)) + int(allocation["window_slot"])
		var squad_id := "%s_s%02d" % [String(packet["id"]), squad_index + 1]
		var pack := _pack_metadata(packet, squad_index, Array(allocation["roles"]))
		var cue := {
			"cue_id":"%s_w%02d_s%02d" % [String(packet["id"]), int(request["arrival_window"]) + 1, int(allocation["window_slot"]) + 1],
			"anchor":Vector2(allocation["unit_positions"][0]),
			"birth_position":Vector2(allocation["unit_positions"][0]),
			"squad_id":squad_id,
			"beat":int(packet["beat"]),
			"arrival_window":int(request["arrival_window"]),
			"window_slot":int(allocation["window_slot"]),
			"requested_cue_at":float(request["requested_cue_at"]),
			"cue_at":cue_at,
			"cue_lead":cue_lead,
			"visual_duration":cue_lead,
			"player_distance":float(allocation["player_distance"]),
			"outside_visible_margin":bool(allocation["outside_visible_margin"]),
			"birth_sector":int(allocation["birth_sector"]),
			"relaxation_tier":StringName(allocation["relaxation_tier"]),
			"roles":Array(allocation["roles"]).duplicate(),
			"pack_family":StringName(pack["family"]),
			"pack_tier":int(pack["tier"]),
			"pack_trait":StringName(pack["trait"]),
		}
		cues.append(cue)
		_allocation_debug.append(cue.duplicate(true))
		if _first_cue_time < 0.0:
			_first_cue_time = cue_at
		_timeline.append({"kind":&"cue", "id":cue["cue_id"], "time":cue_at, "requested":request["requested_cue_at"]})
	for unit_index in maximum_size:
		var specs: Array[Dictionary] = []
		for allocation in allocations:
			var roles: Array = allocation["roles"]
			var protected_emitter_index := -1
			for role_index in roles.size():
				var role_definition := EnemyArchetypes.definition(StringName(roles[role_index]))
				if StringName(role_definition.get("family", &"")) == &"emitter":
					protected_emitter_index = role_index
					break
			if unit_index >= roles.size():
				continue
			var squad_index := int(request["arrival_window"]) * int(packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW)) + int(allocation["window_slot"])
			var squad_id := "%s_s%02d" % [String(packet["id"]), squad_index + 1]
			var pack := _pack_metadata(packet, squad_index, roles)
			var collective_tactic := Dictionary(packet.get("collective_tactic", {}))
			var spec := {
				"id":"%s_u%02d" % [squad_id, unit_index + 1],
				"role":StringName(roles[unit_index]),
				"pos":Vector2(allocation["unit_positions"][unit_index]),
				"birth_position":Vector2(allocation["unit_positions"][unit_index]),
				"birth_clearance":float(allocation["unit_clearances"][unit_index]),
				"birth_sector":int(allocation["unit_sectors"][unit_index]),
				"arrival_window":int(request["arrival_window"]),
				"window_slot":int(allocation["window_slot"]),
				"unit_index":unit_index,
				"zone":String(packet.get("zone", "")),
				"group_id":squad_id,
				"squad_id":squad_id,
				"squad_leader":unit_index == 0,
				"formation_slot":unit_index,
				"formation_size":roles.size(),
				"escort_target_id":(
					"%s_u%02d" % [squad_id, protected_emitter_index + 1]
					if protected_emitter_index >= 0
					and StringName(EnemyArchetypes.definition(StringName(roles[unit_index])).get("family", &"")) == &"defender"
					else ""
				),
				"pack_family":StringName(pack["family"]),
				"pack_tier":int(pack["tier"]),
				"pack_trait":StringName(pack["trait"]),
				"leash_rect":Rect2(packet["leash"]),
				"active":true,
				"packet_beat":int(packet["beat"]),
				"collective_tactic_id":StringName(pack["tactic_id"]),
				"collective_beat_kind":StringName(collective_tactic.get("beat_kind", &"teach")),
			}
			_attach_engagement_reservation(
				spec, packet, int(request["arrival_window"]), player_position, player_velocity,
				cue_at + cue_lead + float(unit_index) * unit_spacing
			)
			specs.append(spec)
		_spawn_queue.append({
			"nominal_due":cue_at + cue_lead + float(unit_index) * unit_spacing,
			"packet_index":int(packet["_packet_index"]),
			"arrival_window":int(request["arrival_window"]),
			"unit_index":unit_index,
			"reserved":true,
			"specs":specs,
		})
	_spawn_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _round_sort_key(a) < _round_sort_key(b)
	)


func _pack_metadata(packet: Dictionary, squad_index: int, roles: Array) -> Dictionary:
	var packs: Array = packet.get("packs", [])
	if squad_index >= 0 and squad_index < packs.size():
		return Dictionary(packs[squad_index])
	var first_role := StringName(roles[0]) if not roles.is_empty() else &"ordinary_pursuer_t1"
	var definition := EnemyArchetypes.definition(first_role)
	var family := StringName(definition.get("family", &"pursuer"))
	return {
		"family":family,
		"tier":int(definition.get("tier", 1)),
		"trait":&"",
		"tactic_id":FamilyTraits.tactic_for_family(family),
		"roles":roles.duplicate(),
	}


func _attach_engagement_reservation(
	spec: Dictionary,
	packet: Dictionary,
	arrival_window: int,
	player_position: Vector2,
	player_velocity: Vector2,
	birth_time: float
) -> void:
	var patterns: Array = packet.get("engagement_patterns", [])
	if patterns.is_empty() or arrival_window < 0 or arrival_window >= patterns.size():
		return
	if StringName(patterns[arrival_window]) == &"none":
		return
	var archetype := StringName(spec["role"])
	var definition := EnemyArchetypes.definition(archetype)
	var role := StringName(definition["behavior"])
	var family := MovementPolicy.family(archetype, role)
	if family in [MovementPolicy.STATIONARY, MovementPolicy.PURSUIT]:
		# Pursuers own direct pressure on the player. They do not reserve a
		# formation gate that could make a melee unit peel away to a position.
		return
	var speed := SpeedProfile.effective_speed(archetype, _stage_index, difficulty)
	if speed <= 0.001:
		return
	var birth := Vector2(spec["birth_position"])
	var anchor := TargetingPolicy.movement_focus(family, birth, player_position, player_velocity, speed)
	var radius := EngagementDirector.gate_radius(family, MovementPolicy.distance_band(role))
	if radius <= 0.001:
		return
	var heading := _sector_for_offset(player_velocity) if player_velocity.length() >= TargetingPolicy.MIN_TARGET_SPEED else posmod(hash("%s:%d" % [String(packet["id"]), arrival_window]), EngagementDirector.SECTOR_COUNT)
	var sectors := EngagementDirector.pattern_sectors(StringName(patterns[arrival_window]), heading, int(spec["unit_index"]))
	var gates := {}
	var expected := {}
	var validity := {}
	for sector in sectors:
		var angle := (float(sector) + 0.5) * TAU / float(EngagementDirector.SECTOR_COUNT) - PI
		var gate := anchor + Vector2.from_angle(angle) * radius
		gates[sector] = gate
		expected[sector] = birth_time + birth.distance_to(gate) / speed
		validity[sector] = _geometry_snapshot == null or bool(_geometry_snapshot.is_spawnable_disc(gate, float(definition["radius"])))
	var start := Time.get_ticks_usec() if _engagement_telemetry_enabled else 0
	var handle := _engagement_director.reserve({
		"id":spec["id"], "ordinal":int(spec["unit_index"]), "eligible_sectors":sectors,
		"heading_sector":heading, "candidate_expected_times":expected,
		"gate_valid_by_sector":validity, "gate_by_sector":gates, "anchor":anchor, "birth_time":birth_time,
	})
	if _engagement_telemetry_enabled:
		note_engagement_director_cpu_usec(Time.get_ticks_usec() - start)
	if handle.is_empty() or bool(handle.get("no_gate", false)):
		return
	var reservation := _engagement_director.reservation(handle)
	if (
		reservation.is_empty()
		or not reservation.has("gate")
		or not reservation.has("expected_time")
		or not reservation.has("expiry_time")
		or not reservation.has("sector")
	):
		cancel_engagement(handle)
		return
	spec["engagement_handle"] = handle
	spec["engagement_gate"] = Vector2(reservation["gate"])
	spec["engagement_expected_time"] = float(reservation["expected_time"])
	spec["engagement_expiry"] = float(reservation["expiry_time"])
	spec["engagement_sector"] = int(reservation["sector"])
	spec["engagement_started_at"] = birth_time


func confirm_engagement(handle: Dictionary) -> bool:
	return _engagement_director.confirm(handle)


func complete_engagement(handle: Dictionary) -> bool:
	var released := _engagement_director.complete(handle)
	if released:
		note_engagement_gate_completion()
	return released


func expire_engagement(handle: Dictionary, now: float) -> bool:
	var released := _engagement_director.expire(handle, now)
	if released:
		note_engagement_expiry()
	return released


func release_engagement(handle: Dictionary) -> bool:
	var released := _engagement_director.release(handle)
	return released


func cancel_engagement(handle: Dictionary) -> bool:
	var cancelled := _engagement_director.cancel(handle)
	if cancelled:
		note_engagement_cancellation()
	return cancelled


func _cancel_queued_engagements() -> void:
	for round in _spawn_queue:
		for spec in Array(round.get("specs", [])):
			var handle: Dictionary = Dictionary(spec).get("engagement_handle", {})
			if not handle.is_empty():
				cancel_engagement(handle)


func _process_due_round(active_mobile_count: int, delta: float, spawns: Array[Dictionary]) -> void:
	if _spawn_queue.is_empty():
		return
	var round: Dictionary = _spawn_queue[0]
	if float(round["nominal_due"]) > elapsed + 0.0001:
		return
	var specs: Array = round["specs"]
	if specs.size() > MAX_SPAWNS_PER_TICK:
		_scheduler_starvation += 1
		return
	_spawn_queue.pop_front()
	if bool(round["reserved"]):
		_reserved_arrival_slots = maxi(0, _reserved_arrival_slots - specs.size())
	for spec_variant in specs:
		var spec := Dictionary(spec_variant)
		spawns.append(spec)
		_virtual_reserve_units = maxi(0, _virtual_reserve_units - 1)
		_materialized_spawned += 1
		var squad_id := String(spec["squad_id"])
		_spawned_by_squad[squad_id] = int(_spawned_by_squad.get(squad_id, 0)) + 1
		_recent_births.append({"id":String(spec["id"]), "time":elapsed, "position":Vector2(spec["pos"])})
		if _first_spawn_time < 0.0:
			_first_spawn_time = elapsed
		_timeline.append({
			"kind":&"spawn",
			"id":spec["id"],
			"squad_id":squad_id,
			"time":elapsed,
			"nominal_due":round["nominal_due"],
		})
		if _engagement_telemetry_enabled:
			_telemetry_births += 1


func note_spawn_materialization_failed(spec: Dictionary) -> void:
	## The scheduler emits a birth before the external enemy store admits it.
	## Roll back that optimistic record if the bounded store rejects the actor.
	_spawn_materialization_failures += 1
	_materialized_spawned = maxi(0, _materialized_spawned - 1)
	var handle: Dictionary = spec.get("engagement_handle", {})
	if not handle.is_empty():
		cancel_engagement(handle)
	var id := String(spec.get("id", ""))
	var squad_id := String(spec.get("squad_id", ""))
	var squad_count := int(_spawned_by_squad.get(squad_id, 0))
	if squad_count <= 1:
		_spawned_by_squad.erase(squad_id)
	else:
		_spawned_by_squad[squad_id] = squad_count - 1
	for index in range(_recent_births.size() - 1, -1, -1):
		if String(_recent_births[index].get("id", "")) == id:
			_recent_births.remove_at(index)
			break
	for index in range(_timeline.size() - 1, -1, -1):
		var entry: Dictionary = _timeline[index]
		if StringName(entry.get("kind", &"")) == &"spawn" and String(entry.get("id", "")) == id:
			_timeline.remove_at(index)
			break
	_timeline.append({
		"kind":&"spawn_materialization_failed",
		"id":id,
		"squad_id":squad_id,
		"time":elapsed,
	})
	_first_spawn_time = -1.0
	for entry in _timeline:
		if StringName(entry.get("kind", &"")) == &"spawn":
			_first_spawn_time = float(entry.get("time", -1.0))
			break
	if _engagement_telemetry_enabled:
		_telemetry_births = maxi(0, _telemetry_births - 1)


func _complete_inflight_packet_if_ready() -> void:
	if not _packet_inflight or not _window_queue.is_empty() or not _spawn_queue.is_empty():
		return
	_packet_inflight = false


func _prune_recent_births() -> void:
	while not _recent_births.is_empty() and elapsed - float(_recent_births[0]["time"]) > RECENT_BIRTH_SECONDS:
		_recent_births.pop_front()


func _recent_birth_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for birth in _recent_births:
		result.append(Vector2(birth["position"]))
	return result


func _queued_spawn_count() -> int:
	var result := 0
	for round in _spawn_queue:
		result += Array(round["specs"]).size()
	return result


func _authored_reserve_count() -> int:
	## Event-owned count: reserve units have no world or combat state.
	return _virtual_reserve_units


static func _packet_unit_count(packet: Dictionary) -> int:
	var total := 0
	for squad in Array(packet.get("squads", [])):
		total += Array(squad).size()
	return total


static func _window_unit_count(request: Dictionary) -> int:
	var packet: Dictionary = request.get("packet", {})
	var squads: Array = packet.get("squads", [])
	var squads_per_window := int(packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW))
	var first_squad := int(request.get("arrival_window", 0)) * squads_per_window
	var end_squad := mini(squads.size(), first_squad + squads_per_window)
	var total := 0
	for squad_index in range(first_squad, end_squad):
		total += Array(squads[squad_index]).size()
	return total


func _round_sort_key(round: Dictionary) -> String:
	return "%020.6f:%06d:%03d:%03d" % [
		float(round["nominal_due"]),
		int(round["packet_index"]),
		int(round["arrival_window"]),
		int(round["unit_index"]),
	]
