class_name VehicleGuidebookStatAdapter
extends RefCounted

## Read-only Guidebook projection over gameplay-owned combat values. This file
## owns rounding and row semantics, but no independent balance constants.

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const BossPhaseCatalog = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const BossRuntime = preload("res://scripts/bosses/vehicle_boss_runtime.gd")
const BossShieldRuntime = preload("res://scripts/bosses/vehicle_boss_shield_runtime.gd")
const ContactRuntime = preload("res://scripts/enemies/vehicle_enemy_contact_runtime.gd")
const FamilyTraits = preload(
	"res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd"
)
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const EnemyUpgradeDeviceRuntime = preload(
	"res://scripts/vehicle/vehicle_enemy_upgrade_device_runtime.gd"
)
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const TerrainRuntime = preload("res://scripts/vehicle/vehicle_terrain_runtime.gd")


static func rows_for(entry: Dictionary, context: Dictionary = {}) -> Array[Dictionary]:
	match StringName(entry.get("entry_kind", &"")):
		&"enemy":
			return enemy_rows(StringName(entry["archetype"]), context)
		&"trait":
			return trait_rows(StringName(entry["family_trait"]))
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
	var final_stage := StageDifficulty.HEALTH.size() - 1
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
				roundi(_enemy_health(archetype, final_stage)),
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
				_enemy_damage(base_damage, final_stage),
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
				roundi(_enemy_speed(base_speed, final_stage)),
			], &"speed"
		))
	if StringName(definition.get("family", &"")) == &"defender":
		rows.append(_row(
			"GUIDE_STAT_PROTECTION", "GUIDE_VALUE_FRONT_PLATE",
			[roundi(SpecialistRuntime.GUARD_PLATE_STRUCTURE)], &"protection"
		))
	return rows


static func trait_rows(family_trait: StringName) -> Array[Dictionary]:
	var value_key := "GUIDE_VALUE_TRAIT_%s" % String(family_trait).to_upper()
	var value_args: Array = []
	match family_trait:
		&"frenzy":
			value_args = [
				roundi((FamilyTraits.FRENZY_SPEED_MULTIPLIER - 1.0) * 100.0),
				roundi((1.0 - FamilyTraits.FRENZY_CADENCE_MULTIPLIER) * 100.0),
			]
		&"slow":
			value_args = [
				roundi((1.0 - FamilyTraits.SLOW_MOVEMENT_MULTIPLIER) * 100.0),
				FamilyTraits.SLOW_DURATION,
			]
		&"bulwark":
			value_args = [
				FamilyTraits.BULWARK_INTERVAL,
				FamilyTraits.BULWARK_ACTIVE_DURATION,
				roundi(FamilyTraits.BULWARK_RADIUS),
				FamilyTraits.BULWARK_VISUAL_PERCENT,
			]
		&"reflector":
			value_args = [
				FamilyTraits.REFLECTOR_INTERVAL,
				FamilyTraits.REFLECTOR_ACTIVE_DURATION,
			]
		&"blink":
			value_args = [
				FamilyTraits.BLINK_INTERVAL,
				FamilyTraits.BLINK_WARNING_DURATION,
			]
		&"pack_feed":
			value_args = [
				roundi(FamilyTraits.PACK_FEED_HEAL_RATIO * 100.0),
				roundi(FamilyTraits.PACK_FEED_DAMAGE_PER_STACK * 100.0),
				roundi(FamilyTraits.PACK_FEED_SPEED_PER_STACK * 100.0),
				FamilyTraits.PACK_FEED_MAX_STACKS,
			]
	return [_row("GUIDE_STAT_EFFECT", value_key, value_args, &"effect")]


static func boss_rows(stage_index: int) -> Array[Dictionary]:
	if stage_index < 0 or stage_index >= BossProfiles.PROFILES.size():
		return []
	var index := stage_index
	var stage_id := StringName("stage_%d" % (index + 1))
	var patterns: Array[String] = BossPatterns.sequence(stage_id, 1)
	for autonomous in BossPatterns.autonomous_sequence(stage_id):
		patterns.append(String(autonomous))
	if patterns.is_empty():
		return []
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
	var profile := BossProfiles.profile(index)
	var intervals: Array = profile["autonomous_intervals"]
	var rows: Array[Dictionary] = [
		_row(
			"GUIDE_STAT_HEALTH", "GUIDE_VALUE_HP",
			[roundi(float(profile["health"]))], &"health"
		),
		_row(
			"GUIDE_STAT_ATTACK_DAMAGE", "GUIDE_VALUE_DAMAGE_RANGE",
			[_one_decimal(minimum_damage), _one_decimal(maximum_damage)], &"damage"
		),
		_row(
			"GUIDE_STAT_AUTONOMOUS_CADENCE", "GUIDE_VALUE_SECONDS_RANGE",
			[
				_one_decimal(float(intervals[-1])),
				_one_decimal(float(intervals[0])),
			], &"cadence"
		),
	]
	if maximum_radius > 0.0:
		rows.append(_row(
			"GUIDE_STAT_MAX_COVERAGE", "GUIDE_VALUE_RADIUS",
			[roundi(maximum_radius)], &"coverage"
		))
	if BossPhaseCatalog.uses_shield(stage_id):
		var defense := BossPhaseCatalog.defense_profile(stage_id)
		if BossPhaseCatalog.defense_effect(stage_id) == &"guard":
			var reduction_percent := roundi(
				(1.0 - float(defense.get("blocked_damage_multiplier", 1.0))) * 100.0
			)
			rows.insert(2, _row(
				"GUIDE_STAT_BOSS_SHIELD", "GUIDE_VALUE_DAMAGE_REDUCTION",
				[reduction_percent], &"protection"
			))
		rows.insert(3, _row(
			"GUIDE_STAT_EXPOSED", "GUIDE_VALUE_SECONDS",
			[float(defense.get("down_seconds", 0.0))], &"window"
		))
	return rows


static func object_rows(
	object_kind: StringName,
	context: Dictionary = {}
) -> Array[Dictionary]:
	match object_kind:
		&"experience":
			return [_row("GUIDE_STAT_EFFECT", "GUIDE_VALUE_EXPERIENCE", [], &"effect")]
		&"recall":
			return [_row("GUIDE_STAT_EFFECT", "GUIDE_VALUE_RECALL", [], &"effect")]
		&"mystery_device":
			return [
				_row(
					"GUIDE_STAT_HEALTH", "GUIDE_VALUE_HP",
					[roundi(EnemyUpgradeDeviceRuntime.BASE_HEALTH)], &"health"
				),
				_row(
					"GUIDE_STAT_DEVICE_CHANNEL", "GUIDE_VALUE_DEVICE_CHANNEL",
					[
						EnemyUpgradeDeviceRuntime.REQUIRED_ENEMY_COUNT,
						EnemyUpgradeDeviceRuntime.CAPTURE_SECONDS,
						roundi(EnemyUpgradeDeviceRuntime.CAPTURE_RADIUS),
					],
					&"activation"
				),
				_row(
					"GUIDE_STAT_FUTURE_ENEMY_HEALTH", "GUIDE_VALUE_HP_BONUS",
					[roundi(EnemyUpgradeDeviceRuntime.HEALTH_BONUS_PER_ACTIVATION)],
					&"health"
				),
				_row(
					"GUIDE_STAT_FUTURE_ENEMY_DAMAGE", "GUIDE_VALUE_PERCENT_UP",
					[roundi(EnemyUpgradeDeviceRuntime.DAMAGE_MULTIPLIER_PER_ACTIVATION * 100.0)],
					&"effect"
				),
				_row(
					"GUIDE_STAT_FUTURE_ENEMY_SPEED", "GUIDE_VALUE_SPEED_BONUS",
					[roundi(EnemyUpgradeDeviceRuntime.SPEED_BONUS_PER_ACTIVATION)],
					&"effect"
				),
			]
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
	return (
		float(definition["health"])
		* class_multiplier
		* StageDifficulty.ordinary_health_multiplier(stage_index)
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
	var behavior := StringName(definition.get("behavior", &""))
	match behavior:
		&"ordinary_pull_01":
			return {
				"damage":SpecialistRuntime.PULL_CHARGE_DAMAGE,
				"range":SpecialistRuntime.PULL_CHARGE_SPEED * SpecialistRuntime.PULL_CHARGE_ACTIVE,
			}
		&"ordinary_fixed_beam_01":
			return {
				"damage":SpecialistRuntime.BEAM_DAMAGE,
				"range":SpecialistRuntime.BEAM_RANGE,
			}
		&"ordinary_shield_01":
			return {
				"damage":ContactRuntime.PERSISTENT_CONTACT_DAMAGE,
				"range":0.0,
			}
	var attack := AttackContract.ordinary_attack(behavior)
	if attack.is_empty() or float(attack.get("damage", 0.0)) <= 0.0:
		return {"support":true, "value_key":"GUIDE_VALUE_SUPPORT", "value_args":[]}
	var attack_range := 0.0
	match StringName(attack["kind"]):
		&"projectile":
			attack_range = float(attack.get(
				"range",
				EncounterDirector.effective_hostile_projectile_speed(float(attack["speed"]))
					* AttackContract.HOSTILE_PROJECTILE_LIFETIME
			))
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
