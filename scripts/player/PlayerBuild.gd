class_name PlayerBuild
extends RefCounted

const EffectDefinitionScript = preload("res://scripts/player/EffectDefinition.gd")
const PlayerBuildSnapshotScript = preload("res://scripts/player/PlayerBuildSnapshot.gd")

const BASE_CHARACTER_SOURCE := "base_character"
const BUILD_LIMITS_SOURCE := "build_limits"

# These broad bounds reject corrupt builds; character balance uses narrower data.
const STAT_RULES: Dictionary = {
	"max_health": {"minimum": 1.0, "maximum": 999.0, "integer": true},
	"attack_damage": {"minimum": 1.0, "maximum": 999.0, "integer": true},
	"attack_cooldown": {"minimum": 0.05, "maximum": 60.0, "integer": false},
	"attack_active_time": {"minimum": 0.01, "maximum": 10.0, "integer": false},
	"attack_range": {"minimum": 1.0, "maximum": 2000.0, "integer": false},
	"attack_height": {"minimum": 1.0, "maximum": 2000.0, "integer": false},
	"attack_offset_x": {"minimum": -2000.0, "maximum": 2000.0, "integer": false},
	"attack_offset_y": {"minimum": -2000.0, "maximum": 2000.0, "integer": false},
	"attack_knockback_x": {"minimum": -5000.0, "maximum": 5000.0, "integer": false},
	"attack_knockback_y": {"minimum": -5000.0, "maximum": 5000.0, "integer": false},
	"attack_projectile_speed": {"minimum": 0.0, "maximum": 5000.0, "integer": false},
	"attack_projectile_lifetime": {"minimum": 0.01, "maximum": 60.0, "integer": false},
	"direct_damage_multiplier": {"minimum": 0.1, "maximum": 10.0, "integer": false},
	"skill_cooldown_multiplier": {"minimum": 0.1, "maximum": 2.0, "integer": false},
	"move_speed": {"minimum": 1.0, "maximum": 2000.0, "integer": false},
	"acceleration": {"minimum": 1.0, "maximum": 20000.0, "integer": false},
	"deceleration": {"minimum": 1.0, "maximum": 20000.0, "integer": false},
	"air_acceleration": {"minimum": 1.0, "maximum": 20000.0, "integer": false},
	"gravity": {"minimum": 1.0, "maximum": 20000.0, "integer": false},
	"max_fall_speed": {"minimum": 1.0, "maximum": 5000.0, "integer": false},
	"jump_velocity": {"minimum": -5000.0, "maximum": -1.0, "integer": false},
	"jump_cut_multiplier": {"minimum": 0.05, "maximum": 1.0, "integer": false},
	"coyote_time": {"minimum": 0.0, "maximum": 1.0, "integer": false},
	"jump_buffer_time": {"minimum": 0.0, "maximum": 1.0, "integer": false},
	"extra_jumps": {"minimum": 1.0, "maximum": 8.0, "integer": true},
	"dash_speed": {"minimum": 1.0, "maximum": 5000.0, "integer": false},
	"dash_duration": {"minimum": 0.01, "maximum": 10.0, "integer": false},
	"dash_cooldown": {"minimum": 0.05, "maximum": 60.0, "integer": false},
	"dash_charges": {"minimum": 1.0, "maximum": 8.0, "integer": true},
	"post_hit_invulnerability": {"minimum": 0.0, "maximum": 10.0, "integer": false},
	"damage_knockback_x": {"minimum": -5000.0, "maximum": 5000.0, "integer": false},
	"damage_knockback_y": {"minimum": -5000.0, "maximum": 5000.0, "integer": false},
}

const OPERATION_ORDER: Dictionary = {
	EffectDefinitionScript.OPERATION_ADD: 0,
	EffectDefinitionScript.OPERATION_MULTIPLY: 1,
	EffectDefinitionScript.OPERATION_OVERRIDE: 2,
}

const SOURCE_SCOPE_ORDER: Dictionary = {
	EffectDefinitionScript.SOURCE_SCOPE_MASTERY: 0,
	EffectDefinitionScript.SOURCE_SCOPE_EQUIPMENT: 1,
	EffectDefinitionScript.SOURCE_SCOPE_RUN_LEVEL: 2,
	EffectDefinitionScript.SOURCE_SCOPE_CARD: 3,
	EffectDefinitionScript.SOURCE_SCOPE_TEMPORARY: 4,
}

const SUPPORTED_STACKING: Array[String] = [
	EffectDefinitionScript.STACKING_STACK,
	EffectDefinitionScript.STACKING_UNIQUE,
	EffectDefinitionScript.STACKING_REPLACE,
	EffectDefinitionScript.STACKING_HIGHEST,
]


static func resolve(base_stats: Dictionary, effects: Array = []) -> PlayerBuildSnapshot:
	var validation_errors: Array = []
	var source_breakdown: Dictionary = {}
	var values := _resolve_base_stats(base_stats, source_breakdown, validation_errors)
	var normalized_effects := _normalize_effects(effects, values, validation_errors)
	var selected_effects := _select_stacks(normalized_effects, validation_errors)
	selected_effects.sort_custom(_effect_precedes)

	for effect in selected_effects:
		_apply_effect(effect, values, source_breakdown, validation_errors)

	_apply_build_limits(values, source_breakdown)
	validation_errors.sort_custom(_validation_error_precedes)
	return PlayerBuildSnapshotScript.new(values, source_breakdown, validation_errors)


static func _resolve_base_stats(
	base_stats: Dictionary,
	source_breakdown: Dictionary,
	validation_errors: Array
) -> Dictionary:
	var values: Dictionary = {}
	var stat_ids: Array = base_stats.keys()
	stat_ids.sort_custom(_base_stat_id_precedes)

	for raw_stat_id in stat_ids:
		var key_type := typeof(raw_stat_id)
		if key_type != TYPE_STRING and key_type != TYPE_STRING_NAME:
			_add_validation_error(
				validation_errors,
				"invalid_base_player_stat_id",
				"Player build base stats contain a player stat ID that is not text."
			)
			continue

		var stat_id := String(raw_stat_id)
		if not STAT_RULES.has(stat_id):
			_add_validation_error(
				validation_errors,
				"unsupported_base_player_stat",
				"Player build base stat '%s' is not a supported canonical player stat." % stat_id,
				stat_id
			)
			continue

		var raw_value: Variant = base_stats[raw_stat_id]
		var value_type := typeof(raw_value)
		if value_type != TYPE_INT and value_type != TYPE_FLOAT:
			_add_validation_error(
				validation_errors,
				"non_numeric_base_player_stat",
				"Player build base stat '%s' must be numeric." % stat_id,
				stat_id
			)
			continue

		var value := float(raw_value)
		if not is_finite(value):
			_add_validation_error(
				validation_errors,
				"non_finite_base_player_stat",
				"Player build base stat '%s' must have a finite value." % stat_id,
				stat_id
			)
			continue

		values[stat_id] = value
		_append_breakdown(source_breakdown, BASE_CHARACTER_SOURCE, {
			"stat_id": stat_id,
			"operation": "base",
			"value": value,
			"before": value,
			"after": value,
			"stacking": "base",
			"stack_key": "",
			"source_id": BASE_CHARACTER_SOURCE,
			"source_scope": "base",
			"priority": 0,
		})

	return values


static func _normalize_effects(
	effects: Array,
	base_values: Dictionary,
	validation_errors: Array
) -> Array:
	var normalized_effects: Array = []
	for raw_effect in effects:
		if not raw_effect is EffectDefinitionScript:
			_add_validation_error(
				validation_errors,
				"invalid_effect_definition",
				"Player build effects must use EffectDefinition resources."
			)
			continue

		var effect: EffectDefinition = raw_effect
		var stat_id := String(effect.stat_id)
		var operation := effect.operation
		var stacking := effect.stacking
		var stack_key := String(effect.stack_key)
		var source_id := String(effect.source_id)
		var source_scope := effect.source_scope

		if stat_id.is_empty() or not STAT_RULES.has(stat_id):
			_add_validation_error(
				validation_errors,
				"unsupported_effect_player_stat",
				"Effect source '%s' targets unsupported player stat '%s'." % [source_id, stat_id],
				stat_id,
				source_id
			)
			continue
		if not OPERATION_ORDER.has(operation):
			_add_validation_error(
				validation_errors,
				"unsupported_effect_operation",
				"Effect source '%s' uses unsupported operation '%s' for player stat '%s'." % [
					source_id, operation, stat_id
				],
				stat_id,
				source_id
			)
			continue
		if not SUPPORTED_STACKING.has(stacking):
			_add_validation_error(
				validation_errors,
				"unsupported_effect_stacking",
				"Effect source '%s' uses unsupported stacking '%s' for player stat '%s'." % [
					source_id, stacking, stat_id
				],
				stat_id,
				source_id
			)
			continue
		if source_id.is_empty():
			_add_validation_error(
				validation_errors,
				"missing_effect_source",
				"Player stat effect '%s' must declare its build source." % stat_id,
				stat_id
			)
			continue
		if source_id == BASE_CHARACTER_SOURCE or source_id == BUILD_LIMITS_SOURCE:
			_add_validation_error(
				validation_errors,
				"reserved_effect_source",
				"Effect source '%s' is reserved by the player build resolver." % source_id,
				stat_id,
				source_id
			)
			continue
		if not SOURCE_SCOPE_ORDER.has(source_scope):
			_add_validation_error(
				validation_errors,
				"unsupported_effect_source_scope",
				"Effect source '%s' uses unsupported source scope '%s'." % [source_id, source_scope],
				stat_id,
				source_id
			)
			continue
		if stacking != EffectDefinitionScript.STACKING_STACK and stack_key.is_empty():
			_add_validation_error(
				validation_errors,
				"missing_effect_stack_key",
				"Effect source '%s' must declare a stack key for '%s' stacking." % [
					source_id, stacking
				],
				stat_id,
				source_id
			)
			continue
		if not is_finite(effect.value):
			_add_validation_error(
				validation_errors,
				"non_finite_effect_value",
				"Effect source '%s' must use a finite value for player stat '%s'." % [
					source_id, stat_id
				],
				stat_id,
				source_id
			)
			continue
		if not base_values.has(stat_id):
			_add_validation_error(
				validation_errors,
				"missing_base_player_stat",
				"Effect source '%s' targets player stat '%s', but the base character did not provide it." % [
					source_id, stat_id
				],
				stat_id,
				source_id
			)
			continue

		normalized_effects.append({
			"stat_id": stat_id,
			"operation": operation,
			"value": effect.value,
			"stacking": stacking,
			"stack_key": stack_key,
			"source_id": source_id,
			"source_scope": source_scope,
			"priority": effect.priority,
		})

	return normalized_effects


static func _select_stacks(effects: Array, validation_errors: Array) -> Array:
	var selected: Array = []
	var grouped: Dictionary = {}
	var invalid_groups: Dictionary = {}

	for effect in effects:
		if effect["stacking"] == EffectDefinitionScript.STACKING_STACK:
			selected.append(effect)
			continue

		var group_key := _stack_group_key(effect)
		if not grouped.has(group_key):
			grouped[group_key] = effect
			continue

		var current: Dictionary = grouped[group_key]
		if current["operation"] != effect["operation"] or current["stacking"] != effect["stacking"]:
			if not invalid_groups.has(group_key):
				_add_validation_error(
					validation_errors,
					"conflicting_effect_stack_policy",
					"Stack key '%s' has conflicting operation or stacking policies for player stat '%s'." % [
						effect["stack_key"], effect["stat_id"]
					],
					effect["stat_id"],
					effect["source_id"]
				)
			invalid_groups[group_key] = true
			continue
		if _effect_wins_stack(effect, current):
			grouped[group_key] = effect

	var group_keys: Array = grouped.keys()
	group_keys.sort()
	for group_key in group_keys:
		if not invalid_groups.has(group_key):
			selected.append(grouped[group_key])
	return selected


static func _stack_group_key(effect: Dictionary) -> String:
	return var_to_str([
		effect["stat_id"],
		effect["stack_key"],
	])


static func _effect_wins_stack(candidate: Dictionary, current: Dictionary) -> bool:
	if candidate["stacking"] == EffectDefinitionScript.STACKING_HIGHEST:
		var candidate_value := float(candidate["value"])
		var current_value := float(current["value"])
		if candidate_value != current_value:
			return candidate_value > current_value

	var candidate_scope_order := int(SOURCE_SCOPE_ORDER[candidate["source_scope"]])
	var current_scope_order := int(SOURCE_SCOPE_ORDER[current["source_scope"]])
	if candidate_scope_order != current_scope_order:
		return candidate_scope_order > current_scope_order

	var candidate_priority := int(candidate["priority"])
	var current_priority := int(current["priority"])
	if candidate_priority != current_priority:
		return candidate_priority > current_priority
	return _effect_precedes(current, candidate)


static func _apply_effect(
	effect: Dictionary,
	values: Dictionary,
	source_breakdown: Dictionary,
	validation_errors: Array
) -> void:
	var stat_id: String = effect["stat_id"]
	var before := float(values[stat_id])
	var after := before
	match effect["operation"]:
		EffectDefinitionScript.OPERATION_ADD:
			after = before + float(effect["value"])
		EffectDefinitionScript.OPERATION_MULTIPLY:
			after = before * float(effect["value"])
		EffectDefinitionScript.OPERATION_OVERRIDE:
			after = float(effect["value"])

	if not is_finite(after):
		_add_validation_error(
			validation_errors,
			"non_finite_resolved_player_stat",
			"Effect source '%s' produced a non-finite value for player stat '%s'." % [
				effect["source_id"], stat_id
			],
			stat_id,
			effect["source_id"]
		)
		return

	values[stat_id] = after
	var record := effect.duplicate(true)
	record["before"] = before
	record["after"] = after
	_append_breakdown(source_breakdown, effect["source_id"], record)


static func _apply_build_limits(values: Dictionary, source_breakdown: Dictionary) -> void:
	var stat_ids: Array = values.keys()
	stat_ids.sort()
	for stat_id in stat_ids:
		var before := float(values[stat_id])
		var rule: Dictionary = STAT_RULES[stat_id]
		var after := clampf(before, float(rule["minimum"]), float(rule["maximum"]))
		if bool(rule["integer"]):
			after = float(roundi(after))
		values[stat_id] = after
		if before != after:
			_append_breakdown(source_breakdown, BUILD_LIMITS_SOURCE, {
				"stat_id": stat_id,
				"operation": "clamp",
				"value": after,
				"before": before,
				"after": after,
				"stacking": "build_limit",
				"stack_key": "",
				"source_id": BUILD_LIMITS_SOURCE,
				"source_scope": "build_limits",
				"priority": 0,
			})


static func _append_breakdown(source_breakdown: Dictionary, source_id: String, record: Dictionary) -> void:
	if not source_breakdown.has(source_id):
		source_breakdown[source_id] = []
	var records: Array = source_breakdown[source_id]
	records.append(record)
	source_breakdown[source_id] = records


static func _add_validation_error(
	validation_errors: Array,
	code: String,
	message: String,
	stat_id: String = "",
	source_id: String = ""
) -> void:
	validation_errors.append({
		"code": code,
		"message": message,
		"stat_id": stat_id,
		"source_id": source_id,
	})


static func _base_stat_id_precedes(left: Variant, right: Variant) -> bool:
	var left_key := "%02d:%s" % [typeof(left), str(left)]
	var right_key := "%02d:%s" % [typeof(right), str(right)]
	return left_key < right_key


static func _effect_precedes(left: Dictionary, right: Dictionary) -> bool:
	if left["stat_id"] != right["stat_id"]:
		return left["stat_id"] < right["stat_id"]
	var left_scope_order := int(SOURCE_SCOPE_ORDER[left["source_scope"]])
	var right_scope_order := int(SOURCE_SCOPE_ORDER[right["source_scope"]])
	if left_scope_order != right_scope_order:
		return left_scope_order < right_scope_order
	var left_operation_order := int(OPERATION_ORDER[left["operation"]])
	var right_operation_order := int(OPERATION_ORDER[right["operation"]])
	if left_operation_order != right_operation_order:
		return left_operation_order < right_operation_order
	if left["priority"] != right["priority"]:
		return left["priority"] < right["priority"]
	if left["stack_key"] != right["stack_key"]:
		return left["stack_key"] < right["stack_key"]
	if left["source_id"] != right["source_id"]:
		return left["source_id"] < right["source_id"]
	if left["stacking"] != right["stacking"]:
		return left["stacking"] < right["stacking"]
	return float(left["value"]) < float(right["value"])


static func _validation_error_precedes(left: Dictionary, right: Dictionary) -> bool:
	for key in ["code", "stat_id", "source_id", "message"]:
		if left[key] != right[key]:
			return str(left[key]) < str(right[key])
	return false
