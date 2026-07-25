class_name TidalArchiveField
extends RefCounted

## Two lateral archive halls joined by three wide crossings.

const FIELD_ID := &"tidal_archive_field"
const NAME_KEY := "FIELD_TIDAL_ARCHIVE"
const WORLD_RECT := Rect2(0.0, 0.0, 7200.0, 4320.0)
const CENTER := Vector2(3600.0, 2160.0)
const START_CLEARANCE := 560.0

const ORDINARY_SPAWN_CANDIDATES: Array[Vector2] = [
	Vector2(520,600), Vector2(980,520), Vector2(1480,560), Vector2(2080,620),
	Vector2(5120,620), Vector2(5720,560), Vector2(6220,520), Vector2(6680,600),
	Vector2(520,3720), Vector2(980,3800), Vector2(1480,3760), Vector2(2080,3700),
	Vector2(5120,3700), Vector2(5720,3760), Vector2(6220,3800), Vector2(6680,3720),
	Vector2(620,1260), Vector2(620,2160), Vector2(620,3060), Vector2(6580,1260),
	Vector2(6580,2160), Vector2(6580,3060), Vector2(2600,720), Vector2(3200,720),
	Vector2(4000,720), Vector2(4600,720), Vector2(2600,3600), Vector2(3200,3600),
	Vector2(4000,3600), Vector2(4600,3600), Vector2(1700,2160), Vector2(5500,2160),
]

const BOSS_ARRIVAL_ANCHORS: Array[Vector2] = [
	Vector2(560,980), Vector2(1500,520), Vector2(2780,700), Vector2(4420,700),
	Vector2(5700,520), Vector2(6640,980), Vector2(560,3340), Vector2(1500,3800),
	Vector2(2780,3620), Vector2(4420,3620), Vector2(5700,3800), Vector2(6640,3340),
]

const COVER_CANDIDATES: Array[Dictionary] = [
	{"id":&"nw_a", "sector":&"nw", "rect":Rect2(760,840,300,170)},
	{"id":&"nw_b", "sector":&"nw", "rect":Rect2(1380,1180,340,180)},
	{"id":&"nw_c", "sector":&"nw", "rect":Rect2(1940,780,280,180)},
	{"id":&"nw_d", "sector":&"nw", "rect":Rect2(2020,1440,260,180)},
	{"id":&"n_a", "sector":&"n", "rect":Rect2(2680,720,300,170)},
	{"id":&"n_b", "sector":&"n", "rect":Rect2(3260,980,280,170)},
	{"id":&"n_c", "sector":&"n", "rect":Rect2(3900,980,280,170)},
	{"id":&"n_d", "sector":&"n", "rect":Rect2(4480,720,300,170)},
	{"id":&"ne_a", "sector":&"ne", "rect":Rect2(6140,840,300,170)},
	{"id":&"ne_b", "sector":&"ne", "rect":Rect2(5480,1180,340,180)},
	{"id":&"ne_c", "sector":&"ne", "rect":Rect2(4980,780,280,180)},
	{"id":&"ne_d", "sector":&"ne", "rect":Rect2(4920,1440,260,180)},
	{"id":&"sw_a", "sector":&"sw", "rect":Rect2(760,3310,300,170)},
	{"id":&"sw_b", "sector":&"sw", "rect":Rect2(1380,2960,340,180)},
	{"id":&"sw_c", "sector":&"sw", "rect":Rect2(1940,3360,280,180)},
	{"id":&"sw_d", "sector":&"sw", "rect":Rect2(2020,2700,260,180)},
	{"id":&"s_a", "sector":&"s", "rect":Rect2(2680,3430,300,170)},
	{"id":&"s_b", "sector":&"s", "rect":Rect2(3260,3170,280,170)},
	{"id":&"s_c", "sector":&"s", "rect":Rect2(3900,3170,280,170)},
	{"id":&"s_d", "sector":&"s", "rect":Rect2(4480,3430,300,170)},
	{"id":&"se_a", "sector":&"se", "rect":Rect2(6140,3310,300,170)},
	{"id":&"se_b", "sector":&"se", "rect":Rect2(5480,2960,340,180)},
	{"id":&"se_c", "sector":&"se", "rect":Rect2(4980,3360,280,180)},
	{"id":&"se_d", "sector":&"se", "rect":Rect2(4920,2700,260,180)},
]

const FALLBACK_COVER_IDS: Array[StringName] = [
	&"nw_b", &"n_a", &"n_c", &"ne_b", &"sw_b", &"s_a", &"s_c", &"se_b",
]

const STATIONARY_CANDIDATES := {
	&"nw":[Vector2(1100,1540), Vector2(1700,1340), Vector2(2120,1640)],
	&"n":[Vector2(2900,1140), Vector2(3600,980), Vector2(4300,1140)],
	&"ne":[Vector2(6100,1540), Vector2(5500,1340), Vector2(5080,1640)],
	&"sw":[Vector2(1100,2780), Vector2(1700,2980), Vector2(2120,2680)],
	&"s":[Vector2(2900,3180), Vector2(3600,3340), Vector2(4300,3180)],
	&"se":[Vector2(6100,2780), Vector2(5500,2980), Vector2(5080,2680)],
}

const ITEM_SOCKET_CANDIDATES: Array[Vector2] = [
	Vector2(900,1040), Vector2(1120,1760), Vector2(1120,2560), Vector2(900,3280),
	Vector2(1700,900), Vector2(1880,1680), Vector2(1880,2640), Vector2(1700,3420),
	Vector2(2440,780), Vector2(2500,1520), Vector2(2500,2160), Vector2(2500,2800),
	Vector2(2920,960), Vector2(3240,1140), Vector2(3960,1140), Vector2(4280,960),
	Vector2(2920,3360), Vector2(3240,3180), Vector2(3960,3180), Vector2(4280,3360),
	Vector2(4700,780), Vector2(4700,1520), Vector2(4700,2160), Vector2(4700,2800),
	Vector2(5500,900), Vector2(5320,1680), Vector2(5320,2640), Vector2(5500,3420),
	Vector2(6300,1040), Vector2(6080,1760), Vector2(6080,2560), Vector2(6300,3280),
	Vector2(2860,2160), Vector2(3200,1860), Vector2(4000,2460), Vector2(4340,2160),
]


static func definition() -> Dictionary:
	return {
		"id":FIELD_ID, "name_key":NAME_KEY, "world_rect":WORLD_RECT,
		"player_start":CENTER, "start_clearance":START_CLEARANCE,
		"walkable_regions":_walkable_regions(), "cover_rects":[],
		"water_rects":_water_rects(),
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
		{"id":"west_hall", "rect":Rect2(240,480,2260,3360), "tone":&"light"},
		{"id":"east_hall", "rect":Rect2(4700,480,2260,3360), "tone":&"mid"},
		{"id":"north_crossing", "rect":Rect2(2100,560,3000,920), "tone":&"dark"},
		{"id":"central_crossing", "rect":Rect2(1940,1720,3320,880), "tone":&"light"},
		{"id":"south_crossing", "rect":Rect2(2100,2840,3000,920), "tone":&"dark"},
		{"id":"central_court", "rect":Rect2(2760,1260,1680,1800), "tone":&"light"},
		{"id":"west_north_stack", "rect":Rect2(520,360,1640,1120), "tone":&"mid"},
		{"id":"west_south_stack", "rect":Rect2(520,2840,1640,1120), "tone":&"mid"},
		{"id":"east_north_stack", "rect":Rect2(5040,360,1640,1120), "tone":&"light"},
		{"id":"east_south_stack", "rect":Rect2(5040,2840,1640,1120), "tone":&"light"},
		{"id":"west_upper_gallery", "rect":Rect2(900,980,1900,820), "tone":&"light"},
		{"id":"west_lower_gallery", "rect":Rect2(900,2520,1900,820), "tone":&"light"},
		{"id":"east_upper_gallery", "rect":Rect2(4400,980,1900,820), "tone":&"mid"},
		{"id":"east_lower_gallery", "rect":Rect2(4400,2520,1900,820), "tone":&"mid"},
		{"id":"north_archive", "rect":Rect2(2920,440,1360,1080), "tone":&"dark"},
		{"id":"south_archive", "rect":Rect2(2920,2800,1360,1080), "tone":&"dark"},
		{"id":"west_mid", "rect":Rect2(400,1520,1800,1280), "tone":&"light"},
		{"id":"east_mid", "rect":Rect2(5000,1520,1800,1280), "tone":&"mid"},
		{"id":"north_link", "rect":Rect2(2380,920,2440,520), "tone":&"dark"},
		{"id":"south_link", "rect":Rect2(2380,2880,2440,520), "tone":&"dark"},
	]


static func _water_rects() -> Array[Rect2]:
	return [Rect2(80,60,7040,180), Rect2(80,4080,7040,180)]


static func _features() -> Array[Dictionary]:
	return [
		{"id":&"surge_1", "kind":&"arc_surge", "rect":Rect2(6000,1720,360,880)},
		{"id":&"bulkhead_1", "kind":&"breakable_bulkhead", "rect":Rect2(2140,2040,180,240)},
		{"id":&"bulkhead_2", "kind":&"breakable_bulkhead", "rect":Rect2(4880,2040,180,240)},
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(720,900)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(6480,3420)},
		{"id":&"gate_b_1", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(6480,900)},
		{"id":&"gate_b_2", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(720,3420)},
	]
