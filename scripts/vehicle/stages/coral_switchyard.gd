class_name CoralSwitchyardStage
extends RefCounted

## Stage 4 definition. Three drive-over pads toggle one large paired gate state;
## both states preserve a full-width critical flank and a return route.


static func definition() -> Dictionary:
	var generator_a := Vector2(2920.0, 820.0)
	var generator_b := Vector2(2920.0, 2180.0)
	var field_boss := Vector2(3420.0, 360.0)
	var relay_cache := Vector2(3720.0, 1500.0)
	var boss_position := Vector2(4680.0, 1500.0)
	return {
		"id":&"coral_switchyard", "title_key":"STAGE_CORAL_SWITCHYARD", "number":4,
		"field_boss_name_key":"ENEMY_SALVAGE_CONVOY", "boss_name_key":"ENEMY_SWITCHYARD_BEHEMOTH",
		"environment":&"switchyard", "world_rect":Rect2(0,0,5200,3000), "player_start":Vector2(600,1500),
		"start_clearance":360.0, "boss_arena":Rect2(4220,500,850,2000), "boss_gate":Rect2(4160,1120,60,760),
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
		{"id":"maintenance_court", "name":"Maintenance Court", "rect":Rect2(160,1040,1040,920), "tone":&"light"},
		{"id":"switch_gallery", "name":"Switch Gallery", "rect":Rect2(820,600,1200,1800), "tone":&"mid"},
		{"id":"upper_flank", "name":"Upper Gate Flank", "rect":Rect2(1700,400,1760,850), "tone":&"dark"},
		{"id":"lower_flank", "name":"Lower Gate Flank", "rect":Rect2(1700,1750,1760,850), "tone":&"dark"},
		{"id":"service_spine", "name":"Service Spine", "rect":Rect2(1700,1120,1980,760), "tone":&"light"},
		{"id":"convoy_dock", "name":"Convoy Side Dock", "rect":Rect2(3040,140,920,620), "tone":&"light"},
		{"id":"relay_court", "name":"Relay Court", "rect":Rect2(3360,760,820,1480), "tone":&"mid"},
		{"id":"behemoth_link", "name":"Behemoth Link", "rect":Rect2(4040,1080,260,840), "tone":&"light"},
		{"id":"behemoth_cradle", "name":"Behemoth Cradle", "rect":Rect2(4220,500,850,2000), "tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(1440,1160,220,220), Rect2(1440,1620,220,220),
		Rect2(2050,1020,260,170), Rect2(2050,1810,260,170),
		Rect2(3440,920,180,250),
		Rect2(4820,720,170,240), Rect2(4820,2040,170,240),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(40,160,1380,620), Rect2(40,2220,1380,620),
		Rect2(2060,1300,620,400), Rect2(3000,1260,280,480),
		Rect2(3580,2280,420,560),
	]


static func _landmarks(generator_a:Vector2, generator_b:Vector2, field_boss:Vector2, relay_cache:Vector2, boss_position:Vector2) -> Dictionary:
	return {
		"start":Vector2(600,1500), "open_entry":Vector2(1120,1500), "installation_entry":Vector2(1840,1500),
		"upper_route":Vector2(2200,820), "lower_route":Vector2(2200,2180), "generator_a":generator_a,
		"generator_b":generator_b, "field_boss":field_boss, "calibration_cache":Vector2(1660,1500),
		"chest":relay_cache, "boss_gate":Vector2(4190,1500), "boss":boss_position,
	}


static func _objective_triggers() -> Dictionary:
	return {
		"approach":Rect2(900,600,1000,1800), "installations":Rect2(1760,340,1780,2320),
		"calibration":Rect2(1500,1340,320,320), "boss_start":Rect2(4220,500,850,2000),
		"field_boss_discovery":Rect2(3000,120,1000,680), "relay_discovery":Rect2(3320,720,900,1560),
		"boss_discovery":Rect2(4020,440,1050,2120),
		"upper_route_event":Rect2(1800,400,1660,850), "lower_route_event":Rect2(1800,1750,1660,850),
	}


static func _static_enemies(generator_a:Vector2, generator_b:Vector2, field_boss:Vector2) -> Array[Dictionary]:
	var convoy_leash := Rect2(3000,120,1000,680)
	return [
		{"id":"switch_tender_upper", "role":"repair_tender", "pos":Vector2(2720,820), "zone":"installations"},
		{"id":"switch_tender_lower", "role":"repair_tender", "pos":Vector2(2720,2180), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":generator_a, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":generator_b, "zone":"installations", "required":true},
		{"id":"salvage_convoy", "role":"field_boss", "pos":field_boss, "zone":"field_boss", "optional":true, "name_key":"ENEMY_SALVAGE_CONVOY", "leash_rect":convoy_leash},
		{"id":"convoy_ram_upper", "role":"rammer", "pos":field_boss+Vector2(-170,120), "zone":"field_boss", "optional":true, "leash_rect":convoy_leash, "squad_id":"salvage_convoy"},
		{"id":"convoy_ram_lower", "role":"rammer", "pos":field_boss+Vector2(170,120), "zone":"field_boss", "optional":true, "leash_rect":convoy_leash, "squad_id":"salvage_convoy"},
	]


static func _environment_zones() -> Array[Dictionary]:
	return [
		{"kind":&"switch_pad", "id":&"west_upper_pad", "center":Vector2(1280,820), "radius":108.0},
		{"kind":&"switch_pad", "id":&"west_lower_pad", "center":Vector2(1280,2180), "radius":108.0},
		{"kind":&"switch_pad", "id":&"relay_pad", "center":Vector2(3720,1500), "radius":108.0},
		{"kind":&"switch_gate", "id":&"route_gate_a", "positions":[Rect2(2460,400,180,850),Rect2(2460,1750,180,850)]},
		{"kind":&"switch_gate", "id":&"route_gate_b", "positions":[Rect2(3180,400,180,850),Rect2(3180,1750,180,850)]},
		{"kind":&"convoy_route", "id":&"bonus_convoy", "start":Vector2(3420,360), "end":Vector2(3860,360), "duration":26.0},
	]


static func _packets() -> Array[Dictionary]:
	return [
		_packet("switchyard_arrival",0,{"kind":&"time","at":5.1},Vector2(1120,1500),[[&"scrap_drone"]],0.90,8.0,"arrival"),
		_packet("switchyard_gallery",1,{"kind":&"event","id":&"approach_entered"},Vector2(1440,1500),_squads_with_specialist(10,3,[&"scrap_drone",&"needle_drone"],&"rammer",3),0.80,8.0,"approach"),
		_packet("switchyard_calibration",2,{"kind":&"event","id":&"calibration_claimed"},Vector2(1860,1500),_squads_with_specialist(10,4,[&"needle_drone",&"shooter",&"scrap_drone"],&"repair_tender",4),0.65,6.0,"approach"),
		_packet("switchyard_upper",3,{"kind":&"event","id":&"upper_route_entered"},Vector2(2200,820),_squads_with_specialist(5,5,[&"rammer",&"needle_drone",&"scrap_drone"],&"repair_tender",3),0.50,4.5,"installations"),
		_packet("switchyard_lower",3,{"kind":&"event","id":&"lower_route_entered"},Vector2(2200,2180),_squads_with_specialist(5,5,[&"scrap_drone",&"rammer",&"needle_drone"],&"repair_tender",3),0.50,4.5,"installations"),
		_packet("switchyard_relay",4,{"kind":&"event","id":&"generators_complete"},Vector2(3700,1500),_squads_with_specialist(6,5,[&"rammer",&"scrap_drone",&"shooter",&"needle_drone"],&"repair_tender",2),0.50,4.5,"relay"),
	]


static func _packet(id:String, beat:int, trigger:Dictionary, anchor:Vector2, squads:Array, spacing:float, gap:float, zone:String) -> Dictionary:
	return {"id":id,"beat":beat,"trigger":trigger,"anchor":anchor,"squads":squads,"unit_spacing":spacing,"squad_gap":gap,"cue_lead":0.9,"zone":zone,"leash":Rect2(anchor-Vector2(620,460),Vector2(1240,920))}


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
		{"id":"repair_entry","kind":"repair","heal_amount":35.0,"pos":Vector2(1480,990)},
		{"id":"experience_recall","kind":"experience_recall","pos":Vector2(3140,600)},
		{"id":"repair_boss_lane","kind":"repair","heal_amount":70.0,"pos":Vector2(4380,1500)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_repair_entry","pos":Vector2(1120,1640),"drop":"repair"}, {"id":"crate_repair","pos":Vector2(1760,1040),"drop":"repair"},
		{"id":"crate_repair_relay","pos":Vector2(3500,1320),"drop":"repair"}, {"id":"crate_repair_lower","pos":Vector2(1760,1960),"drop":"repair"},
		{"id":"crate_recall","pos":Vector2(4380,660),"drop":"experience_recall"},
	]
