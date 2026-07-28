class_name VehicleWorldStampCatalog
extends RefCounted

## Runtime view of the approved space-hangar stamp recipe. The catalog owns
## atlas-cell lookup only; field geometry remains the placement authority.

const RECIPE_PATH := (
	"res://pixel-art-production/runtime/atlases/space-hangar-v2/world-recipe.json"
)
const ATLAS_PATHS := {
	"structure": (
		"res://pixel-art-production/runtime/atlases/space-hangar-v2/"
		+ "structure-atlas.png"
	),
	"prop": (
		"res://pixel-art-production/runtime/atlases/space-hangar-v2/"
		+ "prop-atlas.png"
	),
}
const CELL_SIZE := 64
const EXPECTED_STAMP_COUNT := 32

static var _loaded := false
static var _records: Dictionary = {}
static var _textures: Dictionary = {}
static var _errors := PackedStringArray()


static func stamp(stamp_id: StringName) -> Dictionary:
	_ensure_loaded()
	if not _records.has(stamp_id):
		push_error("Unknown approved world stamp ID: %s" % stamp_id)
		return {}
	var result := Dictionary(_records[stamp_id]).duplicate(true)
	var atlas_id := String(result["atlas"])
	result["texture"] = _textures.get(atlas_id)
	var cell := Vector2i(result["cell"])
	result["region"] = Rect2(
		Vector2(cell * CELL_SIZE),
		Vector2.ONE * float(CELL_SIZE)
	)
	return result


static func debug_contract() -> Dictionary:
	_ensure_loaded()
	var ids := PackedStringArray()
	for value in _records.keys():
		ids.append(String(value))
	ids.sort()
	return {
		"loaded":_errors.is_empty(),
		"recipe_path":RECIPE_PATH,
		"stamp_count":_records.size(),
		"expected_stamp_count":EXPECTED_STAMP_COUNT,
		"ids":ids,
		"errors":_errors.duplicate(),
	}


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(RECIPE_PATH):
		_errors.append("Runtime world recipe is missing.")
		return
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(RECIPE_PATH)
	)
	if not parsed is Dictionary:
		_errors.append("Runtime world recipe is invalid.")
		return
	for atlas_id in ATLAS_PATHS:
		var texture := load(String(ATLAS_PATHS[atlas_id])) as Texture2D
		if texture == null:
			_errors.append("Runtime world atlas is missing: %s" % atlas_id)
		else:
			_textures[atlas_id] = texture
	var recipe := Dictionary(parsed)
	_register_stamps(Array(recipe.get("structure_stamps", [])), "structure")
	_register_stamps(Array(recipe.get("prop_stamps", [])), "prop")
	if _records.size() != EXPECTED_STAMP_COUNT:
		_errors.append(
			"Runtime world recipe must expose %d stamps, found %d."
			% [EXPECTED_STAMP_COUNT, _records.size()]
		)


static func _register_stamps(stamps: Array, atlas_id: String) -> void:
	for value in stamps:
		if not value is Dictionary:
			_errors.append("World stamp record is invalid.")
			continue
		var source := Dictionary(value)
		var stamp_id := StringName(source.get("id", ""))
		var cell_values := Array(source.get("cell", []))
		if stamp_id.is_empty() or cell_values.size() != 2:
			_errors.append("World stamp ID or cell is invalid.")
			continue
		if _records.has(stamp_id):
			_errors.append("Duplicate world stamp ID: %s" % stamp_id)
			continue
		var cell := Vector2i(int(cell_values[0]), int(cell_values[1]))
		if cell.x < 0 or cell.x >= 4 or cell.y < 0 or cell.y >= 4:
			_errors.append("World stamp cell is outside the 4x4 atlas: %s" % stamp_id)
			continue
		_records[stamp_id] = {
			"id":stamp_id,
			"atlas":atlas_id,
			"cell":cell,
			"role":StringName(source.get("role", "")),
			"allowed_anchor":StringName(source.get("allowed_anchor", "")),
		}
