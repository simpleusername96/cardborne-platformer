class_name FloodedWorksRoomSkin
extends RefCounted

const REPRESENTATIVE_ROOM_ID := &"fw_poison_timing"
const TEXTURE_PATHS := {
	"layer_1_320x100": "res://art/world/flooded_works/terrain/solid_320x100.png",
	"layer_1_240x100": "res://art/world/flooded_works/terrain/solid_240x100.png",
	"layer_1_240x140": "res://art/world/flooded_works/terrain/solid_240x140.png",
	"layer_1_240x180": "res://art/world/flooded_works/terrain/solid_240x180.png",
	"layer_2_720x12": "res://art/world/flooded_works/terrain/oneway_720x12.png",
}


static func apply(
	room_hosts: Dictionary,
	room_id: StringName = REPRESENTATIVE_ROOM_ID
) -> Dictionary:
	var room := room_hosts.get(String(room_id)) as Node2D
	if room == null:
		return {
			"applied": false,
			"room_id": String(room_id),
			"reason": "representative_room_not_present",
			"surface_count": 0,
			"unique_signatures": [],
		}
	var signatures := {}
	var surface_ids: Array[String] = []
	for candidate in room.find_children("*", "StaticBody2D", true, false):
		var body := candidate as StaticBody2D
		var body_path := String(room.get_path_to(body))
		if not body_path.begins_with("Terrain/") and not body_path.begins_with("OneWay/"):
			continue
		var collision := _rectangle_collision(body)
		if collision == null:
			continue
		var size := (collision.shape as RectangleShape2D).size
		var signature := _signature(body.collision_layer, size)
		var texture_path := String(TEXTURE_PATHS.get(signature, ""))
		if texture_path.is_empty():
			continue
		var texture := load(texture_path) as Texture2D
		if texture == null:
			continue
		_hide_authored_visuals(body)
		var sprite := body.get_node_or_null("ProductionTerrainVisual") as Sprite2D
		if sprite == null:
			sprite = Sprite2D.new()
			sprite.name = "ProductionTerrainVisual"
			sprite.centered = false
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			body.add_child(sprite)
		sprite.texture = texture
		if body.collision_layer == 2:
			sprite.position = Vector2(-size.x * 0.5, -16.0)
		else:
			sprite.position = Vector2(
				-size.x * 0.5,
				collision.position.y - size.y * 0.5
			)
		sprite.set_meta("terrain_signature", signature)
		signatures[signature] = true
		surface_ids.append(String(body.get_meta("surface_id", body.name)))
	var unique_signatures := signatures.keys()
	unique_signatures.sort()
	surface_ids.sort()
	return {
		"applied": surface_ids.size() == 6 and unique_signatures.size() == 5,
		"room_id": String(room_id),
		"surface_count": surface_ids.size(),
		"surface_ids": surface_ids,
		"unique_signatures": unique_signatures,
		"unique_signature_count": unique_signatures.size(),
		"geometry_mutated": false,
	}


static func _rectangle_collision(body: StaticBody2D) -> CollisionShape2D:
	for child in body.find_children("*", "CollisionShape2D", true, false):
		var collision := child as CollisionShape2D
		if collision.shape is RectangleShape2D:
			return collision
	return null


static func _hide_authored_visuals(body: StaticBody2D) -> void:
	for child in body.find_children("*", "Polygon2D", true, false):
		(child as Polygon2D).visible = false
	for child in body.find_children("*", "Line2D", true, false):
		(child as Line2D).visible = false


static func _signature(collision_layer: int, size: Vector2) -> String:
	return "layer_%d_%dx%d" % [collision_layer, roundi(size.x), roundi(size.y)]
