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
			Rect2(650,760,300,170), Rect2(1030,520,190,260),
			Rect2(650,1880,300,170), Rect2(1050,2020,210,220),
			Rect2(1320,1260,250,280),
			Rect2(2130,460,170,240), Rect2(2730,760,260,150), Rect2(3120,500,150,260),
			Rect2(2130,2100,170,240), Rect2(2730,1890,260,150), Rect2(3120,2040,150,260),
			Rect2(3310,1080,170,180), Rect2(3310,1540,170,180),
			Rect2(3750,780,150,220), Rect2(3750,1800,150,220),
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
			"open_entry": Vector2(1640,1400),
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
		},
		"static_enemies": _static_enemies(generator_a, generator_b, field_boss),
		"legacy_swarm_groups": _legacy_swarm_groups(),
		"pickups": _pickups(),
		"crates": _crates(),
		"reward_anchors": {
			&"calibration_cache": Vector2(1860,1400),
			&"field_boss_cache": field_boss,
			&"relay_cache": relay_cache,
			&"boss_reward": boss_position,
		},
		"environment_zones": [],
		"packets": [],
	}


static func _static_enemies(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2) -> Array[Dictionary]:
	return [
		{"id":"approach_chaser_a", "role":"chaser", "pos":Vector2(1450,1000), "zone":"approach"},
		{"id":"approach_shooter_a", "role":"shooter", "pos":Vector2(1320,700), "zone":"approach"},
		{"id":"approach_chaser_b", "role":"chaser", "pos":Vector2(1420,1800), "zone":"approach"},
		{"id":"approach_controller", "role":"controller", "pos":Vector2(1000,2120), "zone":"approach"},
		{"id":"approach_shooter_b", "role":"shooter", "pos":Vector2(720,1120), "zone":"approach"},
		{"id":"upper_turret", "role":"turret", "pos":Vector2(3050,950), "zone":"installations"},
		{"id":"lower_turret", "role":"turret", "pos":Vector2(3050,1810), "zone":"installations"},
		{"id":"upper_arc_mine", "role":"mine", "pos":Vector2(2720,590), "zone":"installations"},
		{"id":"lower_arc_mine", "role":"mine", "pos":Vector2(2720,2210), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"install_chaser", "role":"chaser", "pos":Vector2(3360,980), "zone":"installations"},
		{"id":"install_shooter", "role":"shooter", "pos":Vector2(3360,1820), "zone":"installations"},
		{"id":"install_controller", "role":"controller", "pos":Vector2(3480,1400), "zone":"installations"},
		{"id":"dredge_warden", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true},
	]


static func _legacy_swarm_groups() -> Array[Dictionary]:
	return [
		{"id":"works_swarm_a", "anchor":Vector2(1480,1050), "count":27, "roles":[&"scrap_drone", &"needle_drone"], "zone":"approach", "angle":0.1},
		{"id":"works_swarm_b", "anchor":Vector2(970,700), "count":27, "roles":[&"needle_drone", &"spark_minelet"], "zone":"approach", "angle":0.5},
		{"id":"works_swarm_c", "anchor":Vector2(1030,2060), "count":27, "roles":[&"scrap_drone", &"needle_drone"], "zone":"approach", "angle":0.8},
		{"id":"works_swarm_d", "anchor":Vector2(1450,1740), "count":27, "roles":[&"scrap_drone", &"spark_minelet"], "zone":"approach", "angle":0.2},
		{"id":"works_swarm_e", "anchor":Vector2(2820,620), "count":27, "roles":[&"needle_drone", &"spark_minelet"], "zone":"installations", "angle":1.15},
		{"id":"works_swarm_f", "anchor":Vector2(2820,2180), "count":27, "roles":[&"scrap_drone", &"spark_minelet"], "zone":"installations", "angle":0.25},
		{"id":"works_swarm_g", "anchor":Vector2(3350,1400), "count":27, "roles":[&"scrap_drone", &"needle_drone"], "zone":"installations", "angle":0.9},
	]


static func _pickups() -> Array[Dictionary]:
	return [
		{"id":"repair_open", "kind":"repair", "pos":Vector2(1700,1400)},
		{"id":"attack_upper", "kind":"attack_boost", "pos":Vector2(2350,560)},
		{"id":"coolant_upper", "kind":"coolant", "pos":Vector2(3040,570)},
		{"id":"overdrive_lower", "kind":"overdrive", "pos":Vector2(2350,2240)},
		{"id":"barrier_lower", "kind":"barrier", "pos":Vector2(3040,2230)},
		{"id":"seeker_relay", "kind":"seeker_battery", "pos":Vector2(3390,980)},
		{"id":"capacitor_relay", "kind":"capacitor_cell", "pos":Vector2(3390,1820)},
		{"id":"magnet_boss_lane", "kind":"magnet_field", "pos":Vector2(3680,2050)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_attack", "pos":Vector2(730,1700), "drop":"attack_boost"},
		{"id":"crate_repair", "pos":Vector2(1610,1510), "drop":"repair"},
		{"id":"crate_barrier", "pos":Vector2(3260,1410), "drop":"barrier"},
		{"id":"crate_coolant", "pos":Vector2(1420,1160), "drop":"coolant"},
		{"id":"crate_seeker", "pos":Vector2(3700,690), "drop":"seeker_battery"},
	]
