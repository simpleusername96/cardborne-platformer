class_name TidalArchiveStage
extends RefCounted

## Stage 2 definition. Its geometry is isolated here so the catalog, simulation,
## renderer, minimap, and validators all consume one authored source.


static func definition() -> Dictionary:
	var generator_a := Vector2(2860.0, 740.0)
	var generator_b := Vector2(2860.0, 2060.0)
	var field_boss := Vector2(2780.0, 320.0)
	var relay_cache := Vector2(3500.0, 1400.0)
	var boss_position := Vector2(4440.0, 1400.0)
	return {
		"id": &"tidal_archive",
		"title_key": "STAGE_TIDAL_ARCHIVE",
		"number": 2,
		"field_boss_name_key": "ENEMY_CURRENT_CURATOR",
		"boss_name_key": "ENEMY_ARCHIVE_LEVIATHAN",
		"environment": &"current",
		"world_rect": Rect2(0,0,5000,2800),
		"player_start": Vector2(520,1400),
		"start_clearance": 360.0,
		"boss_arena": Rect2(3980,620,900,1560),
		"boss_gate": Rect2(3920,1080,60,640),
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
			&"calibration_cache": Vector2(1660,1400), &"field_boss_cache":field_boss,
			&"relay_cache":relay_cache, &"boss_reward":boss_position,
		},
		"environment_zones": [
			{"id":&"upper_current", "rect":Rect2(1840,540,1320,400), "direction":Vector2.RIGHT, "strength":72.0},
			{"id":&"lower_current", "rect":Rect2(1840,1860,1320,400), "direction":Vector2.LEFT, "strength":86.0},
			{"id":&"counter_current", "rect":Rect2(2460,190,640,300), "direction":Vector2.LEFT, "strength":92.0, "optional":true},
		],
		"packets": _packets(),
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"intake", "name":"Safe Intake Plaza", "rect":Rect2(160,1040,800,720), "tone":&"light"},
		{"id":"gallery", "name":"Current Gallery", "rect":Rect2(780,500,1180,1800), "tone":&"mid"},
		{"id":"upper_channel", "name":"Upper Current Lane", "rect":Rect2(1780,420,1500,640), "tone":&"dark"},
		{"id":"lower_channel", "name":"Lower Current Lane", "rect":Rect2(1780,1740,1500,640), "tone":&"dark"},
		{"id":"counter_branch", "name":"Counter-current Annex", "rect":Rect2(2380,120,800,460), "tone":&"light"},
		{"id":"index_court", "name":"Index Court", "rect":Rect2(3040,800,820,1200), "tone":&"mid"},
		{"id":"vault_causeway", "name":"Vault Causeway", "rect":Rect2(3680,1040,360,720), "tone":&"light"},
		{"id":"vault", "name":"Leviathan Vault", "rect":Rect2(3980,620,900,1560), "tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(1040,720,240,220), Rect2(1040,1840,240,220),
		Rect2(1420,1040,260,180), Rect2(1420,1580,260,180),
		Rect2(2140,660,260,150), Rect2(2140,1990,260,150),
		Rect2(2620,930,300,130), Rect2(2620,1740,300,130),
		Rect2(3150,980,170,250), Rect2(3150,1570,170,250),
		Rect2(3500,880,170,220), Rect2(3500,1700,170,220),
		Rect2(4160,800,150,220), Rect2(4160,1780,150,220),
		Rect2(4580,800,150,220), Rect2(4580,1780,150,220),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(40,160,1380,720), Rect2(40,1920,1380,720),
		Rect2(1960,1120,1000,560),
		Rect2(3320,140,460,520), Rect2(3320,2140,460,520),
	]


static func _landmarks(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2, relay_cache: Vector2, boss_position: Vector2) -> Dictionary:
	return {
		"start":Vector2(520,1400), "open_entry":Vector2(1040,1400),
		"installation_entry":Vector2(1900,1400), "upper_route":Vector2(1900,740),
		"lower_route":Vector2(1900,2060), "generator_a":generator_a, "generator_b":generator_b,
		"field_boss":field_boss, "calibration_cache":Vector2(1660,1400), "chest":relay_cache,
		"boss_gate":Vector2(3950,1400), "boss":boss_position,
	}


static func _objective_triggers() -> Dictionary:
	return {
		"approach":Rect2(900,780,980,1240), "installations":Rect2(1760,120,1600,2260),
		"calibration":Rect2(1500,1240,320,320), "boss_start":Rect2(3980,620,900,1560),
		"field_boss_discovery":Rect2(2360,100,840,500), "relay_discovery":Rect2(3020,760,860,1280),
		"boss_discovery":Rect2(3740,520,1140,1760),
		"upper_route_event":Rect2(1780,420,1500,640), "lower_route_event":Rect2(1780,1740,1500,640),
	}


static func _static_enemies(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2) -> Array[Dictionary]:
	return [
		{"id":"archive_interceptor_a", "role":"interceptor_tower", "pos":Vector2(2540,740), "zone":"installations"},
		{"id":"archive_interceptor_b", "role":"interceptor_tower", "pos":Vector2(2540,2060), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"current_curator", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true, "name_key":"ENEMY_CURRENT_CURATOR"},
	]


static func _packets() -> Array[Dictionary]:
	return [
		_packet("archive_arrival",0,{"kind":&"time","at":5.1},Vector2(1040,1400),[[&"scrap_drone"]],0.90,8.0,"arrival"),
		_packet("archive_intake",1,{"kind":&"event","id":&"approach_entered"},Vector2(1300,1400),_squads(8,3,[&"scrap_drone",&"needle_drone"]),0.80,8.0,"approach"),
		_packet("archive_calibration",2,{"kind":&"event","id":&"calibration_claimed"},Vector2(1840,1400),_squads(8,4,[&"needle_drone",&"artillery_spotter",&"scrap_drone",&"spark_minelet"]),0.65,6.0,"approach"),
		_packet("archive_upper",3,{"kind":&"event","id":&"upper_route_entered"},Vector2(1900,740),_squads(4,5,[&"spark_minelet",&"needle_drone",&"scrap_drone"]),0.50,4.5,"installations"),
		_packet("archive_lower",3,{"kind":&"event","id":&"lower_route_entered"},Vector2(1900,2060),_squads(4,5,[&"scrap_drone",&"needle_drone",&"spark_minelet"]),0.50,4.5,"installations"),
		_packet("archive_relay",4,{"kind":&"event","id":&"generators_complete"},Vector2(3500,1400),_squads(6,5,[&"needle_drone",&"scrap_drone",&"spark_minelet"]),0.50,4.5,"relay"),
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
		{"id":"attack_upper", "kind":"attack_boost", "pos":Vector2(2300,520)},
		{"id":"coolant_upper", "kind":"coolant", "pos":Vector2(2580,370)},
		{"id":"overdrive_lower", "kind":"overdrive", "pos":Vector2(2280,1810)},
		{"id":"barrier_lower", "kind":"barrier", "pos":Vector2(3260,1840)},
		{"id":"seeker_relay", "kind":"seeker_battery", "pos":Vector2(3740,920)},
		{"id":"capacitor_relay", "kind":"capacitor_cell", "pos":Vector2(3740,1260)},
		{"id":"magnet_boss_lane", "kind":"magnet_field", "pos":Vector2(4030,1570)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_attack", "pos":Vector2(1080,1510), "drop":"attack_boost"},
		{"id":"crate_repair", "pos":Vector2(1810,1080), "drop":"repair"},
		{"id":"crate_barrier", "pos":Vector2(3360,1120), "drop":"barrier"},
		{"id":"crate_coolant", "pos":Vector2(1740,1100), "drop":"coolant"},
		{"id":"crate_seeker", "pos":Vector2(4040,680), "drop":"seeker_battery"},
	]
