class_name VehicleVisualEventCatalog
extends RefCounted

## Presentation-only contract for the four transient visuals that are actually
## buffered and rendered. Gameplay truth and direct actor/HUD feedback stay out.

const EVENTS := {
	&"player_dash_afterimage": {
		"mode": &"hull_afterimage",
		"rotation": &"direction",
	},
	&"player_emp_charge": {"mode": &"live_emp_radius"},
	&"player_emp_release": {
		"mode": &"authored_emp",
		"asset": &"effect/emp_release",
	},
	&"thermal_burst_impact": {
		"mode": &"authored_thermal",
		"asset": &"effect/thermal_burst_impact",
	},
}


static func has_event(event_id: StringName) -> bool:
	return EVENTS.has(event_id)


static func descriptor(event_id: StringName) -> Dictionary:
	return Dictionary(EVENTS.get(event_id, {}))


static func event_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for event_id in EVENTS:
		ids.append(StringName(event_id))
	ids.sort()
	return ids
