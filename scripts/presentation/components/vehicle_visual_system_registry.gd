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
const SecondaryCatalog = preload(
	"res://scripts/presentation/components/vehicle_secondary_visual_catalog.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const ACTION_GLYPH_RECIPE_PATH := (
	"res://scripts/presentation/components/vehicle_ui_action_glyph_renderer.gd"
)
const COMBAT_RENDERER_PATH := (
	"res://scripts/presentation/vehicle_combat_renderer.gd"
)
const WORLD_GEOMETRY_PATH := (
	"res://scripts/presentation/vehicle_world_mesh_builder.gd"
)
const SURFACE_DETAIL_PATH := (
	"res://scripts/presentation/vehicle_surface_detail_compiler.gd"
)
const MINIMAP_GEOMETRY_PATH := (
	"res://scripts/ui/vehicle_minimap_mesh_builder.gd"
)
const RETAINED_MINIMAP_GEOMETRY_PATH := (
	"res://scripts/ui/vehicle_retained_minimap_mesh.gd"
)
const VEHICLE_THEME_PATH := (
	"res://art/visuals/production/ui/vehicle_stage_theme.tres"
)
const VEHICLE_FONT_PATH := (
	"res://art/visuals/production/ui/fonts/NotoSansKR-Variable.ttf"
)


static func catalog_ids() -> Dictionary:
	return {
		&"actor": ActorCatalog.descriptor_ids(),
		&"projectile": ProjectileCatalog.descriptor_ids(),
		&"reward": RewardCatalog.descriptor_ids(),
		&"effect": EffectCatalog.descriptor_ids(),
		&"world": WorldCatalog.descriptor_ids(),
		&"secondary": SecondaryCatalog.descriptor_ids(),
		&"semantic_asset": AssetProvider.asset_ids(),
		&"glyph_core": GlyphCatalog.descriptor_ids(),
	}


static func provider_fingerprint() -> String:
	var records := PackedStringArray()
	for owner_variant in catalog_ids():
		var owner := StringName(owner_variant)
		var families := PackedStringArray()
		for family in Array(catalog_ids()[owner]):
			families.append(String(family))
		families.sort()
		records.append("%s=%s" % [String(owner), ",".join(families)])
	_append_descriptor_records(records, "actor", ActorCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "projectile", ProjectileCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "reward", RewardCatalog.DESCRIPTORS)
	_append_descriptor_records(records, "effect", EffectCatalog.DESCRIPTORS)
	_append_descriptor_records(
		records,
		"secondary",
		SecondaryCatalog.DESCRIPTORS
	)
	_append_descriptor_records(records, "world_field", WorldCatalog.FIELD_DESCRIPTORS)
	_append_descriptor_records(records, "world_object", WorldCatalog.WORLD_OBJECT_DESCRIPTORS)
	_append_descriptor_records(records, "surface_detail", WorldCatalog.SURFACE_DETAIL_DESCRIPTORS)
	records.append(
		"action_glyph_recipes=%s"
		% FileAccess.get_sha256(ACTION_GLYPH_RECIPE_PATH)
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
		"surface_detail=%s"
		% FileAccess.get_sha256(SURFACE_DETAIL_PATH)
	)
	records.append(
		"minimap_geometry=%s"
		% FileAccess.get_sha256(MINIMAP_GEOMETRY_PATH)
	)
	records.append(
		"retained_minimap_geometry=%s"
		% FileAccess.get_sha256(RETAINED_MINIMAP_GEOMETRY_PATH)
	)
	records.append(
		"vehicle_theme=%s"
		% FileAccess.get_sha256(VEHICLE_THEME_PATH)
	)
	records.append(
		"vehicle_font=%s"
		% FileAccess.get_sha256(VEHICLE_FONT_PATH)
	)
	records.sort()
	return "|".join(records).sha256_text()


static func validate_catalog_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	errors.append_array(AssetProvider.validate_pack())
	for group_variant in catalog_ids():
		var catalog_group := StringName(group_variant)
		var ids := Array(catalog_ids()[catalog_group])
		if ids.is_empty():
			errors.append("visual catalog is empty: %s" % catalog_group)
			continue
		var seen := {}
		for id_variant in ids:
			var visual_id := StringName(id_variant)
			if visual_id == &"":
				errors.append(
					"visual catalog has an empty id: %s" % catalog_group
				)
			elif seen.has(visual_id):
				errors.append(
					"visual catalog has a duplicate id: %s/%s"
					% [catalog_group, visual_id]
				)
			seen[visual_id] = true
	return errors


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
