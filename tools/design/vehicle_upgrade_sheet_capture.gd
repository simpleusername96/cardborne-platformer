extends Node

## Renders a deterministic PNG design sheet from the production player mesh.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const OUTPUT_PATH := "res://docs/design/vehicle-hud-upgrade-direction/03-runtime-vehicle-upgrade-sheet.png"
const SHEET_SIZE := Vector2i(1800, 1200)
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
	_label(canvas, "현재 기체 기반 업그레이드 시각 시트", Vector2(64, 34), 36, Art.INK)
	_label(
		canvas,
		"현재 player_mesh() 유지 · 부착 파츠만 단계적으로 추가 · 속성은 아이콘으로 표시",
		Vector2(66, 86),
		20,
		Art.INK_MUTED
	)

	_section(canvas, "기체", 148)
	var chassis_positions := [180.0, 420.0, 660.0, 900.0, 1140.0, 1380.0, 1620.0]
	var chassis_labels := ["기본", "장갑 1", "장갑 2", "장갑 3", "속도 1", "속도 2", "속도 3"]
	for index in chassis_positions.size():
		var center := Vector2(chassis_positions[index], 255)
		_ship(canvas, center)
		if index in [1, 2, 3]:
			_armor(canvas, center, index)
		elif index in [4, 5, 6]:
			_thrusters(canvas, center, index - 3)
		_caption(canvas, chassis_labels[index], center + Vector2(-90, 78))

	_section(canvas, "기본 공격", 405)
	var primary_positions := [180.0, 420.0, 660.0, 900.0, 1140.0, 1380.0, 1620.0]
	var primary_labels := ["기본", "공격력 1", "공격력 2", "공격력 3", "연사", "분열 포구", "대구경"]
	for index in primary_positions.size():
		var center := Vector2(primary_positions[index], 515)
		_ship(canvas, center)
		match index:
			1, 2, 3:
				_primary_cannon(canvas, center, index)
			4:
				_rapid_chamber(canvas, center)
			5:
				_forked_muzzle(canvas, center)
			6:
				_mass_driver(canvas, center)
		_caption(canvas, primary_labels[index], center + Vector2(-90, 78))

	_section(canvas, "보조 무기", 665)
	var secondary_positions := [210.0, 550.0, 890.0, 1230.0, 1570.0]
	var secondary_labels := ["추적탄 1 → 3", "이온 역장 1 → 3", "궤도 칼날 2 → 4", "후방 지뢰 3 → 5", "호위 드론 1 → 3"]
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


func _ship(canvas: Node2D, center: Vector2, scale_multiplier: float = 1.0) -> void:
	var ship := MeshInstance2D.new()
	ship.mesh = Visuals.player_mesh()
	ship.position = center
	ship.scale = Vector2.ONE * SHIP_SCALE * scale_multiplier
	canvas.add_child(ship)


func _armor(canvas: Node2D, center: Vector2, level: int) -> void:
	var length := 28.0 + level * 5.0
	for sign_value in [-1.0, 1.0]:
		var side := float(sign_value)
		_polygon(canvas, center, PackedVector2Array([
			Vector2(-35, side * 18),
			Vector2(-16, side * (18 + length * 0.28)),
			Vector2(12 + level * 3, side * (15 + length * 0.22)),
			Vector2(20, side * 8),
			Vector2(-14, side * 10),
		]), Art.CERAMIC_GREEN_LIGHT if level < 3 else Art.CERAMIC_GREEN)
	if level >= 2:
		_polygon(canvas, center, PackedVector2Array([
			Vector2(18, -13), Vector2(43, -8), Vector2(49, 0),
			Vector2(43, 8), Vector2(18, 13), Vector2(28, 0),
		]), Art.CERAMIC_GREEN_MID)
	if level >= 3:
		_ring(canvas, center, 23.0, 5.0, Art.IVORY_BRIGHT)


func _thrusters(canvas: Node2D, center: Vector2, level: int) -> void:
	for sign_value in [-1.0, 1.0]:
		var side := float(sign_value)
		_polygon(canvas, center, PackedVector2Array([
			Vector2(-28, side * 18),
			Vector2(-48 - level * 3, side * (25 + level * 2)),
			Vector2(-42, side * 10),
			Vector2(-24, side * 8),
		]), Art.MINT)
		var trail_length := 18.0 + level * 13.0
		_line(
			canvas,
			center + Vector2(-42, side * 18),
			center + Vector2(-42 - trail_length, side * 18),
			4.0 + level,
			Color(Art.MINT, 0.46 + level * 0.12)
		)


func _primary_cannon(canvas: Node2D, center: Vector2, level: int) -> void:
	_polygon(canvas, center, PackedVector2Array([
		Vector2(27, -10 - level * 2),
		Vector2(47 + level * 4, -7 - level),
		Vector2(55 + level * 5, 0),
		Vector2(47 + level * 4, 7 + level),
		Vector2(27, 10 + level * 2),
		Vector2(36, 0),
	]), Art.MUSTARD_DARK)
	for ring_index in level:
		_ring(
			canvas,
			center + Vector2(40 + ring_index * 7, 0),
			7.0 + ring_index * 1.5,
			2.5,
			Art.IVORY_BRIGHT
		)


func _rapid_chamber(canvas: Node2D, center: Vector2) -> void:
	_primary_cannon(canvas, center, 1)
	for index in 3:
		_circle(canvas, center + Vector2(34 + index * 8, -15), 4.0, Art.COBALT_DEEP)


func _forked_muzzle(canvas: Node2D, center: Vector2) -> void:
	for angle in [-0.30, 0.0, 0.30]:
		var direction := Vector2.RIGHT.rotated(angle)
		_line(canvas, center + direction * 25.0, center + direction * 62.0, 8.0, Art.MUSTARD_DARK)
		_circle(canvas, center + direction * 64.0, 6.0, Art.IVORY_BRIGHT)


func _mass_driver(canvas: Node2D, center: Vector2) -> void:
	_primary_cannon(canvas, center, 3)
	_ring(canvas, center + Vector2(62, 0), 15.0, 5.0, Art.COBALT_DEEP)
	_circle(canvas, center + Vector2(104, 0), 13.0, Art.MUSTARD)


func _seeker_pods(canvas: Node2D, center: Vector2, level: int) -> void:
	for sign_value in [-1.0, 1.0]:
		var side := float(sign_value)
		_polygon(canvas, center, PackedVector2Array([
			Vector2(-6, side * 34), Vector2(24, side * 34),
			Vector2(36, side * 27), Vector2(20, side * 22),
			Vector2(-12, side * 25),
		]), Art.CERAMIC_GREEN_MID)
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
	_circle(canvas, drone_position, 8.0, Art.CERAMIC_GREEN)
	for barrel in level:
		_line(
			canvas,
			drone_position + Vector2(12, -6 + barrel * 6),
			drone_position + Vector2(34 + barrel * 3, -6 + barrel * 6),
			4.0,
			Art.MUSTARD
		)


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
