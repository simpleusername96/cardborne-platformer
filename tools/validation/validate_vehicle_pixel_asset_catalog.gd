extends SceneTree

const PixelCatalog = preload("res://scripts/presentation/vehicle_pixel_asset_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var catalog := PixelCatalog.new()
	_expect(catalog.is_ready(), "published pixel catalog loads")
	var expected_families: Array[StringName] = [
		&"player_chassis",
		&"player_engine_modules",
		&"player_engine_flame",
		&"player_dash_effect",
		&"player_primary_projectiles",
	]
	_expect(
		catalog.published_families().size() == 39,
		"all thirty-nine inventory families are published exactly once"
	)
	for family in expected_families:
		_expect(catalog.has_family(family), "%s remains published" % String(family))
	var chassis := catalog.frame(&"player_chassis", &"base", 15, &"normal")
	var engines := catalog.frame(&"player_engine_modules", &"module_count_3", 12, &"installed")
	var dash := catalog.frame(&"player_dash_effect", &"travel", 4, &"frame_0")
	var breach := catalog.frame(
		&"player_primary_projectiles", &"opening_breach", 14, &"flight_1", 1
	)
	var chaser := catalog.frame(&"mobile_enemy_set", &"chaser", 6, &"move")
	var boss := catalog.frame(&"boss_set", &"crown", 12, &"read")
	var card := catalog.frame(&"upgrade_card_icons", &"toxin_core", 0, &"normal")
	var preview := catalog.first_frame(&"boss_set", &"leviathan", &"read")
	for pair in [
		["chassis", chassis],
		["engine count", engines],
		["dash", dash],
		["breach projectile", breach],
		["mobile enemy", chaser],
		["boss", boss],
		["upgrade card", card],
		["derived preview", preview],
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
				texture.get_width() > 1024 and texture.get_height() > 1024,
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
