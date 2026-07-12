class_name MaterialNode
extends StageRewardInteractable


func _init() -> void:
	reward_role = &"material_node"
	claim_prompt_text = "Extract material"
	visual_size = Vector2(44.0, 54.0)
	visual_color = Color("55c6a9")


func _build_visual_polygon() -> PackedVector2Array:
	var half_width := visual_size.x * 0.5
	return PackedVector2Array([
		Vector2(0.0, -visual_size.y),
		Vector2(half_width, -visual_size.y * 0.54),
		Vector2(half_width * 0.58, 0.0),
		Vector2(-half_width * 0.58, 0.0),
		Vector2(-half_width, -visual_size.y * 0.54),
	])
