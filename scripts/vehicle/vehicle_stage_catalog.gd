class_name VehicleStageCatalog
extends RefCounted

## Authored data for the continuous vehicle run. Simulation code consumes these
## profiles instead of cloning scenes or stage scripts.

const STAGE_IDS: Array[StringName] = [&"flooded_works", &"tidal_archive", &"storm_drydock"]
const WORLD_RECT := Rect2(0.0, 0.0, 5200.0, 2200.0)
const PLAYER_START := Vector2(330.0, 1100.0)
const BOSS_ARENA := Rect2(3970.0, 420.0, 1100.0, 1360.0)
const BOSS_GATE := Rect2(3890.0, 820.0, 70.0, 560.0)
const CHEST_POSITION := Vector2(3470.0, 1120.0)
const FIELD_BOSS_POSITION := Vector2(2860.0, 330.0)
const STAGE_BOSS_POSITION := Vector2(4580.0, 1090.0)
const GENERATOR_A_POSITION := Vector2(2300.0, 570.0)
const GENERATOR_B_POSITION := Vector2(2880.0, 1650.0)


static func normalized_id(stage_id: StringName) -> StringName:
	return stage_id if stage_id in STAGE_IDS else STAGE_IDS[0]


static func index_of(stage_id: StringName) -> int:
	return maxi(0, STAGE_IDS.find(normalized_id(stage_id)))


static func profile(stage_id: StringName) -> Dictionary:
	match normalized_id(stage_id):
		&"tidal_archive":
			return {
				"title_key": "STAGE_TIDAL_ARCHIVE",
				"number": 2,
				"field_boss_name_key": "ENEMY_CURRENT_CURATOR",
				"boss_name_key": "ENEMY_ARCHIVE_LEVIATHAN",
				"environment": &"current",
			}
		&"storm_drydock":
			return {
				"title_key": "STAGE_STORM_DRYDOCK",
				"number": 3,
				"field_boss_name_key": "ENEMY_STORM_FOREMAN",
				"boss_name_key": "ENEMY_DRYDOCK_TITAN",
				"environment": &"storm",
			}
	return {
		"title_key": "STAGE_FLOODED_WORKS",
		"number": 1,
		"field_boss_name_key": "ENEMY_DREDGE_WARDEN",
		"boss_name_key": "ENEMY_FOUNDRY_COLOSSUS",
		"environment": &"none",
	}


static func cover_rects(stage_id: StringName) -> Array[Rect2]:
	var rects := _boundaries()
	match normalized_id(stage_id):
		&"tidal_archive":
			rects.append_array([
				Rect2(620.0, 70.0, 70.0, 450.0), Rect2(620.0, 1680.0, 70.0, 450.0),
				Rect2(900.0, 350.0, 260.0, 240.0), Rect2(930.0, 1600.0, 280.0, 230.0),
				Rect2(1320.0, 760.0, 320.0, 190.0), Rect2(1320.0, 1260.0, 320.0, 180.0),
				Rect2(1900.0, 70.0, 160.0, 600.0), Rect2(1900.0, 1530.0, 160.0, 600.0),
				Rect2(2100.0, 820.0, 640.0, 180.0), Rect2(2300.0, 1200.0, 640.0, 180.0),
				Rect2(2800.0, 650.0, 260.0, 200.0), Rect2(3100.0, 1450.0, 280.0, 220.0),
				Rect2(3260.0, 650.0, 190.0, 260.0), Rect2(3440.0, 1360.0, 170.0, 250.0),
			])
		&"storm_drydock":
			rects.append_array([
				Rect2(620.0, 70.0, 70.0, 700.0), Rect2(620.0, 1430.0, 70.0, 700.0),
				Rect2(880.0, 820.0, 420.0, 170.0), Rect2(1120.0, 1260.0, 420.0, 180.0),
				Rect2(1580.0, 430.0, 180.0, 430.0), Rect2(1580.0, 1370.0, 180.0, 430.0),
				Rect2(1900.0, 70.0, 160.0, 560.0), Rect2(1900.0, 1580.0, 160.0, 550.0),
				Rect2(2200.0, 820.0, 300.0, 430.0), Rect2(2660.0, 760.0, 240.0, 380.0),
				Rect2(3060.0, 330.0, 260.0, 250.0), Rect2(3020.0, 1500.0, 300.0, 220.0),
				Rect2(3380.0, 700.0, 220.0, 220.0), Rect2(3400.0, 1360.0, 200.0, 230.0),
			])
		_:
			rects.append_array([
				Rect2(620.0, 70.0, 70.0, 650.0), Rect2(620.0, 1480.0, 70.0, 650.0),
				Rect2(980.0, 540.0, 190.0, 330.0), Rect2(1260.0, 1230.0, 300.0, 180.0),
				Rect2(1600.0, 670.0, 180.0, 340.0), Rect2(1700.0, 1510.0, 250.0, 160.0),
				Rect2(2030.0, 760.0, 930.0, 680.0), Rect2(2160.0, 180.0, 260.0, 210.0),
				Rect2(2600.0, 430.0, 250.0, 170.0), Rect2(2140.0, 1760.0, 300.0, 190.0),
				Rect2(3040.0, 1510.0, 240.0, 220.0), Rect2(3200.0, 530.0, 210.0, 310.0),
				Rect2(3390.0, 680.0, 210.0, 210.0), Rect2(3390.0, 1390.0, 210.0, 210.0),
				Rect2(3660.0, 260.0, 160.0, 440.0), Rect2(3660.0, 1500.0, 160.0, 440.0),
			])
	# Boss circulation is common so the shared boss pattern keeps valid lanes.
	rects.append_array([
		Rect2(4200.0, 610.0, 170.0, 230.0), Rect2(4200.0, 1360.0, 170.0, 230.0),
		Rect2(4740.0, 610.0, 170.0, 230.0), Rect2(4740.0, 1360.0, 170.0, 230.0),
	])
	return rects


static func water_rects(stage_id: StringName) -> Array[Rect2]:
	match normalized_id(stage_id):
		&"tidal_archive":
			return [
				Rect2(690.0, 70.0, 200.0, 520.0), Rect2(690.0, 1610.0, 200.0, 520.0),
				Rect2(1160.0, 70.0, 210.0, 580.0), Rect2(1660.0, 1550.0, 240.0, 580.0),
				Rect2(2060.0, 70.0, 180.0, 650.0), Rect2(2060.0, 1480.0, 180.0, 650.0),
				Rect2(3000.0, 70.0, 220.0, 470.0), Rect2(3000.0, 1750.0, 220.0, 380.0),
			]
		&"storm_drydock":
			return [
				Rect2(690.0, 70.0, 190.0, 680.0), Rect2(690.0, 1450.0, 190.0, 680.0),
				Rect2(1380.0, 70.0, 200.0, 420.0), Rect2(1380.0, 1710.0, 200.0, 420.0),
				Rect2(2060.0, 70.0, 140.0, 620.0), Rect2(2060.0, 1510.0, 140.0, 620.0),
				Rect2(3320.0, 70.0, 180.0, 540.0), Rect2(3320.0, 1660.0, 180.0, 470.0),
			]
	return [
		Rect2(690.0, 70.0, 330.0, 430.0), Rect2(690.0, 1700.0, 330.0, 430.0),
		Rect2(1220.0, 70.0, 250.0, 360.0), Rect2(1500.0, 1750.0, 380.0, 380.0),
		Rect2(1900.0, 70.0, 180.0, 650.0), Rect2(1900.0, 1480.0, 180.0, 650.0),
		Rect2(2960.0, 70.0, 200.0, 420.0), Rect2(2960.0, 1780.0, 200.0, 350.0),
		Rect2(3820.0, 70.0, 120.0, 640.0), Rect2(3820.0, 1490.0, 120.0, 640.0),
	]


static func floor_regions(stage_id: StringName, colors: Dictionary) -> Array[Dictionary]:
	var names: Array[String]
	match normalized_id(stage_id):
		&"tidal_archive": names = ["Intake Shelf", "Current Gallery", "Archive Channels", "Index Court", "Leviathan Vault"]
		&"storm_drydock": names = ["Service Pier", "Drydock Rails", "Storm Gantries", "Launch Court", "Titan Cradle"]
		_: names = ["Deployment Dock", "Foundry Approach", "Drowned Installations", "Relay Court", "Colossus Basin"]
	return [
		{"name": names[0], "rect": Rect2(70.0, 720.0, 550.0, 760.0), "color": colors["light"]},
		{"name": names[1], "rect": Rect2(620.0, 300.0, 1360.0, 1600.0), "color": colors["mid"]},
		{"name": names[2], "rect": Rect2(1980.0, 120.0, 1460.0, 1960.0), "color": colors["dark"]},
		{"name": names[3], "rect": Rect2(3300.0, 610.0, 650.0, 980.0), "color": colors["mid"]},
		{"name": names[4], "rect": BOSS_ARENA, "color": colors["dark"]},
	]


static func enemy_blueprint(stage_id: StringName) -> Array[Dictionary]:
	match normalized_id(stage_id):
		&"tidal_archive":
			return [
				{"id":"archive_chaser_a", "role":"chaser", "pos":Vector2(880,1120), "zone":"approach"},
				{"id":"archive_spotter_a", "role":"artillery_spotter", "pos":Vector2(1230,610), "zone":"approach"},
				{"id":"archive_chaser_b", "role":"chaser", "pos":Vector2(1460,1600), "zone":"approach"},
				{"id":"archive_shooter", "role":"shooter", "pos":Vector2(1740,1120), "zone":"approach"},
				{"id":"archive_interceptor_a", "role":"interceptor_tower", "pos":Vector2(2350,410), "zone":"installations"},
				{"id":"archive_interceptor_b", "role":"interceptor_tower", "pos":Vector2(2830,1810), "zone":"installations"},
				{"id":"generator_a", "role":"generator", "pos":GENERATOR_A_POSITION, "zone":"installations", "required":true},
				{"id":"generator_b", "role":"generator", "pos":GENERATOR_B_POSITION, "zone":"installations", "required":true},
				{"id":"archive_spotter_b", "role":"artillery_spotter", "pos":Vector2(3160,1110), "zone":"installations"},
				{"id":"archive_controller", "role":"controller", "pos":Vector2(3320,1280), "zone":"installations"},
				{"id":"current_curator", "role":"field_boss", "pos":FIELD_BOSS_POSITION, "zone":"field_boss", "optional":true, "name_key":"ENEMY_CURRENT_CURATOR"},
			]
		&"storm_drydock":
			return [
				{"id":"drydock_chaser_a", "role":"chaser", "pos":Vector2(860,660), "zone":"approach"},
				{"id":"drydock_escort_a", "role":"shield_escort", "pos":Vector2(1090,1120), "zone":"approach"},
				{"id":"drydock_shooter_a", "role":"shooter", "pos":Vector2(1450,1080), "zone":"approach"},
				{"id":"drydock_chaser_b", "role":"chaser", "pos":Vector2(1730,1160), "zone":"approach"},
				{"id":"drydock_interceptor", "role":"interceptor_tower", "pos":Vector2(2340,680), "zone":"installations"},
				{"id":"generator_a", "role":"generator", "pos":GENERATOR_A_POSITION, "zone":"installations", "required":true},
				{"id":"generator_b", "role":"generator", "pos":GENERATOR_B_POSITION, "zone":"installations", "required":true},
				{"id":"drydock_escort_b", "role":"shield_escort", "pos":Vector2(3060,1180), "zone":"installations"},
				{"id":"drydock_spotter", "role":"artillery_spotter", "pos":Vector2(3290,1050), "zone":"installations"},
				{"id":"drydock_shooter_b", "role":"shooter", "pos":Vector2(3200,1800), "zone":"installations"},
				{"id":"storm_foreman", "role":"field_boss", "pos":FIELD_BOSS_POSITION, "zone":"field_boss", "optional":true, "name_key":"ENEMY_STORM_FOREMAN"},
			]
	return [
		{"id":"approach_chaser_a", "role":"chaser", "pos":Vector2(900,1110), "zone":"approach"},
		{"id":"approach_shooter_a", "role":"shooter", "pos":Vector2(1240,690), "zone":"approach"},
		{"id":"approach_chaser_b", "role":"chaser", "pos":Vector2(1420,1600), "zone":"approach"},
		{"id":"approach_controller", "role":"controller", "pos":Vector2(1730,1210), "zone":"approach"},
		{"id":"approach_shooter_b", "role":"shooter", "pos":Vector2(1840,520), "zone":"approach"},
		{"id":"upper_turret", "role":"turret", "pos":Vector2(2460,370), "zone":"installations"},
		{"id":"lower_turret", "role":"turret", "pos":Vector2(2670,1830), "zone":"installations"},
		{"id":"upper_arc_mine", "role":"mine", "pos":Vector2(3100,710), "zone":"installations"},
		{"id":"lower_arc_mine", "role":"mine", "pos":Vector2(2260,1610), "zone":"installations"},
		{"id":"generator_a", "role":"generator", "pos":GENERATOR_A_POSITION, "zone":"installations", "required":true},
		{"id":"generator_b", "role":"generator", "pos":GENERATOR_B_POSITION, "zone":"installations", "required":true},
		{"id":"install_chaser", "role":"chaser", "pos":Vector2(3160,1110), "zone":"installations"},
		{"id":"install_shooter", "role":"shooter", "pos":Vector2(3270,1290), "zone":"installations"},
		{"id":"install_controller", "role":"controller", "pos":Vector2(3030,1030), "zone":"installations"},
		{"id":"dredge_warden", "role":"field_boss", "pos":FIELD_BOSS_POSITION, "zone":"field_boss", "optional":true},
	]


static func pickup_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var offset := Vector2(0.0, 0.0) if normalized_id(stage_id) == &"flooded_works" else Vector2(40.0, -60.0)
	return [
		{"id":"repair_open", "kind":"repair", "pos":Vector2(1500,1050) + offset},
		{"id":"attack_upper", "kind":"attack", "pos":Vector2(2080,470) + offset},
		{"id":"overdrive_lower", "kind":"overdrive", "pos":Vector2(2120,1690) - offset},
		{"id":"barrier_lower", "kind":"barrier", "pos":Vector2(3170,1780) - offset},
		{"id":"repair_relay", "kind":"repair", "pos":Vector2(3660,1110)},
	]


static func crate_blueprint(stage_id: StringName) -> Array[Dictionary]:
	var shifted := normalized_id(stage_id) != &"flooded_works"
	return [
		{"id":"crate_attack", "pos":Vector2(1080,1510) if shifted else Vector2(1110,1510), "drop":"attack"},
		{"id":"crate_repair", "pos":Vector2(1810,1080) if shifted else Vector2(1880,1130), "drop":"repair"},
		{"id":"crate_barrier", "pos":Vector2(3360,1120) if shifted else Vector2(3370,1080), "drop":"barrier"},
	]


static func environment_zones(stage_id: StringName) -> Array[Dictionary]:
	match normalized_id(stage_id):
		&"tidal_archive":
			return [
				{"rect":Rect2(720,980,1120,240), "direction":Vector2.RIGHT, "strength":72.0},
				{"rect":Rect2(2000,1440,1350,220), "direction":Vector2.LEFT, "strength":86.0},
			]
		&"storm_drydock":
			return [
				{"rect":Rect2(760,540,3000,260), "phase":0.0},
				{"rect":Rect2(760,1400,3000,260), "phase":2.2},
			]
	return []


static func _boundaries() -> Array[Rect2]:
	return [
		Rect2(0.0, 0.0, 5200.0, 70.0), Rect2(0.0, 2130.0, 5200.0, 70.0),
		Rect2(0.0, 0.0, 70.0, 2200.0), Rect2(5130.0, 0.0, 70.0, 2200.0),
	]
