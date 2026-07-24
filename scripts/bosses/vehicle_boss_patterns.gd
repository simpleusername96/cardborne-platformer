class_name VehicleBossPatterns
extends RefCounted

## Data-owned boss exams. Damage values are final Standard damage and therefore
## bypass ordinary enemy and stage multipliers in VehicleRun.

const STAGGER_THRESHOLD := 35.0
const STAGGER_WINDOW := 0.75
const STAGGER_RECOVERY_READ := 0.35
const ACTIVE_MOVE_SCALE := 0.62
const AREA_TARGET_MAX_LEAD := 96.0
const MIN_BASE_WALK_ESCAPE_MARGIN := 40.0
const BOSS_CHARGE_SPEED := 790.0
const BOSS_CONTACT_PADDING := 10.0
const BEAM_RANGE := 920.0
const BEAM_COVER_PADDING := 5.0

const PATTERNS := {
	&"twin_foundry_lanes":{"kind":&"lanes", "affinity":&"thermal", "startup":0.90, "active":0.80, "recovery":1.00, "damage":20.0},
	&"foundry_ram":{"kind":&"charge", "affinity":&"kinetic", "startup":1.10, "active":0.65, "recovery":1.30, "damage":34.0},
	&"furnace_ring":{"kind":&"area", "affinity":&"thermal", "startup":1.00, "active":0.60, "recovery":1.00, "damage":26.0, "radius":230.0},
	&"pylon_overload":{"kind":&"pylons", "affinity":&"arc", "startup":0.90, "active":0.55, "recovery":1.15, "damage":24.0, "radius":205.0},

	&"current_fan":{"kind":&"fan", "affinity":&"kinetic", "startup":0.85, "active":0.65, "recovery":0.95, "damage":20.0},
	&"undertow_sweep":{"kind":&"beam", "affinity":&"kinetic", "startup":0.95, "active":0.75, "recovery":1.10, "damage":28.0, "width":70.0},
	&"depth_charge":{"kind":&"area", "affinity":&"kinetic", "startup":1.10, "active":0.55, "recovery":1.25, "damage":32.0, "radius":185.0},
	&"archive_ram":{"kind":&"charge", "affinity":&"kinetic", "startup":1.10, "active":0.65, "recovery":1.35, "damage":34.0},

	&"arc_lanes":{"kind":&"lanes", "affinity":&"arc", "startup":0.85, "active":0.80, "recovery":0.95, "damage":22.0},
	&"grounded_ring":{"kind":&"area", "affinity":&"arc", "startup":1.00, "active":0.65, "recovery":1.10, "damage":28.0, "radius":235.0},
	&"thunder_drop":{"kind":&"area", "affinity":&"arc", "startup":1.10, "active":0.50, "recovery":1.35, "damage":34.0, "radius":175.0},
	&"escort_surge":{"kind":&"summon", "affinity":&"arc", "startup":0.85, "active":0.80, "recovery":1.20, "damage":24.0, "radius":190.0},

	&"open_lane_charge":{"kind":&"charge", "affinity":&"kinetic", "startup":1.10, "active":0.70, "recovery":1.45, "damage":36.0},
	&"gate_shockwave":{"kind":&"area", "affinity":&"kinetic", "startup":1.00, "active":0.55, "recovery":1.05, "damage":28.0, "radius":240.0},
	&"ricochet_volley":{"kind":&"fan", "affinity":&"kinetic", "startup":0.85, "active":0.70, "recovery":1.00, "damage":22.0},
	&"switch_sweep":{"kind":&"beam", "affinity":&"arc", "startup":1.00, "active":0.80, "recovery":1.20, "damage":30.0, "width":78.0},

	&"crown_beam":{"kind":&"beam", "affinity":&"arc", "startup":1.15, "active":0.80, "recovery":1.30, "damage":34.0, "width":82.0},
	&"mirror_cross":{"kind":&"cross", "affinity":&"arc", "startup":0.95, "active":0.65, "recovery":1.10, "damage":28.0},
	&"carrier_wave":{"kind":&"summon", "affinity":&"support", "startup":0.85, "active":0.85, "recovery":1.25, "damage":0.0},
	&"relay_pulse":{"kind":&"area", "affinity":&"arc", "startup":0.95, "active":0.60, "recovery":1.10, "damage":30.0, "radius":225.0},
}

const STAGE_SEQUENCES := {
	&"stage_1":[&"twin_foundry_lanes", &"foundry_ram", &"furnace_ring", &"pylon_overload"],
	&"stage_2":[&"current_fan", &"undertow_sweep", &"depth_charge", &"archive_ram"],
	&"stage_3":[&"arc_lanes", &"grounded_ring", &"thunder_drop", &"escort_surge"],
	&"stage_4":[&"open_lane_charge", &"gate_shockwave", &"ricochet_volley", &"switch_sweep"],
	&"stage_5":[&"crown_beam", &"mirror_cross", &"carrier_wave", &"relay_pulse"],
}

static func sequence(stage_id: StringName, phase_two: bool) -> Array[String]:
	var base: Array = STAGE_SEQUENCES.get(stage_id, STAGE_SEQUENCES[&"stage_1"])
	var ordered: Array = [base[2], base[0], base[3], base[1]] if phase_two else base
	var result: Array[String] = []
	for value in ordered: result.append(String(value))
	return result


static func definition(pattern: String) -> Dictionary:
	return Dictionary(PATTERNS.get(StringName(pattern), PATTERNS[&"twin_foundry_lanes"]))


static func kind(pattern: String) -> StringName:
	return StringName(definition(pattern)["kind"])


static func startup_seconds(pattern: String) -> float:
	return float(definition(pattern)["startup"])


static func active_seconds(pattern: String) -> float:
	return float(definition(pattern)["active"])


static func recovery_seconds(pattern: String) -> float:
	return float(definition(pattern)["recovery"])


static func damage(pattern: String) -> float:
	return float(definition(pattern)["damage"])


static func affinity(pattern: String) -> StringName:
	return StringName(definition(pattern).get("affinity", &"kinetic"))


static func radius(pattern: String) -> float:
	return float(definition(pattern).get("radius", 210.0))


static func width(pattern: String) -> float:
	return float(definition(pattern).get("width", 68.0))


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
