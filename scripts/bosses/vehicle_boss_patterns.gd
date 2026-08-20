class_name VehicleBossPatterns
extends RefCounted

## Data-owned boss exams. PATTERNS store authored base Standard damage. The
## public damage contract applies one boss-only multiplier before VehicleRun
## bypasses ordinary enemy and stage multipliers.

const ACTIVE_MOVE_SCALE := 0.62
const AREA_TARGET_MAX_LEAD := 96.0
const MIN_BASE_WALK_ESCAPE_MARGIN := 40.0
const BOSS_CHARGE_SPEED := 1027.0
const BOSS_CONTACT_PADDING := 10.0
const BEAM_RANGE := 1334.0
const BEAM_COVER_PADDING := 5.0
const BASE_LANE_SPACING := 135.0
const BASE_FAN_OFFSETS := [-0.34, -0.17, 0.0, 0.17, 0.34]
const BOSS_PROJECTILE_SPEED_SCALE := 1.40
const BOSS_AREA_RADIUS_SCALE := 1.25

const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
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
	&"alternating_sectors_a": {"kind": &"alternating_pulse", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.30, "active": 1.45, "recovery": 1.00, "damage": 18.0, "radius": 300.0},
	&"alternating_sectors_b": {"kind": &"alternating_pulse", "commit_mode": &"autonomous", "affinity": &"arc", "startup": 1.30, "active": 1.45, "recovery": 1.00, "damage": 20.0, "radius": 320.0},
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
	&"stage_8": [&"common_charge", &"alternating_sectors_a", &"common_broad_barrage", &"alternating_sectors_b", &"focused_beam"],
	&"stage_9": [&"compression_single", &"compression_shift", &"compression_pair", &"compression_reverse", &"compression_break"],
	&"stage_10": [&"reflect_lance", &"reflect_fan", &"reflect_break", &"reflect_crossfire", &"reflect_reposition"],
	&"stage_11": [&"resonance_lanes", &"resonance_pulse", &"resonance_fan", &"resonance_cross", &"resonance_break"],
	&"stage_12": [&"overload_rush", &"overload_crossfire", &"overload_break", &"overload_crossfire_shift", &"overload_rush_return"],
}
const AUTONOMOUS_SEQUENCES := {
	&"stage_1": [&"slag_ring", &"forge_vent"], &"stage_2": [&"opposing_lanes", &"depth_charges"], &"stage_3": [&"thunder_chain", &"boss_pattern_fixed_beam_01_call"], &"stage_4": [&"switchyard_mines", &"switch_sweeps"], &"stage_5": [&"parallel_beams", &"relay_pulse_rings"],
	&"stage_6": [&"long_bank_barrage", &"long_bank_barrage"], &"stage_7": [&"crossing_weave_a", &"crossing_weave_b"], &"stage_8": [&"alternating_sectors_a", &"alternating_sectors_b"],
	&"stage_9": [&"compression_single", &"compression_pair"], &"stage_10": [&"reflect_lance", &"reflect_break"], &"stage_11": [&"resonance_lanes", &"resonance_pulse"], &"stage_12": [&"overload_crossfire_shift", &"overload_break"],
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


static func broad_barrage_rows(cycle_index: int, axis: Vector2, mode: StringName) -> Array[Dictionary]:
	var count := 4 if cycle_index <= 2 else (5 if cycle_index <= 5 else 6)
	var rows: Array[Dictionary] = []
	for row_index in 3:
		rows.append({"row": row_index, "at": float(row_index) * 0.38, "count": count, "spacing": 96.0, "warning": 0.65, "damage": 14.0 * StageDifficulty.boss_damage_multiplier(cycle_index), "axis": axis.rotated(float(row_index) * deg_to_rad(22.5) if mode == &"rotate" else 0.0), "mode": mode, "per_target_hit_lock": 0.80})
	return rows


static func barrage_mode(stage_id: StringName) -> StringName:
	return &"rotate" if stage_id in [&"stage_2", &"stage_4", &"stage_7", &"stage_8"] else &"spread"


static func barrage_mode_for_stage_index(stage_index: int) -> StringName:
	if stage_index < 0 or stage_index >= CombatStages.STAGE_IDS.size():
		return &"spread"
	return barrage_mode(CombatStages.STAGE_IDS[stage_index])


static func kind(pattern: String) -> StringName:
	return StringName(definition(pattern)["kind"])


static func startup_seconds(pattern: String) -> float:
	return float(definition(pattern)["startup"])


static func active_seconds(pattern: String) -> float:
	return float(definition(pattern)["active"])


static func scaled_startup_seconds(pattern: String, stage_index: int) -> float:
	return StageDifficulty.boss_startup_seconds(startup_seconds(pattern), stage_index)


static func scaled_active_seconds(pattern: String, stage_index: int) -> float:
	return StageDifficulty.boss_active_seconds(active_seconds(pattern), stage_index)


static func recovery_seconds(pattern: String) -> float:
	return float(definition(pattern)["recovery"])


static func damage(pattern: String, stage_index: int = 0) -> float:
	return (
		float(definition(pattern)["damage"])
		* StageDifficulty.boss_damage_multiplier(stage_index)
	)


static func affinity(pattern: String) -> StringName:
	return StringName(definition(pattern).get("affinity", &"kinetic"))


static func commit_mode(pattern: String) -> StringName:
	return StringName(definition(pattern).get("commit_mode", &""))


static func radius(pattern: String, stage_index: int = 0) -> float:
	return (
		float(definition(pattern).get("radius", 210.0))
		* StageDifficulty.boss_coverage_scale(stage_index)
		* BOSS_AREA_RADIUS_SCALE
	)


static func width(pattern: String, stage_index: int = 0) -> float:
	return (
		float(definition(pattern).get("width", 68.0))
		* StageDifficulty.boss_coverage_scale(stage_index)
	)


static func lane_spacing(stage_index: int = 0) -> float:
	return BASE_LANE_SPACING * StageDifficulty.boss_coverage_scale(stage_index)


static func fan_offsets(stage_index: int = 0) -> Array[float]:
	var scale := StageDifficulty.boss_coverage_scale(stage_index)
	var result: Array[float] = []
	for value in BASE_FAN_OFFSETS:
		result.append(float(value) * scale)
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
