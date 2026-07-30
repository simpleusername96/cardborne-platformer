class_name VehicleEncounterRuntime
extends RefCounted

## Deterministic authored-packet scheduler. It owns grace, cue timing, queue
## order, beat caps, and metrics, but never draws or mutates combat actors.

const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const SpawnAllocator = preload("res://scripts/encounters/vehicle_spawn_allocator.gd")
const Field = preload("res://scripts/vehicle/stages/drowned_ruin_field.gd")

const ARRIVAL_GRACE := 6.0
const CUE_LEAD := 0.9
const METRIC_SAMPLE_INTERVAL := 0.10
const MAX_ACTIVE_COUNT_SAMPLES := 4096
const MAX_SPAWNS_PER_TICK := 4
const PACK_SPAWN_FAN_RADIUS := 38.0
# Non-commensurate with squad rings, so pack members do not stack at one point.
const PACK_SQUAD_PHASE_STEP := PI * 11.0 / 180.0

var stage_id: StringName = &"stage_1"
var difficulty: StringName = RunDifficulty.DEFAULT
var elapsed := 0.0
var current_beat := 0

var _packets: Array[Dictionary] = []
var _activated_packets: Dictionary = {}
var _events: Dictionary = {}
var _cue_queue: Array[Dictionary] = []
var _spawn_queue: Array[Dictionary] = []
var _timeline: Array[Dictionary] = []
var _spawned_by_squad: Dictionary = {}
var _first_cue_time := -1.0
var _first_spawn_time := -1.0
var _first_damage_time := -1.0
var _first_reward_time := -1.0
var _active_count_samples: Array[int] = []
var _max_attack_family_overlap := 0
var _damage_source_families: Dictionary = {}
var _schedule_delay_total := 0.0
var _next_metric_sample := 0.0
var _spawning_enabled := true
var _spawn_allocator := SpawnAllocator.new()
var _allocation_debug: Array[Dictionary] = []
var _pressure_snapshot := {}


func configure(
	next_stage_id: StringName,
	packets: Array[Dictionary],
	run_difficulty: StringName,
	spawn_anchors: Array[Vector2] = Field.ORDINARY_SPAWN_CANDIDATES,
	encounter_seed: int = 0
) -> void:
	stage_id = next_stage_id
	difficulty = RunDifficulty.normalize(run_difficulty)
	elapsed = 0.0
	current_beat = 0
	_packets.clear()
	for packet in packets:
		_packets.append(packet.duplicate(true))
	_activated_packets.clear()
	_events.clear()
	_cue_queue.clear()
	_spawn_queue.clear()
	_timeline.clear()
	_spawned_by_squad.clear()
	_first_cue_time = -1.0
	_first_spawn_time = -1.0
	_first_damage_time = -1.0
	_first_reward_time = -1.0
	_active_count_samples.clear()
	_max_attack_family_overlap = 0
	_damage_source_families.clear()
	_schedule_delay_total = 0.0
	_next_metric_sample = 0.0
	_spawning_enabled = true
	_allocation_debug.clear()
	_pressure_snapshot = _empty_pressure_snapshot()
	_spawn_allocator.configure(encounter_seed, spawn_anchors)


func stop_spawning() -> void:
	_spawning_enabled = false
	_cue_queue.clear()
	_spawn_queue.clear()


func spawning_enabled() -> bool:
	return _spawning_enabled


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
	hostile_projectile_count: int = 0
) -> Dictionary:
	elapsed += maxf(0.0, delta)
	_record_active_count_sample(active_mobile_count)
	_pressure_snapshot = build_pressure_snapshot(
		active_mobile_count,
		active_enemies,
		player_position,
		visible_world,
		hostile_projectile_count
	)
	_max_attack_family_overlap = maxi(_max_attack_family_overlap, active_attack_families.size())
	if _spawning_enabled:
		_activate_ready_packets(player_position, visible_world)
	var cues: Array[Dictionary] = []
	while not _cue_queue.is_empty() and _effective_time(_cue_queue[0]) <= elapsed + 0.0001:
		var cue: Dictionary = _cue_queue.pop_front()
		cues.append(cue)
		var cue_time := _effective_time(cue)
		if _first_cue_time < 0.0:
			_first_cue_time = cue_time
		_timeline.append({
			"kind":&"cue",
			"id":cue.get("cue_id", cue["squad_id"]),
			"time":cue_time,
		})

	var spawns: Array[Dictionary] = []
	var spawn_budget := mini(MAX_SPAWNS_PER_TICK, maxi(0, active_cap() - active_mobile_count))
	while (
		_spawning_enabled
		and spawn_budget > 0
		and not _spawn_queue.is_empty()
		and _effective_time(_spawn_queue[0]) <= elapsed + 0.0001
	):
			var request: Dictionary = _spawn_queue.pop_front()
			spawns.append(request["spec"])
			spawn_budget -= 1
			var squad_id := String(request["spec"]["squad_id"])
			_spawned_by_squad[squad_id] = int(_spawned_by_squad.get(squad_id, 0)) + 1
			var spawn_time := _effective_time(request)
			if _first_spawn_time < 0.0:
				_first_spawn_time = spawn_time
			_timeline.append({"kind":&"spawn", "id":request["spec"]["id"], "squad_id":squad_id, "time":spawn_time})
	if (
		_spawning_enabled
		and spawn_budget == 0
		and not _spawn_queue.is_empty()
		and _effective_time(_spawn_queue[0]) <= elapsed + 0.0001
	):
		_schedule_delay_total += maxf(0.0, delta)
	return {"cues":cues, "spawns":spawns}


func active_cap() -> int:
	return RunDifficulty.scaled_active_cap(Director.active_cap_for(current_beat), difficulty)


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
	return {
		"stage_id":stage_id,
		"difficulty":difficulty,
		"elapsed":elapsed,
		"beat":current_beat,
		"active_cap":active_cap(),
		"threat_budget":threat_budget(),
		"queued_spawns":_spawn_queue.size(),
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
		"schedule_delay":_schedule_delay_total,
		"active_count_samples":_active_count_samples.size(),
		"spawning_enabled":_spawning_enabled,
		"allocations":_allocation_debug.duplicate(true),
		"pressure":_pressure_snapshot.duplicate(true),
	}


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
		"active": active_mobile_count,
		"visible": visible,
		"near_600": near_600,
		"near_900": near_900,
		"sector_histogram": sectors,
		"ranged_commits": ranged_commits,
		"denial_commits": denial_commits,
		"hostile_projectiles": maxi(0, hostile_projectile_count),
	}


static func _empty_pressure_snapshot() -> Dictionary:
	var sectors := PackedInt32Array()
	sectors.resize(8)
	return {
		"active": 0,
		"visible": 0,
		"near_600": 0,
		"near_900": 0,
		"sector_histogram": sectors,
		"ranged_commits": 0,
		"denial_commits": 0,
		"hostile_projectiles": 0,
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


func _effective_time(entry: Dictionary) -> float:
	return float(entry["time"]) + _schedule_delay_total - float(entry.get("delay_base", 0.0))


func _scheduled_key(entry: Dictionary) -> float:
	return float(entry["time"]) - float(entry.get("delay_base", 0.0))


func _activate_ready_packets(player_position: Vector2, visible_world: Rect2) -> void:
	for packet in _packets:
		var packet_id := String(packet["id"])
		if _activated_packets.has(packet_id) or not _trigger_ready(packet["trigger"]):
			continue
		_activated_packets[packet_id] = elapsed
		current_beat = maxi(current_beat, int(packet["beat"]))
		_schedule_packet(packet, player_position, visible_world)


func _trigger_ready(trigger: Dictionary) -> bool:
	match StringName(trigger.get("kind", &"event")):
		&"time":
			return elapsed >= float(trigger.get("at", INF))
		&"event":
			return _events.has(StringName(trigger.get("id", &"")))
	return false


func _schedule_packet(packet: Dictionary, player_position: Vector2, visible_world: Rect2) -> void:
	var packet_id := String(packet["id"])
	var beat := int(packet["beat"])
	var squads: Array = packet["squads"]
	var allocations := _spawn_allocator.allocate(packet, player_position, visible_world)
	var arrival_mode := StringName(packet.get("arrival_mode", SpawnAllocator.ARRIVAL_DISTRIBUTED))
	var unit_spacing := float(packet.get("unit_spacing", 0.16))
	var gap := float(packet.get(
		"pack_gap",
		0.90 if beat <= 1 else 0.65
	))
	var cue_lead := float(packet.get("cue_lead", CUE_LEAD))
	var collective_tactic := Dictionary(packet.get("collective_tactic", {}))
	var tactic_squad_index := int(
		collective_tactic.get("squad_index", -1)
	)
	var queued_cue_groups := {}
	for squad_index in squads.size():
		var allocation: Dictionary = allocations[squad_index]
		var squad: Array = allocation["roles"]
		var anchor := Vector2(allocation["anchor"])
		var squad_id := "%s_s%02d" % [packet_id, squad_index + 1]
		var group_index := int(allocation["group_index"])
		var cursor := elapsed + cue_lead + float(group_index) * gap
		var cue := {
			"time":cursor - cue_lead,
			"delay_base":_schedule_delay_total,
			"anchor":anchor,
			"squad_id":squad_id,
			"beat":beat,
			"player_distance":allocation["player_distance"],
			"outside_visible_margin":allocation["outside_visible_margin"],
			"sector":allocation["sector"],
			"group_index":group_index,
			"arrival_mode":arrival_mode,
			"roles":squad.duplicate(),
		}
		_allocation_debug.append(cue.duplicate(true))
		if arrival_mode == SpawnAllocator.ARRIVAL_MULTI_SECTOR:
			if not queued_cue_groups.has(group_index):
				queued_cue_groups[group_index] = true
				cue["cue_id"] = "%s_p%02d" % [packet_id, group_index + 1]
				cue["pack_index"] = group_index
				cue["roles"] = _roles_for_group(allocations, group_index)
				_cue_queue.append(cue)
		else:
			_cue_queue.append(cue)
		for unit_index in squad.size():
			var role := StringName(squad[unit_index])
			var formation_phase := 0.0
			if arrival_mode == SpawnAllocator.ARRIVAL_MULTI_SECTOR:
				var pack_squad_index := squad_index % SpawnAllocator.SQUADS_PER_PACK
				formation_phase = float(pack_squad_index) * PACK_SQUAD_PHASE_STEP
			var formation_angle := (
				formation_phase
				+ TAU * float(unit_index) / float(maxi(1, squad.size()))
			)
			var formation_offset := Vector2.RIGHT.rotated(formation_angle) * (58.0 if squad.size() > 1 else 0.0)
			var spawn_offset := (
				Vector2.RIGHT.rotated(formation_angle) * PACK_SPAWN_FAN_RADIUS
				if arrival_mode == SpawnAllocator.ARRIVAL_MULTI_SECTOR
				else Vector2.ZERO
			)
			var spec := {
				"id":"%s_u%02d" % [squad_id, unit_index + 1],
				"role":role,
				"pos":anchor + spawn_offset,
				"zone":String(packet.get("zone", "")),
				"group_id":squad_id,
				"squad_id":squad_id,
				"squad_leader":unit_index == 0,
				"formation_slot":unit_index,
				"formation_size":squad.size(),
				"formation_anchor":anchor,
				"formation_offset":formation_offset,
				"target_sector":Vector2.RIGHT.rotated(float((packet_id + squad_id).hash() % 16) / 16.0 * TAU),
				"leash_rect":Rect2(packet["leash"]),
				"active":true,
				"packet_beat":beat,
				"collective_tactic_id":(
					StringName(collective_tactic.get("id", &""))
					if squad_index == tactic_squad_index
					else &""
				),
				"collective_beat_kind":(
					StringName(collective_tactic.get("beat_kind", &""))
					if squad_index == tactic_squad_index
					else &""
				),
			}
			_spawn_queue.append({"time":cursor + float(unit_index) * unit_spacing, "delay_base":_schedule_delay_total, "spec":spec})
	_cue_queue.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return _scheduled_key(a) < _scheduled_key(b))
	_spawn_queue.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return _scheduled_key(a) < _scheduled_key(b))


func _roles_for_group(allocations: Array[Dictionary], group_index: int) -> Array[StringName]:
	var result: Array[StringName] = []
	for allocation in allocations:
		if int(allocation["group_index"]) != group_index:
			continue
		for role in allocation["roles"]:
			result.append(StringName(role))
	return result
