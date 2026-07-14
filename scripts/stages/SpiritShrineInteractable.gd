class_name SpiritShrineInteractable
extends StageRewardInteractable


func _init() -> void:
	reward_role = &"spirit_shrine"
	claim_prompt_text = "Commune with shrine"
	visual_size = Vector2(54.0, 66.0)
	visual_color = Color("70bfd0")


func _build_visual_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -66.0),
		Vector2(22.0, -38.0),
		Vector2(12.0, -14.0),
		Vector2(27.0, 0.0),
		Vector2(-27.0, 0.0),
		Vector2(-12.0, -14.0),
		Vector2(-22.0, -38.0),
	])
