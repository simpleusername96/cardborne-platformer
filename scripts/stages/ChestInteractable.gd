class_name ChestInteractable
extends StageRewardInteractable


func _init() -> void:
	reward_role = &"cache_reward"
	claim_prompt_text = "Open chest"
	visual_size = Vector2(58.0, 38.0)
	visual_color = Color("d49a4b")


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
