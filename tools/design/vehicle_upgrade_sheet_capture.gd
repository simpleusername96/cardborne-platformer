extends Node

## Renders the locked HUD/upgrade direction from the production player mesh.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const OUTPUT_PATH := "res://docs/design/vehicle-hud-upgrade-direction/03-runtime-vehicle-upgrade-sheet.png"
const SHEET_SIZE := Vector2i(1800, 1500)
const SHIP_SCALE := 58.0
const FONT := preload("res://art/ui/production/fonts/NotoSansKR-Variable.ttf")


func _ready() -> void:
	var viewport := SubViewport.new()
	viewport.size = SHEET_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)

	var canvas := Node2D.new()
	viewport.add_child(canvas)
	_build_sheet(canvas)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var output_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	var error := image.save_png(output_path)
	if error == OK:
		print("VEHICLE_UPGRADE_SHEET_SAVED %s" % output_path)
	else:
		push_error("Could not save vehicle upgrade sheet: %s" % error_string(error))
	get_tree().quit(error)


func _build_sheet(canvas: Node2D) -> void:
	_rect(canvas, Rect2(Vector2.ZERO, SHEET_SIZE), Art.IVORY_BRIGHT)
	_label(canvas, "기체 · HUD · 동적 장판 최종 시각 계약", Vector2(64, 34), 36, Art.INK)
	_label(
		canvas,
		"실제 분리형 기체 메시 · 보이는 수량은 수량으로 · 보이지 않는 영구 강화만 색 농도로",
		Vector2(66, 86),
		20,
		Art.INK_MUTED
	)

	_section(canvas, "기체", 148)
	var chassis_positions := [180.0, 420.0, 660.0, 900.0, 1140.0, 1380.0, 1620.0]
	var chassis_labels := ["기본", "내구 1", "내구 2", "내구 3", "엔진 1", "엔진 2", "엔진 3"]
	for index in chassis_positions.size():
		var center := Vector2(chassis_positions[index], 255)
		_ship(canvas, center, 1.0, index if index in [1, 2, 3] else 0)
		if index in [4, 5, 6]:
			_thrusters(canvas, center, index - 3)
		_caption(canvas, chassis_labels[index], center + Vector2(-90, 78))

	_section(canvas, "기본 공격", 405)
	var primary_positions := [270.0, 630.0, 990.0, 1350.0]
	var primary_labels := ["기본 포구", "공격력 1", "공격력 2", "공격력 3"]
	for index in primary_positions.size():
		var center := Vector2(primary_positions[index], 515)
		_ship(canvas, center)
		_primary_cannon(canvas, center, index)
		_caption(canvas, primary_labels[index], center + Vector2(-110, 78), 220)
	_label(
		canvas,
		"연사 · 다중탄 · 관통은 실제 발사 동작 자체로 보이므로 기체에 별도 표식을 붙이지 않음",
		Vector2(470, 642),
		14,
		Art.INK_MUTED,
		860,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_section(canvas, "보조 무기", 665)
	var secondary_positions := [210.0, 550.0, 890.0, 1230.0, 1570.0]
	var secondary_labels := ["추적탄 수량 1 → 3", "이온 역장 반경 1 → 3", "궤도 칼날 수량 2 → 4", "후방 지뢰 수량 3 → 5", "드론 화력 1 → 3"]
	for index in secondary_positions.size():
		var center := Vector2(secondary_positions[index], 780)
		_ship(canvas, center, 0.86)
		match index:
			0:
				_seeker_pods(canvas, center, 3)
			1:
				_ion_field(canvas, center, 3)
			2:
				_orbit_blades(canvas, center, 4)
			3:
				_wake_mines(canvas, center, 5)
			4:
				_escort_drone(canvas, center, 3)
		_caption(canvas, secondary_labels[index], center + Vector2(-130, 90), 260)
	_label(
		canvas,
		"수량·반경으로 단계가 보이는 보조무기는 색을 더 진하게 만들지 않음",
		Vector2(470, 692),
		14,
		Art.INK_MUTED,
		860,
		HORIZONTAL_ALIGNMENT_CENTER
	)

	_section(canvas, "속성 표시와 탄환", 925)
	var element_center := Vector2(390, 1055)
	_ship(canvas, element_center, 0.82)
	_element_badge(canvas, element_center + Vector2(-100, -18), &"burn")
	_element_badge(canvas, element_center + Vector2(-100, 44), &"poison")
	_element_badge(canvas, element_center + Vector2(100, 12), &"chill")
	_caption(canvas, "화상 · 독 · 빙결은 기체 옆 아이콘", element_center + Vector2(-190, 76), 380)

	var projectile_origin := Vector2(930, 1035)
	for index in 4:
		_player_projectile(canvas, projectile_origin + Vector2(index * 135.0, 0))
	_label(canvas, "속성이 겹쳐도 탄환 색은 고정", Vector2(890, 1130), 21, Art.INK_MUTED, 600)

	_section(canvas, "동적 장판과 전투 HUD", 1195)
	_dynamic_field_contract(canvas)
	_compact_hud_contract(canvas)


func _ship(
	canvas: Node2D,
	center: Vector2,
	scale_multiplier: float = 1.0,
	hull_tier: int = 0
) -> void:
	var ship := MeshInstance2D.new()
	ship.mesh = Visuals.player_hull_mesh()
	ship.position = center
	ship.scale = Vector2.ONE * SHIP_SCALE * scale_multiplier
	var mixes := [0.0, 0.28, 0.52, 0.72]
	ship.modulate = Art.MUSTARD.lerp(
		Art.MUSTARD_DARK, mixes[clampi(hull_tier, 0, 3)]
	)
	canvas.add_child(ship)


func _thrusters(canvas: Node2D, center: Vector2, level: int) -> void:
	var offsets := [Vector2(-36, 0)]
	if level == 2:
		offsets = [Vector2(-34, -20), Vector2(-34, 20)]
	elif level >= 3:
		offsets = [Vector2(-34, -24), Vector2(-43, 0), Vector2(-34, 24)]
	for offset in offsets:
		var engine := MeshInstance2D.new()
		engine.mesh = Visuals.player_engine_mesh()
		engine.position = center + offset
		engine.scale = Vector2(24.0, 16.0)
		engine.modulate = Art.MUSTARD_DARK
		canvas.add_child(engine)
		_line(
			canvas,
			center + offset + Vector2(-14, 0),
			center + offset + Vector2(-34, 0),
			5.0,
			Color(Art.MINT, 0.72)
		)


func _primary_cannon(canvas: Node2D, center: Vector2, level: int) -> void:
	var cannon := MeshInstance2D.new()
	cannon.mesh = Visuals.player_primary_mesh()
	cannon.position = center + Vector2(18.0, 0.0)
	cannon.scale = Vector2(48.0, 20.0)
	var mixes := [0.0, 0.28, 0.52, 0.72]
	cannon.modulate = Art.MUSTARD.lerp(
		Art.MUSTARD_DARK, mixes[clampi(level, 0, 3)]
	)
	canvas.add_child(cannon)


func _seeker_pods(canvas: Node2D, center: Vector2, level: int) -> void:
	for sign_value in [-1.0, 1.0]:
		var side := float(sign_value)
		_polygon(canvas, center, PackedVector2Array([
			Vector2(-6, side * 34), Vector2(24, side * 34),
			Vector2(36, side * 27), Vector2(20, side * 22),
			Vector2(-12, side * 25),
		]), Art.STRUCTURE_MID)
		for notch in level:
			_circle(canvas, center + Vector2(4 + notch * 9, side * 28), 3.0, Art.MUSTARD)


func _ion_field(canvas: Node2D, center: Vector2, level: int) -> void:
	for ring_index in level:
		_ring(
			canvas,
			center,
			72.0 + ring_index * 12.0,
			4.0,
			Color(Art.MINT, 0.42 + ring_index * 0.18)
		)


func _orbit_blades(canvas: Node2D, center: Vector2, count: int) -> void:
	for index in count:
		var position := center + Vector2.RIGHT.rotated(TAU * float(index) / float(count)) * 92.0
		_diamond(canvas, position, 15.0, Art.MUSTARD)


func _wake_mines(canvas: Node2D, center: Vector2, count: int) -> void:
	for index in count:
		var offset := Vector2(-80.0 - float(index % 3) * 30.0, (float(index / 3) - 0.5) * 38.0)
		_diamond(canvas, center + offset, 12.0, Art.CORAL)
		_circle(canvas, center + offset, 4.0, Art.MUSTARD)


func _escort_drone(canvas: Node2D, center: Vector2, level: int) -> void:
	var drone_position := center + Vector2(-105, -50)
	_diamond(canvas, drone_position, 23.0, Art.MINT_SOFT)
	var core_colors := [Art.MUSTARD, Color("#B97B12"), Art.MUSTARD_DARK]
	_circle(canvas, drone_position, 9.0, core_colors[clampi(level - 1, 0, 2)])
	_line(canvas, drone_position + Vector2(12, 0), drone_position + Vector2(37, 0), 5.0, Art.MUSTARD_DARK)


func _element_badge(canvas: Node2D, center: Vector2, kind: StringName) -> void:
	var color := Art.ATTACK_THERMAL
	if kind == &"poison":
		color = Art.ATTACK_TOXIN
	elif kind == &"chill":
		color = Art.ATTACK_CRYO
	_circle(canvas, center, 24.0, Art.IVORY_BRIGHT)
	_ring(canvas, center, 24.0, 4.0, color)
	if kind == &"burn":
		_polygon(canvas, center, PackedVector2Array([
			Vector2(0, -15), Vector2(10, -2), Vector2(8, 12),
			Vector2(0, 17), Vector2(-10, 9), Vector2(-8, -3),
		]), color)
	elif kind == &"poison":
		_polygon(canvas, center, PackedVector2Array([
			Vector2(-7, -14), Vector2(7, -14), Vector2(5, -5),
			Vector2(13, 10), Vector2(8, 16), Vector2(-8, 16),
			Vector2(-13, 10), Vector2(-5, -5),
		]), color)
		_line(canvas, center + Vector2(-8, 8), center + Vector2(8, 8), 3.0, Art.IVORY_BRIGHT)
	else:
		for angle in [0.0, PI / 3.0, PI * 2.0 / 3.0]:
			var direction := Vector2.RIGHT.rotated(angle)
			_line(canvas, center - direction * 14.0, center + direction * 14.0, 3.0, color)


func _player_projectile(canvas: Node2D, center: Vector2) -> void:
	_line(canvas, center - Vector2(34, 0), center - Vector2(4, 0), 9.0, Color(Art.MUSTARD, 0.55))
	_circle(canvas, center, 11.0, Art.MUSTARD)
	_circle(canvas, center + Vector2(2, 0), 4.0, Art.COBALT_DEEP)


func _dynamic_field_contract(canvas: Node2D) -> void:
	var map_rect := Rect2(64, 1250, 1010, 192)
	_label(
		canvas,
		"4개 슬롯 · 서로 다른 수명 · 재배치는 최소 3초 간격",
		Vector2(210, 1215),
		16,
		Art.INK_MUTED,
		720,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_rect(canvas, map_rect, Color(Art.COBALT_VOID, 0.94))
	_rect(canvas, Rect2(88, 1270, 962, 148), Art.IVORY)
	_support_field(canvas, Vector2(230, 1325), 47.0, Art.MINT, 0.76, "+", "회복 A · 18초")
	_support_field(canvas, Vector2(445, 1350), 47.0, Art.MINT, 0.42, "+", "회복 B · 23초")
	_support_field(canvas, Vector2(700, 1318), 54.0, Art.MUSTARD, 0.58, "»", "강화 A · 12초")
	_support_field(canvas, Vector2(915, 1350), 54.0, Art.MUSTARD, 0.24, "»", "강화 B · 15초")


func _support_field(
	canvas: Node2D,
	center: Vector2,
	radius: float,
	color: Color,
	ratio: float,
	glyph: String,
	caption: String
) -> void:
	_circle(canvas, center, radius, Color(color, 0.18))
	_ring(canvas, center, radius, 3.0, Color(color, 0.42))
	_arc(canvas, center, radius + 6.0, -PI * 0.5, TAU * ratio, 7.0, color)
	_label(
		canvas,
		glyph,
		center + Vector2(-17, -23),
		31,
		color,
		34,
		HORIZONTAL_ALIGNMENT_CENTER
	)
	_label(
		canvas,
		caption,
		center + Vector2(-68, 18),
		13,
		Art.INK,
		136,
		HORIZONTAL_ALIGNMENT_CENTER
	)


func _compact_hud_contract(canvas: Node2D) -> void:
	var origin := Vector2(1128, 1250)
	_rect(canvas, Rect2(origin, Vector2(608, 192)), Color(Art.COBALT_VOID, 0.94))
	_rect(canvas, Rect2(origin + Vector2(18, 18), Vector2(184, 54)), Color(Art.IVORY_BRIGHT, 0.96))
	_label(canvas, "78 / 100", origin + Vector2(32, 27), 17, Art.INK, 110)
	_rect(canvas, Rect2(origin + Vector2(32, 54), Vector2(150, 8)), Art.IVORY_SHADE)
	_rect(canvas, Rect2(origin + Vector2(32, 54), Vector2(117, 8)), Art.CORAL)
	for index in 4:
		var slot := Rect2(origin + Vector2(18 + index * 40, 80), Vector2(34, 34))
		_rect(canvas, slot, Color(Art.IVORY_BRIGHT, 0.94))
		_ring(canvas, slot.get_center(), 13.0, 3.0, [Art.MUSTARD, Art.MINT, Art.COBALT_ENERGY, Art.ATTACK_ARC][index])
		if index == 0:
			_circle(canvas, slot.get_center(), 5.0, Art.MUSTARD)
		elif index == 1:
			_diamond(canvas, slot.get_center(), 6.0, Art.MINT)
		elif index == 2:
			_polygon(canvas, slot.get_center(), PackedVector2Array([
				Vector2(-7, -8), Vector2(9, 0), Vector2(-7, 8),
			]), Art.COBALT_ENERGY)
		else:
			_draw_terrain_bolt_icon(canvas, slot.get_center(), 8.0, Art.ATTACK_ARC)

	var minimap := Rect2(origin + Vector2(396, 18), Vector2(190, 116))
	_rect(canvas, minimap, Color(Art.COBALT_DEEP, 0.96))
	_rect(canvas, Rect2(minimap.position + Vector2(9, 9), minimap.size - Vector2(18, 18)), Color(Art.IVORY, 0.88))
	_polygon(canvas, minimap.get_center(), PackedVector2Array([
		Vector2(9, 0), Vector2(-6, -6), Vector2(-6, 6),
	]), Art.MUSTARD)
	for marker in [
		{"p":Vector2(20, -25), "r":3.0},
		{"p":Vector2(50, 18), "r":5.0},
		{"p":Vector2(-42, 28), "r":4.0},
	]:
		var marker_position: Vector2 = marker["p"]
		_circle(canvas, minimap.get_center() + marker_position, float(marker["r"]), Art.CORAL)
	_line(canvas, minimap.get_center() + Vector2(50, 18), minimap.get_center() + Vector2(62, 13), 2.0, Art.CORAL)
	_diamond(canvas, minimap.get_center() + Vector2(-63, -28), 5.0, Art.MINT)
	_ring(canvas, minimap.get_center() + Vector2(65, -30), 8.0, 3.0, Art.MUSTARD)
	_arc(canvas, minimap.get_center() + Vector2(65, -30), 11.0, -PI * 0.5, PI * 1.2, 3.0, Art.MUSTARD)
	_label(
		canvas,
		"하단 패널 제거 · 체력 아래 아이콘 레일 · 미니맵: 적 군집/이동, 아이템, 장판",
		origin + Vector2(40, 150),
		14,
		Art.IVORY_BRIGHT,
		530,
		HORIZONTAL_ALIGNMENT_CENTER
	)


func _draw_terrain_bolt_icon(canvas: Node2D, center: Vector2, extent: float, color: Color) -> void:
	_polygon(canvas, center, PackedVector2Array([
		Vector2(-0.18, -1.0) * extent,
		Vector2(0.50, -0.22) * extent,
		Vector2(0.12, -0.18) * extent,
		Vector2(0.35, 1.0) * extent,
		Vector2(-0.50, 0.18) * extent,
		Vector2(-0.12, 0.12) * extent,
	]), color)


func _section(canvas: Node2D, title: String, y: float) -> void:
	_label(canvas, title, Vector2(64, y), 25, Art.MUSTARD_DARK)
	_line(canvas, Vector2(150, y + 18), Vector2(1736, y + 18), 2.0, Color(Art.IVORY_SHADE, 0.9))


func _caption(
	canvas: Node2D,
	text: String,
	position: Vector2,
	width: float = 180.0
) -> void:
	_label(canvas, text, position, 19, Art.INK, width, HORIZONTAL_ALIGNMENT_CENTER)


func _label(
	canvas: Node2D,
	text: String,
	position: Vector2,
	font_size: int,
	color: Color,
	width: float = 900.0,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	var label := Label.new()
	label.position = position
	label.size = Vector2(width, 46)
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	canvas.add_child(label)


func _rect(canvas: Node2D, rect: Rect2, color: Color) -> void:
	var node := Polygon2D.new()
	node.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.end,
		rect.position + Vector2(0, rect.size.y),
	])
	node.color = color
	canvas.add_child(node)


func _polygon(
	canvas: Node2D,
	center: Vector2,
	points: PackedVector2Array,
	color: Color
) -> void:
	var node := Polygon2D.new()
	node.position = center
	node.polygon = points
	node.color = color
	canvas.add_child(node)


func _circle(canvas: Node2D, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / 24.0) * radius)
	_polygon(canvas, center, points, color)


func _ring(
	canvas: Node2D,
	center: Vector2,
	radius: float,
	width: float,
	color: Color
) -> void:
	var line := Line2D.new()
	line.closed = true
	line.width = width
	line.default_color = color
	for index in 40:
		line.add_point(center + Vector2.RIGHT.rotated(TAU * float(index) / 40.0) * radius)
	canvas.add_child(line)


func _arc(
	canvas: Node2D,
	center: Vector2,
	radius: float,
	start_angle: float,
	sweep: float,
	width: float,
	color: Color
) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var segments := maxi(6, ceili(36.0 * absf(sweep) / TAU))
	for index in range(segments + 1):
		var ratio := float(index) / float(segments)
		line.add_point(center + Vector2.RIGHT.rotated(start_angle + sweep * ratio) * radius)
	canvas.add_child(line)


func _line(
	canvas: Node2D,
	from: Vector2,
	to: Vector2,
	width: float,
	color: Color
) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.add_point(from)
	line.add_point(to)
	canvas.add_child(line)


func _diamond(canvas: Node2D, center: Vector2, radius: float, color: Color) -> void:
	_polygon(canvas, center, PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	]), color)
