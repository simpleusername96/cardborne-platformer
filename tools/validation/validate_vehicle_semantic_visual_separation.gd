extends SceneTree

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)

const DISTINCT_GROUPS := {
	"secondaries":[
		&"secondary/seeker",
		&"secondary/escort_drone",
		&"secondary/orbit_blade",
		&"secondary/wake_mine",
	],
	"active_pickups":[
		&"pickup/experience_master",
		&"pickup/repair",
		&"pickup/experience_recall",
	],
	"neutral_facility_roles":[
		&"world/facility_repair_beacon",
		&"world/mystery_device_cryo",
		&"world/mystery_device_weakpoint",
		&"world/mystery_device_lava",
	],
	"hostile_device_role":[
		&"world/enemy_upgrade_device",
	],
}

var _failures: Array[String] = []


func _initialize() -> void:
	for group_name in DISTINCT_GROUPS:
		_validate_distinct_group(
			String(group_name),
			Array(DISTINCT_GROUPS[group_name])
		)
	_validate_actor_perimeters()
	_validate_active_world_roles()
	_finish()


func _validate_active_world_roles() -> void:
	var expected := [
		&"repair_beacon",
		&"mystery_device_cryo",
		&"mystery_device_weakpoint",
		&"mystery_device_lava",
		&"enemy_upgrade_device",
		&"transit_gate",
	]
	var active_ids := WorldCatalog.WORLD_OBJECT_DESCRIPTORS.keys()
	var matches := active_ids.size() == expected.size()
	for expected_id in expected:
		matches = matches and active_ids.has(expected_id)
	_expect(
		matches,
		"world visual roles include the hostile device and preserved facility identities"
	)


func _validate_distinct_group(group_name: String, asset_ids: Array) -> void:
	var alpha_signatures := {}
	var grayscale_signatures := {}
	for asset_id_variant in asset_ids:
		var asset_id := StringName(asset_id_variant)
		var image := _normalized_image(asset_id)
		_expect(image != null, "%s loads for %s" % [asset_id, group_name])
		if image == null:
			continue
		var alpha_signature := _alpha_signature(image)
		var grayscale_signature := _grayscale_signature(image)
		_expect(
			not alpha_signatures.has(alpha_signature)
				or grayscale_signatures.get(alpha_signature, "") != grayscale_signature,
			"%s remains shape/pattern-distinct after color removal: %s"
			% [group_name, asset_id]
		)
		alpha_signatures[alpha_signature] = asset_id
		grayscale_signatures[alpha_signature] = grayscale_signature


func _validate_actor_perimeters() -> void:
	for asset_id in AssetProvider.asset_ids():
		if (
			not String(asset_id).begins_with("actor/")
			and not String(asset_id).begins_with("boss/")
		):
			continue
		var texture := AssetProvider.texture(asset_id)
		if texture == null:
			continue
		var image := texture.get_image()
		var boundary_pixels := 0
		var dark_boundary_pixels := 0
		for y in image.get_height():
			for x in image.get_width():
				var pixel := image.get_pixel(x, y)
				if pixel.a < 0.35 or not _touches_transparency(image, x, y):
					continue
				boundary_pixels += 1
				var luminance := (
					pixel.r * 0.2126
					+ pixel.g * 0.7152
					+ pixel.b * 0.0722
				)
				if luminance <= 0.28:
					dark_boundary_pixels += 1
		var dark_ratio := (
			float(dark_boundary_pixels)
			/ float(maxi(1, boundary_pixels))
		)
		_expect(
			boundary_pixels >= 12 and dark_ratio >= 0.15,
			"%s keeps authored dark separation in its antialiased boundary band (dark boundary %.3f)"
			% [asset_id, dark_ratio]
		)


func _normalized_image(asset_id: StringName) -> Image:
	var texture := AssetProvider.texture(asset_id)
	if texture == null:
		return null
	var image := texture.get_image()
	image.resize(32, 32, Image.INTERPOLATE_LANCZOS)
	return image


func _alpha_signature(image: Image) -> String:
	var bytes := PackedByteArray()
	for y in image.get_height():
		for x in image.get_width():
			bytes.append(1 if image.get_pixel(x, y).a >= 0.28 else 0)
	return Marshalls.raw_to_base64(bytes).sha256_text()


func _grayscale_signature(image: Image) -> String:
	var bytes := PackedByteArray()
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var luminance := (
				pixel.r * 0.2126
				+ pixel.g * 0.7152
				+ pixel.b * 0.0722
			)
			bytes.append(clampi(roundi(luminance * pixel.a * 15.0), 0, 15))
	return Marshalls.raw_to_base64(bytes).sha256_text()


func _touches_transparency(image: Image, x: int, y: int) -> bool:
	# Authored antialiasing may place one or two bright transition pixels outside
	# the actual dark separator. Inspect a shallow contour band instead of
	# treating only the outermost alpha edge as the whole perimeter.
	for offset_y in range(-3, 4):
		for offset_x in range(-3, 4):
			if absi(offset_x) + absi(offset_y) > 3:
				continue
			var point := Vector2i(x + offset_x, y + offset_y)
			if (
				point.x < 0
				or point.y < 0
				or point.x >= image.get_width()
				or point.y >= image.get_height()
				or image.get_pixelv(point).a < 0.20
			):
				return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_SEMANTIC_VISUAL_SEPARATION_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
