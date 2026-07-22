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
		"packets": _packets(),
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
		"upper_route_event":Rect2(2140,220,1300,760), "lower_route_event":Rect2(2140,1220,1300,820),
	}


static func _static_enemies(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2) -> Array[Dictionary]:
	return [
		{"id":"archive_interceptor_a", "role":"interceptor_tower", "pos":Vector2(2350,410), "zone":"installations"},
		{"id":"archive_interceptor_b", "role":"interceptor_tower", "pos":Vector2(2830,1810), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"current_curator", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true, "name_key":"ENEMY_CURRENT_CURATOR"},
	]


static func _packets() -> Array[Dictionary]:
	return [
		_packet("archive_arrival",0,{"kind":&"time","at":5.1},Vector2(760,1100),[[&"scrap_drone"]],0.90,8.0,"arrival"),
		_packet("archive_intake",1,{"kind":&"event","id":&"approach_entered"},Vector2(1120,1100),_squads(8,3,[&"scrap_drone",&"needle_drone"]),0.80,8.0,"approach"),
		_packet("archive_calibration",2,{"kind":&"event","id":&"calibration_claimed"},Vector2(1740,1100),_squads(8,4,[&"needle_drone",&"artillery_spotter",&"scrap_drone",&"spark_minelet"]),0.65,6.0,"approach"),
		_packet("archive_upper",3,{"kind":&"event","id":&"upper_route_entered"},Vector2(2500,520),_squads(4,5,[&"spark_minelet",&"needle_drone",&"scrap_drone"]),0.50,4.5,"installations"),
		_packet("archive_lower",3,{"kind":&"event","id":&"lower_route_entered"},Vector2(2500,1670),_squads(4,5,[&"scrap_drone",&"needle_drone",&"spark_minelet"]),0.50,4.5,"installations"),
		_packet("archive_relay",4,{"kind":&"event","id":&"generators_complete"},Vector2(3660,1120),_squads(6,5,[&"needle_drone",&"scrap_drone",&"spark_minelet"]),0.50,4.5,"relay"),
	]


static func _packet(id:String, beat:int, trigger:Dictionary, anchor:Vector2, squads:Array, spacing:float, gap:float, zone:String) -> Dictionary:
	return {"id":id,"beat":beat,"trigger":trigger,"anchor":anchor,"squads":squads,"unit_spacing":spacing,"squad_gap":gap,"cue_lead":0.9,"zone":zone,"leash":Rect2(anchor-Vector2(540,420),Vector2(1080,840))}


static func _squads(count:int, size:int, roles:Array[StringName]) -> Array:
	var result := []
	for squad_index in count:
		var squad:Array[StringName] = []
		for unit_index in size:
			squad.append(roles[(squad_index+unit_index)%roles.size()])
		result.append(squad)
	return result


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
