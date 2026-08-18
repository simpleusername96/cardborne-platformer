class_name VehicleField01
extends RefCounted

## Broad central court and four outer courts for field 01.

const FIELD_ID := &"field_01"
const WORLD_RECT := Rect2(0.0, 0.0, 7200.0, 4320.0)
const CENTER := Vector2(3600.0, 2160.0)
const START_CLEARANCE := 560.0

const ORDINARY_SPAWN_CANDIDATES: Array[Vector2] = [
	Vector2(520,620), Vector2(1040,520), Vector2(1580,600), Vector2(2200,660),
	Vector2(5000,660), Vector2(5620,600), Vector2(6160,520), Vector2(6680,620),
	Vector2(520,3700), Vector2(1040,3800), Vector2(1580,3720), Vector2(2200,3660),
	Vector2(5000,3660), Vector2(5620,3720), Vector2(6160,3800), Vector2(6680,3700),
	Vector2(620,1320), Vector2(620,2160), Vector2(620,3000), Vector2(6580,1320),
	Vector2(6580,2160), Vector2(6580,3000), Vector2(2500,560), Vector2(3100,560),
	Vector2(4100,560), Vector2(4700,560), Vector2(2500,3760), Vector2(3100,3760),
	Vector2(4100,3760), Vector2(4700,3760), Vector2(1720,2160), Vector2(5480,2160),
]

const BOSS_ARRIVAL_ANCHORS: Array[Vector2] = [
	Vector2(560,980), Vector2(1440,520), Vector2(2780,560), Vector2(4420,560),
	Vector2(5760,520), Vector2(6640,980), Vector2(560,3340), Vector2(1440,3800),
	Vector2(2780,3760), Vector2(4420,3760), Vector2(5760,3800), Vector2(6640,3340),
]

const ITEM_SOCKET_CANDIDATES: Array[Vector2] = [
	Vector2(900,1080), Vector2(1200,1800), Vector2(1200,2520), Vector2(900,3240),
	Vector2(1700,900), Vector2(1900,1660), Vector2(1900,2660), Vector2(1700,3420),
	Vector2(2460,980), Vector2(2460,1700), Vector2(2460,2620), Vector2(2460,3340),
	Vector2(2920,920), Vector2(3260,1080), Vector2(3940,1080), Vector2(4280,920),
	Vector2(2920,3400), Vector2(3260,3240), Vector2(3940,3240), Vector2(4280,3400),
	Vector2(4740,980), Vector2(4740,1700), Vector2(4740,2620), Vector2(4740,3340),
	Vector2(5500,900), Vector2(5300,1660), Vector2(5300,2660), Vector2(5500,3420),
	Vector2(6300,1080), Vector2(6000,1800), Vector2(6000,2520), Vector2(6300,3240),
	Vector2(2800,2160), Vector2(3200,1540), Vector2(4000,2780), Vector2(4400,2160),
]


static func definition() -> Dictionary:
	return {
		"id": FIELD_ID,
		"world_rect": WORLD_RECT,
		"player_start": CENTER,
		"start_clearance": START_CLEARANCE,
		"walkable_regions": _walkable_regions(),
		"cover_rects": [],
		"void_rects": _void_rects(),
		"ordinary_spawn_anchors": ORDINARY_SPAWN_CANDIDATES.duplicate(),
		"boss_arrival_anchors": BOSS_ARRIVAL_ANCHORS.duplicate(),
		"item_socket_candidates": ITEM_SOCKET_CANDIDATES.duplicate(),
		"outer_courts": [
			Vector2(720,900), Vector2(6480,900), Vector2(720,3420), Vector2(6480,3420),
		],
		"features": _features(),
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"field_foundation", "rect":Rect2(240,360,6720,3600), "tone":&"mid"},
		{"id":"central_plaza", "rect":Rect2(2520,1260,2160,1800), "tone":&"light"},
		{"id":"west_bridge", "rect":Rect2(1320,1480,1440,1360), "tone":&"mid"},
		{"id":"east_bridge", "rect":Rect2(4440,1480,1440,1360), "tone":&"mid"},
		{"id":"north_loop", "rect":Rect2(1280,440,4640,760), "tone":&"dark"},
		{"id":"south_loop", "rect":Rect2(1280,3120,4640,760), "tone":&"dark"},
		{"id":"west_court", "rect":Rect2(240,560,1480,3200), "tone":&"light"},
		{"id":"east_court", "rect":Rect2(5480,560,1480,3200), "tone":&"light"},
		{"id":"northwest_court", "rect":Rect2(560,360,1800,1160), "tone":&"light"},
		{"id":"northeast_court", "rect":Rect2(4840,360,1800,1160), "tone":&"mid"},
		{"id":"southwest_court", "rect":Rect2(560,2800,1800,1160), "tone":&"light"},
		{"id":"southeast_court", "rect":Rect2(4840,2800,1800,1160), "tone":&"mid"},
		{"id":"north_riser", "rect":Rect2(3040,800,1120,760), "tone":&"mid"},
		{"id":"south_riser", "rect":Rect2(3040,2760,1120,760), "tone":&"mid"},
		{"id":"west_upper", "rect":Rect2(920,900,1800,900), "tone":&"light"},
		{"id":"west_lower", "rect":Rect2(920,2520,1800,900), "tone":&"light"},
		{"id":"east_upper", "rect":Rect2(4480,900,1800,900), "tone":&"dark"},
		{"id":"east_lower", "rect":Rect2(4480,2520,1800,900), "tone":&"dark"},
		{"id":"central_north", "rect":Rect2(2780,920,1640,720), "tone":&"mid"},
		{"id":"central_south", "rect":Rect2(2780,2680,1640,720), "tone":&"mid"},
		{"id":"central_cross", "rect":Rect2(1880,1840,3440,640), "tone":&"light"},
	]


static func _void_rects() -> Array[Rect2]:
	return [
		Rect2(80,60,3000,200), Rect2(4120,60,3000,200),
		Rect2(80,4060,3000,200), Rect2(4120,4060,3000,200),
	]


static func _features() -> Array[Dictionary]:
	return [
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(780,900)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(6420,3420)},
		{"id":&"gate_b_1", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(6420,900)},
		{"id":&"gate_b_2", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(780,3420)},
	]
