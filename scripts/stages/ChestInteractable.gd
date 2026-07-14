class_name ChestInteractable
extends StageRewardInteractable

@onready var _lid_visual: Polygon2D = get_node_or_null("LidVisual") as Polygon2D


func _init() -> void:
	reward_role = &"cache_reward"
	claim_prompt_text = "Open chest"
	visual_size = Vector2(58.0, 38.0)
	visual_color = Color("d49a4b")


func interact(player: Node) -> void:
	if not interaction_enabled or is_claimed():
		return
	var transaction := _resolve_reward_transaction()
	if transaction == null:
		return
	_apply_resolved_reward(transaction, player)


func _build_visual_polygon() -> PackedVector2Array:
	var half_width := visual_size.x * 0.5
	return PackedVector2Array([
		Vector2(-half_width * 0.78, -visual_size.y),
		Vector2(half_width * 0.78, -visual_size.y),
		Vector2(half_width, -visual_size.y * 0.72),
		Vector2(half_width, 0.0),
		Vector2(-half_width, 0.0),
		Vector2(-half_width, -visual_size.y * 0.72),
	])


func _apply_claimed_visual() -> void:
	super._apply_claimed_visual()
	if _visual != null:
		var half_width := visual_size.x * 0.5
		_visual.polygon = PackedVector2Array([
			Vector2(-half_width, -visual_size.y * 0.62),
			Vector2(half_width, -visual_size.y * 0.62),
			Vector2(half_width, 0.0),
			Vector2(-half_width, 0.0),
		])
	if _lid_visual != null:
		var half_width := visual_size.x * 0.5
		_lid_visual.visible = true
		_lid_visual.color = Color(visual_color, 0.42)
		_lid_visual.position = Vector2(-2.0, -visual_size.y * 0.64)
		_lid_visual.rotation = -0.28
		_lid_visual.polygon = PackedVector2Array([
			Vector2(-half_width, -visual_size.y * 0.24),
			Vector2(half_width, -visual_size.y * 0.24),
			Vector2(half_width * 0.84, 0.0),
			Vector2(-half_width * 0.84, 0.0),
		])
