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
	elif enemy.role == &"ordinary_pull_01":
		_append_charge(
			enemy,
			SpecialistRuntime.PULL_CHARGE_SPEED * SpecialistRuntime.PULL_CHARGE_ACTIVE,
			SpecialistRuntime.PULL_CHARGE_CONTACT_PADDING,
			SpecialistRuntime.PULL_CHARGE_DAMAGE,
			AttackContract.KINETIC,
			charge_path
		)
	elif enemy.role == &"ordinary_fixed_beam_01":
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
			&"beam",
			SpecialistRuntime.BEAM_WIDTH
		))
		enemy.attack_telegraphs[-1]["beam_growth_seconds"] = (
			AttackContract.EMITTED_BEAM_GROWTH_SECONDS
		)
		enemy.attack_telegraphs[-1]["beam_emission_mode"] = (
			AttackContract.EMITTED_BEAM_FORWARD
		)
		enemy.attack_telegraphs[-1]["active_seconds"] = SpecialistRuntime.BEAM_ACTIVE
	_stamp_threat_tier(
		enemy,
		AttackContract.threat_tier_for(enemy.role, enemy.family_trait)
	)
	update_ordinary_readiness(enemy)


static func update_ordinary_readiness(enemy: EnemyState) -> void:
	if enemy.phase != &"startup":
		return
	_stamp_readiness(
		enemy,
		AttackContract.warning_readiness(
			enemy.phase_time,
			_ordinary_startup_seconds(enemy)
		)
	)


static func refresh_boss(
	enemy: EnemyState,
	pattern: String,
	resolve_path: Callable,
	resolve_charge_path: Callable = Callable(),
	stage_index: int = 0
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
	var damage := BossPatterns.damage(pattern, stage_index)
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
		var offsets: Array = (
			BossPatterns.fan_offsets(stage_index)
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
	elif kind == &"cross_corridors":
		for offset in [-PI * 0.25, PI * 0.25]:
			var axis := Vector2(enemy.committed_dir).rotated(float(offset))
			var from := _resolve_path(
				resolve_path, enemy.pos, -axis, BossPatterns.BEAM_RANGE, BossPatterns.width(pattern, stage_index) * 0.5
			)
			var to := _resolve_path(
				resolve_path, enemy.pos, axis, BossPatterns.BEAM_RANGE, BossPatterns.width(pattern, stage_index) * 0.5
			)
			enemy.attack_telegraphs.append(_corridor(
				from, to,
				BossPatterns.width(pattern, stage_index) * 0.5,
				damage, affinity, &"beam",
				BossPatterns.width(pattern, stage_index)
			))
			enemy.attack_telegraphs[-1]["beam_growth_seconds"] = (
				AttackContract.EMITTED_BEAM_GROWTH_SECONDS
			)
			enemy.attack_telegraphs[-1]["beam_emission_mode"] = (
				AttackContract.EMITTED_BEAM_BIDIRECTIONAL
			)
			enemy.attack_telegraphs[-1]["active_seconds"] = (
				BossPatterns.scaled_active_seconds(pattern, stage_index)
			)
	elif kind == &"broad_barrage":
		for row in BossPatterns.broad_barrage_rows(
			stage_index,
			enemy.committed_dir,
			BossPatterns.barrage_mode_for_stage_index(stage_index)
		):
			var axis := Vector2(row["axis"]).normalized()
			var tangent := axis.rotated(PI * 0.5)
			var count := int(row["count"])
			for shot_index in count:
				var centered := float(shot_index) - float(count - 1) * 0.5
				var direction := axis
				if StringName(row["mode"]) == &"spread":
					var ratio := centered / maxf(1.0, float(count - 1) * 0.5)
					direction = axis.rotated(deg_to_rad(21.0) * ratio)
				var origin := Vector2(enemy.pos) + tangent * float(row["spacing"]) * centered + direction * 72.0
				_append_projectile(
					enemy, origin, direction, float(row["damage"]),
					BossPatterns.projectile_speed(pattern), affinity, resolve_path
				)
				enemy.attack_telegraphs[-1]["row_delay"] = float(row["at"])
	elif kind == &"charge":
		_append_charge(
			enemy,
			BossPatterns.BOSS_CHARGE_SPEED
				* EncounterDirector.ENEMY_SPEED_MULTIPLIER
				* BossPatterns.scaled_active_seconds(pattern, stage_index),
			BossPatterns.BOSS_CONTACT_PADDING,
			damage,
			affinity,
			charge_path
		)
		_append_boss_aimed_burst(enemy, pattern, damage * 0.55, resolve_path)
	elif kind == &"beam":
		_append_hostile_beam_topology(
			enemy,
			pattern,
			stage_index,
			damage,
			affinity,
			resolve_path,
			AttackContract.HOSTILE_BEAM_TOPOLOGIES[
				posmod(enemy.pattern_index - 1, AttackContract.HOSTILE_BEAM_TOPOLOGIES.size())
			]
		)
	elif kind in [&"area", &"pylons"]:
		enemy.attack_telegraphs.append(_area(
			enemy.committed_target,
			BossPatterns.radius(pattern, stage_index),
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
				BossPatterns.radius(pattern, stage_index),
				damage,
				affinity
			))
			_append_boss_aimed_burst(
				enemy, pattern, maxf(12.0, damage * 0.55), resolve_path
			)
		enemy.attack_telegraphs.append({
			"shape":&"support",
			"delivery":&"support",
			"center":Vector2(enemy.pos),
			"radius":112.0,
			"affinity":AttackContract.SUPPORT,
			"damage":0.0,
		})
	_stamp_threat_tier(enemy, AttackContract.THREAT_BOSS)
	_stamp_commit_mode(enemy, BossPatterns.commit_mode(pattern))
	update_boss_readiness(enemy, pattern, stage_index)


static func update_boss_readiness(
	enemy: EnemyState,
	pattern: String,
	stage_index: int = 0
) -> void:
	if enemy.phase != &"boss_startup":
		return
	_stamp_readiness(
		enemy,
		AttackContract.warning_readiness(
			enemy.phase_time,
			BossPatterns.scaled_startup_seconds(pattern, stage_index)
		)
	)


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
		var center := enemy.pos if enemy.role == &"ordinary_fixed_area_01" else enemy.committed_target
		enemy.attack_telegraphs.append(_area(
			center,
			float(attack["radius"]),
			damage,
			affinity
		))
	elif kind == &"support":
		enemy.attack_telegraphs.append({
			"shape":&"support",
			"delivery":&"support",
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
		affinity,
		&"charge"
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


static func _append_hostile_beam_topology(
	enemy: EnemyState,
	pattern: String,
	stage_index: int,
	damage: float,
	affinity: StringName,
	resolve_path: Callable,
	topology: StringName
) -> void:
	var width := BossPatterns.width(pattern, stage_index)
	var axes: Array[Vector2] = []
	var emitters: Array[Vector2] = []
	var emission_mode := AttackContract.EMITTED_BEAM_BIDIRECTIONAL
	if topology == AttackContract.BEAM_TOPOLOGY_PARALLEL:
		emission_mode = AttackContract.EMITTED_BEAM_FORWARD
		var tangent := Vector2(enemy.committed_dir).rotated(PI * 0.5)
		for offset in [-54.0, 54.0]:
			axes.append(Vector2(enemy.committed_dir))
			emitters.append(Vector2(enemy.pos) + tangent * offset)
	elif topology == AttackContract.BEAM_TOPOLOGY_X:
		axes = [
			Vector2(enemy.committed_dir).rotated(-PI * 0.25),
			Vector2(enemy.committed_dir).rotated(PI * 0.25),
		]
		emitters = [Vector2(enemy.pos), Vector2(enemy.pos)]
	else:
		axes = [
			Vector2(enemy.committed_dir),
			Vector2(enemy.committed_dir).rotated(PI * 0.5),
		]
		emitters = [Vector2(enemy.pos), Vector2(enemy.pos)]
	for index in axes.size():
		var axis := axes[index].normalized()
		var emitter := emitters[index]
		var from := emitter
		if emission_mode == AttackContract.EMITTED_BEAM_BIDIRECTIONAL:
			from = _resolve_path(
				resolve_path, emitter, -axis, BossPatterns.BEAM_RANGE,
				BossPatterns.BEAM_COVER_PADDING
			)
		var to := _resolve_path(
			resolve_path, emitter, axis, BossPatterns.BEAM_RANGE,
			BossPatterns.BEAM_COVER_PADDING
		)
		enemy.beam_end = to
		var descriptor := _corridor(
			from, to, AttackContract.beam_danger_half_width(width),
			damage, affinity, &"beam", width
		)
		descriptor["beam_growth_seconds"] = AttackContract.EMITTED_BEAM_GROWTH_SECONDS
		descriptor["beam_emission_mode"] = emission_mode
		descriptor["beam_emitter"] = emitter
		descriptor["beam_topology"] = topology
		descriptor["active_seconds"] = BossPatterns.scaled_active_seconds(pattern, stage_index)
		enemy.attack_telegraphs.append(descriptor)


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
		* AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS
	)
	var to := _resolve_path(resolve_path, origin, direction, distance, radius)
	enemy.attack_telegraphs.append(_corridor(
		origin,
		to,
		AttackContract.projectile_danger_half_width(radius),
		damage,
		affinity,
		&"projectile",
		0.0,
		AttackContract.PROJECTILE_TELEGRAPH_LEAD_SECONDS
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
	delivery: StringName,
	active_width: float = 0.0,
	lead_seconds: float = 0.0
) -> Dictionary:
	return {
		"shape":&"corridor",
		"delivery":delivery,
		"from":from,
		"to":to,
		"half_width":half_width,
		"damage":damage,
		"affinity":AttackContract.normalize_affinity(affinity),
		"active_width":active_width,
		"lead_seconds":lead_seconds,
	}


static func _area(
	center: Vector2,
	radius: float,
	damage: float,
	affinity: StringName
) -> Dictionary:
	return {
		"shape":&"area",
		"delivery":&"area",
		"center":center,
		"radius":radius,
		"damage":damage,
		"affinity":AttackContract.normalize_affinity(affinity),
	}


static func _ordinary_startup_seconds(enemy: EnemyState) -> float:
	var attack := AttackContract.ordinary_attack(enemy.role)
	if not attack.is_empty():
		return float(attack["startup"])
	if enemy.role == &"ordinary_pull_01":
		return SpecialistRuntime.PULL_CHARGE_STARTUP
	if enemy.role == &"ordinary_fixed_beam_01":
		return SpecialistRuntime.BEAM_STARTUP
	return 0.0


static func _stamp_readiness(enemy: EnemyState, readiness: float) -> void:
	var normalized := clampf(readiness, 0.0, 1.0)
	for descriptor in enemy.attack_telegraphs:
		descriptor["readiness"] = normalized


static func _stamp_commit_mode(enemy: EnemyState, commit_mode: StringName) -> void:
	for descriptor in enemy.attack_telegraphs:
		descriptor["commit_mode"] = commit_mode


static func _stamp_threat_tier(enemy: EnemyState, threat_tier: StringName) -> void:
	var normalized := AttackContract.normalize_threat_tier(threat_tier)
	for descriptor in enemy.attack_telegraphs:
		descriptor["threat_tier"] = normalized
