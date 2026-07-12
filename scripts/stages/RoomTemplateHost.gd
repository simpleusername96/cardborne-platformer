class_name RoomTemplateHost
extends Node2D

@export var room_id: StringName

var template_data: RoomTemplateData


func configure(data: RoomTemplateData) -> PackedStringArray:
	var errors := PackedStringArray()
	if data == null:
		errors.append("Room host '%s' needs template data." % name)
		return errors
	for error in data.validate_definition():
		errors.append(error)
	if data.id != room_id:
		errors.append("Room host '%s' ID does not match data '%s'." % [room_id, data.id])
	template_data = data
	return errors


func get_anchor(group_name: StringName, anchor_name: StringName) -> Marker2D:
	return get_node_or_null("Anchors/%s/%s" % [group_name, anchor_name]) as Marker2D


func get_exit_portal() -> ExitPortal:
	return get_node_or_null("Anchors/Objective/ExitGate") as ExitPortal


func get_support_surfaces() -> Array[Dictionary]:
	var surfaces: Array[Dictionary] = []
	var terrain := get_node_or_null("Terrain")
	if terrain == null:
		return surfaces
	for child in terrain.get_children():
		if not child is StaticBody2D or not child.has_meta("surface_id"):
			continue
		surfaces.append({
			"id": StringName(child.get_meta("surface_id")),
			"x": child.position.x - float(child.get_meta("support_width")) * 0.5,
			"width": float(child.get_meta("support_width")),
			"top": float(child.get_meta("support_top")),
		})
	surfaces.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left["x"] < right["x"])
	return surfaces
