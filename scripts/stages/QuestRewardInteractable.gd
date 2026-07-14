class_name QuestRewardInteractable
extends StageRewardInteractable

var _required_room_id: StringName
var _signal_bus: Node


func _init() -> void:
	reward_role = &"npc_reward"
	claim_prompt_text = "Collect request reward"
	disabled_prompt_text = "Defeat the nearby enemies"
	visual_size = Vector2(42.0, 58.0)
	visual_color = Color("78a66a")
	interaction_enabled = false


func _ready() -> void:
	_required_room_id = StringName(get_claim_context().get("room_id", &""))
	super._ready()
	set_interaction_enabled(false)
	_signal_bus = get_node_or_null("/root/SignalBus")
	if _signal_bus != null and _signal_bus.has_signal("required_room_encounter_cleared"):
		_signal_bus.connect("required_room_encounter_cleared", _on_required_room_cleared)
	var stage := get_tree().get_first_node_in_group("active_stage")
	if (
		stage != null
		and stage.has_method("is_required_room_cleared")
		and bool(stage.call("is_required_room_cleared", _required_room_id))
	):
		set_interaction_enabled(true)


func _exit_tree() -> void:
	if (
		_signal_bus != null
		and _signal_bus.is_connected("required_room_encounter_cleared", _on_required_room_cleared)
	):
		_signal_bus.disconnect("required_room_encounter_cleared", _on_required_room_cleared)


func _on_required_room_cleared(context: Dictionary) -> void:
	if StringName(context.get("room_id", &"")) != _required_room_id:
		return
	set_interaction_enabled(true)


func _build_visual_polygon() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0.0, -58.0),
		Vector2(18.0, -42.0),
		Vector2(15.0, -8.0),
		Vector2(25.0, 0.0),
		Vector2(-25.0, 0.0),
		Vector2(-15.0, -8.0),
		Vector2(-18.0, -42.0),
	])
