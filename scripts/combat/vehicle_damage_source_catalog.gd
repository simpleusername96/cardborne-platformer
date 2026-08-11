class_name VehicleDamageSourceCatalog
extends RefCounted

## Converts simulation-owned source tokens into bounded, stable report IDs.

const OUTGOING: Dictionary = {
	&"primary": "REPORT_SOURCE_PRIMARY",
	&"seeker": "REPORT_SOURCE_SEEKER",
	&"electric_field": "REPORT_SOURCE_ELECTRIC_FIELD",
	&"orbiting_blades": "REPORT_SOURCE_ORBITING_BLADES",
	&"drop_mine": "REPORT_SOURCE_DROP_MINE",
	&"emp": "REPORT_SOURCE_EMP",
	&"dash_impact": "REPORT_SOURCE_DASH",
	&"elemental_status": "REPORT_SOURCE_STATUS",
	&"thermal_burst": "REPORT_SOURCE_THERMAL_BURST",
	&"dash_afterburn": "REPORT_SOURCE_DASH_AFTERBURN",
	&"rear_laser": "REPORT_SOURCE_REAR_LASER",
	&"storm_barrage": "REPORT_SOURCE_STORM_BARRAGE",
	&"arc_mine": "REPORT_SOURCE_ARC_MINE",
	&"reflected": "REPORT_SOURCE_REFLECTED",
	&"other": "REPORT_SOURCE_OTHER",
}

const INCOMING: Dictionary = {
	&"projectile": "REPORT_INCOMING_PROJECTILE",
	&"contact": "REPORT_INCOMING_CONTACT",
	&"denial": "REPORT_INCOMING_DENIAL",
	&"environment": "REPORT_INCOMING_ENVIRONMENT",
	&"boss": "REPORT_INCOMING_BOSS",
	&"other": "REPORT_SOURCE_OTHER",
}


static func outgoing_id(source: String) -> StringName:
	var normalized := source.to_lower()
	if normalized.begins_with("reflected_"):
		return &"reflected"
	match normalized:
		"player_primary":
			return &"primary"
		"seeker":
			return &"seeker"
		"electric field":
			return &"electric_field"
		"orbiting blades":
			return &"orbiting_blades"
		"drop mine":
			return &"drop_mine"
		"emp nova":
			return &"emp"
		"dash impact":
			return &"dash_impact"
		"status":
			return &"elemental_status"
		"thermal_burst":
			return &"thermal_burst"
		"dash_afterburn":
			return &"dash_afterburn"
		"rear_laser":
			return &"rear_laser"
		"storm_barrage":
			return &"storm_barrage"
		"enemy_mine", "arc proximity burst", "player_arc_mine", "player_spark_minelet":
			return &"arc_mine"
		"seeker burst":
			return &"seeker"
	return &"other"


static func incoming_id(source: String, enemy_source: bool) -> StringName:
	if not enemy_source:
		return &"environment"
	var normalized := source.to_lower()
	if (
		"boss" in normalized
		or "colossus" in normalized
		or "furnace" in normalized
		or "archive" in normalized
		or "titan" in normalized
		or "crown" in normalized
		or "breaker" in normalized
		or "mirror" in normalized
	):
		return &"boss"
	if "bolt" in normalized or "shot" in normalized or "volley" in normalized or "beam" in normalized:
		return &"projectile"
	if "mine" in normalized or "burst" in normalized or "zone" in normalized or "impact" in normalized:
		return &"denial"
	if "contact" in normalized or "charge" in normalized or "lunge" in normalized:
		return &"contact"
	return &"other"


static func title_key(source_id: StringName, incoming: bool = false) -> String:
	var catalog := INCOMING if incoming else OUTGOING
	return String(catalog.get(source_id, "REPORT_SOURCE_OTHER"))


static func valid_outgoing_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for source_id in OUTGOING:
		result.append(StringName(source_id))
	return result


static func valid_incoming_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for source_id in INCOMING:
		result.append(StringName(source_id))
	return result
