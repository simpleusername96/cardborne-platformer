extends SceneTree

## Offline, deterministic material proof builder for the approved space-hangar
## reference. Base pixels come from quantized source neighborhoods; authored
## arena geometry and decorative marks remain inspectable in separate layers.

const GENERATOR_PATH := "res://tools/design/synthesize_world_material.gd"
const TILE_SIZE := 24
const EDGE_WIDTH := 1
const EXEMPLAR_SIZE := 48
const PROOF_SIZE := Vector2i(1280, 720)
const FLOOR_VARIANTS := 3
const WALL_VARIANTS := 2
const VOID_VARIANTS := 2
const SIGNATURE_COUNT := 16
const SYNTHESIS_SWEEPS := 10
const RELAXATION_SWEEPS := 3
const HASH_MODULUS := 2147483647
const DEFAULT_SEED := 472013
const STAGING_SUFFIX := ".cardborne-world-material-staging"
const BACKUP_SUFFIX := ".cardborne-world-material-previous"

const PREFERRED_FLOOR_CROP := Rect2i(494, 575, 96, 96)
const PREFERRED_WALL_CROP := Rect2i(260, 65, 240, 96)
const PREFERRED_VOID_CROP := Rect2i(0, 150, 120, 600)
const ARENA_RECT := Rect2i(156, 106, 968, 514)
const CENTRAL_NO_GO := Rect2i(500, 250, 280, 250)
const BULKHEAD_RECTS := [
	Rect2i(426, 335, 24, 54),
	Rect2i(829, 335, 24, 54),
]
const SURGE_BAY_RECTS := [
	Rect2i(284, 334, 110, 53),
	Rect2i(886, 334, 110, 53),
]
const COVER_RECTS := [
	Rect2i(445, 251, 38, 28),
	Rect2i(694, 188, 42, 26),
	Rect2i(763, 151, 43, 26),
	Rect2i(904, 208, 48, 28),
	Rect2i(603, 508, 40, 26),
	Rect2i(763, 545, 44, 26),
	Rect2i(904, 486, 48, 28),
	Rect2i(232, 529, 44, 26),
]
const APPROVED_OVERLAY_ACCENTS := [
	Color("#3E91B7"),
	Color("#75C4B2"),
	Color("#D9A83D"),
]
const APPROVED_WALL_BASE := [
	Color("#070D16"),
	Color("#131B24"),
	Color("#1C252D"),
	Color("#252D35"),
]
const APPROVED_VOID_BASE := [
	Color("#050B14"),
	Color("#070D16"),
]

const OUTPUT_NAMES := {
	"exemplar":"00-quantized-exemplar.png",
	"atlas":"01-wang-atlas.png",
	"base":"02-map-base.png",
	"overlays":"03-map-overlays.png",
	"structure":"03a-structure-overlay.png",
	"wear":"03b-wear-overlay.png",
	"props":"03c-prop-overlay.png",
	"final":"04-map-final.png",
	"proof":"world-material-proof.json",
}

var _source_path := ""
var _output_directory := ""
var _write_directory := ""
var _staging_directory := ""
var _backup_directory := ""
var _seed := DEFAULT_SEED
var _force_output := false
var _generation_failed := false
var _proof_validation: Dictionary = {}

var _floor_crop := Rect2i()
var _wall_crop := Rect2i()
var _void_crop := Rect2i()

var _floor_palette: Array[Color] = []
var _wall_palette: Array[Color] = []
var _void_palette: Array[Color] = []
var _accent_palette: Array[Color] = []

var _floor_exemplar: Image
var _wall_exemplar: Image
var _void_exemplar: Image
var _floor_model: Dictionary = {}
var _wall_model: Dictionary = {}
var _void_model: Dictionary = {}

var _floor_tiles: Array[Image] = []
var _wall_tiles: Array[Image] = []
var _void_tiles: Array[Image] = []
var _wear_positions: Array[Vector2i] = []
var _prop_positions: Array[Vector2i] = []


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
	_source_path = String(arguments["source"])
	_output_directory = String(arguments["output"])
	_seed = int(arguments["seed"])
	_force_output = bool(arguments["force"])
	if not _validate_paths():
		quit(2)
		return

	var source := Image.load_from_file(_source_path)
	if source == null or source.is_empty():
		_fail("Could not load approved source PNG: %s" % _source_path)
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	if source.get_width() < EXEMPLAR_SIZE or source.get_height() < EXEMPLAR_SIZE:
		_fail("Approved source must be at least %dx%d pixels." % [
			EXEMPLAR_SIZE,
			EXEMPLAR_SIZE,
		])
		quit(1)
		return

	_resolve_source_crops(source.get_size())
	_build_palettes_and_exemplars(source)
	if _generation_failed:
		quit(1)
		return
	_floor_model = _build_neighborhood_model(_floor_exemplar, _floor_palette)
	_wall_model = _build_neighborhood_model(_wall_exemplar, _wall_palette)
	_void_model = _build_neighborhood_model(_void_exemplar, _void_palette)
	if _generation_failed:
		quit(1)
		return

	_floor_tiles = _build_tile_family(
		_floor_model,
		FLOOR_VARIANTS,
		11003
	)
	_wall_tiles = _build_tile_family(
		_wall_model,
		WALL_VARIANTS,
		27011
	)
	_void_tiles = _build_void_tiles()
	if not _validate_material_outputs():
		quit(1)
		return

	var exemplar_board := _build_exemplar_board()
	var atlas := _build_atlas()
	var base := _build_map_base()
	var structure := _build_structure_overlay()
	var wear := _build_wear_overlay()
	var props := _build_prop_overlay()
	var overlays := _combine_layers([structure, wear, props])
	var final := base.duplicate()
	final.blend_rect(
		overlays,
		Rect2i(Vector2i.ZERO, PROOF_SIZE),
		Vector2i.ZERO
	)
	_proof_validation = _validate_proof_layers(
		base,
		structure,
		wear,
		props,
		overlays,
		final
	)
	if not bool(_proof_validation.get("valid", false)):
		quit(1)
		return

	var output_records := {}
	var images := {
		"exemplar":exemplar_board,
		"atlas":atlas,
		"base":base,
		"overlays":overlays,
		"structure":structure,
		"wear":wear,
		"props":props,
		"final":final,
	}
	if not _prepare_staging_directory():
		quit(1)
		return
	for key_variant in [
		"exemplar",
		"atlas",
		"base",
		"overlays",
		"structure",
		"wear",
		"props",
		"final",
	]:
		var key := String(key_variant)
		var image: Image = images[key]
		var record := _save_png(String(OUTPUT_NAMES[key]), image)
		if record.is_empty():
			_discard_staging_output()
			quit(1)
			return
		output_records[key] = record

	var proof := _build_proof_record(source, output_records, wear, props)
	var proof_path := _output_path(String(OUTPUT_NAMES["proof"]))
	if not _write_json(proof_path, proof):
		_discard_staging_output()
		quit(1)
		return
	if not _publish_staged_output():
		_discard_staging_output()
		quit(1)
		return
	print(
		"WORLD_MATERIAL_PROOF_OK seed=%d output=%s"
		% [_seed, _output_directory]
	)
	quit(0)


func _parse_arguments() -> Dictionary:
	var values := {
		"source":"",
		"output":"",
		"seed":DEFAULT_SEED,
		"force":false,
		"help":false,
		"valid":true,
	}
	var arguments := OS.get_cmdline_user_args()
	var index := 0
	while index < arguments.size():
		var argument := String(arguments[index])
		if argument in ["--help", "-h"]:
			values["help"] = true
			index += 1
			continue
		if argument == "--force":
			values["force"] = true
			index += 1
			continue
		if argument.begins_with("--source="):
			values["source"] = argument.trim_prefix("--source=")
		elif argument.begins_with("--output="):
			values["output"] = argument.trim_prefix("--output=")
		elif argument.begins_with("--seed="):
			var seed_value := argument.trim_prefix("--seed=")
			if not seed_value.is_valid_int():
				push_error("--seed must be an integer.")
				values["valid"] = false
			else:
				values["seed"] = int(seed_value)
		elif argument in ["--source", "--output", "--seed"]:
			if index + 1 >= arguments.size():
				push_error("%s requires a value." % argument)
				values["valid"] = false
			else:
				index += 1
				var value := String(arguments[index])
				match argument:
					"--source":
						values["source"] = value
					"--output":
						values["output"] = value
					"--seed":
						if not value.is_valid_int():
							push_error("--seed must be an integer.")
							values["valid"] = false
						else:
							values["seed"] = int(value)
		else:
			push_error("Unknown world material argument: %s" % argument)
			values["valid"] = false
		index += 1
	if not bool(values["help"]):
		if String(values["source"]).is_empty():
			push_error("Missing required --source argument.")
			values["valid"] = false
		if String(values["output"]).is_empty():
			push_error("Missing required --output argument.")
			values["valid"] = false
	return values


func _print_usage() -> void:
	print(
		(
			"Usage: godot --headless --script %s -- "
			+ "--source <absolute-approved.png> --output <directory> "
			+ "[--seed <integer>] [--force]"
		)
		% GENERATOR_PATH
	)


func _validate_paths() -> bool:
	if not _source_path.is_absolute_path():
		_fail("--source must be an absolute filesystem path.")
		return false
	if _source_path.get_extension().to_lower() != "png":
		_fail("--source must point to a PNG file.")
		return false
	if not FileAccess.file_exists(_source_path):
		_fail("Approved source PNG does not exist: %s" % _source_path)
		return false
	if not _output_directory.is_absolute_path():
		_fail("--output must be an absolute filesystem path.")
		return false
	var output_parent := _output_directory.get_base_dir()
	var make_error := DirAccess.make_dir_recursive_absolute(output_parent)
	if make_error != OK:
		_fail(
			"Could not create output parent directory: %s (%s)"
			% [output_parent, error_string(make_error)]
		)
		return false
	if FileAccess.file_exists(_output_directory):
		_fail("--output points to a file: %s" % _output_directory)
		return false
	_staging_directory = _output_directory + STAGING_SUFFIX
	_backup_directory = _output_directory + BACKUP_SUFFIX
	for reserved_path in [_staging_directory, _backup_directory]:
		if (
			FileAccess.file_exists(reserved_path)
			or DirAccess.dir_exists_absolute(reserved_path)
		):
			_fail(
				"Reserved publish path already exists; inspect it before retrying: %s"
				% reserved_path
			)
			return false
	if not DirAccess.dir_exists_absolute(_output_directory):
		return true
	return _validate_existing_output_directory()


func _validate_existing_output_directory() -> bool:
	if not DirAccess.dir_exists_absolute(_output_directory):
		return true
	var output_access := DirAccess.open(_output_directory)
	if output_access == null:
		_fail("Could not inspect output directory: %s" % _output_directory)
		return false
	var existing_files := output_access.get_files()
	var existing_directories := output_access.get_directories()
	if existing_files.is_empty() and existing_directories.is_empty():
		return true
	if not _force_output:
		_fail(
			"Output directory is not empty; use --force only for a "
			+ "generator-owned directory: %s" % _output_directory
		)
		return false
	if not existing_directories.is_empty():
		_fail(
			"--force refuses an output directory containing subdirectories: %s"
			% _output_directory
		)
		return false
	var allowed_names := {}
	for name_variant in OUTPUT_NAMES.values():
		allowed_names[String(name_variant)] = true
	for file_name in existing_files:
		if not allowed_names.has(file_name):
			_fail(
				"--force found an unrelated file in the output directory: %s"
				% file_name
			)
			return false
	return true


func _prepare_staging_directory() -> bool:
	var make_error := DirAccess.make_dir_recursive_absolute(_staging_directory)
	if make_error != OK:
		_fail(
			"Could not create staging directory: %s (%s)"
			% [_staging_directory, error_string(make_error)]
		)
		return false
	_write_directory = _staging_directory
	return true


func _publish_staged_output() -> bool:
	if not _validate_existing_output_directory():
		return false
	if (
		FileAccess.file_exists(_backup_directory)
		or DirAccess.dir_exists_absolute(_backup_directory)
	):
		_fail("Publish backup path appeared during generation: %s" % _backup_directory)
		return false
	var moved_previous := false
	if DirAccess.dir_exists_absolute(_output_directory):
		var backup_error := DirAccess.rename_absolute(
			_output_directory,
			_backup_directory
		)
		if backup_error != OK:
			_fail(
				"Could not preserve prior verified output: %s"
				% error_string(backup_error)
			)
			return false
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
				_fail(
					"Publish failed (%s) and prior-output rollback failed (%s)."
					% [
						error_string(publish_error),
						error_string(rollback_error),
					]
				)
				return false
		_fail(
			"Could not publish staged output: %s"
			% error_string(publish_error)
		)
		return false
	_write_directory = _output_directory
	if moved_previous and not _remove_generator_directory(_backup_directory):
		push_warning(
			"Published output is valid, but the prior-output backup remains: %s"
			% _backup_directory
		)
	return true


func _discard_staging_output() -> void:
	if not _remove_generator_directory(_staging_directory):
		push_warning(
			"Could not fully remove failed staging output: %s"
			% _staging_directory
		)


func _remove_generator_directory(directory: String) -> bool:
	if not DirAccess.dir_exists_absolute(directory):
		return true
	var access := DirAccess.open(directory)
	if access == null or not access.get_directories().is_empty():
		return false
	var allowed_names := {}
	for name_variant in OUTPUT_NAMES.values():
		allowed_names[String(name_variant)] = true
	var files := access.get_files()
	for file_name in files:
		if not allowed_names.has(file_name):
			return false
	for file_name in files:
		var remove_error := DirAccess.remove_absolute(directory.path_join(file_name))
		if remove_error != OK:
			return false
	return DirAccess.remove_absolute(directory) == OK


func _resolve_source_crops(source_size: Vector2i) -> void:
	var bounds := Rect2i(Vector2i.ZERO, source_size)
	_floor_crop = PREFERRED_FLOOR_CROP.intersection(bounds)
	if _floor_crop.size.x < 96 or _floor_crop.size.y < 96:
		_floor_crop = _normalized_crop(
			source_size,
			Rect2(0.30, 0.55, 0.40, 0.36)
		)
	_wall_crop = PREFERRED_WALL_CROP.intersection(bounds)
	if _wall_crop.size.x < EXEMPLAR_SIZE or _wall_crop.size.y < EXEMPLAR_SIZE:
		_wall_crop = _normalized_crop(
			source_size,
			Rect2(0.10, 0.12, 0.12, 0.70)
		)
	_void_crop = PREFERRED_VOID_CROP.intersection(bounds)
	if _void_crop.size.x < EXEMPLAR_SIZE or _void_crop.size.y < EXEMPLAR_SIZE:
		_void_crop = _normalized_crop(
			source_size,
			Rect2(0.0, 0.20, 0.10, 0.64)
		)


func _normalized_crop(source_size: Vector2i, normalized: Rect2) -> Rect2i:
	var position := Vector2i(
		floori(normalized.position.x * float(source_size.x)),
		floori(normalized.position.y * float(source_size.y))
	)
	var size := Vector2i(
		maxi(EXEMPLAR_SIZE, floori(normalized.size.x * float(source_size.x))),
		maxi(EXEMPLAR_SIZE, floori(normalized.size.y * float(source_size.y)))
	)
	return Rect2i(position, size).intersection(
		Rect2i(Vector2i.ZERO, source_size)
	)


func _build_palettes_and_exemplars(source: Image) -> void:
	var floor_raw := _sample_crop(source, _floor_crop, EXEMPLAR_SIZE)
	var wall_raw := _sample_crop(source, _wall_crop, EXEMPLAR_SIZE)
	var void_raw := _sample_crop(source, _void_crop, EXEMPLAR_SIZE)
	_floor_palette = _derive_palette(
		_palette_candidates(floor_raw, "floor"),
		4,
		4109
	)
	_wall_palette.assign(APPROVED_WALL_BASE)
	_void_palette.assign(APPROVED_VOID_BASE)
	if (
		_floor_palette.size() != 4
		or _wall_palette.size() != 4
		or _void_palette.size() != 2
	):
		_fail(
			"Approved source does not provide enough distinct colors for "
			+ "the required 4/4/2 palette lock."
		)
		return
	_accent_palette.assign(APPROVED_OVERLAY_ACCENTS)
	_floor_exemplar = _quantize_samples(
		floor_raw,
		_floor_palette,
		EXEMPLAR_SIZE
	)
	_wall_exemplar = _quantize_samples(
		wall_raw,
		_wall_palette,
		EXEMPLAR_SIZE
	)
	_void_exemplar = _quantize_samples(
		void_raw,
		_void_palette,
		EXEMPLAR_SIZE
	)


func _sample_crop(source: Image, crop: Rect2i, output_size: int) -> Array[Color]:
	var samples: Array[Color] = []
	for y in output_size:
		var source_y := clampi(
			crop.position.y
				+ floori((float(y) + 0.5) * float(crop.size.y) / output_size),
			crop.position.y,
			crop.end.y - 1
		)
		for x in output_size:
			var source_x := clampi(
				crop.position.x
					+ floori((float(x) + 0.5) * float(crop.size.x) / output_size),
				crop.position.x,
				crop.end.x - 1
			)
			var color := source.get_pixel(source_x, source_y)
			samples.append(Color(color.r, color.g, color.b, 1.0))
	return samples


func _palette_candidates(
	raw_samples: Array[Color],
	family: String
) -> Array[Color]:
	var neutral: Array[Color] = []
	for color in raw_samples:
		var maximum := maxf(color.r, maxf(color.g, color.b))
		var minimum := minf(color.r, minf(color.g, color.b))
		var chroma := maximum - minimum
		var luminance := _luminance(color)
		if chroma <= 0.40 and luminance >= 0.025 and luminance <= 0.90:
			neutral.append(color)
	var candidates := neutral if neutral.size() >= 64 else raw_samples.duplicate()
	candidates.sort_custom(
		func(a: Color, b: Color) -> bool:
			var difference := _luminance(a) - _luminance(b)
			if absf(difference) > 0.000001:
				return difference < 0.0
			return _color_key(a) < _color_key(b)
	)
	if family == "void":
		var dark_count := maxi(32, floori(float(candidates.size()) * 0.55))
		candidates.resize(mini(candidates.size(), dark_count))
	elif family == "wall":
		var wall_count := maxi(64, floori(float(candidates.size()) * 0.82))
		candidates.resize(mini(candidates.size(), wall_count))
	return candidates


func _derive_palette(
	samples: Array[Color],
	count: int,
	salt: int
) -> Array[Color]:
	var unique := {}
	for color in samples:
		unique[_color_key(color)] = color
	if unique.size() < count:
		return []
	var centers: Array[Color] = []
	centers.append(samples[_hash4(salt, count, samples.size(), 0) % samples.size()])
	while centers.size() < count:
		var best_color := samples[0]
		var best_distance := -1.0
		for color in samples:
			var nearest := INF
			for center in centers:
				nearest = minf(nearest, _color_distance_squared(color, center))
			if (
				nearest > best_distance + 0.0000001
				or (
					is_equal_approx(nearest, best_distance)
					and _color_key(color) < _color_key(best_color)
				)
			):
				best_distance = nearest
				best_color = color
		centers.append(best_color)
	for _iteration in 10:
		var red := PackedFloat64Array()
		var green := PackedFloat64Array()
		var blue := PackedFloat64Array()
		var totals := PackedInt32Array()
		red.resize(count)
		green.resize(count)
		blue.resize(count)
		totals.resize(count)
		for color in samples:
			var cluster := _nearest_color_index(color, centers)
			red[cluster] += color.r
			green[cluster] += color.g
			blue[cluster] += color.b
			totals[cluster] += 1
		for cluster in count:
			if totals[cluster] > 0:
				centers[cluster] = Color(
					red[cluster] / float(totals[cluster]),
					green[cluster] / float(totals[cluster]),
					blue[cluster] / float(totals[cluster]),
					1.0
				)
	var result: Array[Color] = []
	var used := {}
	for center in centers:
		var best_index := -1
		var best_distance := INF
		for sample_index in samples.size():
			var candidate := samples[sample_index]
			if used.has(_color_key(candidate)):
				continue
			var distance := _color_distance_squared(candidate, center)
			if distance < best_distance:
				best_distance = distance
				best_index = sample_index
		if best_index >= 0:
			var selected := samples[best_index]
			result.append(selected)
			used[_color_key(selected)] = true
	if result.size() != count:
		return []
	result.sort_custom(
		func(a: Color, b: Color) -> bool:
			var difference := _luminance(a) - _luminance(b)
			if absf(difference) > 0.000001:
				return difference < 0.0
			return _color_key(a) < _color_key(b)
	)
	return result


func _quantize_samples(
	samples: Array[Color],
	palette: Array[Color],
	size: int
) -> Image:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for index in samples.size():
		var palette_index := _nearest_color_index(samples[index], palette)
		image.set_pixel(index % size, index / size, palette[palette_index])
	return image


func _build_neighborhood_model(
	exemplar: Image,
	palette: Array[Color]
) -> Dictionary:
	var count := palette.size()
	var grid := PackedInt32Array()
	var global_counts := PackedInt32Array()
	var horizontal := PackedInt32Array()
	var vertical := PackedInt32Array()
	grid.resize(EXEMPLAR_SIZE * EXEMPLAR_SIZE)
	global_counts.resize(count)
	horizontal.resize(count * count)
	vertical.resize(count * count)
	for y in EXEMPLAR_SIZE:
		for x in EXEMPLAR_SIZE:
			var category := _nearest_color_index(
				exemplar.get_pixel(x, y),
				palette
			)
			grid[y * EXEMPLAR_SIZE + x] = category
			global_counts[category] += 1
	for y in EXEMPLAR_SIZE:
		for x in EXEMPLAR_SIZE:
			var category := grid[y * EXEMPLAR_SIZE + x]
			var east := grid[y * EXEMPLAR_SIZE + posmod(x + 1, EXEMPLAR_SIZE)]
			var south := grid[
				posmod(y + 1, EXEMPLAR_SIZE) * EXEMPLAR_SIZE + x
			]
			horizontal[category * count + east] += 1
			vertical[category * count + south] += 1
	var universal := 0
	for category in range(1, count):
		if global_counts[category] > global_counts[universal]:
			universal = category
	var horizontal_profiles := _derive_edge_profiles(
		grid,
		true,
		universal
	)
	var vertical_profiles := _derive_edge_profiles(
		grid,
		false,
		universal
	)
	if (
		_edge_profile_distance(horizontal_profiles[0], horizontal_profiles[1]) == 0
		or _edge_profile_distance(vertical_profiles[0], vertical_profiles[1]) == 0
	):
		_fail(
			"Quantized exemplar does not contain two distinct edge profiles "
			+ "for both axes."
		)
	return {
		"palette":palette,
		"grid":grid,
		"global_counts":global_counts,
		"horizontal":horizontal,
		"vertical":vertical,
		"horizontal_profiles":horizontal_profiles,
		"vertical_profiles":vertical_profiles,
		"universal":universal,
	}


func _derive_edge_profiles(
	grid: PackedInt32Array,
	horizontal_axis: bool,
	universal: int
) -> Array[PackedInt32Array]:
	var candidates: Array[PackedInt32Array] = []
	for anchor in EXEMPLAR_SIZE:
		var profile := PackedInt32Array()
		profile.resize(TILE_SIZE)
		var offset := posmod(anchor * 11, EXEMPLAR_SIZE)
		for position in TILE_SIZE:
			var sample_position := posmod(offset + position, EXEMPLAR_SIZE)
			if horizontal_axis:
				profile[position] = grid[
					anchor * EXEMPLAR_SIZE + sample_position
				]
			else:
				profile[position] = grid[
					sample_position * EXEMPLAR_SIZE + anchor
				]
		for position in EDGE_WIDTH:
			profile[position] = universal
			profile[TILE_SIZE - 1 - position] = universal
		candidates.append(profile)
	var base := PackedInt32Array()
	base.resize(TILE_SIZE)
	base.fill(universal)
	var closest_candidate := -1
	var closest_distance := TILE_SIZE + 1
	for index in candidates.size():
		var distance := _edge_profile_distance(base, candidates[index])
		if distance > 0 and distance < closest_distance:
			closest_distance = distance
			closest_candidate = index
	if closest_candidate < 0:
		return [base, base.duplicate()]
	var detail := base.duplicate()
	var copied := 0
	for position in range(EDGE_WIDTH, TILE_SIZE - EDGE_WIDTH):
		if candidates[closest_candidate][position] == universal:
			continue
		detail[position] = candidates[closest_candidate][position]
		copied += 1
		if copied == 4:
			break
	return [
		base,
		detail,
	]


func _edge_profile_distance(
	first: PackedInt32Array,
	second: PackedInt32Array
) -> int:
	var difference := 0
	for index in mini(first.size(), second.size()):
		if first[index] != second[index]:
			difference += 1
	return difference


func _build_tile_family(
	model: Dictionary,
	variants: int,
	family_salt: int
) -> Array[Image]:
	var tiles: Array[Image] = []
	for signature in SIGNATURE_COUNT:
		for variant in variants:
			tiles.append(
				_synthesize_tile(
					model,
					signature,
					variant,
					family_salt
				)
			)
	return tiles


func _build_void_tiles() -> Array[Image]:
	var tiles: Array[Image] = []
	for variant in VOID_VARIANTS:
		tiles.append(_synthesize_tile(_void_model, 0, variant, 39019))
	return tiles


func _synthesize_tile(
	model: Dictionary,
	signature: int,
	variant: int,
	family_salt: int
) -> Image:
	var palette: Array = model["palette"]
	var count := palette.size()
	var exemplar_grid: PackedInt32Array = model["grid"]
	var horizontal: PackedInt32Array = model["horizontal"]
	var vertical: PackedInt32Array = model["vertical"]
	var global_counts: PackedInt32Array = model["global_counts"]
	var values := PackedInt32Array()
	var locked := PackedByteArray()
	values.resize(TILE_SIZE * TILE_SIZE)
	locked.resize(TILE_SIZE * TILE_SIZE)
	var tile_salt := family_salt + signature * 101 + variant * 1009
	var offset_x := _hash4(tile_salt, 1, signature, variant) % EXEMPLAR_SIZE
	var offset_y := _hash4(tile_salt, 2, signature, variant) % EXEMPLAR_SIZE
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			var source_x := posmod(offset_x + x, EXEMPLAR_SIZE)
			var source_y := posmod(offset_y + y, EXEMPLAR_SIZE)
			values[y * TILE_SIZE + x] = exemplar_grid[
				source_y * EXEMPLAR_SIZE + source_x
			]
	_apply_edge_profiles(values, locked, model, signature)
	for sweep in SYNTHESIS_SWEEPS:
		for step in TILE_SIZE * TILE_SIZE:
			var index := (
				step
				if sweep % 2 == 0
				else TILE_SIZE * TILE_SIZE - 1 - step
			)
			if locked[index] != 0:
				continue
			var x := index % TILE_SIZE
			var y := index / TILE_SIZE
			var scores: Array[float] = []
			scores.resize(count)
			for category in count:
				var score := log(float(global_counts[category] + 1))
				if x > 0:
					var west := values[index - 1]
					score += 1.35 * log(
						float(horizontal[west * count + category] + 1)
						/ float(global_counts[west] + count)
					)
				if x + 1 < TILE_SIZE:
					var east := values[index + 1]
					score += 1.35 * log(
						float(horizontal[category * count + east] + 1)
						/ float(global_counts[category] + count)
					)
				if y > 0:
					var north := values[index - TILE_SIZE]
					score += 1.35 * log(
						float(vertical[north * count + category] + 1)
						/ float(global_counts[north] + count)
					)
				if y + 1 < TILE_SIZE:
					var south := values[index + TILE_SIZE]
					score += 1.35 * log(
						float(vertical[category * count + south] + 1)
						/ float(global_counts[category] + count)
					)
				scores[category] = score
			values[index] = _sample_scores(
				scores,
				x,
				y,
				sweep,
				tile_salt
			)
	_relax_unlocked_categories(values, locked, count)
	_apply_edge_profiles(values, locked, model, signature)
	if signature == 0 and variant == 0:
		_preserve_missing_exemplar_categories(
			values,
			locked,
			exemplar_grid,
			count,
			tile_salt
		)
		_apply_edge_profiles(values, locked, model, signature)
	var image := Image.create(
		TILE_SIZE,
		TILE_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	for y in TILE_SIZE:
		for x in TILE_SIZE:
			image.set_pixel(
				x,
				y,
				palette[values[y * TILE_SIZE + x]]
			)
	return image


func _relax_unlocked_categories(
	values: PackedInt32Array,
	locked: PackedByteArray,
	category_count: int
) -> void:
	var next := PackedInt32Array()
	next.resize(values.size())
	for _sweep in RELAXATION_SWEEPS:
		for index in values.size():
			next[index] = values[index]
		for y in range(1, TILE_SIZE - 1):
			for x in range(1, TILE_SIZE - 1):
				var index := y * TILE_SIZE + x
				if locked[index] != 0:
					continue
				var counts := PackedInt32Array()
				counts.resize(category_count)
				for offset_y in range(-1, 2):
					for offset_x in range(-1, 2):
						counts[
							values[
								(y + offset_y) * TILE_SIZE
								+ x + offset_x
							]
						] += 1
				var current := values[index]
				var selected := current
				for category in category_count:
					if counts[category] > counts[selected]:
						selected = category
				if counts[selected] >= counts[current] + 2:
					next[index] = selected
		for index in values.size():
			if locked[index] == 0:
				values[index] = next[index]


func _preserve_missing_exemplar_categories(
	values: PackedInt32Array,
	locked: PackedByteArray,
	exemplar_grid: PackedInt32Array,
	category_count: int,
	salt: int
) -> void:
	var present := PackedByteArray()
	present.resize(category_count)
	for value in values:
		present[value] = 1
	for category in category_count:
		if present[category] != 0:
			continue
		var source_index := -1
		for index in exemplar_grid.size():
			if exemplar_grid[index] == category:
				source_index = index
				break
		if source_index < 0:
			continue
		var source_center := Vector2i(
			source_index % EXEMPLAR_SIZE,
			source_index / EXEMPLAR_SIZE
		)
		var target_center := Vector2i(
			4 + _hash4(category, salt, 0, 43067) % (TILE_SIZE - 8),
			4 + _hash4(category, salt, 1, 43067) % (TILE_SIZE - 8)
		)
		for offset_y in range(-1, 2):
			for offset_x in range(-1, 2):
				var target := target_center + Vector2i(offset_x, offset_y)
				var target_index := target.y * TILE_SIZE + target.x
				if locked[target_index] != 0:
					continue
				var source := source_center + Vector2i(offset_x, offset_y)
				var source_x := posmod(source.x, EXEMPLAR_SIZE)
				var source_y := posmod(source.y, EXEMPLAR_SIZE)
				values[target_index] = exemplar_grid[
					source_y * EXEMPLAR_SIZE + source_x
				]


func _apply_edge_profiles(
	values: PackedInt32Array,
	locked: PackedByteArray,
	model: Dictionary,
	signature: int
) -> void:
	var horizontal_profiles: Array = model["horizontal_profiles"]
	var vertical_profiles: Array = model["vertical_profiles"]
	var north: PackedInt32Array = horizontal_profiles[(signature >> 0) & 1]
	var east: PackedInt32Array = vertical_profiles[(signature >> 1) & 1]
	var south: PackedInt32Array = horizontal_profiles[(signature >> 2) & 1]
	var west: PackedInt32Array = vertical_profiles[(signature >> 3) & 1]
	for distance in EDGE_WIDTH:
		for position in TILE_SIZE:
			var north_index := distance * TILE_SIZE + position
			var south_index := (
				(TILE_SIZE - 1 - distance) * TILE_SIZE + position
			)
			values[north_index] = north[position]
			values[south_index] = south[position]
			locked[north_index] = 1
			locked[south_index] = 1
			var west_index := position * TILE_SIZE + distance
			var east_index := (
				position * TILE_SIZE + TILE_SIZE - 1 - distance
			)
			values[west_index] = west[position]
			values[east_index] = east[position]
			locked[west_index] = 1
			locked[east_index] = 1


func _sample_scores(
	scores: Array[float],
	x: int,
	y: int,
	sweep: int,
	salt: int
) -> int:
	var maximum := scores[0]
	for score in scores:
		maximum = maxf(maximum, score)
	var weights := PackedFloat64Array()
	weights.resize(scores.size())
	var total := 0.0
	for index in scores.size():
		var weight := exp(scores[index] - maximum)
		weights[index] = weight
		total += weight
	var ticket := _hash_unit(x + salt, y, sweep, salt) * total
	var cumulative := 0.0
	for index in weights.size():
		cumulative += weights[index]
		if ticket <= cumulative:
			return index
	return weights.size() - 1


func _validate_material_outputs() -> bool:
	for family in [
		["floor", _floor_tiles, _floor_palette, FLOOR_VARIANTS, _floor_model],
		["wall", _wall_tiles, _wall_palette, WALL_VARIANTS, _wall_model],
	]:
		var family_name := String(family[0])
		var tiles: Array = family[1]
		var palette: Array = family[2]
		var variants := int(family[3])
		var model: Dictionary = family[4]
		if tiles.size() != SIGNATURE_COUNT * variants:
			_fail("%s Wang catalog has the wrong tile count." % family_name)
			return false
		if _unique_image_colors(tiles).size() != palette.size():
			_fail(
				"%s Wang catalog does not use its exact declared palette."
				% family_name
			)
			return false
		if _edge_profile_mismatches(tiles, variants, model) != 0:
			_fail("%s Wang edge profile validation failed." % family_name)
			return false
		if _catalog_adjacency_mismatches(tiles, variants) != 0:
			_fail("%s Wang shared-edge validation failed." % family_name)
			return false
	if _unique_image_colors(_void_tiles).size() != _void_palette.size():
		_fail("Void catalog does not use its exact declared palette.")
		return false
	for image in _floor_tiles + _wall_tiles + _void_tiles:
		if not _is_opaque(image):
			_fail("Base material output contains alpha.")
			return false
	return true


func _edge_profile_mismatches(
	tiles: Array,
	variants: int,
	model: Dictionary
) -> int:
	var palette: Array = model["palette"]
	var horizontal_profiles: Array = model["horizontal_profiles"]
	var vertical_profiles: Array = model["vertical_profiles"]
	var mismatch := 0
	for signature in SIGNATURE_COUNT:
		var north: PackedInt32Array = horizontal_profiles[(signature >> 0) & 1]
		var east: PackedInt32Array = vertical_profiles[(signature >> 1) & 1]
		var south: PackedInt32Array = horizontal_profiles[(signature >> 2) & 1]
		var west: PackedInt32Array = vertical_profiles[(signature >> 3) & 1]
		for variant in variants:
			var tile: Image = tiles[signature * variants + variant]
			for distance in EDGE_WIDTH:
				for position in TILE_SIZE:
					mismatch += int(
						tile.get_pixel(position, distance)
						!= palette[north[position]]
					)
					mismatch += int(
						tile.get_pixel(position, TILE_SIZE - 1 - distance)
						!= palette[south[position]]
					)
					mismatch += int(
						tile.get_pixel(distance, position)
						!= palette[west[position]]
					)
					mismatch += int(
						tile.get_pixel(TILE_SIZE - 1 - distance, position)
						!= palette[east[position]]
					)
	return mismatch


func _catalog_adjacency_mismatches(tiles: Array, variants: int) -> int:
	var mismatch := 0
	for first_signature in SIGNATURE_COUNT:
		for second_signature in SIGNATURE_COUNT:
			for first_variant in variants:
				var first: Image = tiles[
					first_signature * variants + first_variant
				]
				for second_variant in variants:
					var second: Image = tiles[
						second_signature * variants + second_variant
					]
					if (
						((first_signature >> 1) & 1)
						== ((second_signature >> 3) & 1)
					):
						for position in TILE_SIZE:
							mismatch += int(
								first.get_pixel(TILE_SIZE - 1, position)
								!= second.get_pixel(0, position)
							)
					if (
						((first_signature >> 2) & 1)
						== ((second_signature >> 0) & 1)
					):
						for position in TILE_SIZE:
							mismatch += int(
								first.get_pixel(position, TILE_SIZE - 1)
								!= second.get_pixel(position, 0)
							)
	return mismatch


func _build_exemplar_board() -> Image:
	var board := Image.create(
		EXEMPLAR_SIZE * 3,
		EXEMPLAR_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	board.blit_rect(
		_floor_exemplar,
		Rect2i(0, 0, EXEMPLAR_SIZE, EXEMPLAR_SIZE),
		Vector2i.ZERO
	)
	board.blit_rect(
		_wall_exemplar,
		Rect2i(0, 0, EXEMPLAR_SIZE, EXEMPLAR_SIZE),
		Vector2i(EXEMPLAR_SIZE, 0)
	)
	board.blit_rect(
		_void_exemplar,
		Rect2i(0, 0, EXEMPLAR_SIZE, EXEMPLAR_SIZE),
		Vector2i(EXEMPLAR_SIZE * 2, 0)
	)
	return board


func _build_atlas() -> Image:
	var row_count := FLOOR_VARIANTS + WALL_VARIANTS + 1
	var atlas := Image.create(
		SIGNATURE_COUNT * TILE_SIZE,
		row_count * TILE_SIZE,
		false,
		Image.FORMAT_RGBA8
	)
	for variant in FLOOR_VARIANTS:
		for signature in SIGNATURE_COUNT:
			atlas.blit_rect(
				_floor_tiles[signature * FLOOR_VARIANTS + variant],
				Rect2i(0, 0, TILE_SIZE, TILE_SIZE),
				Vector2i(signature * TILE_SIZE, variant * TILE_SIZE)
			)
	for variant in WALL_VARIANTS:
		for signature in SIGNATURE_COUNT:
			atlas.blit_rect(
				_wall_tiles[signature * WALL_VARIANTS + variant],
				Rect2i(0, 0, TILE_SIZE, TILE_SIZE),
				Vector2i(
					signature * TILE_SIZE,
					(FLOOR_VARIANTS + variant) * TILE_SIZE
				)
			)
	for signature in SIGNATURE_COUNT:
		atlas.blit_rect(
			_void_tiles[signature % VOID_VARIANTS],
			Rect2i(0, 0, TILE_SIZE, TILE_SIZE),
			Vector2i(
				signature * TILE_SIZE,
				(FLOOR_VARIANTS + WALL_VARIANTS) * TILE_SIZE
			)
		)
	return atlas


func _build_map_base() -> Image:
	var base := Image.create(
		PROOF_SIZE.x,
		PROOF_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	var columns := ceili(float(PROOF_SIZE.x) / float(TILE_SIZE))
	var rows := ceili(float(PROOF_SIZE.y) / float(TILE_SIZE))
	for tile_y in rows:
		for tile_x in columns:
			var signature := _signature_for_coordinate(tile_x, tile_y)
			var floor_variant := _hash4(
				tile_x,
				tile_y,
				signature,
				51001
			) % FLOOR_VARIANTS
			var wall_variant := _hash4(
				tile_x,
				tile_y,
				signature,
				63029
			) % WALL_VARIANTS
			var void_variant := _hash4(
				tile_x,
				tile_y,
				0,
				75011
			) % VOID_VARIANTS
			var floor_tile := _floor_tiles[
				signature * FLOOR_VARIANTS + floor_variant
			]
			var wall_tile := _wall_tiles[
				signature * WALL_VARIANTS + wall_variant
			]
			var void_tile := _void_tiles[void_variant]
			for local_y in TILE_SIZE:
				var pixel_y := tile_y * TILE_SIZE + local_y
				if pixel_y >= PROOF_SIZE.y:
					break
				for local_x in TILE_SIZE:
					var pixel_x := tile_x * TILE_SIZE + local_x
					if pixel_x >= PROOF_SIZE.x:
						break
					var point := Vector2i(pixel_x, pixel_y)
					var material := _material_at(point)
					match material:
						"floor":
							base.set_pixel(
								pixel_x,
								pixel_y,
								floor_tile.get_pixel(local_x, local_y)
							)
						"wall":
							base.set_pixel(
								pixel_x,
								pixel_y,
								wall_tile.get_pixel(local_x, local_y)
							)
						_:
							base.set_pixel(
								pixel_x,
								pixel_y,
								void_tile.get_pixel(local_x, local_y)
							)
	return base


func _material_at(point: Vector2i) -> String:
	if not ARENA_RECT.has_point(point):
		return "void"
	var local := point - ARENA_RECT.position
	if (
		local.x < TILE_SIZE
		or local.y < TILE_SIZE
		or local.x >= ARENA_RECT.size.x - TILE_SIZE
		or local.y >= ARENA_RECT.size.y - TILE_SIZE
	):
		return "wall"
	for rect_variant in BULKHEAD_RECTS:
		var rect: Rect2i = rect_variant
		if rect.has_point(point):
			return "wall"
	for rect_variant in COVER_RECTS:
		var rect: Rect2i = rect_variant
		if rect.has_point(point):
			return "wall"
	return "floor"


func _build_structure_overlay() -> Image:
	var image := _transparent_proof()
	var shadow := _opaque(_wall_palette[0])
	var highlight := _opaque(_wall_palette[_wall_palette.size() - 1])
	var accent := _opaque(_accent_palette[0])
	var support := _opaque(_accent_palette[1])
	var warning := _opaque(_accent_palette[2])
	var inner_frame := ARENA_RECT.grow(-TILE_SIZE + 4)
	_draw_topology_rect(image, ARENA_RECT, highlight, shadow, 3)
	_draw_rect_outline(image, inner_frame, accent, 2)
	_draw_corner_brackets(image, inner_frame, support)
	_draw_wall_frame_segments(
		image,
		ARENA_RECT,
		highlight,
		shadow,
		accent,
		warning
	)
	_draw_floor_panel_grid(image)
	for rect_variant in BULKHEAD_RECTS:
		_draw_topology_rect(
			image,
			rect_variant,
			highlight,
			shadow,
			3
		)
	for rect_variant in COVER_RECTS:
		var rect: Rect2i = rect_variant
		_draw_topology_rect(image, rect, highlight, shadow, 2)
		_fill_rect(
			image,
			Rect2i(
				rect.position + Vector2i(5, rect.size.y - 6),
				Vector2i(mini(12, rect.size.x - 10), 2)
			),
			accent
		)
	for rect_variant in SURGE_BAY_RECTS:
		var rect: Rect2i = rect_variant
		_draw_rect_outline(image, rect, accent, 2)
		for offset in range(12, rect.size.x - 6, 24):
			_draw_line(
				image,
				Vector2i(rect.position.x + offset, rect.position.y + 4),
				Vector2i(rect.position.x + offset - 8, rect.end.y - 5),
				accent,
				1
			)
	for tile_y in range(ARENA_RECT.position.y / TILE_SIZE, ARENA_RECT.end.y / TILE_SIZE + 1):
		for tile_x in range(ARENA_RECT.position.x / TILE_SIZE, ARENA_RECT.end.x / TILE_SIZE + 1):
			var center := Vector2i(
				tile_x * TILE_SIZE + TILE_SIZE / 2,
				tile_y * TILE_SIZE + TILE_SIZE / 2
			)
			if _material_at(center) != "floor":
				continue
			if CENTRAL_NO_GO.has_point(center):
				continue
			if _hash4(tile_x, tile_y, 0, 86011) % 23 != 0:
				continue
			var origin := Vector2i(tile_x * TILE_SIZE, tile_y * TILE_SIZE)
			if _hash4(tile_x, tile_y, 1, 86011) % 2 == 0:
				_draw_line(
					image,
					origin + Vector2i(7, 9),
					origin + Vector2i(16, 9),
					_opaque(_floor_palette[0]),
					1
				)
			else:
				_draw_line(
					image,
					origin + Vector2i(10, 7),
					origin + Vector2i(10, 16),
					_opaque(_floor_palette[0]),
					1
				)
	return image


func _draw_wall_frame_segments(
	image: Image,
	rect: Rect2i,
	highlight: Color,
	shadow: Color,
	accent: Color,
	warning: Color
) -> void:
	# These marks describe the existing wall band; they never imply new collision.
	var horizontal_index := 0
	for x in range(rect.position.x + 28, rect.end.x - 20, 72):
		for y in [rect.position.y + 4, rect.end.y - TILE_SIZE + 4]:
			_draw_line(
				image,
				Vector2i(x, y),
				Vector2i(x, y + TILE_SIZE - 9),
				shadow,
				2
			)
			_draw_line(
				image,
				Vector2i(x + 2, y + 1),
				Vector2i(x + 2, y + TILE_SIZE - 10),
				highlight,
				1
			)
		if horizontal_index % 3 == 1:
			_fill_rect(
				image,
				Rect2i(
					Vector2i(x + 18, rect.position.y + 14),
					Vector2i(12, 2)
				),
				accent
			)
			_fill_rect(
				image,
				Rect2i(
					Vector2i(x + 18, rect.end.y - 16),
					Vector2i(12, 2)
				),
				accent
			)
		elif horizontal_index % 3 == 2:
			_fill_rect(
				image,
				Rect2i(
					Vector2i(x + 22, rect.position.y + 12),
					Vector2i(2, 2)
				),
				warning
			)
			_fill_rect(
				image,
				Rect2i(
					Vector2i(x + 22, rect.end.y - 14),
					Vector2i(2, 2)
				),
				warning
			)
		horizontal_index += 1

	var vertical_index := 0
	for y in range(rect.position.y + 28, rect.end.y - 20, 64):
		for x in [rect.position.x + 4, rect.end.x - TILE_SIZE + 4]:
			_draw_line(
				image,
				Vector2i(x, y),
				Vector2i(x + TILE_SIZE - 9, y),
				shadow,
				2
			)
			_draw_line(
				image,
				Vector2i(x + 1, y + 2),
				Vector2i(x + TILE_SIZE - 10, y + 2),
				highlight,
				1
			)
		if vertical_index % 3 == 1:
			_fill_rect(
				image,
				Rect2i(
					Vector2i(rect.position.x + 14, y + 15),
					Vector2i(2, 10)
				),
				accent
			)
			_fill_rect(
				image,
				Rect2i(
					Vector2i(rect.end.x - 16, y + 15),
					Vector2i(2, 10)
				),
				accent
			)
		elif vertical_index % 3 == 2:
			_fill_rect(
				image,
				Rect2i(
					Vector2i(rect.position.x + 12, y + 18),
					Vector2i(2, 2)
				),
				warning
			)
			_fill_rect(
				image,
				Rect2i(
					Vector2i(rect.end.x - 14, y + 18),
					Vector2i(2, 2)
				),
				warning
			)
		vertical_index += 1


func _draw_floor_panel_grid(image: Image) -> void:
	var inner := ARENA_RECT.grow(-TILE_SIZE)
	var seam := _opaque(_floor_palette[0])
	var x := inner.position.x + 104
	var column := 0
	while x < inner.end.x:
		for y in range(inner.position.y, inner.end.y):
			var point := Vector2i(x, y)
			if _material_at(point) == "floor":
				image.set_pixelv(point, seam)
		x += 112 + (_hash4(column, 0, 0, 84179) % 2) * 24
		column += 1
	var y := inner.position.y + 92
	var row := 0
	while y < inner.end.y:
		for x_position in range(inner.position.x, inner.end.x):
			var point := Vector2i(x_position, y)
			if _material_at(point) == "floor":
				image.set_pixelv(point, seam)
		y += 92 + (_hash4(row, 0, 1, 84179) % 2) * 24
		row += 1


func _draw_corner_brackets(
	image: Image,
	rect: Rect2i,
	color: Color
) -> void:
	var length := 18
	for corner in [
		[rect.position, Vector2i(1, 0), Vector2i(0, 1)],
		[
			Vector2i(rect.end.x - 1, rect.position.y),
			Vector2i(-1, 0),
			Vector2i(0, 1),
		],
		[
			Vector2i(rect.position.x, rect.end.y - 1),
			Vector2i(1, 0),
			Vector2i(0, -1),
		],
		[
			rect.end - Vector2i.ONE,
			Vector2i(-1, 0),
			Vector2i(0, -1),
		],
	]:
		var origin: Vector2i = corner[0]
		_draw_line(
			image,
			origin,
			origin + Vector2i(corner[1]) * length,
			color,
			2
		)
		_draw_line(
			image,
			origin,
			origin + Vector2i(corner[2]) * length,
			color,
			2
		)


func _build_wear_overlay() -> Image:
	var image := _transparent_proof()
	var candidates: Array[Dictionary] = []
	for tile_y in range(ARENA_RECT.position.y / TILE_SIZE, ARENA_RECT.end.y / TILE_SIZE + 1):
		for tile_x in range(ARENA_RECT.position.x / TILE_SIZE, ARENA_RECT.end.x / TILE_SIZE + 1):
			var jitter := Vector2i(
				4 + _hash4(tile_x, tile_y, 0, 97001) % 16,
				4 + _hash4(tile_x, tile_y, 1, 97001) % 16
			)
			var point := Vector2i(tile_x * TILE_SIZE, tile_y * TILE_SIZE) + jitter
			if not _has_clear_floor(point, 12):
				continue
			candidates.append({
				"point":point,
				"rank":_hash4(tile_x, tile_y, 2, 97001),
			})
	candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["rank"]) < int(b["rank"])
	)
	_wear_positions.clear()
	for candidate in candidates:
		var point: Vector2i = candidate["point"]
		var legal := true
		for accepted in _wear_positions:
			if accepted.distance_squared_to(point) < 96 * 96:
				legal = false
				break
		if not legal:
			continue
		_wear_positions.append(point)
		var length := 4 + _hash4(point.x, point.y, 0, 101003) % 6
		var direction := -1 if _hash4(point.x, point.y, 1, 101003) % 2 == 0 else 1
		_draw_line(
			image,
			point - Vector2i(length / 2, 0),
			point + Vector2i(length / 2, direction),
			_opaque(_floor_palette[0]),
			1
		)
		if _hash4(point.x, point.y, 2, 101003) % 3 == 0:
			_draw_line(
				image,
				point + Vector2i(2, 3),
				point + Vector2i(5, 2),
				_opaque(_floor_palette[1]),
				1
			)
	return image


func _build_prop_overlay() -> Image:
	var image := _transparent_proof()
	var candidates: Array[Dictionary] = []
	for tile_y in range(ARENA_RECT.position.y / TILE_SIZE, ARENA_RECT.end.y / TILE_SIZE + 1):
		for tile_x in range(ARENA_RECT.position.x / TILE_SIZE, ARENA_RECT.end.x / TILE_SIZE + 1):
			var point := Vector2i(
				tile_x * TILE_SIZE + TILE_SIZE / 2,
				tile_y * TILE_SIZE + TILE_SIZE / 2
			)
			if not _has_clear_floor(point, 24):
				continue
			candidates.append({
				"point":point,
				"rank":_hash4(tile_x, tile_y, 0, 111031),
			})
	candidates.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["rank"]) < int(b["rank"])
	)
	_prop_positions.clear()
	for candidate in candidates:
		if _prop_positions.size() >= 9:
			break
		var point: Vector2i = candidate["point"]
		var legal := true
		for accepted in _prop_positions:
			if accepted.distance_squared_to(point) < 128 * 128:
				legal = false
				break
		if not legal:
			continue
		_prop_positions.append(point)
		_draw_proof_prop(
			image,
			point,
			_hash4(point.x, point.y, 0, 121021) % 3
		)
	return image


func _draw_proof_prop(image: Image, center: Vector2i, kind: int) -> void:
	var dark := _opaque(_wall_palette[0])
	var body := _opaque(_wall_palette[2])
	var light := _opaque(_wall_palette[3])
	var accent := _opaque(_accent_palette[1])
	match kind:
		0:
			_fill_rect(image, Rect2i(center - Vector2i(12, 8), Vector2i(24, 16)), dark)
			_fill_rect(image, Rect2i(center - Vector2i(9, 5), Vector2i(18, 10)), body)
			for offset in range(-6, 7, 4):
				_draw_line(
					image,
					center + Vector2i(offset, -4),
					center + Vector2i(offset, 4),
					light,
					1
				)
		1:
			_fill_rect(image, Rect2i(center - Vector2i(9, 8), Vector2i(18, 16)), dark)
			_fill_rect(image, Rect2i(center - Vector2i(6, 6), Vector2i(12, 8)), body)
			_fill_rect(image, Rect2i(center - Vector2i(4, 4), Vector2i(8, 3)), accent)
			_fill_rect(image, Rect2i(center + Vector2i(-5, 4), Vector2i(3, 2)), light)
		_:
			_fill_rect(image, Rect2i(center - Vector2i(14, 10), Vector2i(28, 20)), dark)
			_fill_rect(image, Rect2i(center - Vector2i(11, 7), Vector2i(22, 14)), body)
			_draw_line(
				image,
				center + Vector2i(-10, -6),
				center + Vector2i(10, 6),
				light,
				2
			)
			_draw_line(
				image,
				center + Vector2i(10, -6),
				center + Vector2i(-10, 6),
				light,
				2
			)


func _has_clear_floor(point: Vector2i, radius: int) -> bool:
	for offset in [
		Vector2i.ZERO,
		Vector2i(radius, 0),
		Vector2i(-radius, 0),
		Vector2i(0, radius),
		Vector2i(0, -radius),
		Vector2i(radius, radius),
		Vector2i(-radius, radius),
		Vector2i(radius, -radius),
		Vector2i(-radius, -radius),
	]:
		var sample := point + Vector2i(offset)
		if (
			_material_at(sample) != "floor"
			or CENTRAL_NO_GO.has_point(sample)
		):
			return false
	return true


func _draw_topology_rect(
	image: Image,
	rect: Rect2i,
	highlight: Color,
	shadow: Color,
	width: int
) -> void:
	_draw_line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), highlight, width)
	_draw_line(image, rect.position, Vector2i(rect.position.x, rect.end.y - 1), highlight, width)
	_draw_line(
		image,
		Vector2i(rect.position.x, rect.end.y - 1),
		rect.end - Vector2i.ONE,
		shadow,
		width
	)
	_draw_line(
		image,
		Vector2i(rect.end.x - 1, rect.position.y),
		rect.end - Vector2i.ONE,
		shadow,
		width
	)


func _draw_rect_outline(
	image: Image,
	rect: Rect2i,
	color: Color,
	width: int
) -> void:
	_draw_line(image, rect.position, Vector2i(rect.end.x - 1, rect.position.y), color, width)
	_draw_line(image, rect.position, Vector2i(rect.position.x, rect.end.y - 1), color, width)
	_draw_line(
		image,
		Vector2i(rect.position.x, rect.end.y - 1),
		rect.end - Vector2i.ONE,
		color,
		width
	)
	_draw_line(
		image,
		Vector2i(rect.end.x - 1, rect.position.y),
		rect.end - Vector2i.ONE,
		color,
		width
	)


func _draw_line(
	image: Image,
	from: Vector2i,
	to: Vector2i,
	color: Color,
	width: int
) -> void:
	var delta := to - from
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps == 0:
		_fill_rect(
			image,
			Rect2i(from - Vector2i(width / 2, width / 2), Vector2i(width, width)),
			color
		)
		return
	for step in steps + 1:
		var point := Vector2(from).lerp(Vector2(to), float(step) / float(steps))
		_fill_rect(
			image,
			Rect2i(
				Vector2i(point.round()) - Vector2i(width / 2, width / 2),
				Vector2i(width, width)
			),
			color
		)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var clipped := rect.intersection(
		Rect2i(Vector2i.ZERO, image.get_size())
	)
	for y in range(clipped.position.y, clipped.end.y):
		for x in range(clipped.position.x, clipped.end.x):
			image.set_pixel(x, y, color)


func _combine_layers(layers: Array) -> Image:
	var result := _transparent_proof()
	for layer_variant in layers:
		var layer: Image = layer_variant
		result.blend_rect(
			layer,
			Rect2i(Vector2i.ZERO, PROOF_SIZE),
			Vector2i.ZERO
		)
	return result


func _validate_proof_layers(
	base: Image,
	structure: Image,
	wear: Image,
	props: Image,
	overlays: Image,
	final: Image
) -> Dictionary:
	var images := {
		"base":base,
		"structure":structure,
		"wear":wear,
		"props":props,
		"overlays":overlays,
		"final":final,
	}
	var dimension_mismatches := 0
	var format_mismatches := 0
	for image_variant in images.values():
		var image: Image = image_variant
		dimension_mismatches += int(image.get_size() != PROOF_SIZE)
		format_mismatches += int(image.get_format() != Image.FORMAT_RGBA8)

	var base_non_opaque_pixels := _non_opaque_pixel_count(base)
	var final_non_opaque_pixels := _non_opaque_pixel_count(final)
	var overlay_partial_alpha_pixels := 0
	var overlay_transparent_pixels := {}
	for key in ["structure", "wear", "props", "overlays"]:
		var layer: Image = images[key]
		overlay_partial_alpha_pixels += _partial_alpha_pixel_count(layer)
		overlay_transparent_pixels[key] = _transparent_pixel_count(layer)

	var expected_overlays := _combine_layers([structure, wear, props])
	var expected_final := base.duplicate()
	expected_final.blend_rect(
		expected_overlays,
		Rect2i(Vector2i.ZERO, PROOF_SIZE),
		Vector2i.ZERO
	)
	var overlay_composition_mismatches := _pixel_mismatch_count(
		overlays,
		expected_overlays
	)
	var final_composition_mismatches := _pixel_mismatch_count(
		final,
		expected_final
	)
	var wear_illegal_pixels := _illegal_floor_overlay_pixel_count(wear)
	var prop_illegal_pixels := _illegal_floor_overlay_pixel_count(props)
	var missing_transparent_layer_backgrounds := 0
	for transparent_count in overlay_transparent_pixels.values():
		missing_transparent_layer_backgrounds += int(int(transparent_count) == 0)

	var valid := (
		dimension_mismatches == 0
		and format_mismatches == 0
		and base_non_opaque_pixels == 0
		and final_non_opaque_pixels == 0
		and overlay_partial_alpha_pixels == 0
		and missing_transparent_layer_backgrounds == 0
		and overlay_composition_mismatches == 0
		and final_composition_mismatches == 0
		and wear_illegal_pixels == 0
		and prop_illegal_pixels == 0
	)
	var record := {
		"valid":valid,
		"dimension_mismatches":dimension_mismatches,
		"format_mismatches":format_mismatches,
		"base_non_opaque_pixels":base_non_opaque_pixels,
		"final_non_opaque_pixels":final_non_opaque_pixels,
		"overlay_partial_alpha_pixels":overlay_partial_alpha_pixels,
		"missing_transparent_layer_backgrounds":missing_transparent_layer_backgrounds,
		"overlay_composition_mismatches":overlay_composition_mismatches,
		"final_composition_mismatches":final_composition_mismatches,
		"wear_illegal_pixels":wear_illegal_pixels,
		"prop_illegal_pixels":prop_illegal_pixels,
	}
	if not valid:
		_fail("Proof layer validation failed: %s" % JSON.stringify(record))
	return record


func _non_opaque_pixel_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			count += int(roundi(image.get_pixel(x, y).a * 255.0) != 255)
	return count


func _partial_alpha_pixel_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var alpha := roundi(image.get_pixel(x, y).a * 255.0)
			count += int(alpha != 0 and alpha != 255)
	return count


func _transparent_pixel_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			count += int(roundi(image.get_pixel(x, y).a * 255.0) == 0)
	return count


func _pixel_mismatch_count(first: Image, second: Image) -> int:
	if first.get_size() != second.get_size():
		return maxi(first.get_width() * first.get_height(), 1)
	var count := 0
	for y in first.get_height():
		for x in first.get_width():
			count += int(
				first.get_pixel(x, y).to_rgba32()
				!= second.get_pixel(x, y).to_rgba32()
			)
	return count


func _illegal_floor_overlay_pixel_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var point := Vector2i(x, y)
			if roundi(image.get_pixel(x, y).a * 255.0) == 0:
				continue
			count += int(
				_material_at(point) != "floor"
				or CENTRAL_NO_GO.has_point(point)
			)
	return count


func _transparent_proof() -> Image:
	var image := Image.create(
		PROOF_SIZE.x,
		PROOF_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	image.fill(Color.TRANSPARENT)
	return image


func _build_proof_record(
	source: Image,
	output_records: Dictionary,
	wear: Image,
	props: Image
) -> Dictionary:
	var signatures := []
	for signature in SIGNATURE_COUNT:
		signatures.append({
			"index":signature,
			"north":(signature >> 0) & 1,
			"east":(signature >> 1) & 1,
			"south":(signature >> 2) & 1,
			"west":(signature >> 3) & 1,
		})
	var wear_coverage := (
		float(_opaque_pixel_count(wear))
		/ float(PROOF_SIZE.x * PROOF_SIZE.y)
	)
	return {
		"schema_version":1,
		"generator":{
			"path":GENERATOR_PATH.trim_prefix("res://"),
			"sha256":FileAccess.get_sha256(
				ProjectSettings.globalize_path(GENERATOR_PATH)
			),
			"godot_version":Engine.get_version_info(),
		},
		"provenance":{
			"production_method":"approved_source_categorical_neighborhood_synthesis",
			"source_path":_source_path,
			"source_sha256":FileAccess.get_sha256(_source_path),
			"source_size":[source.get_width(), source.get_height()],
			"source_crops":{
				"floor":_rect_record(_floor_crop),
				"wall":_rect_record(_wall_crop),
				"void":_rect_record(_void_crop),
			},
			"seed":_seed,
			"deterministic":true,
			"timestamp_omitted_for_reproducibility":true,
		},
		"synthesis":{
			"method":"categorical_four_neighbor_markov_gibbs",
			"exemplar_size":[EXEMPLAR_SIZE, EXEMPLAR_SIZE],
			"tile_size":[TILE_SIZE, TILE_SIZE],
			"neighborhood":"north_east_south_west",
			"sweeps":SYNTHESIS_SWEEPS,
			"sampling":"nearest_source_pixel_then_exact_palette_medoid",
			"edge_strip_width":EDGE_WIDTH,
			"edge_profile_count":2,
			"signature_bit_order":"north,east,south,west",
			"coordinate_selection":"integer_hash_shared_boundary_and_variant",
		},
		"palettes":{
			"floor":{
				"declared_count":4,
				"actual_count":_unique_image_colors(_floor_tiles).size(),
				"colors":_palette_strings(_floor_palette),
			},
			"wall":{
				"declared_count":4,
				"actual_count":_unique_image_colors(_wall_tiles).size(),
				"colors":_palette_strings(_wall_palette),
			},
			"void":{
				"declared_count":2,
				"actual_count":_unique_image_colors(_void_tiles).size(),
				"colors":_palette_strings(_void_palette),
			},
		},
		"wang":{
			"signature_count":SIGNATURE_COUNT,
			"signatures":signatures,
			"floor_variants_per_signature":FLOOR_VARIANTS,
			"wall_variants_per_signature":WALL_VARIANTS,
			"floor_tile_count":_floor_tiles.size(),
			"wall_tile_count":_wall_tiles.size(),
			"floor_profile_mismatch_pixels":_edge_profile_mismatches(
				_floor_tiles,
				FLOOR_VARIANTS,
				_floor_model
			),
			"wall_profile_mismatch_pixels":_edge_profile_mismatches(
				_wall_tiles,
				WALL_VARIANTS,
				_wall_model
			),
			"floor_adjacency_mismatch_pixels":_catalog_adjacency_mismatches(
				_floor_tiles,
				FLOOR_VARIANTS
			),
			"wall_adjacency_mismatch_pixels":_catalog_adjacency_mismatches(
				_wall_tiles,
				WALL_VARIANTS
			),
			"coordinate_hash_mismatches":_coordinate_hash_mismatches(),
		},
		"proof":{
			"size":[PROOF_SIZE.x, PROOF_SIZE.y],
			"arena":_rect_record(ARENA_RECT),
			"central_no_go":_rect_record(CENTRAL_NO_GO),
			"bulkheads":_rect_array_record(BULKHEAD_RECTS),
			"covers":_rect_array_record(COVER_RECTS),
			"surge_bays":_rect_array_record(SURGE_BAY_RECTS),
			"layers":[
				"base",
				"structure",
				"wear",
				"props",
				"final",
			],
			"wear_stamp_count":_wear_positions.size(),
			"wear_minimum_spacing_px":96,
			"wear_coverage":wear_coverage,
			"wear_coverage_limit":0.02,
			"prop_count":_prop_positions.size(),
			"prop_opaque_pixels":_opaque_pixel_count(props),
			"composition_validation":_proof_validation,
		},
		"outputs":output_records,
	}


func _coordinate_hash_mismatches() -> int:
	var mismatch := 0
	for y in range(-8, 39):
		for x in range(-8, 63):
			var current := _signature_for_coordinate(x, y)
			var east := _signature_for_coordinate(x + 1, y)
			var south := _signature_for_coordinate(x, y + 1)
			mismatch += int(((current >> 1) & 1) != ((east >> 3) & 1))
			mismatch += int(((current >> 2) & 1) != ((south >> 0) & 1))
	return mismatch


func _signature_for_coordinate(x: int, y: int) -> int:
	var north := _shared_horizontal_edge(x, y)
	var east := _shared_vertical_edge(x + 1, y)
	var south := _shared_horizontal_edge(x, y + 1)
	var west := _shared_vertical_edge(x, y)
	return north | (east << 1) | (south << 2) | (west << 3)


func _shared_horizontal_edge(x: int, boundary_y: int) -> int:
	return _hash4(x, boundary_y, 0, 131071) & 1


func _shared_vertical_edge(boundary_x: int, y: int) -> int:
	return _hash4(boundary_x, y, 1, 131071) & 1


func _save_png(name: String, image: Image) -> Dictionary:
	var path := _output_path(name)
	var save_error := image.save_png(path)
	if save_error != OK:
		_fail("Could not save %s: %s" % [path, error_string(save_error)])
		return {}
	return {
		"path":name,
		"size":[image.get_width(), image.get_height()],
		"sha256":FileAccess.get_sha256(path),
	}


func _write_json(path: String, value: Variant) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("Could not open proof JSON for writing: %s" % path)
		return false
	file.store_string(JSON.stringify(value, "\t", true) + "\n")
	return true


func _output_path(name: String) -> String:
	return _write_directory.path_join(name)


func _unique_image_colors(images: Array) -> Dictionary:
	var colors := {}
	for image_variant in images:
		var image: Image = image_variant
		for y in image.get_height():
			for x in image.get_width():
				var color := image.get_pixel(x, y)
				if color.a > 0.0:
					colors[_color_key(color)] = true
	return colors


func _is_opaque(image: Image) -> bool:
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 1.0:
				return false
	return true


func _opaque_pixel_count(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			count += int(image.get_pixel(x, y).a > 0.0)
	return count


func _palette_strings(palette: Array[Color]) -> Array[String]:
	var result: Array[String] = []
	for color in palette:
		result.append("#%s" % color.to_html(false).to_upper())
	return result


func _rect_record(rect: Rect2i) -> Array[int]:
	return [
		rect.position.x,
		rect.position.y,
		rect.size.x,
		rect.size.y,
	]


func _rect_array_record(rectangles: Array) -> Array:
	var result := []
	for rect_variant in rectangles:
		result.append(_rect_record(rect_variant))
	return result


func _nearest_color_index(color: Color, palette: Array) -> int:
	var best_index := 0
	var best_distance := INF
	for index in palette.size():
		var distance := _color_distance_squared(color, palette[index])
		if distance < best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _color_distance_squared(first: Color, second: Color) -> float:
	var red := first.r - second.r
	var green := first.g - second.g
	var blue := first.b - second.b
	return red * red + green * green + blue * blue


func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722


func _color_key(color: Color) -> int:
	var red := clampi(roundi(color.r * 255.0), 0, 255)
	var green := clampi(roundi(color.g * 255.0), 0, 255)
	var blue := clampi(roundi(color.b * 255.0), 0, 255)
	return (red << 16) | (green << 8) | blue


func _opaque(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 1.0)


func _hash4(first: int, second: int, third: int, fourth: int) -> int:
	var value := posmod(_seed, HASH_MODULUS)
	value = _mix_hash(value, first)
	value = _mix_hash(value, second)
	value = _mix_hash(value, third)
	value = _mix_hash(value, fourth)
	return value


func _mix_hash(value: int, component: int) -> int:
	var normalized := posmod(component, HASH_MODULUS)
	var mixed := posmod(value + normalized * 374761393, HASH_MODULUS)
	mixed = posmod((mixed ^ (mixed >> 13)) * 1274126177, HASH_MODULUS)
	return posmod(mixed ^ (mixed >> 16), HASH_MODULUS)


func _hash_unit(first: int, second: int, third: int, fourth: int) -> float:
	return float(_hash4(first, second, third, fourth)) / float(HASH_MODULUS)


func _fail(message: String) -> void:
	_generation_failed = true
	push_error(message)
