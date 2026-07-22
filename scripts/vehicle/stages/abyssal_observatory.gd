class_name AbyssalObservatoryStage
extends RefCounted

## Stage 5 definition. Two drive-over consoles rotate two large reflectors; the
## same authored plates serve the optional vault and Crown Engine relay puzzle.


static func definition() -> Dictionary:
	var generator_a := Vector2(2920.0, 760.0)
	var generator_b := Vector2(2920.0, 2240.0)
	var field_boss := Vector2(3420.0, 340.0)
	var relay_cache := Vector2(3260.0, 1500.0)
	var boss_position := Vector2(4880.0, 1500.0)
	return {
		"id":&"abyssal_observatory", "title_key":"STAGE_ABYSSAL_OBSERVATORY", "number":5,
		"field_boss_name_key":"ENEMY_MIRROR_WARDEN", "boss_name_key":"ENEMY_CROWN_ENGINE",
		"environment":&"observatory", "world_rect":Rect2(0,0,5400,3000), "player_start":Vector2(600,1500),
		"start_clearance":360.0, "boss_arena":Rect2(3400,400,1840,2200), "boss_gate":Rect2(3340,400,60,2200),
		"walkable_regions":_walkable_regions(), "cover_rects":_cover_rects(), "water_rects":_water_rects(),
		"hazard_regions":[], "landmarks":_landmarks(generator_a,generator_b,field_boss,relay_cache,boss_position),
		"objective_triggers":_objective_triggers(), "static_enemies":_static_enemies(generator_a,generator_b,field_boss),
		"pickups":_pickups(), "crates":_crates(),
		"reward_anchors":{&"calibration_cache":Vector2(1660,1500), &"field_boss_cache":field_boss, &"relay_cache":relay_cache, &"boss_reward":boss_position},
		"environment_zones":_environment_zones(),
		"packets":_packets(),
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"observation_court","name":"Observation Court","rect":Rect2(160,1000,900,1000),"tone":&"light"},
		{"id":"diagram_gallery","name":"Reflector Diagram Gallery","rect":Rect2(840,600,1260,1800),"tone":&"mid"},
		{"id":"upper_optic_lane","name":"Upper Optic Lane","rect":Rect2(1880,400,1580,900),"tone":&"dark"},
		{"id":"lower_optic_lane","name":"Lower Optic Lane","rect":Rect2(1880,1700,1580,900),"tone":&"dark"},
		{"id":"optic_spine","name":"Optic Spine","rect":Rect2(1820,1160,1680,680),"tone":&"light"},
		{"id":"mirror_vault","name":"Mirror Warden Vault","rect":Rect2(3000,120,1000,620),"tone":&"light"},
		{"id":"crown_link","name":"Crown Link","rect":Rect2(3260,1040,260,920),"tone":&"mid"},
		{"id":"crown_chamber","name":"Crown Chamber","rect":Rect2(3400,400,1840,2200),"tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(1080,740,260,210), Rect2(1080,2050,260,210),
		Rect2(1440,1120,220,230), Rect2(1440,1650,220,230),
		Rect2(2160,940,260,170), Rect2(2160,1890,260,170),
		Rect2(2740,1120,260,150), Rect2(2740,1730,260,150),
		Rect2(3540,760,180,240), Rect2(3540,2000,180,240),
		Rect2(4460,760,170,220), Rect2(4460,2020,170,220),
		Rect2(5080,760,120,220), Rect2(5080,2020,120,220),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(40,140,1380,620), Rect2(40,2240,1380,620),
		Rect2(2080,1300,620,400), Rect2(3000,820,260,300), Rect2(3000,1880,260,300),
	]


static func _landmarks(generator_a:Vector2, generator_b:Vector2, field_boss:Vector2, relay_cache:Vector2, boss_position:Vector2) -> Dictionary:
	return {
		"start":Vector2(600,1500), "open_entry":Vector2(1120,1500), "installation_entry":Vector2(1880,1500),
		"upper_route":Vector2(2240,760), "lower_route":Vector2(2240,2240), "generator_a":generator_a,
		"generator_b":generator_b, "field_boss":field_boss, "calibration_cache":Vector2(1660,1500),
		"chest":relay_cache, "boss_gate":Vector2(3370,1500), "boss":boss_position,
	}


static func _objective_triggers() -> Dictionary:
	return {
		"approach":Rect2(900,600,1000,1800), "installations":Rect2(1840,340,1700,2320),
		"calibration":Rect2(1500,1340,320,320), "boss_start":Rect2(3400,400,1840,2200),
		"field_boss_discovery":Rect2(2960,100,1080,680), "relay_discovery":Rect2(3040,980,500,1040),
		"boss_discovery":Rect2(3260,340,1980,2320),
		"upper_route_event":Rect2(1880,400,1580,900), "lower_route_event":Rect2(1880,1700,1580,900),
	}


static func _static_enemies(generator_a:Vector2, generator_b:Vector2, field_boss:Vector2) -> Array[Dictionary]:
	var vault_leash := Rect2(2960,100,1080,680)
	return [
		{"id":"observatory_beam_upper","role":"beam_sentinel","pos":Vector2(2600,760),"zone":"installations"},
		{"id":"observatory_beam_lower","role":"beam_sentinel","pos":Vector2(2600,2240),"zone":"installations"},
		{"id":"generator_a","role":"generator","pos":generator_a,"zone":"installations","required":true},
		{"id":"generator_b","role":"generator","pos":generator_b,"zone":"installations","required":true},
		{"id":"mirror_warden","role":"field_boss","pos":field_boss,"zone":"field_boss","optional":true,"name_key":"ENEMY_MIRROR_WARDEN","leash_rect":vault_leash},
		{"id":"mirror_guard_beam","role":"beam_sentinel","pos":field_boss+Vector2(300,80),"zone":"field_boss","optional":true,"leash_rect":vault_leash},
		{"id":"vault_carrier","role":"drone_carrier","pos":field_boss+Vector2(-280,100),"zone":"field_boss","optional":true,"leash_rect":vault_leash},
	]


static func _environment_zones() -> Array[Dictionary]:
	return [
		{"kind":&"reflector_console","id":&"upper_console","reflector_id":&"upper_reflector","center":Vector2(3140,1260),"radius":96.0},
		{"kind":&"reflector_console","id":&"lower_console","reflector_id":&"lower_reflector","center":Vector2(3140,1740),"radius":96.0},
		{"kind":&"reflector","id":&"upper_reflector","rect":Rect2(4030,1170,140,140),"center":Vector2(4100,1240),"initial_orientation":0,"vault_orientation":3,"relay_position":Vector2(4030,700)},
		{"kind":&"reflector","id":&"lower_reflector","rect":Rect2(4030,1690,140,140),"center":Vector2(4100,1760),"initial_orientation":2,"vault_orientation":1,"relay_position":Vector2(4030,2300)},
		{"kind":&"vault_gate","id":&"mirror_vault_gate","rect":Rect2(3300,120,180,620)},
	]


static func _packets() -> Array[Dictionary]:
	return [
		_packet("observatory_arrival",0,{"kind":&"time","at":5.1},Vector2(1120,1500),[[&"scrap_drone"]],0.90,8.0,"arrival"),
		_packet("observatory_gallery",1,{"kind":&"event","id":&"approach_entered"},Vector2(1440,1500),_squads_with_specialist(10,3,[&"scrap_drone",&"needle_drone"],&"drone_carrier",4),0.80,8.0,"approach"),
		_packet("observatory_calibration",2,{"kind":&"event","id":&"calibration_claimed"},Vector2(1880,1500),_squads_with_specialist(10,4,[&"needle_drone",&"shooter",&"scrap_drone"],&"drone_carrier",4),0.65,6.0,"approach"),
		_packet("observatory_upper",3,{"kind":&"event","id":&"upper_route_entered"},Vector2(2240,760),_squads_with_specialist(6,5,[&"needle_drone",&"scrap_drone",&"shooter"],&"drone_carrier",3),0.50,4.5,"installations"),
		_packet("observatory_lower",3,{"kind":&"event","id":&"lower_route_entered"},Vector2(2240,2240),_squads_with_specialist(6,5,[&"scrap_drone",&"needle_drone",&"spark_minelet"],&"drone_carrier",3),0.50,4.5,"installations"),
		_packet("observatory_crown",4,{"kind":&"event","id":&"generators_complete"},Vector2(3260,1500),_squads_with_specialist(8,5,[&"drone_carrier",&"needle_drone",&"shooter",&"scrap_drone"],&"beam_sentinel",3),0.50,4.5,"relay"),
	]


static func _packet(id:String, beat:int, trigger:Dictionary, anchor:Vector2, squads:Array, spacing:float, gap:float, zone:String) -> Dictionary:
	return {"id":id,"beat":beat,"trigger":trigger,"anchor":anchor,"squads":squads,"unit_spacing":spacing,"squad_gap":gap,"cue_lead":0.9,"zone":zone,"leash":Rect2(anchor-Vector2(640,460),Vector2(1280,920))}


static func _squads(count:int, size:int, roles:Array[StringName]) -> Array:
	var result := []
	for squad_index in count:
		var squad:Array[StringName] = []
		for unit_index in size:
			squad.append(roles[(squad_index+unit_index)%roles.size()])
		result.append(squad)
	return result


static func _squads_with_specialist(count:int, size:int, roles:Array[StringName], specialist:StringName, every:int) -> Array:
	var result := _squads(count,size,roles)
	for squad_index in count:
		if squad_index%every==0:
			result[squad_index][0]=specialist
	return result


static func _pickups() -> Array[Dictionary]:
	return [
		{"id":"repair_entry","kind":"repair","pos":Vector2(1460,1000)}, {"id":"attack_upper","kind":"attack_boost","pos":Vector2(2220,520)},
		{"id":"coolant_upper","kind":"coolant","pos":Vector2(3040,620)}, {"id":"overdrive_lower","kind":"overdrive","pos":Vector2(2220,2460)},
		{"id":"barrier_lower","kind":"barrier","pos":Vector2(3040,2380)}, {"id":"seeker_crown","kind":"seeker_battery","pos":Vector2(3820,900)},
		{"id":"capacitor_crown","kind":"capacitor_cell","pos":Vector2(3820,2100)}, {"id":"magnet_boss","kind":"magnet_field","pos":Vector2(4480,1500)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_attack","pos":Vector2(1120,1660),"drop":"attack_boost"}, {"id":"crate_repair","pos":Vector2(1760,1040),"drop":"repair"},
		{"id":"crate_barrier","pos":Vector2(3180,1400),"drop":"barrier"}, {"id":"crate_coolant","pos":Vector2(1760,1960),"drop":"coolant"},
		{"id":"crate_seeker","pos":Vector2(4580,620),"drop":"seeker_battery"},
	]
