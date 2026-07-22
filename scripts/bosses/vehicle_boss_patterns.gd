class_name VehicleBossPatterns
extends RefCounted

## Stage-selected boss sequences and timing. VehicleRun executes these entries;
## this owner keeps content selection out of the shared combat state machine.


static func sequence(stage_id: StringName, phase_two: bool) -> Array[String]:
	var values: Array
	match stage_id:
		&"coral_switchyard":
			values = ["switch_charge", "switch_charge"]
		&"abyssal_observatory":
			values = ["crown_beam", "crown_carrier", "crown_beam"] if phase_two else ["crown_beam", "crown_carrier"]
		_:
			values = ["overload_combo", "pylons", "lane_barrage", "charge"] if phase_two else ["lane_barrage", "charge", "pylons", "lane_barrage", "charge"]
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result


static func startup_seconds(pattern: String) -> float:
	return {
		"lane_barrage":0.95, "charge":0.86, "pylons":1.05, "overload_combo":1.10,
		"switch_charge":1.00, "crown_beam":1.20, "crown_carrier":1.00,
	}.get(pattern, 0.9)


static func active_seconds(pattern: String) -> float:
	return {
		"lane_barrage":1.55, "charge":0.58, "overload_combo":1.35,
		"switch_charge":0.92, "crown_beam":0.75, "crown_carrier":2.20,
	}.get(pattern, 0.0)


static func recovery_seconds(pattern: String) -> float:
	return {
		"charge":1.30, "switch_charge":1.55, "crown_beam":1.15,
		"crown_carrier":1.40,
	}.get(pattern, 1.05)
