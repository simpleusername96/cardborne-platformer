class_name VehicleBossProfileCatalog
extends RefCounted

## Absolute encounter values for each one-stage boss. These are intentionally
## not derived from the ordinary-enemy stage pressure curves.

const PROFILES: Array[Dictionary] = [
	{"health":16900.0, "move_speed":405.0, "attack_move_speed":251.1, "initial_autonomous_delay":2.144, "read_gaps":[0.2412, 0.1809, 0.14472], "autonomous_intervals":[3.216, 2.613, 2.077], "default_radius":262.5, "default_width":68.0, "lane_spacing":135.0, "fan_offsets":[-0.34, -0.17, 0.0, 0.17, 0.34]},
	{"health":21300.0, "move_speed":420.0, "attack_move_speed":268.8, "initial_autonomous_delay":2.080, "read_gaps":[0.234, 0.1755, 0.1404], "autonomous_intervals":[3.120, 2.535, 2.015], "default_radius":273.0, "default_width":70.72, "lane_spacing":140.4, "fan_offsets":[-0.3536, -0.1768, 0.0, 0.1768, 0.3536]},
	{"health":28300.0, "move_speed":435.0, "attack_move_speed":287.1, "initial_autonomous_delay":2.016, "read_gaps":[0.2268, 0.1701, 0.13608], "autonomous_intervals":[3.024, 2.457, 1.953], "default_radius":283.5, "default_width":73.44, "lane_spacing":145.8, "fan_offsets":[-0.3672, -0.1836, 0.0, 0.1836, 0.3672]},
	{"health":36800.0, "move_speed":450.0, "attack_move_speed":306.0, "initial_autonomous_delay":1.952, "read_gaps":[0.244, 0.183, 0.1464], "autonomous_intervals":[2.928, 2.379, 1.891], "default_radius":294.0, "default_width":76.16, "lane_spacing":151.2, "fan_offsets":[-0.3808, -0.1904, 0.0, 0.1904, 0.3808]},
	{"health":46700.0, "move_speed":465.0, "attack_move_speed":325.5, "initial_autonomous_delay":1.888, "read_gaps":[0.236, 0.177, 0.1416], "autonomous_intervals":[2.832, 2.301, 1.829], "default_radius":304.5, "default_width":78.88, "lane_spacing":156.6, "fan_offsets":[-0.3944, -0.1972, 0.0, 0.1972, 0.3944]},
	{"health":57500.0, "move_speed":480.0, "attack_move_speed":345.6, "initial_autonomous_delay":1.824, "read_gaps":[0.228, 0.171, 0.1368], "autonomous_intervals":[2.736, 2.223, 1.767], "default_radius":315.0, "default_width":81.60, "lane_spacing":162.0, "fan_offsets":[-0.408, -0.204, 0.0, 0.204, 0.408]},
	{"health":69200.0, "move_speed":500.0, "attack_move_speed":370.0, "initial_autonomous_delay":1.760, "read_gaps":[0.220, 0.165, 0.1320], "autonomous_intervals":[2.640, 2.145, 1.705], "default_radius":325.5, "default_width":84.32, "lane_spacing":167.4, "fan_offsets":[-0.4216, -0.2108, 0.0, 0.2108, 0.4216]},
	{"health":81600.0, "move_speed":515.0, "attack_move_speed":391.4, "initial_autonomous_delay":1.696, "read_gaps":[0.212, 0.159, 0.1272], "autonomous_intervals":[2.544, 2.067, 1.643], "default_radius":336.0, "default_width":87.04, "lane_spacing":172.8, "fan_offsets":[-0.4352, -0.2176, 0.0, 0.2176, 0.4352]},
	{"health":94600.0, "move_speed":525.0, "attack_move_speed":409.5, "initial_autonomous_delay":1.664, "read_gaps":[0.208, 0.156, 0.1248], "autonomous_intervals":[2.496, 2.028, 1.612], "default_radius":341.25, "default_width":88.40, "lane_spacing":175.5, "fan_offsets":[-0.442, -0.221, 0.0, 0.221, 0.442]},
	{"health":108200.0, "move_speed":535.0, "attack_move_speed":428.0, "initial_autonomous_delay":1.632, "read_gaps":[0.204, 0.153, 0.1224], "autonomous_intervals":[2.448, 1.989, 1.581], "default_radius":346.5, "default_width":89.76, "lane_spacing":178.2, "fan_offsets":[-0.4488, -0.2244, 0.0, 0.2244, 0.4488]},
	{"health":122300.0, "move_speed":540.0, "attack_move_speed":432.0, "initial_autonomous_delay":2.000, "read_gaps":[0.200, 0.150, 0.1200], "autonomous_intervals":[2.750, 2.300, 1.950], "default_radius":351.75, "default_width":91.12, "lane_spacing":180.9, "fan_offsets":[-0.4556, -0.2278, 0.0, 0.2278, 0.4556]},
	{"health":136890.0, "move_speed":555.0, "attack_move_speed":455.1, "initial_autonomous_delay":1.568, "read_gaps":[0.196, 0.147, 0.1176], "autonomous_intervals":[2.352, 1.911, 1.519], "default_radius":357.0, "default_width":92.48, "lane_spacing":183.6, "fan_offsets":[-0.4624, -0.2312, 0.0, 0.2312, 0.4624]},
]


static func profile(stage_index: int) -> Dictionary:
	if stage_index < 0 or stage_index >= PROFILES.size():
		return {}
	return PROFILES[stage_index]


static func stage_index_from_id(stage_id: StringName) -> int:
	var index := String(stage_id).trim_prefix("stage_").to_int() - 1
	return index if index >= 0 and index < PROFILES.size() else -1


static func health(stage_index: int) -> float:
	return float(profile(stage_index).get("health", 0.0))


static func move_speed(stage_index: int) -> float:
	return float(profile(stage_index).get("move_speed", 0.0))


static func attack_move_speed(stage_index: int) -> float:
	return float(profile(stage_index).get("attack_move_speed", 0.0))


static func read_gap(stage_index: int, phase: int) -> float:
	var gaps: Array = profile(stage_index).get("read_gaps", [])
	return float(gaps[clampi(phase - 1, 0, gaps.size() - 1)]) if not gaps.is_empty() else 0.0


static func autonomous_interval(stage_index: int, phase: int) -> float:
	var intervals: Array = profile(stage_index).get("autonomous_intervals", [])
	return float(intervals[clampi(phase - 1, 0, intervals.size() - 1)]) if not intervals.is_empty() else 0.0
