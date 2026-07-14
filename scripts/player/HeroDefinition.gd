class_name HeroDefinition
extends Resource

const REQUIRED_STATS: Array[StringName] = [
	&"max_health",
	&"direct_damage_multiplier",
	&"move_speed",
	&"acceleration",
	&"deceleration",
	&"air_acceleration",
	&"gravity",
	&"max_fall_speed",
	&"jump_velocity",
	&"jump_cut_multiplier",
	&"coyote_time",
	&"jump_buffer_time",
	&"extra_jumps",
	&"dash_speed",
	&"dash_duration",
	&"dash_cooldown",
	&"dash_charges",
	&"post_hit_invulnerability",
	&"damage_knockback_x",
	&"damage_knockback_y",
]

@export var id: StringName = &"traveler"
@export var display_name: String = "Traveler"
@export var visual_color: Color = Color(0.22, 0.74, 0.76, 1.0)
@export var base_stats: Dictionary = {}


func to_base_stats_dictionary() -> Dictionary:
	return base_stats.duplicate(true)


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Hero ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Hero needs a display name.")
	if visual_color.a <= 0.0:
		errors.append("Hero visual color must be visible.")
	for stat_id in REQUIRED_STATS:
		if not base_stats.has(stat_id):
			errors.append("Hero '%s' is missing stat '%s'." % [id, stat_id])
			continue
		var value: Variant = base_stats[stat_id]
		if not (value is int or value is float) or not is_finite(float(value)):
			errors.append("Hero '%s' stat '%s' must be finite and numeric." % [id, stat_id])
	for stat_id in base_stats:
		if not REQUIRED_STATS.has(StringName(stat_id)):
			errors.append("Hero '%s' has unsupported stat '%s'." % [id, stat_id])
	if errors.is_empty():
		_validate_ranges(errors)
	return errors


func _validate_ranges(errors: PackedStringArray) -> void:
	if int(base_stats[&"max_health"]) <= 0:
		errors.append("Hero max health must be positive.")
	if float(base_stats[&"move_speed"]) <= 0.0 or float(base_stats[&"jump_velocity"]) >= 0.0:
		errors.append("Hero movement speed must be positive and jump velocity must be negative.")
	if int(base_stats[&"extra_jumps"]) < 1:
		errors.append("The shared hero baseline must support double jump.")
	if int(base_stats[&"dash_charges"]) < 1 or float(base_stats[&"dash_speed"]) <= 0.0:
		errors.append("The shared hero baseline must support at least one dash.")
	if float(base_stats[&"jump_cut_multiplier"]) <= 0.0 or float(base_stats[&"jump_cut_multiplier"]) > 1.0:
		errors.append("Hero jump cut multiplier must be within (0, 1].")
