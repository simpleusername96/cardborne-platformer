class_name VehicleBossPatterns
extends RefCounted

## Data-owned boss exams. Pattern IDs describe authored selections while the
## resolved stage table stores absolute values for the one boss that uses them.

const AREA_TARGET_MAX_LEAD := 96.0
const MIN_BASE_WALK_ESCAPE_MARGIN := 40.0
const BOSS_CHARGE_SPEED := 1027.0
const BOSS_CONTACT_PADDING := 10.0
const BEAM_RANGE := 1334.0
const BEAM_COVER_PADDING := 5.0
const BASE_FAN_OFFSETS := [-0.34, -0.17, 0.0, 0.17, 0.34]
const BOSS_PROJECTILE_SPEED_SCALE := 1.40

const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

const PATTERNS := {
	&"thermal_gates":{"kind":&"lanes", "commit_mode":&"committed", "affinity":&"thermal", "startup":1.00, "active":0.90, "recovery":0.90, "damage":22.0},
	&"direct_charge":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.30, "active":0.65, "recovery":1.30, "damage":34.0},
	&"heated_fan":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"thermal", "startup":0.85, "active":0.70, "recovery":0.90, "damage":20.0},
	&"thermal_ring":{"kind":&"area", "commit_mode":&"committed", "affinity":&"thermal", "startup":1.20, "active":0.60, "recovery":1.00, "damage":28.0, "radius":230.0},
	&"slag_ring":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"thermal", "startup":1.15, "active":0.70, "recovery":0.0, "damage":20.0, "radius":210.0},
	&"forge_vent":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.00, "active":2.4, "recovery":0.0, "damage":20.0, "radius":190.0},

	&"current_fan":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"kinetic", "startup":0.90, "active":0.70, "recovery":0.90, "damage":20.0},
	&"lunge":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.30, "active":0.65, "recovery":1.25, "damage":34.0},
	&"cross_corridors":{"kind":&"cross_corridors", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.30, "active":0.70, "recovery":0.95, "damage":26.0, "width":84.0},
	&"depth_area":{"kind":&"area", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.10, "active":0.55, "recovery":1.10, "damage":32.0, "radius":185.0},
	&"opposing_lanes":{"kind":&"lanes", "commit_mode":&"autonomous", "affinity":&"kinetic", "startup":1.10, "active":1.4, "recovery":0.0, "damage":20.0},
	&"depth_charges":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"kinetic", "startup":1.15, "active":0.60, "recovery":0.0, "damage":30.0, "radius":175.0},

	&"grounding_grid":{"kind":&"lanes", "commit_mode":&"committed", "affinity":&"arc", "startup":1.00, "active":0.85, "recovery":0.95, "damage":22.0},
	&"radial_pulse":{"kind":&"area", "commit_mode":&"committed", "affinity":&"arc", "startup":1.30, "active":0.60, "recovery":1.20, "damage":30.0, "radius":235.0},
	&"shield_burst":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"arc", "startup":0.90, "active":0.70, "recovery":0.90, "damage":22.0},
	&"shield_ram":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.30, "active":0.62, "recovery":1.20, "damage":34.0},
	&"thunder_chain":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.20, "active":0.55, "recovery":0.0, "damage":32.0, "radius":170.0},
	&"boss_pattern_fixed_beam_01_call":{"kind":&"summon", "commit_mode":&"autonomous", "affinity":&"support", "startup":1.00, "active":2.5, "recovery":0.0, "damage":0.0},

	&"breaker_charge":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.30, "active":0.70, "recovery":1.20, "damage":36.0},
	&"ricochet_volley":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.00, "active":0.75, "recovery":1.05, "damage":22.0},
	&"gate_shockwave":{"kind":&"area", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.75, "active":0.55, "recovery":1.05, "damage":28.0, "radius":240.0},
	&"switch_sweep":{"kind":&"beam", "commit_mode":&"committed", "affinity":&"arc", "startup":1.05, "active":0.80, "recovery":1.15, "damage":30.0, "width":78.0},
	&"switchyard_mines":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.15, "active":0.60, "recovery":0.0, "damage":26.0, "radius":145.0},
	&"switch_sweeps":{"kind":&"beam", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.15, "active":0.75, "recovery":0.0, "damage":28.0, "width":72.0},

	&"mirror_cross":{"kind":&"cross", "commit_mode":&"committed", "affinity":&"arc", "startup":0.95, "active":0.65, "recovery":1.00, "damage":28.0},
	&"carrier_wave":{"kind":&"summon", "commit_mode":&"committed", "affinity":&"support", "startup":1.10, "active":0.85, "recovery":1.25, "damage":0.0},
	&"focused_beam":{"kind":&"beam", "commit_mode":&"committed", "affinity":&"arc", "startup":1.15, "active":0.80, "recovery":1.25, "damage":34.0, "width":82.0},
	&"focused_burst":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"arc", "startup":0.90, "active":0.70, "recovery":0.90, "damage":22.0},
	&"parallel_beams":{"kind":&"lanes", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.20, "active":1.4, "recovery":0.0, "damage":22.0},
	&"relay_pulse_rings":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.35, "active":0.60, "recovery":0.0, "damage":30.0, "radius":225.0},
}

const EXTRA_PATTERNS := {
	&"common_charge": {"kind": &"charge", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 1.30, "active": 0.65, "recovery": 1.00, "damage": 30.0},
	&"common_broad_barrage": {"kind": &"broad_barrage", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 1.30, "active": 1.14, "recovery": 0.90, "damage": 14.0},
	&"shield_counterburst": {"kind": &"fan", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 1.30, "active": 0.70, "recovery": 1.00, "damage": 32.0},
	&"long_bank_barrage": {"kind": &"long_banks", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 1.30, "active": 1.30, "recovery": 0.0, "damage": 16.0},
	&"crossing_weave_a": {"kind": &"crossing_weave", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.30, "active": 1.55, "recovery": 1.00, "damage": 68.0},
	&"crossing_weave_b": {"kind": &"crossing_weave", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.30, "active": 1.55, "recovery": 1.00, "damage": 72.0},
	&"radial_volley_a": {"kind": &"radial_volley", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.30, "active": 1.45, "recovery": 1.00, "damage": 18.0},
	&"radial_volley_b": {"kind": &"radial_volley", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.30, "active": 1.45, "recovery": 1.00, "damage": 20.0},
	&"edge_bars_a": {"kind": &"long_banks", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 1.10, "active": 1.20, "recovery": 0.0, "damage": 18.0},
	&"edge_bars_b": {"kind": &"crossing_weave", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 1.15, "active": 1.35, "recovery": 0.90, "damage": 60.0},
	&"pull_pulse_a": {"kind": &"area", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.55, "active": 0.75, "recovery": 0.0, "damage": 24.0, "radius": 220.0},
	&"pull_pulse_b": {"kind": &"lanes", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 1.05, "active": 0.85, "recovery": 0.0, "damage": 30.0, "width": 76.0},
	&"range_pulse_near": {"kind": &"area", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.45, "active": 0.70, "recovery": 0.0, "damage": 26.0, "radius": 180.0},
	&"range_pulse_far": {"kind": &"lanes", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.10, "active": 1.15, "recovery": 0.90, "damage": 22.0},
	&"remix_three_beat_a": {"kind": &"lanes", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 0.95, "active": 0.75, "recovery": 0.0, "damage": 24.0},
	&"remix_three_beat_b": {"kind": &"crossing_weave", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.10, "active": 1.25, "recovery": 0.90, "damage": 64.0},
	&"compression_single": {"kind": &"compression", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 0.75, "active": 1.20, "recovery": 0.95, "damage": 56.0},
	&"compression_shift": {"kind": &"compression", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 0.82, "active": 1.30, "recovery": 1.00, "damage": 60.0},
	&"compression_pair": {"kind": &"compression", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 0.90, "active": 1.45, "recovery": 1.10, "damage": 66.0},
	&"compression_reverse": {"kind": &"compression", "commit_mode": &"autonomous", "affinity": &"kinetic", "startup": 0.80, "active": 1.25, "recovery": 0.95, "damage": 58.0},
	&"compression_break": {"kind": &"fan", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.82, "active": 0.62, "recovery": 0.95, "damage": 24.0},
	&"reflect_lance": {"kind": &"beam", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.88, "active": 0.72, "recovery": 0.95, "damage": 34.0, "width": 84.0},
	&"reflect_fan": {"kind": &"fan", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.80, "active": 0.62, "recovery": 0.90, "damage": 25.0},
	&"reflect_break": {"kind": &"area", "commit_mode": &"committed", "affinity": &"arc", "startup": 1.00, "active": 0.55, "recovery": 1.00, "damage": 36.0, "radius": 210.0},
	&"reflect_crossfire": {"kind": &"cross", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.86, "active": 0.64, "recovery": 0.92, "damage": 27.0},
	&"reflect_reposition": {"kind": &"lanes", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.82, "active": 0.66, "recovery": 0.90, "damage": 23.0},
	&"resonance_lanes": {"kind": &"lanes", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.82, "active": 0.68, "recovery": 0.92, "damage": 25.0},
	&"resonance_pulse": {"kind": &"area", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.96, "active": 0.55, "recovery": 0.95, "damage": 35.0, "radius": 230.0},
	&"resonance_fan": {"kind": &"fan", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.80, "active": 0.62, "recovery": 0.90, "damage": 24.0},
	&"resonance_cross": {"kind": &"cross", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.86, "active": 0.64, "recovery": 0.92, "damage": 27.0},
	&"resonance_break": {"kind": &"beam", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.90, "active": 0.72, "recovery": 1.00, "damage": 36.0, "width": 86.0},
	&"overload_rush": {"kind": &"charge", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.82, "active": 0.58, "recovery": 0.90, "damage": 40.0},
	&"overload_crossfire": {"kind": &"cross", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.78, "active": 0.62, "recovery": 0.88, "damage": 30.0},
	&"overload_break": {"kind": &"area", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.92, "active": 0.52, "recovery": 0.92, "damage": 38.0, "radius": 245.0},
	&"overload_crossfire_shift": {"kind": &"lanes", "commit_mode": &"committed", "affinity": &"arc", "startup": 0.80, "active": 0.64, "recovery": 0.90, "damage": 28.0},
	&"overload_rush_return": {"kind": &"charge", "commit_mode": &"committed", "affinity": &"kinetic", "startup": 0.86, "active": 0.60, "recovery": 0.94, "damage": 42.0},
}
const STAGE_SEQUENCES := {
	&"stage_1": [&"common_charge", &"thermal_gates", &"common_broad_barrage", &"heated_fan", &"thermal_ring"],
	&"stage_2": [&"common_charge", &"cross_corridors", &"common_broad_barrage", &"depth_area", &"current_fan"],
	&"stage_3": [&"common_charge", &"grounding_grid", &"common_broad_barrage", &"shield_counterburst", &"radial_pulse"],
	&"stage_4": [&"common_charge", &"switch_sweep", &"common_broad_barrage", &"gate_shockwave", &"ricochet_volley"],
	&"stage_5": [&"common_charge", &"focused_beam", &"common_broad_barrage", &"mirror_cross", &"carrier_wave"],
	&"stage_6": [&"common_charge", &"long_bank_barrage", &"common_broad_barrage", &"ricochet_volley", &"gate_shockwave"],
	&"stage_7": [&"common_charge", &"crossing_weave_a", &"common_broad_barrage", &"crossing_weave_b", &"ricochet_volley"],
	&"stage_8": [&"common_charge", &"radial_volley_a", &"common_broad_barrage", &"radial_volley_b", &"focused_beam"],
	&"stage_9": [&"compression_single", &"compression_shift", &"compression_pair", &"compression_reverse", &"compression_break"],
	&"stage_10": [&"reflect_lance", &"reflect_fan", &"reflect_break", &"reflect_crossfire", &"reflect_reposition"],
	&"stage_11": [&"resonance_lanes", &"resonance_pulse", &"resonance_fan", &"resonance_cross", &"resonance_break"],
	&"stage_12": [&"overload_rush", &"overload_crossfire", &"overload_break", &"overload_crossfire_shift", &"overload_rush_return"],
}
const AUTONOMOUS_SEQUENCES := {
	&"stage_1": [&"slag_ring", &"forge_vent"], &"stage_2": [&"opposing_lanes", &"depth_charges"], &"stage_3": [&"thunder_chain", &"boss_pattern_fixed_beam_01_call"], &"stage_4": [&"switchyard_mines", &"switch_sweeps"], &"stage_5": [&"parallel_beams", &"relay_pulse_rings"],
	&"stage_6": [&"long_bank_barrage", &"long_bank_barrage"], &"stage_7": [&"crossing_weave_a", &"crossing_weave_b"], &"stage_8": [&"radial_volley_a", &"radial_volley_b"],
	&"stage_9": [&"compression_single", &"compression_pair"], &"stage_10": [&"reflect_lance", &"reflect_break"], &"stage_11": [&"resonance_lanes", &"resonance_pulse"], &"stage_12": [&"overload_crossfire_shift", &"overload_break"],
}

# [startup, active, recovery, damage, optional radius, optional width]. Values
# are the preserved pre-migration effective results, not stage multipliers.
const RESOLVED_STAGE_STATS: Array[Dictionary] = [
	{
		&"common_charge":[1.3, .65, .4824, 30.0], &"thermal_gates":[1.0, .9, .43416, 22.0],
		&"common_broad_barrage":[1.3, 1.14, .43416, 14.0], &"heated_fan":[.85, .7, .43416, 20.0],
		&"thermal_ring":[1.2, .6, .4824, 28.0, 287.5], &"slag_ring":[1.15, .7, 0.0, 20.0],
		&"forge_vent":[1.0, 2.4, 0.0, 20.0, 237.5],
	},
	{
		&"common_charge":[1.274, .637, .468, 31.8], &"cross_corridors":[1.274, .686, .4446, 27.56, 0.0, 87.36],
		&"common_broad_barrage":[1.274, 1.1172, .4212, 14.84], &"depth_area":[1.078, .539, .5148, 33.92, 240.5],
		&"current_fan":[.882, .686, .4212, 21.2], &"opposing_lanes":[1.078, 1.372, 0.0, 21.2],
		&"depth_charges":[1.127, .588, 0.0, 31.8, 227.5],
	},
	{
		&"common_charge":[1.248, .624, .4536, 33.6], &"grounding_grid":[.96, .816, .43092, 24.64],
		&"common_broad_barrage":[1.248, 1.0944, .40824, 15.68], &"shield_counterburst":[1.248, .672, .4536, 35.84],
		&"radial_pulse":[1.28, .576, .54432, 33.6, 317.25], &"thunder_chain":[1.152, .528, 0.0, 35.84, 229.5],
		&"boss_pattern_fixed_beam_01_call":[.96, 2.4, 0.0, 0.0],
	},
	{
		&"common_charge":[1.222, .611, .4392, 35.4], &"switch_sweep":[.987, .752, .50508, 35.4, 0.0, 87.36],
		&"common_broad_barrage":[1.222, 1.0716, .39528, 16.52], &"gate_shockwave":[1.645, .517, .46116, 33.04, 336.0],
		&"ricochet_volley":[.94, .705, .46116, 25.96], &"switchyard_mines":[1.081, .564, 0.0, 30.68, 203.0],
		&"switch_sweeps":[1.081, .705, 0.0, 33.04, 0.0, 80.64],
	},
	{
		&"common_charge":[1.196, .598, .4248, 37.2], &"focused_beam":[1.058, .736, .531, 42.16, 0.0, 95.12],
		&"common_broad_barrage":[1.196, 1.0488, .38232, 17.36], &"mirror_cross":[.874, .598, .4248, 34.72],
		&"carrier_wave":[1.012, .782, .531, 0.0], &"parallel_beams":[1.104, 1.288, 0.0, 27.28],
		&"relay_pulse_rings":[1.31, .552, 0.0, 37.2, 326.25],
	},
	{
		&"common_charge":[1.17, .585, .4104, 39.3], &"long_bank_barrage":[1.17, 1.17, 0.0, 20.96],
		&"common_broad_barrage":[1.17, 1.026, .36936, 18.34], &"ricochet_volley":[.9, .675, .43092, 28.82],
		&"gate_shockwave":[1.575, .495, .43092, 36.68, 360.0],
	},
	{
		&"common_charge":[1.144, .572, .396, 41.4], &"crossing_weave_a":[1.144, 1.364, .396, 93.84],
		&"common_broad_barrage":[1.144, 1.0032, .3564, 19.32], &"crossing_weave_b":[1.144, 1.364, .396, 99.36],
		&"ricochet_volley":[.88, .66, .4158, 30.36],
	},
	{
		&"common_charge":[1.118, .559, .3816, 43.8], &"radial_volley_a":[1.118, 1.247, .3816, 26.28],
		&"common_broad_barrage":[1.118, .9804, .34344, 20.44], &"radial_volley_b":[1.118, 1.247, .3816, 29.2],
		&"focused_beam":[.989, .688, .477, 49.64, 0.0, 104.96],
	},
	{
		&"compression_single":[.65, 1.02, .35568, 86.24], &"compression_shift":[.697, 1.105, .3744, 92.4],
		&"compression_pair":[.765, 1.2325, .41184, 101.64], &"compression_reverse":[.68, 1.0625, .35568, 89.32],
		&"compression_break":[.697, .527, .35568, 36.96],
	},
	{
		&"reflect_lance":[.7392, .6048, .34884, 55.08, 0.0, 110.88], &"reflect_fan":[.672, .5208, .33048, 40.5],
		&"reflect_break":[.84, .462, .3672, 58.32], &"reflect_crossfire":[.7224, .5376, .337824, 43.74],
		&"reflect_reposition":[.6888, .5544, .33048, 37.26],
	},
	{
		&"resonance_lanes":[.6806, .5644, .3312, 42.5], &"resonance_pulse":[.7968, .4565, .342, 59.5, 385.25],
		&"resonance_fan":[.664, .5146, .324, 40.8], &"resonance_cross":[.7138, .5312, .3312, 45.9],
		&"resonance_break":[.747, .5976, .36, 61.2, 0.0, 115.24],
	},
	{
		&"overload_rush":[.6724, .4756, .31752, 71.2], &"overload_crossfire":[.65, .5084, .310464, 53.4],
		&"overload_break":[.7544, .45, .324576, 67.64, 416.5], &"overload_crossfire_shift":[.656, .5248, .31752, 49.84],
		&"overload_rush_return":[.7052, .492, .331632, 74.76],
	},
]

# Pattern IDs are authored selections. Behavior families describe the runtime
# algorithm that actually executes them, so aliases with different tuning or
# affinity do not masquerade as different mechanics.
const BEHAVIOR_FAMILY_BY_KIND := {
	&"charge": &"charge",
	&"lanes": &"lane_volley",
	&"fan": &"fan_volley",
	&"cross": &"cross_volley",
	&"beam": &"emitted_beam",
	&"broad_barrage": &"broad_barrage",
	&"cross_corridors": &"cross_corridor_beam",
	&"long_banks": &"distance_growth_banks",
	&"crossing_weave": &"crossing_weave",
	&"radial_volley": &"radial_volley",
	&"compression": &"compression_slabs",
}
const BEHAVIOR_FAMILY_OVERRIDES := {
	&"carrier_wave": &"carrier_summon",
	&"boss_pattern_fixed_beam_01_call": &"fixed_beam_summon",
}

static func sequence(stage_id: StringName, phase_value: Variant = 1) -> Array[String]:
	var profile_id := CombatStages.boss_profile_id(stage_id)
	var base: Array = STAGE_SEQUENCES.get(profile_id, [])
	if base.is_empty():
		return []
	var phase := (
		2
		if phase_value is bool and bool(phase_value)
		else int(phase_value)
	)
	var ordered: Array = [base[2], base[0], base[3], base[1], base[4]] if phase == 2 else base
	if phase >= 3:
		ordered = [base[0], base[2], base[1], base[4], base[3]]
	var result: Array[String] = []
	for value in ordered: result.append(String(value))
	return result


static func autonomous_sequence(stage_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var profile_id := CombatStages.boss_profile_id(stage_id)
	for value in Array(AUTONOMOUS_SEQUENCES.get(profile_id, [])):
		result.append(StringName(value))
	return result


static func definition(pattern: String) -> Dictionary:
	var pattern_id := StringName(pattern)
	return Dictionary(EXTRA_PATTERNS.get(pattern_id, PATTERNS.get(pattern_id, PATTERNS[&"thermal_gates"])))


static func is_common(pattern: String) -> bool:
	return StringName(pattern) in [&"common_charge", &"common_broad_barrage"]


static func behavior_family(pattern: String) -> StringName:
	var pattern_id := StringName(pattern)
	if BEHAVIOR_FAMILY_OVERRIDES.has(pattern_id):
		return StringName(BEHAVIOR_FAMILY_OVERRIDES[pattern_id])
	var pattern_kind := kind(pattern)
	if pattern_kind == &"area":
		return (
			&"autonomous_radial_zone"
			if commit_mode(pattern) == &"autonomous"
			else &"committed_radial_bombardment"
		)
	return StringName(BEHAVIOR_FAMILY_BY_KIND.get(pattern_kind, pattern_kind))


static func stages_using_behavior(family: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	for stage_id in STAGE_SEQUENCES:
		var selected: Array = Array(STAGE_SEQUENCES[stage_id]).duplicate()
		selected.append_array(Array(AUTONOMOUS_SEQUENCES.get(stage_id, [])))
		for pattern in selected:
			if behavior_family(String(pattern)) != family:
				continue
			result.append(StringName(stage_id))
			break
	return result


static func is_shared_behavior(pattern: String) -> bool:
	return stages_using_behavior(behavior_family(pattern)).size() >= 2


static func broad_barrage_rows(cycle_index: int, axis: Vector2, mode: StringName) -> Array[Dictionary]:
	var count := 4 if cycle_index <= 2 else (5 if cycle_index <= 5 else 6)
	var rows: Array[Dictionary] = []
	for row_index in 3:
		rows.append({"row": row_index, "at": float(row_index) * 0.38, "count": count, "spacing": 96.0, "warning": 0.65, "damage": damage("common_broad_barrage", cycle_index), "axis": axis.rotated(float(row_index) * deg_to_rad(22.5) if mode == &"rotate" else 0.0), "mode": mode, "per_target_hit_lock": 0.80})
	return rows


static func barrage_mode(stage_id: StringName) -> StringName:
	return &"rotate" if stage_id in [&"stage_2", &"stage_4", &"stage_7", &"stage_8"] else &"spread"


static func barrage_mode_for_stage_index(stage_index: int) -> StringName:
	if stage_index < 0 or stage_index >= CombatStages.STAGE_IDS.size():
		return &"spread"
	return barrage_mode(CombatStages.STAGE_IDS[stage_index])


static func kind(pattern: String) -> StringName:
	return StringName(definition(pattern)["kind"])


static func resolved_stats(pattern: String, stage_index: int) -> Array:
	if stage_index < 0 or stage_index >= RESOLVED_STAGE_STATS.size():
		return []
	return Array(RESOLVED_STAGE_STATS[stage_index].get(StringName(pattern), []))


static func startup_seconds(pattern: String, stage_index: int = -1) -> float:
	var stats := resolved_stats(pattern, stage_index)
	return float(stats[0]) if not stats.is_empty() else float(definition(pattern)["startup"])


static func active_seconds(pattern: String, stage_index: int = -1) -> float:
	var stats := resolved_stats(pattern, stage_index)
	return float(stats[1]) if not stats.is_empty() else float(definition(pattern)["active"])


static func recovery_seconds(pattern: String, stage_index: int = -1) -> float:
	var stats := resolved_stats(pattern, stage_index)
	return float(stats[2]) if not stats.is_empty() else float(definition(pattern)["recovery"])


static func damage(pattern: String, stage_index: int = 0) -> float:
	var stats := resolved_stats(pattern, stage_index)
	return float(stats[3]) if not stats.is_empty() else float(definition(pattern)["damage"])


static func affinity(pattern: String) -> StringName:
	return StringName(definition(pattern).get("affinity", &"kinetic"))


static func commit_mode(pattern: String) -> StringName:
	return StringName(definition(pattern).get("commit_mode", &""))


static func radius(pattern: String, stage_index: int = 0) -> float:
	var stats := resolved_stats(pattern, stage_index)
	if stats.size() >= 5 and float(stats[4]) > 0.0:
		return float(stats[4])
	return float(BossProfiles.profile(stage_index).get("default_radius", 262.5))


static func width(pattern: String, stage_index: int = 0) -> float:
	var stats := resolved_stats(pattern, stage_index)
	if stats.size() >= 6 and float(stats[5]) > 0.0:
		return float(stats[5])
	return float(BossProfiles.profile(stage_index).get("default_width", 68.0))


static func lane_spacing(stage_index: int = 0) -> float:
	return float(BossProfiles.profile(stage_index).get("lane_spacing", 135.0))


static func fan_offsets(stage_index: int = 0) -> Array[float]:
	var result: Array[float] = []
	for value in Array(BossProfiles.profile(stage_index).get("fan_offsets", BASE_FAN_OFFSETS)):
		result.append(float(value))
	return result


static func volley_interval(pattern: String) -> float:
	match kind(pattern):
		&"lanes":
			return 0.16
		&"fan", &"cross":
			return 0.20
	return 0.0


static func volley_limit(pattern: String, phase_two: bool) -> int:
	match kind(pattern):
		&"lanes":
			return 5 if phase_two else 4
		&"fan", &"cross":
			return 4 if phase_two else 3
	return 0


static func projectile_speed(pattern: String) -> float:
	var base_speed := 590.0
	match kind(pattern):
		&"lanes":
			base_speed = 720.0
		&"fan", &"cross":
			base_speed = 620.0
	return base_speed * BOSS_PROJECTILE_SPEED_SCALE
