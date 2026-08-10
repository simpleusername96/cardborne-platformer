class_name VehicleVisualEventCatalog
extends RefCounted

## Presentation-only contract for the bounded transient visuals that are
## buffered and rendered. Gameplay truth and direct actor/HUD feedback stay out.

const EVENTS := {
	&"player_dash_afterimage": {
		"mode": &"hull_afterimage",
		"rotation": &"direction",
	},
	&"player_emp_charge": {"mode": &"live_emp_radius"},
	&"player_emp_release": {"mode": &"emp_area"},
	&"thermal_burst_impact": {"mode": &"thermal_area"},
	&"drop_mine_detonation": {"mode": &"drop_mine_area"},
	&"mystery_projectile_purge": {
		"mode": &"mystery_purge_pulse",
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
