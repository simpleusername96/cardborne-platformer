class_name FloodedWorksStage
extends RefCounted

## Central onboarding map: a safe calibration plaza links a west learning loop,
## a north/south generator fork, an optional northwest pocket, and the east boss.


static func definition() -> Dictionary:
	var generator_a := Vector2(2970.0, 690.0)
	var generator_b := Vector2(2970.0, 2110.0)
	var field_boss := Vector2(860.0, 680.0)
	var relay_cache := Vector2(3380.0, 1400.0)
	var boss_position := Vector2(3980.0, 1400.0)
	return {
		"id": &"flooded_works",
		"title_key": "STAGE_FLOODED_WORKS",
		"number": 1,
		"field_boss_name_key": "ENEMY_DREDGE_WARDEN",
		"boss_name_key": "ENEMY_FOUNDRY_COLOSSUS",
		"environment": &"none",
		"world_rect": Rect2(0.0, 0.0, 4400.0, 2800.0),
		"player_start": Vector2(2200.0, 1400.0),
		"start_clearance": 360.0,
		"boss_arena": Rect2(3600.0, 620.0, 720.0, 1560.0),
		"boss_gate": Rect2(3540.0, 1080.0, 60.0, 640.0),
		"walkable_regions": [
			{"id":"west_upper", "name":"West Learning Loop", "rect":Rect2(420,420,1120,820), "tone":&"light"},
			{"id":"west_lower", "name":"West Return Loop", "rect":Rect2(420,1560,1120,820), "tone":&"light"},
			{"id":"west_bridge", "name":"Calibration Causeway", "rect":Rect2(980,1120,940,560), "tone":&"mid"},
			{"id":"central_plaza", "name":"Calibration Plaza", "rect":Rect2(1800,960,800,880), "tone":&"light"},
			{"id":"north_riser", "name":"North Generator Rise", "rect":Rect2(2040,280,620,800), "tone":&"mid"},
			{"id":"north_lane", "name":"North Generator Lane", "rect":Rect2(2520,420,880,620), "tone":&"dark"},
			{"id":"south_riser", "name":"South Generator Drop", "rect":Rect2(2040,1720,620,800), "tone":&"mid"},
			{"id":"south_lane", "name":"South Generator Lane", "rect":Rect2(2520,1760,880,620), "tone":&"dark"},
			{"id":"relay_court", "name":"Relay Court", "rect":Rect2(3200,900,520,1000), "tone":&"mid"},
			{"id":"colossus_basin", "name":"Colossus Basin", "rect":Rect2(3560,580,800,1640), "tone":&"dark"},
		],
		"cover_rects": [
			Rect2(650,760,300,170), Rect2(650,1880,300,170),
			Rect2(1320,1260,250,280),
			Rect2(2730,760,260,150), Rect2(2730,1890,260,150),
			Rect2(3310,1080,170,180), Rect2(3310,1540,170,180),
			Rect2(4090,780,150,220), Rect2(4090,1800,150,220),
		],
		"water_rects": [
			Rect2(60,60,1520,260), Rect2(60,2480,1520,260),
			Rect2(1580,120,360,720), Rect2(1580,1960,360,720),
			Rect2(2720,1120,360,560),
		],
		"hazard_regions": [],
		"landmarks": {
			"start": Vector2(2200,1400),
			"open_entry": Vector2(1740,1400),
			"installation_entry": Vector2(2380,1040),
			"upper_route": Vector2(2380,720),
			"lower_route": Vector2(2380,2080),
			"generator_a": generator_a,
			"generator_b": generator_b,
			"field_boss": field_boss,
			"calibration_cache": Vector2(1860,1400),
			"chest": relay_cache,
			"boss_gate": Vector2(3570,1400),
			"boss": boss_position,
		},
		"objective_triggers": {
			"approach": Rect2(760,980,820,840),
			"installations": [Rect2(2460,300,980,820), Rect2(2460,1680,980,820)],
			"calibration": Rect2(1760,1180,360,440),
			"boss_start": Rect2(3580,580,780,1640),
			"field_boss_discovery": Rect2(420,360,1000,760),
			"relay_discovery": Rect2(3060,880,700,1040),
			"boss_discovery": Rect2(3420,520,940,1760),
			"upper_route_event": Rect2(2460,300,980,820),
			"lower_route_event": Rect2(2460,1680,980,820),
		},
		"static_enemies": _static_enemies(generator_a, generator_b, field_boss),
		"pickups": _pickups(),
		"crates": _crates(),
		"reward_anchors": {
			&"calibration_cache": Vector2(1860,1400),
			&"field_boss_cache": field_boss,
			&"relay_cache": relay_cache,
			&"boss_reward": boss_position,
		},
		"environment_zones": [],
		"packets": _packets(),
	}


static func _static_enemies(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2) -> Array[Dictionary]:
	return [
		{"id":"upper_turret", "role":"turret", "pos":Vector2(3050,950), "zone":"installations"},
		{"id":"lower_turret", "role":"turret", "pos":Vector2(3050,1810), "zone":"installations"},
		{"id":"upper_arc_mine", "role":"mine", "pos":Vector2(2720,590), "zone":"installations"},
		{"id":"lower_arc_mine", "role":"mine", "pos":Vector2(2720,2210), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"dredge_warden", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true},
	]


static func _packets() -> Array[Dictionary]:
	return [
		_packet("arrival_scout", 0, {"kind":&"time", "at":5.1}, Vector2(1680,1400), [[&"scrap_drone"]], 0.90, 8.0, "arrival"),
		_packet("west_learning", 1, {"kind":&"event", "id":&"approach_entered"}, Vector2(1420,1080), _squads(6, 3, [&"scrap_drone", &"needle_drone"]), 0.80, 8.0, "approach"),
		_packet("calibration_return", 2, {"kind":&"event", "id":&"calibration_claimed"}, Vector2(1500,1740), _squads(6, 4, [&"needle_drone", &"scrap_drone"]), 0.65, 6.0, "approach"),
		_packet("north_generator", 3, {"kind":&"event", "id":&"upper_route_entered"}, Vector2(2630,620), _squads(3, 5, [&"needle_drone", &"spark_minelet", &"scrap_drone"]), 0.50, 4.5, "installations"),
		_packet("south_generator", 3, {"kind":&"event", "id":&"lower_route_entered"}, Vector2(2630,2180), _squads(3, 5, [&"scrap_drone", &"spark_minelet", &"needle_drone"]), 0.50, 4.5, "installations"),
		_packet("relay_compound", 4, {"kind":&"event", "id":&"generators_complete"}, Vector2(3380,1400), _squads(7, 5, [&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser", &"shooter"]), 0.50, 4.5, "relay"),
	]


static func _packet(id: String, beat: int, trigger: Dictionary, anchor: Vector2, squads: Array, unit_spacing: float, squad_gap: float, zone: String) -> Dictionary:
	return {
		"id":id, "beat":beat, "trigger":trigger, "anchor":anchor, "squads":squads,
		"unit_spacing":unit_spacing, "squad_gap":squad_gap, "cue_lead":0.9,
		"zone":zone, "leash":Rect2(anchor - Vector2(520,420), Vector2(1040,840)),
	}


static func _squads(count: int, size: int, roles: Array[StringName]) -> Array:
	var result := []
	for squad_index in count:
		var squad: Array[StringName] = []
		for unit_index in size:
			squad.append(roles[(squad_index + unit_index) % roles.size()])
		result.append(squad)
	return result


static func _pickups() -> Array[Dictionary]:
	return [
		{"id":"repair_entry", "kind":"repair", "heal_amount":35.0, "pos":Vector2(1700,1400)},
		{"id":"experience_recall", "kind":"experience_recall", "pos":Vector2(3040,570)},
		{"id":"repair_boss_lane", "kind":"repair", "heal_amount":70.0, "pos":Vector2(3680,2050)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_repair_west", "pos":Vector2(730,1700), "drop":"repair"},
		{"id":"crate_repair", "pos":Vector2(1610,1510), "drop":"repair"},
		{"id":"crate_repair_relay", "pos":Vector2(3260,1410), "drop":"repair"},
		{"id":"crate_repair_loop", "pos":Vector2(1420,1160), "drop":"repair"},
		{"id":"crate_recall", "pos":Vector2(3700,690), "drop":"experience_recall"},
	]
