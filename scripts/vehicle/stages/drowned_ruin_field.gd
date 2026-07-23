class_name DrownedRuinField
extends RefCounted

## Immutable geometry and field-object anchors shared by every combat stage.

const FIELD_ID := &"drowned_ruin_field"
const WORLD_RECT := Rect2(0.0, 0.0, 5600.0, 3400.0)
const CENTER := Vector2(2800.0, 1700.0)
const START_CLEARANCE := 480.0

const ORDINARY_SPAWN_ANCHORS: Array[Vector2] = [
	Vector2(480,520), Vector2(880,480), Vector2(1280,560), Vector2(4320,520),
	Vector2(4800,480), Vector2(5200,640), Vector2(480,2860), Vector2(880,2920),
	Vector2(1280,2820), Vector2(4320,2860), Vector2(4800,2920), Vector2(5200,2760),
	Vector2(1900,700), Vector2(3600,700), Vector2(1900,2700), Vector2(3600,2700),
]

const BOSS_ARRIVAL_ANCHORS: Array[Vector2] = [
	Vector2(520,960), Vector2(1280,440), Vector2(4320,440), Vector2(5080,960),
	Vector2(520,2440), Vector2(1280,2960), Vector2(4320,2960), Vector2(5080,2440),
]

const STATIONARY_ANCHORS: Array[Vector2] = [
	Vector2(3650,1250), Vector2(3650,2110), Vector2(3320,890), Vector2(3320,2510),
]


static func definition() -> Dictionary:
	return {
		"id": FIELD_ID,
		"world_rect": WORLD_RECT,
		"player_start": CENTER,
		"start_clearance": START_CLEARANCE,
		"walkable_regions": _walkable_regions(),
		"cover_rects": _cover_rects(),
		"water_rects": _water_rects(),
		"motifs": _motifs(),
		"ordinary_spawn_anchors": ORDINARY_SPAWN_ANCHORS.duplicate(),
		"boss_arrival_anchors": BOSS_ARRIVAL_ANCHORS.duplicate(),
		"stationary_anchors": STATIONARY_ANCHORS.duplicate(),
		"pickups": _pickups(),
		"crates": _crates(),
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"west_upper", "name":"West Learning Loop", "rect":Rect2(1020,720,1120,820), "tone":&"light"},
		{"id":"west_lower", "name":"West Return Loop", "rect":Rect2(1020,1860,1120,820), "tone":&"light"},
		{"id":"west_bridge", "name":"Calibration Causeway", "rect":Rect2(1580,1420,940,560), "tone":&"mid"},
		{"id":"central_plaza", "name":"Calibration Plaza", "rect":Rect2(2400,1260,800,880), "tone":&"light"},
		{"id":"north_riser", "name":"North Rise", "rect":Rect2(2640,580,620,800), "tone":&"mid"},
		{"id":"north_lane", "name":"North Lane", "rect":Rect2(3120,720,880,620), "tone":&"dark"},
		{"id":"south_riser", "name":"South Drop", "rect":Rect2(2640,2020,620,800), "tone":&"mid"},
		{"id":"south_lane", "name":"South Lane", "rect":Rect2(3120,2060,880,620), "tone":&"dark"},
		{"id":"relay_court", "name":"Relay Court", "rect":Rect2(3800,1200,520,1000), "tone":&"mid"},
		{"id":"east_basin", "name":"East Basin", "rect":Rect2(4160,880,800,1640), "tone":&"dark"},
		{"id":"northwest_court", "name":"Northwest Court", "rect":Rect2(240,300,1400,900), "tone":&"light"},
		{"id":"southwest_court", "name":"Southwest Court", "rect":Rect2(240,2200,1400,900), "tone":&"light"},
		{"id":"northeast_court", "name":"Northeast Court", "rect":Rect2(3960,300,1400,900), "tone":&"mid"},
		{"id":"southeast_court", "name":"Southeast Court", "rect":Rect2(3960,2200,1400,900), "tone":&"mid"},
		{"id":"north_outer_lane", "name":"North Outer Lane", "rect":Rect2(1380,500,2840,520), "tone":&"dark"},
		{"id":"south_outer_lane", "name":"South Outer Lane", "rect":Rect2(1380,2380,2840,520), "tone":&"dark"},
	]


static func _cover_rects() -> Array[Rect2]:
	return [
		Rect2(1250,1060,300,170), Rect2(1190,2180,360,170),
		Rect2(1920,1560,250,280),
		Rect2(3330,1060,260,150), Rect2(3330,2190,260,150),
		Rect2(3910,1380,170,180), Rect2(3910,1840,170,180),
		Rect2(4690,1080,150,220), Rect2(4690,2100,150,220),
		Rect2(640,690,280,180), Rect2(640,2530,280,180),
		Rect2(4680,690,280,180), Rect2(4680,2530,280,180),
	]


static func _water_rects() -> Array[Rect2]:
	return [
		Rect2(80,60,2400,180), Rect2(3120,60,2400,180),
		Rect2(80,3160,2400,180), Rect2(3120,3160,2400,180),
	]


static func _motifs() -> Array[Dictionary]:
	return [
		{"kind":&"tide_curl", "center":Vector2(1120,560), "radius":210.0, "rotation":-0.28},
		{"kind":&"split_current", "center":Vector2(1250,2850), "radius":245.0, "rotation":0.0},
		{"kind":&"relay_flower", "center":Vector2(4440,900), "radius":135.0, "rotation":PI / 4.0},
		{"kind":&"sun_gate", "center":Vector2(4360,2520), "radius":235.0, "rotation":0.0},
	]


static func _pickups() -> Array[Dictionary]:
	return [
		{"id":"repair_center", "kind":&"repair", "heal_amount":35.0, "pos":Vector2(2300,1700)},
		{"id":"experience_recall_north", "kind":&"experience_recall", "pos":Vector2(3640,870)},
		{"id":"repair_east", "kind":&"repair", "heal_amount":70.0, "pos":Vector2(4280,2350)},
	]


static func _crates() -> Array[Dictionary]:
	return [
		{"id":"crate_repair_west", "pos":Vector2(1330,2000), "drop":&"repair"},
		{"id":"crate_repair_center", "pos":Vector2(2210,1810), "drop":&"repair"},
		{"id":"crate_repair_relay", "pos":Vector2(3860,1710), "drop":&"repair"},
		{"id":"crate_repair_loop", "pos":Vector2(2020,1460), "drop":&"repair"},
		{"id":"crate_recall", "pos":Vector2(4300,990), "drop":&"experience_recall"},
	]
