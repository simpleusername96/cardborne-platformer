extends SceneTree

## Deterministic raster compiler for the approved Space Hangar V2 candidate.
## It normalizes authored sources, packs fixed atlases, and assembles review
## proofs without inventing visible structure, wear, or props in code.

const GENERATOR_PATH := "res://tools/design/build_space_hangar_candidate.gd"
const DEFAULT_RECIPE_PATH := (
	"res://pixel-art-production/assets/recipes/candidates/space-hangar-v2.json"
)
const SCHEMA_PATH := (
	"res://pixel-art-production/schemas/space-hangar-candidate-recipe.schema.json"
)
const SOURCE_MANIFEST_RELATIVE_PATH := (
	"pixel-art-production/assets/source/candidates/space-hangar-v2/source-manifest.json"
)
const CANONICAL_OUTPUT_PATH := (
	"res://pixel-art-production/evidence/space-hangar-v2"
)
const TILE_SIZE := 24
const TILE_EDGE := 2
const LOGICAL_MATERIAL_SIZE := Vector2i(256, 256)
const STAMP_CELL_SIZE := 64
const STAMP_ATLAS_SIZE := Vector2i(256, 256)
const REPEAT_MASTER_SIZE := Vector2i(192, 192)
const PROOF_REPEAT_SCALE := 2
const PROOF_REPEAT_SIZE := Vector2i(384, 384)
const BASE_ATLAS_SIZE := Vector2i(288, 48)
const HASH_MODULUS := 2147483647
const STAGING_SUFFIX := ".space-hangar-candidate-staging"
const BACKUP_SUFFIX := ".space-hangar-candidate-previous"
const ALLOWED_ANCHORS := [
	"boundary",
	"cover",
	"bulkhead",
	"feature",
	"floor_flat",
]
const ALLOWED_TRANSFORMS := [
	"identity",
	"flip_h",
	"flip_v",
	"rotate_180",
]
const SOURCE_KEYS := [
	"full_map_target",
	"deck_material_master",
	"wall_material_master",
	"void_material_master",
	"structure_sheet",
	"prop_sheet",
]
const EXPECTED_SOURCE_PATHS := {
	"full_map_target":"pixel-art-production/assets/source/candidates/space-hangar-v2/raw/full-map-target.png",
	"deck_material_master":"pixel-art-production/assets/source/candidates/space-hangar-v2/raw/deck-material-master.png",
	"wall_material_master":"pixel-art-production/assets/source/candidates/space-hangar-v2/raw/wall-material-master.png",
	"void_material_master":"pixel-art-production/assets/source/candidates/space-hangar-v2/raw/void-material-master.png",
	"structure_sheet":"pixel-art-production/assets/source/candidates/space-hangar-v2/raw/structure-sheet.png",
	"prop_sheet":"pixel-art-production/assets/source/candidates/space-hangar-v2/raw/prop-sheet.png",
}
const SOURCE_MANIFEST_IDS := {
	"full_map_target":"full-map-target",
	"deck_material_master":"deck-material-master",
	"wall_material_master":"wall-material-master",
	"void_material_master":"void-material-master",
	"structure_sheet":"structure-sheet",
	"prop_sheet":"prop-sheet",
}
const FAMILY_IDS := ["deck", "wall", "void"]
const FAMILY_COUNTS := [12, 8, 4]
const EXPECTED_WINDOWS := {
	"deck":[
		[104, 48, 24, 24], [136, 48, 24, 24],
		[104, 80, 24, 24], [136, 80, 24, 24],
		[112, 104, 24, 24], [144, 104, 24, 24],
		[24, 96, 24, 24], [184, 64, 24, 24],
		[184, 184, 24, 24], [48, 144, 24, 24],
		[104, 184, 24, 24], [200, 208, 24, 24],
	],
	"wall":[
		[16, 48, 24, 24], [80, 48, 24, 24],
		[144, 48, 24, 24], [208, 48, 24, 24],
		[16, 176, 24, 24], [80, 176, 24, 24],
		[144, 176, 24, 24], [208, 176, 24, 24],
	],
	"void":[
		[16, 116, 24, 24], [80, 116, 24, 24],
		[144, 116, 24, 24], [208, 116, 24, 24],
	],
}
const STRUCTURE_IDS := [
	"frame_h",
	"frame_v",
	"corner_nw",
	"corner_ne",
	"corner_se",
	"corner_sw",
	"rail_h",
	"rail_v",
	"service_bay_h",
	"service_bay_v",
	"cover_small",
	"cover_wide",
	"bulkhead_h",
	"bulkhead_v",
	"inner_cap_h",
	"inner_cap_v",
]
const STRUCTURE_ANCHORS := [
	"boundary",
	"boundary",
	"boundary",
	"boundary",
	"boundary",
	"boundary",
	"boundary",
	"boundary",
	"feature",
	"feature",
	"cover",
	"cover",
	"bulkhead",
	"bulkhead",
	"boundary",
	"boundary",
]
const PROP_IDS := [
	"hatch_round",
	"vent_round",
	"console_small",
	"console_wide",
	"cargo_small",
	"cargo_wide",
	"machinery_small",
	"machinery_tall",
	"warning_plate",
	"pipe_cluster",
	"cable_coil",
	"terminal",
	"wear_scrape_a",
	"wear_scrape_b",
	"wear_chip_a",
	"wear_chip_b",
]

var _recipe_path := ""
var _output_directory := ""
var _write_directory := ""
var _staging_directory := ""
var _backup_directory := ""
var _check_only := false
var _recipe: Dictionary = {}
var _seed := 0
var _source_paths: Dictionary = {}
var _source_images: Dictionary = {}
var _source_manifest_path := ""
var _source_manifest_sha256 := ""
var _schema_path := ""
var _schema_sha256 := ""
var _family_specs: Dictionary = {}
var _family_variants: Dictionary = {}
var _family_clean_masters: Dictionary = {}
var _family_repeat_masters: Dictionary = {}
var _stamp_catalog: Dictionary = {}
var _structure_atlas: Image
var _prop_atlas: Image
var _last_error := ""


func _initialize() -> void:
	var arguments := _parse_arguments()
	if bool(arguments.get("help", false)):
		_print_usage()
		quit(0)
		return
	if not bool(arguments.get("valid", false)):
		_print_usage()
		quit(2)
		return
	_check_only = bool(arguments["check_only"])
	_recipe_path = String(arguments["recipe"]).replace("\\", "/")
	if _recipe_path.is_empty() and _check_only:
		_recipe_path = ProjectSettings.globalize_path(DEFAULT_RECIPE_PATH)
	_output_directory = String(arguments["output"]).replace("\\", "/")
	if not _validate_cli_paths():
		quit(2)
		return
	if not _load_recipe():
		quit(1)
		return
	if not _validate_recipe_contract():
		quit(1)
		return
	print("SPACE_HANGAR_CANDIDATE_CONFIG_OK recipe=%s" % _recipe_path)
	if not _load_and_validate_sources():
		push_error(
			"SPACE_HANGAR_CANDIDATE_SOURCE_INVALID: %s" % _last_error
		)
		quit(1)
		return
	print("SPACE_HANGAR_CANDIDATE_SOURCE_OK count=6")
	if _check_only:
		print("SPACE_HANGAR_CANDIDATE_CHECK_OK")
		quit(0)
		return
	if not _compile_and_publish():
		_discard_staging_output()
		quit(1)
		return
	print(
		"SPACE_HANGAR_CANDIDATE_OK seed=%d output=%s"
		% [_seed, _output_directory]
	)
	quit(0)


func _parse_arguments() -> Dictionary:
	var values := {
		"recipe":"",
		"output":"",
		"check_only":false,
		"help":false,
		"valid":true,
	}
	var arguments := OS.get_cmdline_user_args()
	var index := 0
	while index < arguments.size():
		var argument := String(arguments[index])
		if argument in ["--help", "-h"]:
			values["help"] = true
		elif argument == "--check-only":
			values["check_only"] = true
		elif argument.begins_with("--recipe="):
			values["recipe"] = argument.trim_prefix("--recipe=")
		elif argument.begins_with("--output="):
			values["output"] = argument.trim_prefix("--output=")
		elif argument in ["--recipe", "--output"]:
			if index + 1 >= arguments.size():
				push_error("%s requires a value." % argument)
				values["valid"] = false
			else:
				index += 1
				if argument == "--recipe":
					values["recipe"] = String(arguments[index])
				else:
					values["output"] = String(arguments[index])
		else:
			push_error("Unknown space-hangar candidate argument: %s" % argument)
			values["valid"] = false
		index += 1
	if not bool(values["help"]):
		if String(values["recipe"]).is_empty() and not bool(values["check_only"]):
			push_error("Missing required --recipe argument.")
			values["valid"] = false
		if String(values["output"]).is_empty() and not bool(values["check_only"]):
			push_error("Missing required --output argument.")
			values["valid"] = false
	return values


func _print_usage() -> void:
	print(
		(
			"Usage: godot --headless --script %s -- "
			+ "--recipe <absolute.json> --output "
			+ "<absolute-canonical-evidence-directory>\n"
			+ "       godot --headless --script %s -- --check-only "
			+ "[--recipe <absolute.json>]"
		)
		% [GENERATOR_PATH, GENERATOR_PATH]
	)


func _validate_cli_paths() -> bool:
	if _recipe_path.is_empty() or not _recipe_path.is_absolute_path():
		return _fail("--recipe must be an absolute filesystem path.")
	if _recipe_path.get_extension().to_lower() != "json":
		return _fail("--recipe must point to a JSON file.")
	if not FileAccess.file_exists(_recipe_path):
		return _fail("Recipe does not exist: %s" % _recipe_path)
	_schema_path = ProjectSettings.globalize_path(SCHEMA_PATH)
	if not FileAccess.file_exists(_schema_path):
		return _fail("Candidate schema does not exist: %s" % _schema_path)
	_schema_sha256 = FileAccess.get_sha256(_schema_path)
	if _check_only:
		if _output_directory.is_empty():
			return true
	if _output_directory.is_empty() or not _output_directory.is_absolute_path():
		return _fail("--output must be an absolute filesystem path.")
	var canonical_output := _normalized_filesystem_path(
		ProjectSettings.globalize_path(CANONICAL_OUTPUT_PATH)
	)
	var requested_output := _normalized_filesystem_path(_output_directory)
	if requested_output.to_lower() != canonical_output.to_lower():
		return _fail(
			"--output is candidate-only and must be %s." % canonical_output
		)
	_output_directory = canonical_output
	if FileAccess.file_exists(_output_directory):
		return _fail("--output points to a file: %s" % _output_directory)
	_staging_directory = _output_directory + STAGING_SUFFIX
	_backup_directory = _output_directory + BACKUP_SUFFIX
	for reserved_path in [_staging_directory, _backup_directory]:
		if (
			FileAccess.file_exists(reserved_path)
			or DirAccess.dir_exists_absolute(reserved_path)
		):
			return _fail(
				"Reserved publish path already exists; inspect it first: %s"
				% reserved_path
			)
	return true


func _normalized_filesystem_path(path: String) -> String:
	return path.replace("\\", "/").simplify_path().trim_suffix("/")


func _load_recipe() -> bool:
	var text := FileAccess.get_file_as_string(_recipe_path)
	if text.is_empty():
		return _fail("Recipe is empty or unreadable: %s" % _recipe_path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return _fail("Recipe root must be a JSON object: %s" % _recipe_path)
	_recipe = Dictionary(parsed)
	return true


func _validate_recipe_contract() -> bool:
	if not _require_exact_keys(
		_recipe,
		[
			"schema_version",
			"seed",
			"sources",
			"base_families",
			"structure_stamps",
			"prop_stamps",
			"proof_layout",
			"outputs",
		],
		"recipe"
	):
		return false
	if int(_recipe["schema_version"]) != 1:
		return _fail("recipe.schema_version must be 1.")
	_seed = int(_recipe["seed"])
	if _seed < 0 or _seed > HASH_MODULUS:
		return _fail("recipe.seed must be between 0 and %d." % HASH_MODULUS)
	if not _validate_sources_contract(Dictionary(_recipe["sources"])):
		return false
	if not _validate_base_families(Array(_recipe["base_families"])):
		return false
	if not _validate_stamp_contracts(
		Array(_recipe["structure_stamps"]),
		STRUCTURE_IDS,
		STRUCTURE_ANCHORS,
		"structure"
	):
		return false
	var prop_anchors: Array = []
	for _index in PROP_IDS.size():
		prop_anchors.append("floor_flat")
	if not _validate_stamp_contracts(
		Array(_recipe["prop_stamps"]),
		PROP_IDS,
		prop_anchors,
		"prop"
	):
		return false
	if not _validate_proof_layout(Dictionary(_recipe["proof_layout"])):
		return false
	return _validate_outputs_contract(Dictionary(_recipe["outputs"]))


func _validate_sources_contract(sources: Dictionary) -> bool:
	if not _require_exact_keys(
		sources,
		[
			"source_manifest",
			"full_map_target",
			"deck_material_master",
			"wall_material_master",
			"void_material_master",
			"structure_sheet",
			"prop_sheet",
			"full_map_size",
			"material_source_size",
			"sheet_source_size",
			"sheet_grid",
			"logical_sheet_size",
			"cell_clearance_px",
			"chroma_key",
			"chroma_predicate",
			"stamp_fit_long_axis_px",
			"stamp_palette",
		],
		"recipe.sources"
	):
		return false
	if (
		String(sources["source_manifest"]).replace("\\", "/")
		!= SOURCE_MANIFEST_RELATIVE_PATH
	):
		return _fail(
			"recipe.sources.source_manifest must be the fixed path %s."
			% SOURCE_MANIFEST_RELATIVE_PATH
		)
	for key_variant in SOURCE_KEYS:
		var key := String(key_variant)
		var expected := String(EXPECTED_SOURCE_PATHS[key])
		if String(sources[key]).replace("\\", "/") != expected:
			return _fail(
				"recipe.sources.%s must be the fixed path %s." % [key, expected]
			)
	if not _array_equals(Array(sources["full_map_size"]), [1280, 720]):
		return _fail("recipe.sources.full_map_size must be [1280, 720].")
	for key in [
		"material_source_size",
		"sheet_source_size",
	]:
		if not _array_equals(Array(sources[key]), [1024, 1024]):
			return _fail("recipe.sources.%s must be [1024, 1024]." % key)
	if not _array_equals(Array(sources["sheet_grid"]), [4, 4]):
		return _fail("recipe.sources.sheet_grid must be [4, 4].")
	if not _array_equals(Array(sources["logical_sheet_size"]), [256, 256]):
		return _fail("recipe.sources.logical_sheet_size must be [256, 256].")
	if int(sources["cell_clearance_px"]) != 24:
		return _fail("recipe.sources.cell_clearance_px must be 24.")
	if String(sources["chroma_key"]).to_upper() != "#FF00FF":
		return _fail("recipe.sources.chroma_key must be #FF00FF.")
	var predicate := Dictionary(sources["chroma_predicate"])
	if not _require_exact_keys(
		predicate,
		[
			"red_min",
			"green_max",
			"blue_min",
			"dominance_min",
			"fringe_value_min",
			"fringe_green_ratio_max",
			"fringe_rb_delta_max",
		],
		"recipe.sources.chroma_predicate"
	):
		return false
	if (
		int(predicate["red_min"]) < 128
		or int(predicate["blue_min"]) < 128
		or int(predicate["green_max"]) > 127
		or int(predicate["dominance_min"]) < 32
		or int(predicate["fringe_value_min"]) < 8
		or int(predicate["fringe_value_min"]) > 96
		or float(predicate["fringe_green_ratio_max"]) <= 0.0
		or float(predicate["fringe_green_ratio_max"]) > 0.7
		or int(predicate["fringe_rb_delta_max"]) < 0
		or int(predicate["fringe_rb_delta_max"]) > 64
	):
		return _fail("recipe.sources.chroma_predicate is not magenta-specific.")
	var stamp_fit := Dictionary(sources["stamp_fit_long_axis_px"])
	if not _require_exact_keys(
		stamp_fit,
		["structure", "prop", "wear"],
		"recipe.sources.stamp_fit_long_axis_px"
	):
		return false
	if (
		int(stamp_fit["structure"]) != 56
		or int(stamp_fit["prop"]) != 42
		or int(stamp_fit["wear"]) != 32
	):
		return _fail("recipe.sources.stamp_fit_long_axis_px must be 56/42/32.")
	var palette := Array(sources["stamp_palette"])
	if palette.size() < 4 or palette.size() > 16:
		return _fail("recipe.sources.stamp_palette must contain 4-16 colors.")
	if not _validate_color_list(palette, "recipe.sources.stamp_palette"):
		return false
	return true


func _validate_base_families(families: Array) -> bool:
	if families.size() != FAMILY_IDS.size():
		return _fail("recipe.base_families must contain deck, wall, and void.")
	for index in families.size():
		if not families[index] is Dictionary:
			return _fail("recipe.base_families[%d] must be an object." % index)
		var family := Dictionary(families[index])
		if not _require_exact_keys(
			family,
			[
				"id",
				"source",
				"palette",
				"neutral_color",
				"prequantize_sample_size",
				"variant_count",
				"sample_windows",
				"allowed_transforms",
			],
			"recipe.base_families[%d]" % index
		):
			return false
		var family_id := String(family["id"])
		if family_id != String(FAMILY_IDS[index]):
			return _fail(
				"recipe.base_families[%d].id must be %s."
				% [index, FAMILY_IDS[index]]
			)
		if String(family["source"]) != "%s_material_master" % family_id:
			return _fail("Base family %s references the wrong source." % family_id)
		if int(family["variant_count"]) != int(FAMILY_COUNTS[index]):
			return _fail("Base family %s has the wrong variant count." % family_id)
		var palette := Array(family["palette"])
		if not _validate_color_list(palette, "base family %s palette" % family_id):
			return false
		if not palette.has(String(family["neutral_color"])):
			return _fail(
				"Base family %s neutral color must be in its palette." % family_id
			)
		var sample_size := int(family["prequantize_sample_size"])
		var expected_sample_size := 32 if family_id == "void" else 256
		if sample_size != expected_sample_size:
			return _fail(
				"Base family %s prequantize_sample_size must be %d."
				% [family_id, expected_sample_size]
			)
		var windows := Array(family["sample_windows"])
		if not _nested_array_equals(windows, Array(EXPECTED_WINDOWS[family_id])):
			return _fail("Base family %s sample windows do not match the contract." % family_id)
		var transforms := Array(family["allowed_transforms"])
		if not _array_equals(transforms, ALLOWED_TRANSFORMS):
			return _fail(
				"Base family %s allowed transforms do not match the contract."
				% family_id
			)
		_family_specs[family_id] = family
	return true


func _validate_stamp_contracts(
	stamps: Array,
	expected_ids: Array,
	expected_anchors: Array,
	group: String
) -> bool:
	if stamps.size() != 16:
		return _fail("recipe.%s_stamps must contain exactly 16 cells." % group)
	for index in stamps.size():
		if not stamps[index] is Dictionary:
			return _fail("recipe.%s_stamps[%d] must be an object." % [group, index])
		var stamp := Dictionary(stamps[index])
		if not _require_exact_keys(
			stamp,
			["id", "cell", "role", "allowed_anchor"],
			"recipe.%s_stamps[%d]" % [group, index]
		):
			return false
		var stamp_id := String(stamp["id"])
		if stamp_id != String(expected_ids[index]):
			return _fail(
				"recipe.%s_stamps[%d].id must be %s."
				% [group, index, expected_ids[index]]
			)
		if not _array_equals(Array(stamp["cell"]), [index % 4, index / 4]):
			return _fail("Stamp %s has the wrong row-major cell." % stamp_id)
		var role := String(stamp["role"])
		if group == "structure" and role != "structure":
			return _fail("Structure stamp %s must use role structure." % stamp_id)
		if group == "prop":
			var expected_role := "wear" if index >= 12 else "prop"
			if role != expected_role:
				return _fail("Prop stamp %s must use role %s." % [stamp_id, expected_role])
		var anchor := String(stamp["allowed_anchor"])
		if anchor != String(expected_anchors[index]) or not anchor in ALLOWED_ANCHORS:
			return _fail("Stamp %s has an invalid allowed_anchor." % stamp_id)
		if _stamp_catalog.has(stamp_id):
			return _fail("Duplicate stamp id: %s" % stamp_id)
		_stamp_catalog[stamp_id] = stamp.duplicate(true)
	return true


func _validate_proof_layout(layout: Dictionary) -> bool:
	if not _require_exact_keys(
		layout,
		[
			"size",
			"arena",
			"outer_frame",
			"center_no_go",
			"base_regions",
			"anchor_regions",
			"placements",
			"wear_min_spacing",
			"prop_fixture_range",
			"minimum_landmarks",
		],
		"recipe.proof_layout"
	):
		return false
	if not _array_equals(Array(layout["size"]), [1280, 720]):
		return _fail("proof_layout.size must be [1280, 720].")
	if not _array_equals(Array(layout["arena"]), [156, 106, 968, 514]):
		return _fail("proof_layout.arena does not match current-layout evidence.")
	if not _array_equals(Array(layout["center_no_go"]), [500, 250, 280, 250]):
		return _fail("proof_layout.center_no_go does not match the contract.")
	if not _array_equals(Array(layout["outer_frame"]), [124, 51, 1032, 619]):
		return _fail("proof_layout.outer_frame does not match current-layout evidence.")
	var base_regions := Array(layout["base_regions"])
	if base_regions.size() != 3:
		return _fail("proof_layout.base_regions must contain void, wall, and deck.")
	for index in base_regions.size():
		var region := Dictionary(base_regions[index])
		if not _require_exact_keys(
			region,
			["family", "rect"],
			"proof_layout.base_regions[%d]" % index
		):
			return false
		if String(region["family"]) != String(FAMILY_IDS[2 - index]):
			return _fail("proof_layout.base_regions must be ordered void, wall, deck.")
		if not _valid_rect_array(Array(region["rect"])):
			return _fail("proof_layout.base_regions[%d].rect is invalid." % index)
	var anchors := Dictionary(layout["anchor_regions"])
	if not _require_exact_keys(
		anchors,
		ALLOWED_ANCHORS,
		"proof_layout.anchor_regions"
	):
		return false
	for anchor in ALLOWED_ANCHORS:
		var regions := Array(anchors[anchor])
		if regions.is_empty():
			return _fail("proof_layout.anchor_regions.%s cannot be empty." % anchor)
		for rect_value in regions:
			if not rect_value is Array or not _valid_rect_array(Array(rect_value)):
				return _fail("Invalid %s anchor region." % anchor)
	if int(layout["wear_min_spacing"]) < 96:
		return _fail("proof_layout.wear_min_spacing must be at least 96.")
	if not _array_equals(Array(layout["prop_fixture_range"]), [6, 10]):
		return _fail("proof_layout.prop_fixture_range must be [6, 10].")
	if int(layout["minimum_landmarks"]) < 4:
		return _fail("proof_layout.minimum_landmarks must be at least 4.")
	return _validate_placements(layout)


func _validate_placements(layout: Dictionary) -> bool:
	var placements := Array(layout["placements"])
	if placements.is_empty():
		return _fail("proof_layout.placements cannot be empty.")
	var proof_bounds := Rect2i(Vector2i.ZERO, _vector2i(Array(layout["size"])))
	var arena := _rect2i(Array(layout["arena"]))
	var no_go := _rect2i(Array(layout["center_no_go"]))
	var anchors := Dictionary(layout["anchor_regions"])
	var placement_ids := {}
	var wear_centers: Array[Vector2i] = []
	var prop_count := 0
	var landmark_count := 0
	for index in placements.size():
		if not placements[index] is Dictionary:
			return _fail("proof_layout.placements[%d] must be an object." % index)
		var placement := Dictionary(placements[index])
		var placement_keys := [
			"id",
			"stamp_id",
			"position",
			"anchor",
			"transform",
			"landmark",
		]
		if placement.has("target_size"):
			placement_keys.append("target_size")
		if not _require_exact_keys(
			placement,
			placement_keys,
			"proof_layout.placements[%d]" % index
		):
			return false
		var placement_id := String(placement["id"])
		if placement_id.is_empty() or placement_ids.has(placement_id):
			return _fail("Duplicate or empty placement id: %s" % placement_id)
		placement_ids[placement_id] = true
		var stamp_id := String(placement["stamp_id"])
		if not _stamp_catalog.has(stamp_id):
			return _fail("Placement %s references unknown stamp %s." % [placement_id, stamp_id])
		var stamp := Dictionary(_stamp_catalog[stamp_id])
		var anchor := String(placement["anchor"])
		if anchor != String(stamp["allowed_anchor"]):
			return _fail("Placement %s violates stamp anchor ownership." % placement_id)
		if not String(placement["transform"]) in ALLOWED_TRANSFORMS:
			return _fail("Placement %s has an invalid transform." % placement_id)
		var position_value := Array(placement["position"])
		if position_value.size() != 2:
			return _fail("Placement %s position must have two integers." % placement_id)
		var position := _vector2i(position_value)
		var placement_size := Vector2i(STAMP_CELL_SIZE, STAMP_CELL_SIZE)
		if placement.has("target_size"):
			var target_size_value := Array(placement["target_size"])
			if target_size_value.size() != 2:
				return _fail("Placement %s target_size must have two integers." % placement_id)
			placement_size = _vector2i(target_size_value)
			if (
				placement_size.x <= 0
				or placement_size.y <= 0
				or placement_size.x > 256
				or placement_size.y > 256
			):
				return _fail("Placement %s target_size is outside 1-256 px." % placement_id)
		var cell_rect := Rect2i(position, placement_size)
		if proof_bounds.intersection(cell_rect) != cell_rect:
			return _fail("Placement %s leaves the proof canvas." % placement_id)
		var center := position + placement_size / 2
		if not _point_in_any_rect(center, Array(anchors[anchor])):
			return _fail("Placement %s is outside its declared anchor regions." % placement_id)
		var role := String(stamp["role"])
		if role in ["prop", "wear"]:
			if arena.intersection(cell_rect) != cell_rect or no_go.has_point(center):
				return _fail("Placement %s violates arena or center no-go." % placement_id)
			for blocked_anchor in ["cover", "bulkhead", "feature"]:
				if _point_in_any_rect(center, Array(anchors[blocked_anchor])):
					return _fail("Placement %s overlaps %s geometry." % [
						placement_id,
						blocked_anchor,
					])
		if role == "prop":
			prop_count += 1
		elif role == "wear":
			wear_centers.append(center)
		if bool(placement["landmark"]):
			if role != "structure":
				return _fail("Only structure placements may be landmarks.")
			landmark_count += 1
	var fixture_range := Array(layout["prop_fixture_range"])
	if prop_count < int(fixture_range[0]) or prop_count > int(fixture_range[1]):
		return _fail("Proof must place 6-10 prop fixtures.")
	if wear_centers.size() > 8:
		return _fail("Proof may place at most 8 wear stamps.")
	var minimum_spacing := int(layout["wear_min_spacing"])
	for first in wear_centers.size():
		for second in range(first + 1, wear_centers.size()):
			if (
				wear_centers[first].distance_squared_to(wear_centers[second])
				< minimum_spacing * minimum_spacing
			):
				return _fail("Wear placements are closer than %d px." % minimum_spacing)
	if landmark_count < int(layout["minimum_landmarks"]):
		return _fail("Proof does not declare enough boundary landmarks.")
	return true


func _validate_outputs_contract(outputs: Dictionary) -> bool:
	if not _require_exact_keys(
		outputs,
		["clean", "review", "proof_layers", "validation", "hashes"],
		"recipe.outputs"
	):
		return false
	if not outputs["clean"] is Dictionary:
		return _fail("recipe.outputs.clean must be an object.")
	if not outputs["review"] is Dictionary:
		return _fail("recipe.outputs.review must be an object.")
	if not outputs["proof_layers"] is Dictionary:
		return _fail("recipe.outputs.proof_layers must be an object.")
	if not _require_exact_keys(
		Dictionary(outputs["clean"]),
		[
			"deck_material_master",
			"wall_material_master",
			"void_material_master",
			"base_variant_atlas",
			"structure_atlas",
			"prop_atlas",
			"deck_repeat_master",
			"wall_repeat_master",
			"void_repeat_master",
		],
		"recipe.outputs.clean"
	):
		return false
	if not _require_exact_keys(
		Dictionary(outputs["review"]),
		[
			"base_variant_atlas_4x",
			"structure_atlas_4x",
			"prop_atlas_4x",
			"deck_seam_2x2",
			"deck_seam_3x3",
			"deck_seam_offset_20x12",
			"wall_seam_2x2",
			"wall_seam_3x3",
			"wall_seam_offset_20x12",
			"void_seam_2x2",
			"void_seam_3x3",
			"void_seam_offset_20x12",
			"side_by_side",
		],
		"recipe.outputs.review"
	):
		return false
	if not _require_exact_keys(
		Dictionary(outputs["proof_layers"]),
		["base", "structure", "wear", "props", "final"],
		"recipe.outputs.proof_layers"
	):
		return false
	var paths := _collect_output_paths(outputs)
	var seen := {}
	for path_variant in paths:
		var path := String(path_variant).replace("\\", "/")
		if (
			path.is_empty()
			or path.is_absolute_path()
			or path.begins_with("../")
			or "/../" in path
		):
			return _fail("Output paths must be safe relative paths: %s" % path)
		if seen.has(path):
			return _fail("Duplicate output path: %s" % path)
		seen[path] = true
		if path in [String(outputs["validation"]), String(outputs["hashes"])]:
			if path.get_extension().to_lower() != "json":
				return _fail("Validation and hash outputs must be JSON.")
		elif path.get_extension().to_lower() != "png":
			return _fail("Image output must be PNG: %s" % path)
	return true


func _load_and_validate_sources() -> bool:
	var sources := Dictionary(_recipe["sources"])
	if not _validate_source_manifest(sources):
		return false
	for key_variant in SOURCE_KEYS:
		var key := String(key_variant)
		var resource_path := "res://%s" % String(sources[key])
		var absolute_path := ProjectSettings.globalize_path(resource_path)
		_source_paths[key] = absolute_path
		if not FileAccess.file_exists(absolute_path):
			return _fail("Missing required source %s: %s" % [key, absolute_path])
		var image := Image.load_from_file(absolute_path)
		if image == null or image.is_empty():
			return _fail("Could not load required source %s: %s" % [key, absolute_path])
		image.convert(Image.FORMAT_RGBA8)
		if not _is_opaque(image):
			return _fail("Raw source %s must be fully opaque." % key)
		_source_images[key] = image
	var expected_sizes := {
		"full_map_target":_vector2i(Array(sources["full_map_size"])),
		"deck_material_master":_vector2i(Array(sources["material_source_size"])),
		"wall_material_master":_vector2i(Array(sources["material_source_size"])),
		"void_material_master":_vector2i(Array(sources["material_source_size"])),
		"structure_sheet":_vector2i(Array(sources["sheet_source_size"])),
		"prop_sheet":_vector2i(Array(sources["sheet_source_size"])),
	}
	for key_variant in SOURCE_KEYS:
		var key := String(key_variant)
		var image: Image = _source_images[key]
		if image.get_size() != Vector2i(expected_sizes[key]):
			return _fail(
				"Source %s must be %s, got %s."
				% [key, expected_sizes[key], image.get_size()]
			)
	for key in ["structure_sheet", "prop_sheet"]:
		if not _validate_sheet_cells(String(key), _source_images[key]):
			return false
	return true


func _validate_source_manifest(sources: Dictionary) -> bool:
	_source_manifest_path = ProjectSettings.globalize_path(
		"res://%s" % String(sources["source_manifest"])
	)
	if not FileAccess.file_exists(_source_manifest_path):
		return _fail("Missing source manifest: %s" % _source_manifest_path)
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(_source_manifest_path)
	)
	if not parsed is Dictionary:
		return _fail("Source manifest root must be a JSON object.")
	var manifest := Dictionary(parsed)
	if (
		int(manifest.get("schema_version", 0)) != 1
		or String(manifest.get("candidate_id", "")) != "space-hangar-v2"
	):
		return _fail("Source manifest identity does not match space-hangar-v2.")
	var assets_value: Variant = manifest.get("assets", [])
	if not assets_value is Array or Array(assets_value).size() != SOURCE_KEYS.size():
		return _fail("Source manifest must contain exactly six accepted assets.")
	var assets_by_id := {}
	for asset_value in Array(assets_value):
		if not asset_value is Dictionary:
			return _fail("Source manifest asset records must be objects.")
		var asset := Dictionary(asset_value)
		var asset_id := String(asset.get("id", ""))
		if asset_id.is_empty() or assets_by_id.has(asset_id):
			return _fail("Source manifest contains an empty or duplicate asset id.")
		assets_by_id[asset_id] = asset
	for key_variant in SOURCE_KEYS:
		var key := String(key_variant)
		var manifest_id := String(SOURCE_MANIFEST_IDS[key])
		if not assets_by_id.has(manifest_id):
			return _fail("Source manifest is missing accepted asset %s." % manifest_id)
		var record := Dictionary(assets_by_id[manifest_id])
		if (
			String(record.get("normalized_path", "")).replace("\\", "/")
			!= String(sources[key]).replace("\\", "/")
		):
			return _fail("Source manifest path mismatch for %s." % manifest_id)
		if not _validate_manifest_file_hash(
			record,
			"provider_copy",
			"provider_sha256",
			"accepted provider %s" % manifest_id
		):
			return false
		if not _validate_manifest_file_hash(
			record,
			"normalized_path",
			"normalized_sha256",
			"accepted normalized %s" % manifest_id
		):
			return false
		if not _validate_manifest_path_exists(
			String(record.get("prompt_path", "")),
			"accepted prompt %s" % manifest_id
		):
			return false
		var steps_value: Variant = record.get("normalization_steps", [])
		if not steps_value is Array or Array(steps_value).is_empty():
			return _fail(
				"Source manifest must record normalization steps for %s."
				% manifest_id
			)
	var references_value: Variant = manifest.get("references", [])
	if not references_value is Array or Array(references_value).size() != 2:
		return _fail("Source manifest must contain the two direction references.")
	for reference_value in Array(references_value):
		if not reference_value is Dictionary:
			return _fail("Source manifest reference records must be objects.")
		if not _validate_manifest_file_hash(
			Dictionary(reference_value),
			"workspace_path",
			"sha256",
			"direction reference"
		):
			return false
	var rejected_value: Variant = manifest.get("rejected_attempts", [])
	if not rejected_value is Array:
		return _fail("Source manifest rejected_attempts must be an array.")
	for rejected_asset_value in Array(rejected_value):
		if not rejected_asset_value is Dictionary:
			return _fail("Rejected source records must be objects.")
		var rejected := Dictionary(rejected_asset_value)
		var rejected_id := String(rejected.get("id", ""))
		if not _validate_manifest_file_hash(
			rejected,
			"provider_copy",
			"provider_sha256",
			"rejected provider %s" % rejected_id
		):
			return false
		if not _validate_manifest_file_hash(
			rejected,
			"normalized_copy",
			"normalized_sha256",
			"rejected normalized %s" % rejected_id
		):
			return false
		if not _validate_manifest_path_exists(
			String(rejected.get("prompt_path", "")),
			"rejected prompt %s" % rejected_id
		):
			return false
		var rejected_steps: Variant = rejected.get("normalization_steps", [])
		if not rejected_steps is Array or Array(rejected_steps).is_empty():
			return _fail(
				"Source manifest must record normalization steps for %s."
				% rejected_id
			)
	_source_manifest_sha256 = FileAccess.get_sha256(_source_manifest_path)
	return true


func _validate_manifest_file_hash(
	record: Dictionary,
	path_key: String,
	hash_key: String,
	label: String
) -> bool:
	var relative_path := String(record.get(path_key, "")).replace("\\", "/")
	if not _validate_manifest_path_exists(relative_path, label):
		return false
	var expected_hash := String(record.get(hash_key, "")).to_lower()
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	var actual_hash := FileAccess.get_sha256(absolute_path).to_lower()
	if expected_hash.length() != 64 or actual_hash != expected_hash:
		return _fail("Source manifest hash mismatch for %s." % label)
	return true


func _validate_manifest_path_exists(relative_path: String, label: String) -> bool:
	if (
		relative_path.is_empty()
		or relative_path.is_absolute_path()
		or relative_path.begins_with("../")
		or "/../" in relative_path
	):
		return _fail("Source manifest path is unsafe for %s." % label)
	var absolute_path := ProjectSettings.globalize_path("res://%s" % relative_path)
	if not FileAccess.file_exists(absolute_path):
		return _fail("Source manifest file is missing for %s." % label)
	return true


func _validate_sheet_cells(label: String, image: Image) -> bool:
	var clearance := int(Dictionary(_recipe["sources"])["cell_clearance_px"])
	var raw_cell_size := image.get_width() / 4
	for row in 4:
		for column in 4:
			var visible_pixels := 0
			var min_x := raw_cell_size
			var min_y := raw_cell_size
			var max_x := -1
			var max_y := -1
			for y in raw_cell_size:
				for x in raw_cell_size:
					var color := image.get_pixel(
						column * raw_cell_size + x,
						row * raw_cell_size + y
					)
					var chroma := _is_chroma(color)
					if not chroma:
						visible_pixels += 1
						min_x = mini(min_x, x)
						min_y = mini(min_y, y)
						max_x = maxi(max_x, x)
						max_y = maxi(max_y, y)
			if visible_pixels == 0:
				return _fail("%s cell [%d,%d] has no subject." % [label, column, row])
			if (
				min_x < clearance
				or min_y < clearance
				or max_x >= raw_cell_size - clearance
				or max_y >= raw_cell_size - clearance
			):
				return _fail(
					(
						"%s cell [%d,%d] violates the %d px chroma clearance "
						+ "with non-chroma bounds [%d,%d]-[%d,%d]."
					)
					% [
						label,
						column,
						row,
						clearance,
						min_x,
						min_y,
						max_x,
						max_y,
					]
				)
	return true


func _compile_and_publish() -> bool:
	if not _build_material_assets():
		return false
	_structure_atlas = _build_stamp_atlas("structure_sheet")
	if _structure_atlas == null or _structure_atlas.is_empty():
		return false
	_prop_atlas = _build_stamp_atlas("prop_sheet")
	if _prop_atlas == null or _prop_atlas.is_empty():
		return false
	var base_atlas := _build_base_variant_atlas()
	var repeat_masters := {}
	var seam_images := {}
	var seam_mismatch_count := 0
	var repeat_master_edge_mismatch_count := 0
	for family_id_variant in FAMILY_IDS:
		var family_id := String(family_id_variant)
		var repeat_master := _build_repeat_master(family_id)
		if repeat_master.get_size() != REPEAT_MASTER_SIZE:
			return _fail("Repeat master %s must be 192x192." % family_id)
		repeat_master_edge_mismatch_count += _count_opposite_edge_mismatches(repeat_master)
		repeat_masters[family_id] = repeat_master
		_family_repeat_masters[family_id] = repeat_master
		var seam_2x2 := _build_family_mosaic(family_id, Vector2i(2, 2), Vector2i.ZERO)
		var seam_3x3 := _build_family_mosaic(family_id, Vector2i(3, 3), Vector2i.ZERO)
		var seam_offset := _build_family_mosaic(
			family_id,
			Vector2i(20, 12),
			Vector2i(17, -11)
		)
		seam_images["%s_2x2" % family_id] = seam_2x2
		seam_images["%s_3x3" % family_id] = seam_3x3
		seam_images["%s_offset_20x12" % family_id] = seam_offset
		seam_mismatch_count += _count_mosaic_seam_mismatches(seam_2x2)
		seam_mismatch_count += _count_mosaic_seam_mismatches(seam_3x3)
		seam_mismatch_count += _count_mosaic_seam_mismatches(seam_offset)
	if seam_mismatch_count != 0:
		return _fail("Generated seam mosaics contain %d edge mismatches." % seam_mismatch_count)
	if repeat_master_edge_mismatch_count != 0:
		return _fail(
			"Generated repeat masters contain %d opposite-edge mismatches."
			% repeat_master_edge_mismatch_count
		)
	var proof := _build_proof_layers()
	if proof.is_empty():
		return false
	var base_proof: Image = proof["base"]
	var final_proof: Image = proof["final"]
	var wear_proof: Image = proof["wear"]
	var props_proof: Image = proof["props"]
	var recomposed := base_proof.duplicate()
	for layer_key in ["structure", "wear", "props"]:
		var layer: Image = proof[layer_key]
		recomposed.blend_rect(
			layer,
			Rect2i(Vector2i.ZERO, layer.get_size()),
			Vector2i.ZERO
		)
	var recomposition_mismatches := _pixel_mismatch_count(
		recomposed,
		final_proof
	)
	if recomposition_mismatches != 0:
		return _fail("Proof layer recomposition changed %d pixels." % recomposition_mismatches)
	var no_go := _rect2i(Array(Dictionary(_recipe["proof_layout"])["center_no_go"]))
	var no_go_pixels := (
		_opaque_pixels_in_rect(wear_proof, no_go)
		+ _opaque_pixels_in_rect(props_proof, no_go)
	)
	if no_go_pixels != 0:
		return _fail("Prop/wear layers contain %d center no-go pixels." % no_go_pixels)
	if not _is_opaque(base_proof) or not _is_opaque(final_proof):
		return _fail("Base and final proof layers must be fully opaque.")
	for layer_key in ["structure", "wear", "props"]:
		var proof_layer: Image = proof[layer_key]
		if _partial_alpha_pixel_count(proof_layer) != 0:
			return _fail("Proof layer %s contains partial alpha." % layer_key)
	var target: Image = _source_images["full_map_target"]
	var side_by_side := Image.create(
		target.get_width() * 2,
		target.get_height(),
		false,
		Image.FORMAT_RGBA8
	)
	side_by_side.fill(Color("#141B24"))
	side_by_side.blit_rect(
		target,
		Rect2i(Vector2i.ZERO, target.get_size()),
		Vector2i.ZERO
	)
	side_by_side.blit_rect(
		final_proof,
		Rect2i(Vector2i.ZERO, final_proof.get_size()),
		Vector2i(target.get_width(), 0)
	)
	var images := _assemble_output_images(
		base_atlas,
		repeat_masters,
		seam_images,
		proof,
		side_by_side
	)
	var checks := {
		"config_valid":true,
		"source_valid":true,
		"family_counts":{"deck":12, "wall":8, "void":4},
		"neutral_perimeter_px":TILE_EDGE,
		"sheet_cell_clearance_px":int(Dictionary(_recipe["sources"])["cell_clearance_px"]),
		"seam_mismatch_count":seam_mismatch_count,
		"repeat_master_edge_mismatch_count":repeat_master_edge_mismatch_count,
		"recomposition_mismatch_count":recomposition_mismatches,
		"center_no_go_overlay_pixels":no_go_pixels,
		"visible_geometry_source":"raster_tiles_and_recipe_declared_stamps",
	}
	return _write_staging_and_publish(images, checks)


func _build_material_assets() -> bool:
	for family_id_variant in FAMILY_IDS:
		var family_id := String(family_id_variant)
		var family := Dictionary(_family_specs[family_id])
		var source_key := String(family["source"])
		var source_image: Image = _source_images[source_key]
		var clean: Image = source_image.duplicate()
		clean.resize(
			LOGICAL_MATERIAL_SIZE.x,
			LOGICAL_MATERIAL_SIZE.y,
			Image.INTERPOLATE_NEAREST
		)
		var prequantize_sample_size := int(family["prequantize_sample_size"])
		if prequantize_sample_size < LOGICAL_MATERIAL_SIZE.x:
			clean.resize(
				prequantize_sample_size,
				prequantize_sample_size,
				Image.INTERPOLATE_LANCZOS
			)
			clean.resize(
				LOGICAL_MATERIAL_SIZE.x,
				LOGICAL_MATERIAL_SIZE.y,
				Image.INTERPOLATE_NEAREST
			)
		clean.convert(Image.FORMAT_RGBA8)
		var palette := _colors(Array(family["palette"]))
		for y in clean.get_height():
			for x in clean.get_width():
				clean.set_pixel(x, y, _nearest_palette_color(clean.get_pixel(x, y), palette))
		var variants: Array[Image] = []
		for window_variant in Array(family["sample_windows"]):
			var tile := clean.get_region(_rect2i(Array(window_variant)))
			_enforce_neutral_perimeter(
				tile,
				Color.from_string(String(family["neutral_color"]), Color.BLACK)
			)
			if not _validate_base_tile(tile, palette, String(family["neutral_color"])):
				return false
			variants.append(tile)
		if variants.size() != int(family["variant_count"]):
			return _fail("Base family %s produced the wrong variant count." % family_id)
		_family_clean_masters[family_id] = clean
		_family_variants[family_id] = variants
	return true


func _enforce_neutral_perimeter(
	tile: Image,
	neutral: Color,
	edge_width: int = TILE_EDGE
) -> void:
	for y in tile.get_height():
		for x in tile.get_width():
			if (
				x < edge_width
				or y < edge_width
				or x >= tile.get_width() - edge_width
				or y >= tile.get_height() - edge_width
			):
				tile.set_pixel(x, y, Color(neutral.r, neutral.g, neutral.b, 1.0))


func _build_repeat_master(family_id: String) -> Image:
	var clean: Image = _family_clean_masters[family_id]
	var inset := (clean.get_size() - REPEAT_MASTER_SIZE) / 2
	var master := clean.get_region(Rect2i(inset, REPEAT_MASTER_SIZE))
	var family := Dictionary(_family_specs[family_id])
	_enforce_neutral_perimeter(
		master,
		Color.from_string(String(family["neutral_color"]), Color.BLACK),
		1
	)
	return master


func _validate_base_tile(
	tile: Image,
	palette: Array[Color],
	neutral_string: String
) -> bool:
	if tile.get_size() != Vector2i(TILE_SIZE, TILE_SIZE):
		return _fail("Base tile has an invalid size: %s" % tile.get_size())
	var allowed := {}
	for color in palette:
		allowed[_color_key(color)] = true
	var neutral := Color.from_string(neutral_string, Color.BLACK)
	for y in tile.get_height():
		for x in tile.get_width():
			var color := tile.get_pixel(x, y)
			if color.a < 1.0 or not allowed.has(_color_key(color)):
				return _fail("Base tile contains alpha or an undeclared palette color.")
			if (
				x < TILE_EDGE
				or y < TILE_EDGE
				or x >= tile.get_width() - TILE_EDGE
				or y >= tile.get_height() - TILE_EDGE
			) and _color_key(color) != _color_key(neutral):
				return _fail("Base tile neutral perimeter validation failed.")
	return true


func _build_stamp_atlas(source_key: String) -> Image:
	var raw: Image = _source_images[source_key]
	var palette := _colors(Array(Dictionary(_recipe["sources"])["stamp_palette"]))
	var atlas := Image.create(
		STAMP_ATLAS_SIZE.x,
		STAMP_ATLAS_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	atlas.fill(Color(0.0, 0.0, 0.0, 0.0))
	var raw_cell_size := raw.get_width() / 4
	for row in 4:
		for column in 4:
			var cell := raw.get_region(
				Rect2i(
					Vector2i(column * raw_cell_size, row * raw_cell_size),
					Vector2i(raw_cell_size, raw_cell_size)
				)
			)
			cell.resize(STAMP_CELL_SIZE, STAMP_CELL_SIZE, Image.INTERPOLATE_NEAREST)
			cell.convert(Image.FORMAT_RGBA8)
			var visible_pixels := 0
			for y in cell.get_height():
				for x in cell.get_width():
					var source_color := cell.get_pixel(x, y)
					if _is_chroma(source_color):
						cell.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
					else:
						cell.set_pixel(
							x,
							y,
							_nearest_palette_color(source_color, palette)
						)
						visible_pixels += 1
			if visible_pixels == 0:
				_fail("%s logical cell [%d,%d] became empty." % [
					source_key,
					column,
					row,
				])
				return Image.new()
			var stamp_ids := STRUCTURE_IDS if source_key == "structure_sheet" else PROP_IDS
			var stamp_id := String(stamp_ids[row * 4 + column])
			var stamp := Dictionary(_stamp_catalog[stamp_id])
			var fit_contract := Dictionary(
				Dictionary(_recipe["sources"])["stamp_fit_long_axis_px"]
			)
			var fit_long_axis := int(fit_contract[String(stamp["role"])])
			cell = _fit_opaque_subject(
				cell,
				Vector2i(STAMP_CELL_SIZE, STAMP_CELL_SIZE),
				Vector2i(fit_long_axis, fit_long_axis)
			)
			atlas.blit_rect(
				cell,
				Rect2i(Vector2i.ZERO, cell.get_size()),
				Vector2i(column * STAMP_CELL_SIZE, row * STAMP_CELL_SIZE)
			)
	if _partial_alpha_pixel_count(atlas) != 0:
		_fail("%s output contains partial alpha." % source_key)
		return Image.new()
	return atlas


func _build_base_variant_atlas() -> Image:
	var atlas := Image.create(
		BASE_ATLAS_SIZE.x,
		BASE_ATLAS_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	atlas.fill(Color("#141B24"))
	var deck: Array = _family_variants["deck"]
	var wall: Array = _family_variants["wall"]
	var void_tiles: Array = _family_variants["void"]
	for index in deck.size():
		_blit_full(atlas, deck[index], Vector2i(index * TILE_SIZE, 0))
	for index in wall.size():
		_blit_full(atlas, wall[index], Vector2i(index * TILE_SIZE, TILE_SIZE))
	for index in void_tiles.size():
		_blit_full(
			atlas,
			void_tiles[index],
			Vector2i((8 + index) * TILE_SIZE, TILE_SIZE)
		)
	return atlas


func _build_family_mosaic(
	family_id: String,
	grid_size: Vector2i,
	coordinate_offset: Vector2i
) -> Image:
	var image := Image.create(
		grid_size.x * TILE_SIZE,
		grid_size.y * TILE_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(Color("#141B24"))
	for y in grid_size.y:
		for x in grid_size.x:
			var tile := _tile_for_coordinate(
				family_id,
				x + coordinate_offset.x,
				y + coordinate_offset.y
			)
			_blit_full(image, tile, Vector2i(x * TILE_SIZE, y * TILE_SIZE))
	return image


func _tile_for_coordinate(family_id: String, x: int, y: int) -> Image:
	var family_index := FAMILY_IDS.find(family_id)
	var variants: Array = _family_variants[family_id]
	var family := Dictionary(_family_specs[family_id])
	var hash_value := _hash4(x, y, family_index, 104729)
	var source_tile: Image = variants[hash_value % variants.size()]
	var tile: Image = source_tile.duplicate()
	var transforms := Array(family["allowed_transforms"])
	var transform_hash := _hash4(x, y, family_index, 130363)
	return _transform_image(tile, String(transforms[transform_hash % transforms.size()]))


func _build_proof_layers() -> Dictionary:
	var layout := Dictionary(_recipe["proof_layout"])
	var proof_size := _vector2i(Array(layout["size"]))
	var base := Image.create(proof_size.x, proof_size.y, false, Image.FORMAT_RGBA8)
	base.fill(Color("#141B24"))
	for region_variant in Array(layout["base_regions"]):
		var region := Dictionary(region_variant)
		_blit_tiled_region(
			base,
			String(region["family"]),
			_rect2i(Array(region["rect"]))
		)
	var structure := _transparent_image(proof_size)
	var wear := _transparent_image(proof_size)
	var props := _transparent_image(proof_size)
	for placement_variant in Array(layout["placements"]):
		var placement := Dictionary(placement_variant)
		var stamp := Dictionary(_stamp_catalog[String(placement["stamp_id"])])
		var atlas := _structure_atlas if String(stamp["role"]) == "structure" else _prop_atlas
		var cell := _vector2i(Array(stamp["cell"]))
		var stamp_image := atlas.get_region(
			Rect2i(cell * STAMP_CELL_SIZE, Vector2i(STAMP_CELL_SIZE, STAMP_CELL_SIZE))
		)
		stamp_image = _transform_image(
			stamp_image,
			String(placement["transform"])
		)
		if placement.has("target_size"):
			var target_size := _vector2i(Array(placement["target_size"]))
			stamp_image = _fit_opaque_subject(
				stamp_image,
				target_size,
				Vector2i(
					maxi(1, target_size.x - 4),
					maxi(1, target_size.y - 4)
				)
			)
		var target := structure
		match String(stamp["role"]):
			"wear":
				target = wear
			"prop":
				target = props
		target.blend_rect(
			stamp_image,
			Rect2i(Vector2i.ZERO, stamp_image.get_size()),
			_vector2i(Array(placement["position"]))
		)
	var final := base.duplicate()
	for layer in [structure, wear, props]:
		final.blend_rect(
			layer,
			Rect2i(Vector2i.ZERO, proof_size),
			Vector2i.ZERO
		)
	return {
		"base":base,
		"structure":structure,
		"wear":wear,
		"props":props,
		"final":final,
	}


func _blit_tiled_region(target: Image, family_id: String, region: Rect2i) -> void:
	var repeat_master: Image = _family_repeat_masters[family_id]
	var proof_master := _nearest_scaled(repeat_master, PROOF_REPEAT_SCALE)
	var first_x := floori(float(region.position.x) / float(PROOF_REPEAT_SIZE.x))
	var first_y := floori(float(region.position.y) / float(PROOF_REPEAT_SIZE.y))
	var last_x := ceili(float(region.end.x) / float(PROOF_REPEAT_SIZE.x))
	var last_y := ceili(float(region.end.y) / float(PROOF_REPEAT_SIZE.y))
	for cell_y in range(first_y, last_y):
		for cell_x in range(first_x, last_x):
			var destination := Vector2i(
				cell_x * PROOF_REPEAT_SIZE.x,
				cell_y * PROOF_REPEAT_SIZE.y
			)
			var destination_rect := Rect2i(
				destination,
				PROOF_REPEAT_SIZE
			).intersection(region)
			if destination_rect.has_area():
				var source_rect := Rect2i(
					destination_rect.position - destination,
					destination_rect.size
				)
				target.blit_rect(
					proof_master,
					source_rect,
					destination_rect.position
				)


func _assemble_output_images(
	base_atlas: Image,
	repeat_masters: Dictionary,
	seam_images: Dictionary,
	proof: Dictionary,
	side_by_side: Image
) -> Dictionary:
	var outputs := Dictionary(_recipe["outputs"])
	var clean := Dictionary(outputs["clean"])
	var review := Dictionary(outputs["review"])
	var proof_outputs := Dictionary(outputs["proof_layers"])
	var images := {}
	images[String(clean["deck_material_master"])] = _family_clean_masters["deck"]
	images[String(clean["wall_material_master"])] = _family_clean_masters["wall"]
	images[String(clean["void_material_master"])] = _family_clean_masters["void"]
	images[String(clean["base_variant_atlas"])] = base_atlas
	images[String(clean["structure_atlas"])] = _structure_atlas
	images[String(clean["prop_atlas"])] = _prop_atlas
	images[String(clean["deck_repeat_master"])] = repeat_masters["deck"]
	images[String(clean["wall_repeat_master"])] = repeat_masters["wall"]
	images[String(clean["void_repeat_master"])] = repeat_masters["void"]
	images[String(review["base_variant_atlas_4x"])] = _nearest_scaled(base_atlas, 4)
	images[String(review["structure_atlas_4x"])] = _nearest_scaled(_structure_atlas, 4)
	images[String(review["prop_atlas_4x"])] = _nearest_scaled(_prop_atlas, 4)
	for family_id_variant in FAMILY_IDS:
		var family_id := String(family_id_variant)
		images[String(review["%s_seam_2x2" % family_id])] = seam_images["%s_2x2" % family_id]
		images[String(review["%s_seam_3x3" % family_id])] = seam_images["%s_3x3" % family_id]
		images[String(review["%s_seam_offset_20x12" % family_id])] = (
			seam_images["%s_offset_20x12" % family_id]
		)
	images[String(review["side_by_side"])] = side_by_side
	for layer_key in ["base", "structure", "wear", "props", "final"]:
		images[String(proof_outputs[layer_key])] = proof[layer_key]
	return images


func _write_staging_and_publish(images: Dictionary, checks: Dictionary) -> bool:
	var parent := _output_directory.get_base_dir()
	var make_parent_error := DirAccess.make_dir_recursive_absolute(parent)
	if make_parent_error != OK:
		return _fail("Could not create output parent: %s" % error_string(make_parent_error))
	var make_staging_error := DirAccess.make_dir_recursive_absolute(_staging_directory)
	if make_staging_error != OK:
		return _fail("Could not create staging output: %s" % error_string(make_staging_error))
	_write_directory = _staging_directory
	var image_paths: Array = images.keys()
	image_paths.sort()
	var output_records: Array[Dictionary] = []
	for path_variant in image_paths:
		var relative_path := String(path_variant)
		var image: Image = images[relative_path]
		var record := _save_png(relative_path, image)
		if record.is_empty():
			return false
		output_records.append(record)
	var source_records: Array[Dictionary] = []
	for key_variant in SOURCE_KEYS:
		var key := String(key_variant)
		var image: Image = _source_images[key]
		source_records.append({
			"id":key,
			"path":String(Dictionary(_recipe["sources"])[key]),
			"size":[image.get_width(), image.get_height()],
			"sha256":FileAccess.get_sha256(String(_source_paths[key])),
		})
	var validation := {
		"generator":GENERATOR_PATH,
		"generator_sha256":FileAccess.get_sha256(
			ProjectSettings.globalize_path(GENERATOR_PATH)
		),
		"schema_version":int(_recipe["schema_version"]),
		"schema":{
			"path":SCHEMA_PATH.trim_prefix("res://"),
			"sha256":_schema_sha256,
		},
		"seed":_seed,
		"recipe_sha256":FileAccess.get_sha256(_recipe_path),
		"source_manifest":{
			"path":String(Dictionary(_recipe["sources"])["source_manifest"]),
			"sha256":_source_manifest_sha256,
		},
		"sources":source_records,
		"checks":checks,
		"outputs":output_records,
	}
	var outputs := Dictionary(_recipe["outputs"])
	var validation_relative := String(outputs["validation"])
	if not _write_json(_output_path(validation_relative), validation):
		return false
	var hash_records: Array[Dictionary] = []
	hash_records.append({
		"path":validation_relative,
		"sha256":FileAccess.get_sha256(_output_path(validation_relative)),
	})
	for record in output_records:
		hash_records.append({
			"path":String(record["path"]),
			"sha256":String(record["sha256"]),
		})
	hash_records.sort_custom(
		func(first: Dictionary, second: Dictionary) -> bool:
			return String(first["path"]) < String(second["path"])
	)
	var hashes := {
		"algorithm":"sha256",
		"generator":GENERATOR_PATH,
		"recipe":{
			"path":_recipe_path,
			"sha256":FileAccess.get_sha256(_recipe_path),
		},
		"schema":{
			"path":SCHEMA_PATH.trim_prefix("res://"),
			"sha256":_schema_sha256,
		},
		"source_manifest":{
			"path":String(Dictionary(_recipe["sources"])["source_manifest"]),
			"sha256":_source_manifest_sha256,
		},
		"sources":source_records,
		"outputs":hash_records,
	}
	if not _write_json(_output_path(String(outputs["hashes"])), hashes):
		return false
	return _publish_staged_output()


func _save_png(relative_path: String, image: Image) -> Dictionary:
	var path := _output_path(relative_path)
	var make_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if make_error != OK:
		_fail("Could not create output directory for %s." % relative_path)
		return {}
	var save_error := image.save_png(path)
	if save_error != OK:
		_fail("Could not save %s: %s" % [path, error_string(save_error)])
		return {}
	return {
		"path":relative_path,
		"size":[image.get_width(), image.get_height()],
		"sha256":FileAccess.get_sha256(path),
	}


func _write_json(path: String, value: Variant) -> bool:
	var make_error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if make_error != OK:
		return _fail("Could not create JSON output directory: %s" % path)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _fail("Could not write JSON output: %s" % path)
	file.store_string(JSON.stringify(value, "\t", true) + "\n")
	return true


func _publish_staged_output() -> bool:
	if (
		DirAccess.dir_exists_absolute(_output_directory)
		and not _is_owned_candidate_directory(_output_directory)
	):
		return _fail(
			"Existing output is not a verified candidate directory: %s"
			% _output_directory
		)
	var moved_previous := false
	if DirAccess.dir_exists_absolute(_output_directory):
		var backup_error := DirAccess.rename_absolute(
			_output_directory,
			_backup_directory
		)
		if backup_error != OK:
			return _fail("Could not preserve previous candidate output.")
		moved_previous = true
	var publish_error := DirAccess.rename_absolute(
		_staging_directory,
		_output_directory
	)
	if publish_error != OK:
		if moved_previous:
			var rollback_error := DirAccess.rename_absolute(
				_backup_directory,
				_output_directory
			)
			if rollback_error != OK:
				return _fail(
					"Publish and prior-output rollback both failed: %s / %s"
					% [error_string(publish_error), error_string(rollback_error)]
				)
		return _fail("Could not publish staged candidate output.")
	_write_directory = _output_directory
	if moved_previous and not _remove_owned_tree(_backup_directory, true):
		push_warning("Previous candidate backup remains: %s" % _backup_directory)
	return true


func _is_owned_candidate_directory(directory: String) -> bool:
	var validation_name := String(Dictionary(_recipe["outputs"])["validation"])
	var marker_path := directory.path_join(validation_name)
	if not FileAccess.file_exists(marker_path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(marker_path))
	if (
		not parsed is Dictionary
		or String(Dictionary(parsed).get("generator", "")) != GENERATOR_PATH
	):
		return false
	var expected := _collect_output_paths(Dictionary(_recipe["outputs"]))
	var actual := _directory_inventory(directory, directory)
	expected.sort()
	actual.sort()
	return _array_equals(actual, expected)


func _directory_inventory(root: String, directory: String) -> Array:
	var result := []
	var access := DirAccess.open(directory)
	if access == null:
		return result
	for file_name in access.get_files():
		result.append(
			directory.path_join(file_name).trim_prefix(root).trim_prefix("/")
		)
	for child in access.get_directories():
		result.append_array(
			_directory_inventory(root, directory.path_join(child))
		)
	return result


func _discard_staging_output() -> void:
	if DirAccess.dir_exists_absolute(_staging_directory):
		if not _remove_owned_tree(_staging_directory, false):
			push_warning("Could not fully remove failed staging output: %s" % _staging_directory)


func _remove_owned_tree(directory: String, require_marker: bool) -> bool:
	if not DirAccess.dir_exists_absolute(directory):
		return true
	if require_marker and not _is_owned_candidate_directory(directory):
		return false
	if (
		not require_marker
		and not directory.ends_with(STAGING_SUFFIX)
	):
		return false
	var access := DirAccess.open(directory)
	if access == null:
		return false
	for child in access.get_directories():
		if not _remove_tree_contents(directory.path_join(child)):
			return false
	for file_name in access.get_files():
		if DirAccess.remove_absolute(directory.path_join(file_name)) != OK:
			return false
	return DirAccess.remove_absolute(directory) == OK


func _remove_tree_contents(directory: String) -> bool:
	var access := DirAccess.open(directory)
	if access == null:
		return false
	for child in access.get_directories():
		if not _remove_tree_contents(directory.path_join(child)):
			return false
	for file_name in access.get_files():
		if DirAccess.remove_absolute(directory.path_join(file_name)) != OK:
			return false
	return DirAccess.remove_absolute(directory) == OK


func _count_mosaic_seam_mismatches(image: Image) -> int:
	var mismatches := 0
	for seam_x in range(TILE_SIZE, image.get_width(), TILE_SIZE):
		for y in image.get_height():
			mismatches += int(
				_color_key(image.get_pixel(seam_x - 1, y))
				!= _color_key(image.get_pixel(seam_x, y))
			)
	for seam_y in range(TILE_SIZE, image.get_height(), TILE_SIZE):
		for x in image.get_width():
			mismatches += int(
				_color_key(image.get_pixel(x, seam_y - 1))
				!= _color_key(image.get_pixel(x, seam_y))
			)
	return mismatches


func _count_opposite_edge_mismatches(image: Image) -> int:
	var mismatches := 0
	var last_x := image.get_width() - 1
	var last_y := image.get_height() - 1
	for y in image.get_height():
		mismatches += int(
			_color_key(image.get_pixel(0, y))
			!= _color_key(image.get_pixel(last_x, y))
		)
	for x in image.get_width():
		mismatches += int(
			_color_key(image.get_pixel(x, 0))
			!= _color_key(image.get_pixel(x, last_y))
		)
	return mismatches


func _pixel_mismatch_count(first: Image, second: Image) -> int:
	if first.get_size() != second.get_size():
		return maxi(first.get_width() * first.get_height(), second.get_width() * second.get_height())
	var mismatches := 0
	for y in first.get_height():
		for x in first.get_width():
			mismatches += int(
				first.get_pixel(x, y).to_rgba32()
				!= second.get_pixel(x, y).to_rgba32()
			)
	return mismatches


func _opaque_pixels_in_rect(image: Image, rect: Rect2i) -> int:
	var count := 0
	var clipped := rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			count += int(image.get_pixel(x, y).a > 0.0)
	return count


func _fit_opaque_subject(
	image: Image,
	canvas_size: Vector2i,
	max_subject_size: Vector2i
) -> Image:
	var bounds := _opaque_bounds(image)
	if not bounds.has_area():
		return Image.new()
	var cropped := image.get_region(bounds)
	var scale := minf(
		float(max_subject_size.x) / float(bounds.size.x),
		float(max_subject_size.y) / float(bounds.size.y)
	)
	var fitted_size := Vector2i(
		clampi(roundi(float(bounds.size.x) * scale), 1, canvas_size.x),
		clampi(roundi(float(bounds.size.y) * scale), 1, canvas_size.y)
	)
	cropped.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_NEAREST)
	var fitted := _transparent_image(canvas_size)
	fitted.blit_rect(
		cropped,
		Rect2i(Vector2i.ZERO, cropped.get_size()),
		(canvas_size - fitted_size) / 2
	)
	return fitted


func _opaque_bounds(image: Image) -> Rect2i:
	var minimum := image.get_size()
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.0:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _partial_alpha_pixel_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var alpha := image.get_pixel(x, y).a
			count += int(alpha > 0.0 and alpha < 1.0)
	return count


func _is_opaque(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 1.0:
				return false
	return true


func _is_chroma(color: Color) -> bool:
	var predicate := Dictionary(Dictionary(_recipe["sources"])["chroma_predicate"])
	var red := roundi(color.r * 255.0)
	var green := roundi(color.g * 255.0)
	var blue := roundi(color.b * 255.0)
	var dominance := int(predicate["dominance_min"])
	var bright_key := (
		red >= int(predicate["red_min"])
		and blue >= int(predicate["blue_min"])
		and green <= int(predicate["green_max"])
		and red - green >= dominance
		and blue - green >= dominance
	)
	var fringe_floor := int(predicate["fringe_value_min"])
	var fringe_key := (
		red >= fringe_floor
		and blue >= fringe_floor
		and green
		<= mini(red, blue) * float(predicate["fringe_green_ratio_max"])
		and absi(red - blue) <= int(predicate["fringe_rb_delta_max"])
	)
	return bright_key or fringe_key


func _nearest_palette_color(color: Color, palette: Array[Color]) -> Color:
	var best := palette[0]
	var best_distance := INF
	for candidate in palette:
		var red := color.r - candidate.r
		var green := color.g - candidate.g
		var blue := color.b - candidate.b
		var distance := red * red + green * green + blue * blue
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return Color(best.r, best.g, best.b, 1.0)


func _transform_image(image: Image, transform: String) -> Image:
	var result := image.duplicate()
	match transform:
		"flip_h":
			result.flip_x()
		"flip_v":
			result.flip_y()
		"rotate_180":
			result.flip_x()
			result.flip_y()
	return result


func _nearest_scaled(image: Image, factor: int) -> Image:
	var result := image.duplicate()
	result.resize(
		image.get_width() * factor,
		image.get_height() * factor,
		Image.INTERPOLATE_NEAREST
	)
	return result


func _transparent_image(size: Vector2i) -> Image:
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	return image


func _blit_full(target: Image, source: Image, position: Vector2i) -> void:
	target.blit_rect(
		source,
		Rect2i(Vector2i.ZERO, source.get_size()),
		position
	)


func _hash4(first: int, second: int, third: int, fourth: int) -> int:
	var value := posmod(_seed, HASH_MODULUS)
	for component in [first, second, third, fourth]:
		value = _mix_hash(value, int(component))
	return value


func _mix_hash(value: int, component: int) -> int:
	var normalized := posmod(component, HASH_MODULUS)
	var mixed := posmod(value + normalized * 374761393, HASH_MODULUS)
	mixed = posmod((mixed ^ (mixed >> 13)) * 1274126177, HASH_MODULUS)
	return posmod(mixed ^ (mixed >> 16), HASH_MODULUS)


func _require_exact_keys(
	value: Dictionary,
	expected_keys: Array,
	context: String
) -> bool:
	if value.size() != expected_keys.size():
		return _fail("%s has missing or undeclared keys." % context)
	for key_variant in expected_keys:
		var key := String(key_variant)
		if not value.has(key):
			return _fail("%s is missing required key %s." % [context, key])
	for key_variant in value.keys():
		if not String(key_variant) in expected_keys:
			return _fail("%s contains undeclared key %s." % [context, key_variant])
	return true


func _validate_color_list(colors: Array, context: String) -> bool:
	var seen := {}
	for color_variant in colors:
		var value := String(color_variant).to_upper()
		if not value.is_valid_html_color() or value.length() != 7:
			return _fail("%s contains invalid color %s." % [context, value])
		if seen.has(value):
			return _fail("%s contains duplicate color %s." % [context, value])
		seen[value] = true
	return true


func _collect_output_paths(value: Variant) -> Array:
	var result := []
	if value is Dictionary:
		var keys := Dictionary(value).keys()
		keys.sort()
		for key in keys:
			result.append_array(_collect_output_paths(Dictionary(value)[key]))
	elif value is String:
		result.append(String(value))
	return result


func _colors(values: Array) -> Array[Color]:
	var result: Array[Color] = []
	for value in values:
		result.append(Color.from_string(String(value), Color.BLACK))
	return result


func _valid_rect_array(value: Array) -> bool:
	return (
		value.size() == 4
		and int(value[2]) > 0
		and int(value[3]) > 0
	)


func _vector2i(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))


func _rect2i(value: Array) -> Rect2i:
	return Rect2i(
		int(value[0]),
		int(value[1]),
		int(value[2]),
		int(value[3])
	)


func _point_in_any_rect(point: Vector2i, rectangles: Array) -> bool:
	for rect_value in rectangles:
		if _rect2i(Array(rect_value)).has_point(point):
			return true
	return false


func _array_equals(first: Array, second: Array) -> bool:
	if first.size() != second.size():
		return false
	for index in first.size():
		if first[index] != second[index]:
			return false
	return true


func _nested_array_equals(first: Array, second: Array) -> bool:
	if first.size() != second.size():
		return false
	for index in first.size():
		if not first[index] is Array or not second[index] is Array:
			return false
		if not _array_equals(Array(first[index]), Array(second[index])):
			return false
	return true


func _color_key(color: Color) -> int:
	var red := clampi(roundi(color.r * 255.0), 0, 255)
	var green := clampi(roundi(color.g * 255.0), 0, 255)
	var blue := clampi(roundi(color.b * 255.0), 0, 255)
	return (red << 16) | (green << 8) | blue


func _output_path(relative_path: String) -> String:
	return _write_directory.path_join(relative_path)


func _fail(message: String) -> bool:
	_last_error = message
	push_error(message)
	return false
