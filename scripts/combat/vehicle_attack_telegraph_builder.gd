class_name VehicleAttackTelegraphBuilder
extends RefCounted

## Builds presentation descriptors from the same values used by combat. The
## supplied path resolver clips corridors against the current run's blockers.

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")


static func refresh_ordinary(
	enemy: EnemyState,
	resolve_path: Callable,
	resolve_charge_path: Callable = Callable()
) -> void:
	enemy.attack_telegraphs.clear()
	if enemy.phase != &"startup":
		return
	var charge_path := (
		resolve_charge_path
		if resolve_charge_path.is_valid()
		else resolve_path
	)
	var attack := AttackContract.ordinary_attack(enemy.role)
	if not attack.is_empty():
		_append_ordinary_attack(enemy, attack, resolve_path, charge_path)
		return
	if enemy.role == &"rammer":
		_append_charge(
			enemy,
			SpecialistRuntime.RAMMER_SPEED * SpecialistRuntime.RAMMER_ACTIVE,
			SpecialistRuntime.RAMMER_CONTACT_PADDING,
			SpecialistRuntime.RAMMER_DAMAGE,
			AttackContract.KINETIC,
			charge_path
		)
	elif enemy.role == &"beam_sentinel":
		var to := _resolve_path(
			resolve_path,
			enemy.pos,
			enemy.committed_dir,
			SpecialistRuntime.BEAM_RANGE,
			SpecialistRuntime.BEAM_COVER_PADDING
		)
		enemy.beam_end = to
		enemy.attack_telegraphs.append(_corridor(
			enemy.pos,
			to,
			AttackContract.beam_danger_half_width(SpecialistRuntime.BEAM_WIDTH),
			SpecialistRuntime.BEAM_DAMAGE,
			AttackContract.ARC,
			SpecialistRuntime.BEAM_WIDTH
		))


static func refresh_boss(
	enemy: EnemyState,
	pattern: String,
	resolve_path: Callable,
	resolve_charge_path: Callable = Callable()
) -> void:
	enemy.attack_telegraphs.clear()
	if enemy.phase != &"boss_startup":
		return
	var charge_path := (
		resolve_charge_path
		if resolve_charge_path.is_valid()
		else resolve_path
	)
	var kind := BossPatterns.kind(pattern)
	var affinity := BossPatterns.affinity(pattern)
	var damage := BossPatterns.damage(pattern)
	if kind == &"lanes":
		var direction := Vector2(enemy.committed_dir)
		var tangent := direction.rotated(PI * 0.5)
		for lane_offset in enemy.lane_centers:
			var origin := Vector2(enemy.pos) + direction * 86.0 + tangent * float(lane_offset)
			_append_projectile(
				enemy, origin, direction, damage, BossPatterns.projectile_speed(pattern),
				affinity, resolve_path
			)
	elif kind in [&"fan", &"cross"]:
		var offsets := (
			[-0.34, -0.17, 0.0, 0.17, 0.34]
			if kind == &"fan"
			else [0.0, PI * 0.5, PI, PI * 1.5]
		)
		for offset in offsets:
			var direction := Vector2(enemy.committed_dir).rotated(float(offset))
			_append_projectile(
				enemy,
				Vector2(enemy.pos) + direction * 72.0,
				direction,
				damage,
				BossPatterns.projectile_speed(pattern),
				affinity,
				resolve_path
			)
	elif kind == &"charge":
		_append_charge(
			enemy,
			BossPatterns.BOSS_CHARGE_SPEED
				* EncounterDirector.ENEMY_SPEED_MULTIPLIER
				* BossPatterns.active_seconds(pattern),
			BossPatterns.BOSS_CONTACT_PADDING,
			damage,
			affinity,
			charge_path
		)
		_append_boss_aimed_burst(enemy, pattern, damage * 0.55, resolve_path)
	elif kind == &"beam":
		var to := _resolve_path(
			resolve_path,
			enemy.pos,
			enemy.committed_dir,
			BossPatterns.BEAM_RANGE,
			BossPatterns.BEAM_COVER_PADDING
		)
		enemy.beam_end = to
		enemy.attack_telegraphs.append(_corridor(
			enemy.pos,
			to,
			AttackContract.beam_danger_half_width(BossPatterns.width(pattern)),
			damage,
			affinity,
			BossPatterns.width(pattern)
		))
	elif kind in [&"area", &"pylons"]:
		enemy.attack_telegraphs.append(_area(
			enemy.committed_target,
			BossPatterns.radius(pattern),
			damage,
			affinity
		))
		_append_boss_aimed_burst(
			enemy, pattern, maxf(12.0, damage * 0.55), resolve_path
		)
	elif kind == &"summon":
		if damage > 0.0:
			enemy.attack_telegraphs.append(_area(
				enemy.committed_target,
				BossPatterns.radius(pattern),
				damage,
				affinity
			))
			_append_boss_aimed_burst(
				enemy, pattern, maxf(12.0, damage * 0.55), resolve_path
			)
		enemy.attack_telegraphs.append({
			"shape":&"support",
			"center":Vector2(enemy.pos),
			"radius":112.0,
			"affinity":AttackContract.SUPPORT,
			"damage":0.0,
		})


static func _append_ordinary_attack(
	enemy: EnemyState,
	attack: Dictionary,
	resolve_path: Callable,
	resolve_charge_path: Callable
) -> void:
	var kind := StringName(attack["kind"])
	var affinity := StringName(attack["affinity"])
	var damage := float(attack["damage"])
	if kind == &"projectile":
		var direction := Vector2(enemy.committed_dir)
		var origin := Vector2(enemy.pos) + direction * float(attack["origin_offset"])
		_append_projectile(
			enemy,
			origin,
			direction,
			damage,
			float(attack["speed"]),
			affinity,
			resolve_path
		)
	elif kind == &"charge":
		_append_charge(
			enemy,
			float(attack["speed"]) * float(attack["active"])
				* EncounterDirector.ENEMY_SPEED_MULTIPLIER,
			float(attack["contact_padding"]),
			damage,
			affinity,
			resolve_charge_path
		)
	elif kind == &"area":
		var center := enemy.pos if enemy.role == &"mine" else enemy.committed_target
		enemy.attack_telegraphs.append(_area(
			center,
			float(attack["radius"]),
			damage,
			affinity
		))
	elif kind == &"support":
		enemy.attack_telegraphs.append({
			"shape":&"support",
			"center":Vector2(enemy.pos),
			"radius":float(attack["radius"]),
			"affinity":AttackContract.SUPPORT,
			"damage":0.0,
		})


static func _append_charge(
	enemy: EnemyState,
	distance: float,
	contact_padding: float,
	damage: float,
	affinity: StringName,
	resolve_path: Callable
) -> void:
	var to := _resolve_path(
		resolve_path,
		enemy.pos,
		enemy.committed_dir,
		distance,
		enemy.radius
	)
	enemy.attack_telegraphs.append(_corridor(
		enemy.pos,
		to,
		AttackContract.contact_danger_half_width(enemy.radius, contact_padding),
		damage,
		affinity
	))


static func _append_boss_aimed_burst(
	enemy: EnemyState,
	pattern: String,
	damage: float,
	resolve_path: Callable
) -> void:
	for offset in [-0.13, 0.0, 0.13]:
		var direction := Vector2(enemy.committed_dir).rotated(float(offset))
		_append_projectile(
			enemy,
			Vector2(enemy.pos) + direction * 76.0,
			direction,
			damage,
			BossPatterns.projectile_speed(pattern),
			BossPatterns.affinity(pattern),
			resolve_path
		)


static func _append_projectile(
	enemy: EnemyState,
	origin: Vector2,
	direction: Vector2,
	damage: float,
	base_speed: float,
	affinity: StringName,
	resolve_path: Callable
) -> void:
	var radius := AttackContract.hostile_projectile_radius(damage)
	var distance := (
		EncounterDirector.effective_hostile_projectile_speed(base_speed)
		* AttackContract.HOSTILE_PROJECTILE_LIFETIME
	)
	var to := _resolve_path(resolve_path, origin, direction, distance, radius)
	enemy.attack_telegraphs.append(_corridor(
		origin,
		to,
		AttackContract.projectile_danger_half_width(radius),
		damage,
		affinity
	))


static func _resolve_path(
	resolve_path: Callable,
	origin: Vector2,
	direction: Vector2,
	distance: float,
	padding: float
) -> Vector2:
	return Vector2(resolve_path.call(
		origin,
		direction.normalized(),
		maxf(0.0, distance),
		maxf(0.0, padding)
	))


static func _corridor(
	from: Vector2,
	to: Vector2,
	half_width: float,
	damage: float,
	affinity: StringName,
	active_width: float = 0.0
) -> Dictionary:
	return {
		"shape":&"corridor",
		"from":from,
		"to":to,
		"half_width":half_width,
		"damage":damage,
		"affinity":AttackContract.normalize_affinity(affinity),
		"active_width":active_width,
	}


static func _area(
	center: Vector2,
	radius: float,
	damage: float,
	affinity: StringName
) -> Dictionary:
	return {
		"shape":&"area",
		"center":center,
		"radius":radius,
		"damage":damage,
		"affinity":AttackContract.normalize_affinity(affinity),
	}
