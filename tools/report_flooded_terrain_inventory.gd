extends SceneTree

const CATALOG: RoomCatalog = preload(
	"res://data/generation/flooded_works_room_catalog.tres"
)
const REPRESENTATIVE_ROOM_ID := &"fw_poison_timing"
const REPORT_PATH := "res://.codex-runtime/reports/flooded_terrain_inventory.json"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room_reports: Array[Dictionary] = []
	var global_signatures := {}
	var component_ids := {}
	for room_data in CATALOG.rooms:
		if room_data == null or room_data.scene == null:
			_failures.append("Flooded Works catalog contains an unusable room definition.")
			continue
		var room := room_data.scene.instantiate()
		var room_report := _inspect_room(room_data, room)
		room_reports.append(room_report)
		_merge_signatures(global_signatures, room_report)
		for component_id in room_report["hazard_component_ids"]:
			component_ids[String(component_id)] = true
		room.free()

	room_reports.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["room_id"]) < String(b["room_id"])
	)
	var representative := _find_room_report(room_reports, REPRESENTATIVE_ROOM_ID)
	if representative.is_empty():
		_failures.append("Representative room %s was not found." % REPRESENTATIVE_ROOM_ID)
	elif int(representative["unique_signature_count"]) != 5:
		_failures.append(
			"Representative room should derive exactly 5 reusable terrain signatures, got %d."
			% int(representative["unique_signature_count"])
		)

	var global_rows: Array[Dictionary] = []
	var global_keys := global_signatures.keys()
	global_keys.sort()
	for signature in global_keys:
		var row: Dictionary = global_signatures[signature]
		row["rooms"].sort()
		row["surface_ids"].sort()
		global_rows.append(row)
	var sorted_components := component_ids.keys()
	sorted_components.sort()
	var report := {
		"schema_version": 1,
		"stage_id": "flooded_works",
		"catalog_id": String(CATALOG.id),
		"catalog_content_version": CATALOG.content_version,
		"representative_room_id": String(REPRESENTATIVE_ROOM_ID),
		"representative_minimum_chunk_count": int(
			representative.get("unique_signature_count", 0)
		),
		"representative_signatures": representative.get("signatures", []),
		"global_unique_signature_count": global_rows.size(),
		"global_signatures": global_rows,
		"hazard_component_ids": sorted_components,
		"rooms": room_reports,
		"derivation_rule": "collision layer + RectangleShape2D dimensions; duplicate geometry reuses one type",
	}
	_write_report(report)
	print("FLOODED_TERRAIN_INVENTORY %s" % JSON.stringify(report))
	_finish()


func _inspect_room(room_data: RoomTemplateData, room: Node) -> Dictionary:
	var signature_rows := {}
	var surface_count := 0
	for candidate in room.find_children("*", "StaticBody2D", true, false):
		var body := candidate as StaticBody2D
		var path := String(room.get_path_to(body))
		if not path.begins_with("Terrain/") and not path.begins_with("OneWay/"):
			continue
		var shape_node := _rectangle_collision(body)
		if shape_node == null:
			continue
		var rectangle := shape_node.shape as RectangleShape2D
		var signature := _signature(body.collision_layer, rectangle.size)
		if not signature_rows.has(signature):
			signature_rows[signature] = {
				"signature": signature,
				"collision_layer": body.collision_layer,
				"shape_size": _vector2_data(rectangle.size),
				"occurrences": 0,
				"surface_ids": [],
			}
		var row: Dictionary = signature_rows[signature]
		row["occurrences"] = int(row["occurrences"]) + 1
		(row["surface_ids"] as Array).append(String(body.get_meta("surface_id", body.name)))
		surface_count += 1
	var signatures: Array[Dictionary] = []
	var signature_keys := signature_rows.keys()
	signature_keys.sort()
	for signature in signature_keys:
		var row: Dictionary = signature_rows[signature]
		row["surface_ids"].sort()
		signatures.append(row)
	var component_ids := {}
	for anchor in room_data.hazard_anchors:
		if anchor == null:
			continue
		for component_id in anchor.allowed_hazard_ids:
			component_ids[String(component_id)] = true
	var sorted_components := component_ids.keys()
	sorted_components.sort()
	return {
		"room_id": String(room_data.id),
		"scene_path": room_data.scene.resource_path,
		"bounds": _rect2_data(room_data.bounds),
		"surface_count": surface_count,
		"unique_signature_count": signatures.size(),
		"signatures": signatures,
		"hazard_component_ids": sorted_components,
	}


func _rectangle_collision(body: StaticBody2D) -> CollisionShape2D:
	for child in body.find_children("*", "CollisionShape2D", true, false):
		var collision := child as CollisionShape2D
		if collision.shape is RectangleShape2D:
			return collision
	return null


func _merge_signatures(global_signatures: Dictionary, room_report: Dictionary) -> void:
	for room_signature in room_report["signatures"]:
		var signature := String(room_signature["signature"])
		if not global_signatures.has(signature):
			global_signatures[signature] = {
				"signature": signature,
				"collision_layer": room_signature["collision_layer"],
				"shape_size": room_signature["shape_size"],
				"occurrences": 0,
				"rooms": [],
				"surface_ids": [],
			}
		var global_row: Dictionary = global_signatures[signature]
		global_row["occurrences"] += int(room_signature["occurrences"])
		(global_row["rooms"] as Array).append(String(room_report["room_id"]))
		for surface_id in room_signature["surface_ids"]:
			(global_row["surface_ids"] as Array).append(String(surface_id))


func _find_room_report(room_reports: Array[Dictionary], room_id: StringName) -> Dictionary:
	for room_report in room_reports:
		if StringName(room_report["room_id"]) == room_id:
			return room_report
	return {}


func _signature(collision_layer: int, size: Vector2) -> String:
	return "layer_%d_%dx%d" % [collision_layer, roundi(size.x), roundi(size.y)]


func _write_report(report: Dictionary) -> void:
	var absolute := ProjectSettings.globalize_path(REPORT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file == null:
		_failures.append("Could not write %s." % REPORT_PATH)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")


func _rect2_data(value: Rect2) -> Dictionary:
	return {"x": value.position.x, "y": value.position.y, "width": value.size.x, "height": value.size.y}


func _vector2_data(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_TERRAIN_INVENTORY_OK representative_types=5")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
