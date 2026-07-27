extends SceneTree

## Deterministic full-library publisher. It preserves the approved Phase 2
## masters, imports reviewed source overrides, truthfully labels any remaining
## direct/procedural frames, emits semantic-by-palette SVG masters, and packs
## one shared runtime atlas without changing gameplay geometry.

const INVENTORY_PATH := "res://pixel-art-production/assets/asset-inventory.json"
const PHASE2_CATALOG_PATH := "res://pixel-art-production/assets/generated/approved/phase-2/catalog.json"
const SOURCE_OVERRIDE_MANIFEST_PATH := "res://pixel-art-production/assets/manifests/approved/visual-recovery/core-slice.json"
const OUTPUT_ATLAS_PATH := "res://pixel-art-production/runtime/atlases/cardborne-pixel-atlas.png"
const OUTPUT_CATALOG_PATH := "res://pixel-art-production/runtime/catalog.json"
const MASTER_ROOT := "res://pixel-art-production/assets/generated/approved/complete/masters"
const FRAME_SOURCE_ROOT := "res://pixel-art-production/assets/generated/approved/complete/frames"
const EVIDENCE_ROOT := "res://pixel-art-production/evidence/gates/08-final-migration"
const PixelSourceOverrideCatalog := preload(
	"res://tools/design/pixel_source_override_catalog.gd"
)

const FRAME_SIZE := 64
const CELL_SIZE := 66
const CELL_STRIDE := 68
const ATLAS_COLUMNS := 24

const SPACE := Color("#141B24")
const RECESS := Color("#202833")
const SHADOW := Color("#2E3945")
const DECK := Color("#44515E")
const BLOCKER := Color("#596774")
const EDGE := Color("#222B35")
const LIGHT := Color("#E8EEF0")
const GOLD := Color("#D9A83D")
const ENERGY := Color("#65A9B8")
const THREAT := Color("#C92F4E")
const BOSS := Color("#962754")
const MINT := Color("#75C4B2")
const THERMAL := Color("#E45F36")
const TOXIN := Color("#769A32")
const CRYO := Color("#3E91B7")
const ARC := Color("#9B59B6")

const PHASE2_FAMILIES := [
	"player_chassis",
	"player_primary_weapon",
	"player_engine_modules",
	"player_engine_flame",
	"player_dash_effect",
	"player_primary_projectiles",
]
const ACTOR_VARIANTS := [
	"scrap_drone", "needle_drone", "spark_minelet", "chaser", "shooter",
	"controller", "shield_escort", "artillery_spotter", "rammer",
	"bulkhead_guard", "splitter_barge", "repair_tender", "drone_carrier",
	"turret", "mine", "interceptor_tower", "beam_sentinel", "generator",
	"boss_pylon", "colossus", "leviathan", "titan", "behemoth", "crown",
]

var _frames: Array[Dictionary] = []
var _assets: Array[Dictionary] = []
var _masters: Dictionary = {}
var _generation_failed := false
var _source_overrides
var _repeat_tile_records: Array[Dictionary] = []
var _palette_names := {
	"#141B24":"space_void",
	"#202833":"structure_recess",
	"#2E3945":"deck_shadow",
	"#44515E":"deck_base",
	"#596774":"blocker_top",
	"#222B35":"blocker_edge",
	"#E8EEF0":"neutral_highlight",
	"#D9A83D":"player_reward",
	"#65A9B8":"player_energy",
	"#C92F4E":"ordinary_threat",
	"#962754":"boss_threat",
	"#75C4B2":"support_recovery",
	"#E45F36":"thermal",
	"#769A32":"toxin",
	"#3E91B7":"cryo",
	"#9B59B6":"arc",
}


func _initialize() -> void:
	_ensure_directories()
	_source_overrides = PixelSourceOverrideCatalog.new()
	if not _source_overrides.load_manifest(SOURCE_OVERRIDE_MANIFEST_PATH):
		for message in _source_overrides.errors():
			push_error(message)
		quit(1)
		return
	var inventory_variant: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(INVENTORY_PATH)
	)
	var phase2_variant: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(PHASE2_CATALOG_PATH)
	)
	if not inventory_variant is Dictionary or not phase2_variant is Dictionary:
		push_error("Pixel inventory or Phase 2 catalog could not be parsed.")
		quit(1)
		return
	var inventory := Dictionary(inventory_variant)
	var phase2 := Dictionary(phase2_variant)
	_import_phase2(phase2)
	for asset_variant in Array(inventory.get("assets", [])):
		var inventory_asset := Dictionary(asset_variant)
		if String(inventory_asset["id"]) in PHASE2_FAMILIES:
			continue
		_produce_inventory_asset(inventory_asset)
	_publish_repeat_tiles()
	for unused_key in _source_overrides.unused_frame_keys():
		push_error("Pixel source override target was not published: %s" % unused_key)
		_generation_failed = true
	for message in _source_overrides.errors():
		push_error(message)
		_generation_failed = true
	if _generation_failed:
		quit(1)
		return
	_pack_and_publish(inventory)
	if _generation_failed:
		quit(1)
		return
	_build_review_boards()
	print(
		"COMPLETE_PIXEL_LIBRARY_OK assets=%d frames=%d"
		% [_assets.size(), _frames.size()]
	)
	quit(0)


func _ensure_directories() -> void:
	for path in [
		MASTER_ROOT,
		FRAME_SOURCE_ROOT,
		EVIDENCE_ROOT,
		OUTPUT_ATLAS_PATH.get_base_dir(),
	]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _import_phase2(catalog: Dictionary) -> void:
	for asset_variant in Array(catalog.get("assets", [])):
		var source_asset := Dictionary(asset_variant)
		var atlas := Image.load_from_file(
			"res://%s" % String(source_asset["atlas_path"])
		)
		var output_frames: Array[Dictionary] = []
		for frame_variant in Array(source_asset.get("frames", [])):
			var source_frame := Dictionary(frame_variant)
			var region_values := Array(source_frame["region"])
			var image := atlas.get_region(Rect2i(
				int(region_values[0]),
				int(region_values[1]),
				int(region_values[2]),
				int(region_values[3])
			))
			if image.get_width() != FRAME_SIZE or image.get_height() != FRAME_SIZE:
				image.resize(FRAME_SIZE, FRAME_SIZE, Image.INTERPOLATE_NEAREST)
			var source_metadata := source_frame.duplicate(true)
			source_metadata["production_method"] = String(
				source_asset.get("production_method", "imagegen_assisted")
			)
			source_metadata["source_catalog_path"] = (
				PHASE2_CATALOG_PATH.trim_prefix("res://")
			)
			var resolved := _resolve_frame_override(
				String(source_asset["id"]),
				String(source_frame["variant"]),
				int(source_frame["direction_index"]),
				String(source_frame["state"]),
				int(source_frame["sequence_index"])
			)
			if not resolved.is_empty():
				image = resolved["image"] as Image
				source_metadata.merge(
					Dictionary(resolved["metadata"]),
					true
				)
			var record := _frame_record(
				String(source_asset["id"]),
				String(source_frame["variant"]),
				int(source_frame["direction_index"]),
				String(source_frame["state"]),
				int(source_frame["sequence_index"]),
				image,
				source_metadata
			)
			output_frames.append(record)
		_assets.append(_asset_record(
			String(source_asset["id"]),
			String(source_asset.get("runtime_group", "")),
			Array(source_asset.get("runtime_layers", [])),
			output_frames,
			_asset_production_method(
				output_frames,
				String(source_asset.get("production_method", "imagegen_assisted"))
			)
		))


func _produce_inventory_asset(spec: Dictionary) -> void:
	var asset_id := String(spec["id"])
	var target := String(spec.get("target_representation", ""))
	var output_frames: Array[Dictionary] = []
	var declared_method := String(spec.get("production_method", "direct_pixel"))
	var fallback_method := (
		"legacy_procedural"
		if declared_method == "imagegen_assisted"
		else declared_method
	)
	if target == "raster_atlas":
		for frame_spec in _frame_specs(spec):
			var variant := String(frame_spec["variant"])
			var state := String(frame_spec["state"])
			var direction := int(frame_spec["direction"])
			var sequence := int(frame_spec.get("sequence", 0))
			var image := _make_sprite(asset_id, variant, state, direction, sequence)
			var source_metadata := {
				"production_method":fallback_method,
				"generator_path":"tools/design/generate_complete_pixel_library.gd",
			}
			var resolved := _resolve_frame_override(
				asset_id,
				variant,
				direction,
				state,
				sequence
			)
			if not resolved.is_empty():
				image = resolved["image"] as Image
				source_metadata.merge(
					Dictionary(resolved["metadata"]),
					true
				)
			var record := _frame_record(
				asset_id,
				variant,
				direction,
				state,
				sequence,
				image,
				source_metadata
			)
			output_frames.append(record)
			var master_key := "%s/%s" % [asset_id, variant]
			if not _masters.has(master_key):
				_masters[master_key] = image.duplicate()
				_write_semantic_svg(asset_id, variant, image)
	_assets.append(_asset_record(
		asset_id,
		String(spec.get("runtime_group", "")),
		Array(spec.get("semantic_layers", [])),
		output_frames,
		_asset_production_method(output_frames, fallback_method)
	))


func _resolve_frame_override(
	family: String,
	variant: String,
	direction: int,
	state: String,
	sequence: int
) -> Dictionary:
	return _source_overrides.resolve_frame(
		family,
		variant,
		direction,
		state,
		sequence
	)


func _frame_specs(spec: Dictionary) -> Array[Dictionary]:
	var asset_id := String(spec["id"])
	var variants := Array(spec.get("variants", []))
	var states := Array(spec.get("states", ["static"]))
	var ceiling := int(spec.get("frame_ceiling", 0))
	var result: Array[Dictionary] = []
	match asset_id:
		"mobile_enemy_set":
			for variant_value in variants:
				for slot in 8:
					result.append(_spec(String(variant_value), slot * 2, "move"))
				result.append(_spec(String(variant_value), 0, "attack_startup"))
				result.append(_spec(String(variant_value), 0, "attack_active"))
		"stationary_enemy_set":
			for variant_value in variants:
				for slot in 8:
					result.append(_spec(String(variant_value), slot * 2, "idle"))
				result.append(_spec(String(variant_value), 0, "attack_startup"))
		"boss_set":
			for variant_value in variants:
				for slot in 8:
					result.append(_spec(String(variant_value), slot * 2, "read"))
				for state in ["startup", "active", "recovery", "phase_transition"]:
					result.append(_spec(String(variant_value), 0, state))
		"hostile_projectile_affinities":
			for variant_value in variants:
				for state in ["standard_0", "affinity_motion_0", "affinity_motion_1"]:
					result.append(_spec(String(variant_value), 0, state))
		"secondary_seeker":
			for slot in 8:
				for state in ["flight_0", "flight_1"]:
					result.append(_spec("seeker_missile", slot * 2, state))
		"secondary_escort_drone":
			for slot in 8:
				for state in ["follow", "fire"]:
					result.append(_spec("drone", slot * 2, state))
			result.append(_spec("drone_shot", 0, "fire"))
		"impact_effects":
			for variant_value in variants:
				for sequence in 4:
					result.append(
						_spec(String(variant_value), 0, "frame_%d" % sequence, sequence)
					)
		"reward_crate":
			for variant_value in variants:
				for state in ["intact", "opening", "opened"]:
					result.append(_spec(String(variant_value), 0, state))
		"upgrade_card_icons":
			for variant_value in variants:
				result.append(_spec(String(variant_value), 0, "normal"))
		"hud_action_icons":
			for variant_value in variants:
				result.append(_spec(String(variant_value), 0, "ready"))
		"experience_shards":
			for variant_value in variants:
				result.append(_spec(String(variant_value), 0, "idle"))
		_:
			var direction_count := int(spec.get("directions", 0))
			var direction_values: Array[int] = [0]
			if direction_count > 0:
				direction_values.clear()
				for slot in direction_count:
					direction_values.append(
						roundi(float(slot) * 16.0 / float(direction_count)) % 16
					)
			for variant_value in variants:
				for direction in direction_values:
					for state_value in states:
						result.append(
							_spec(String(variant_value), direction, String(state_value))
						)
	if ceiling > 0 and result.size() > ceiling:
		result.resize(ceiling)
	return result


func _spec(
	variant: String,
	direction: int,
	state: String,
	sequence: int = 0
) -> Dictionary:
	return {
		"variant":variant,
		"direction":direction,
		"state":state,
		"sequence":sequence,
	}


func _asset_record(
	asset_id: String,
	runtime_group: String,
	layers: Array,
	frames: Array[Dictionary],
	method: String
) -> Dictionary:
	return {
		"id":asset_id,
		"family":asset_id,
		"runtime_group":runtime_group,
		"runtime_layers":layers,
		"approval_status":"approved",
		"production_method":method,
		"atlas_path":"pixel-art-production/runtime/atlases/cardborne-pixel-atlas.png",
		"atlas_sha256":"",
		"atlas_size":[0, 0],
		"frame_size":[FRAME_SIZE, FRAME_SIZE],
		"cell_size":[CELL_SIZE, CELL_SIZE],
		"padding":2,
		"extrude":1,
		"frames":frames,
	}


func _asset_production_method(
	frames: Array[Dictionary],
	fallback: String
) -> String:
	var methods := {}
	for frame in frames:
		var method := String(frame.get("production_method", fallback))
		methods[method] = true
	if methods.is_empty():
		return fallback
	if methods.size() == 1:
		return String(methods.keys()[0])
	return "mixed"


func _frame_record(
	family: String,
	variant: String,
	direction: int,
	state: String,
	sequence: int,
	image: Image,
	source: Dictionary
) -> Dictionary:
	var frame := {
		"key":"%s/%s/%d/%s/%d" % [family, variant, direction, state, sequence],
		"id":"%s_%02d_%s_%d" % [variant, direction, state, sequence],
		"atlas_index":_frames.size(),
		"region":[0, 0, FRAME_SIZE, FRAME_SIZE],
		"cell_region":[0, 0, CELL_SIZE, CELL_SIZE],
		"pivot":Array(source.get("pivot", [32, 32])),
		"anchors":Dictionary(source.get("anchors", {})).duplicate(true),
		"variant":variant,
		"direction_index":direction,
		"state":state,
		"sequence_index":sequence,
		"duration_ms":int(source.get("duration_ms", 0)),
		"source_sha256":String(source.get("source_sha256", "")),
		"_image":image,
		"family":family,
	}
	for field in [
		"production_method",
		"source_catalog_path",
		"generator_path",
		"approved_source_path",
		"approved_source_sha256",
		"raw_source_path",
		"raw_source_sha256",
		"prompt_path",
		"prompt_sha256",
		"derivation",
		"source_transform",
	]:
		if source.has(field):
			frame[field] = source[field]
	_frames.append(frame)
	return frame


func _make_sprite(
	asset_id: String,
	variant: String,
	state: String,
	direction: int,
	sequence: int
) -> Image:
	var image := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	match asset_id:
		"world_floor_void_tiles", "wall_cover_tiles", "water_void_edge_tiles":
			_draw_world_tile(image, asset_id, variant)
		"arc_surge_strip", "breakable_bulkhead", "transit_gate", "repair_field", "overdrive_field", "reward_crate":
			_draw_facility(image, asset_id, variant, state)
		"mobile_enemy_set":
			image = _rotated(
				_actor_master(variant, state, false, false),
				float(direction) * TAU / 16.0
			)
		"stationary_enemy_set":
			image = _rotated(
				_actor_master(variant, state, false, true),
				float(direction) * TAU / 16.0
			)
		"boss_set":
			image = _rotated(
				_actor_master(variant, state, true, false),
				float(direction) * TAU / 16.0
			)
		"hostile_projectile_affinities", "secondary_seeker", "secondary_orbit_blades", "secondary_wake_mines", "secondary_escort_drone":
			_draw_weapon_sprite(image, asset_id, variant, state, sequence)
			if direction != 0:
				image = _rotated(image, float(direction) * TAU / 16.0)
		"impact_effects":
			_draw_impact(image, variant, sequence)
		"experience_shards", "repair_pickup", "experience_recall_pickup":
			_draw_pickup(image, asset_id, variant, state)
		"hud_action_icons", "upgrade_card_icons":
			_draw_glyph(image, variant, asset_id == "upgrade_card_icons")
		_:
			_draw_glyph(image, variant, false)
	return image


func _draw_world_tile(image: Image, asset_id: String, variant: String) -> void:
	if asset_id == "world_floor_void_tiles":
		var base := SPACE if variant == "space_void" else DECK
		image.fill(base)
		if variant == "floor_light":
			_rect(image, Rect2i(0, 0, 64, 64), BLOCKER)
		elif variant == "floor_mid":
			_rect(image, Rect2i(0, 0, 64, 64), DECK)
		elif variant == "floor_dark":
			_rect(image, Rect2i(0, 0, 64, 64), SHADOW)
		elif variant == "floor_patch_2x2":
			_rect(image, Rect2i(0, 0, 32, 32), BLOCKER)
			_rect(image, Rect2i(32, 32, 32, 32), SHADOW)
		if variant != "space_void":
			_line(image, Vector2i(0, 0), Vector2i(63, 0), EDGE, 2)
			_line(image, Vector2i(0, 32), Vector2i(63, 32), SHADOW, 1)
			_line(image, Vector2i(32, 0), Vector2i(32, 63), SHADOW, 1)
		return
	if asset_id == "water_void_edge_tiles":
		image.fill(SPACE)
		_rect(image, Rect2i(0, 0, 64, 42), CRYO)
		_rect(image, Rect2i(0, 40, 64, 4), ENERGY)
		if "corner" in variant:
			_rect(image, Rect2i(40, 0, 24, 44), SPACE)
		if variant == "channel_cap":
			_rect(image, Rect2i(20, 0, 24, 44), SPACE)
		return
	image.fill(Color.TRANSPARENT)
	var connections := {
		"north":Vector2i(32, 0),
		"east":Vector2i(63, 32),
		"south":Vector2i(32, 63),
		"west":Vector2i(0, 32),
	}
	_rect(image, Rect2i(20, 20, 24, 24), BLOCKER)
	_rect(image, Rect2i(24, 24, 16, 16), SHADOW)
	for name in connections:
		if name in variant or variant == "all":
			_line(image, Vector2i(32, 32), connections[name], BLOCKER, 11)
			_line(image, Vector2i(32, 32), connections[name], SHADOW, 5)
	_rect(image, Rect2i(24, 20, 16, 3), LIGHT)


func _draw_facility(
	image: Image,
	asset_id: String,
	variant: String,
	state: String
) -> void:
	match asset_id:
		"arc_surge_strip":
			var vertical := "vertical" in variant
			if vertical:
				_rect(image, Rect2i(27, 4, 10, 56), EDGE)
				for y in range(8, 58, 12):
					_rect(image, Rect2i(29, y, 6, 5), ARC)
			else:
				_rect(image, Rect2i(4, 27, 56, 10), EDGE)
				for x in range(8, 58, 12):
					_rect(image, Rect2i(x, 29, 5, 6), ARC)
		"breakable_bulkhead":
			_rect(image, Rect2i(6, 12, 52, 40), EDGE)
			_rect(image, Rect2i(10, 16, 44, 32), BLOCKER)
			if state in ["cracked", "critical"]:
				_line(image, Vector2i(18, 18), Vector2i(32, 33), LIGHT, 3)
				_line(image, Vector2i(32, 33), Vector2i(24, 47), LIGHT, 3)
			if state == "destroyed":
				_rect(image, Rect2i(23, 12, 20, 40), Color.TRANSPARENT)
		"transit_gate":
			var glow := MINT if "a" in variant else ENERGY
			_rect(image, Rect2i(6, 8, 10, 48), EDGE)
			_rect(image, Rect2i(48, 8, 10, 48), EDGE)
			_rect(image, Rect2i(10, 12, 4, 40), glow)
			_rect(image, Rect2i(50, 12, 4, 40), glow)
			if state != "inactive":
				_line(image, Vector2i(17, 32), Vector2i(47, 32), glow, 3)
		"repair_field", "overdrive_field":
			var accent := MINT if asset_id == "repair_field" else GOLD
			_diamond(image, Vector2i(32, 32), 24, EDGE)
			_diamond(image, Vector2i(32, 32), 19, SHADOW)
			_circle(image, Vector2i(32, 32), 10, accent)
			if asset_id == "repair_field":
				_rect(image, Rect2i(29, 22, 6, 20), LIGHT)
				_rect(image, Rect2i(22, 29, 20, 6), LIGHT)
			else:
				_line(image, Vector2i(22, 38), Vector2i(31, 24), LIGHT, 5)
				_line(image, Vector2i(31, 24), Vector2i(42, 30), LIGHT, 5)
			if state in ["warning", "depleted"]:
				_overlay_checker(image, Color(accent, 0.45))
		"reward_crate":
			_rect(image, Rect2i(10, 15, 44, 36), EDGE)
			_rect(image, Rect2i(14, 19, 36, 28), BLOCKER)
			_rect(image, Rect2i(28, 19, 8, 28), GOLD)
			_rect(image, Rect2i(14, 28, 36, 6), SHADOW)
			if state == "opening":
				_rect(image, Rect2i(14, 10, 36, 7), LIGHT)
			elif state == "opened":
				_rect(image, Rect2i(14, 8, 36, 6), LIGHT)
				_rect(image, Rect2i(18, 18, 28, 24), SPACE)
				_circle(image, Vector2i(32, 29), 7, MINT if "repair" in variant else ENERGY)


func _actor_master(
	variant: String,
	state: String,
	is_boss: bool,
	is_stationary: bool
) -> Image:
	var image := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var index := ACTOR_VARIANTS.find(variant)
	if index < 0:
		index = _stable_index(variant)
	var threat_color := BOSS if is_boss else THREAT
	var extent := 27 if is_boss else (21 if is_stationary else 18)
	var shape := index % 7
	match shape:
		0:
			_poly(image, PackedVector2Array([
				Vector2(32 + extent, 32),
				Vector2(22, 16),
				Vector2(10, 20),
				Vector2(18, 32),
				Vector2(10, 44),
				Vector2(22, 48),
			]), EDGE)
			_poly(image, PackedVector2Array([
				Vector2(32 + extent - 5, 32),
				Vector2(23, 21),
				Vector2(16, 23),
				Vector2(23, 32),
				Vector2(16, 41),
				Vector2(23, 43),
			]), threat_color)
		1:
			_diamond(image, Vector2i(32, 32), extent, EDGE)
			_diamond(image, Vector2i(33, 32), extent - 5, threat_color)
			_rect(image, Rect2i(32, 25, extent, 14), threat_color)
		2:
			_circle(image, Vector2i(30, 32), extent, EDGE)
			_circle(image, Vector2i(30, 32), extent - 5, threat_color)
			_rect(image, Rect2i(30, 27, extent + 2, 10), EDGE)
			_rect(image, Rect2i(32, 29, extent, 6), LIGHT)
		3:
			_rect(image, Rect2i(10, 17, 39 + (8 if is_boss else 0), 30), EDGE)
			_rect(image, Rect2i(15, 22, 34 + (8 if is_boss else 0), 20), threat_color)
			_diamond(image, Vector2i(52, 32), 10, EDGE)
		4:
			_poly(image, PackedVector2Array([
				Vector2(56, 32), Vector2(38, 13), Vector2(16, 13),
				Vector2(8, 32), Vector2(16, 51), Vector2(38, 51),
			]), EDGE)
			_poly(image, PackedVector2Array([
				Vector2(50, 32), Vector2(36, 19), Vector2(19, 19),
				Vector2(14, 32), Vector2(19, 45), Vector2(36, 45),
			]), threat_color)
		5:
			_circle(image, Vector2i(31, 32), extent, EDGE)
			_circle(image, Vector2i(31, 32), extent - 6, threat_color)
			_circle(image, Vector2i(31, 32), extent - 12, SPACE)
			_rect(image, Rect2i(31, 28, extent + 3, 8), threat_color)
		_:
			_poly(image, PackedVector2Array([
				Vector2(57, 32), Vector2(39, 20), Vector2(26, 11),
				Vector2(11, 17), Vector2(17, 32), Vector2(11, 47),
				Vector2(26, 53), Vector2(39, 44),
			]), EDGE)
			_poly(image, PackedVector2Array([
				Vector2(50, 32), Vector2(36, 25), Vector2(25, 18),
				Vector2(17, 21), Vector2(23, 32), Vector2(17, 43),
				Vector2(25, 46), Vector2(36, 39),
			]), threat_color)
	if is_stationary:
		_rect(image, Rect2i(12, 48, 38, 7), EDGE)
		_rect(image, Rect2i(18, 44, 26, 7), SHADOW)
	if is_boss:
		_rect(image, Rect2i(9, 27, 10, 10), BOSS)
		_rect(image, Rect2i(20, 8, 9, 12), BOSS)
		_rect(image, Rect2i(20, 44, 9, 12), BOSS)
	var core_color := LIGHT
	if state in ["attack_startup", "startup"]:
		core_color = GOLD
	elif state in ["attack_active", "active", "phase_transition"]:
		core_color = THERMAL
	_circle(image, Vector2i(34, 32), 7 if is_boss else 5, EDGE)
	_circle(image, Vector2i(34, 32), 4 if is_boss else 3, core_color)
	if state in ["attack_active", "active"]:
		_rect(image, Rect2i(52, 29, 9, 6), core_color)
	return image


func _draw_weapon_sprite(
	image: Image,
	asset_id: String,
	variant: String,
	state: String,
	sequence: int
) -> void:
	if asset_id == "hostile_projectile_affinities":
		var accent := _affinity_color(variant)
		_rect(image, Rect2i(18, 27, 28, 10), EDGE)
		_diamond(image, Vector2i(45, 32), 10, accent)
		_circle(image, Vector2i(45, 32), 4, LIGHT)
		if state == "affinity_motion_0":
			_rect(image, Rect2i(11, 29, 10, 6), accent)
		elif state == "affinity_motion_1":
			_rect(image, Rect2i(7, 30, 14, 4), accent)
		return
	if asset_id == "secondary_orbit_blades":
		_poly(image, PackedVector2Array([
			Vector2(9, 35), Vector2(44, 16), Vector2(56, 20),
				Vector2(35, 31), Vector2(51, 39), Vector2(42, 47),
		]), EDGE)
		_poly(image, PackedVector2Array([
			Vector2(15, 34), Vector2(43, 21), Vector2(50, 22),
				Vector2(34, 29), Vector2(45, 39), Vector2(41, 42),
		]), GOLD)
		return
	if asset_id == "secondary_wake_mines":
		_circle(image, Vector2i(32, 32), 17, EDGE)
		_diamond(image, Vector2i(32, 32), 12, THERMAL)
		_circle(image, Vector2i(32, 32), 4 + sequence, LIGHT)
		return
	if asset_id == "secondary_escort_drone" and variant == "drone":
		_diamond(image, Vector2i(32, 32), 19, EDGE)
		_rect(image, Rect2i(18, 27, 28, 10), MINT)
		_circle(image, Vector2i(37, 32), 5, LIGHT)
		if state == "fire":
			_rect(image, Rect2i(48, 29, 10, 6), GOLD)
		return
	_rect(image, Rect2i(14, 27, 34, 10), EDGE)
	_poly(image, PackedVector2Array([
		Vector2(57, 32), Vector2(41, 21), Vector2(41, 43),
	]), GOLD if "seeker" in variant else MINT)
	_rect(image, Rect2i(10, 29, 10, 6), ENERGY)
	if state.ends_with("_1"):
		_rect(image, Rect2i(5, 30, 9, 4), LIGHT)


func _draw_impact(image: Image, variant: String, sequence: int) -> void:
	var accent := GOLD
	if variant == "enemy":
		accent = THREAT
	elif variant == "player_hull":
		accent = THERMAL
	elif variant == "barrier":
		accent = MINT
	elif variant == "breach_interrupt":
		accent = ARC
	var radius := 5 + sequence * 5
	for angle_index in 8:
		var direction := Vector2.RIGHT.rotated(float(angle_index) * TAU / 8.0)
		var start := Vector2(32, 32) + direction * float(maxi(1, radius - 4))
		var finish := Vector2(32, 32) + direction * float(radius)
		_line(image, Vector2i(start), Vector2i(finish), accent, 3)
	_circle(image, Vector2i(32, 32), maxi(1, 5 - sequence), LIGHT)


func _draw_pickup(
	image: Image,
	asset_id: String,
	variant: String,
	state: String
) -> void:
	if asset_id == "experience_shards":
		var radius := 7
		if variant == "medium":
			radius = 11
		elif variant == "large":
			radius = 15
		_diamond(image, Vector2i(32, 32), radius + 4, EDGE)
		_diamond(image, Vector2i(32, 32), radius, GOLD)
		_diamond(image, Vector2i(32, 29), maxi(2, radius / 3), LIGHT)
		return
	var accent := MINT if asset_id == "repair_pickup" else ENERGY
	_circle(image, Vector2i(32, 32), 19, EDGE)
	_circle(image, Vector2i(32, 32), 15, accent)
	if asset_id == "repair_pickup":
		_rect(image, Rect2i(29, 20, 6, 24), LIGHT)
		_rect(image, Rect2i(20, 29, 24, 6), LIGHT)
	else:
		for angle_index in 4:
			var direction := Vector2.RIGHT.rotated(float(angle_index) * TAU / 4.0)
			_line(
				image,
				Vector2i(Vector2(32, 32) + direction * 5.0),
				Vector2i(Vector2(32, 32) + direction * 13.0),
				LIGHT,
				4
			)
	if state.ends_with("_1"):
		_circle(image, Vector2i(32, 32), 22, Color(LIGHT, 0.7), false)


func _draw_glyph(image: Image, variant: String, framed: bool) -> void:
	var accent := _glyph_color(variant)
	if framed:
		_rect(image, Rect2i(10, 10, 44, 44), EDGE)
		_rect(image, Rect2i(14, 14, 36, 36), SHADOW)
	var center := Vector2i(32, 32)
	var mode := _stable_index(variant) % 8
	match mode:
		0:
			_diamond(image, center, 14, accent)
			_circle(image, center, 5, LIGHT)
		1:
			_circle(image, center, 15, accent)
			_rect(image, Rect2i(29, 20, 6, 24), LIGHT)
			_rect(image, Rect2i(20, 29, 24, 6), LIGHT)
		2:
			_poly(image, PackedVector2Array([
				Vector2(17, 38), Vector2(34, 17), Vector2(31, 29),
				Vector2(47, 26), Vector2(28, 48), Vector2(32, 35),
			]), accent)
		3:
			_rect(image, Rect2i(17, 27, 31, 10), accent)
			_poly(image, PackedVector2Array([
				Vector2(50, 32), Vector2(39, 21), Vector2(39, 43),
			]), LIGHT)
		4:
			for offset in [-9, 0, 9]:
				_circle(image, center + Vector2i(offset, 0), 4, accent)
		5:
			_diamond(image, center, 16, accent)
			_diamond(image, center, 9, SPACE)
		6:
			_line(image, Vector2i(19, 43), Vector2i(32, 19), accent, 6)
			_line(image, Vector2i(32, 19), Vector2i(45, 43), accent, 6)
			_line(image, Vector2i(24, 35), Vector2i(40, 35), LIGHT, 4)
		_:
			_circle(image, center, 15, EDGE)
			for angle_index in 6:
				var direction := Vector2.RIGHT.rotated(float(angle_index) * TAU / 6.0)
				_line(
					image,
					Vector2i(Vector2(center) + direction * 7.0),
					Vector2i(Vector2(center) + direction * 16.0),
					accent,
					4
				)


func _pack_and_publish(inventory: Dictionary) -> void:
	var rows := ceili(float(_frames.size()) / float(ATLAS_COLUMNS))
	var atlas_width := ATLAS_COLUMNS * CELL_STRIDE - 2
	var atlas_height := rows * CELL_STRIDE - 2
	var atlas := Image.create(
		atlas_width, atlas_height, false, Image.FORMAT_RGBA8
	)
	atlas.fill(Color.TRANSPARENT)
	for index in _frames.size():
		var frame := _frames[index]
		var column := index % ATLAS_COLUMNS
		var row := index / ATLAS_COLUMNS
		var cell_origin := Vector2i(column * CELL_STRIDE, row * CELL_STRIDE)
		var region_origin := cell_origin + Vector2i.ONE
		var image := frame["_image"] as Image
		_publish_frame_sources(frame, image)
		atlas.blit_rect(image, Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE), region_origin)
		_extrude(atlas, image, cell_origin)
		frame["atlas_index"] = index
		frame["region"] = [
			region_origin.x, region_origin.y, FRAME_SIZE, FRAME_SIZE
		]
		frame["cell_region"] = [
			cell_origin.x, cell_origin.y, CELL_SIZE, CELL_SIZE
		]
		frame.erase("_image")
		frame.erase("family")
	var atlas_absolute := ProjectSettings.globalize_path(OUTPUT_ATLAS_PATH)
	var save_error := atlas.save_png(atlas_absolute)
	if save_error != OK:
		push_error("Could not save the complete pixel atlas: %s" % save_error)
		quit(1)
		return
	var atlas_hash := FileAccess.get_sha256(atlas_absolute)
	for asset in _assets:
		asset["atlas_sha256"] = atlas_hash
		asset["atlas_size"] = [atlas_width, atlas_height]
	var runtime_groups := {}
	for asset in _assets:
		var group := String(asset.get("runtime_group", ""))
		runtime_groups[group] = int(runtime_groups.get(group, 0)) + 1
	var catalog := {
		"schema_version":1,
		"generated_from":[
			"pixel-art-production/assets/asset-inventory.json",
			"pixel-art-production/assets/generated/approved/phase-2/catalog.json",
			SOURCE_OVERRIDE_MANIFEST_PATH.trim_prefix("res://"),
		],
		"source_overrides":_source_overrides.catalog_summary(),
		"runtime_repeat_tiles":_repeat_tile_records,
		"asset_count":_assets.size(),
		"frame_count":_frames.size(),
		"runtime_groups":runtime_groups,
		"assets":_assets,
		"inventory_schema_version":int(inventory.get("schema_version", 0)),
	}
	_write_json(OUTPUT_CATALOG_PATH, catalog)
	var family_ledger: Array[Dictionary] = []
	for asset in _assets:
		family_ledger.append({
			"id":String(asset["id"]),
			"runtime_group":String(asset["runtime_group"]),
			"frame_count":Array(asset["frames"]).size(),
			"production_method":String(asset["production_method"]),
		})
	var ledger := {
		"schema_version":1,
		"inventory_assets":Array(inventory.get("assets", [])).size(),
		"published_assets":_assets.size(),
		"published_frames":_frames.size(),
		"atlas_size":[atlas_width, atlas_height],
		"atlas_sha256":atlas_hash,
		"families":family_ledger,
	}
	_write_json("%s/coverage-ledger.json" % EVIDENCE_ROOT, ledger)


func _publish_frame_sources(frame: Dictionary, image: Image) -> void:
	var family := String(frame["family"])
	var frame_id := String(frame["id"])
	var directory := "%s/%s/%s" % [FRAME_SOURCE_ROOT, family, frame_id]
	var layer_directory := "%s/layers" % directory
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(layer_directory)
	)
	var master_path := "%s/master.png" % directory
	var save_error := image.save_png(ProjectSettings.globalize_path(master_path))
	if save_error != OK:
		push_error("Could not save pixel frame master: %s" % master_path)
		_generation_failed = true
		return
	var source_hash := FileAccess.get_sha256(
		ProjectSettings.globalize_path(master_path)
	)
	var origin_source_hash := String(frame.get("source_sha256", ""))
	if not origin_source_hash.is_empty():
		frame["origin_source_sha256"] = origin_source_hash
	frame["source_sha256"] = source_hash
	var layers_by_role := {}
	var visible_pixel_count := 0
	for y in FRAME_SIZE:
		for x in FRAME_SIZE:
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			visible_pixel_count += 1
			var color_key := "#%s" % color.to_html(false).to_upper()
			var role := String(
				_palette_names.get(
					color_key,
					"palette_%s" % color_key.trim_prefix("#")
				)
			)
			if not layers_by_role.has(role):
				var layer := Image.create(
					FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8
				)
				layer.fill(Color.TRANSPARENT)
				layers_by_role[role] = layer
			(layers_by_role[role] as Image).set_pixel(x, y, color)
	var reassembled := Image.create(
		FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8
	)
	reassembled.fill(Color.TRANSPARENT)
	var layer_records: Array[Dictionary] = []
	var roles := layers_by_role.keys()
	roles.sort()
	for role_variant in roles:
		var role := String(role_variant)
		var layer := layers_by_role[role] as Image
		var layer_path := "%s/%s.png" % [layer_directory, role]
		layer.save_png(ProjectSettings.globalize_path(layer_path))
		for y in FRAME_SIZE:
			for x in FRAME_SIZE:
				var layer_color := layer.get_pixel(x, y)
				if layer_color.a > 0.0:
					reassembled.set_pixel(x, y, layer_color)
		layer_records.append({
			"role":role,
			"path":layer_path.trim_prefix("res://"),
			"sha256":FileAccess.get_sha256(
				ProjectSettings.globalize_path(layer_path)
			),
		})
	var difference_count := 0
	for y in FRAME_SIZE:
		for x in FRAME_SIZE:
			var rebuilt_color := reassembled.get_pixel(x, y)
			var source_color := image.get_pixel(x, y)
			# Fully transparent RGB bytes do not contribute a visible pixel and
			# may differ after PNG import. Semantic equality is exact for every
			# visible cell.
			if rebuilt_color.a <= 0.0 and source_color.a <= 0.0:
				continue
			if not rebuilt_color.is_equal_approx(source_color):
				difference_count += 1
	if difference_count > 0:
		push_error("Semantic reassembly differs for %s" % String(frame["key"]))
		_generation_failed = true
		return
	var manifest := {
		"schema_version":1,
		"approval_status":"approved",
		"family":family,
		"frame_key":String(frame["key"]),
		"variant":String(frame["variant"]),
		"direction_index":int(frame["direction_index"]),
		"state":String(frame["state"]),
		"sequence_index":int(frame["sequence_index"]),
		"pivot":Array(frame["pivot"]),
		"anchors":Dictionary(frame["anchors"]).duplicate(true),
		"master_path":master_path.trim_prefix("res://"),
		"source_sha256":source_hash,
		"semantic_layers":layer_records,
		"visible_pixel_count":visible_pixel_count,
		"reassembly_difference_pixels":difference_count,
	}
	if frame.has("approved_source_path"):
		manifest["production_method"] = String(
			frame.get("production_method", "")
		)
		for field in [
			"origin_source_sha256",
			"approved_source_path",
			"approved_source_sha256",
			"raw_source_path",
			"raw_source_sha256",
			"prompt_path",
			"prompt_sha256",
			"derivation",
			"source_transform",
		]:
			if frame.has(field):
				manifest[field] = frame[field]
	_write_json("%s/manifest.json" % directory, manifest)


func _publish_repeat_tiles() -> void:
	var tile_root := "res://pixel-art-production/runtime/tiles"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(tile_root))
	_repeat_tile_records.clear()
	var outputs := {
		"hangar_floor":"hangar-floor.png",
		"hangar_wall":"hangar-wall.png",
		"hangar_water":"hangar-water.png",
	}
	for runtime_key_variant in outputs:
		var runtime_key := String(runtime_key_variant)
		var resolved: Dictionary = _source_overrides.repeat_tile(runtime_key)
		if resolved.is_empty():
			push_error("Missing approved repeat tile override: %s" % runtime_key)
			_generation_failed = true
			continue
		var image := resolved["image"] as Image
		var output_path := "%s/%s" % [tile_root, String(outputs[runtime_key])]
		var save_error := image.save_png(
			ProjectSettings.globalize_path(output_path)
		)
		if save_error != OK:
			push_error("Could not publish repeat tile: %s" % output_path)
			_generation_failed = true
			continue
		var record := Dictionary(resolved["metadata"]).duplicate(true)
		record["runtime_key"] = runtime_key
		record["output_path"] = output_path.trim_prefix("res://")
		record["output_sha256"] = FileAccess.get_sha256(
			ProjectSettings.globalize_path(output_path)
		)
		record["size"] = [image.get_width(), image.get_height()]
		record["repeat_safe"] = true
		_repeat_tile_records.append(record)


func _extrude(atlas: Image, image: Image, cell_origin: Vector2i) -> void:
	var region := cell_origin + Vector2i.ONE
	for x in FRAME_SIZE:
		atlas.set_pixelv(
			Vector2i(region.x + x, cell_origin.y),
			image.get_pixel(x, 0)
		)
		atlas.set_pixelv(
			Vector2i(region.x + x, region.y + FRAME_SIZE),
			image.get_pixel(x, FRAME_SIZE - 1)
		)
	for y in FRAME_SIZE:
		atlas.set_pixelv(
			Vector2i(cell_origin.x, region.y + y),
			image.get_pixel(0, y)
		)
		atlas.set_pixelv(
			Vector2i(region.x + FRAME_SIZE, region.y + y),
			image.get_pixel(FRAME_SIZE - 1, y)
		)
	atlas.set_pixelv(cell_origin, image.get_pixel(0, 0))
	atlas.set_pixelv(
		Vector2i(region.x + FRAME_SIZE, cell_origin.y),
		image.get_pixel(FRAME_SIZE - 1, 0)
	)
	atlas.set_pixelv(
		Vector2i(cell_origin.x, region.y + FRAME_SIZE),
		image.get_pixel(0, FRAME_SIZE - 1)
	)
	atlas.set_pixelv(
		Vector2i(region.x + FRAME_SIZE, region.y + FRAME_SIZE),
		image.get_pixel(FRAME_SIZE - 1, FRAME_SIZE - 1)
	)


func _build_review_boards() -> void:
	var groups := {
		"03-core-field":[
			"world_floor_void_tiles", "wall_cover_tiles",
			"mobile_enemy_set", "hostile_projectile_affinities",
			"experience_shards", "repair_pickup", "reward_crate",
		],
		"04-world-functions":[
			"water_void_edge_tiles", "arc_surge_strip",
			"breakable_bulkhead", "transit_gate",
			"repair_field", "overdrive_field",
		],
		"05-enemies":["mobile_enemy_set", "stationary_enemy_set"],
		"06-secondaries":[
			"secondary_seeker", "secondary_orbit_blades",
			"secondary_wake_mines", "secondary_escort_drone",
		],
		"07-bosses":["boss_set", "impact_effects"],
		"08-ui":["hud_action_icons", "upgrade_card_icons"],
	}
	for board_name in groups:
		var images: Array[Image] = []
		var entries: Array[Dictionary] = []
		for family in groups[board_name]:
			for asset in _assets:
				if String(asset["id"]) != family:
					continue
				var seen := {}
				for frame in Array(asset["frames"]):
					var variant := String(frame["variant"])
					if seen.has(variant):
						continue
					seen[variant] = true
					var master_key := "%s/%s" % [family, variant]
					if _masters.has(master_key):
						images.append((_masters[master_key] as Image).duplicate())
						entries.append({
							"family":family,
							"variant":variant,
							"index":images.size() - 1,
						})
		_write_board(String(board_name), images, entries)


func _write_board(
	name: String,
	images: Array[Image],
	entries: Array[Dictionary]
) -> void:
	if images.is_empty():
		return
	var columns := 8
	var scale := 2
	var tile := FRAME_SIZE * scale
	var rows := ceili(float(images.size()) / float(columns))
	var board := Image.create(columns * tile, rows * tile, false, Image.FORMAT_RGBA8)
	board.fill(SHADOW)
	for index in images.size():
		var scaled := images[index].duplicate()
		scaled.resize(tile, tile, Image.INTERPOLATE_NEAREST)
		board.blit_rect(
			scaled,
			Rect2i(0, 0, tile, tile),
			Vector2i((index % columns) * tile, (index / columns) * tile)
		)
	board.save_png(ProjectSettings.globalize_path("%s/%s.png" % [EVIDENCE_ROOT, name]))
	_write_json("%s/%s.json" % [EVIDENCE_ROOT, name], {
		"schema_version":1,
		"columns":columns,
		"tile_size":tile,
		"entries":entries,
	})


func _write_semantic_svg(asset_id: String, variant: String, image: Image) -> void:
	var groups := {}
	for y in FRAME_SIZE:
		var x := 0
		while x < FRAME_SIZE:
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				x += 1
				continue
			var color_key := "#%s" % color.to_html(false).to_upper()
			var start := x
			x += 1
			while (
				x < FRAME_SIZE
				and image.get_pixel(x, y).to_html(false).to_upper()
					== color.to_html(false).to_upper()
				and image.get_pixel(x, y).a > 0.0
			):
				x += 1
			if not groups.has(color_key):
				groups[color_key] = []
			groups[color_key].append(
				'<rect x="%d" y="%d" width="%d" height="1"/>'
				% [start, y, x - start]
			)
	var lines: Array[String] = [
		'<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64" shape-rendering="crispEdges">',
		"  <metadata>Editable canonical pixel master; palette-role groups preserve semantic color ownership.</metadata>",
	]
	for color_key in groups:
		var group_name := String(_palette_names.get(color_key, "palette_%s" % color_key.trim_prefix("#")))
		lines.append('  <g id="%s" fill="%s">' % [group_name, color_key])
		for rect_line in groups[color_key]:
			lines.append("    %s" % rect_line)
		lines.append("  </g>")
	lines.append("</svg>")
	var directory := "%s/%s" % [MASTER_ROOT, asset_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var file := FileAccess.open(
		ProjectSettings.globalize_path("%s/%s.svg" % [directory, variant]),
		FileAccess.WRITE
	)
	file.store_string("\n".join(lines) + "\n")


func _write_json(path: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(path.get_base_dir())
	)
	var file := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t") + "\n")


func _rotated(source: Image, angle: float) -> Image:
	if is_zero_approx(angle):
		return source
	var result := Image.create(FRAME_SIZE, FRAME_SIZE, false, Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var center := Vector2(31.5, 31.5)
	var sine := sin(-angle)
	var cosine := cos(-angle)
	for y in FRAME_SIZE:
		for x in FRAME_SIZE:
			var delta := Vector2(float(x), float(y)) - center
			var source_position := Vector2(
				delta.x * cosine - delta.y * sine,
				delta.x * sine + delta.y * cosine
			) + center
			var sx := roundi(source_position.x)
			var sy := roundi(source_position.y)
			if sx >= 0 and sx < FRAME_SIZE and sy >= 0 and sy < FRAME_SIZE:
				result.set_pixel(x, y, source.get_pixel(sx, sy))
	return result


func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(FRAME_SIZE, rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(FRAME_SIZE, rect.end.x)):
			image.set_pixel(x, y, color)


func _line(
	image: Image,
	from: Vector2i,
	to: Vector2i,
	color: Color,
	width: int = 1
) -> void:
	var delta := to - from
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps <= 0:
		_circle(image, from, maxi(0, width / 2), color)
		return
	for step in steps + 1:
		var point := Vector2(from).lerp(Vector2(to), float(step) / float(steps))
		_circle(image, Vector2i(point.round()), maxi(0, width / 2), color)


func _circle(
	image: Image,
	center: Vector2i,
	radius: int,
	color: Color,
	filled: bool = true
) -> void:
	var inner := maxi(0, radius - 2)
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x < 0 or x >= FRAME_SIZE or y < 0 or y >= FRAME_SIZE:
				continue
			var distance := Vector2i(x, y).distance_squared_to(center)
			if distance <= radius * radius and (
				filled or distance >= inner * inner
			):
				image.set_pixel(x, y, color)


func _diamond(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		var half_width := radius - absi(y - center.y)
		for x in range(center.x - half_width, center.x + half_width + 1):
			if x >= 0 and x < FRAME_SIZE and y >= 0 and y < FRAME_SIZE:
				image.set_pixel(x, y, color)


func _poly(image: Image, points: PackedVector2Array, color: Color) -> void:
	if points.size() < 3:
		return
	var minimum_y := FRAME_SIZE - 1
	var maximum_y := 0
	for point in points:
		minimum_y = mini(minimum_y, floori(point.y))
		maximum_y = maxi(maximum_y, ceili(point.y))
	for y in range(maxi(0, minimum_y), mini(FRAME_SIZE - 1, maximum_y) + 1):
		var intersections: Array[float] = []
		for index in points.size():
			var a := points[index]
			var b := points[(index + 1) % points.size()]
			if (
				(a.y <= float(y) and b.y > float(y))
				or (b.y <= float(y) and a.y > float(y))
			):
				intersections.append(
					a.x + (float(y) - a.y) * (b.x - a.x) / (b.y - a.y)
				)
		intersections.sort()
		for index in range(0, intersections.size() - 1, 2):
			for x in range(
				maxi(0, ceili(intersections[index])),
				mini(FRAME_SIZE - 1, floori(intersections[index + 1])) + 1
			):
				image.set_pixel(x, y, color)


func _overlay_checker(image: Image, color: Color) -> void:
	for y in range(0, FRAME_SIZE, 8):
		for x in range(0, FRAME_SIZE, 8):
			if ((x + y) / 8) % 2 == 0:
				_rect(image, Rect2i(x, y, 4, 4), color)


func _stable_index(value: String) -> int:
	var result := 17
	for character in value.to_utf8_buffer():
		result = posmod(result * 31 + int(character), 104729)
	return result


func _affinity_color(variant: String) -> Color:
	match variant:
		"thermal":
			return THERMAL
		"toxin":
			return TOXIN
		"cryo":
			return CRYO
		"arc":
			return ARC
		"hybrid":
			return BOSS
		_:
			return THREAT


func _glyph_color(variant: String) -> Color:
	if "toxin" in variant or "contagion" in variant:
		return TOXIN
	if "thermal" in variant or "fire" in variant or "incendiary" in variant:
		return THERMAL
	if "cryo" in variant or "freeze" in variant or "coolant" in variant:
		return CRYO
	if (
		"hull" in variant or "aegis" in variant
		or "repair" in variant or "siphon" in variant
	):
		return MINT
	if (
		"thruster" in variant or "dash" in variant
		or "cycle" in variant or "accelerator" in variant
	):
		return ENERGY
	if "emp" in variant or "phase" in variant or "ion" in variant:
		return ARC
	return GOLD
