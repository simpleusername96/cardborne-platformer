class_name TerrainPresentationStyler
extends RefCounted

const PALETTES := {
	&"ruin_approach": {
		"rock": Color("343c3f"),
		"cap": Color("78935d"),
		"shadow": Color("20292b"),
		"ledge": Color("485b5c"),
		"bracket": Color("8a6946"),
	},
	&"flooded_works": {
		"rock": Color("30474a"),
		"cap": Color("67b7b2"),
		"shadow": Color("1c3033"),
		"ledge": Color("455f61"),
		"bracket": Color("997350"),
	},
	&"broken_sanctum": {
		"rock": Color("48434f"),
		"cap": Color("ad9956"),
		"shadow": Color("2d2934"),
		"ledge": Color("595261"),
		"bracket": Color("a66e58"),
	},
}


static func apply(room_hosts: Dictionary, stage_id: StringName) -> Dictionary:
	var palette: Dictionary = PALETTES.get(stage_id, PALETTES[&"ruin_approach"])
	var counts := {
		"rock": 0,
		"cap": 0,
		"groove": 0,
		"ledge": 0,
		"bracket": 0,
	}
	var room_ids := room_hosts.keys()
	room_ids.sort()
	for room_id in room_ids:
		var room := room_hosts[room_id] as Node
		if room == null:
			continue
		_style_room(room, palette, counts)
	return {
		"stage_id": String(stage_id),
		"palette": palette.duplicate(true),
		"counts": counts.duplicate(true),
		"styled_total": _sum_counts(counts),
	}


static func _style_room(room: Node, palette: Dictionary, counts: Dictionary) -> void:
	for node in room.find_children("*", "Polygon2D", true, false):
		var polygon := node as Polygon2D
		var path := String(room.get_path_to(polygon))
		if path.begins_with("Terrain/"):
			if _is_surface_name(polygon.name):
				polygon.color = palette["cap"]
				counts["cap"] = int(counts["cap"]) + 1
			elif polygon.name in [&"RockVisual", &"Visual"]:
				polygon.color = palette["rock"]
				counts["rock"] = int(counts["rock"]) + 1
		elif path.begins_with("OneWay/"):
			if polygon.name in [&"RockBracket", &"LeftBracket", &"RightBracket"]:
				polygon.color = palette["bracket"]
				counts["bracket"] = int(counts["bracket"]) + 1
			elif polygon.name == &"Visual":
				polygon.color = palette["ledge"]
				counts["ledge"] = int(counts["ledge"]) + 1
	for node in room.find_children("*", "Line2D", true, false):
		var line := node as Line2D
		var path := String(room.get_path_to(line))
		if path.begins_with("Terrain/"):
			line.default_color = palette["shadow"]
			counts["groove"] = int(counts["groove"]) + 1
		elif path.begins_with("OneWay/") and line.name == &"Surface":
			line.default_color = palette["cap"]
			counts["cap"] = int(counts["cap"]) + 1


static func _is_surface_name(node_name: StringName) -> bool:
	return node_name in [&"SupportCap", &"Surface", &"Cap"]


static func _sum_counts(counts: Dictionary) -> int:
	var total := 0
	for value in counts.values():
		total += int(value)
	return total
