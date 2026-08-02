class_name StormDrydockField
extends RefCounted

## Center basin, broad perimeter loops, and diagonal drydock approaches.

const FIELD_ID := &"storm_drydock_field"
const NAME_KEY := "FIELD_STORM_DRYDOCK"
const WORLD_RECT := Rect2(0.0, 0.0, 7200.0, 4320.0)
const CENTER := Vector2(3600.0, 2160.0)
const START_CLEARANCE := 560.0

const ORDINARY_SPAWN_CANDIDATES: Array[Vector2] = [
	Vector2(520,600), Vector2(1040,520), Vector2(1600,560), Vector2(2200,640),
	Vector2(5000,640), Vector2(5600,560), Vector2(6160,520), Vector2(6680,600),
	Vector2(520,3720), Vector2(1040,3800), Vector2(1600,3760), Vector2(2200,3680),
	Vector2(5000,3680), Vector2(5600,3760), Vector2(6160,3800), Vector2(6680,3720),
	Vector2(600,1320), Vector2(600,2160), Vector2(600,3000), Vector2(6600,1320),
	Vector2(6600,2160), Vector2(6600,3000), Vector2(2600,600), Vector2(3200,600),
	Vector2(4000,600), Vector2(4600,600), Vector2(2600,3720), Vector2(3200,3720),
	Vector2(4000,3720), Vector2(4600,3720), Vector2(1760,2160), Vector2(5440,2160),
]

const BOSS_ARRIVAL_ANCHORS: Array[Vector2] = [
	Vector2(560,980), Vector2(1460,520), Vector2(2780,600), Vector2(4420,600),
	Vector2(5740,520), Vector2(6640,980), Vector2(560,3340), Vector2(1460,3800),
	Vector2(2780,3720), Vector2(4420,3720), Vector2(5740,3800), Vector2(6640,3340),
]

const COVER_CANDIDATES: Array[Dictionary] = [
	{"id":&"nw_a", "sector":&"nw", "rect":Rect2(760,820,300,170)},
	{"id":&"nw_b", "sector":&"nw", "rect":Rect2(1420,1100,340,180)},
	{"id":&"nw_c", "sector":&"nw", "rect":Rect2(2040,800,280,180)},
	{"id":&"nw_d", "sector":&"nw", "rect":Rect2(2240,1400,260,180)},
	{"id":&"n_a", "sector":&"n", "rect":Rect2(2780,700,300,170)},
	{"id":&"n_b", "sector":&"n", "rect":Rect2(3340,960,280,170)},
	{"id":&"n_c", "sector":&"n", "rect":Rect2(3980,960,280,170)},
	{"id":&"n_d", "sector":&"n", "rect":Rect2(4460,700,300,170)},
	{"id":&"ne_a", "sector":&"ne", "rect":Rect2(6140,820,300,170)},
	{"id":&"ne_b", "sector":&"ne", "rect":Rect2(5440,1100,340,180)},
	{"id":&"ne_c", "sector":&"ne", "rect":Rect2(4880,800,280,180)},
	{"id":&"ne_d", "sector":&"ne", "rect":Rect2(4700,1400,260,180)},
	{"id":&"sw_a", "sector":&"sw", "rect":Rect2(760,3330,300,170)},
	{"id":&"sw_b", "sector":&"sw", "rect":Rect2(1420,3040,340,180)},
	{"id":&"sw_c", "sector":&"sw", "rect":Rect2(2040,3340,280,180)},
	{"id":&"sw_d", "sector":&"sw", "rect":Rect2(2240,2740,260,180)},
	{"id":&"s_a", "sector":&"s", "rect":Rect2(2780,3450,300,170)},
	{"id":&"s_b", "sector":&"s", "rect":Rect2(3340,3190,280,170)},
	{"id":&"s_c", "sector":&"s", "rect":Rect2(3980,3190,280,170)},
	{"id":&"s_d", "sector":&"s", "rect":Rect2(4460,3450,300,170)},
	{"id":&"se_a", "sector":&"se", "rect":Rect2(6140,3330,300,170)},
	{"id":&"se_b", "sector":&"se", "rect":Rect2(5440,3040,340,180)},
	{"id":&"se_c", "sector":&"se", "rect":Rect2(4880,3340,280,180)},
	{"id":&"se_d", "sector":&"se", "rect":Rect2(4700,2740,260,180)},
]

const FALLBACK_COVER_IDS: Array[StringName] = [
	&"n_a", &"n_d", &"ne_d", &"nw_c", &"s_c", &"s_d", &"se_d", &"sw_b",
]

const STATIONARY_CANDIDATES := {
	&"nw":[Vector2(1180,1500), Vector2(1700,1260), Vector2(2240,1600)],
	&"n":[Vector2(2920,1100), Vector2(3600,920), Vector2(4280,1100)],
	&"ne":[Vector2(6020,1500), Vector2(5500,1260), Vector2(4960,1600)],
	&"sw":[Vector2(1180,2820), Vector2(1700,3060), Vector2(2240,2720)],
	&"s":[Vector2(2920,3220), Vector2(3600,3400), Vector2(4280,3220)],
	&"se":[Vector2(6020,2820), Vector2(5500,3060), Vector2(4960,2720)],
}

const ITEM_SOCKET_CANDIDATES: Array[Vector2] = [
	Vector2(900,1040), Vector2(1160,1740), Vector2(1160,2580), Vector2(900,3280),
	Vector2(1720,900), Vector2(1940,1620), Vector2(1940,2700), Vector2(1720,3420),
	Vector2(2460,920), Vector2(2460,1660), Vector2(2460,2660), Vector2(2460,3400),
	Vector2(2920,900), Vector2(3240,1080), Vector2(3960,1080), Vector2(4280,900),
	Vector2(2920,3420), Vector2(3240,3240), Vector2(3960,3240), Vector2(4280,3420),
	Vector2(4740,920), Vector2(4740,1660), Vector2(4740,2660), Vector2(4740,3400),
	Vector2(5480,900), Vector2(5260,1620), Vector2(5260,2700), Vector2(5480,3420),
	Vector2(6300,1040), Vector2(6040,1740), Vector2(6040,2580), Vector2(6300,3280),
	Vector2(2800,2160), Vector2(3180,1560), Vector2(4020,2760), Vector2(4400,2160),
]


static func definition() -> Dictionary:
	return {
		"id":FIELD_ID, "name_key":NAME_KEY, "world_rect":WORLD_RECT,
		"player_start":CENTER, "start_clearance":START_CLEARANCE,
		"walkable_regions":_walkable_regions(), "cover_rects":[],
		"void_rects":_void_rects(),
		"ordinary_spawn_anchors":ORDINARY_SPAWN_CANDIDATES.duplicate(),
		"boss_arrival_anchors":BOSS_ARRIVAL_ANCHORS.duplicate(),
		"cover_candidates":COVER_CANDIDATES.duplicate(true),
		"fallback_cover_ids":FALLBACK_COVER_IDS.duplicate(),
		"stationary_candidates":STATIONARY_CANDIDATES.duplicate(true),
		"item_socket_candidates":ITEM_SOCKET_CANDIDATES.duplicate(),
		"outer_courts":[Vector2(720,900), Vector2(6480,900), Vector2(720,3420), Vector2(6480,3420)],
		"features":_features(),
	}


static func _walkable_regions() -> Array[Dictionary]:
	return [
		{"id":"field_foundation", "rect":Rect2(240,360,6720,3600), "tone":&"mid"},
		{"id":"center_basin", "rect":Rect2(2380,1120,2440,2080), "tone":&"light"},
		{"id":"north_loop", "rect":Rect2(760,360,5680,820), "tone":&"dark"},
		{"id":"south_loop", "rect":Rect2(760,3140,5680,820), "tone":&"dark"},
		{"id":"west_loop", "rect":Rect2(240,720,1480,2880), "tone":&"mid"},
		{"id":"east_loop", "rect":Rect2(5480,720,1480,2880), "tone":&"mid"},
		{"id":"northwest_approach", "rect":Rect2(1280,760,1880,1280), "tone":&"light"},
		{"id":"northeast_approach", "rect":Rect2(4040,760,1880,1280), "tone":&"light"},
		{"id":"southwest_approach", "rect":Rect2(1280,2280,1880,1280), "tone":&"light"},
		{"id":"southeast_approach", "rect":Rect2(4040,2280,1880,1280), "tone":&"light"},
		{"id":"west_court", "rect":Rect2(480,1160,1760,2000), "tone":&"mid"},
		{"id":"east_court", "rect":Rect2(4960,1160,1760,2000), "tone":&"mid"},
		{"id":"north_court", "rect":Rect2(2460,440,2280,1160), "tone":&"dark"},
		{"id":"south_court", "rect":Rect2(2460,2720,2280,1160), "tone":&"dark"},
		{"id":"west_mid", "rect":Rect2(1120,1680,1800,960), "tone":&"light"},
		{"id":"east_mid", "rect":Rect2(4280,1680,1800,960), "tone":&"light"},
		{"id":"northwest_dock", "rect":Rect2(560,440,1900,1260), "tone":&"mid"},
		{"id":"northeast_dock", "rect":Rect2(4740,440,1900,1260), "tone":&"mid"},
		{"id":"southwest_dock", "rect":Rect2(560,2620,1900,1260), "tone":&"mid"},
		{"id":"southeast_dock", "rect":Rect2(4740,2620,1900,1260), "tone":&"mid"},
		{"id":"central_cross", "rect":Rect2(1700,1840,3800,640), "tone":&"light"},
	]


static func _void_rects() -> Array[Rect2]:
	return [
		Rect2(80,60,2760,180), Rect2(4360,60,2760,180),
		Rect2(80,4080,2760,180), Rect2(4360,4080,2760,180),
	]


static func _features() -> Array[Dictionary]:
	return [
		{"id":&"surge_1", "kind":&"arc_surge", "rect":Rect2(1120,1980,760,360)},
		{"id":&"surge_2", "kind":&"arc_surge", "rect":Rect2(6100,1980,760,360)},
		{"id":&"wear_1", "kind":&"wear_collapse_tile", "rect":Rect2(3280,1400,240,160)},
		{"id":&"wear_2", "kind":&"wear_collapse_tile", "rect":Rect2(3680,1400,240,160)},
		{"id":&"wear_3", "kind":&"wear_collapse_tile", "rect":Rect2(3280,2760,240,160)},
		{"id":&"wear_4", "kind":&"wear_collapse_tile", "rect":Rect2(3680,2760,240,160)},
		{"id":&"bulkhead_1", "kind":&"breakable_bulkhead", "rect":Rect2(2100,2040,180,240), "reward_pos":Vector2(2410,2160)},
		{"id":&"bulkhead_1_top", "kind":&"structural_wall", "rect":Rect2(2100,1840,640,200)},
		{"id":&"bulkhead_1_end", "kind":&"structural_wall", "rect":Rect2(2540,2040,200,240)},
		{"id":&"bulkhead_1_bottom", "kind":&"structural_wall", "rect":Rect2(2100,2280,640,200)},
		{"id":&"bulkhead_2", "kind":&"breakable_bulkhead", "rect":Rect2(4920,2040,180,240), "reward_pos":Vector2(4790,2160)},
		{"id":&"bulkhead_2_top", "kind":&"structural_wall", "rect":Rect2(4460,1840,640,200)},
		{"id":&"bulkhead_2_end", "kind":&"structural_wall", "rect":Rect2(4460,2040,200,240)},
		{"id":&"bulkhead_2_bottom", "kind":&"structural_wall", "rect":Rect2(4460,2280,640,200)},
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(720,900)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(6480,3420)},
		{"id":&"gate_b_1", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(6480,900)},
		{"id":&"gate_b_2", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(720,3420)},
	]
