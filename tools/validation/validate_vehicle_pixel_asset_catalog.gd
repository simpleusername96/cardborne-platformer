extends SceneTree

const PixelCatalog = preload("res://scripts/presentation/vehicle_pixel_asset_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := PixelCatalog.new()
	_expect(catalog.is_ready(), "published pixel catalog loads")
	var expected_families: Array[StringName] = [
		&"player_chassis",
		&"player_primary_weapon",
		&"player_engine_modules",
		&"player_engine_flame",
		&"player_dash_effect",
		&"player_primary_projectiles",
	]
	expected_families.sort()
	_expect(
		catalog.published_families() == expected_families,
		"phase-two pixel families are published exactly once"
	)
	var chassis := catalog.frame(&"player_chassis", &"base", 15, &"normal")
	var recoil := catalog.frame(&"player_primary_weapon", &"pulse_cannon", 7, &"recoil")
	var engines := catalog.frame(&"player_engine_modules", &"module_count_3", 12, &"installed")
	var dash := catalog.frame(&"player_dash_effect", &"travel", 4, &"frame_0")
	var breach := catalog.frame(
		&"player_primary_projectiles", &"opening_breach", 14, &"flight_1", 1
	)
	for pair in [
		["chassis", chassis],
		["weapon recoil", recoil],
		["engine count", engines],
		["dash", dash],
		["breach projectile", breach],
	]:
		var frame: Dictionary = pair[1]
		_expect(not frame.is_empty(), "%s tuple resolves" % pair[0])
		if frame.is_empty():
			continue
		var uv := catalog.frame_uv(frame)
		_expect(
			uv.r >= 0.0 and uv.g >= 0.0
				and uv.b > 0.0 and uv.a > 0.0
				and uv.r + uv.b <= 1.0
				and uv.g + uv.a <= 1.0,
			"%s atlas region is normalized and bounded" % pair[0]
		)
	for family in expected_families:
		var texture := catalog.texture(family)
		_expect(texture != null, "%s texture loads" % String(family))
		if texture != null:
			_expect(
				texture.get_width() == 542 and texture.get_height() == 1492,
				"%s points at the shared runtime atlas" % String(family)
			)
	if failures.is_empty():
		print("VEHICLE_PIXEL_ASSET_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
