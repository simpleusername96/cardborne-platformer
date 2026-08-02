class_name DrownedRuinField
extends RefCounted

## Broad central court and four outer courts for the drowned-ruin field.

const FIELD_ID := &"drowned_ruin_field"
const NAME_KEY := "FIELD_DROWNED_RUIN"
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

const COVER_CANDIDATES: Array[Dictionary] = [
	{"id":&"nw_a", "sector":&"nw", "rect":Rect2(760,820,300,170)},
	{"id":&"nw_b", "sector":&"nw", "rect":Rect2(1420,1120,340,180)},
	{"id":&"nw_c", "sector":&"nw", "rect":Rect2(2060,820,280,180)},
	{"id":&"nw_d", "sector":&"nw", "rect":Rect2(2260,1360,260,180)},
	{"id":&"n_a", "sector":&"n", "rect":Rect2(2800,700,300,170)},
	{"id":&"n_b", "sector":&"n", "rect":Rect2(3360,920,280,170)},
	{"id":&"n_c", "sector":&"n", "rect":Rect2(3980,700,300,170)},
	{"id":&"n_d", "sector":&"n", "rect":Rect2(4460,1080,260,180)},
	{"id":&"ne_a", "sector":&"ne", "rect":Rect2(6140,820,300,170)},
	{"id":&"ne_b", "sector":&"ne", "rect":Rect2(5440,1120,340,180)},
	{"id":&"ne_c", "sector":&"ne", "rect":Rect2(4860,820,280,180)},
	{"id":&"ne_d", "sector":&"ne", "rect":Rect2(4680,1360,260,180)},
	{"id":&"sw_a", "sector":&"sw", "rect":Rect2(760,3330,300,170)},
	{"id":&"sw_b", "sector":&"sw", "rect":Rect2(1420,3020,340,180)},
	{"id":&"sw_c", "sector":&"sw", "rect":Rect2(2060,3320,280,180)},
	{"id":&"sw_d", "sector":&"sw", "rect":Rect2(2260,2780,260,180)},
	{"id":&"s_a", "sector":&"s", "rect":Rect2(2800,3450,300,170)},
	{"id":&"s_b", "sector":&"s", "rect":Rect2(3360,3230,280,170)},
	{"id":&"s_c", "sector":&"s", "rect":Rect2(3980,3450,300,170)},
	{"id":&"s_d", "sector":&"s", "rect":Rect2(4460,3060,260,180)},
	{"id":&"se_a", "sector":&"se", "rect":Rect2(6140,3330,300,170)},
	{"id":&"se_b", "sector":&"se", "rect":Rect2(5440,3020,340,180)},
	{"id":&"se_c", "sector":&"se", "rect":Rect2(4860,3320,280,180)},
	{"id":&"se_d", "sector":&"se", "rect":Rect2(4680,2780,260,180)},
]

const FALLBACK_COVER_IDS: Array[StringName] = [
	&"n_d", &"ne_b", &"nw_b", &"nw_c", &"s_a", &"s_c", &"se_d", &"sw_c",
]

const STATIONARY_CANDIDATES := {
	&"nw":[Vector2(1180,1500), Vector2(1720,1320), Vector2(2200,1580)],
	&"n":[Vector2(2920,1120), Vector2(3600,940), Vector2(4280,1120)],
	&"ne":[Vector2(6020,1500), Vector2(5480,1320), Vector2(5000,1580)],
	&"sw":[Vector2(1180,2820), Vector2(1720,3000), Vector2(2200,2740)],
	&"s":[Vector2(2920,3200), Vector2(3600,3380), Vector2(4280,3200)],
	&"se":[Vector2(6020,2820), Vector2(5480,3000), Vector2(5000,2740)],
}

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
		"name_key": NAME_KEY,
		"world_rect": WORLD_RECT,
		"player_start": CENTER,
		"start_clearance": START_CLEARANCE,
		"walkable_regions": _walkable_regions(),
		"cover_rects": [],
		"void_rects": _void_rects(),
		"ordinary_spawn_anchors": ORDINARY_SPAWN_CANDIDATES.duplicate(),
		"boss_arrival_anchors": BOSS_ARRIVAL_ANCHORS.duplicate(),
		"cover_candidates": COVER_CANDIDATES.duplicate(true),
		"fallback_cover_ids": FALLBACK_COVER_IDS.duplicate(),
		"stationary_candidates": STATIONARY_CANDIDATES.duplicate(true),
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
		{"id":&"surge_1", "kind":&"arc_surge", "rect":Rect2(3420,3120,360,760)},
		{"id":&"wear_1", "kind":&"wear_collapse_tile", "rect":Rect2(3280,1400,240,160)},
		{"id":&"wear_2", "kind":&"wear_collapse_tile", "rect":Rect2(3680,1400,240,160)},
		{"id":&"wear_3", "kind":&"wear_collapse_tile", "rect":Rect2(3280,2760,240,160)},
		{"id":&"wear_4", "kind":&"wear_collapse_tile", "rect":Rect2(3680,2760,240,160)},
		{"id":&"bulkhead_1", "kind":&"breakable_bulkhead", "rect":Rect2(1580,2040,180,240), "reward_pos":Vector2(1890,2160)},
		{"id":&"bulkhead_1_top", "kind":&"structural_wall", "rect":Rect2(1580,1840,640,200)},
		{"id":&"bulkhead_1_end", "kind":&"structural_wall", "rect":Rect2(2020,2040,200,240)},
		{"id":&"bulkhead_1_bottom", "kind":&"structural_wall", "rect":Rect2(1580,2280,640,200)},
		{"id":&"bulkhead_2", "kind":&"breakable_bulkhead", "rect":Rect2(5440,2040,180,240), "reward_pos":Vector2(5310,2160)},
		{"id":&"bulkhead_2_top", "kind":&"structural_wall", "rect":Rect2(4980,1840,640,200)},
		{"id":&"bulkhead_2_end", "kind":&"structural_wall", "rect":Rect2(4980,2040,200,240)},
		{"id":&"bulkhead_2_bottom", "kind":&"structural_wall", "rect":Rect2(4980,2280,640,200)},
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(780,900)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(6420,3420)},
		{"id":&"gate_b_1", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(6420,900)},
		{"id":&"gate_b_2", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(780,3420)},
	]
