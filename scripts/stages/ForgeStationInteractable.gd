class_name ForgeStationInteractable
extends Interactable

@export var station_id: StringName = &"intermission_forge"
@export var heading: String = "TRAVELER FORGE"

var _visual: Polygon2D


func _ready() -> void:
	prompt_text = "Use forge"
	collision_layer = 0
	collision_mask = 4
	_ensure_shape_and_visual()
	super._ready()


func interact(player: Node) -> void:
	if not interaction_enabled:
		return
	super.interact(player)
	var bus := get_node_or_null("/root/SignalBus")
	if bus != null:
		bus.emit_signal("forge_requested", {
			"station_id": String(station_id),
			"heading": heading,
		})


func _ensure_shape_and_visual() -> void:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(90.0, 78.0)
	collision.position = Vector2(0.0, -34.0)
	collision.shape = rectangle
	add_child(collision)
	_visual = Polygon2D.new()
	_visual.name = "Visual"
	_visual.color = Color("b97b3d")
	_visual.polygon = PackedVector2Array([
		Vector2(-42.0, -18.0),
		Vector2(34.0, -18.0),
		Vector2(42.0, 0.0),
		Vector2(-36.0, 0.0),
		Vector2(-36.0, -7.0),
		Vector2(-48.0, -7.0),
		Vector2(-48.0, -13.0),
		Vector2(-36.0, -13.0),
	])
	add_child(_visual)
	var ember := Polygon2D.new()
	ember.name = "Ember"
	ember.position = Vector2(20.0, -28.0)
	ember.color = Color("d4a33f")
	ember.polygon = PackedVector2Array([
		Vector2(0.0, -17.0), Vector2(9.0, 0.0), Vector2(-9.0, 0.0),
	])
	add_child(ember)
