extends SceneTree

## Mechanical readability gate for the shared non-beam projectile master.
## The image may be larger than collision truth, but its bright pivot core and
## visual multipliers must remain deterministic and renderer-owned.

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const ProjectileCatalog = preload(
	"res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

const PROJECTILE_ID := &"projectile/energy_teardrop"
const CANVAS := Vector2i(64, 64)
const PIVOT := Vector2i(32, 32)

var failures: Array[String] = []


func _initialize() -> void:
	var texture := AssetProvider.texture(PROJECTILE_ID)
	_expect(texture != null, "shared projectile texture resolves")
	if texture == null:
		_finish()
		return
	var image := texture.get_image()
	_expect(Vector2i(image.get_size()) == CANVAS, "projectile canvas is 64x64")
	var bounds := _alpha_bounds(image)
	_expect(bounds.size.x >= 46 and bounds.size.x <= 52, "projectile opaque width stays within 46-52px")
	_expect(bounds.size.y >= 24 and bounds.size.y <= 30, "projectile opaque height stays within 24-30px")
	_expect(bounds.position.x <= PIVOT.x and PIVOT.x < bounds.end.x, "projectile alpha surrounds the pivot horizontally")
	_expect(bounds.position.y <= PIVOT.y and PIVOT.y < bounds.end.y, "projectile alpha surrounds the pivot vertically")
	var pivot := image.get_pixelv(PIVOT)
	_expect(pivot.a >= 0.95 and _luminance(pivot) >= 0.72, "projectile pivot is an opaque bright core")
	for y in range(PIVOT.y - 1, PIVOT.y + 2):
		for x in range(PIVOT.x - 1, PIVOT.x + 2):
			var pixel := image.get_pixel(x, y)
			_expect(pixel.a >= 0.90, "projectile 3x3 pivot neighborhood remains opaque")
	_expect(
		ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_PRIMARY) == PROJECTILE_ID,
		"primary projectile keeps its dedicated semantic identity"
	)
	_expect(
		ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_SEEKER)
			!= ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_PRIMARY)
			and ProjectileCatalog.asset_id(ProjectileCatalog.HOSTILE)
			!= ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_PRIMARY)
			and ProjectileCatalog.asset_id(ProjectileCatalog.HOSTILE)
			!= ProjectileCatalog.asset_id(ProjectileCatalog.PLAYER_SEEKER),
		"primary, seeker, and hostile projectiles keep distinct assets"
	)
	_expect(AssetProvider.descriptor(PROJECTILE_ID).get("pivot") == Vector2(32, 32), "projectile pivot is semantic center")
	_validate_scale_contract()
	_validate_renderer_ownership()
	_finish()


func _validate_scale_contract() -> void:
	var collision_radius := AttackContract.hostile_projectile_radius(12.0)
	_expect(
		is_equal_approx(collision_radius * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE, 23.1),
		"hostile visual envelope uses the profile multiplier"
	)
	_expect(
		is_equal_approx(collision_radius * Art.PLAYER_PRIMARY_PROJECTILE_SCALE, 26.25),
		"primary visual envelope uses the profile multiplier"
	)
	_expect(
		is_equal_approx(collision_radius * Art.PLAYER_SEEKER_PROJECTILE_SCALE, 30.0),
		"seeker visual envelope uses the profile multiplier"
	)
	_expect(
		is_equal_approx(collision_radius * Art.PLAYER_OPENING_BREACH_PROJECTILE_SCALE, 27.3),
		"opening-breach visual envelope uses the profile multiplier"
	)
	_expect(Art.attack_color(&"kinetic").a >= 1.0 and Art.attack_color(&"thermal").a >= 1.0, "friendly and hostile role colors remain opaque")


func _validate_renderer_ownership() -> void:
	var source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_combat_renderer.gd"
	)
	for obsolete_literal in [
		"radius * 5.0",
		"radius * 5.6",
		"radius * 5.8",
		"radius * 4.5",
	]:
		_expect(not source.contains(obsolete_literal), "combat renderer has no legacy projectile scale literal: %s" % obsolete_literal)


func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 0.08:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < 0:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PROJECTILE_READABILITY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
