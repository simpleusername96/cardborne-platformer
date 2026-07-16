extends Node2D

var _terrain_rects: Array[Rect2] = []
var _one_way_rects: Array[Rect2] = []
var _hazard_rects: Array[Rect2] = []
var _player_rects: Array[Rect2] = []


func configure(stage: Node, room: Node2D) -> void:
	top_level = true
	z_index = 90
	_collect_room_geometry(room)
	_collect_runtime_hazards(stage, room)
	_collect_player(stage)
	queue_redraw()


func _draw() -> void:
	for rect in _terrain_rects:
		draw_rect(rect, Color("e0ad4e", 0.16), true)
		draw_rect(rect, Color("e0ad4e", 0.94), false, 2.0)
	for rect in _one_way_rects:
		draw_rect(rect, Color("72c7c2", 0.18), true)
		draw_rect(rect, Color("72c7c2", 0.96), false, 2.0)
	for rect in _hazard_rects:
		draw_rect(rect, Color("d86c82", 0.20), true)
		draw_rect(rect, Color("f08096", 0.98), false, 3.0)
	for rect in _player_rects:
		draw_rect(rect, Color("a8d47b", 0.18), true)
		draw_rect(rect, Color("a8d47b", 0.98), false, 2.0)


func _collect_room_geometry(room: Node2D) -> void:
	for candidate in room.find_children("*", "StaticBody2D", true, false):
		var body := candidate as StaticBody2D
		var path := String(room.get_path_to(body))
		if not path.begins_with("Terrain/") and not path.begins_with("OneWay/"):
			continue
		for child in body.find_children("*", "CollisionShape2D", true, false):
			var collision := child as CollisionShape2D
			if collision.shape is RectangleShape2D:
				var rect := _world_rect(collision, (collision.shape as RectangleShape2D).size)
				if collision.one_way_collision or body.collision_layer == 2:
					_one_way_rects.append(rect)
				else:
					_terrain_rects.append(rect)


func _collect_runtime_hazards(stage: Node, room: Node2D) -> void:
	var room_bounds := Rect2(room.global_position, Vector2(1280.0, 720.0))
	for hazard in stage.get_spawned_hazards():
		if not room_bounds.grow(160.0).has_point(hazard.global_position):
			continue
		for child in hazard.find_children("*", "CollisionShape2D", true, false):
			var collision := child as CollisionShape2D
			if collision.shape is RectangleShape2D:
				_hazard_rects.append(
					_world_rect(collision, (collision.shape as RectangleShape2D).size)
				)


func _collect_player(stage: Node) -> void:
	if stage.player == null:
		return
	for child in stage.player.find_children("*", "CollisionShape2D", true, false):
		var collision := child as CollisionShape2D
		if collision.shape is RectangleShape2D:
			_player_rects.append(
				_world_rect(collision, (collision.shape as RectangleShape2D).size)
			)


func _world_rect(collision: CollisionShape2D, size: Vector2) -> Rect2:
	return Rect2(collision.global_position - size * 0.5, size)
