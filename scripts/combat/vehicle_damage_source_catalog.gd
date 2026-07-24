class_name VehicleDamageSourceCatalog
extends RefCounted

## Converts simulation-owned source tokens into bounded, stable report IDs.

const OUTGOING: Dictionary = {
	&"primary": "REPORT_SOURCE_PRIMARY",
	&"passive_seeker": "REPORT_SOURCE_SEEKER",
	&"ion_field": "REPORT_SOURCE_ION_FIELD",
	&"orbit_blades": "REPORT_SOURCE_ORBIT_BLADES",
	&"wake_mine": "REPORT_SOURCE_WAKE_MINE",
	&"escort_drone": "REPORT_SOURCE_ESCORT_DRONE",
	&"emp": "REPORT_SOURCE_EMP",
	&"emp_aftershock": "REPORT_SOURCE_EMP_AFTERSHOCK",
	&"dash_impact": "REPORT_SOURCE_DASH",
	&"elemental_status": "REPORT_SOURCE_STATUS",
	&"arc_surge": "REPORT_SOURCE_ARC_SURGE",
	&"arc_mine": "REPORT_SOURCE_ARC_MINE",
	&"ion_wake": "REPORT_SOURCE_ION_WAKE",
	&"reflected": "REPORT_SOURCE_REFLECTED",
	&"breach_burst": "REPORT_SOURCE_BREACH_BURST",
	&"ram_pulse": "REPORT_SOURCE_RAM_PULSE",
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
		"passive_seeker":
			return &"passive_seeker"
		"ion field":
			return &"ion_field"
		"orbit blades":
			return &"orbit_blades"
		"wake mine":
			return &"wake_mine"
		"escort drone":
			return &"escort_drone"
		"emp nova":
			return &"emp"
		"emp aftershock":
			return &"emp_aftershock"
		"dash impact":
			return &"dash_impact"
		"status":
			return &"elemental_status"
		"arc surge":
			return &"arc_surge"
		"enemy_mine", "arc proximity burst", "player_arc_mine", "player_spark_minelet":
			return &"arc_mine"
		"ion wake":
			return &"ion_wake"
		"shock breach":
			return &"breach_burst"
		"ram pulse":
			return &"ram_pulse"
		"seeker burst":
			return &"passive_seeker"
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
