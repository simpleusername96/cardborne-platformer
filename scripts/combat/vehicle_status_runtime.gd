class_name VehicleStatusRuntime
extends RefCounted

## Applies bounded elemental state to typed live enemies and returns explicit DOT.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")


static func ensure(enemy: EnemyState) -> Dictionary:
	return enemy.statuses


static func payload(build: VehicleRunBuild) -> Dictionary:
	if build.element_core == &"incendiary_core":
		return {"kind": &"burn", "dps": 4.0 + 2.0 * build.level_of(&"thermal_compound"), "duration": 3.0 + build.level_of(&"thermal_compound")}
	if build.element_core == &"toxin_core":
		return {"kind": &"poison", "dps": 2.0 + build.level_of(&"concentrated_toxin"), "duration": 5.0, "max_stacks": 3 + build.level_of(&"concentrated_toxin")}
	if build.element_core == &"cryo_core":
		return {"kind": &"slow", "magnitude": minf(0.40, 0.18 + 0.08 * build.level_of(&"deep_freeze")), "duration": 2.0 + 0.5 * build.level_of(&"deep_freeze")}
	return {}


static func apply(enemy: EnemyState, effect: Dictionary) -> void:
	if effect.is_empty(): return
	var statuses := ensure(enemy)
	var kind := StringName(effect["kind"])
	if kind == &"burn":
		statuses[&"burn"] = {"dps": float(effect["dps"]), "time": float(effect["duration"]), "tick": 0.25}
	elif kind == &"poison":
		var poison: Dictionary = statuses.get(&"poison", {"dps": float(effect["dps"]), "time": 0.0, "tick": 0.25, "stacks": 0, "max_stacks": int(effect["max_stacks"])})
		poison["dps"] = float(effect["dps"])
		poison["time"] = float(effect["duration"])
		poison["stacks"] = mini(int(effect["max_stacks"]), int(poison["stacks"]) + 1)
		poison["max_stacks"] = int(effect["max_stacks"])
		statuses[&"poison"] = poison
	elif kind == &"slow":
		var boss_scale := 0.5 if enemy.role == &"stage_boss" else 1.0
		statuses[&"slow"] = {"magnitude": float(effect["magnitude"]) * boss_scale, "time": float(effect["duration"]) * boss_scale}


static func tick(enemy: EnemyState, delta: float) -> float:
	var statuses := enemy.statuses
	if statuses.is_empty():
		return 0.0
	var damage := 0.0
	for kind in [&"burn", &"poison"]:
		if not statuses.has(kind): continue
		var status: Dictionary = statuses[kind]
		status["time"] = float(status["time"]) - delta
		status["tick"] = float(status["tick"]) - delta
		while float(status["tick"]) <= 0.0 and float(status["time"]) > 0.0:
			status["tick"] = float(status["tick"]) + 0.25
			damage += float(status["dps"]) * 0.25 * float(status.get("stacks", 1))
		if float(status["time"]) <= 0.0: statuses.erase(kind)
		else: statuses[kind] = status
	if statuses.has(&"slow"):
		var slow: Dictionary = statuses[&"slow"]
		slow["time"] = float(slow["time"]) - delta
		if float(slow["time"]) <= 0.0: statuses.erase(&"slow")
		else: statuses[&"slow"] = slow
	return damage


static func speed_multiplier(enemy: EnemyState) -> float:
	var statuses := enemy.statuses
	if statuses.has(&"slow"): return 1.0 - float(statuses[&"slow"]["magnitude"])
	return 1.0


static func resolve_opening(enemy: EnemyState, build: VehicleRunBuild, base_damage: float) -> Dictionary:
	var statuses := enemy.statuses
	if build.has(&"flashover") and statuses.has(&"burn"):
		var burn: Dictionary = statuses[&"burn"]
		var bonus := float(burn["dps"]) * float(burn["time"]) * 1.25
		statuses.erase(&"burn")
		return {"bonus_damage": bonus, "splash_radius": 70.0, "kind": &"flashover"}
	if build.has(&"shatter") and statuses.has(&"slow") and float(statuses[&"slow"]["magnitude"]) >= 0.30:
		statuses.erase(&"slow")
		return {"bonus_damage": base_damage * 0.40, "splash_radius": 0.0, "kind": &"shatter"}
	return {"bonus_damage": 0.0, "splash_radius": 0.0, "kind": &"none"}
