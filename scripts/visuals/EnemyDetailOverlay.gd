class_name EnemyDetailOverlay
extends Node2D

const INK := Color("182126")
const BONE := Color("e7e5d4")
const STAGE_ACCENTS := {
	&"ruin_approach": Color("98b66f"),
	&"flooded_works": Color("68c8c3"),
	&"broken_sanctum": Color("d8aa52"),
}

var _enemy: Node
var _archetype_id: StringName
var _variant_id: StringName
var _stage_id: StringName
var _animation_time: float = 0.0


func configure(enemy: Node, archetype_id: StringName, variant_id: StringName, stage_id: StringName) -> void:
	_enemy = enemy
	_archetype_id = archetype_id
	_variant_id = variant_id
	_stage_id = stage_id
	queue_redraw()


func get_visual_contract() -> Dictionary:
	return {
		"archetype_id": String(_archetype_id),
		"variant_id": String(_variant_id),
		"stage_id": String(_stage_id),
		"accent": _accent(),
	}


func _process(delta: float) -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		return
	_animation_time += maxf(delta, 0.0)
	visible = bool(_enemy.get("visible"))
	if not visible:
		return
	var direction := -1
	if _enemy.has_method("get_facing_direction"):
		direction = int(_enemy.call("get_facing_direction"))
	scale.x = float(direction if direction != 0 else -1)
	var velocity_value: Variant = _enemy.get("velocity")
	var velocity := velocity_value as Vector2 if velocity_value is Vector2 else Vector2.ZERO
	var grounded := bool(_enemy.call("is_on_floor")) if _enemy.has_method("is_on_floor") else true
	position.y = sin(_animation_time * 11.0) * 1.25 if grounded and absf(velocity.x) > 12.0 else 0.0
	rotation = clampf(velocity.x / 1800.0, -0.055, 0.055)
	queue_redraw()


func _draw() -> void:
	var accent := _accent()
	match _archetype_id:
		&"charger":
			_draw_charger(accent)
		&"shooter":
			_draw_shooter(accent)
		&"leaper":
			_draw_leaper(accent)
		&"shield_guard":
			_draw_shield_guard(accent)
		&"sentry":
			_draw_sentry(accent)
		&"summon_node":
			_draw_summon_node(accent)
		&"small_slime":
			_draw_small_slime(accent)
		_:
			_draw_walker(accent)
	_draw_variant_marks(accent)


func _draw_walker(accent: Color) -> void:
	draw_line(Vector2(-13, -37), Vector2(14, -37), INK, 3.0)
	draw_circle(Vector2(9, -29), 3.4, accent)
	draw_circle(Vector2(10, -29), 1.2, BONE)
	draw_line(Vector2(-13, -3), Vector2(-15, 4), INK, 5.0)
	draw_line(Vector2(12, -3), Vector2(15, 4), INK, 5.0)


func _draw_charger(accent: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(18, -36), Vector2(43, -29), Vector2(20, -20),
	]), accent)
	draw_line(Vector2(-18, -33), Vector2(18, -33), INK, 5.0)
	draw_circle(Vector2(12, -24), 3.5, BONE)
	draw_line(Vector2(-18, -4), Vector2(-21, 4), INK, 7.0)
	draw_line(Vector2(14, -4), Vector2(19, 4), INK, 7.0)


func _draw_shooter(accent: Color) -> void:
	draw_arc(Vector2(0, -31), 15.0, PI, TAU, 16, INK, 4.0)
	draw_circle(Vector2(8, -30), 3.2, accent)
	draw_rect(Rect2(-22, -27, 7, 20), Color(INK, 0.9))
	draw_line(Vector2(15, -22), Vector2(34, -22), accent, 3.0)
	draw_line(Vector2(-11, -4), Vector2(-13, 4), INK, 5.0)
	draw_line(Vector2(10, -4), Vector2(13, 4), INK, 5.0)


func _draw_leaper(accent: Color) -> void:
	draw_circle(Vector2(8, -27), 3.4, BONE)
	draw_line(Vector2(-12, -7), Vector2(-27, 4), INK, 7.0)
	draw_line(Vector2(10, -7), Vector2(26, 4), INK, 7.0)
	draw_line(Vector2(-17, -28), Vector2(17, -28), accent, 3.0)


func _draw_shield_guard(accent: Color) -> void:
	draw_rect(Rect2(-15, -42, 29, 8), INK)
	draw_line(Vector2(-9, -38), Vector2(10, -38), accent, 2.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(20, -49), Vector2(37, -43), Vector2(39, -12),
		Vector2(29, 3), Vector2(18, -12),
	]), Color(accent, 0.88))
	draw_line(Vector2(25, -34), Vector2(34, -22), BONE, 3.0)
	draw_line(Vector2(34, -34), Vector2(25, -22), BONE, 3.0)


func _draw_sentry(accent: Color) -> void:
	draw_rect(Rect2(-23, -10, 46, 9), INK)
	draw_circle(Vector2(10, -28), 7.0, accent)
	draw_circle(Vector2(10, -28), 3.0, BONE)
	draw_line(Vector2(-15, -35), Vector2(16, -35), INK, 4.0)
	draw_circle(Vector2(-14, -20), 2.3, BONE)


func _draw_summon_node(accent: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -50), Vector2(13, -28), Vector2(0, -8), Vector2(-13, -28),
	]), Color(accent, 0.9))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -42), Vector2(7, -28), Vector2(0, -16), Vector2(-7, -28),
	]), BONE)
	draw_line(Vector2(-21, -4), Vector2(21, -4), INK, 6.0)


func _draw_small_slime(accent: Color) -> void:
	draw_circle(Vector2(-8, -22), 3.0, INK)
	draw_circle(Vector2(8, -22), 3.0, INK)
	draw_circle(Vector2(-7, -23), 1.0, BONE)
	draw_circle(Vector2(9, -23), 1.0, BONE)
	draw_arc(Vector2(0, -14), 6.0, 0.15, PI - 0.15, 8, accent, 2.0)


func _draw_variant_marks(accent: Color) -> void:
	var stripe_count := absi(String(_variant_id).hash()) % 3 + 1
	for index in stripe_count:
		var y := -18.0 + float(index) * 5.0
		draw_line(Vector2(-8, y), Vector2(8, y), Color(accent, 0.72), 1.5)


func _accent() -> Color:
	return STAGE_ACCENTS.get(_stage_id, Color("d6a44a"))
