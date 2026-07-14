class_name MovementMetrics
extends RefCounted

# Conservative movement envelopes are shared by route generation and validation.
const CONSERVATIVE_AIR_REACH := 0.82
const CONSERVATIVE_DASH_REACH := 0.85
const REQUIRED_GAP_FACTOR := 0.68
const REQUIRED_LEDGE_FACTOR := 0.72
const MAX_ROUTE_DASH_CHAIN := 2
const MINIMUM_ROUTE_HEADROOM := 100.0
const REQUIRED_ROUTE_ABILITIES: Array[StringName] = [
	&"baseline", &"double_jump", &"dash", &"crouch", &"climb",
]


static func calculate(stats: Dictionary) -> Dictionary:
	var move_speed := float(stats.get("move_speed", 220.0))
	var gravity := maxf(float(stats.get("gravity", 1200.0)), 1.0)
	var jump_velocity := absf(float(stats.get("jump_velocity", -420.0)))
	var dash_speed := float(stats.get("dash_speed", 520.0))
	var dash_duration := float(stats.get("dash_duration", 0.13))
	var dash_charges := int(stats.get("dash_charges", 1))
	var extra_jumps := int(stats.get("extra_jumps", 1))

	var time_to_apex := jump_velocity / gravity
	var airtime := time_to_apex * 2.0
	var jump_height := (jump_velocity * jump_velocity) / (2.0 * gravity)
	var single_jump_reach := move_speed * airtime * CONSERVATIVE_AIR_REACH
	var dash_reach := dash_speed * dash_duration
	var dash_chain_reach := dash_reach * float(mini(maxi(dash_charges, 1), MAX_ROUTE_DASH_CHAIN)) * CONSERVATIVE_DASH_REACH
	var jump_dash_reach := single_jump_reach + dash_reach * CONSERVATIVE_DASH_REACH

	var double_jump_height := jump_height
	var double_jump_reach := single_jump_reach
	if extra_jumps > 0:
		double_jump_height = jump_height * 1.65
		double_jump_reach = single_jump_reach + move_speed * time_to_apex * 0.70
	var double_jump_dash_reach := double_jump_reach + dash_chain_reach
	var route_reach := maxf(single_jump_reach, jump_dash_reach)
	var route_ledge_height := jump_height
	if extra_jumps > 0:
		route_reach = maxf(route_reach, double_jump_dash_reach)
		route_ledge_height = maxf(route_ledge_height, double_jump_height)

	return {
		"jump_height": jump_height,
		"time_to_apex": time_to_apex,
		"airtime": airtime,
		"single_jump_reach": single_jump_reach,
		"dash_reach": dash_reach,
		"dash_chain_reach": dash_chain_reach,
		"jump_dash_reach": jump_dash_reach,
		"double_jump_height": double_jump_height,
		"double_jump_reach": double_jump_reach,
		"double_jump_dash_reach": double_jump_dash_reach,
		"route_reach": route_reach,
		"route_ledge_height": route_ledge_height,
		"dash_charges": dash_charges,
		"extra_jumps": extra_jumps,
	}


static func calculate_for_profile(profile: CharacterProfile) -> Dictionary:
	if profile == null:
		return {}

	var metrics := calculate(profile.to_stats_dictionary())
	metrics["profile_id"] = profile.id
	metrics["profile_name"] = profile.display_name
	return metrics


static func route_limits_for_stats(
	stats: Dictionary,
	hero_id: StringName = &"traveler",
	display_name: String = "Traveler"
) -> Dictionary:
	var metrics := calculate(stats)
	if metrics.is_empty():
		return {}
	return {
		"least_mobile_profile_id": hero_id,
		"least_mobile_profile_name": display_name,
		"gap_limiting_profile_id": hero_id,
		"ledge_limiting_profile_id": hero_id,
		"max_required_gap": floorf(float(metrics["route_reach"]) * REQUIRED_GAP_FACTOR),
		"max_required_ledge": floorf(
			float(metrics["route_ledge_height"]) * REQUIRED_LEDGE_FACTOR
		),
		"minimum_headroom": MINIMUM_ROUTE_HEADROOM,
		"allowed_required_abilities": REQUIRED_ROUTE_ABILITIES.duplicate(),
		"least_metrics": metrics,
	}


static func route_limits_for_profiles(profiles: Array) -> Dictionary:
	var gap_profile: CharacterProfile
	var ledge_profile: CharacterProfile
	var gap_metrics: Dictionary = {}
	var minimum_route_reach := INF
	var minimum_ledge_height := INF

	for profile in profiles:
		if not profile is CharacterProfile:
			continue
		var metrics := calculate_for_profile(profile)
		var route_reach := float(metrics.get("route_reach", 0.0))
		var ledge_height := float(metrics.get("route_ledge_height", 0.0))
		# Limit each axis independently; one composite score can hide a weaker axis.
		if route_reach < minimum_route_reach:
			minimum_route_reach = route_reach
			gap_profile = profile
			gap_metrics = metrics
		if ledge_height < minimum_ledge_height:
			minimum_ledge_height = ledge_height
			ledge_profile = profile

	if gap_profile == null or ledge_profile == null:
		return {}

	return {
		"least_mobile_profile_id": gap_profile.id,
		"least_mobile_profile_name": gap_profile.display_name,
		"gap_limiting_profile_id": gap_profile.id,
		"ledge_limiting_profile_id": ledge_profile.id,
		"max_required_gap": floorf(minimum_route_reach * REQUIRED_GAP_FACTOR),
		"max_required_ledge": floorf(minimum_ledge_height * REQUIRED_LEDGE_FACTOR),
		"minimum_headroom": MINIMUM_ROUTE_HEADROOM,
		"allowed_required_abilities": REQUIRED_ROUTE_ABILITIES.duplicate(),
		"least_metrics": gap_metrics,
	}
