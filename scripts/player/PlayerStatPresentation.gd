class_name PlayerStatPresentation
extends RefCounted

const LABELS: Dictionary = {
	"max_health": "Health",
	"attack_damage": "Damage",
	"attack_cooldown": "Attack cooldown",
	"attack_active_time": "Attack window",
	"attack_range": "Attack reach",
	"attack_height": "Attack height",
	"attack_knockback_x": "Hit knockback",
	"attack_knockback_y": "Launch strength",
	"attack_projectile_speed": "Projectile speed",
	"attack_projectile_lifetime": "Projectile lifetime",
	"direct_damage_multiplier": "Direct damage",
	"skill_cooldown_multiplier": "Skill cooldown",
	"move_speed": "Move speed",
	"acceleration": "Acceleration",
	"deceleration": "Deceleration",
	"air_acceleration": "Air control",
	"gravity": "Gravity",
	"max_fall_speed": "Fall speed",
	"jump_velocity": "Jump strength",
	"jump_cut_multiplier": "Short-hop control",
	"coyote_time": "Ledge grace",
	"jump_buffer_time": "Jump buffer",
	"extra_jumps": "Extra jumps",
	"dash_speed": "Dash speed",
	"dash_duration": "Dash duration",
	"dash_cooldown": "Dash cooldown",
	"dash_charges": "Dash charges",
	"post_hit_invulnerability": "Hit protection",
	"damage_knockback_x": "Damage pushback",
	"damage_knockback_y": "Damage lift",
}
const INTEGER_STATS: Array[StringName] = [
	&"max_health",
	&"attack_damage",
	&"extra_jumps",
	&"dash_charges",
]
const SECOND_STATS: Array[StringName] = [
	&"attack_cooldown",
	&"attack_active_time",
	&"attack_projectile_lifetime",
	&"coyote_time",
	&"jump_buffer_time",
	&"dash_duration",
	&"dash_cooldown",
	&"post_hit_invulnerability",
]
const MULTIPLIER_STATS: Array[StringName] = [
	&"direct_damage_multiplier",
	&"skill_cooldown_multiplier",
	&"jump_cut_multiplier",
]
const MAGNITUDE_STATS: Array[StringName] = [
	&"jump_velocity",
	&"attack_knockback_y",
	&"damage_knockback_y",
]


static func display_name(stat_id: StringName) -> String:
	return String(LABELS.get(String(stat_id), String(stat_id).replace("_", " ").capitalize()))


static func format_value(stat_id: StringName, value: float) -> String:
	var display_value := absf(value) if stat_id in MAGNITUDE_STATS else value
	if stat_id in INTEGER_STATS:
		return str(int(round(display_value)))
	if stat_id in SECOND_STATS:
		return "%ss" % _trim_decimal(display_value, 2)
	if stat_id in MULTIPLIER_STATS:
		return "x%s" % _trim_decimal(display_value, 2, true)
	return _trim_decimal(display_value, 2)


static func format_transition(stat_id: StringName, before: float, after: float) -> String:
	return "%s %s -> %s" % [
		display_name(stat_id),
		format_value(stat_id, before),
		format_value(stat_id, after),
	]


static func format_effect(effect: Dictionary) -> String:
	var stat_id := StringName(effect.get("stat_id", ""))
	var operation := String(effect.get("operation", ""))
	var value := float(effect.get("value", 0.0))
	match operation:
		EffectDefinition.OPERATION_MULTIPLY:
			return "%s x%s" % [display_name(stat_id), _trim_decimal(value, 2, true)]
		EffectDefinition.OPERATION_OVERRIDE:
			return "%s %s" % [display_name(stat_id), format_value(stat_id, value)]
		_:
			var display_delta := -value if stat_id in MAGNITUDE_STATS else value
			var sign_prefix := "+" if display_delta > 0.0 else ""
			return "%s %s%s" % [
				display_name(stat_id),
				sign_prefix,
				format_value(stat_id, display_delta),
			]


static func compact_delta_summary(deltas: Array, limit: int = 2) -> String:
	var parts: Array[String] = []
	for delta_value in deltas:
		if parts.size() >= maxi(limit, 0):
			break
		if not delta_value is Dictionary:
			continue
		var delta := delta_value as Dictionary
		parts.append(format_transition(
			StringName(delta.get("stat_id", "")),
			float(delta.get("before", 0.0)),
			float(delta.get("after", 0.0))
		))
	return " | ".join(parts)


static func _trim_decimal(value: float, precision: int, keep_trailing_zeroes: bool = false) -> String:
	var formatted := "%.*f" % [precision, value]
	if keep_trailing_zeroes:
		return formatted
	while formatted.contains(".") and formatted.ends_with("0"):
		formatted = formatted.trim_suffix("0")
	return formatted.trim_suffix(".")
