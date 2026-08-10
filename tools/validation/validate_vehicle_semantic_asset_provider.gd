extends SceneTree

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const REQUIRED_RUNTIME_IDS: Array[StringName] = [
	&"attachment/player_craft_body",
	&"actor/scrap_drone",
	&"actor/mine",
	&"boss/colossus",
	&"boss/crown",
	&"secondary/seeker",
	&"secondary/escort_drone",
	&"secondary/orbit_blade",
	&"secondary/wake_mine",
	&"projectile/energy_teardrop",
	&"projectile/hostile_barbed_bolt",
	&"upgrade/ion_field",
	&"upgrade/element_thermal",
	&"upgrade/element_toxin",
	&"upgrade/element_cryo",
	&"upgrade/dash_wake",
	&"upgrade/defense_matrix",
	&"upgrade/system_relay",
	&"upgrade/mobility_thruster",
	&"upgrade/pickup_magnet",
	&"upgrade/hull_reinforcement",
	&"pickup/experience_master",
	&"pickup/reward_crate",
	&"pickup/repair",
	&"pickup/experience_recall",
	&"world/facility_transit_gate",
	&"world/mystery_device_intact",
	&"world/mystery_device_resolved",
	&"world/surface_detail_crack",
	&"world/surface_detail_stain",
	&"world/surface_detail_embedded_chip",
]

const RETIRED_PRIMITIVE_IDS: Array[StringName] = [
	&"effect/emp_release",
	&"effect/thermal_burst_impact",
	&"effect/drop_mine_detonation",
	&"cue/health_bar_frame_9",
	&"cue/ring",
	&"cue/beam_strip_9",
	&"cue/diamond_marker",
	&"cue/disk_mask",
	&"cue/crosshair",
]

const RETIRED_PRIMITIVE_PATHS := [
	"res://art/visuals/production/gameplay/effects/fx_emp_release.png",
	"res://art/visuals/production/gameplay/effects/thermal_burst_impact.png",
	"res://art/visuals/production/gameplay/effects/drop_mine_detonation.png",
	"res://art/visuals/production/gameplay/effects/cues/cue_health_bar_frame_9.png",
	"res://art/visuals/production/gameplay/effects/cues/cue_ring.png",
	"res://art/visuals/production/gameplay/effects/cues/cue_beam_strip_9.png",
	"res://art/visuals/production/gameplay/effects/cues/cue_diamond_marker.png",
	"res://art/visuals/production/gameplay/effects/cues/cue_disk_mask.png",
	"res://art/visuals/production/gameplay/effects/cues/cue_crosshair.png",
]

const FORBIDDEN_ID_PREFIXES := [
	"boss_module/",
	"state/",
	"hud/",
]

var _failures: Array[String] = []


func _initialize() -> void:
	var ids := AssetProvider.asset_ids()
	_expect(ids.size() == 63, "all 60 semantic PNGs and three approved SurfaceDetail SVGs are indexed")
	for asset_id in REQUIRED_RUNTIME_IDS:
		_expect(AssetProvider.has_asset(asset_id), "%s is indexed" % asset_id)
	for asset_id in RETIRED_PRIMITIVE_IDS:
		_expect(not AssetProvider.has_asset(asset_id), "%s stays retired from the runtime pack" % asset_id)
	for path in RETIRED_PRIMITIVE_PATHS:
		_expect(
			not FileAccess.file_exists(path) and not FileAccess.file_exists("%s.import" % path),
			"shape/color-only production source and import sidecar stay retired: %s" % path
		)
	for asset_id in ids:
		var id_text := String(asset_id)
		_expect(
			not id_text.contains("world_shared_floor")
				and not id_text.contains("world_wall_"),
			"%s is not a deferred map-surface asset" % asset_id
		)
		for forbidden_prefix in FORBIDDEN_ID_PREFIXES:
			_expect(
				not id_text.begins_with(forbidden_prefix),
				"%s is not an authored %s identity" % [asset_id, forbidden_prefix]
			)
	_expect(
		not AssetProvider.has_asset(&"projectile/player_primary")
			and not AssetProvider.has_asset(&"projectile/hostile_kinetic")
			and not AssetProvider.has_asset(&"pickup/experience_small")
			and not AssetProvider.has_asset(&"world/facility_repair_pad_core")
			and not AssetProvider.has_asset(&"world/facility_overdrive_lane"),
		"consolidated raster aliases are absent"
	)
	_expect(
		not AssetProvider.has_asset(&"world/service_rail_tile")
			and not AssetProvider.has_asset(&"cue/support_timer_segment"),
		"decorative rail and support timer rasters stay retired"
	)
	var manifest := AssetProvider.manifest()
	_expect(
		int(manifest.get("final_asset_count", 0)) == 63
			and not manifest.has("animations"),
		"manifest declares 63 static semantic images and no frame animations"
	)
	_validate_surface_details()
	_validate_normalized_content_rects()
	for error in AssetProvider.validate_pack():
		_failures.append(error)
	for upgrade_id in [
		&"upgrade/ion_field",
		&"upgrade/element_thermal",
		&"upgrade/element_toxin",
		&"upgrade/element_cryo",
		&"upgrade/dash_wake",
		&"upgrade/defense_matrix",
		&"upgrade/system_relay",
		&"upgrade/mobility_thruster",
		&"upgrade/pickup_magnet",
		&"upgrade/hull_reinforcement",
	]:
		var texture := AssetProvider.texture(upgrade_id)
		if texture == null:
			continue
		var image := texture.get_image()
		_expect(
			image.get_pixel(0, 0).a < 0.05
				and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a < 0.05,
			"%s keeps a transparent raster exterior" % upgrade_id
		)
	_finish()


func _validate_normalized_content_rects() -> void:
	var expected := {
		&"world/mystery_device_intact":Rect2i(6, 5, 372, 374),
		&"world/mystery_device_resolved":Rect2i(6, 5, 372, 374),
		&"world/facility_reinforcement_fabricator":Rect2i(16, 43, 224, 170),
	}
	for asset_id in expected:
		var descriptor := AssetProvider.descriptor(asset_id)
		var expected_rect: Rect2i = expected[asset_id]
		_expect(
			Rect2i(descriptor.get("content_rect", Rect2i())) == expected_rect,
			"%s preserves its approved alpha-content bounds" % asset_id
		)
		var texture := AssetProvider.texture(asset_id)
		var image := texture.get_image() if texture != null else null
		var expected_canvas := Vector2i(descriptor.get("canvas", Vector2i.ZERO))
		_expect(
			image != null and image.get_size() == expected_canvas,
			"%s actual PNG canvas matches its semantic descriptor" % asset_id
		)
		if image != null:
			_expect(
				image.get_used_rect() == expected_rect,
				"%s actual alpha content matches its approved content rect" % asset_id
			)
			for corner in [
				Vector2i.ZERO,
				Vector2i(image.get_width() - 1, 0),
				Vector2i(0, image.get_height() - 1),
				Vector2i(image.get_width() - 1, image.get_height() - 1),
			]:
				_expect(
					image.get_pixelv(corner).a <= 0.001,
					"%s keeps transparent canvas corners" % asset_id
				)
		var mesh := AssetProvider.normalized_mesh(asset_id)
		var content_size: Vector2 = Vector2(expected_rect.size)
		var canvas_size := Vector2(descriptor.get("canvas", Vector2i.ZERO))
		var unit_radius := maxf(content_size.x, content_size.y) * 0.5
		_expect(
			mesh != null
				and mesh.size.is_equal_approx(canvas_size / unit_radius),
			"%s normalizes from visible content instead of transparent canvas padding"
			% asset_id
		)


func _validate_surface_details() -> void:
	var expected := {
		&"world/surface_detail_crack":Vector2i(96, 96),
		&"world/surface_detail_stain":Vector2i(128, 96),
		&"world/surface_detail_embedded_chip":Vector2i(64, 64),
	}
	for asset_id in expected:
		var descriptor := AssetProvider.descriptor(asset_id)
		var path := String(descriptor.get("path", ""))
		var texture := AssetProvider.texture(asset_id)
		_expect(
			path.ends_with(".svg")
				and Vector2i(descriptor.get("canvas", Vector2i.ZERO)) == expected[asset_id],
			"%s is the approved deterministic SVG canvas" % asset_id
		)
		_expect(
			texture != null and Vector2i(texture.get_size()) == expected[asset_id],
			"%s imports as its exact runtime canvas" % asset_id
		)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_SEMANTIC_ASSET_PROVIDER_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
