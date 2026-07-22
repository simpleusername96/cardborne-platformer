class_name TidalArchiveStage
extends RefCounted

## Stage 2 definition. Its geometry is isolated here so the catalog, simulation,
## renderer, minimap, and validators all consume one authored source.


static func definition() -> Dictionary:
	var generator_a := Vector2(2300.0, 570.0)
	var generator_b := Vector2(2880.0, 1650.0)
	var field_boss := Vector2(2860.0, 330.0)
	var relay_cache := Vector2(3470.0, 1120.0)
	var boss_position := Vector2(4580.0, 1090.0)
	return {
		"id": &"tidal_archive",
		"title_key": "STAGE_TIDAL_ARCHIVE",
		"number": 2,
		"field_boss_name_key": "ENEMY_CURRENT_CURATOR",
		"boss_name_key": "ENEMY_ARCHIVE_LEVIATHAN",
		"environment": &"current",
		"world_rect": Rect2(0,0,5200,2200),
		"player_start": Vector2(330,1100),
		"start_clearance": 360.0,
		"boss_arena": Rect2(3970,420,1100,1360),
		"boss_gate": Rect2(3890,820,70,560),
		"walkable_regions": _walkable_regions(),
		"cover_rects": _cover_rects(),
		"water_rects": _water_rects(),
		"hazard_regions": [],
		"landmarks": _landmarks(generator_a, generator_b, field_boss, relay_cache, boss_position),
		"objective_triggers": _objective_triggers(),
		"static_enemies": _static_enemies(generator_a, generator_b, field_boss),
		"legacy_swarm_groups": _legacy_swarm_groups(),
		"pickups": _pickups(),
		"crates": _crates(),
		"reward_anchors": {
			&"calibration_cache": Vector2(1760,1100), &"field_boss_cache":field_boss,
			&"relay_cache":relay_cache, &"boss_reward":boss_position,
		},
		"environment_zones": [
			{"rect":Rect2(720,980,1120,240), "direction":Vector2.RIGHT, "strength":72.0},
			{"rect":Rect2(2000,1440,1350,220), "direction":Vector2.LEFT, "strength":86.0},
		],
		"packets": [],
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"intake", "name":"Intake Shelf", "rect":Rect2(70,680,620,840), "tone":&"light"},
		{"id":"gallery", "name":"Current Gallery", "rect":Rect2(600,260,1440,1680), "tone":&"mid"},
		{"id":"channels", "name":"Archive Channels", "rect":Rect2(1940,100,1540,2000), "tone":&"dark"},
		{"id":"court", "name":"Index Court", "rect":Rect2(3260,560,760,1080), "tone":&"mid"},
		{"id":"vault", "name":"Leviathan Vault", "rect":Rect2(3910,380,1160,1440), "tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(900,350,260,240), Rect2(930,1600,280,230),
		Rect2(1320,760,320,190), Rect2(1320,1260,320,180),
		Rect2(1900,70,160,600), Rect2(1900,1530,160,600),
		Rect2(2100,820,640,180), Rect2(2300,1200,640,180),
		Rect2(2800,650,260,200), Rect2(3100,1450,280,220),
		Rect2(3260,650,190,260), Rect2(3440,1360,170,250),
		Rect2(4200,610,170,230), Rect2(4200,1360,170,230),
		Rect2(4740,610,170,230), Rect2(4740,1360,170,230),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(690,70,200,520), Rect2(690,1610,200,520),
		Rect2(1160,70,210,580), Rect2(1660,1550,240,580),
		Rect2(2060,70,180,650), Rect2(2060,1480,180,650),
		Rect2(3000,70,220,470), Rect2(3000,1750,220,380),
	]


static func _landmarks(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2, relay_cache: Vector2, boss_position: Vector2) -> Dictionary:
	return {
		"start":Vector2(330,1100), "open_entry":Vector2(760,1100),
		"installation_entry":Vector2(1940,1100), "upper_route":Vector2(2500,520),
		"lower_route":Vector2(2500,1670), "generator_a":generator_a, "generator_b":generator_b,
		"field_boss":field_boss, "calibration_cache":Vector2(1760,1100), "chest":relay_cache,
		"boss_gate":Vector2(3860,1100), "boss":boss_position,
	}


static func _objective_triggers() -> Dictionary:
	return {
		"approach":Rect2(680,620,1160,960), "installations":Rect2(1840,100,1740,2000),
		"calibration":Rect2(1640,980,260,260), "boss_start":Rect2(3940,380,1160,1440),
		"field_boss_discovery":Rect2(2440,80,820,640), "relay_discovery":Rect2(3240,760,600,720),
		"boss_discovery":Rect2(3760,300,1340,1600),
	}


static func _static_enemies(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2) -> Array[Dictionary]:
	return [
		{"id":"archive_chaser_a", "role":"chaser", "pos":Vector2(880,1120), "zone":"approach"},
		{"id":"archive_spotter_a", "role":"artillery_spotter", "pos":Vector2(1230,700), "zone":"approach"},
		{"id":"archive_chaser_b", "role":"chaser", "pos":Vector2(1460,1600), "zone":"approach"},
		{"id":"archive_shooter", "role":"shooter", "pos":Vector2(1740,1120), "zone":"approach"},
		{"id":"archive_interceptor_a", "role":"interceptor_tower", "pos":Vector2(2350,410), "zone":"installations"},
		{"id":"archive_interceptor_b", "role":"interceptor_tower", "pos":Vector2(2830,1810), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"archive_spotter_b", "role":"artillery_spotter", "pos":Vector2(3160,1110), "zone":"installations"},
		{"id":"archive_controller", "role":"controller", "pos":Vector2(3320,1280), "zone":"installations"},
		{"id":"current_curator", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true, "name_key":"ENEMY_CURRENT_CURATOR"},
	]


static func _legacy_swarm_groups() -> Array[Dictionary]:
	return [
		{"id":"archive_swarm_a", "anchor":Vector2(880,1120), "count":28, "roles":[&"scrap_drone", &"needle_drone"], "zone":"approach", "angle":0.15},
		{"id":"archive_swarm_b", "anchor":Vector2(1270,650), "count":27, "roles":[&"needle_drone", &"spark_minelet"], "zone":"approach", "angle":0.85},
		{"id":"archive_swarm_c", "anchor":Vector2(1460,1600), "count":27, "roles":[&"scrap_drone", &"needle_drone"], "zone":"approach", "angle":0.75},
		{"id":"archive_swarm_d", "anchor":Vector2(1740,1120), "count":27, "roles":[&"needle_drone", &"scrap_drone"], "zone":"approach", "angle":0.1},
		{"id":"archive_swarm_e", "anchor":Vector2(2350,410), "count":27, "roles":[&"spark_minelet", &"needle_drone"], "zone":"installations", "angle":0.65},
		{"id":"archive_swarm_f", "anchor":Vector2(2830,1810), "count":27, "roles":[&"scrap_drone", &"spark_minelet"], "zone":"installations", "angle":0.2},
		{"id":"archive_swarm_g", "anchor":Vector2(3160,1110), "count":27, "roles":[&"needle_drone", &"scrap_drone"], "zone":"installations", "angle":0.9},
		{"id":"archive_swarm_h", "anchor":Vector2(3320,1280), "count":27, "roles":[&"scrap_drone", &"needle_drone", &"spark_minelet"], "zone":"installations", "angle":0.35},
	]


static func _pickups() -> Array[Dictionary]:
	return [
		{"id":"repair_open", "kind":"repair", "pos":Vector2(1540,990)},
		{"id":"attack_upper", "kind":"attack_boost", "pos":Vector2(2300,410)},
		{"id":"coolant_upper", "kind":"coolant", "pos":Vector2(2580,370)},
		{"id":"overdrive_lower", "kind":"overdrive", "pos":Vector2(2280,1750)},
		{"id":"barrier_lower", "kind":"barrier", "pos":Vector2(3260,1840)},
		{"id":"seeker_relay", "kind":"seeker_battery", "pos":Vector2(3660,920)},
		{"id":"capacitor_relay", "kind":"capacitor_cell", "pos":Vector2(3660,1110)},
		{"id":"magnet_boss_lane", "kind":"magnet_field", "pos":Vector2(4030,1570)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_attack", "pos":Vector2(1080,1510), "drop":"attack_boost"},
		{"id":"crate_repair", "pos":Vector2(1810,1080), "drop":"repair"},
		{"id":"crate_barrier", "pos":Vector2(3360,1120), "drop":"barrier"},
		{"id":"crate_coolant", "pos":Vector2(1580,1050), "drop":"coolant"},
		{"id":"crate_seeker", "pos":Vector2(3980,680), "drop":"seeker_battery"},
	]
