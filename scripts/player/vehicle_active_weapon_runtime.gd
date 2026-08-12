class_name VehicleActiveWeaponRuntime
extends RefCounted

## Owns the equipped active weapon's bounded cooldown and phase state. VehicleRun
## consumes the emitted gameplay events so enemy and projectile mutation stay with
## their existing owners.

const BLACK_HOLE_PULL_INTERVAL := 0.1
const BLACK_HOLE_AIM_DISTANCE := 480.0
const RELEASE_VISUAL_SECONDS := 0.18

var catalog := VehicleActiveWeaponCatalog.new()
var equipped_id: StringName = &"emp"
var cooldown_remaining := 0.0
var startup_remaining := 0.0
var active_remaining := 0.0
var release_visual_remaining := 0.0
var pull_tick_remaining := 0.0
var center := Vector2.ZERO
var direction := Vector2.RIGHT
var level := 1
var damage := 0.0
var size := 0.0
var action_serial := 0


func reset(player_position: Vector2 = Vector2.ZERO) -> void:
	equipped_id = &"emp"
	cooldown_remaining = 0.0
	startup_remaining = 0.0
	active_remaining = 0.0
	release_visual_remaining = 0.0
	pull_tick_remaining = 0.0
	center = player_position
	direction = Vector2.RIGHT
	level = 1
	damage = 0.0
	size = 0.0
	action_serial = 0


func configure(build: VehicleRunBuild) -> void:
	var next_id := build.active_weapon_id()
	if next_id == equipped_id:
		return
	equipped_id = next_id
	cooldown_remaining = 0.0
	startup_remaining = 0.0
	active_remaining = 0.0
	release_visual_remaining = 0.0
	pull_tick_remaining = 0.0


func try_start(
	player_position: Vector2,
	aim_direction: Vector2,
	play_bounds: Rect2,
	build: VehicleRunBuild,
	emp_relay_reduction := 0.0
) -> Dictionary:
	configure(build)
	if not is_ready():
		return {"started":false}
	var definition := catalog.get_definition(equipped_id)
	if definition == null:
		return {"started":false}
	level = 1 if equipped_id == &"emp" else maxi(1, build.level_of(definition.upgrade_id))
	direction = aim_direction.normalized() if aim_direction.length_squared() > 0.0001 else Vector2.RIGHT
	center = player_position
	if equipped_id == &"black_hole":
		var target := player_position + direction * BLACK_HOLE_AIM_DISTANCE
		var inset := definition.size(level)
		center = Vector2(
			clampf(target.x, play_bounds.position.x + inset, play_bounds.end.x - inset),
			clampf(target.y, play_bounds.position.y + inset, play_bounds.end.y - inset)
		)
	damage = definition.damage(level) * build.stat(&"active_damage_multiplier", 1.0)
	size = definition.size(level)
	startup_remaining = definition.startup_seconds
	active_remaining = 0.0
	release_visual_remaining = 0.0
	pull_tick_remaining = BLACK_HOLE_PULL_INTERVAL
	var base_cooldown := definition.cooldown_seconds
	if equipped_id == &"emp":
		base_cooldown = maxf(0.0, base_cooldown - emp_relay_reduction)
	cooldown_remaining = base_cooldown * build.stat(&"active_cooldown_multiplier", 1.0)
	action_serial += 1
	return {
		"started":true,
		"weapon_id":equipped_id,
		"startup":startup_remaining,
		"center":center,
		"direction":direction,
		"size":size,
		"auxiliary_size":definition.auxiliary_size,
	}


func advance(delta: float, build: VehicleRunBuild) -> Dictionary:
	configure(build)
	var result := {
		"released":false,
		"collapse":false,
		"pull_steps":0,
	}
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	release_visual_remaining = maxf(0.0, release_visual_remaining - delta)
	var released_this_step := false
	if startup_remaining > 0.0:
		startup_remaining = maxf(0.0, startup_remaining - delta)
		if startup_remaining <= 0.0:
			if equipped_id == &"black_hole":
				var definition := catalog.get_definition(equipped_id)
				active_remaining = definition.active_seconds if definition != null else 0.0
			else:
				result["released"] = true
				release_visual_remaining = RELEASE_VISUAL_SECONDS
			released_this_step = true
	if equipped_id == &"black_hole" and active_remaining > 0.0 and not released_this_step:
		var active_delta := minf(delta, active_remaining)
		active_remaining = maxf(0.0, active_remaining - active_delta)
		pull_tick_remaining -= active_delta
		while pull_tick_remaining <= 0.000001:
			result["pull_steps"] = int(result["pull_steps"]) + 1
			pull_tick_remaining += BLACK_HOLE_PULL_INTERVAL
		if active_remaining <= 0.0:
			result["collapse"] = true
			release_visual_remaining = RELEASE_VISUAL_SECONDS
	return result


func is_ready() -> bool:
	return cooldown_remaining <= 0.0 and startup_remaining <= 0.0 and active_remaining <= 0.0


func cooldown_max(build: VehicleRunBuild, emp_relay_reduction := 0.0) -> float:
	configure(build)
	var definition := catalog.get_definition(equipped_id)
	if definition == null:
		return 0.0
	var base := definition.cooldown_seconds
	if equipped_id == &"emp":
		base = maxf(0.0, base - emp_relay_reduction)
	return base * build.stat(&"active_cooldown_multiplier", 1.0)


func snapshot(build: VehicleRunBuild, emp_relay_reduction := 0.0) -> Dictionary:
	configure(build)
	var definition := catalog.get_definition(equipped_id)
	var current_level := (
		1
		if equipped_id == &"emp" or definition == null
		else maxi(1, build.level_of(definition.upgrade_id))
	)
	var current_damage := (
		definition.damage(current_level) * build.stat(&"active_damage_multiplier", 1.0)
		if definition != null
		else 0.0
	)
	var current_size := definition.size(current_level) if definition != null else 0.0
	return {
		"weapon_id":equipped_id,
		"available":is_ready(),
		"remaining":maxf(cooldown_remaining, startup_remaining),
		"cooldown_max":cooldown_max(build, emp_relay_reduction),
		"startup_remaining":startup_remaining,
		"active_remaining":active_remaining,
		"release_remaining":release_visual_remaining,
		"center":center,
		"direction":direction,
		"damage":current_damage,
		"size":current_size,
		"auxiliary_size":definition.auxiliary_size if definition != null else 0.0,
		"level":current_level,
		"action_serial":action_serial,
	}
