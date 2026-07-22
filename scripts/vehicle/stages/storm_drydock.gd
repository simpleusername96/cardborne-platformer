class_name StormDrydockStage
extends RefCounted

## Stage 3 definition. Large grounded courts remain readable while electrical
## sweep zones are stored beside the geometry they affect.


static func definition() -> Dictionary:
	var generator_a := Vector2(2780.0, 760.0)
	var generator_b := Vector2(2780.0, 2040.0)
	var field_boss := Vector2(2860.0, 500.0)
	var relay_cache := Vector2(3460.0, 1400.0)
	var boss_position := Vector2(4420.0, 1400.0)
	return {
		"id":&"storm_drydock", "title_key":"STAGE_STORM_DRYDOCK", "number":3,
		"field_boss_name_key":"ENEMY_STORM_FOREMAN", "boss_name_key":"ENEMY_DRYDOCK_TITAN",
		"environment":&"storm", "world_rect":Rect2(0,0,5000,2800), "player_start":Vector2(560,1400),
		"start_clearance":360.0, "boss_arena":Rect2(3860,520,1020,1760), "boss_gate":Rect2(3800,1080,60,640),
		"walkable_regions":_walkable_regions(), "cover_rects":_cover_rects(), "water_rects":_water_rects(),
		"hazard_regions":[], "landmarks":_landmarks(generator_a,generator_b,field_boss,relay_cache,boss_position),
		"objective_triggers":_objective_triggers(), "static_enemies":_static_enemies(generator_a,generator_b,field_boss),
		"pickups":_pickups(), "crates":_crates(),
		"reward_anchors":{&"calibration_cache":Vector2(1640,1400), &"field_boss_cache":field_boss, &"relay_cache":relay_cache, &"boss_reward":boss_position},
		"environment_zones":[
			{"id":&"upper_sweep", "rect":Rect2(1800,620,1200,280), "phase":0.0, "safe_rect":Rect2(1880,1280,1040,240)},
			{"id":&"lower_sweep", "rect":Rect2(1800,1900,1200,280), "phase":2.6, "safe_rect":Rect2(1880,1280,1040,240)},
		],
		"packets":_packets(),
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"service", "name":"Grounded Service Plaza", "rect":Rect2(160,1000,800,800), "tone":&"light"},
		{"id":"approach", "name":"Drydock Approach", "rect":Rect2(800,700,1000,1400), "tone":&"mid"},
		{"id":"upper_island", "name":"Upper Grounding Island", "rect":Rect2(1640,400,1500,800), "tone":&"dark"},
		{"id":"lower_island", "name":"Lower Grounding Island", "rect":Rect2(1640,1600,1500,800), "tone":&"dark"},
		{"id":"safe_spine", "name":"Grounded Safe Spine", "rect":Rect2(1540,1050,1800,700), "tone":&"light"},
		{"id":"launch_court", "name":"Launch Court", "rect":Rect2(3060,780,820,1240), "tone":&"mid"},
		{"id":"cradle_link", "name":"Titan Cradle Link", "rect":Rect2(3720,1040,220,720), "tone":&"light"},
		{"id":"cradle", "name":"Titan Cradle", "rect":Rect2(3860,520,1020,1760), "tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(1040,820,300,160), Rect2(1040,1820,300,160),
		Rect2(1400,1120,180,230), Rect2(1400,1450,180,230),
		Rect2(2020,930,260,170), Rect2(2020,1700,260,170),
		Rect2(2500,430,180,220), Rect2(2500,2150,180,220),
		Rect2(2980,900,180,230), Rect2(2980,1670,180,230),
		Rect2(3400,900,170,240), Rect2(3400,1660,170,240),
		Rect2(4080,720,170,230), Rect2(4080,1850,170,230),
		Rect2(4580,720,170,230), Rect2(4580,1850,170,230),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(40,120,1320,620), Rect2(40,2060,1320,620),
		Rect2(1740,1220,500,360), Rect2(2740,1220,420,360),
		Rect2(3300,140,420,500), Rect2(3300,2160,420,500),
	]


static func _landmarks(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2, relay_cache: Vector2, boss_position: Vector2) -> Dictionary:
	return {
		"start":Vector2(560,1400), "open_entry":Vector2(1080,1400), "installation_entry":Vector2(1640,1400),
		"upper_route":Vector2(2180,760), "lower_route":Vector2(2180,2040), "generator_a":generator_a,
		"generator_b":generator_b, "field_boss":field_boss, "calibration_cache":Vector2(1640,1400),
		"chest":relay_cache, "boss_gate":Vector2(3830,1400), "boss":boss_position,
	}


static func _objective_triggers() -> Dictionary:
	return {
		"approach":Rect2(900,700,900,1400), "installations":Rect2(1600,360,1660,2080),
		"calibration":Rect2(1500,1240,320,320), "boss_start":Rect2(3860,520,1020,1760),
		"field_boss_discovery":Rect2(2380,320,720,500), "relay_discovery":Rect2(3040,740,860,1320),
		"boss_discovery":Rect2(3700,460,1180,1880),
		"upper_route_event":Rect2(1640,400,1500,800), "lower_route_event":Rect2(1640,1600,1500,800),
	}


static func _static_enemies(generator_a: Vector2, generator_b: Vector2, field_boss: Vector2) -> Array[Dictionary]:
	return [
		{"id":"drydock_interceptor", "role":"interceptor_tower", "pos":Vector2(2380,760), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"storm_foreman", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true, "name_key":"ENEMY_STORM_FOREMAN"},
	]


static func _packets() -> Array[Dictionary]:
	return [
		_packet("drydock_arrival",0,{"kind":&"time","at":5.1},Vector2(1080,1400),[[&"scrap_drone"]],0.90,8.0,"arrival"),
		_packet("drydock_service",1,{"kind":&"event","id":&"approach_entered"},Vector2(1320,1400),_squads(9,3,[&"scrap_drone",&"needle_drone"]),0.80,8.0,"approach"),
		_packet("drydock_calibration",2,{"kind":&"event","id":&"calibration_claimed"},Vector2(1640,1400),_squads(9,4,[&"needle_drone",&"shield_escort",&"shooter",&"scrap_drone"]),0.65,6.0,"approach"),
		_packet("drydock_upper",3,{"kind":&"event","id":&"upper_route_entered"},Vector2(2180,760),_squads(5,5,[&"spark_minelet",&"needle_drone",&"scrap_drone"]),0.50,4.5,"installations"),
		_packet("drydock_lower",3,{"kind":&"event","id":&"lower_route_entered"},Vector2(2180,2040),_squads(5,5,[&"scrap_drone",&"needle_drone",&"spark_minelet"]),0.50,4.5,"installations"),
		_packet("drydock_relay",4,{"kind":&"event","id":&"generators_complete"},Vector2(3460,1400),_squads(6,5,[&"needle_drone",&"scrap_drone",&"spark_minelet"]),0.50,4.5,"relay"),
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
		{"id":"attack_upper", "kind":"attack_boost", "pos":Vector2(2300,500)},
		{"id":"coolant_upper", "kind":"coolant", "pos":Vector2(2600,720)},
		{"id":"overdrive_lower", "kind":"overdrive", "pos":Vector2(2380,1800)},
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
		{"id":"crate_coolant", "pos":Vector2(1620,1120), "drop":"coolant"},
		{"id":"crate_seeker", "pos":Vector2(3980,680), "drop":"seeker_battery"},
	]
