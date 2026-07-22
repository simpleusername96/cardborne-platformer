class_name VehicleEncounterRuntime
extends RefCounted

## Deterministic authored-packet scheduler. It owns grace, cue timing, queue
## order, beat caps, and metrics, but never draws or mutates combat actors.

const Director = preload("res://scripts/encounters/vehicle_encounter_director.gd")

const ARRIVAL_GRACE := 6.0
const CUE_LEAD := 0.9
const METRIC_SAMPLE_INTERVAL := 0.10
const MAX_ACTIVE_COUNT_SAMPLES := 4096

var stage_id: StringName = &"flooded_works"
var preset: StringName = &"standard"
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


func configure(next_stage_id: StringName, packets: Array[Dictionary], combat_preset: StringName) -> void:
	stage_id = next_stage_id
	preset = &"onslaught" if combat_preset == &"onslaught" else &"standard"
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


func signal_event(event_id: StringName) -> void:
	if event_id.is_empty():
		return
	_events[event_id] = elapsed
	_timeline.append({"kind":&"event", "id":event_id, "time":elapsed})


func has_event(event_id: StringName) -> bool:
	return _events.has(event_id)


func tick(delta: float, active_mobile_count: int, active_attack_families: Array[StringName] = []) -> Dictionary:
	elapsed += maxf(0.0, delta)
	_record_active_count_sample(active_mobile_count)
	_max_attack_family_overlap = maxi(_max_attack_family_overlap, active_attack_families.size())
	_activate_ready_packets()
	var cues: Array[Dictionary] = []
	while not _cue_queue.is_empty() and _effective_time(_cue_queue[0]) <= elapsed + 0.0001:
		var cue: Dictionary = _cue_queue.pop_front()
		cues.append(cue)
		var cue_time := _effective_time(cue)
		if _first_cue_time < 0.0:
			_first_cue_time = cue_time
		_timeline.append({"kind":&"cue", "id":cue["squad_id"], "time":cue_time})

	var spawns: Array[Dictionary] = []
	if not _spawn_queue.is_empty() and _effective_time(_spawn_queue[0]) <= elapsed + 0.0001:
		if active_mobile_count < active_cap():
			var request: Dictionary = _spawn_queue.pop_front()
			spawns.append(request["spec"])
			var squad_id := String(request["spec"]["squad_id"])
			_spawned_by_squad[squad_id] = int(_spawned_by_squad.get(squad_id, 0)) + 1
			var spawn_time := _effective_time(request)
			if _first_spawn_time < 0.0:
				_first_spawn_time = spawn_time
			_timeline.append({"kind":&"spawn", "id":request["spec"]["id"], "squad_id":squad_id, "time":spawn_time})
		else:
			_schedule_delay_total += maxf(0.0, delta)
	return {"cues":cues, "spawns":spawns}


func active_cap() -> int:
	return Director.active_cap_for(current_beat, preset)


func threat_budget() -> float:
	return Director.threat_budget_for(current_beat, preset)


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
		"preset":preset,
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
	}


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


func _activate_ready_packets() -> void:
	for packet in _packets:
		var packet_id := String(packet["id"])
		if _activated_packets.has(packet_id) or not _trigger_ready(packet["trigger"]):
			continue
		_activated_packets[packet_id] = elapsed
		current_beat = maxi(current_beat, int(packet["beat"]))
		_schedule_packet(packet)


func _trigger_ready(trigger: Dictionary) -> bool:
	match StringName(trigger.get("kind", &"event")):
		&"time":
			return elapsed >= float(trigger.get("at", INF))
		&"event":
			return _events.has(StringName(trigger.get("id", &"")))
	return false


func _schedule_packet(packet: Dictionary) -> void:
	var packet_id := String(packet["id"])
	var beat := int(packet["beat"])
	var anchor := Vector2(packet["anchor"])
	var squads: Array = packet["squads"]
	var pace_multiplier := Director.spawn_pace_multiplier(beat, preset)
	var unit_spacing := float(packet.get("unit_spacing", 0.5)) * pace_multiplier
	var gap := float(packet.get("squad_gap", 4.5)) * Director.squad_gap_multiplier(beat, preset)
	var cue_lead := float(packet.get("cue_lead", CUE_LEAD))
	var cursor := elapsed + cue_lead
	for squad_index in squads.size():
		var squad: Array = squads[squad_index]
		var squad_id := "%s_s%02d" % [packet_id, squad_index + 1]
		_cue_queue.append({"time":cursor - cue_lead, "delay_base":_schedule_delay_total, "anchor":anchor, "squad_id":squad_id, "beat":beat})
		for unit_index in squad.size():
			var role := StringName(squad[unit_index])
			var formation_angle := TAU * float(unit_index) / float(maxi(1, squad.size()))
			var formation_offset := Vector2.RIGHT.rotated(formation_angle) * (58.0 if squad.size() > 1 else 0.0)
			var spec := {
				"id":"%s_u%02d" % [squad_id, unit_index + 1],
				"role":role,
				"pos":anchor,
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
			}
			_spawn_queue.append({"time":cursor + float(unit_index) * unit_spacing, "delay_base":_schedule_delay_total, "spec":spec})
		cursor += gap
	_cue_queue.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return _scheduled_key(a) < _scheduled_key(b))
	_spawn_queue.sort_custom(func(a:Dictionary,b:Dictionary)->bool: return _scheduled_key(a) < _scheduled_key(b))
