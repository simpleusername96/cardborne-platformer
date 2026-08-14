class_name VehicleGuidebookStatAdapter
extends RefCounted

## Read-only Guidebook projection over gameplay-owned combat values. This file
## owns rounding and row semantics, but no independent balance constants.

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossShieldRuntime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const ContactRuntime = preload("res://scripts/enemies/vehicle_enemy_contact_runtime.gd")
const EliteTraits = preload("res://scripts/enemies/vehicle_elite_trait_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const FieldLayoutGenerator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const MysteryDeviceRuntime = preload("res://scripts/vehicle/vehicle_mystery_device_runtime.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")


static func rows_for(entry: Dictionary, context: Dictionary = {}) -> Array[Dictionary]:
	match StringName(entry.get("entry_kind", &"")):
		&"enemy":
			return enemy_rows(StringName(entry["archetype"]), context)
		&"elite":
			return elite_rows(StringName(entry["elite_trait"]))
		&"boss":
			return boss_rows(int(entry["boss_stage_index"]))
		&"object":
			return object_rows(StringName(entry["object_kind"]), context)
	return []


static func enemy_rows(
	archetype: StringName,
	context: Dictionary = {}
) -> Array[Dictionary]:
	var definition := Archetypes.definition(archetype)
	var active_stage := int(context.get("active_stage_index", -1))
	var rows: Array[Dictionary] = []
	if active_stage >= 0:
		rows.append(_row(
			"GUIDE_STAT_HEALTH", "GUIDE_VALUE_HP",
			[roundi(_enemy_health(archetype, active_stage))], &"health"
		))
	else:
		rows.append(_row(
			"GUIDE_STAT_HEALTH", "GUIDE_VALUE_HP_RANGE",
			[
				roundi(_enemy_health(archetype, 0)),
				roundi(_enemy_health(archetype, 4)),
			], &"health"
		))
	var attack := _enemy_attack(archetype, definition)
	if bool(attack.get("support", false)):
		rows.append(_row(
			"GUIDE_STAT_SUPPORT",
			String(attack["value_key"]),
			Array(attack.get("value_args", [])),
			&"support"
		))
	else:
		var base_damage := float(attack.get("damage", 0.0))
		var attack_range := roundi(float(attack.get("range", 0.0)))
		if active_stage >= 0:
			rows.append(_damage_row(
				_enemy_damage(base_damage, active_stage),
				_enemy_damage(base_damage, active_stage),
				attack_range,
				false
			))
		else:
			rows.append(_damage_row(
				_enemy_damage(base_damage, 0),
				_enemy_damage(base_damage, 4),
				attack_range,
				true
			))
	var base_speed := float(definition["speed"])
	if is_zero_approx(base_speed):
		rows.append(_row(
			"GUIDE_STAT_SPEED", "GUIDE_VALUE_STATIONARY", [], &"speed"
		))
	elif active_stage >= 0:
		rows.append(_row(
			"GUIDE_STAT_SPEED", "GUIDE_VALUE_SPEED",
			[roundi(_enemy_speed(base_speed, active_stage))], &"speed"
		))
	else:
		rows.append(_row(
			"GUIDE_STAT_SPEED", "GUIDE_VALUE_SPEED_RANGE",
			[
				roundi(_enemy_speed(base_speed, 0)),
				roundi(_enemy_speed(base_speed, 4)),
			], &"speed"
		))
	if archetype == &"bulkhead_guard":
		rows.append(_row(
			"GUIDE_STAT_PROTECTION", "GUIDE_VALUE_FRONT_PLATE",
			[roundi(SpecialistRuntime.GUARD_PLATE_STRUCTURE)], &"protection"
		))
	return rows


static func elite_rows(elite_trait: StringName) -> Array[Dictionary]:
	match elite_trait:
		&"armored":
			return [_row(
				"GUIDE_STAT_PROTECTION", "GUIDE_VALUE_ARMOR_SHELL",
				[roundi(EliteTraits.ARMORED_SHELL)], &"protection"
			)]
		&"overclocked":
			return [
				_row("GUIDE_STAT_SPEED", "GUIDE_VALUE_PERCENT_UP", [15], &"speed"),
				_row("GUIDE_STAT_CADENCE", "GUIDE_VALUE_COOLDOWN_DOWN", [15], &"cadence"),
			]
		&"heavy":
			return [
				_row("GUIDE_STAT_HEALTH", "GUIDE_VALUE_PERCENT_UP", [35], &"health"),
				_row("GUIDE_STAT_SIZE", "GUIDE_VALUE_PERCENT_UP", [15], &"coverage"),
				_row("GUIDE_STAT_SPEED", "GUIDE_VALUE_PERCENT_DOWN", [10], &"speed"),
			]
	return []


static func boss_rows(stage_index: int) -> Array[Dictionary]:
	var index := clampi(stage_index, 0, 4)
	var stage_id := StringName("stage_%d" % (index + 1))
	var patterns: Array[String] = BossPatterns.sequence(stage_id, 1)
	for autonomous in BossPatterns.autonomous_sequence(stage_id):
		patterns.append(String(autonomous))
	var minimum_damage := INF
	var maximum_damage := 0.0
	var maximum_radius := 0.0
	for pattern in patterns:
		var damage := BossPatterns.damage(pattern, index)
		if damage > 0.0:
			minimum_damage = minf(minimum_damage, damage)
			maximum_damage = maxf(maximum_damage, damage)
		if BossPatterns.kind(pattern) in [&"area", &"pylons"]:
			maximum_radius = maxf(
				maximum_radius, BossPatterns.radius(pattern, index)
			)
	var cadence_scale := StageDifficulty.boss_cadence_scale(index)
	return [
		_row(
			"GUIDE_STAT_HEALTH", "GUIDE_VALUE_HP",
			[roundi(StageDifficulty.boss_health(index))], &"health"
		),
		_row(
			"GUIDE_STAT_ATTACK_DAMAGE", "GUIDE_VALUE_DAMAGE_RANGE",
			[_one_decimal(minimum_damage), _one_decimal(maximum_damage)], &"damage"
		),
		_row(
			"GUIDE_STAT_BOSS_SHIELD", "GUIDE_VALUE_DAMAGE_REDUCTION",
			[roundi(
				(1.0 - StageDifficulty.boss_shielded_damage_multiplier(index))
				* 100.0
			)], &"protection"
		),
		_row(
			"GUIDE_STAT_EXPOSED", "GUIDE_VALUE_SECONDS",
			[BossShieldRuntime.SHIELD_DOWN_SECONDS], &"window"
		),
		_row(
			"GUIDE_STAT_AUTONOMOUS_CADENCE", "GUIDE_VALUE_SECONDS_RANGE",
			[
				_one_decimal(BossRuntime.AUTONOMOUS_INTERVALS[-1] * cadence_scale),
				_one_decimal(BossRuntime.AUTONOMOUS_INTERVALS[0] * cadence_scale),
			], &"cadence"
		),
		_row(
			"GUIDE_STAT_MAX_COVERAGE", "GUIDE_VALUE_RADIUS",
			[roundi(maximum_radius)], &"coverage"
		),
	]


static func object_rows(
	object_kind: StringName,
	context: Dictionary = {}
) -> Array[Dictionary]:
	match object_kind:
		&"experience":
			return [_row("GUIDE_STAT_EFFECT", "GUIDE_VALUE_EXPERIENCE", [], &"effect")]
		&"repair":
			return [_row(
				"GUIDE_STAT_EFFECT", "GUIDE_VALUE_REPAIR",
				[
					roundi(FieldLayoutGenerator.REPAIR_HEAL_MIN),
					roundi(FieldLayoutGenerator.REPAIR_HEAL_MAX),
				], &"effect"
			)]
		&"recall":
			return [_row("GUIDE_STAT_EFFECT", "GUIDE_VALUE_RECALL", [], &"effect")]
		&"mystery_device":
			var result: Array[Dictionary] = [
				_row(
					"GUIDE_STAT_HEALTH", "GUIDE_VALUE_HP",
					[roundi(MysteryDeviceRuntime.DEVICE_HEALTH)], &"health"
				),
			]
			for outcome in MysteryDeviceRuntime.OUTCOME_IDS:
				var profile := Dictionary(
					MysteryDeviceRuntime.OUTCOME_PROFILE[outcome]
				)
				result.append(_row(
					"MYSTERY_OUTCOME_%s" % String(outcome).to_upper(),
					(
						"GUIDE_VALUE_ANOMALY_WEAKPOINT"
						if outcome == &"weakpoint_expose"
						else "GUIDE_VALUE_ANOMALY_PROFILE"
					),
					[roundi(float(profile["radius"])), float(profile["duration"])],
					&"effect"
				))
			return result
		&"transit_gate":
			return [
				_row(
					"GUIDE_STAT_ACTIVATION", "GUIDE_VALUE_SECONDS",
					[TerrainRuntime.GATE_DWELL], &"activation"
				),
				_row(
					"GUIDE_STAT_COOLDOWN", "GUIDE_VALUE_SECONDS",
					[TerrainRuntime.GATE_COOLDOWN], &"cadence"
				),
			]
	return []


static func _enemy_health(archetype: StringName, stage_index: int) -> float:
	var definition := Archetypes.definition(archetype)
	var class_multiplier := (
		EncounterDirector.ENEMY_HEALTH_MULTIPLIER
		if StringName(definition["health_class"]) in [&"swarm", &"standard"]
		else 1.0
	)
	var curve := StageDifficulty.multipliers(stage_index)
	return (
		float(definition["health"])
		* class_multiplier
		* float(curve["health"])
		* float(curve["ordinary_health_pressure"])
		* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER
		* StageDifficulty.ORDINARY_DURABILITY_MULTIPLIER
	)


static func _enemy_damage(base_damage: float, stage_index: int) -> float:
	var curve := StageDifficulty.multipliers(stage_index)
	return (
		base_damage
		* EncounterDirector.ENEMY_DAMAGE_MULTIPLIER
		* float(curve["damage"])
		* float(curve["ordinary_damage_pressure"])
	)


static func _enemy_speed(base_speed: float, stage_index: int) -> float:
	return (
		base_speed
		* EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER
		* float(StageDifficulty.multipliers(stage_index)["speed"])
	)


static func _enemy_attack(
	archetype: StringName,
	definition: Dictionary
) -> Dictionary:
	match archetype:
		&"spark_minelet":
			return {
				"damage":SpecialistRuntime.MOBILE_MINE_DAMAGE,
				"range":SpecialistRuntime.MOBILE_MINE_RADIUS,
			}
		&"mine":
			return {
				"damage":SpecialistRuntime.STATIC_MINE_DAMAGE,
				"range":SpecialistRuntime.STATIC_MINE_RADIUS,
			}
		&"rammer":
			return {
				"damage":SpecialistRuntime.RAMMER_DAMAGE,
				"range":SpecialistRuntime.RAMMER_SPEED * SpecialistRuntime.RAMMER_ACTIVE,
			}
		&"beam_sentinel":
			return {
				"damage":SpecialistRuntime.BEAM_DAMAGE,
				"range":SpecialistRuntime.BEAM_RANGE,
			}
		&"bulkhead_guard", &"splitter_barge":
			return {
				"damage":ContactRuntime.PERSISTENT_CONTACT_DAMAGE,
				"range":0.0,
			}
		&"shield_escort":
			return {
				"support":true,
				"value_key":"GUIDE_VALUE_SHIELD_SUPPORT",
				"value_args":[
					roundi((1.0 - SpecialistRuntime.SHIELDED_RECEIVED_DAMAGE_MULTIPLIER) * 100.0),
					roundi(SpecialistRuntime.SHIELD_ESCORT_RANGE),
				],
			}
		&"repair_tender":
			return {
				"support":true,
				"value_key":"GUIDE_VALUE_REPAIR_SUPPORT",
				"value_args":[
					roundi(SpecialistRuntime.REPAIR_PER_SECOND),
					roundi(SpecialistRuntime.REPAIR_RANGE),
				],
			}
		&"generator":
			return {
				"support":true,
				"value_key":"GUIDE_VALUE_GENERATOR_SUPPORT",
				"value_args":[
					roundi(SpecialistRuntime.GENERATOR_HEAL_PER_TICK),
					roundi(SpecialistRuntime.GENERATOR_RANGE),
				],
			}
		&"drone_carrier":
			return {
				"support":true,
				"value_key":"GUIDE_VALUE_CARRIER_SUPPORT",
				"value_args":[SpecialistRuntime.CARRIER_CHILD_CAP],
			}
	var attack := AttackContract.ordinary_attack(StringName(definition["behavior"]))
	if attack.is_empty() or float(attack.get("damage", 0.0)) <= 0.0:
		return {"support":true, "value_key":"GUIDE_VALUE_SUPPORT", "value_args":[]}
	var attack_range := 0.0
	match StringName(attack["kind"]):
		&"projectile":
			attack_range = (
				EncounterDirector.effective_hostile_projectile_speed(float(attack["speed"]))
				* AttackContract.HOSTILE_PROJECTILE_LIFETIME
			)
		&"charge":
			attack_range = (
				float(attack["speed"])
				* EncounterDirector.ENEMY_SPEED_MULTIPLIER
				* float(attack["active"])
			)
		&"area":
			attack_range = float(attack["radius"])
	return {"damage":float(attack["damage"]), "range":attack_range}


static func _damage_row(
	minimum: float,
	maximum: float,
	attack_range: int,
	stage_range: bool
) -> Dictionary:
	if stage_range:
		return _row(
			"GUIDE_STAT_ATTACK_DAMAGE",
			"GUIDE_VALUE_DAMAGE_STAGE_RANGE_WITH_RANGE"
				if attack_range > 0 else "GUIDE_VALUE_DAMAGE_RANGE",
			[
				_one_decimal(minimum),
				_one_decimal(maximum),
				attack_range,
			] if attack_range > 0 else [
				_one_decimal(minimum), _one_decimal(maximum),
			],
			&"damage"
		)
	return _row(
		"GUIDE_STAT_ATTACK_DAMAGE",
		"GUIDE_VALUE_DAMAGE_WITH_RANGE" if attack_range > 0 else "GUIDE_VALUE_DAMAGE",
		[_one_decimal(minimum), attack_range]
			if attack_range > 0 else [_one_decimal(minimum)],
		&"damage"
	)


static func _row(
	label_key: String,
	value_key: String,
	value_args: Array,
	semantic: StringName
) -> Dictionary:
	return {
		"label_key":label_key,
		"value_key":value_key,
		"value_args":value_args,
		"semantic":semantic,
	}


static func _one_decimal(value: float) -> float:
	return snappedf(value, 0.1)
