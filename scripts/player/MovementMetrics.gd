class_name MovementMetrics
extends RefCounted

const CONSERVATIVE_AIR_REACH := 0.82
const CONSERVATIVE_DASH_REACH := 0.85
const REQUIRED_GAP_FACTOR := 0.68
const REQUIRED_LEDGE_FACTOR := 0.72


static func calculate(stats: Dictionary, ability_flags: Dictionary = {}) -> Dictionary:
	var move_speed := float(stats.get("move_speed", 220.0))
	var gravity := maxf(float(stats.get("gravity", 1200.0)), 1.0)
	var jump_velocity := absf(float(stats.get("jump_velocity", -420.0)))
	var dash_speed := float(stats.get("dash_speed", 520.0))
	var dash_duration := float(stats.get("dash_duration", 0.13))
	var dash_charges := int(stats.get("dash_charges", 1))
	if bool(ability_flags.get("extra_dash_enabled", false)):
		dash_charges += 1

	var time_to_apex := jump_velocity / gravity
	var airtime := time_to_apex * 2.0
	var jump_height := (jump_velocity * jump_velocity) / (2.0 * gravity)
	var single_jump_reach := move_speed * airtime * CONSERVATIVE_AIR_REACH
	var dash_reach := dash_speed * dash_duration
	var jump_dash_reach := single_jump_reach + dash_reach * CONSERVATIVE_DASH_REACH

	var double_jump_height := jump_height
	var double_jump_reach := single_jump_reach
	if bool(ability_flags.get("double_jump_enabled", false)):
		double_jump_height = jump_height * 1.65
		double_jump_reach = single_jump_reach + move_speed * time_to_apex * 0.70

	return {
		"jump_height": jump_height,
		"time_to_apex": time_to_apex,
		"airtime": airtime,
		"single_jump_reach": single_jump_reach,
		"dash_reach": dash_reach,
		"jump_dash_reach": jump_dash_reach,
		"double_jump_height": double_jump_height,
		"double_jump_reach": double_jump_reach,
		"dash_charges": dash_charges,
	}


static func calculate_for_profile(profile: CharacterProfile, ability_flags: Dictionary = {}) -> Dictionary:
	if profile == null:
		return {}

	var metrics := calculate(profile.to_stats_dictionary(), ability_flags)
	metrics["profile_id"] = profile.id
	metrics["profile_name"] = profile.display_name
	return metrics


static func route_limits_for_profiles(profiles: Array, ability_flags: Dictionary = {}) -> Dictionary:
	var least_profile: CharacterProfile
	var least_metrics: Dictionary = {}
	var lowest_score := INF

	for profile in profiles:
		if not profile is CharacterProfile:
			continue
		var metrics := calculate_for_profile(profile, ability_flags)
		var score := float(metrics.get("jump_dash_reach", 0.0)) + float(metrics.get("jump_height", 0.0)) * 0.25
		if score < lowest_score:
			lowest_score = score
			least_profile = profile
			least_metrics = metrics

	if least_profile == null:
		return {}

	return {
		"least_mobile_profile_id": least_profile.id,
		"least_mobile_profile_name": least_profile.display_name,
		"max_required_gap": floorf(float(least_metrics.get("jump_dash_reach", 0.0)) * REQUIRED_GAP_FACTOR),
		"max_required_ledge": floorf(float(least_metrics.get("jump_height", 0.0)) * REQUIRED_LEDGE_FACTOR),
		"least_metrics": least_metrics,
	}
