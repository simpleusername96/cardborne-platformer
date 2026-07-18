class_name TiledSourceParser
extends RefCounted

const EXPECTED_LAYERS := {
	"ground": "tilelayer",
	"structures": "objectgroup",
	"connections": "objectgroup",
	"spawns": "objectgroup",
	"props": "objectgroup",
	"objectives": "objectgroup",
	"camera_bounds": "objectgroup",
}
const GID_TRANSFORM_MASK := 0xF0000000


func parse_map(path: String) -> Dictionary:
	var errors: Array[String] = []
	if not FileAccess.file_exists(path):
		return {"ok": false, "errors": ["Missing map: %s" % path]}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {"ok": false, "errors": ["Map is not a JSON object: %s" % path]}
	var map: Dictionary = parsed
	if map.get("orientation", "") != "orthogonal":
		errors.append("orientation must be orthogonal")
	if map.get("infinite", true):
		errors.append("infinite maps are not supported")
	if int(map.get("tilewidth", 0)) != 64 or int(map.get("tileheight", 0)) != 64:
		errors.append("tile size must be 64x64")
	if int(map.get("width", 0)) <= 0 or int(map.get("height", 0)) <= 0:
		errors.append("map width and height must be positive")
	var map_properties := properties_to_dictionary(map.get("properties", []))
	if String(map_properties.get("room_id", "")).is_empty():
		errors.append("room_id property is required")
	if int(map_properties.get("schema_version", 0)) != 1:
		errors.append("schema_version must be 1")
	if not is_equal_approx(float(map_properties.get("meters_per_tile", 0.0)), 1.0):
		errors.append("meters_per_tile must be 1.0")

	var tilesets: Array = map.get("tilesets", [])
	if tilesets.size() != 1 or not tilesets[0] is Dictionary:
		errors.append("exactly one external tileset is required")
		return {"ok": false, "errors": _prefix_errors(path, errors)}
	var tileset_ref: Dictionary = tilesets[0]
	if not tileset_ref.has("source") or int(tileset_ref.get("firstgid", 0)) != 1:
		errors.append("tileset must be external with firstgid 1")
	var tileset_path := path.get_base_dir().path_join(String(tileset_ref.get("source", ""))).simplify_path()
	var tileset := parse_tileset(tileset_path)
	if not tileset.ok:
		errors.append_array(tileset.errors)

	var layers_by_name: Dictionary = {}
	for layer_variant: Variant in map.get("layers", []):
		if not layer_variant is Dictionary:
			errors.append("layer entry is not an object")
			continue
		var layer: Dictionary = layer_variant
		var layer_name := String(layer.get("name", ""))
		if not EXPECTED_LAYERS.has(layer_name):
			errors.append("unknown layer: %s" % layer_name)
			continue
		if layers_by_name.has(layer_name):
			errors.append("duplicate layer: %s" % layer_name)
			continue
		if String(layer.get("type", "")) != EXPECTED_LAYERS[layer_name]:
			errors.append("layer %s has wrong type" % layer_name)
		layers_by_name[layer_name] = layer
	for required_name: String in EXPECTED_LAYERS:
		if not layers_by_name.has(required_name):
			errors.append("missing layer: %s" % required_name)
	if layers_by_name.has("ground"):
		var ground: Dictionary = layers_by_name.ground
		if ground.has("encoding") or ground.has("compression") or ground.has("chunks"):
			errors.append("ground must use a finite uncompressed JSON array")
		var data: Array = ground.get("data", [])
		if data.size() != int(map.width) * int(map.height):
			errors.append("ground data size does not match map dimensions")
		for index in data.size():
			var gid := int(data[index])
			if gid & GID_TRANSFORM_MASK:
				errors.append("ground GID transform flags are forbidden at index %d" % index)
				break
			var local_id := gid - 1
			if local_id < 0 or local_id > 7:
				errors.append("ground contains non-surface local tile ID %d" % local_id)
				break

	return {
		"ok": errors.is_empty(),
		"errors": _prefix_errors(path, errors),
		"path": path,
		"map": map,
		"properties": map_properties,
		"layers": layers_by_name,
		"tileset": tileset,
	}


func parse_tileset(path: String) -> Dictionary:
	var errors: Array[String] = []
	var parser := XMLParser.new()
	var open_error := parser.open(path)
	if open_error != OK:
		return {"ok": false, "errors": ["Cannot open tileset %s: %s" % [path, error_string(open_error)]]}
	var root_properties: Dictionary = {}
	var tiles: Dictionary = {}
	var current_tile := -1
	var tile_count := 0
	var columns := 0
	var tile_width := 0
	var tile_height := 0
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			match parser.get_node_name():
				"tileset":
					tile_count = int(_attribute(parser, "tilecount", "0"))
					columns = int(_attribute(parser, "columns", "0"))
					tile_width = int(_attribute(parser, "tilewidth", "0"))
					tile_height = int(_attribute(parser, "tileheight", "0"))
				"tile":
					current_tile = int(_attribute(parser, "id", "-1"))
					tiles[current_tile] = {}
				"property":
					var property_name := _attribute(parser, "name", "")
					var property_type := _attribute(parser, "type", "string")
					var property_value: Variant = _typed_value(_attribute(parser, "value", ""), property_type)
					if current_tile >= 0:
						tiles[current_tile][property_name] = property_value
					else:
						root_properties[property_name] = property_value
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END and parser.get_node_name() == "tile":
			current_tile = -1
	if tile_count != 16 or columns != 4 or tile_width != 64 or tile_height != 64:
		errors.append("tileset geometry must be 16 tiles, 4 columns, 64x64")
	if not bool(root_properties.get("authoring_only", false)):
		errors.append("tileset must be marked authoring_only")
	for tile_id in 16:
		if not tiles.has(tile_id):
			errors.append("missing tile definition %d" % tile_id)
		elif String(tiles[tile_id].get("asset_id", "")).is_empty():
			errors.append("tile %d has no asset_id" % tile_id)
	return {
		"ok": errors.is_empty(),
		"errors": _prefix_errors(path, errors),
		"path": path,
		"properties": root_properties,
		"tiles": tiles,
	}


func properties_to_dictionary(property_list: Array) -> Dictionary:
	var result: Dictionary = {}
	for property_variant: Variant in property_list:
		if property_variant is Dictionary:
			var property: Dictionary = property_variant
			result[String(property.get("name", ""))] = property.get("value")
	return result


func local_id_from_gid(gid: int) -> int:
	return (gid & ~GID_TRANSFORM_MASK) - 1


func _attribute(parser: XMLParser, name: String, fallback: String) -> String:
	if parser.has_attribute(name):
		return parser.get_named_attribute_value(name)
	return fallback


func _typed_value(value: String, type: String) -> Variant:
	match type:
		"bool":
			return value.to_lower() == "true" or value == "1"
		"int":
			return int(value)
		"float":
			return float(value)
		_:
			return value


func _prefix_errors(path: String, errors: Array[String]) -> Array[String]:
	var prefixed: Array[String] = []
	for message in errors:
		prefixed.append("%s: %s" % [path, message])
	return prefixed
