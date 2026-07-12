class_name ResolvedEnemySpec
extends RefCounted

var _catalog_content_version: int = 0
var _archetype_content_version: int = 0
var _variant_content_version: int = 0
var _tuning_profile_content_version: int = 0
var _archetype_id: StringName
var _variant_id: StringName
var _stage_id: StringName
var _tuning_profile_id: StringName
var _display_name: String
var _tags: PackedStringArray = PackedStringArray()

var _behavior_owner: StringName
var _pressure_roles: PackedStringArray = PackedStringArray()
var _tell_contract: String
var _response_contract: String
var _punish_contract: String

var _minimum_support_width: float = 0.0
var _minimum_lane_width: float = 0.0
var _minimum_arc_clearance: float = 0.0
var _requires_patrol_turn_points: bool = false
var _requires_escape_route: bool = false
var _allows_wall_stop_lane: bool = false
var _room_requirement_tags: PackedStringArray = PackedStringArray()
var _minimum_warning_time: float = 0.0
var _minimum_recovery_time: float = 0.0
var _maximum_damage: int = 0

var _health: int = 0
var _damage: int = 0
var _move_speed: float = 0.0
var _warning_time: float = 0.0
var _active_time: float = 0.0
var _recovery_time: float = 0.0
var _charge_speed: float = 0.0
var _cadence_time: float = 0.0
var _projectile_speed: float = 0.0
var _attack_range: float = 0.0
var _active_projectile_cap: int = 0
var _stagger_capacity: int = 0

var _presentation_key: StringName
var _presentation_description: String
var _tuning_trait: StringName
var _budget_cost: int = 0
var _drop_source_id: StringName

# Every public property is getter-only. Collection getters create fresh copies.
var id: StringName:
	get:
		return _variant_id
var content_version: int:
	get:
		return _catalog_content_version
var catalog_content_version: int:
	get:
		return _catalog_content_version
var archetype_content_version: int:
	get:
		return _archetype_content_version
var variant_content_version: int:
	get:
		return _variant_content_version
var tuning_profile_content_version: int:
	get:
		return _tuning_profile_content_version
var archetype_id: StringName:
	get:
		return _archetype_id
var variant_id: StringName:
	get:
		return _variant_id
var stage_id: StringName:
	get:
		return _stage_id
var tuning_profile_id: StringName:
	get:
		return _tuning_profile_id
var display_name: String:
	get:
		return _display_name
var tags: PackedStringArray:
	get:
		return _tags.duplicate()

var behavior_owner: StringName:
	get:
		return _behavior_owner
var pressure_roles: PackedStringArray:
	get:
		return _pressure_roles.duplicate()
var tell_contract: String:
	get:
		return _tell_contract
var response_contract: String:
	get:
		return _response_contract
var punish_contract: String:
	get:
		return _punish_contract

var health: int:
	get:
		return _health
var damage: int:
	get:
		return _damage
var move_speed: float:
	get:
		return _move_speed
var warning_time: float:
	get:
		return _warning_time
var active_time: float:
	get:
		return _active_time
var recovery_time: float:
	get:
		return _recovery_time
var charge_speed: float:
	get:
		return _charge_speed
var cadence_time: float:
	get:
		return _cadence_time
var projectile_speed: float:
	get:
		return _projectile_speed
var attack_range: float:
	get:
		return _attack_range
var active_projectile_cap: int:
	get:
		return _active_projectile_cap
var stagger_capacity: int:
	get:
		return _stagger_capacity
var exact_stats: Dictionary:
	get:
		return get_exact_stats()

var presentation_key: StringName:
	get:
		return _presentation_key
var presentation_description: String:
	get:
		return _presentation_description
var tuning_trait: StringName:
	get:
		return _tuning_trait
var budget_cost: int:
	get:
		return _budget_cost
var drop_source_id: StringName:
	get:
		return _drop_source_id
var room_requirements: Dictionary:
	get:
		return get_room_requirements()
var safety_bounds: Dictionary:
	get:
		return get_safety_bounds()


func _init(
	archetype: EnemyArchetypeDefinition = null,
	variant: EnemyVariantDefinition = null,
	tuning_profile: EnemyTuningProfile = null,
	catalog_version: int = 0
) -> void:
	if archetype == null or variant == null or tuning_profile == null:
		return

	_catalog_content_version = catalog_version
	_archetype_content_version = archetype.content_version
	_variant_content_version = variant.content_version
	_tuning_profile_content_version = tuning_profile.content_version
	_archetype_id = archetype.id
	_variant_id = variant.id
	_stage_id = variant.stage_id
	_tuning_profile_id = tuning_profile.id
	_display_name = variant.display_name
	_tags = _merge_string_names(archetype.tags, variant.tags)

	_behavior_owner = archetype.behavior_owner
	_pressure_roles = _pack_string_names(archetype.pressure_roles)
	_tell_contract = archetype.tell_contract
	_response_contract = archetype.response_contract
	_punish_contract = archetype.punish_contract

	_minimum_support_width = archetype.minimum_support_width
	_minimum_lane_width = archetype.minimum_lane_width
	_minimum_arc_clearance = archetype.minimum_arc_clearance
	_requires_patrol_turn_points = archetype.requires_patrol_turn_points
	_requires_escape_route = archetype.requires_escape_route
	_allows_wall_stop_lane = archetype.allows_wall_stop_lane
	_room_requirement_tags = _pack_string_names(archetype.room_requirement_tags)
	_minimum_warning_time = archetype.minimum_warning_time
	_minimum_recovery_time = archetype.minimum_recovery_time
	_maximum_damage = archetype.maximum_damage

	# Exact values are copied verbatim. Tuning ratios never participate in resolution.
	_health = variant.health
	_damage = variant.damage
	_move_speed = variant.move_speed
	_warning_time = variant.warning_time
	_active_time = variant.active_time
	_recovery_time = variant.recovery_time
	_charge_speed = variant.charge_speed
	_cadence_time = variant.cadence_time
	_projectile_speed = variant.projectile_speed
	_attack_range = variant.attack_range
	_active_projectile_cap = variant.active_projectile_cap
	_stagger_capacity = variant.stagger_capacity

	_presentation_key = variant.presentation_key
	_presentation_description = variant.presentation_description
	_tuning_trait = variant.tuning_trait
	_budget_cost = variant.budget_cost
	_drop_source_id = variant.drop_source_id


static func from_definitions(
	archetype: EnemyArchetypeDefinition,
	variant: EnemyVariantDefinition,
	tuning_profile: EnemyTuningProfile,
	catalog_version: int
) -> ResolvedEnemySpec:
	return ResolvedEnemySpec.new(archetype, variant, tuning_profile, catalog_version)


func get_exact_stats() -> Dictionary:
	return {
		"health": _health,
		"damage": _damage,
		"move_speed": _move_speed,
		"warning": _warning_time,
		"active": _active_time,
		"recovery": _recovery_time,
		"charge_speed": _charge_speed,
		"cadence": _cadence_time,
		"projectile_speed": _projectile_speed,
		"attack_range": _attack_range,
		"active_projectile_cap": _active_projectile_cap,
		"stagger_capacity": _stagger_capacity,
	}


func get_room_requirements() -> Dictionary:
	return {
		"minimum_support_width": _minimum_support_width,
		"minimum_lane_width": _minimum_lane_width,
		"minimum_arc_clearance": _minimum_arc_clearance,
		"requires_patrol_turn_points": _requires_patrol_turn_points,
		"requires_escape_route": _requires_escape_route,
		"allows_wall_stop_lane": _allows_wall_stop_lane,
		"tags": _room_requirement_tags.duplicate(),
	}


func get_safety_bounds() -> Dictionary:
	return {
		"minimum_warning_time": _minimum_warning_time,
		"minimum_recovery_time": _minimum_recovery_time,
		"maximum_damage": _maximum_damage,
	}


func to_dictionary() -> Dictionary:
	return {
		"id": _variant_id,
		"archetype_id": _archetype_id,
		"variant_id": _variant_id,
		"stage_id": _stage_id,
		"tuning_profile_id": _tuning_profile_id,
		"content_version": _catalog_content_version,
		"archetype_content_version": _archetype_content_version,
		"variant_content_version": _variant_content_version,
		"tuning_profile_content_version": _tuning_profile_content_version,
		"display_name": _display_name,
		"tags": _tags.duplicate(),
		"behavior_owner": _behavior_owner,
		"pressure_roles": _pressure_roles.duplicate(),
		"tell_contract": _tell_contract,
		"response_contract": _response_contract,
		"punish_contract": _punish_contract,
		"room_requirements": get_room_requirements(),
		"safety_bounds": get_safety_bounds(),
		"exact_stats": get_exact_stats(),
		"presentation_key": _presentation_key,
		"presentation_description": _presentation_description,
		"tuning_trait": _tuning_trait,
		"budget_cost": _budget_cost,
		"drop_source_id": _drop_source_id,
	}


func _pack_string_names(values: Array[StringName]) -> PackedStringArray:
	var packed := PackedStringArray()
	for value in values:
		packed.append(String(value))
	return packed


func _merge_string_names(
	first: Array[StringName],
	second: Array[StringName]
) -> PackedStringArray:
	var merged := PackedStringArray()
	for values in [first, second]:
		for value in values:
			var text_value := String(value)
			if not merged.has(text_value):
				merged.append(text_value)
	return merged
