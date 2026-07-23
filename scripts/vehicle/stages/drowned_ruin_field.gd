class_name DrownedRuinField
extends RefCounted

## Immutable floor topology and authored sockets used by the run layout generator.

const FIELD_ID := &"drowned_ruin_field"
const WORLD_RECT := Rect2(0.0, 0.0, 5600.0, 3400.0)
const CENTER := Vector2(2800.0, 1700.0)
const START_CLEARANCE := 480.0

const ORDINARY_SPAWN_CANDIDATES: Array[Vector2] = [
	Vector2(480,520), Vector2(880,480), Vector2(1280,560), Vector2(4320,520),
	Vector2(4800,480), Vector2(5200,640), Vector2(480,2860), Vector2(880,2920),
	Vector2(1280,2820), Vector2(4320,2860), Vector2(4800,2920), Vector2(5200,2760),
	Vector2(1900,700), Vector2(3600,700), Vector2(1900,2700), Vector2(3600,2700),
	Vector2(1540,620), Vector2(2380,620), Vector2(3220,620), Vector2(4060,620),
	Vector2(1540,2780), Vector2(2380,2780), Vector2(3220,2780), Vector2(4060,2780),
]

const BOSS_ARRIVAL_ANCHORS: Array[Vector2] = [
	Vector2(520,960), Vector2(1280,440), Vector2(4320,440), Vector2(5080,960),
	Vector2(520,2440), Vector2(1280,2960), Vector2(4320,2960), Vector2(5080,2440),
]

const COVER_CANDIDATES: Array[Dictionary] = [
	{"id":&"nw_a", "quadrant":&"nw", "rect":Rect2(600,650,260,150)},
	{"id":&"nw_b", "quadrant":&"nw", "rect":Rect2(1200,1020,300,150)},
	{"id":&"nw_c", "quadrant":&"nw", "rect":Rect2(1760,780,240,160)},
	{"id":&"nw_d", "quadrant":&"nw", "rect":Rect2(1870,1160,220,160)},
	{"id":&"ne_a", "quadrant":&"ne", "rect":Rect2(4740,650,260,150)},
	{"id":&"ne_b", "quadrant":&"ne", "rect":Rect2(4100,1020,300,150)},
	{"id":&"ne_c", "quadrant":&"ne", "rect":Rect2(3600,780,240,160)},
	{"id":&"ne_d", "quadrant":&"ne", "rect":Rect2(3510,1160,220,160)},
	{"id":&"sw_a", "quadrant":&"sw", "rect":Rect2(600,2600,260,150)},
	{"id":&"sw_b", "quadrant":&"sw", "rect":Rect2(1200,2230,300,150)},
	{"id":&"sw_c", "quadrant":&"sw", "rect":Rect2(1760,2460,240,160)},
	{"id":&"sw_d", "quadrant":&"sw", "rect":Rect2(1870,2080,220,160)},
	{"id":&"se_a", "quadrant":&"se", "rect":Rect2(4740,2600,260,150)},
	{"id":&"se_b", "quadrant":&"se", "rect":Rect2(4100,2230,300,150)},
	{"id":&"se_c", "quadrant":&"se", "rect":Rect2(3600,2460,240,160)},
	{"id":&"se_d", "quadrant":&"se", "rect":Rect2(3510,2080,220,160)},
]

const FALLBACK_COVER_IDS: Array[StringName] = [
	&"nw_a", &"nw_c", &"ne_b", &"ne_d",
	&"sw_b", &"sw_d", &"se_a", &"se_c",
]

const STATIONARY_CANDIDATES := {
	&"nw":[Vector2(1120,1340), Vector2(1640,1180), Vector2(1940,1400)],
	&"ne":[Vector2(4480,1340), Vector2(3960,1180), Vector2(4060,1500)],
	&"sw":[Vector2(1120,2060), Vector2(1640,2220), Vector2(1940,2000)],
	&"se":[Vector2(4480,2060), Vector2(3960,2220), Vector2(4060,1900)],
}

const ITEM_SOCKET_CANDIDATES: Array[Vector2] = [
	Vector2(1080,920), Vector2(1420,1420), Vector2(1420,1980), Vector2(1080,2480),
	Vector2(1900,920), Vector2(2180,1460), Vector2(2180,1940), Vector2(1900,2480),
	Vector2(2300,1540), Vector2(2300,1860), Vector2(2680,920), Vector2(2920,920),
	Vector2(2680,2480), Vector2(2920,2480), Vector2(3300,920), Vector2(3300,2480),
	Vector2(3740,920), Vector2(3740,2480), Vector2(4020,1500), Vector2(4020,1900),
	Vector2(4520,1100), Vector2(4520,2300), Vector2(5000,850), Vector2(5000,2550),
]


static func definition() -> Dictionary:
	return {
		"id": FIELD_ID,
		"world_rect": WORLD_RECT,
		"player_start": CENTER,
		"start_clearance": START_CLEARANCE,
		"walkable_regions": _walkable_regions(),
		"cover_rects": [],
		"water_rects": _water_rects(),
		"motifs": _motifs(),
		"ordinary_spawn_anchors": ORDINARY_SPAWN_CANDIDATES.duplicate(),
		"boss_arrival_anchors": BOSS_ARRIVAL_ANCHORS.duplicate(),
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
