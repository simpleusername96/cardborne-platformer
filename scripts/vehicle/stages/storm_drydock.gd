class_name StormDrydockStage
extends RefCounted

## Stage 3 definition. Large grounded courts remain readable while electrical
## sweep zones are stored beside the geometry they affect.


static func definition() -> Dictionary:
	var generator_a := Vector2(2300.0, 570.0)
	var generator_b := Vector2(2880.0, 1650.0)
	var field_boss := Vector2(2860.0, 330.0)
	var relay_cache := Vector2(3470.0, 1120.0)
	var boss_position := Vector2(4580.0, 1090.0)
	return {
		"id":&"storm_drydock", "title_key":"STAGE_STORM_DRYDOCK", "number":3,
		"field_boss_name_key":"ENEMY_STORM_FOREMAN", "boss_name_key":"ENEMY_DRYDOCK_TITAN",
		"environment":&"storm", "world_rect":Rect2(0,0,5200,2200), "player_start":Vector2(330,1100),
		"start_clearance":360.0, "boss_arena":Rect2(3970,420,1100,1360), "boss_gate":Rect2(3890,820,70,560),
		"walkable_regions":_walkable_regions(), "cover_rects":_cover_rects(), "water_rects":_water_rects(),
		"hazard_regions":[], "landmarks":_landmarks(generator_a,generator_b,field_boss,relay_cache,boss_position),
		"objective_triggers":_objective_triggers(), "static_enemies":_static_enemies(generator_a,generator_b,field_boss),
		"legacy_swarm_groups":_legacy_swarm_groups(), "pickups":_pickups(), "crates":_crates(),
		"reward_anchors":{&"calibration_cache":Vector2(1760,1100), &"field_boss_cache":field_boss, &"relay_cache":relay_cache, &"boss_reward":boss_position},
		"environment_zones":[
			{"rect":Rect2(760,540,3000,260), "phase":0.0},
			{"rect":Rect2(760,1400,3000,260), "phase":2.2},
		],
		"packets":[],
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"service", "name":"Service Plaza", "rect":Rect2(70,680,620,840), "tone":&"light"},
		{"id":"rails", "name":"Drydock Rails", "rect":Rect2(600,260,1440,1680), "tone":&"mid"},
		{"id":"gantries", "name":"Storm Gantries", "rect":Rect2(1940,100,1540,2000), "tone":&"dark"},
		{"id":"court", "name":"Launch Court", "rect":Rect2(3260,560,760,1080), "tone":&"mid"},
		{"id":"cradle", "name":"Titan Cradle", "rect":Rect2(3910,380,1160,1440), "tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(880,820,420,170), Rect2(1120,1260,420,180),
		Rect2(1580,430,180,430), Rect2(1580,1370,180,430),
		Rect2(1900,70,160,560), Rect2(1900,1580,160,550),
		Rect2(2200,820,300,430), Rect2(2660,760,240,380),
		Rect2(3060,330,260,250), Rect2(3020,1500,300,220),
		Rect2(3380,700,220,220), Rect2(3400,1360,200,230),
		Rect2(4200,610,170,230), Rect2(4200,1360,170,230),
		Rect2(4740,610,170,230), Rect2(4740,1360,170,230),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(690,70,190,680), Rect2(690,1450,190,680),
		Rect2(1380,70,200,420), Rect2(1380,1710,200,420),
		Rect2(2060,70,140,620), Rect2(2060,1510,140,620),
		Rect2(3320,70,180,540), Rect2(3320,1660,180,470),
	]


static func _landmarks(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2, relay_cache: Vector2, boss_position: Vector2) -> Dictionary:
	return {
		"start":Vector2(330,1100), "open_entry":Vector2(760,1100), "installation_entry":Vector2(1940,1100),
		"upper_route":Vector2(2500,520), "lower_route":Vector2(2500,1670), "generator_a":generator_a,
		"generator_b":generator_b, "field_boss":field_boss, "calibration_cache":Vector2(1760,1100),
		"chest":relay_cache, "boss_gate":Vector2(3860,1100), "boss":boss_position,
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
		{"id":"drydock_chaser_a", "role":"chaser", "pos":Vector2(950,660), "zone":"approach"},
		{"id":"drydock_escort_a", "role":"shield_escort", "pos":Vector2(1090,1120), "zone":"approach"},
		{"id":"drydock_shooter_a", "role":"shooter", "pos":Vector2(1450,1080), "zone":"approach"},
		{"id":"drydock_chaser_b", "role":"chaser", "pos":Vector2(1730,1160), "zone":"approach"},
		{"id":"drydock_interceptor", "role":"interceptor_tower", "pos":Vector2(2340,680), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"drydock_escort_b", "role":"shield_escort", "pos":Vector2(3060,1180), "zone":"installations"},
		{"id":"drydock_spotter", "role":"artillery_spotter", "pos":Vector2(3290,1050), "zone":"installations"},
		{"id":"drydock_shooter_b", "role":"shooter", "pos":Vector2(3200,1800), "zone":"installations"},
		{"id":"storm_foreman", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true, "name_key":"ENEMY_STORM_FOREMAN"},
	]


static func _legacy_swarm_groups() -> Array[Dictionary]:
	return [
		{"id":"drydock_swarm_a", "anchor":Vector2(860,660), "count":31, "roles":[&"scrap_drone", &"needle_drone"], "zone":"approach", "angle":0.1},
		{"id":"drydock_swarm_b", "anchor":Vector2(1090,1120), "count":30, "roles":[&"scrap_drone", &"spark_minelet"], "zone":"approach", "angle":1.0},
		{"id":"drydock_swarm_c", "anchor":Vector2(1450,1080), "count":30, "roles":[&"needle_drone", &"scrap_drone"], "zone":"approach", "angle":0.8},
		{"id":"drydock_swarm_d", "anchor":Vector2(1730,1160), "count":30, "roles":[&"spark_minelet", &"scrap_drone"], "zone":"approach", "angle":0.15},
		{"id":"drydock_swarm_e", "anchor":Vector2(2340,680), "count":30, "roles":[&"needle_drone", &"spark_minelet"], "zone":"installations", "angle":1.05},
		{"id":"drydock_swarm_f", "anchor":Vector2(3060,1180), "count":30, "roles":[&"scrap_drone", &"needle_drone"], "zone":"installations", "angle":0.25},
		{"id":"drydock_swarm_g", "anchor":Vector2(3290,1050), "count":30, "roles":[&"needle_drone", &"spark_minelet"], "zone":"installations", "angle":0.7},
		{"id":"drydock_swarm_h", "anchor":Vector2(3200,1840), "count":30, "roles":[&"scrap_drone", &"needle_drone", &"spark_minelet"], "zone":"installations", "angle":0.95},
	]


static func _pickups() -> Array[Dictionary]:
	return [
		{"id":"repair_open", "kind":"repair", "pos":Vector2(1540,990)},
		{"id":"attack_upper", "kind":"attack_boost", "pos":Vector2(2300,410)},
		{"id":"coolant_upper", "kind":"coolant", "pos":Vector2(2580,370)},
		{"id":"overdrive_lower", "kind":"overdrive", "pos":Vector2(2280,1750)},
		{"id":"barrier_lower", "kind":"barrier", "pos":Vector2(2900,1850)},
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
