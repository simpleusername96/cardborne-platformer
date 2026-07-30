class_name VehicleVisualSystemRegistry
extends RefCounted

## Read-only ownership registry for migration and sheet validation. It reports
## catalog coverage but does not become a second descriptor or rendering owner.

const ActorCatalog = preload("res://scripts/presentation/components/vehicle_actor_visual_catalog.gd")
const ProjectileCatalog = preload("res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd")
const RewardCatalog = preload("res://scripts/presentation/components/vehicle_reward_visual_catalog.gd")
const EffectCatalog = preload("res://scripts/presentation/components/vehicle_effect_visual_catalog.gd")
const WorldCatalog = preload("res://scripts/presentation/components/vehicle_world_visual_catalog.gd")
const GlyphCatalog = preload("res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd")

const LEGACY_CATALOG_PATH := "res://pixel-art-production/runtime/catalog.json"
const COMPONENT_GEOMETRY_PATH := (
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)
const COMBAT_GEOMETRY_PATH := (
	"res://scripts/presentation/vehicle_combat_visual_library.gd"
)
const COMBAT_RENDERER_PATH := (
	"res://scripts/presentation/vehicle_combat_renderer.gd"
)
const WORLD_GEOMETRY_PATH := (
	"res://scripts/presentation/vehicle_world_mesh_builder.gd"
)
const MINIMAP_GEOMETRY_PATH := (
	"res://scripts/ui/vehicle_minimap_mesh_builder.gd"
)
const LEGACY_WORLD_RECIPE_PATH := (
	"res://pixel-art-production/runtime/atlases/space-hangar-v2/world-recipe.json"
)


static func ownership() -> Dictionary:
	return {
		&"actor": ActorCatalog.source_family_ids(),
		&"projectile": ProjectileCatalog.source_family_ids(),
		&"reward": RewardCatalog.source_family_ids(),
		&"effect": EffectCatalog.source_family_ids(),
		&"world": WorldCatalog.source_family_ids(),
		&"glyph": GlyphCatalog.source_family_ids(),
	}


static func owner_for_source_family(family: StringName) -> StringName:
	for owner in ownership():
		if family in Array(ownership()[owner]):
			return StringName(owner)
	return &""


static func provider_fingerprint() -> String:
	var records := PackedStringArray()
	for owner_variant in ownership():
		var owner := StringName(owner_variant)
		var families := PackedStringArray()
		for family in Array(ownership()[owner]):
			families.append(String(family))
		families.sort()
		records.append("%s=%s" % [String(owner), ",".join(families)])
	var stamps := PackedStringArray()
	for stamp in WorldCatalog.source_stamp_ids():
		stamps.append(String(stamp))
	stamps.sort()
	records.append("world_stamps=%s" % ",".join(stamps))
	_append_descriptor_records(records, "actor", ActorCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "projectile", ProjectileCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "reward", RewardCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "effect", EffectCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "world_field", WorldCatalog.FIELD_DESCRIPTORS)
	_append_descriptor_records(records, "world_facility", WorldCatalog.FACILITY_DESCRIPTORS)
	_append_descriptor_records(
		records,
		"glyph_upgrade_family",
		GlyphCatalog.UPGRADE_FAMILY_GLYPHS
	)
	records.append(
		"component_geometry=%s"
		% FileAccess.get_sha256(COMPONENT_GEOMETRY_PATH)
	)
	records.append(
		"combat_geometry=%s"
		% FileAccess.get_sha256(COMBAT_GEOMETRY_PATH)
	)
	records.append(
		"combat_renderer=%s"
		% FileAccess.get_sha256(COMBAT_RENDERER_PATH)
	)
	records.append(
		"world_geometry=%s"
		% FileAccess.get_sha256(WORLD_GEOMETRY_PATH)
	)
	records.append(
		"minimap_geometry=%s"
		% FileAccess.get_sha256(MINIMAP_GEOMETRY_PATH)
	)
	records.sort()
	return "|".join(records).sha256_text()


static func validate_current_source_coverage() -> PackedStringArray:
	var errors := PackedStringArray()
	var target_counts := {}
	for owner_variant in ownership():
		var owner := StringName(owner_variant)
		for family_variant in Array(ownership()[owner]):
			var family := StringName(family_variant)
			target_counts[family] = int(target_counts.get(family, 0)) + 1
			if int(target_counts[family]) > 1:
				errors.append("source family has multiple target owners: %s" % family)
	if not FileAccess.file_exists(LEGACY_CATALOG_PATH):
		errors.append("current runtime catalog is missing")
	else:
		var parsed: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(LEGACY_CATALOG_PATH)
		)
		if not parsed is Dictionary:
			errors.append("current runtime catalog is invalid")
		else:
			var current := {}
			for asset_variant in Array(Dictionary(parsed).get("assets", [])):
				var family := StringName(Dictionary(asset_variant).get("family", ""))
				current[family] = true
				if int(target_counts.get(family, 0)) != 1:
					errors.append("source family must map to exactly one target: %s" % family)
			for family_variant in target_counts:
				if not current.has(family_variant):
					errors.append("target mapping has no current source family: %s" % family_variant)
	_validate_world_stamp_coverage(errors)
	return errors


static func _validate_world_stamp_coverage(errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(LEGACY_WORLD_RECIPE_PATH):
		errors.append("current world recipe is missing")
		return
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(LEGACY_WORLD_RECIPE_PATH)
	)
	if not parsed is Dictionary:
		errors.append("current world recipe is invalid")
		return
	var recipe := Dictionary(parsed)
	var current := {}
	for value in Array(recipe.get("structure_stamps", [])) + Array(recipe.get("prop_stamps", [])):
		current[StringName(Dictionary(value).get("id", ""))] = true
	var target := {}
	for stamp in WorldCatalog.source_stamp_ids():
		target[stamp] = true
	for stamp_variant in current:
		if not target.has(stamp_variant):
			errors.append("world stamp has no target mapping: %s" % stamp_variant)
	for stamp_variant in target:
		if not current.has(stamp_variant):
			errors.append("target world stamp has no current source: %s" % stamp_variant)


static func _append_descriptor_records(
	records: PackedStringArray,
	path: String,
	value: Variant
) -> void:
	if value is Dictionary:
		var keys := Dictionary(value).keys()
		keys.sort_custom(
			func(a: Variant, b: Variant) -> bool:
				return String(a) < String(b)
		)
		for key_variant in keys:
			_append_descriptor_records(
				records,
				"%s/%s" % [path, String(key_variant)],
				Dictionary(value)[key_variant]
			)
		return
	if value is Array:
		for index in Array(value).size():
			_append_descriptor_records(
				records,
				"%s/%d" % [path, index],
				Array(value)[index]
			)
		return
	records.append("%s=%s" % [path, str(value)])
