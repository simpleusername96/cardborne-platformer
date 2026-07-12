class_name ChestInteractable
extends StageRewardInteractable

var _pending_request_id: StringName
var _pending_player: Node
var _optional_claim_published: bool = false
var _signal_bus: Node


func _init() -> void:
	reward_role = &"cache_reward"
	claim_prompt_text = "Open chest"
	visual_size = Vector2(58.0, 38.0)
	visual_color = Color("d49a4b")


func _ready() -> void:
	super._ready()
	_signal_bus = get_node_or_null("/root/SignalBus")
	if _signal_bus != null:
		_signal_bus.connect("reward_preview_replacement_committed", _on_replacement_committed)


func _exit_tree() -> void:
	if (
		_signal_bus != null
		and _signal_bus.is_connected("reward_preview_replacement_committed", _on_replacement_committed)
	):
		_signal_bus.disconnect("reward_preview_replacement_committed", _on_replacement_committed)


func interact(player: Node) -> void:
	if not interaction_enabled or is_claimed():
		return
	var transaction := _resolve_reward_transaction()
	if transaction == null:
		return
	var optional_route := bool(_claim_context.get("optional_route", false))
	var reward_target := _get_reward_target()
	if optional_route and reward_target.has_method("begin_optional_chest_choice"):
		_pending_request_id = StringName(_claim_context.get("request_id", transaction.id))
		_pending_player = player
		set_interaction_enabled(false)
		var choice_context: Dictionary = {}
		if reward_target.has_method("get_reward_resolution_context"):
			choice_context = reward_target.call("get_reward_resolution_context")
		choice_context.merge(_claim_context, true)
		var begin_result: Dictionary = reward_target.call(
			"begin_optional_chest_choice",
			transaction,
			choice_context
		)
		if not bool(begin_result.get("ok", false)):
			_pending_request_id = &""
			_pending_player = null
			set_interaction_enabled(true)
			if _signal_bus != null:
				_signal_bus.emit_signal(
					"status_message_changed",
					String(begin_result.get("message", "Treasure choice is unavailable."))
				)
			return
		if bool(begin_result.get("pending", false)):
			return
		_pending_request_id = &""
		_pending_player = null
		set_interaction_enabled(true)
		var fallback_message := String(begin_result.get("message", ""))
		if not fallback_message.is_empty() and _signal_bus != null:
			_signal_bus.emit_signal("status_message_changed", fallback_message)
	if _apply_resolved_reward(transaction, player) and optional_route:
		_publish_optional_claim()


func _on_replacement_committed(result: Dictionary) -> void:
	if (
		_pending_request_id == &""
		or StringName(result.get("request_id", &"")) != _pending_request_id
	):
		return
	if bool(result.get("cancelled", false)):
		_pending_request_id = &""
		_pending_player = null
		set_interaction_enabled(true)
		return
	if not bool(result.get("ok", false)):
		return
	_settle_claim_context(result, _pending_player)
	_publish_optional_claim()
	_pending_request_id = &""
	_pending_player = null


func _publish_optional_claim() -> void:
	if _optional_claim_published or not bool(_claim_context.get("optional_route", false)):
		return
	_optional_claim_published = true
	if _signal_bus != null:
		_signal_bus.emit_signal("optional_route_chest_claimed", get_last_claim_context())


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
