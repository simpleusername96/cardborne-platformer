class_name StormDrydockField
extends RefCounted

## Center basin, broad perimeter loops, and diagonal drydock approaches.

const FIELD_ID := &"storm_drydock_field"
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
		"id":FIELD_ID, "world_rect":WORLD_RECT,
		"player_start":CENTER, "start_clearance":START_CLEARANCE,
		"walkable_regions":_walkable_regions(), "cover_rects":[],
		"void_rects":_void_rects(),
		"ordinary_spawn_anchors":ORDINARY_SPAWN_CANDIDATES.duplicate(),
		"boss_arrival_anchors":BOSS_ARRIVAL_ANCHORS.duplicate(),
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
		{"id":&"gate_a_1", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(720,900)},
		{"id":&"gate_a_2", "kind":&"transit_gate", "pair":&"a", "pos":Vector2(6480,3420)},
		{"id":&"gate_b_1", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(6480,900)},
		{"id":&"gate_b_2", "kind":&"transit_gate", "pair":&"b", "pos":Vector2(720,3420)},
	]
