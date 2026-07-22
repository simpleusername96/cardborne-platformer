class_name VehicleBossPatterns
extends RefCounted

## Data-owned boss exams. Damage values are final Standard damage and therefore
## bypass ordinary enemy and stage multipliers in VehicleRun.

const PATTERNS := {
	&"twin_foundry_lanes":{"kind":&"lanes", "startup":0.90, "active":0.80, "recovery":1.00, "damage":20.0},
	&"foundry_ram":{"kind":&"charge", "startup":1.10, "active":0.65, "recovery":1.30, "damage":34.0},
	&"furnace_ring":{"kind":&"area", "startup":0.90, "active":0.60, "recovery":1.00, "damage":26.0, "radius":230.0},
	&"pylon_overload":{"kind":&"pylons", "startup":0.85, "active":0.55, "recovery":1.15, "damage":24.0, "radius":205.0},

	&"current_fan":{"kind":&"fan", "startup":0.85, "active":0.65, "recovery":0.95, "damage":20.0},
	&"undertow_sweep":{"kind":&"beam", "startup":0.95, "active":0.75, "recovery":1.10, "damage":28.0, "width":70.0},
	&"depth_charge":{"kind":&"area", "startup":1.10, "active":0.55, "recovery":1.25, "damage":32.0, "radius":185.0},
	&"archive_ram":{"kind":&"charge", "startup":1.10, "active":0.65, "recovery":1.35, "damage":34.0},

	&"arc_lanes":{"kind":&"lanes", "startup":0.85, "active":0.80, "recovery":0.95, "damage":22.0},
	&"grounded_ring":{"kind":&"area", "startup":0.95, "active":0.65, "recovery":1.10, "damage":28.0, "radius":235.0},
	&"thunder_drop":{"kind":&"area", "startup":1.10, "active":0.50, "recovery":1.35, "damage":34.0, "radius":175.0},
	&"escort_surge":{"kind":&"summon", "startup":0.85, "active":0.80, "recovery":1.20, "damage":24.0, "radius":190.0},

	&"open_lane_charge":{"kind":&"charge", "startup":1.10, "active":0.70, "recovery":1.45, "damage":36.0},
	&"gate_shockwave":{"kind":&"area", "startup":0.90, "active":0.55, "recovery":1.05, "damage":28.0, "radius":240.0},
	&"ricochet_volley":{"kind":&"fan", "startup":0.85, "active":0.70, "recovery":1.00, "damage":22.0},
	&"switch_sweep":{"kind":&"beam", "startup":1.00, "active":0.80, "recovery":1.20, "damage":30.0, "width":78.0},

	&"crown_beam":{"kind":&"beam", "startup":1.15, "active":0.80, "recovery":1.30, "damage":34.0, "width":82.0},
	&"mirror_cross":{"kind":&"cross", "startup":0.95, "active":0.65, "recovery":1.10, "damage":28.0},
	&"carrier_wave":{"kind":&"summon", "startup":0.85, "active":0.85, "recovery":1.25, "damage":0.0},
	&"relay_pulse":{"kind":&"area", "startup":0.95, "active":0.60, "recovery":1.10, "damage":30.0, "radius":225.0},
}

const STAGE_SEQUENCES := {
	&"flooded_works":[&"twin_foundry_lanes", &"foundry_ram", &"furnace_ring", &"pylon_overload"],
	&"tidal_archive":[&"current_fan", &"undertow_sweep", &"depth_charge", &"archive_ram"],
	&"storm_drydock":[&"arc_lanes", &"grounded_ring", &"thunder_drop", &"escort_surge"],
	&"coral_switchyard":[&"open_lane_charge", &"gate_shockwave", &"ricochet_volley", &"switch_sweep"],
	&"abyssal_observatory":[&"crown_beam", &"mirror_cross", &"carrier_wave", &"relay_pulse"],
}

const FIELD_PATTERNS := {
	&"field_ram":{"kind":&"charge", "startup":1.05, "active":0.55, "recovery":1.05, "damage":30.0, "radius":170.0},
	&"field_pressure":{"kind":&"area", "startup":0.90, "active":0.55, "recovery":0.95, "damage":28.0, "radius":155.0},
	&"foundry_fan":{"kind":&"fan", "startup":1.10, "active":0.55, "recovery":0.95, "damage":26.0, "radius":170.0},
	&"current_wake":{"kind":&"fan", "startup":1.10, "active":0.60, "recovery":1.00, "damage":28.0, "radius":175.0},
	&"arc_drop":{"kind":&"area", "startup":1.10, "active":0.50, "recovery":1.10, "damage":32.0, "radius":165.0},
	&"switch_shock":{"kind":&"area", "startup":1.10, "active":0.55, "recovery":1.00, "damage":28.0, "radius":180.0},
	&"mirror_fan":{"kind":&"fan", "startup":1.10, "active":0.60, "recovery":1.05, "damage":30.0, "radius":175.0},
}

const FIELD_STAGE_VERB := {
	&"flooded_works":&"foundry_fan", &"tidal_archive":&"current_wake", &"storm_drydock":&"arc_drop",
	&"coral_switchyard":&"switch_shock", &"abyssal_observatory":&"mirror_fan",
}


static func sequence(stage_id: StringName, phase_two: bool) -> Array[String]:
	var base: Array = STAGE_SEQUENCES.get(stage_id, STAGE_SEQUENCES[&"flooded_works"])
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


static func radius(pattern: String) -> float:
	return float(definition(pattern).get("radius", 210.0))


static func width(pattern: String) -> float:
	return float(definition(pattern).get("width", 68.0))


static func field_sequence(stage_id: StringName) -> Array[StringName]:
	return [&"field_ram", &"field_pressure", StringName(FIELD_STAGE_VERB.get(stage_id, &"foundry_fan"))]


static func field_definition(pattern: String) -> Dictionary:
	return Dictionary(FIELD_PATTERNS.get(StringName(pattern), FIELD_PATTERNS[&"field_ram"]))
