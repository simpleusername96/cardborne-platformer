class_name MerchantInteractable
extends Interactable

@export var merchant_id: StringName = &"intermission_merchant"
@export var heading: String = "TRAVELING MERCHANT"


func _ready() -> void:
	prompt_text = "Trade"
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
		bus.emit_signal("merchant_requested", {
			"merchant_id": String(merchant_id),
			"heading": heading,
		})


func _ensure_shape_and_visual() -> void:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(76.0, 110.0)
	collision.position = Vector2(0.0, -52.0)
	collision.shape = rectangle
	add_child(collision)

	var body := Polygon2D.new()
	body.name = "Visual"
	body.color = Color("4f8f82")
	body.polygon = PackedVector2Array([
		Vector2(-28.0, 0.0), Vector2(-24.0, -72.0), Vector2(0.0, -96.0),
		Vector2(24.0, -72.0), Vector2(28.0, 0.0),
	])
	add_child(body)

	var pack := Polygon2D.new()
	pack.name = "Pack"
	pack.position = Vector2(28.0, -42.0)
	pack.color = Color("b9824b")
	pack.polygon = PackedVector2Array([
		Vector2(-12.0, -24.0), Vector2(18.0, -18.0),
		Vector2(18.0, 24.0), Vector2(-12.0, 20.0),
	])
	add_child(pack)
