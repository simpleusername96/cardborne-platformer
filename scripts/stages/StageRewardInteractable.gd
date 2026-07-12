class_name StageRewardInteractable
extends Interactable

signal claimed(context: Dictionary)

@export var reward_role: StringName = &"generic_reward"
@export var reward_table_id: StringName
@export var transaction_id: StringName
@export var claim_prompt_text: String = "Claim reward"
@export var visual_size: Vector2 = Vector2(48.0, 34.0)
@export var visual_color: Color = Color("d4a33f")

var _settled: bool = false
var _visual: Polygon2D
var _reward_target_override: Node
var _reward_catalog_override: RewardCatalog
var _last_claim_context: Dictionary = {}


func _ready() -> void:
	prompt_text = claim_prompt_text
	collision_layer = 0
	collision_mask = 4
	set_meta("reward_role", reward_role)
	_ensure_shape_and_visual()
	super._ready()


func interact(player: Node) -> void:
	if not interaction_enabled or _settled:
		return
	var reward_target := _get_reward_target()
	var catalog := _get_reward_catalog(reward_target)
	var table := catalog.get_table(reward_table_id) if catalog != null else null
	if reward_target == null or table == null or transaction_id == &"":
		return
	var transaction := RewardService.resolve(
		table,
		transaction_id,
		int(reward_target.get("run_seed"))
	)
	var result := RewardService.apply(transaction, reward_target)
	if not result.applied and not result.duplicate:
		return
	_settled = true
	super.interact(player)
	set_interaction_enabled(false)
	if _visual != null:
		_visual.color = Color(visual_color, 0.28)
	_last_claim_context = result.to_dictionary()
	_last_claim_context["reward_role"] = String(reward_role)
	_last_claim_context["reward_table_id"] = String(reward_table_id)
	claimed.emit(_last_claim_context.duplicate(true))


func configure_reward(
	role: StringName,
	table_id: StringName,
	claim_transaction_id: StringName,
	reward_target: Node = null,
	reward_catalog: RewardCatalog = null
) -> void:
	reward_role = role
	reward_table_id = table_id
	transaction_id = claim_transaction_id
	_reward_target_override = reward_target
	_reward_catalog_override = reward_catalog
	set_meta("reward_role", reward_role)


func is_claimed() -> bool:
	return _settled


func get_last_claim_context() -> Dictionary:
	return _last_claim_context.duplicate(true)


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
		add_child(_visual)
	_visual.color = visual_color
	_visual.polygon = _build_visual_polygon()


func _build_visual_polygon() -> PackedVector2Array:
	var half_width := visual_size.x * 0.5
	return PackedVector2Array([
		Vector2(0.0, -visual_size.y),
		Vector2(half_width, -visual_size.y * 0.58),
		Vector2(half_width * 0.72, 0.0),
		Vector2(-half_width * 0.72, 0.0),
		Vector2(-half_width, -visual_size.y * 0.58),
	])


func _get_reward_target() -> Node:
	if _reward_target_override != null:
		return _reward_target_override
	return get_node_or_null("/root/RunState")


func _get_reward_catalog(reward_target: Node) -> RewardCatalog:
	if _reward_catalog_override != null:
		return _reward_catalog_override
	if reward_target == null:
		return null
	return reward_target.get("reward_catalog") as RewardCatalog
