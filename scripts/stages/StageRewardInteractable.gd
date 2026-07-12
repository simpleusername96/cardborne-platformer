class_name StageRewardInteractable
extends Interactable

@export var reward_table_id: StringName
@export var transaction_id: StringName
@export var visual_size: Vector2 = Vector2(48.0, 34.0)
@export var visual_color: Color = Color("d4a33f")

var _settled: bool = false
var _visual: Polygon2D


func _ready() -> void:
	prompt_text = "Claim reward"
	collision_layer = 0
	collision_mask = 4
	_ensure_shape_and_visual()
	super._ready()


func interact(player: Node) -> void:
	if not interaction_enabled or _settled:
		return
	var table := RunState.reward_catalog.get_table(reward_table_id)
	if table == null or transaction_id == &"":
		SignalBus.status_message_changed.emit("Reward unavailable")
		return
	var transaction := RewardService.resolve(table, transaction_id, RunState.run_seed)
	var result := RewardService.apply(transaction, RunState)
	if not result.applied and not result.duplicate:
		SignalBus.status_message_changed.emit(result.message)
		return
	_settled = true
	super.interact(player)
	set_interaction_enabled(false)
	if _visual != null:
		_visual.color = Color(visual_color, 0.28)
	SignalBus.status_message_changed.emit("Reward claimed")


func _ensure_shape_and_visual() -> void:
	if get_node_or_null("CollisionShape2D") == null:
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(visual_size.x + 24.0, visual_size.y + 30.0)
		collision.position = Vector2(0.0, -visual_size.y * 0.5)
		collision.shape = rectangle
		add_child(collision)
	_visual = get_node_or_null("Visual") as Polygon2D
	if _visual == null:
		_visual = Polygon2D.new()
		_visual.name = "Visual"
		_visual.color = visual_color
		_visual.polygon = PackedVector2Array([
			Vector2(-visual_size.x * 0.5, -visual_size.y),
			Vector2(visual_size.x * 0.5, -visual_size.y),
			Vector2(visual_size.x * 0.5, 0.0),
			Vector2(-visual_size.x * 0.5, 0.0),
		])
		add_child(_visual)
