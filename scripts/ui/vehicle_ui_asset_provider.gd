class_name VehicleUiAssetProvider
extends RefCounted

## Runtime lookup for image-backed UI chrome and glyph state textures.
## Localized text, values, icons, and focus behavior remain Control-owned.

const MANIFEST_PATH := (
	"res://art/visuals/production/ui/ui-asset-manifest.json"
)
const PACK_ROOT := "res://art/visuals/production/ui"

static var _manifest: Dictionary = {}
static var _textures: Dictionary = {}
static var _errors := PackedStringArray()


static func texture(
	component_id: StringName,
	state_id: StringName
) -> Texture2D:
	_ensure_loaded()
	var key := StringName("%s/%s" % [component_id, state_id])
	if _textures.has(key):
		return _textures[key] as Texture2D
	var component := Dictionary(
		Dictionary(_manifest.get("components", {})).get(
			String(component_id),
			{}
		)
	)
	var path := String(
		Dictionary(component.get("states", {})).get(
			String(state_id),
			""
		)
	)
	if path.is_empty():
		return null
	var loaded := load("%s/%s" % [PACK_ROOT, path]) as Texture2D
	if loaded != null:
		_textures[key] = loaded
	return loaded


static func validate_pack() -> PackedStringArray:
	_ensure_loaded()
	var errors := _errors.duplicate()
	for component_variant in Dictionary(_manifest.get("components", {})):
		var component_id := StringName(component_variant)
		var component := Dictionary(_manifest["components"][component_variant])
		for state_variant in Dictionary(component.get("states", {})):
			var state_id := StringName(state_variant)
			if texture(component_id, state_id) == null:
				errors.append(
					"UI texture failed to load: %s/%s"
					% [component_id, state_id]
				)
	return errors


static func _ensure_loaded() -> void:
	if not _manifest.is_empty() or not _errors.is_empty():
		return
	if not FileAccess.file_exists(MANIFEST_PATH):
		_errors.append("UI asset manifest missing: %s" % MANIFEST_PATH)
		return
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(MANIFEST_PATH))
	if error != OK:
		_errors.append(
			"UI asset manifest parse failed at line %d: %s"
			% [parser.get_error_line(), parser.get_error_message()]
		)
		return
	_manifest = Dictionary(parser.data)
