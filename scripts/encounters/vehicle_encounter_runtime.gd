class_name VehicleEncounterRuntime
extends RefCounted

## Deterministic authored-packet scheduler. Timing windows own cue/admission;
## the allocator owns unit birth positions and combat actors remain external.

const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const SpawnAllocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const EngagementDirector = preload("res://scripts/encounters/vehicle_engagement_director.gd")
const MovementPolicy = preload("res://scripts/enemies/vehicle_enemy_movement_policy.gd")
const TargetingPolicy = preload("res://scripts/enemies/vehicle_enemy_targeting_policy.gd")
const SpeedProfile = preload("res://scripts/enemies/vehicle_enemy_speed_profile.gd")
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const Field = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")

const CUE_LEAD := 0.9
const WINDOW_GAP := 1.20
const RETRY_INTERVAL := 0.25
const RECENT_BIRTH_SECONDS := 2.0
const METRIC_SAMPLE_INTERVAL := 0.10
const MAX_ACTIVE_COUNT_SAMPLES := 4096
const MAX_SPAWNS_PER_TICK := 4

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
var _first_damage_time := -1.0
var _first_reward_time := -1.0
var _active_count_samples: Array[int] = []
var _max_attack_family_overlap := 0
var _damage_source_families: Dictionary = {}
var _capacity_blocked_seconds := 0.0
var _packet_fence_blocked_seconds := 0.0
var _birth_capacity_blocked := 0
var _scheduler_starvation := 0
var _next_metric_sample := 0.0
var _spawning_enabled := true
var _spawn_allocator := SpawnAllocator.new()
var _engagement_director := EngagementDirector.new()
var _geometry_snapshot: Variant
var _stage_index := 0
var _allocation_debug: Array[Dictionary] = []
var _pressure_snapshot := {}
var _engagement_telemetry_enabled := false
var _telemetry_births := 0
var _telemetry_gate_completions := 0
var _telemetry_expiries := 0
var _telemetry_cancellations := 0
var _telemetry_director_cpu_us := 0


func configure(
	next_stage_id: StringName,
	packets: Array[Dictionary],
	_run_difficulty: StringName,
	spawn_anchors: Array[Vector2] = Field.ORDINARY_SPAWN_CANDIDATES,
	encounter_seed: int = 0,
	geometry_snapshot: Variant = null,
	stage_index: int = 0
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
		_packets.append(packet)
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
	_first_damage_time = -1.0
	_first_reward_time = -1.0
	_active_count_samples.clear()
	_max_attack_family_overlap = 0
	_damage_source_families.clear()
	_capacity_blocked_seconds = 0.0
	_packet_fence_blocked_seconds = 0.0
	_birth_capacity_blocked = 0
	_scheduler_starvation = 0
	_next_metric_sample = 0.0
	_spawning_enabled = true
	_allocation_debug.clear()
	_pressure_snapshot = _empty_pressure_snapshot()
	_geometry_snapshot = geometry_snapshot
	_stage_index = maxi(0, stage_index)
	_telemetry_births = 0
	_telemetry_gate_completions = 0
	_telemetry_expiries = 0
	_telemetry_cancellations = 0
	_telemetry_director_cpu_us = 0
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
	_packet_inflight = false


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
	player_velocity: Vector2 = Vector2.ZERO
) -> Dictionary:
	var step := maxf(0.0, delta)
	elapsed += step
	_prune_recent_births()
	_record_active_count_sample(active_mobile_count)
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
	if _spawning_enabled:
		_process_due_round(active_mobile_count, step, spawns)
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
			cues
		)
		_complete_inflight_packet_if_ready()
	return {"cues":cues, "spawns":spawns}


func active_cap() -> int:
	return RunDifficulty.scaled_active_cap(Director.active_cap_for(current_beat), difficulty)


func reserved_active_slots() -> int:
	return _reserved_arrival_slots


func available_active_slots(active_mobile_count: int) -> int:
	return maxi(0, active_cap() - maxi(0, active_mobile_count) - _reserved_arrival_slots)


func threat_budget() -> float:
	return Director.threat_budget_for(current_beat)


func ranged_commit_cap() -> int:
	return 2 if current_beat < 4 else Director.MAX_RANGED_COMMITS


func denial_commit_cap() -> int:
	return 1 if current_beat < 4 else Director.MAX_DENIAL_COMMITS


func record_player_damage(source_family: StringName = &"unknown") -> void:
	if _first_damage_time < 0.0:
		_first_damage_time = elapsed
	_damage_source_families[source_family] = int(_damage_source_families.get(source_family, 0)) + 1


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
		"threat_budget":threat_budget(),
		"queued_spawns":_queued_spawn_count(),
		"queued_windows":_window_queue.size(),
		"reserved_arrival_slots":_reserved_arrival_slots,
		"capacity_blocked_seconds":_capacity_blocked_seconds,
		"packet_fence_blocked_seconds":_packet_fence_blocked_seconds,
		"birth_capacity_blocked":_birth_capacity_blocked,
		"scheduler_starvation":_scheduler_starvation,
		"activated_packets":_activated_packets.keys(),
		"events":_events.duplicate(true),
		"first_cue_time":_first_cue_time,
		"first_spawn_time":_first_spawn_time,
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
	}


func fill_current_pressure(output: Dictionary) -> void:
	## Copies the already-computed pressure scalars into caller-owned diagnostic storage.
	## This must stay scan-free so observing a slow frame does not add another enemy pass.
	output.clear()
	var active := int(_pressure_snapshot.get("active", 0))
	var center_in_viewport := int(_pressure_snapshot.get("visible", 0))
	output["ordinary_active"] = active
	output["ordinary_active_cap"] = active_cap()
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


func _admit_due_window(
	active_mobile_count: int,
	delta: float,
	player_position: Vector2,
	player_velocity: Vector2,
	visible_world: Rect2,
	cues: Array[Dictionary]
) -> void:
	if _window_queue.is_empty():
		return
	var request: Dictionary = _window_queue[0]
	if elapsed + 0.0001 < float(request["retry_at"]):
		return
	if not _spawn_queue.is_empty() and float(_spawn_queue[0]["nominal_due"]) <= elapsed + 0.0001:
		return
	if elapsed + 0.0001 < _last_cue_at + WINDOW_GAP:
		return
	var packet: Dictionary = request["packet"]
	var squads: Array = packet["squads"]
	var squads_per_window := int(
		packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW)
	)
	var first_squad := int(request["arrival_window"]) * squads_per_window
	var first_round_size := mini(squads.size(), first_squad + squads_per_window) - first_squad
	if available_active_slots(active_mobile_count) < first_round_size:
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
	first_round_size = allocations.size()
	_window_queue.pop_front()
	var cue_at := elapsed
	var cue_lead := float(packet.get("cue_lead", CUE_LEAD))
	var unit_spacing := float(packet.get("unit_spacing", 0.16))
	_last_cue_at = cue_at
	_reserved_arrival_slots += first_round_size
	var maximum_size := 0
	for allocation in allocations:
		maximum_size = maxi(maximum_size, Array(allocation["roles"]).size())
		var squad_index := int(request["arrival_window"]) * int(packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW)) + int(allocation["window_slot"])
		var squad_id := "%s_s%02d" % [String(packet["id"]), squad_index + 1]
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
			if unit_index >= roles.size():
				continue
			var squad_index := int(request["arrival_window"]) * int(packet.get("squads_per_window", SpawnAllocator.SQUADS_PER_WINDOW)) + int(allocation["window_slot"])
			var squad_id := "%s_s%02d" % [String(packet["id"]), squad_index + 1]
			var collective_tactic := Dictionary(packet.get("collective_tactic", {}))
			var tactic_squad_index := int(collective_tactic.get("squad_index", -1))
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
				"leash_rect":Rect2(packet["leash"]),
				"active":true,
				"packet_beat":int(packet["beat"]),
				"collective_tactic_id":StringName(collective_tactic.get("id", &"")) if squad_index == tactic_squad_index else &"",
				"collective_beat_kind":StringName(collective_tactic.get("beat_kind", &"")) if squad_index == tactic_squad_index else &"",
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
			"reserved":unit_index == 0,
			"specs":specs,
		})
	_spawn_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _round_sort_key(a) < _round_sort_key(b)
	)


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
	if family == MovementPolicy.STATIONARY:
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
	if bool(handle.get("no_gate", false)):
		return
	var reservation := _engagement_director.reservation(handle)
	spec["engagement_handle"] = handle
	spec["engagement_gate"] = Vector2(reservation["gate"])
	spec["engagement_expected_time"] = float(reservation["expected_time"])
	spec["engagement_expiry"] = float(reservation["expiry_time"])
	spec["engagement_sector"] = int(reservation["sector"])


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
	if not bool(round["reserved"]) and available_active_slots(active_mobile_count) < specs.size():
		_capacity_blocked_seconds += delta
		return
	_spawn_queue.pop_front()
	if bool(round["reserved"]):
		_reserved_arrival_slots = maxi(0, _reserved_arrival_slots - specs.size())
	for spec_variant in specs:
		var spec := Dictionary(spec_variant)
		spawns.append(spec)
		var squad_id := String(spec["squad_id"])
		_spawned_by_squad[squad_id] = int(_spawned_by_squad.get(squad_id, 0)) + 1
		_recent_births.append({"time":elapsed, "position":Vector2(spec["pos"])})
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


func _round_sort_key(round: Dictionary) -> String:
	return "%020.6f:%06d:%03d:%03d" % [
		float(round["nominal_due"]),
		int(round["packet_index"]),
		int(round["arrival_window"]),
		int(round["unit_index"]),
	]
