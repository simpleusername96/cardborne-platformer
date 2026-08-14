class_name VehicleBossPatterns
extends RefCounted

## Data-owned boss exams. PATTERNS store authored base Standard damage. The
## public damage contract applies one boss-only multiplier before VehicleRun
## bypasses ordinary enemy and stage multipliers.

const ACTIVE_MOVE_SCALE := 0.62
const AREA_TARGET_MAX_LEAD := 96.0
const MIN_BASE_WALK_ESCAPE_MARGIN := 40.0
const BOSS_CHARGE_SPEED := 790.0
const BOSS_CONTACT_PADDING := 10.0
const BEAM_RANGE := 920.0
const BEAM_COVER_PADDING := 5.0
const BASE_LANE_SPACING := 135.0
const BASE_FAN_OFFSETS := [-0.34, -0.17, 0.0, 0.17, 0.34]

const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

const PATTERNS := {
	&"furnace_gates":{"kind":&"lanes", "commit_mode":&"committed", "affinity":&"thermal", "startup":1.00, "active":0.90, "recovery":0.90, "damage":22.0},
	&"foundry_ram":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.10, "active":0.65, "recovery":1.30, "damage":34.0},
	&"foundry_burst":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"thermal", "startup":0.85, "active":0.70, "recovery":0.90, "damage":20.0},
	&"furnace_ring":{"kind":&"area", "commit_mode":&"committed", "affinity":&"thermal", "startup":1.05, "active":0.60, "recovery":1.00, "damage":28.0, "radius":230.0},
	&"slag_ring":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"thermal", "startup":1.15, "active":0.70, "recovery":0.0, "damage":20.0, "radius":210.0},
	&"forge_vent":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.00, "active":2.4, "recovery":0.0, "damage":20.0, "radius":190.0},

	&"current_fan":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"kinetic", "startup":0.90, "active":0.70, "recovery":0.90, "damage":20.0},
	&"archive_lunge":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.10, "active":0.65, "recovery":1.25, "damage":34.0},
	&"archive_cross":{"kind":&"cross", "commit_mode":&"committed", "affinity":&"kinetic", "startup":0.95, "active":0.70, "recovery":0.95, "damage":26.0},
	&"archive_depth":{"kind":&"area", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.10, "active":0.55, "recovery":1.10, "damage":32.0, "radius":185.0},
	&"undertow_lanes":{"kind":&"lanes", "commit_mode":&"autonomous", "affinity":&"kinetic", "startup":1.10, "active":1.4, "recovery":0.0, "damage":20.0},
	&"depth_charges":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"kinetic", "startup":1.15, "active":0.60, "recovery":0.0, "damage":30.0, "radius":175.0},

	&"grounding_grid":{"kind":&"lanes", "commit_mode":&"committed", "affinity":&"arc", "startup":1.00, "active":0.85, "recovery":0.95, "damage":22.0},
	&"titan_pulse":{"kind":&"area", "commit_mode":&"committed", "affinity":&"arc", "startup":1.15, "active":0.60, "recovery":1.20, "damage":30.0, "radius":235.0},
	&"titan_burst":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"arc", "startup":0.90, "active":0.70, "recovery":0.90, "damage":22.0},
	&"titan_ram":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.10, "active":0.62, "recovery":1.20, "damage":34.0},
	&"thunder_chain":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.20, "active":0.55, "recovery":0.0, "damage":32.0, "radius":170.0},
	&"beam_sentinel_call":{"kind":&"summon", "commit_mode":&"autonomous", "affinity":&"support", "startup":1.00, "active":2.5, "recovery":0.0, "damage":0.0},

	&"breaker_charge":{"kind":&"charge", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.10, "active":0.70, "recovery":1.20, "damage":36.0},
	&"ricochet_volley":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.00, "active":0.75, "recovery":1.05, "damage":22.0},
	&"gate_shockwave":{"kind":&"area", "commit_mode":&"committed", "affinity":&"kinetic", "startup":1.20, "active":0.55, "recovery":1.05, "damage":28.0, "radius":240.0},
	&"switch_sweep":{"kind":&"beam", "commit_mode":&"committed", "affinity":&"arc", "startup":1.05, "active":0.80, "recovery":1.15, "damage":30.0, "width":78.0},
	&"switchyard_mines":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.15, "active":0.60, "recovery":0.0, "damage":26.0, "radius":145.0},
	&"switch_sweeps":{"kind":&"beam", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.15, "active":0.75, "recovery":0.0, "damage":28.0, "width":72.0},

	&"mirror_cross":{"kind":&"cross", "commit_mode":&"committed", "affinity":&"arc", "startup":0.95, "active":0.65, "recovery":1.00, "damage":28.0},
	&"carrier_wave":{"kind":&"summon", "commit_mode":&"committed", "affinity":&"support", "startup":1.10, "active":0.85, "recovery":1.25, "damage":0.0},
	&"crown_beam":{"kind":&"beam", "commit_mode":&"committed", "affinity":&"arc", "startup":1.15, "active":0.80, "recovery":1.25, "damage":34.0, "width":82.0},
	&"crown_burst":{"kind":&"fan", "commit_mode":&"committed", "affinity":&"arc", "startup":0.90, "active":0.70, "recovery":0.90, "damage":22.0},
	&"crown_lattice":{"kind":&"lanes", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.20, "active":1.4, "recovery":0.0, "damage":22.0},
	&"relay_pulse_rings":{"kind":&"area", "commit_mode":&"autonomous", "affinity":&"arc", "startup":1.15, "active":0.60, "recovery":0.0, "damage":30.0, "radius":225.0},
}

const STAGE_SEQUENCES := {
	&"stage_1":[&"furnace_gates", &"foundry_ram", &"foundry_burst", &"furnace_ring"],
	&"stage_2":[&"current_fan", &"archive_lunge", &"archive_cross", &"archive_depth"],
	&"stage_3":[&"grounding_grid", &"titan_pulse", &"titan_burst", &"titan_ram"],
	&"stage_4":[&"breaker_charge", &"ricochet_volley", &"gate_shockwave", &"switch_sweep"],
	&"stage_5":[&"mirror_cross", &"carrier_wave", &"crown_beam", &"crown_burst"],
}
const AUTONOMOUS_SEQUENCES := {
	&"stage_1":[&"slag_ring", &"forge_vent"],
	&"stage_2":[&"undertow_lanes", &"depth_charges"],
	&"stage_3":[&"thunder_chain", &"beam_sentinel_call"],
	&"stage_4":[&"switchyard_mines", &"switch_sweeps"],
	&"stage_5":[&"crown_lattice", &"relay_pulse_rings"],
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
	var ordered: Array = [base[2], base[0], base[3], base[1]] if phase == 2 else base
	if phase >= 3:
		ordered = [base[0], base[2], base[1], base[3]]
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
	return Dictionary(PATTERNS.get(StringName(pattern), PATTERNS[&"furnace_gates"]))


static func kind(pattern: String) -> StringName:
	return StringName(definition(pattern)["kind"])


static func startup_seconds(pattern: String) -> float:
	return float(definition(pattern)["startup"])


static func active_seconds(pattern: String) -> float:
	return float(definition(pattern)["active"])


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
	match kind(pattern):
		&"lanes":
			return 720.0
		&"fan", &"cross":
			return 620.0
	return 590.0
