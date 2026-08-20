class_name VehicleCollectiveTacticRuntime
extends RefCounted

## Bounded squad coordinator. It evaluates only registered member IDs and owns
## the single global Lock/Execute permission plus one queued Gather permission.

const Catalog = preload(
	"res://scripts/encounters/vehicle_collective_tactic_catalog.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const FamilyTraits = preload(
	"res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd"
)

const MAX_REGISTERED_SQUADS := 32
const DORMANT_VISIBLE_DWELL_SECONDS := 0.75

var _squads: Dictionary = {}
var _active_permission_id := ""
var _gather_permission_id := ""
var _events: Array[Dictionary] = []
var _phase_counts: Dictionary = {}
var _break_reasons: Dictionary = {}
var _offscreen_cancellations := 0
var _maximum_active_permissions := 0
var _stale_members_removed := 0


func reset() -> void:
	for state_variant in _squads.values():
		_clear_member_state(Dictionary(state_variant))
	_squads.clear()
	_active_permission_id = ""
	_gather_permission_id = ""
	_events.clear()
	_phase_counts.clear()
	_break_reasons.clear()
	_offscreen_cancellations = 0
	_maximum_active_permissions = 0
	_stale_members_removed = 0


func register_enemy(enemy: EnemyState) -> void:
	if (
		enemy == null
		or enemy.collective_tactic_id.is_empty()
		or enemy.squad_id.is_empty()
	):
		return
	var squad_id := enemy.squad_id
	if not _squads.has(squad_id):
		if _squads.size() >= MAX_REGISTERED_SQUADS:
			enemy.collective_tactic_id = &""
			return
		var recipe := Catalog.recipe(enemy.collective_tactic_id)
		if recipe.is_empty():
			enemy.collective_tactic_id = &""
			return
		_squads[squad_id] = {
			"id": squad_id,
			"tactic_id": enemy.collective_tactic_id,
			"recipe": recipe,
			"member_ids": PackedStringArray(),
			"leader_id": "",
			"phase": Catalog.PHASE_DORMANT,
			"timer": 0.0,
			"visible_dwell": 0.0,
			"visible_eligible": false,
			"direction": Vector2.RIGHT,
			"centroid": enemy.pos,
			"cycle": 0,
			"beat_kind": enemy.collective_beat_kind,
			"family": enemy.family,
			"tier": enemy.tier,
			"trait": enemy.family_trait,
			"trait_phase": &"idle",
			"trait_timer": _trait_interval(enemy.family_trait),
			"trait_ratio": 0.0,
			"feed_stacks": 0,
			"feed_enabled": true,
			"defeat_receipts": PackedStringArray(),
		}
	var state: Dictionary = _squads[squad_id]
	var member_ids := PackedStringArray(state["member_ids"])
	if enemy.id not in member_ids:
		member_ids.append(enemy.id)
		member_ids.sort()
	state["member_ids"] = member_ids
	if enemy.squad_leader or String(state["leader_id"]).is_empty():
		state["leader_id"] = enemy.id
	_squads[squad_id] = state


func unregister_enemy(enemy_id: String, squad_id: String) -> void:
	if enemy_id.is_empty() or squad_id.is_empty() or not _squads.has(squad_id):
		return
	var state: Dictionary = _squads[squad_id]
	var member_ids := PackedStringArray(state["member_ids"])
	var index := member_ids.find(enemy_id)
	if index >= 0:
		member_ids.remove_at(index)
		state["member_ids"] = member_ids
	if String(state["leader_id"]) == enemy_id:
		state["leader_id"] = ""
		_break_state(state, &"leader_lost")
	if member_ids.is_empty():
		_erase_squad(squad_id)
	else:
		_squads[squad_id] = state


func advance(
	delta: float,
	player_position: Vector2,
	visible_world: Rect2,
	enemy_lookup: Callable
) -> Array[Dictionary]:
	var squad_ids := _squads.keys()
	squad_ids.sort()
	for squad_id_variant in squad_ids:
		var squad_id := String(squad_id_variant)
		if not _squads.has(squad_id):
			continue
		var state: Dictionary = _squads[squad_id]
		var members := _resolve_members(state, enemy_lookup)
		if members.is_empty():
			_erase_squad(squad_id)
			continue
		var recipe: Dictionary = state["recipe"]
		var minimum_members := int(recipe["minimum_members"])
		var phase := StringName(state["phase"])
		var leader_id := String(state["leader_id"])
		var leader_present := false
		var centroid := Vector2.ZERO
		var visible_members := 0
		var interrupted := false
		for member in members:
			centroid += member.pos
			leader_present = leader_present or member.id == leader_id
			visible_members += 1 if visible_world.has_point(member.pos) else 0
			interrupted = interrupted or member.stun > 0.01
		centroid /= float(members.size())
		state["centroid"] = centroid
		_advance_trait_state(state, delta)
		var visible := (
			visible_world.has_point(centroid)
			and visible_members >= minimum_members
		)
		state["visible_eligible"] = (
			members.size() >= minimum_members
			and leader_present
			and visible
		)
		if (
			phase in [Catalog.PHASE_GATHER, Catalog.PHASE_LOCK, Catalog.PHASE_EXECUTE]
			and (
				members.size() < minimum_members
				or not leader_present
				or interrupted
			)
		):
			_break_state(
				state,
				&"stun"
				if interrupted
				else (&"leader_lost" if not leader_present else &"members_lost")
			)
			phase = StringName(state["phase"])
		if phase in [Catalog.PHASE_LOCK, Catalog.PHASE_EXECUTE] and not visible:
			_offscreen_cancellations += 1
			_break_state(state, &"offscreen")
			phase = StringName(state["phase"])
		match phase:
			Catalog.PHASE_DORMANT:
				state["visible_dwell"] = (
					minf(
						DORMANT_VISIBLE_DWELL_SECONDS,
						float(state["visible_dwell"]) + delta
					)
					if (
						bool(state["visible_eligible"])
					)
					else 0.0
				)
				if (
					bool(state["visible_eligible"])
					and float(state["visible_dwell"]) >= DORMANT_VISIBLE_DWELL_SECONDS
					and _gather_permission_id.is_empty()
				):
					_gather_permission_id = squad_id
					_enter_phase(state, Catalog.PHASE_GATHER)
			Catalog.PHASE_GATHER:
				state["timer"] = maxf(0.0, float(state["timer"]) - delta)
				if (
					float(state["timer"]) <= 0.0
					and visible
					and _active_permission_id.is_empty()
				):
					_active_permission_id = squad_id
					if _gather_permission_id == squad_id:
						_gather_permission_id = ""
					state["direction"] = _safe_direction(
						player_position - centroid
					)
					_enter_phase(state, Catalog.PHASE_LOCK)
			Catalog.PHASE_LOCK:
				state["timer"] = maxf(0.0, float(state["timer"]) - delta)
				if float(state["timer"]) <= 0.0:
					_enter_phase(state, Catalog.PHASE_EXECUTE)
			Catalog.PHASE_EXECUTE:
				state["timer"] = maxf(0.0, float(state["timer"]) - delta)
				if float(state["timer"]) <= 0.0:
					_break_state(state, &"completed")
			Catalog.PHASE_BREAK:
				state["timer"] = maxf(0.0, float(state["timer"]) - delta)
				if float(state["timer"]) <= 0.0:
					_enter_phase(state, Catalog.PHASE_COOLDOWN)
			Catalog.PHASE_COOLDOWN:
				state["timer"] = maxf(0.0, float(state["timer"]) - delta)
				if float(state["timer"]) <= 0.0:
					_enter_phase(state, Catalog.PHASE_DORMANT)
		_apply_member_state(state, members)
		_squads[squad_id] = state
	_maximum_active_permissions = maxi(
		_maximum_active_permissions,
		1 if not _active_permission_id.is_empty() else 0
	)
	var emitted := _events.duplicate(true)
	_events.clear()
	return emitted


func break_squad(squad_id: String, reason: StringName) -> void:
	if not _squads.has(squad_id):
		return
	var state: Dictionary = _squads[squad_id]
	_break_state(state, reason)
	_squads[squad_id] = state


func record_member_defeat(enemy: EnemyState) -> Dictionary:
	if enemy == null or enemy.squad_id.is_empty() or not _squads.has(enemy.squad_id):
		return {}
	var state: Dictionary = _squads[enemy.squad_id]
	if StringName(state.get("trait", &"")) != &"pack_feed":
		return {}
	var receipts := PackedStringArray(state.get("defeat_receipts", PackedStringArray()))
	if enemy.id in receipts:
		return {}
	receipts.append(enemy.id)
	state["defeat_receipts"] = receipts
	if enemy.id == String(state.get("leader_id", "")):
		state["feed_enabled"] = false
		_squads[enemy.squad_id] = state
		return {"leader_lost":true, "squad_id":enemy.squad_id}
	if enemy.summoned or not bool(state.get("feed_enabled", true)):
		_squads[enemy.squad_id] = state
		return {}
	var stacks := mini(
		FamilyTraits.PACK_FEED_MAX_STACKS,
		int(state.get("feed_stacks", 0)) + 1
	)
	state["feed_stacks"] = stacks
	_squads[enemy.squad_id] = state
	var survivor_ids := PackedStringArray()
	for member_id in PackedStringArray(state.get("member_ids", PackedStringArray())):
		if member_id != enemy.id:
			survivor_ids.append(member_id)
	return {
		"squad_id":enemy.squad_id,
		"stacks":stacks,
		"survivor_ids":survivor_ids,
		"heal_ratio":FamilyTraits.PACK_FEED_HEAL_RATIO,
	}


func debug_snapshot() -> Dictionary:
	var phases := {}
	var eligibility := {}
	var packs := {}
	var member_count := 0
	for state_variant in _squads.values():
		var state := Dictionary(state_variant)
		var phase := StringName(state["phase"])
		phases[phase] = int(phases.get(phase, 0)) + 1
		member_count += PackedStringArray(state["member_ids"]).size()
		eligibility[String(state["id"])] = {
			"phase": phase,
			"visible_eligible": bool(state["visible_eligible"]),
			"visible_dwell": float(state["visible_dwell"]),
			"visible_dwell_ready": float(state["visible_dwell"]) >= DORMANT_VISIBLE_DWELL_SECONDS,
		}
		packs[String(state["id"])] = {
			"family":StringName(state.get("family", &"")),
			"tier":int(state.get("tier", 0)),
			"trait":StringName(state.get("trait", &"")),
			"trait_phase":StringName(state.get("trait_phase", &"idle")),
			"trait_ratio":float(state.get("trait_ratio", 0.0)),
			"feed_stacks":int(state.get("feed_stacks", 0)),
			"member_count":PackedStringArray(state["member_ids"]).size(),
		}
	return {
		"squad_count": _squads.size(),
		"member_count": member_count,
		"active_permission": _active_permission_id,
		"gather_permission": _gather_permission_id,
		"active_permission_count": 1 if not _active_permission_id.is_empty() else 0,
		"gather_permission_count": 1 if not _gather_permission_id.is_empty() else 0,
		"maximum_active_permissions": _maximum_active_permissions,
		"offscreen_execute_count": 0,
		"offscreen_cancellations": _offscreen_cancellations,
		"stale_member_count": 0,
		"stale_members_removed": _stale_members_removed,
		"dormant_visible_dwell_seconds": DORMANT_VISIBLE_DWELL_SECONDS,
		"eligibility": eligibility,
		"packs":packs,
		"phases": phases,
		"phase_counts": _phase_counts.duplicate(true),
		"break_reasons": _break_reasons.duplicate(true),
	}


func _resolve_members(
	state: Dictionary,
	enemy_lookup: Callable
) -> Array[EnemyState]:
	var members: Array[EnemyState] = []
	var valid_ids := PackedStringArray()
	var squad_id := String(state["id"])
	var tactic_id := StringName(state["tactic_id"])
	for enemy_id in PackedStringArray(state["member_ids"]):
		var enemy: EnemyState = enemy_lookup.call(enemy_id)
		if (
			enemy == null
			or not enemy.alive
			or not enemy.active
			or enemy.squad_id != squad_id
			or enemy.collective_tactic_id != tactic_id
		):
			_stale_members_removed += 1
			continue
		members.append(enemy)
		valid_ids.append(enemy_id)
	state["member_ids"] = valid_ids
	return members


func _apply_member_state(
	state: Dictionary,
	members: Array[EnemyState]
) -> void:
	var phase := StringName(state["phase"])
	var recipe: Dictionary = state["recipe"]
	var direction := _safe_direction(Vector2(state["direction"]))
	var trait_id := StringName(state.get("trait", &""))
	var trait_phase := StringName(state.get("trait_phase", &"idle"))
	var trait_active := trait_phase == &"active"
	var feed_stacks := int(state.get("feed_stacks", 0))
	for index in members.size():
		var member := members[index]
		var phase_changed := member.collective_phase != phase
		member.collective_phase = phase
		member.collective_mode = StringName(recipe["mode"])
		member.collective_direction = direction
		member.collective_target = (
			Vector2(state["centroid"])
			+ _slot_offset(
				StringName(recipe["formation"]),
				index,
				members.size(),
				direction
			)
		)
		member.collective_slot = index
		member.pack_trait_active = trait_active
		member.pack_trait_phase = trait_phase
		member.pack_trait_ratio = float(state.get("trait_ratio", 0.0))
		member.pack_feed_stacks = feed_stacks
		member.pack_damage_multiplier = (
			1.0 + float(feed_stacks) * FamilyTraits.PACK_FEED_DAMAGE_PER_STACK
			if trait_id == &"pack_feed" else 1.0
		)
		member.pack_speed_multiplier = (
			1.0 + float(feed_stacks) * FamilyTraits.PACK_FEED_SPEED_PER_STACK
			if trait_id == &"pack_feed" else 1.0
		)
		if phase == Catalog.PHASE_EXECUTE:
			if phase_changed:
				member.hit_committed = false
			member.collective_speed_multiplier = (
				1.65
				if member.collective_mode in [&"charge", &"fuse"]
				else 1.12
			)
		else:
			member.collective_speed_multiplier = 1.0
		if phase == Catalog.PHASE_BREAK:
			member.vulnerable = maxf(
				member.vulnerable,
				float(recipe["break"])
			)


func _advance_trait_state(state: Dictionary, delta: float) -> void:
	var trait_id := StringName(state.get("trait", &""))
	if trait_id not in [&"bulwark", &"reflector", &"blink"]:
		state["trait_phase"] = &"idle"
		state["trait_ratio"] = 0.0
		return
	var phase := StringName(state.get("trait_phase", &"idle"))
	var timer := maxf(0.0, float(state.get("trait_timer", 0.0)) - delta)
	if timer > 0.0:
		state["trait_timer"] = timer
		state["trait_ratio"] = _trait_phase_ratio(trait_id, phase, timer)
		return
	if phase == &"idle":
		var next_phase := &"warning" if trait_id == &"blink" else &"active"
		state["trait_phase"] = next_phase
		state["trait_timer"] = (
			FamilyTraits.BLINK_WARNING_DURATION
			if next_phase == &"warning" else _trait_active_duration(trait_id)
		)
		state["trait_ratio"] = 0.0
		_events.append({
			"kind":&"pack_trait",
			"action":next_phase,
			"squad_id":state["id"],
			"trait":trait_id,
			"position":state["centroid"],
		})
		return
	if phase == &"warning" and trait_id == &"blink":
		_events.append({
			"kind":&"pack_trait",
			"action":&"blink_request",
			"squad_id":state["id"],
			"trait":trait_id,
			"position":state["centroid"],
		})
	state["trait_phase"] = &"idle"
	state["trait_timer"] = _trait_interval(trait_id)
	state["trait_ratio"] = 0.0


func _trait_phase_ratio(trait_id: StringName, phase: StringName, timer: float) -> float:
	if phase == &"warning":
		return 1.0 - timer / maxf(0.001, FamilyTraits.BLINK_WARNING_DURATION)
	if phase == &"active":
		return 1.0 - timer / maxf(0.001, _trait_active_duration(trait_id))
	return 0.0


func _trait_interval(trait_id: StringName) -> float:
	match trait_id:
		&"bulwark":
			return FamilyTraits.BULWARK_INTERVAL
		&"reflector":
			return FamilyTraits.REFLECTOR_INTERVAL
		&"blink":
			return FamilyTraits.BLINK_INTERVAL
	return 0.0


func _trait_active_duration(trait_id: StringName) -> float:
	return (
		FamilyTraits.BULWARK_ACTIVE_DURATION
		if trait_id == &"bulwark"
		else FamilyTraits.REFLECTOR_ACTIVE_DURATION
	)


func _clear_member_state(state: Dictionary) -> void:
	# Live actors are reset by their owner; this path only releases permissions.
	var squad_id := String(state.get("id", ""))
	if _active_permission_id == squad_id:
		_active_permission_id = ""
	if _gather_permission_id == squad_id:
		_gather_permission_id = ""


func _enter_phase(state: Dictionary, phase: StringName) -> void:
	var previous := StringName(state["phase"])
	state["phase"] = phase
	var recipe: Dictionary = state["recipe"]
	state["timer"] = float(recipe.get(String(phase), 0.0))
	if phase == Catalog.PHASE_DORMANT:
		state["timer"] = 0.0
		state["visible_dwell"] = 0.0
	if phase == Catalog.PHASE_EXECUTE:
		state["cycle"] = int(state["cycle"]) + 1
	_phase_counts[phase] = int(_phase_counts.get(phase, 0)) + 1
	_events.append({
		"kind": &"phase",
		"squad_id": state["id"],
		"tactic_id": state["tactic_id"],
		"from": previous,
		"phase": phase,
		"position": state["centroid"],
		"beat_kind": state["beat_kind"],
	})


func _break_state(state: Dictionary, reason: StringName) -> void:
	var phase := StringName(state["phase"])
	if phase in [Catalog.PHASE_BREAK, Catalog.PHASE_COOLDOWN, Catalog.PHASE_DORMANT]:
		return
	var squad_id := String(state["id"])
	if _active_permission_id == squad_id:
		_active_permission_id = ""
	if _gather_permission_id == squad_id:
		_gather_permission_id = ""
	_break_reasons[reason] = int(_break_reasons.get(reason, 0)) + 1
	_enter_phase(state, Catalog.PHASE_BREAK)
	_events.append({
		"kind": &"break",
		"squad_id": squad_id,
		"tactic_id": state["tactic_id"],
		"reason": reason,
		"position": state["centroid"],
	})


func _erase_squad(squad_id: String) -> void:
	if not _squads.has(squad_id):
		return
	_clear_member_state(Dictionary(_squads[squad_id]))
	_squads.erase(squad_id)


func _slot_offset(
	formation: StringName,
	index: int,
	count: int,
	direction: Vector2
) -> Vector2:
	var side := direction.rotated(PI * 0.5)
	var centered := float(index) - float(count - 1) * 0.5
	match formation:
		&"spear":
			var row := floori((float(index) + 1.0) * 0.5)
			var sign_value := -1.0 if index % 2 == 0 else 1.0
			return -direction * float(row) * 52.0 + side * sign_value * float(row) * 34.0
		&"column", &"fuse":
			return -direction * centered * 54.0
		&"screen", &"convoy":
			return side * centered * 56.0
		&"escort":
			return (
				Vector2.RIGHT.rotated(TAU * float(index) / float(maxi(1, count)))
				* 86.0
			)
		&"network":
			return (
				Vector2.RIGHT.rotated(TAU * float(index) / float(maxi(1, count)))
				* 102.0
			)
	return side * centered * 48.0


func _safe_direction(value: Vector2) -> Vector2:
	return Vector2.RIGHT if value.is_zero_approx() else value.normalized()
