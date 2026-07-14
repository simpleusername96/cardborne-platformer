extends SceneTree

const AttackIntentScript = preload("res://scripts/player/AttackIntent.gd")
const AttackIntentResolverScript = preload("res://scripts/player/AttackIntentResolver.gd")
const DefenseResolverScript = preload("res://scripts/player/DefenseResolver.gd")

const MELEE_ACTION := {
	"tool_id": &"traveler_sword",
	"hitbox_size": Vector2(76.0, 48.0),
	"hitbox_offset": Vector2(38.0, 0.0),
}
const RANGED_POLICY := {
	"tool_id": &"hunting_bow",
	"range": 520.0,
	"resource_id": &"arrows",
	"resource_cost": 1,
	"requires_line_of_sight": true,
}
const ROUND_SHIELD := {
	"tool_id": &"round_shield",
	"startup_time": 0.08,
	"recovery_time": 0.14,
	"guard_angle_degrees": 120.0,
	"precise_window": 0.14,
	"stability": 100,
	"condition": 10,
	"normal_stability_cost": 20,
	"heavy_stability_cost": 120,
	"normal_condition_cost": 1,
	"heavy_condition_cost": 3,
	"precise_condition_cost_scale": 0.0,
}
const TOWER_SHIELD := {
	"tool_id": &"tower_shield",
	"startup_time": 0.30,
	"recovery_time": 0.28,
	"guard_angle_degrees": 160.0,
	"precise_window": 0.08,
	"stability": 150,
	"condition": 10,
	"normal_stability_cost": 20,
	"heavy_stability_cost": 120,
	"normal_condition_cost": 1,
	"heavy_condition_cost": 2,
	"precise_condition_cost_scale": 0.0,
}

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_near_and_far_targets()
	_validate_disqualified_and_unavailable_targets()
	_validate_boundary_hysteresis()
	_validate_mirrored_melee_geometry()
	_validate_deterministic_targeting()
	_validate_action_lock_and_intent_isolation()
	_validate_defense_phases_and_precision()
	_validate_round_and_tower_differences()
	_validate_defense_rejections()
	_finish()


func _validate_near_and_far_targets() -> void:
	var near_intent = _resolve_attack([_target(&"near", Vector2(56.0, 0.0))])
	_expect(near_intent.mode == AttackIntentScript.MODE_MELEE, "near target should select melee")
	_expect(near_intent.tool_id == &"traveler_sword", "near target should use the melee tool")
	_expect(near_intent.target_id == &"near", "near target should be recorded")
	_expect(near_intent.reason == &"melee_target", "near target should explain melee selection")
	_expect(near_intent.origin == Vector2.ZERO, "intent should preserve the attack origin")
	_expect(near_intent.direction == Vector2.RIGHT, "melee intent should preserve facing")
	_expect(
		near_intent.geometry.get("targeting_buffer") == 16.0,
		"melee targeting should record the 16 px buffer"
	)

	var far_intent = _resolve_attack([_target(&"far", Vector2(240.0, 0.0))])
	_expect(far_intent.mode == AttackIntentScript.MODE_RANGED, "far target should select ranged")
	_expect(far_intent.tool_id == &"hunting_bow", "far target should use the ranged tool")
	_expect(far_intent.target_id == &"far", "far target should be recorded")
	_expect(far_intent.resource_id == &"arrows" and far_intent.resource_cost == 1, "ranged intent should record resource cost")
	_expect(far_intent.reason == &"ranged_target", "far target should explain ranged selection")
	_expect(far_intent.geometry.get("kind") == &"line", "ranged intent should expose line geometry")


func _validate_disqualified_and_unavailable_targets() -> void:
	var behind = _resolve_attack([_target(&"behind", Vector2(-80.0, 0.0))])
	_expect_fallback(behind, &"no_qualified_target", "behind target")

	var blocked_target := _target(&"wall", Vector2(240.0, 0.0))
	blocked_target["line_of_sight"] = false
	var wall = _resolve_attack([blocked_target])
	_expect_fallback(wall, &"line_of_sight_blocked", "wall target")

	var empty_resource = _resolve_attack(
		[_target(&"far", Vector2(240.0, 0.0))],
		{"resource_count": 0, "loaded": true, "reloading": false}
	)
	_expect_fallback(empty_resource, &"ranged_resource_unavailable", "zero resource")

	var reloading = _resolve_attack(
		[_target(&"far", Vector2(240.0, 0.0))],
		{"resource_count": 12, "loaded": false, "reloading": true, "reload_remaining": 0.4}
	)
	_expect_fallback(reloading, &"ranged_reloading", "reload")

	var out_of_range = _resolve_attack([_target(&"distant", Vector2(600.0, 0.0))])
	_expect_fallback(out_of_range, &"out_of_range", "out-of-range target")


func _validate_boundary_hysteresis() -> void:
	# The sword's buffered targeting rect ends at x=92; this hurtbox begins there.
	var exact_boundary = _resolve_attack([_target(&"boundary", Vector2(97.0, 0.0))])
	_expect(exact_boundary.mode == AttackIntentScript.MODE_MELEE, "exact 16 px boundary should be inclusive")

	var moved_target := _target(&"boundary", Vector2(98.0, 0.0))
	var held = _resolve_attack(
		[moved_target],
		_default_ranged_state(),
		{"intent": exact_boundary, "elapsed": 0.10}
	)
	_expect(held.mode == AttackIntentScript.MODE_MELEE, "boundary mode should hold for 0.15 seconds")
	_expect(held.reason == &"selection_hysteresis", "held boundary mode should expose hysteresis reason")

	var expired = _resolve_attack(
		[moved_target],
		_default_ranged_state(),
		{"intent": exact_boundary, "elapsed": 0.151}
	)
	_expect(expired.mode == AttackIntentScript.MODE_RANGED, "boundary hold should expire after 0.15 seconds")

	var ranged_held = _resolve_attack(
		[_target(&"boundary", Vector2(97.0, 0.0))],
		_default_ranged_state(),
		{"intent": expired, "elapsed": 0.10}
	)
	_expect(ranged_held.mode == AttackIntentScript.MODE_RANGED, "ranged boundary mode should also hold for 0.15 seconds")
	_expect(ranged_held.reason == &"selection_hysteresis", "ranged boundary hold should expose hysteresis reason")


func _validate_mirrored_melee_geometry() -> void:
	var action := {
		"tool_id": &"traveler_sword",
		"hitbox_size": Vector2(72.0, 42.0),
		"hitbox_offset": Vector2(40.0, -27.0),
	}
	var intent = AttackIntentResolverScript.resolve(
		Vector2.LEFT,
		Vector2.LEFT,
		{"origin": Vector2.ZERO, "targets": [_target(&"left", Vector2(-58.0, -27.0))]},
		action,
		RANGED_POLICY,
		_default_ranged_state()
	)
	var rect: Rect2 = intent.geometry.get("rect", Rect2())
	_expect(intent.mode == AttackIntentScript.MODE_MELEE, "left-facing nearby target should select melee")
	_expect(
		rect.get_center().is_equal_approx(Vector2(-40.0, -27.0)),
		"mirroring melee reach must not invert its vertical offset"
	)


func _validate_deterministic_targeting() -> void:
	var nearest = _resolve_attack([
		_target(&"farther", Vector2(70.0, 0.0)),
		_target(&"nearest", Vector2(35.0, 0.0)),
		_target(&"dead", Vector2(20.0, 0.0), false, true),
		_target(&"hidden", Vector2(15.0, 0.0), true, false),
	])
	_expect(nearest.target_id == &"nearest", "nearest alive discovered melee target should win")

	var tied = _resolve_attack([
		_target(&"zeta", Vector2(220.0, 0.0)),
		_target(&"alpha", Vector2(220.0, 0.0)),
	])
	_expect(tied.mode == AttackIntentScript.MODE_RANGED, "tied far targets should use ranged")
	_expect(tied.target_id == &"alpha", "equal-distance targets should use lexical ID tie-break")


func _validate_action_lock_and_intent_isolation() -> void:
	var original = _resolve_attack([_target(&"near", Vector2(50.0, 0.0))])
	var locked = _resolve_attack(
		[_target(&"far", Vector2(300.0, 0.0))],
		_default_ranged_state(),
		{"intent": original, "elapsed": 1.0, "action_locked": true}
	)
	_expect(locked == original, "action lock should return the exact committed intent")

	var geometry_copy: Dictionary = original.geometry
	geometry_copy.clear()
	_expect(not original.geometry.is_empty(), "intent geometry should be isolated from callers")
	var snapshot: Dictionary = original.to_snapshot()
	(snapshot["geometry"] as Dictionary).clear()
	_expect(not original.geometry.is_empty(), "intent snapshots should not mutate the intent")


func _validate_defense_phases_and_precision() -> void:
	var normal_attack := _attack(&"normal", Vector2.RIGHT)
	var startup = DefenseResolverScript.resolve(
		normal_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.04}
	)
	_expect(startup.phase == &"startup" and not startup.blocked, "round shield startup should not block")
	_expect(startup.condition_cost == 0 and startup.stability_cost == 0, "startup should not spend defense resources")

	var precise = DefenseResolverScript.resolve(
		normal_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.10}
	)
	_expect(precise.phase == &"active" and precise.blocked, "round shield should become active after startup")
	_expect(precise.precise and precise.reason == &"precise_block", "early active defense should be precise")
	_expect(precise.condition_cost == 0 and precise.stability_cost == 20, "precise block should preserve condition")

	var precise_boundary = DefenseResolverScript.resolve(
		normal_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.22}
	)
	_expect(precise_boundary.precise, "precise window boundary should be inclusive")
	var normal_block = DefenseResolverScript.resolve(
		normal_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.221}
	)
	_expect(normal_block.blocked and not normal_block.precise, "active defense after the precise window should be normal")

	var recovery = DefenseResolverScript.resolve(
		normal_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": false, "release_elapsed": 0.05}
	)
	_expect(recovery.phase == &"recovery" and not recovery.blocked, "shield recovery should not block")
	_expect(recovery.condition_cost == 0 and recovery.stability_cost == 0, "recovery should not spend defense resources")


func _validate_round_and_tower_differences() -> void:
	var normal_attack := _attack(&"normal", _direction_at_degrees(70.0))
	var round_angle = DefenseResolverScript.resolve(
		normal_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.40}
	)
	var tower_startup = DefenseResolverScript.resolve(
		normal_attack, TOWER_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.10}
	)
	var tower_angle = DefenseResolverScript.resolve(
		normal_attack, TOWER_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.40}
	)
	_expect(not round_angle.blocked and round_angle.reason == &"outside_guard_angle", "round shield should reject a 70 degree attack")
	_expect(tower_startup.phase == &"startup" and not tower_startup.blocked, "tower shield should retain its slower startup")
	_expect(tower_angle.blocked, "tower shield should accept the same attack inside its wider angle")

	var heavy_attack := _attack(&"heavy", Vector2.RIGHT)
	var round_heavy = DefenseResolverScript.resolve(
		heavy_attack, ROUND_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.40}
	)
	var tower_heavy = DefenseResolverScript.resolve(
		heavy_attack, TOWER_SHIELD, Vector2.RIGHT, {"guard_held": true, "guard_elapsed": 0.50}
	)
	_expect(not round_heavy.blocked and round_heavy.guard_broken, "heavy attack should break round shield stability")
	_expect(round_heavy.stability_cost == 100 and round_heavy.condition_cost == 3, "guard break should report consumed round-shield resources")
	_expect(tower_heavy.blocked and not tower_heavy.guard_broken, "tower shield stability should survive the same heavy attack")
	_expect(tower_heavy.stability_cost == 120 and tower_heavy.condition_cost == 2, "tower heavy block should report configured costs")


func _validate_defense_rejections() -> void:
	var unblockable = DefenseResolverScript.resolve(
		_attack(&"unblockable", Vector2.RIGHT),
		TOWER_SHIELD,
		Vector2.RIGHT,
		{"guard_held": true, "guard_elapsed": 0.50}
	)
	_expect(not unblockable.blocked and unblockable.reason == &"unblockable", "unblockable attack should bypass every shield")
	_expect(unblockable.condition_cost == 0 and unblockable.stability_cost == 0, "unblockable attack should not invent shield costs")

	var rear = DefenseResolverScript.resolve(
		_attack(&"normal", Vector2.LEFT),
		TOWER_SHIELD,
		Vector2.RIGHT,
		{"guard_held": true, "guard_elapsed": 0.50}
	)
	_expect(not rear.blocked and rear.reason == &"outside_guard_angle", "rear attack should bypass shield defense")

	var worn_shield: Dictionary = ROUND_SHIELD.duplicate(true)
	worn_shield["condition"] = 0
	var worn = DefenseResolverScript.resolve(
		_attack(&"normal", Vector2.RIGHT),
		worn_shield,
		Vector2.RIGHT,
		{"guard_held": true, "guard_elapsed": 0.30}
	)
	_expect(worn.blocked and worn.reason == &"blocked", "zero-condition shield should remain usable")
	_expect(worn.condition_cost == 0, "worn shield cannot spend condition below zero")
	_expect(worn.tags.has(&"worn"), "worn shield result should expose its condition state")

	var tags_copy: Array[StringName] = worn.tags
	tags_copy.clear()
	_expect(not worn.tags.is_empty(), "defense tags should be isolated from callers")


func _resolve_attack(
	targets: Array,
	ranged_state: Dictionary = {},
	previous_selection: Variant = null
) -> Variant:
	var state := _default_ranged_state() if ranged_state.is_empty() else ranged_state
	return AttackIntentResolverScript.resolve(
		Vector2.RIGHT,
		Vector2.RIGHT,
		{"origin": Vector2.ZERO, "targets": targets},
		MELEE_ACTION,
		RANGED_POLICY,
		state,
		previous_selection
	)


func _default_ranged_state() -> Dictionary:
	return {"resource_count": 12, "loaded": true, "reloading": false, "reload_remaining": 0.0}


func _target(
	target_id: StringName,
	position: Vector2,
	alive: bool = true,
	discovered: bool = true
) -> Dictionary:
	return {
		"id": target_id,
		"position": position,
		"hurtbox_size": Vector2(10.0, 30.0),
		"alive": alive,
		"discovered": discovered,
		"targetable": true,
		"is_enemy": true,
		"on_screen": true,
		"line_of_sight": true,
	}


func _attack(attack_type: StringName, source_direction: Vector2) -> Dictionary:
	return {"attack_type": attack_type, "source_direction": source_direction}


func _direction_at_degrees(angle: float) -> Vector2:
	var radians := deg_to_rad(angle)
	return Vector2(cos(radians), sin(radians))


func _expect_fallback(intent: Variant, reason: StringName, scenario: String) -> void:
	_expect(intent.mode == AttackIntentScript.MODE_MELEE, "%s should fall back to melee" % scenario)
	_expect(intent.tool_id == &"traveler_sword", "%s fallback should use melee tool" % scenario)
	_expect(not intent.is_targeted(), "%s fallback should remain untargeted" % scenario)
	_expect(intent.resource_cost == 0, "%s fallback should spend no ranged resource" % scenario)
	_expect(intent.reason == reason, "%s fallback should expose reason '%s'" % [scenario, reason])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("CONTEXT_COMBAT_CONTRACT_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
