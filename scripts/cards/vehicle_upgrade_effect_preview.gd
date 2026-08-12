class_name VehicleUpgradeEffectPreview
extends RefCounted

## Composes frozen display rows from gameplay-owned rules and definitions.

const PrimaryRules = preload("res://scripts/player/vehicle_primary_upgrade_rules.gd")
const SecondaryCatalog = preload("res://scripts/player/vehicle_secondary_catalog.gd")
const ActiveWeaponCatalog = preload("res://scripts/player/vehicle_active_weapon_catalog.gd")
const OutgoingDamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)
const RecoveryPolicy = preload(
	"res://scripts/player/vehicle_player_recovery_policy.gd"
)
const DashRuntime = preload(
	"res://scripts/player/vehicle_dash_upgrade_runtime.gd"
)

static var _secondary_catalog: RefCounted
static var _active_weapon_catalog: RefCounted


static func rows(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Array[Dictionary]:
	if not definition.modifiers.is_empty():
		return _modifier_rows(definition, current_level)
	match definition.id:
		&"split_muzzle":
			return [
				_row(
					"UPGRADE_EFFECT_PROJECTILES_PER_VOLLEY",
					PrimaryRules.projectiles_per_volley(current_level),
					PrimaryRules.projectiles_per_volley(current_level + 1)
				),
				_row(
					"UPGRADE_EFFECT_TOTAL_VOLLEY_DAMAGE",
					PrimaryRules.total_volley_damage_percent(current_level),
					PrimaryRules.total_volley_damage_percent(current_level + 1),
					"percent"
				),
			]
		&"piercing_rounds":
			return [_row(
				"UPGRADE_EFFECT_ADDITIONAL_PENETRATIONS",
				PrimaryRules.additional_penetrations(current_level),
				PrimaryRules.additional_penetrations(current_level + 1)
			)]
		&"homing_missiles":
			return _seeker_rows(current_level)
		&"electric_field":
			return _optional_secondary_rows(
				definition.id,
				current_level,
				"UPGRADE_EFFECT_DPS",
				"UPGRADE_EFFECT_RADIUS",
				false
			)
		&"orbiting_blades":
			return _optional_secondary_rows(
				definition.id,
				current_level,
				"UPGRADE_EFFECT_DAMAGE_PER_BLADE",
				"UPGRADE_EFFECT_BLADE_COUNT",
				true
			)
		&"drop_mines":
			return _optional_secondary_rows(
				definition.id,
				current_level,
				"UPGRADE_EFFECT_DAMAGE",
				"UPGRADE_EFFECT_DEPLOYMENT_INTERVAL",
				false,
				"seconds"
			)
		&"critical_targeting":
			return [
				_row(
					"UPGRADE_EFFECT_CRITICAL_CHANCE",
					OutgoingDamagePolicy.critical_chance(current_level) * 100.0,
					OutgoingDamagePolicy.critical_chance(current_level + 1) * 100.0,
					"percent"
				),
				_row(
					"UPGRADE_EFFECT_CRITICAL_MULTIPLIER",
					OutgoingDamagePolicy.CRITICAL_MULTIPLIER,
					OutgoingDamagePolicy.CRITICAL_MULTIPLIER
				),
			]
		&"dash_overdrive":
			return [
				_row(
					"UPGRADE_EFFECT_CONDITIONAL_DAMAGE",
					OutgoingDamagePolicy.dash_bonus(current_level) * 100.0,
					OutgoingDamagePolicy.dash_bonus(current_level + 1) * 100.0,
					"percent"
				),
				_row(
					"UPGRADE_EFFECT_DURATION",
					DashRuntime.OVERDRIVE_DURATION,
					DashRuntime.OVERDRIVE_DURATION,
					"seconds"
				),
			]
		&"dash_afterburn_field":
			return [
				_row(
					"UPGRADE_EFFECT_DAMAGE_PER_TICK",
					DashRuntime.damage_per_tick(current_level),
					DashRuntime.damage_per_tick(current_level + 1)
				),
				_row(
					"UPGRADE_EFFECT_DURATION",
					DashRuntime.TRAIL_DURATION,
					DashRuntime.TRAIL_DURATION,
					"seconds"
				),
			]
		&"last_stand_amplifier":
			return [_row(
				"UPGRADE_EFFECT_MAX_DAMAGE_BONUS",
				OutgoingDamagePolicy.crisis_max_bonus(current_level) * 100.0,
				OutgoingDamagePolicy.crisis_max_bonus(current_level + 1) * 100.0,
				"percent"
			)]
		&"overflow_barrier":
			return [
				_row(
					"UPGRADE_EFFECT_OVERFLOW_CONVERSION",
					RecoveryPolicy.conversion_rate(current_level) * 100.0,
					RecoveryPolicy.conversion_rate(current_level + 1) * 100.0,
					"percent"
				),
				_row(
					"UPGRADE_EFFECT_BARRIER_CAP",
					RecoveryPolicy.BARRIER_CAP_RATIOS[clampi(current_level, 0, 3)] * 100.0,
					RecoveryPolicy.BARRIER_CAP_RATIOS[clampi(current_level + 1, 0, 3)] * 100.0,
					"percent"
				),
			]
		&"auto_laser":
			return _optional_secondary_rows(
				definition.id, current_level,
				"UPGRADE_EFFECT_DAMAGE", "UPGRADE_EFFECT_COOLDOWN",
				false, "seconds"
			)
		&"storm_barrage":
			return _optional_secondary_rows(
				definition.id, current_level,
				"UPGRADE_EFFECT_DAMAGE", "UPGRADE_EFFECT_COOLDOWN",
				false, "seconds"
			)
		&"gravity_collapse", &"kinetic_shockwave", &"piercing_lance":
			return _active_weapon_rows(definition.id, current_level)
	return []


static func _modifier_rows(
	definition: VehicleUpgradeDefinition,
	current_level: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for modifier in definition.modifiers:
		result.append({
			"stat_key":"UPGRADE_STAT_%s" % String(modifier.stat_id).to_upper(),
			"operation":modifier.operation,
			"display_unit":modifier.display_unit,
			"current":modifier.display_value_at(current_level),
			"next":modifier.display_value_at(current_level + 1),
			"show_current":current_level > 0 or definition.category != &"element",
			"absolute_value":definition.category == &"element",
		})
		if result.size() >= 2:
			break
	return result


static func _seeker_rows(current_level: int) -> Array[Dictionary]:
	var definition := _secondary_def(&"homing_missiles")
	if definition == null:
		return []
	var current_state := current_level + 1
	var next_state := current_level + 2
	return [
		_row(
			"UPGRADE_EFFECT_MISSILES_PER_VOLLEY",
			definition.cap(current_state),
			definition.cap(next_state)
		),
		_row(
			"UPGRADE_EFFECT_DAMAGE_PER_MISSILE",
			definition.value(current_state),
			definition.value(next_state)
		),
	]


static func _optional_secondary_rows(
	upgrade_id: StringName,
	current_level: int,
	value_key: String,
	auxiliary_key: String,
	auxiliary_first: bool,
	auxiliary_unit: String = "none"
) -> Array[Dictionary]:
	var definition := _secondary_def(upgrade_id)
	if definition == null:
		return []
	var current_state := maxi(1, current_level)
	var next_state := current_level + 1
	var show_current := current_level > 0
	var value_row := _row(
		value_key,
		definition.value(current_state),
		definition.value(next_state),
		"none",
		show_current
	)
	var auxiliary_row := _row(
		auxiliary_key,
		definition.cap(current_state) if auxiliary_first else definition.auxiliary(current_state),
		definition.cap(next_state) if auxiliary_first else definition.auxiliary(next_state),
		auxiliary_unit,
		show_current
	)
	return [auxiliary_row, value_row] if auxiliary_first else [value_row, auxiliary_row]


static func _secondary_def(upgrade_id: StringName) -> VehicleSecondaryDefinition:
	if _secondary_catalog == null:
		_secondary_catalog = SecondaryCatalog.new()
	return _secondary_catalog.get_by_upgrade_id(upgrade_id)


static func _active_weapon_rows(
	upgrade_id: StringName,
	current_level: int
) -> Array[Dictionary]:
	if _active_weapon_catalog == null:
		_active_weapon_catalog = ActiveWeaponCatalog.new()
	var active_id := StringName({
		&"gravity_collapse":&"black_hole",
		&"kinetic_shockwave":&"shockwave",
		&"piercing_lance":&"cross_beam",
	}.get(upgrade_id, &""))
	var active: VehicleActiveWeaponDefinition = (
		_active_weapon_catalog.get_definition(active_id)
	)
	if active == null:
		return []
	var current_state := maxi(1, current_level)
	var next_state := current_level + 1
	return [
		_row(
			"UPGRADE_EFFECT_DAMAGE",
			active.damage(current_state),
			active.damage(next_state),
			"none",
			current_level > 0
		),
		_row(
			"UPGRADE_EFFECT_HALF_WIDTH"
				if active_id == &"cross_beam"
				else "UPGRADE_EFFECT_RADIUS",
			active.size(current_state),
			active.size(next_state),
			"none",
			current_level > 0
		),
	]


static func _row(
	stat_key: String,
	current_value: float,
	next_value: float,
	display_unit: String = "none",
	show_current: bool = true
) -> Dictionary:
	return {
		"stat_key":stat_key,
		"operation":"add",
		"display_unit":display_unit,
		"current":current_value,
		"next":next_value,
		"show_current":show_current,
		"absolute_value":true,
	}
