class_name VehicleSecondaryRuntime
extends RefCounted

## Bounded simulation for automatic secondary families other than the existing
## seeker projectile. It emits damage intents; VehicleRun remains damage owner.

const DEFINITION_PATH := "res://data/weapons/vehicle/secondary"
const ION_TICK := 0.25
const ORBIT_HIT_COOLDOWN := 0.55
const MINE_LIFETIME := 8.0

var definitions: Dictionary = {}
var timers: Dictionary = {}
var orbit_angle := 0.0
var orbit_target_cooldowns: Dictionary = {}
var mines: Array[Dictionary] = []
var drone_position := Vector2.ZERO


func _init() -> void:
	for file_name in DirAccess.get_files_at(DEFINITION_PATH):
		if file_name.ends_with(".tres"):
			var definition := load(DEFINITION_PATH.path_join(file_name)) as VehicleSecondaryDefinition
			if definition != null:
				definitions[definition.id] = definition


func reset(player_position: Vector2) -> void:
	timers.clear()
	orbit_target_cooldowns.clear()
	mines.clear()
	orbit_angle = 0.0
	drone_position = player_position


func update(delta: float, player_position: Vector2, player_direction: Vector2, build: VehicleRunBuild, enemies: Array[Dictionary], line_of_sight: Callable) -> Dictionary:
	var damage: Array[Dictionary] = []
	var effects: Array[Dictionary] = []
	orbit_angle = fmod(orbit_angle + delta * 2.45, TAU)
	for enemy_id in orbit_target_cooldowns.keys():
		orbit_target_cooldowns[enemy_id] = maxf(0.0, float(orbit_target_cooldowns[enemy_id]) - delta)
	_update_ion(delta, player_position, build, enemies, line_of_sight, damage)
	_update_orbit(player_position, build, enemies, line_of_sight, damage)
	_update_mines(delta, player_position, player_direction, build, enemies, line_of_sight, damage, effects)
	_update_drone(delta, player_position, build, enemies, line_of_sight, damage, effects)
	return {"damage":damage, "effects":effects}


func snapshot(build: VehicleRunBuild) -> Dictionary:
	return {
		"equipped":equipped_families(build),
		"orbit_angle":orbit_angle,
		"mines":mines.duplicate(true),
		"drone_position":drone_position,
	}


func equipped_families(build: VehicleRunBuild) -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id":&"seeker", "level":1, "name_key":"SECONDARY_SEEKER_NAME"}]
	for secondary_id in [&"ion_field", &"orbit_blades", &"wake_mines", &"escort_drone"]:
		var definition: VehicleSecondaryDefinition = definitions.get(secondary_id)
		if definition == null:
			continue
		var level := build.level_of(definition.upgrade_id)
		if level > 0:
			result.append({"id":secondary_id, "level":level, "name_key":definition.name_key})
	return result


func _update_ion(delta: float, origin: Vector2, build: VehicleRunBuild, enemies: Array[Dictionary], line_of_sight: Callable, output: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"ion_field")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	if not _timer_ready(&"ion_field", delta, ION_TICK):
		return
	var radius := definition.auxiliary(level)
	for enemy in enemies:
		if _eligible(enemy) and origin.distance_to(Vector2(enemy["pos"])) <= radius + float(enemy["radius"]) and line_of_sight.call(origin, Vector2(enemy["pos"]), 3.0):
			output.append({"enemy_id":String(enemy["id"]), "damage":definition.value(level) * ION_TICK, "source":"Ion Field"})


func _update_orbit(origin: Vector2, build: VehicleRunBuild, enemies: Array[Dictionary], line_of_sight: Callable, output: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"orbit_blades")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		return
	var count := definition.cap(level)
	for blade_index in count:
		var blade_position := origin + Vector2.RIGHT.rotated(orbit_angle + TAU * float(blade_index) / float(count)) * 78.0
		for enemy in enemies:
			var enemy_id := String(enemy.get("id", ""))
			if not _eligible(enemy) or float(orbit_target_cooldowns.get(enemy_id, 0.0)) > 0.0:
				continue
			if blade_position.distance_to(Vector2(enemy["pos"])) <= 22.0 + float(enemy["radius"]) and line_of_sight.call(blade_position, Vector2(enemy["pos"]), 2.0):
				orbit_target_cooldowns[enemy_id] = ORBIT_HIT_COOLDOWN
				output.append({"enemy_id":enemy_id, "damage":definition.value(level), "source":"Orbit Blades"})


func _update_mines(delta: float, origin: Vector2, direction: Vector2, build: VehicleRunBuild, enemies: Array[Dictionary], line_of_sight: Callable, output: Array[Dictionary], effects: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"wake_mines")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		mines.clear()
		return
	if _timer_ready(&"wake_mines", delta, definition.auxiliary(level)):
		mines.append({"pos":origin - direction.normalized() * 48.0, "life":MINE_LIFETIME})
		while mines.size() > definition.cap(level):
			mines.pop_front()
	for index in range(mines.size() - 1, -1, -1):
		var mine: Dictionary = mines[index]
		mine["life"] = float(mine["life"]) - delta
		var detonate := float(mine["life"]) <= 0.0
		if not detonate:
			for enemy in enemies:
				if _eligible(enemy) and Vector2(mine["pos"]).distance_to(Vector2(enemy["pos"])) <= 54.0 + float(enemy["radius"]):
					detonate = true
					break
		if not detonate:
			continue
		var radius := 84.0 + float(level) * 12.0
		for enemy in enemies:
			if _eligible(enemy) and Vector2(mine["pos"]).distance_to(Vector2(enemy["pos"])) <= radius + float(enemy["radius"]) and line_of_sight.call(Vector2(mine["pos"]), Vector2(enemy["pos"]), 3.0):
				output.append({"enemy_id":String(enemy["id"]), "damage":definition.value(level), "source":"Wake Mine"})
		effects.append({"pos":Vector2(mine["pos"]), "radius":radius})
		mines.remove_at(index)


func _update_drone(delta: float, origin: Vector2, build: VehicleRunBuild, enemies: Array[Dictionary], line_of_sight: Callable, output: Array[Dictionary], effects: Array[Dictionary]) -> void:
	var definition: VehicleSecondaryDefinition = definitions.get(&"escort_drone")
	var level := build.level_of(definition.upgrade_id) if definition != null else 0
	if level <= 0:
		drone_position = origin
		return
	var desired := origin + Vector2.RIGHT.rotated(orbit_angle * 0.42) * 92.0
	drone_position = drone_position.lerp(desired, clampf(delta * 8.0, 0.0, 1.0))
	if not _timer_ready(&"escort_drone", delta, definition.auxiliary(level)):
		return
	var best: Dictionary = {}
	var best_distance := 480.0
	for enemy in enemies:
		if not _eligible(enemy):
			continue
		var distance := drone_position.distance_to(Vector2(enemy["pos"]))
		if distance < best_distance and line_of_sight.call(drone_position, Vector2(enemy["pos"]), 3.0):
			best = enemy
			best_distance = distance
	if not best.is_empty():
		output.append({"enemy_id":String(best["id"]), "damage":definition.value(level), "source":"Escort Drone"})
		effects.append({"pos":drone_position, "target":Vector2(best["pos"])})


func _timer_ready(timer_id: StringName, delta: float, interval: float) -> bool:
	var remaining := maxf(0.0, float(timers.get(timer_id, 0.0)) - delta)
	timers[timer_id] = remaining
	if remaining > 0.0:
		return false
	timers[timer_id] = interval
	return true


func _eligible(enemy: Dictionary) -> bool:
	return bool(enemy.get("alive", false)) and bool(enemy.get("active", false))
