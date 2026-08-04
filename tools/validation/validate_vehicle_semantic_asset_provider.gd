extends SceneTree

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const REQUIRED_RUNTIME_IDS: Array[StringName] = [
	&"attachment/player_craft_body",
	&"actor/scrap_drone",
	&"actor/mine",
	&"actor/boss_pylon",
	&"boss/colossus",
	&"boss/crown",
	&"boss/node_active",
	&"boss/node_damaged",
	&"boss/node_resolved",
	&"secondary/seeker",
	&"secondary/escort_drone",
	&"secondary/orbit_blade",
	&"secondary/wake_mine",
	&"projectile/energy_teardrop",
	&"pickup/experience_master",
	&"pickup/reward_crate",
	&"world/facility_repair_pad",
	&"world/facility_overdrive_pad",
	&"world/wear_tile_collapsed",
	&"effect/emp_release",
	&"cue/health_bar_frame_9",
	&"cue/ring",
	&"cue/beam_strip_9",
	&"cue/diamond_marker",
	&"cue/disk_mask",
	&"cue/crosshair",
]

const FORBIDDEN_ID_PREFIXES := [
	"boss_module/",
	"state/",
	"hud/",
]

var _failures: Array[String] = []


func _initialize() -> void:
	var ids := AssetProvider.asset_ids()
	_expect(ids.size() == 57, "all 57 final gameplay PNGs are indexed")
	for asset_id in REQUIRED_RUNTIME_IDS:
		_expect(AssetProvider.has_asset(asset_id), "%s is indexed" % asset_id)
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
		int(manifest.get("final_asset_count", 0)) == 57
			and not manifest.has("animations"),
		"manifest declares 57 static authored rasters and no frame animations"
	)
	for error in AssetProvider.validate_pack():
		_failures.append(error)
	_finish()


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
