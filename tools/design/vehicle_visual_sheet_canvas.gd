class_name VehicleVisualSheetCanvas
extends Control

## Deterministic design-sheet renderer fed by the runtime token and component
## providers. These sheets are inspection views, never runtime texture assets.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const ProjectileCatalog = preload(
	"res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd"
)
const RewardCatalog = preload(
	"res://scripts/presentation/components/vehicle_reward_visual_catalog.gd"
)
const EffectCatalog = preload(
	"res://scripts/presentation/components/vehicle_effect_visual_catalog.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const GlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)
const ComponentMeshes = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)
const Visuals = preload(
	"res://scripts/presentation/vehicle_combat_visual_library.gd"
)
const FONT_PATH := "res://art/ui/production/fonts/NotoSansKR-Variable.ttf"

const SHEET_TITLES := {
	&"foundation": ["01  FOUNDATION TOKENS", "기본 토큰 · semantic roles · component grammar"],
	&"world_surfaces": ["02  WORLD SURFACES", "세 필드의 대형 패널 리듬 · geometry truth preserved"],
	&"world_facilities": ["03  WORLD FACILITIES", "기능별 실루엣 · idle / warning / active / cooldown"],
	&"player": ["04  PLAYER COMPONENTS", "compact interceptor · rigid twin engines · independent aim"],
	&"enemies": ["05  ENEMY COMPONENTS", "역할별 외곽선 · target priority before decoration"],
	&"bosses": ["06  BOSS COMPONENTS", "다섯 arena exam · distinct body and objective module"],
	&"projectiles": ["07  PROJECTILE · TELEGRAPH · VFX", "collision-bounded core · affinity tail · directional feedback"],
	&"rewards": ["08  REWARD · UPGRADE GLYPHS", "보상과 위협의 즉시 구분 · shape remains meaningful in grayscale"],
	&"hud": ["09  HUD · MINIMAP MARKERS", "four-zone HUD · sparse center · shared world markers"],
	&"controls": ["10  UI CONTROL STATES", "one border · one semantic rail · 44 px minimum target"],
	&"modals": ["11  MODAL FLOW CONTACT SHEET", "eight surfaces · compact and wide composition contract"],
	&"pressure": ["12  PRESSURE · ACCESSIBILITY", "1× combat density · grayscale · reduced-motion proof layout"],
}

var sheet_id: StringName = &"foundation"
var _font: Font
var _white_texture: Texture2D
var _retained_draw_meshes: Array[Mesh] = []


func _ready() -> void:
	_font = load(FONT_PATH) as Font
	var white_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white_image.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(white_image)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Art.SPACE_BLACK)
	_draw_header()
	match sheet_id:
		&"foundation":
			_draw_foundation()
		&"world_surfaces":
			_draw_world_surfaces()
		&"world_facilities":
			_draw_world_facilities()
		&"player":
			_draw_player_components()
		&"enemies":
			_draw_enemy_components()
		&"bosses":
			_draw_boss_components()
		&"projectiles":
			_draw_projectile_components()
		&"rewards":
			_draw_reward_components()
		&"hud":
			_draw_hud_components()
		&"controls":
			_draw_controls()
		&"modals":
			_draw_modal_contact_sheet()
		&"pressure":
			_draw_pressure_accessibility()


func _draw_header() -> void:
	var copy: Array = SHEET_TITLES.get(
		sheet_id,
		["VISUAL SYSTEM", "runtime-backed inspection sheet"]
	)
	_label(Vector2(72.0, 84.0), String(copy[0]), 36, Art.TEXT_PRIMARY)
	_label(Vector2(72.0, 126.0), String(copy[1]), 17, Art.TEXT_MUTED)
	_label(
		Vector2(1520.0, 84.0),
		"Cardborne · GENERAL SF v1",
		14,
		Art.SYSTEM
	)
	draw_line(Vector2(72.0, 154.0), Vector2(1976.0, 154.0), Art.LINE, 1.0)


func _draw_foundation() -> void:
	var roles := Art.required_color_roles()
	var role_order := [
		"space_black", "world_canvas", "surface", "raised", "line",
		"text_primary", "text_muted", "player_reward", "danger", "boss_command",
		"support", "system", "thermal", "toxin", "cryo", "arc",
	]
	for index in role_order.size():
		var column := index % 4
		var row := index / 4
		var rect := Rect2(72.0 + column * 310.0, 190.0 + row * 116.0, 278.0, 88.0)
		_draw_token(rect, role_order[index], Color(roles[role_order[index]]))
	var type_x := 1370.0
	_label(Vector2(type_x, 190.0), "TYPE SCALE / Noto Sans KR", 20, Art.TEXT_PRIMARY)
	var type_labels := ["caption", "body", "label", "section", "title", "display"]
	for index in Art.TYPE_SCALE_WIDE.size():
		var font_size := int(Art.TYPE_SCALE_WIDE[index])
		_label(
			Vector2(type_x, 242.0 + index * 72.0),
			"%s  %d  기체 상태 / SHIP STATUS" % [type_labels[index], font_size],
			font_size,
			Art.TEXT_PRIMARY if index > 1 else Art.TEXT_MUTED
		)
	_label(Vector2(72.0, 734.0), "SPACING", 20, Art.TEXT_PRIMARY)
	var spacing_x := 72.0
	for spacing in Art.SPACING_SCALE:
		draw_rect(Rect2(spacing_x, 774.0, float(spacing) * 4.0, 18.0), Art.SYSTEM)
		_label(Vector2(spacing_x, 826.0), str(spacing), 15, Art.TEXT_MUTED)
		spacing_x += float(spacing) * 4.0 + 34.0
	_label(Vector2(790.0, 734.0), "ROLE GRAMMAR", 20, Art.TEXT_PRIMARY)
	for index in 5:
		var primitives := [
			&"player_interceptor", &"split_spear", &"solid_chevron",
			&"diamond", &"slab",
		]
		var colors := [
			Art.PLAYER_REWARD, Art.DANGER, Art.SUPPORT,
			Art.BOSS_COMMAND, Art.SYSTEM,
		]
		var captions := ["player", "threat", "support", "boss", "system"]
		_draw_primitive(
			Vector2(900.0 + index * 234.0, 864.0),
			primitives[index],
			colors[index],
			58.0
		)
		_label(
			Vector2(836.0 + index * 234.0, 966.0),
			captions[index],
			13,
			Art.TEXT_MUTED
		)
	_footer("Shape + notch + rail pattern carry meaning; color is secondary.")


func _draw_world_surfaces() -> void:
	var fields := [
		{
			"id": &"drowned_ruin_field",
			"name": "FIELD 01 · CENTRAL COURT",
			"accent": Art.SYSTEM,
			"rhythm": &"court",
		},
		{
			"id": &"tidal_archive_field",
			"name": "FIELD 02 · PARALLEL BAYS",
			"accent": Art.SUPPORT,
			"rhythm": &"bays",
		},
		{
			"id": &"storm_drydock_field",
			"name": "FIELD 03 · DIAGONAL DOCK",
			"accent": Art.PLAYER_REWARD,
			"rhythm": &"dock",
		},
	]
	for index in fields.size():
		var rect := Rect2(72.0 + index * 628.0, 194.0, 580.0, 790.0)
		_draw_field_preview(rect, Dictionary(fields[index]))
		var descriptor := Dictionary(
			WorldCatalog.FIELD_DESCRIPTORS[fields[index]["id"]]
		)
		_label(
			rect.position + Vector2(22.0, rect.size.y - 36.0),
			"decoration ≤ %d · one large mass rhythm"
			% int(descriptor["decoration_budget"]),
			13,
			Art.TEXT_MUTED
		)
	_footer("Design proof only · field geometry, cover, sockets and navigation remain gameplay truth.")


func _draw_field_preview(rect: Rect2, field: Dictionary) -> void:
	_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Color(field["accent"]))
	_label(rect.position + Vector2(22.0, 38.0), String(field["name"]), 18, Art.TEXT_PRIMARY)
	var map_rect := Rect2(rect.position + Vector2(22.0, 64.0), rect.size - Vector2(44.0, 132.0))
	draw_rect(map_rect, Art.SURFACE)
	draw_rect(map_rect, Art.LINE, false, 1.0)
	var accent := Color(field["accent"])
	match StringName(field["rhythm"]):
		&"court":
			_draw_plate(map_rect.grow(-36.0), 42.0, Art.RAISED)
			_draw_plate(
				Rect2(map_rect.get_center() - Vector2(112.0, 170.0), Vector2(224.0, 340.0)),
				28.0,
				Art.WORLD_CANVAS
			)
			draw_line(
				Vector2(map_rect.position.x + 54.0, map_rect.get_center().y),
				Vector2(map_rect.end.x - 54.0, map_rect.get_center().y),
				accent,
				7.0
			)
		&"bays":
			for row in 3:
				var bay := Rect2(
					map_rect.position + Vector2(34.0, 44.0 + row * 170.0),
					Vector2(map_rect.size.x - 68.0, 116.0)
				)
				_draw_plate(bay, 22.0, Art.RAISED)
				draw_line(
					bay.position + Vector2(32.0, bay.size.y * 0.5),
					bay.end - Vector2(32.0, bay.size.y * 0.5),
					accent,
					4.0
				)
		&"dock":
			var center := map_rect.get_center()
			for offset in [-150.0, 0.0, 150.0]:
				draw_line(
					center + Vector2(-230.0, offset - 110.0),
					center + Vector2(230.0, offset + 110.0),
					Art.LINE,
					26.0
				)
				draw_line(
					center + Vector2(-230.0, offset - 110.0),
					center + Vector2(230.0, offset + 110.0),
					accent,
					3.0
				)
			_draw_plate(
				Rect2(center - Vector2(120.0, 160.0), Vector2(240.0, 320.0)),
				30.0,
				Art.RAISED
			)
	_draw_world_marker(map_rect.get_center(), &"player", 1.0)


func _draw_world_facilities() -> void:
	var facilities := [
		[&"repair_field", "REPAIR / 수리", Art.SUPPORT],
		[&"transit_gate", "TRANSIT / 이동", Art.SYSTEM],
		[&"overdrive_field", "OVERDRIVE / 가속", Art.PLAYER_REWARD],
		[&"arc_surge_strip", "ARC SURGE / 전격", Art.ARC],
		[&"breakable_bulkhead", "BULKHEAD / 파괴벽", Art.RAISED],
	]
	var states := ["IDLE", "WARNING", "ACTIVE", "COOLDOWN"]
	for row in facilities.size():
		var y := 206.0 + row * 164.0
		_label(Vector2(72.0, y + 30.0), String(facilities[row][1]), 16, Art.TEXT_PRIMARY)
		for column in states.size():
			var rect := Rect2(400.0 + column * 390.0, y, 350.0, 130.0)
			var alpha: float = [0.58, 0.82, 1.0, 0.28][column]
			_draw_panel(
				rect,
				Art.WORLD_CANVAS,
				Art.LINE,
				Color(facilities[row][2], alpha)
			)
			_draw_facility_glyph(
				rect.get_center() - Vector2(64.0, 0.0),
				StringName(facilities[row][0]),
				Color(facilities[row][2], alpha),
				42.0
			)
			_label(
				rect.position + Vector2(170.0, 55.0),
				states[column],
				14,
				Art.TEXT_PRIMARY if column != 3 else Art.TEXT_MUTED
			)
	_footer("Facility identity never depends on pulse, label, or hue alone.")


func _draw_player_components() -> void:
	var assembly_rect := Rect2(72.0, 194.0, 900.0, 690.0)
	_draw_panel(assembly_rect, Art.WORLD_CANVAS, Art.LINE, Art.PLAYER_REWARD)
	_label(assembly_rect.position + Vector2(24.0, 42.0), "ASSEMBLED / 조립 상태", 20, Art.TEXT_PRIMARY)
	_draw_player_assembly(Vector2(520.0, 535.0), 180.0, Vector2.RIGHT, Vector2.RIGHT.rotated(-0.42), 0.70)
	_draw_measure(
		Vector2(260.0, 800.0),
		Vector2(780.0, 800.0),
		"enlarged inspection view · gameplay 1× appears in MOTION STATES"
	)
	var exploded := Rect2(1010.0, 194.0, 966.0, 390.0)
	_draw_panel(exploded, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(exploded.position + Vector2(24.0, 42.0), "COMPONENT OWNERSHIP", 20, Art.TEXT_PRIMARY)
	_draw_mesh_at(Visuals.player_hull_mesh(), Vector2(1192.0, 390.0), Vector2.ONE * 96.0, 0.0, Art.PLAYER_REWARD)
	_draw_mesh_at(Visuals.player_engine_mesh(), Vector2(1480.0, 340.0), Vector2(44.0, 30.0), 0.0, Art.TEXT_MUTED)
	_draw_mesh_at(Visuals.player_engine_flare_mesh(), Vector2(1480.0, 434.0), Vector2(62.0, 20.0), 0.0, Art.SYSTEM)
	_draw_mesh_at(Visuals.player_primary_mesh(), Vector2(1760.0, 390.0), Vector2(80.0, 30.0), -0.42, Art.PLAYER_REWARD)
	_label(Vector2(1110.0, 536.0), "HULL", 14, Art.TEXT_MUTED)
	_label(Vector2(1400.0, 536.0), "RIGID TWIN ENGINE", 14, Art.TEXT_MUTED)
	_label(Vector2(1680.0, 536.0), "AIM MOUNT", 14, Art.TEXT_MUTED)
	var state_rect := Rect2(1010.0, 622.0, 966.0, 262.0)
	_draw_panel(state_rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(state_rect.position + Vector2(24.0, 40.0), "MOTION STATES", 20, Art.TEXT_PRIMARY)
	var state_names := ["NORMAL", "THRUST", "DASH", "HIT"]
	for index in state_names.size():
		var center := state_rect.position + Vector2(126.0 + index * 230.0, 150.0)
		_draw_player_assembly(
			center,
			48.0,
			Vector2.RIGHT,
			Vector2.RIGHT,
			[0.12, 0.72, 1.0, 0.22][index],
			Art.DANGER if index == 3 else Art.PLAYER_REWARD,
			index == 2
		)
		_label(center + Vector2(-38.0, 88.0), state_names[index], 13, Art.TEXT_MUTED)
	_footer("Engine modules rotate only with the hull; the aim mount rotates only with aim.")


func _draw_enemy_components() -> void:
	var ids := [
		&"scrap_drone", &"needle_drone", &"spark_minelet",
		&"chaser", &"shooter", &"controller",
		&"turret", &"mine", &"generator",
		&"shield_escort", &"artillery_spotter", &"interceptor_tower",
		&"rammer", &"bulkhead_guard", &"splitter_barge",
		&"repair_tender", &"drone_carrier", &"beam_sentinel",
	]
	for index in ids.size():
		var column := index % 6
		var row := index / 6
		var rect := Rect2(72.0 + column * 316.0, 190.0 + row * 288.0, 284.0, 252.0)
		var id := StringName(ids[index])
		var descriptor := ActorCatalog.descriptor(id)
		var role := StringName(descriptor.get("role", &"threat"))
		var color := _role_color(role)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, color)
		_draw_mesh_at(
			Visuals.enemy_mesh(id),
			rect.get_center() - Vector2(0.0, 22.0),
			Vector2.ONE * (54.0 if id not in [&"turret", &"generator"] else 62.0),
			0.0,
			color
		)
		_label(rect.position + Vector2(18.0, 30.0), String(id).to_upper(), 13, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(18.0, 226.0), String(role), 12, Art.TEXT_MUTED)
	_footer("18 role signatures · no role ring · command/support use body modules and shape.")


func _draw_boss_components() -> void:
	var bosses := [
		[&"colossus", "FOUNDRY COLOSSUS", "forge plate", &"forge_plate"],
		[&"leviathan", "ARCHIVE LEVIATHAN", "segment lock", &"segment_lock"],
		[&"titan", "DRYDOCK TITAN", "relay polarity", &"relay_positive"],
		[&"behemoth", "SWITCHYARD BEHEMOTH", "route switch", &"route_switch"],
		[&"crown", "CROWN ENGINE", "lattice command", &"lattice_outer"],
	]
	for index in bosses.size():
		var rect := Rect2(72.0 + index * 380.0, 196.0, 348.0, 730.0)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Art.BOSS_COMMAND)
		_label(rect.position + Vector2(20.0, 36.0), String(bosses[index][1]), 16, Art.TEXT_PRIMARY)
		_draw_mesh_at(
			Visuals.boss_mesh(StringName(bosses[index][0])),
			rect.get_center() - Vector2(0.0, 112.0),
			Vector2.ONE * 118.0,
			-PI * 0.5,
			Art.BOSS_COMMAND
		)
		_draw_boss_modules(
			rect.get_center() + Vector2(0.0, 86.0),
			StringName(bosses[index][3])
		)
		_label(rect.position + Vector2(20.0, 612.0), "EXAM", 12, Art.TEXT_MUTED)
		_label(rect.position + Vector2(20.0, 642.0), String(bosses[index][2]), 15, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(20.0, 684.0), "P1 → P2 → P3", 13, Art.SYSTEM)
	_footer("Each boss owns a body, an objective module, and a sequential phase read.")


func _draw_projectile_components() -> void:
	var affinities := [
		[&"kinetic", "KINETIC", Art.DANGER],
		[&"thermal", "THERMAL", Art.THERMAL],
		[&"toxin", "TOXIN", Art.TOXIN],
		[&"cryo", "CRYO", Art.CRYO],
		[&"arc", "ARC", Art.ARC],
		[&"hybrid", "HYBRID", Art.TEXT_PRIMARY],
	]
	for index in affinities.size():
		var rect := Rect2(72.0 + (index % 3) * 628.0, 194.0 + (index / 3) * 214.0, 580.0, 178.0)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Color(affinities[index][2]))
		_label(rect.position + Vector2(20.0, 34.0), String(affinities[index][1]), 16, Art.TEXT_PRIMARY)
		_draw_mesh_at(
			Visuals.hostile_projectile_mesh(StringName(affinities[index][0])),
			rect.position + Vector2(310.0, 92.0),
			Vector2(26.0, 18.0),
			0.0,
			Color(affinities[index][2])
		)
		draw_circle(rect.position + Vector2(486.0, 92.0), 10.0, Art.SPACE_BLACK)
		draw_circle(rect.position + Vector2(486.0, 92.0), 6.0, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(430.0, 146.0), "core = hit", 12, Art.TEXT_MUTED)
	_label(Vector2(72.0, 668.0), "TELEGRAPH FOOTPRINTS", 20, Art.TEXT_PRIMARY)
	var telegraphs := [
		["LINE", &"line"], ["CONE", &"cone"], ["AREA", &"area"],
		["LOCK", &"lock"], ["IMPACT", &"impact"],
	]
	for index in telegraphs.size():
		var rect := Rect2(72.0 + index * 380.0, 706.0, 348.0, 276.0)
		_draw_panel(rect, Art.SURFACE, Art.LINE, Art.DANGER)
		_draw_telegraph(rect, StringName(telegraphs[index][1]))
		_label(rect.position + Vector2(18.0, 248.0), String(telegraphs[index][0]), 13, Art.TEXT_MUTED)
	_footer("Bright cores stop at collision truth; tails and telegraphs may extend beyond it.")


func _draw_reward_components() -> void:
	var rewards := [
		[&"experience_small", "XP · SMALL", Art.PLAYER_REWARD],
		[&"experience_medium", "XP · MEDIUM", Art.PLAYER_REWARD],
		[&"experience_large", "XP · LARGE", Art.PLAYER_REWARD],
		[&"repair", "REPAIR", Art.SUPPORT],
		[&"experience_recall", "RECALL", Art.SYSTEM],
		[&"reward_crate", "CRATE", Art.PLAYER_REWARD],
	]
	for index in rewards.size():
		var rect := Rect2(72.0 + index * 316.0, 194.0, 284.0, 310.0)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Color(rewards[index][2]))
		_draw_reward_glyph(
			rect.get_center() - Vector2(0.0, 18.0),
			StringName(rewards[index][0]),
			Color(rewards[index][2]),
			70.0
		)
		_label(rect.position + Vector2(18.0, 278.0), String(rewards[index][1]), 13, Art.TEXT_PRIMARY)
	_label(Vector2(72.0, 568.0), "UPGRADE FAMILIES", 20, Art.TEXT_PRIMARY)
	var families := GlyphCatalog.UPGRADE_FAMILY_GLYPHS.keys()
	families.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	for index in families.size():
		var family := StringName(families[index])
		var descriptor := GlyphCatalog.upgrade_family_descriptor(family)
		var column := index % 4
		var row := index / 4
		var rect := Rect2(72.0 + column * 474.0, 612.0 + row * 180.0, 442.0, 148.0)
		var color := _semantic_color(StringName(descriptor["color"]))
		_draw_panel(rect, Art.SURFACE, Art.LINE, color)
		_draw_primitive(
			rect.position + Vector2(76.0, 74.0),
			StringName(descriptor["shape"]),
			color,
			42.0
		)
		_label(rect.position + Vector2(146.0, 70.0), String(family).to_upper(), 15, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(146.0, 100.0), "family glyph", 12, Art.TEXT_MUTED)
	_footer("Rewards use gold/support/system; hostile red never appears on collectible bodies.")


func _draw_hud_components() -> void:
	var screen := Rect2(72.0, 194.0, 1260.0, 790.0)
	_draw_panel(screen, Art.WORLD_CANVAS, Art.LINE, Art.SYSTEM)
	_draw_mock_combat_field(screen.grow(-1.0), false)
	_draw_hud_zone(Rect2(96.0, 218.0, 350.0, 124.0), "HULL  86 / 100", Art.SUPPORT)
	_draw_hud_zone(Rect2(958.0, 218.0, 350.0, 124.0), "STAGE 03 · 62%", Art.SYSTEM)
	_draw_hud_zone(Rect2(96.0, 864.0, 474.0, 96.0), "PRIMARY · DASH · EMP", Art.PLAYER_REWARD)
	_draw_hud_zone(Rect2(834.0, 864.0, 474.0, 96.0), "TARGET · ARTILLERY", Art.DANGER)
	draw_rect(Rect2(486.0, 218.0, 380.0, 18.0), Art.SPACE_BLACK)
	draw_rect(Rect2(486.0, 218.0, 264.0, 18.0), Art.BOSS_COMMAND)
	_label(Vector2(588.0, 266.0), "central combat rectangle stays clear", 13, Art.TEXT_MUTED)
	var marker_rect := Rect2(1370.0, 194.0, 606.0, 790.0)
	_draw_panel(marker_rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(marker_rect.position + Vector2(24.0, 42.0), "MINIMAP / TARGET MARKERS", 20, Art.TEXT_PRIMARY)
	var marker_ids := [&"player", &"enemy", &"elite", &"boss", &"stationary", &"pickup", &"crate", &"target"]
	for index in marker_ids.size():
		var center := marker_rect.position + Vector2(82.0 + (index % 2) * 292.0, 126.0 + (index / 2) * 146.0)
		_draw_world_marker(center, marker_ids[index], 1.0)
		_label(center + Vector2(50.0, 6.0), String(marker_ids[index]), 14, Art.TEXT_PRIMARY)
	_footer("HUD decoration yields to live combat; markers reuse world identity and add shape beyond hue.")


func _draw_controls() -> void:
	var states := [
		{"id": "normal", "label": "기본 / NORMAL", "line": Art.LINE, "rail": Color.TRANSPARENT, "text": Art.TEXT_PRIMARY},
		{"id": "hover", "label": "가리킴 / HOVER", "line": Art.LINE, "rail": Art.SYSTEM, "text": Art.TEXT_PRIMARY},
		{"id": "focus", "label": "키보드 초점 / FOCUS", "line": Art.SYSTEM, "rail": Art.SYSTEM, "text": Art.TEXT_PRIMARY},
		{"id": "selected", "label": "선택 / SELECTED", "line": Art.LINE, "rail": Art.PLAYER_REWARD, "text": Art.TEXT_PRIMARY},
		{"id": "disabled", "label": "비활성 / DISABLED", "line": Art.LINE.darkened(0.35), "rail": Color.TRANSPARENT, "text": Art.TEXT_MUTED.darkened(0.28)},
		{"id": "danger", "label": "위험 / DANGER", "line": Art.DANGER, "rail": Art.DANGER, "text": Art.DANGER},
	]
	for index in states.size():
		var column := index % 3
		var row := index / 3
		var rect := Rect2(72.0 + column * 624.0, 210.0 + row * 176.0, 568.0, 132.0)
		_draw_control_state(rect, Dictionary(states[index]))
	_label(Vector2(72.0, 620.0), "PANEL HIERARCHY", 20, Art.TEXT_PRIMARY)
	var modal := Rect2(72.0, 660.0, 1190.0, 360.0)
	_draw_panel(modal, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(modal.position + Vector2(28.0, 48.0), "함선 시스템 / SHIP SYSTEMS", 28, Art.TEXT_PRIMARY)
	_label(modal.position + Vector2(28.0, 84.0), "Title → content → action", 15, Art.TEXT_MUTED)
	_draw_panel(Rect2(100.0, 782.0, 710.0, 180.0), Art.WORLD_CANVAS, Art.LINE, Color.TRANSPARENT)
	_label(Vector2(128.0, 830.0), "현재 상태", 17, Art.TEXT_PRIMARY)
	_label(Vector2(128.0, 870.0), "장갑  100 / 100", 15, Art.TEXT_MUTED)
	_label(Vector2(128.0, 906.0), "추진  준비", 15, Art.SUPPORT)
	_draw_button(Rect2(862.0, 886.0, 348.0, 64.0), "확인 / CONFIRM", Art.PLAYER_REWARD, true)
	_label(Vector2(1340.0, 620.0), "CONTROL FAMILY", 20, Art.TEXT_PRIMARY)
	_draw_button(Rect2(1340.0, 676.0, 560.0, 64.0), "주요 행동 / PRIMARY", Art.PLAYER_REWARD, true)
	_draw_button(Rect2(1340.0, 764.0, 560.0, 64.0), "보조 행동 / SECONDARY", Art.SYSTEM, false)
	_draw_button(Rect2(1340.0, 852.0, 560.0, 64.0), "위험 행동 / DANGER", Art.DANGER, false)
	_draw_checkbox(Rect2(1340.0, 948.0, 560.0, 56.0), "모션 감소 / REDUCED MOTION")
	_footer("Selected, focus, disabled, and danger remain identifiable without hue alone.")


func _draw_modal_contact_sheet() -> void:
	var surfaces := [
		["DEPLOYMENT", "출격 준비", &"primary"],
		["UPGRADE", "업그레이드 선택", &"cards"],
		["PAUSE", "일시 정지", &"list"],
		["GUIDEBOOK", "도감", &"split"],
		["REPORT", "전투 보고", &"metrics"],
		["RESULT", "작전 결과", &"result"],
		["GARAGE", "격납고", &"split"],
		["PRACTICE", "보스 연습", &"cards"],
	]
	for index in surfaces.size():
		var column := index % 4
		var row := index / 4
		var rect := Rect2(72.0 + column * 474.0, 194.0 + row * 416.0, 442.0, 374.0)
		_draw_modal_thumbnail(rect, surfaces[index])
	_footer("Compact stacks content; wide may split. Every modal keeps one unmistakable primary action.")


func _draw_pressure_accessibility() -> void:
	var live_rect := Rect2(72.0, 194.0, 1190.0, 790.0)
	_draw_panel(live_rect, Art.WORLD_CANVAS, Art.LINE, Art.DANGER)
	_draw_mock_combat_field(live_rect, true)
	_label(live_rect.position + Vector2(24.0, 38.0), "COMPOSITION TEST · GAMEPLAY 1×", 16, Art.TEXT_PRIMARY)
	var proof_rect := Rect2(1300.0, 194.0, 676.0, 790.0)
	_draw_panel(proof_rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(proof_rect.position + Vector2(24.0, 40.0), "ACCESSIBILITY CHECKS", 20, Art.TEXT_PRIMARY)
	var checks := [
		["GRAYSCALE", "role contours remain distinct", true],
		["REDUCED MOTION", "static dash beam + short afterimage", true],
		["CORE / TAIL", "collision core stays bright", true],
		["TARGET PRIORITY", "committed attack precedes trim", true],
		["CENTER CLEAR", "HUD does not cover player space", true],
		["TEXT FIT", "ko/en labels remain inside panels", true],
	]
	for index in checks.size():
		var rect := Rect2(
			proof_rect.position + Vector2(24.0, 90.0 + index * 104.0),
			Vector2(proof_rect.size.x - 48.0, 82.0)
		)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Art.SUPPORT)
		_draw_check(rect.position + Vector2(28.0, 41.0), bool(checks[index][2]))
		_label(rect.position + Vector2(64.0, 34.0), String(checks[index][0]), 14, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(64.0, 60.0), String(checks[index][1]), 12, Art.TEXT_MUTED)
	_footer("Inspection composition · final sheet is regenerated with production capture evidence in Phase 8.")


func _draw_player_assembly(
	center: Vector2,
	radius: float,
	hull_direction: Vector2,
	aim_direction: Vector2,
	thrust: float,
	hull_color: Color = Art.PLAYER_REWARD,
	dashing: bool = false
) -> void:
	var hull_angle := hull_direction.angle()
	var side := hull_direction.rotated(PI * 0.5)
	var rear := -hull_direction
	var descriptor := ActorCatalog.descriptor(&"player")
	for socket_variant in Array(descriptor["rear_sockets"]):
		var socket := Vector2(socket_variant)
		var mount := (
			center
			+ hull_direction * socket.x * radius
			+ side * socket.y * radius
		)
		_draw_mesh_at(
			Visuals.player_engine_flare_mesh(),
			mount + rear * radius * (0.22 + thrust * 0.12),
			Vector2(radius * (0.22 + thrust * 0.24), radius * 0.10),
			hull_angle,
			Art.SYSTEM if dashing else Art.PLAYER_REWARD
		)
		_draw_mesh_at(
			Visuals.player_engine_mesh(),
			mount,
			Vector2(radius * 0.20, radius * 0.14),
			hull_angle,
			Art.TEXT_MUTED
		)
	_draw_mesh_at(
		Visuals.player_hull_mesh(),
		center,
		Vector2.ONE * radius,
		hull_angle,
		hull_color
	)
	_draw_mesh_at(
		Visuals.player_primary_mesh(),
		center + aim_direction * radius * 0.18,
		Vector2(radius * 0.45, radius * 0.18),
		aim_direction.angle(),
		hull_color
	)
	if dashing:
		for index in 3:
			var after_center := center + rear * radius * (0.65 + index * 0.38)
			_draw_mesh_at(
				Visuals.player_hull_mesh(),
				after_center,
				Vector2.ONE * radius * (0.78 - index * 0.12),
				hull_angle,
				Color(Art.SYSTEM, 0.26 - index * 0.06)
			)


func _draw_mock_combat_field(rect: Rect2, dense: bool) -> void:
	var clip := rect.grow(-18.0)
	draw_rect(clip, Art.SURFACE)
	for index in 7:
		var x := clip.position.x + 40.0 + index * clip.size.x / 7.0
		draw_line(
			Vector2(x, clip.position.y),
			Vector2(x, clip.end.y),
			Color(Art.LINE, 0.22),
			1.0
		)
	for index in 5:
		var y := clip.position.y + 40.0 + index * clip.size.y / 5.0
		draw_line(
			Vector2(clip.position.x, y),
			Vector2(clip.end.x, y),
			Color(Art.LINE, 0.22),
			1.0
		)
	var player_center := clip.get_center()
	_draw_player_assembly(
		player_center,
		50.0,
		Vector2.RIGHT.rotated(-0.18),
		Vector2.RIGHT.rotated(-0.62),
		0.66
	)
	var enemy_ids := [
		&"chaser", &"shooter", &"controller", &"shield_escort",
		&"artillery_spotter", &"rammer", &"beam_sentinel",
	]
	var count := 22 if dense else 8
	for index in count:
		var angle := TAU * float(index) / float(count)
		var ring := 150.0 + float(index % 4) * 62.0
		var position := player_center + Vector2.RIGHT.rotated(angle) * ring
		if not clip.grow(-30.0).has_point(position):
			continue
		var id: StringName = enemy_ids[index % enemy_ids.size()]
		var color := _role_color(StringName(ActorCatalog.descriptor(id)["role"]))
		_draw_mesh_at(
			Visuals.enemy_mesh(id),
			position,
			Vector2.ONE * (28.0 if dense else 38.0),
			angle + PI,
			color
		)
	for index in (16 if dense else 6):
		var angle := -0.75 + float(index) * 0.09
		var position := player_center + Vector2.RIGHT.rotated(angle) * (100.0 + index * 19.0)
		_draw_mesh_at(
			Visuals.hostile_projectile_mesh(
				[&"kinetic", &"thermal", &"cryo", &"arc"][index % 4]
			),
			position,
			Vector2(7.0, 5.0),
			angle + PI,
			[Art.DANGER, Art.THERMAL, Art.CRYO, Art.ARC][index % 4]
		)


func _draw_facility_glyph(
	center: Vector2,
	facility_id: StringName,
	color: Color,
	scale: float
) -> void:
	match facility_id:
		&"repair_field":
			draw_rect(Rect2(center - Vector2(scale * 0.16, scale * 0.48), Vector2(scale * 0.32, scale * 0.96)), color)
			draw_rect(Rect2(center - Vector2(scale * 0.48, scale * 0.16), Vector2(scale * 0.96, scale * 0.32)), color)
		&"transit_gate":
			for sign_value in [-1.0, 1.0]:
				_draw_chevron(center + Vector2(sign_value * scale * 0.38, 0.0), Vector2(-sign_value, 0.0), scale * 0.72, color, scale * 0.18)
		&"overdrive_field":
			for offset in [-0.34, 0.0, 0.34]:
				_draw_chevron(center + Vector2(offset * scale, 0.0), Vector2.RIGHT, scale * 0.72, color, scale * 0.18)
		&"arc_surge_strip":
			var points := PackedVector2Array([
				center + Vector2(-scale * 0.52, -scale * 0.12),
				center + Vector2(-scale * 0.10, -scale * 0.44),
				center + Vector2(-scale * 0.02, -scale * 0.08),
				center + Vector2(scale * 0.48, -scale * 0.22),
				center + Vector2(scale * 0.08, scale * 0.44),
				center + Vector2(scale * 0.02, scale * 0.08),
			])
			draw_colored_polygon(points, color)
		_:
			draw_rect(Rect2(center - Vector2(scale * 0.54, scale * 0.34), Vector2(scale * 0.42, scale * 0.68)), color)
			draw_rect(Rect2(center + Vector2(scale * 0.12, -scale * 0.34), Vector2(scale * 0.42, scale * 0.68)), color)


func _draw_reward_glyph(
	center: Vector2,
	reward_id: StringName,
	color: Color,
	scale: float
) -> void:
	match reward_id:
		&"experience_small":
			_draw_regular_polygon(center, scale * 0.58, 4, color, PI / 4.0)
		&"experience_medium":
			_draw_regular_polygon(center, scale * 0.68, 6, color, PI / 6.0)
		&"experience_large":
			_draw_star(center, scale * 0.72, scale * 0.48, 8, color)
		&"repair":
			_draw_regular_polygon(center, scale * 0.78, 8, Art.TEXT_PRIMARY, PI / 8.0)
			_draw_facility_glyph(center, &"repair_field", color, scale)
		&"experience_recall":
			_draw_regular_polygon(center, scale * 0.78, 6, Art.TEXT_PRIMARY, PI / 6.0)
			_draw_facility_glyph(center, &"transit_gate", color, scale * 0.84)
		&"reward_crate":
			_draw_plate(Rect2(center - Vector2.ONE * scale * 0.68, Vector2.ONE * scale * 1.36), scale * 0.18, color)
			_draw_regular_polygon(center, scale * 0.30, 4, Art.SURFACE, PI / 4.0)


func _draw_world_marker(center: Vector2, marker_id: StringName, scale: float) -> void:
	var color := Art.TEXT_PRIMARY
	match marker_id:
		&"player":
			color = Art.PLAYER_REWARD
			_draw_primitive(center, &"player_interceptor", color, 25.0 * scale)
		&"enemy":
			color = Art.DANGER
			_draw_primitive(center, &"split_spear", color, 23.0 * scale)
		&"elite":
			color = Art.DANGER
			_draw_star(center, 28.0 * scale, 18.0 * scale, 6, color)
		&"boss":
			color = Art.BOSS_COMMAND
			_draw_regular_polygon(center, 27.0 * scale, 8, color, PI / 8.0)
		&"stationary":
			color = Art.DANGER
			_draw_regular_polygon(center, 25.0 * scale, 4, color, PI / 4.0)
		&"pickup":
			color = Art.SUPPORT
			_draw_regular_polygon(center, 23.0 * scale, 6, color, PI / 6.0)
		&"crate":
			color = Art.PLAYER_REWARD
			_draw_plate(Rect2(center - Vector2.ONE * 22.0 * scale, Vector2.ONE * 44.0 * scale), 7.0 * scale, color)
		_:
			color = Art.SYSTEM
			draw_arc(center, 26.0 * scale, -2.4, 2.4, 24, color, 4.0 * scale)


func _draw_boss_modules(center: Vector2, module_id: StringName) -> void:
	for index in 2:
		var module_center := center + Vector2((float(index) - 0.5) * 92.0, 0.0)
		_draw_mesh_at(
			Visuals.boss_module_mesh(module_id, &"active"),
			module_center,
			Vector2.ONE * 30.0,
			0.0,
			Color.WHITE
		)


func _draw_telegraph(rect: Rect2, kind: StringName) -> void:
	var center := rect.get_center() - Vector2(0.0, 12.0)
	match kind:
		&"line":
			draw_line(center - Vector2(118.0, 0.0), center + Vector2(118.0, 0.0), Color(Art.DANGER, 0.34), 28.0)
			draw_line(center - Vector2(118.0, 0.0), center + Vector2(118.0, 0.0), Art.DANGER, 3.0)
		&"cone":
			draw_colored_polygon(PackedVector2Array([
				center - Vector2(80.0, 0.0),
				center + Vector2(94.0, -72.0),
				center + Vector2(94.0, 72.0),
			]), Color(Art.DANGER, 0.24))
			draw_line(center - Vector2(80.0, 0.0), center + Vector2(94.0, -72.0), Art.DANGER, 3.0)
			draw_line(center - Vector2(80.0, 0.0), center + Vector2(94.0, 72.0), Art.DANGER, 3.0)
		&"area":
			draw_circle(center, 82.0, Color(Art.DANGER, 0.18))
			draw_arc(center, 82.0, 0.0, TAU, 48, Art.DANGER, 4.0)
		&"lock":
			for offset_variant in [Vector2(-52.0, -52.0), Vector2(52.0, -52.0), Vector2(52.0, 52.0), Vector2(-52.0, 52.0)]:
				var offset := Vector2(offset_variant)
				var direction: Vector2 = -offset.normalized()
				draw_line(center + offset, center + offset + direction * 26.0, Art.DANGER, 5.0)
		_:
			for index in 6:
				var direction := Vector2.RIGHT.rotated(TAU * float(index) / 6.0)
				draw_line(center + direction * 22.0, center + direction * 78.0, Art.TEXT_PRIMARY, 5.0)


func _draw_modal_thumbnail(rect: Rect2, surface: Array) -> void:
	_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Art.SYSTEM)
	_label(rect.position + Vector2(18.0, 30.0), String(surface[0]), 14, Art.TEXT_PRIMARY)
	_label(rect.position + Vector2(18.0, 55.0), String(surface[1]), 12, Art.TEXT_MUTED)
	var content := Rect2(rect.position + Vector2(18.0, 78.0), Vector2(rect.size.x - 36.0, 218.0))
	_draw_panel(content, Art.SURFACE, Art.LINE, Color.TRANSPARENT)
	match StringName(surface[2]):
		&"cards":
			for index in 3:
				_draw_panel(
					Rect2(content.position + Vector2(14.0 + index * 126.0, 18.0), Vector2(112.0, 180.0)),
					Art.WORLD_CANVAS,
					Art.LINE,
					Art.PLAYER_REWARD if index == 0 else Color.TRANSPARENT
				)
		&"split":
			_draw_panel(Rect2(content.position + Vector2(14.0, 18.0), Vector2(136.0, 180.0)), Art.WORLD_CANVAS, Art.LINE, Art.SYSTEM)
			_draw_panel(Rect2(content.position + Vector2(164.0, 18.0), Vector2(224.0, 180.0)), Art.WORLD_CANVAS, Art.LINE, Color.TRANSPARENT)
		&"metrics":
			for index in 3:
				draw_rect(Rect2(content.position + Vector2(18.0, 24.0 + index * 54.0), Vector2(310.0 - index * 44.0, 24.0)), Art.RAISED)
		&"result":
			_draw_regular_polygon(content.get_center() - Vector2(0.0, 28.0), 48.0, 6, Art.PLAYER_REWARD, PI / 6.0)
		_:
			for index in 4:
				draw_rect(Rect2(content.position + Vector2(18.0, 20.0 + index * 42.0), Vector2(content.size.x - 36.0, 24.0)), Art.RAISED)
	_draw_button(
		Rect2(rect.position + Vector2(18.0, 314.0), Vector2(rect.size.x - 36.0, 44.0)),
		"PRIMARY ACTION",
		Art.PLAYER_REWARD,
		true
	)


func _draw_hud_zone(rect: Rect2, text: String, accent: Color) -> void:
	_draw_panel(rect, Color(Art.SPACE_BLACK, 0.86), Art.LINE, accent)
	_label(rect.position + Vector2(18.0, rect.size.y * 0.58), text, 14, Art.TEXT_PRIMARY)


func _draw_control_state(rect: Rect2, state: Dictionary) -> void:
	_draw_panel(rect, Art.SURFACE, Color(state["line"]), Color(state["rail"]))
	if String(state["id"]) == "focus":
		draw_rect(rect.grow(4.0), Art.SYSTEM, false, 2.0)
	if String(state["id"]) == "selected":
		_draw_regular_polygon(rect.position + Vector2(48.0, 66.0), 10.0, 4, Art.PLAYER_REWARD, PI / 4.0)
	_label(rect.position + Vector2(76.0, 57.0), String(state["label"]), 17, Color(state["text"]))
	_label(rect.position + Vector2(76.0, 88.0), String(state["id"]), 13, Art.TEXT_MUTED)


func _draw_panel(rect: Rect2, fill: Color, line: Color, rail: Color) -> void:
	draw_rect(rect, fill)
	draw_rect(rect, line, false, 1.0)
	if rail.a > 0.0:
		draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), rail)


func _draw_plate(rect: Rect2, cut: float, color: Color) -> void:
	draw_colored_polygon(Art.stepped_rect(rect, cut), color)
	draw_polyline(Art.stepped_rect(rect, cut), Art.LINE, 1.0)


func _draw_token(rect: Rect2, role: String, color: Color) -> void:
	draw_rect(rect, Art.SURFACE)
	draw_rect(Rect2(rect.position, Vector2(74.0, rect.size.y)), color)
	draw_rect(rect, Art.LINE, false, 1.0)
	_label(rect.position + Vector2(92.0, 34.0), role, 15, Art.TEXT_PRIMARY)
	_label(rect.position + Vector2(92.0, 63.0), "#%s" % color.to_html(false).to_upper(), 13, Art.TEXT_MUTED)


func _draw_primitive(
	center: Vector2,
	primitive_id: StringName,
	color: Color,
	scale: float
) -> void:
	var points := ComponentMeshes.primitive_points(primitive_id)
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(center + point * scale)
	if transformed.size() >= 3:
		draw_colored_polygon(transformed, color)


func _draw_mesh_at(
	mesh: Mesh,
	center: Vector2,
	mesh_scale: Vector2,
	rotation: float,
	modulate: Color
) -> void:
	if mesh == null:
		return
	if mesh not in _retained_draw_meshes:
		# Canvas draw commands execute after _draw returns, so sheet-local
		# runtime meshes must remain strongly referenced until capture.
		_retained_draw_meshes.append(mesh)
	draw_mesh(
		mesh,
		_white_texture,
		Transform2D(rotation, mesh_scale, 0.0, center),
		modulate
	)


func _draw_regular_polygon(
	center: Vector2,
	radius: float,
	sides: int,
	color: Color,
	rotation: float = 0.0
) -> void:
	var points := PackedVector2Array()
	for index in sides:
		points.append(
			center
			+ Vector2.RIGHT.rotated(
				rotation + TAU * float(index) / float(sides)
			) * radius
		)
	draw_colored_polygon(points, color)


func _draw_star(
	center: Vector2,
	outer_radius: float,
	inner_radius: float,
	points_count: int,
	color: Color
) -> void:
	var points := PackedVector2Array()
	for index in points_count * 2:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		points.append(
			center
			+ Vector2.RIGHT.rotated(
				-PI * 0.5 + TAU * float(index) / float(points_count * 2)
			) * radius
		)
	draw_colored_polygon(points, color)


func _draw_chevron(
	center: Vector2,
	direction: Vector2,
	length: float,
	color: Color,
	width: float
) -> void:
	var side := direction.rotated(PI * 0.5)
	var rear := center - direction * length * 0.5
	var front := center + direction * length * 0.5
	var points := PackedVector2Array([
		rear + side * width,
		center + side * width,
		front,
		center - side * width,
		rear - side * width,
		center - direction * length * 0.12,
	])
	draw_colored_polygon(points, color)


func _draw_measure(from: Vector2, to: Vector2, text: String) -> void:
	draw_line(from, to, Art.SYSTEM, 1.0)
	draw_line(from - Vector2(0.0, 8.0), from + Vector2(0.0, 8.0), Art.SYSTEM, 1.0)
	draw_line(to - Vector2(0.0, 8.0), to + Vector2(0.0, 8.0), Art.SYSTEM, 1.0)
	_label((from + to) * 0.5 - Vector2(150.0, 12.0), text, 13, Art.TEXT_MUTED)


func _draw_button(rect: Rect2, text: String, accent: Color, filled: bool) -> void:
	draw_rect(rect, accent if filled else Art.SURFACE)
	draw_rect(rect, accent, false, 1.0)
	if not filled:
		draw_rect(Rect2(rect.position, Vector2(3.0, rect.size.y)), accent)
	_label(
		rect.position + Vector2(22.0, rect.size.y * 0.64),
		text,
		15,
		Art.SPACE_BLACK if filled else Art.TEXT_PRIMARY
	)


func _draw_checkbox(rect: Rect2, text: String) -> void:
	_draw_panel(rect, Art.SURFACE, Art.LINE, Color.TRANSPARENT)
	var box := Rect2(rect.position + Vector2(18.0, 14.0), Vector2(28.0, 28.0))
	draw_rect(box, Art.SYSTEM, false, 2.0)
	draw_line(box.position + Vector2(6.0, 14.0), box.position + Vector2(12.0, 21.0), Art.SYSTEM, 3.0)
	draw_line(box.position + Vector2(12.0, 21.0), box.position + Vector2(23.0, 7.0), Art.SYSTEM, 3.0)
	_label(rect.position + Vector2(64.0, 36.0), text, 16, Art.TEXT_PRIMARY)


func _draw_check(center: Vector2, checked: bool) -> void:
	_draw_regular_polygon(center, 16.0, 4, Art.SUPPORT if checked else Art.DANGER, PI / 4.0)
	if checked:
		draw_line(center + Vector2(-7.0, 0.0), center + Vector2(-1.0, 7.0), Art.SPACE_BLACK, 3.0)
		draw_line(center + Vector2(-1.0, 7.0), center + Vector2(9.0, -7.0), Art.SPACE_BLACK, 3.0)


func _role_color(role: StringName) -> Color:
	if role in [&"support_structure", &"shield", &"repair"]:
		return Art.SUPPORT
	if role in [&"command", &"carrier", &"boss", &"boss_module"]:
		return Art.BOSS_COMMAND
	return Art.DANGER


func _semantic_color(role: StringName) -> Color:
	return Color(Art.required_color_roles().get(String(role), Art.TEXT_PRIMARY))


func _footer(text: String) -> void:
	_label(Vector2(72.0, 1082.0), text, 15, Art.TEXT_MUTED)


func _label(position: Vector2, text: String, font_size: int, color: Color) -> void:
	if _font == null:
		return
	draw_string(
		_font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)
