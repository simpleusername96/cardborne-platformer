extends SceneTree

const StageUI = preload("res://scripts/ui/vehicle_stage_ui.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var ui := StageUI.new()
	get_root().add_child(ui)
	await process_frame
	for width in [960.0, 1280.0, 1920.0]:
		var contract := ui.debug_ui_contract(width)
		_expect(Vector2(contract["action_rail_size"]) == Vector2(154.0, 34.0), "action rail size is fixed at %d" % width)
		_expect(Vector2(contract["action_rail_position"]) == Vector2(18.0, 76.0), "action rail stays below hull at %d" % width)
		_expect(bool(contract["action_rail_icon_only"]), "action rail contains icons only at %d" % width)
		_expect(bool(contract["top_clusters_do_not_overlap"]), "top clusters do not overlap at %d" % width)
		_expect(bool(contract["central_safe_clear"]), "central play space remains clear at %d" % width)
		var minimap_size := Vector2(contract["minimap_size"])
		_expect(minimap_size.x >= 160.0 and minimap_size.y >= 98.0, "minimap keeps tactical area at %d" % width)
	ui.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_STAGE_UI_LAYOUT_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
