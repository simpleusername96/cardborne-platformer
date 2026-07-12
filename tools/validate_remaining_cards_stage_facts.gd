extends SceneTree

const HOST_SCRIPT_PATH := "res://scripts/stages/production/ProductionStageHost.gd"

var _failures: Array[String] = []
var _clear_events: Array[Dictionary] = []
var _signal_bus: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_signal_bus = root.get_node_or_null("/root/SignalBus")
	_expect(_signal_bus != null, "SignalBus should be available")
	if _signal_bus == null:
		_finish()
		return
	_signal_bus.connect("required_room_encounter_cleared", _on_room_cleared)
	var host_script := load(HOST_SCRIPT_PATH) as Script
	_expect(
		host_script != null and host_script.can_instantiate(),
		"production stage host should compile and instantiate"
	)
	if host_script == null or not host_script.can_instantiate():
		_finish()
		return
	var host: Node = host_script.new()
	host.set("stage_id", "fixture_stage")
	host.set("_required_room_encounter_ids", {
		"room_a": {"required_a": true},
		"room_b": {"required_b1": true, "required_b2": true},
	})
	host.set("_defeated_required_ids", {
		"required_a": true,
		# This optional encounter is deliberately outside the required-room index.
		"optional_enemy": false,
	})
	host.call("_publish_required_room_clear_if_complete", &"room_a")
	_expect(_clear_events.size() == 1, "an optional enemy should not block required room clear")
	if not _clear_events.is_empty():
		var first := _clear_events[0]
		_expect(first.get("room_id") == &"room_a", "room clear should publish its stable room ID")
		_expect(first.get("stage_id") == &"fixture_stage", "room clear should publish its stage ID")
		_expect(first.get("required_encounter_ids") == ["required_a"], "room clear should list only required encounters")

	host.call("_publish_required_room_clear_if_complete", &"room_a")
	_expect(_clear_events.size() == 1, "room clear should publish once")
	host.set("_defeated_required_ids", {"required_a": true, "required_b1": true})
	host.call("_publish_required_room_clear_if_complete", &"room_b")
	_expect(_clear_events.size() == 1, "a room should wait for every required encounter")
	host.set("_defeated_required_ids", {
		"required_a": true,
		"required_b1": true,
		"required_b2": true,
	})
	host.call("_publish_required_room_clear_if_complete", &"room_b")
	_expect(_clear_events.size() == 2, "a room should clear after its final required encounter")
	if _clear_events.size() == 2:
		_expect(
			_clear_events[1].get("required_encounter_ids") == ["required_b1", "required_b2"],
			"required encounter IDs should be stable and sorted"
		)
	host.free()
	_finish()


func _on_room_cleared(context: Dictionary) -> void:
	_clear_events.append(context.duplicate(true))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _signal_bus != null and _signal_bus.is_connected("required_room_encounter_cleared", _on_room_cleared):
		_signal_bus.disconnect("required_room_encounter_cleared", _on_room_cleared)
	if _failures.is_empty():
		print("REMAINING_CARDS_STAGE_FACTS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
