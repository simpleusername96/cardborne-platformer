class_name ExitPortal
extends Interactable


func interact(player: Node) -> void:
	if not interaction_enabled:
		return
	super.interact(player)
	var active_stage := get_tree().get_first_node_in_group("active_stage")
	if active_stage != null and active_stage.has_method("complete_stage"):
		active_stage.complete_stage()
