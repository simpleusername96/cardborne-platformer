extends SceneTree

const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const SecondaryCatalog = preload(
	"res://scripts/presentation/components/vehicle_secondary_visual_catalog.gd"
)

const ORDINARY_ARCHETYPES: Array[StringName] = [
	&"scrap_drone", &"needle_drone", &"spark_minelet", &"chaser",
	&"shooter", &"controller", &"turret", &"mine", &"generator",
	&"shield_escort", &"artillery_spotter", &"interceptor_tower",
	&"rammer", &"bulkhead_guard", &"splitter_barge", &"repair_tender",
	&"drone_carrier", &"beam_sentinel",
]
const BOSS_VARIANTS: Array[StringName] = [
	&"colossus", &"leviathan", &"titan", &"behemoth", &"crown",
]
var _failures: Array[String] = []


func _initialize() -> void:
	_validate_player_attachments()
	_validate_actor_images()
	_validate_secondary_ownership()
	_finish()


func _validate_player_attachments() -> void:
	var player := ActorCatalog.descriptor(&"player")
	_expect(
		Array(player.get("rear_anchors", [])).size() == 1
			and Vector2(Array(player["rear_anchors"])[0])
				.is_equal_approx(Vector2(-0.84, 0.0)),
		"player owns one centered rear anchor for transient dash feedback"
	)
	var manifest := AssetProvider.manifest()
	var attachments := Dictionary(manifest.get("attachments", {}))
	_expect(
		attachments.size() == 1
			and String(Dictionary(attachments.get("player_craft_body", {})).get(
			"rotation_driver",
			""
		)) == "hull",
		"one integrated player craft attachment is driven by the hull"
	)
	_expect(
		not attachments.has("player_hull")
			and not attachments.has("player_engine")
			and not attachments.has("player_aim_mount"),
		"legacy player part attachments are absent"
	)
	var asset_id := &"attachment/player_craft_body"
	_expect(
		AssetProvider.texture(asset_id) != null
			and AssetProvider.normalized_mesh(asset_id) != null,
		"integrated player craft resolves to a texture-capable runtime quad"
	)


func _validate_actor_images() -> void:
	var signatures := {}
	for archetype in ORDINARY_ARCHETYPES:
		var asset_id := StringName("actor/%s" % archetype)
		_validate_unique_alpha_signature(asset_id, signatures)
	_expect(
		signatures.size() == ORDINARY_ARCHETYPES.size(),
		"all 18 ordinary actor silhouettes remain distinct"
	)
	signatures.clear()
	for boss in BOSS_VARIANTS:
		_validate_unique_alpha_signature(
			StringName("boss/%s" % boss),
			signatures
		)
	_expect(signatures.size() == 5, "all five boss body silhouettes remain distinct")


func _validate_secondary_ownership() -> void:
	var seen_assets := {}
	for secondary_id in SecondaryCatalog.descriptor_ids():
		var asset_id := StringName(
			SecondaryCatalog.descriptor(secondary_id).get("asset", &"")
		)
		_expect(
			asset_id != &"" and AssetProvider.has_asset(asset_id),
			"%s owns a semantic-v2 asset" % secondary_id
		)
		_expect(
			not seen_assets.has(asset_id),
			"%s does not alias another secondary image" % secondary_id
		)
		seen_assets[asset_id] = secondary_id
	_expect(
		ActorCatalog.descriptor(&"escort_drone").is_empty(),
		"escort drone no longer borrows an ordinary enemy recipe"
	)


func _validate_unique_alpha_signature(
	asset_id: StringName,
	signatures: Dictionary
) -> void:
	var descriptor := AssetProvider.descriptor(asset_id)
	var path := String(descriptor.get("path", ""))
	_expect(not path.is_empty(), "%s has a runtime path" % asset_id)
	if path.is_empty():
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	_expect(image != null and not image.is_empty(), "%s loads as an image" % asset_id)
	if image == null or image.is_empty():
		return
	image.resize(24, 24, Image.INTERPOLATE_LANCZOS)
	var bits := PackedStringArray()
	for y in 24:
		var row := ""
		for x in 24:
			row += "1" if image.get_pixel(x, y).a >= 0.12 else "0"
		bits.append(row)
	var signature := "|".join(bits)
	_expect(
		not signatures.has(signature),
		"%s keeps a unique alpha silhouette from %s"
		% [asset_id, signatures.get(signature, &"")]
	)
	signatures[signature] = asset_id


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_ACTOR_VISUALS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
