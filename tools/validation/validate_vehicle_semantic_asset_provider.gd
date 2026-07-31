extends SceneTree

const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const REQUIRED_RUNTIME_IDS: Array[StringName] = [
	&"attachment/player_hull",
	&"attachment/player_engine",
	&"attachment/player_aim_mount",
	&"actor/scrap_drone",
	&"actor/mine",
	&"actor/boss_pylon",
	&"boss/colossus",
	&"boss/crown",
	&"boss_module/route_switch",
	&"secondary/seeker",
	&"secondary/escort_drone",
	&"secondary/orbit_blade",
	&"secondary/wake_mine",
	&"projectile/player_primary",
	&"projectile/player_opening_breach",
	&"projectile/player_seeker",
	&"state/player_barrier_plate",
	&"state/player_ion_emitter",
	&"pickup/experience_small",
	&"pickup/reward_crate",
	&"world/facility_repair_pad",
	&"hud/action_primary",
	&"hud/minimap_marker_objective_active",
	&"effect/dash_start/00",
	&"effect/barrier_contact/00",
	&"effect/boss_reduced_hit/00",
	&"cue/priority_target",
	&"cue/boss_core_open",
	&"cue/guide_objects",
]

var _failures: Array[String] = []


func _initialize() -> void:
	var ids := AssetProvider.asset_ids()
	_expect(ids.size() == 239, "all 239 non-map runtime PNGs are indexed")
	for asset_id in REQUIRED_RUNTIME_IDS:
		_expect(AssetProvider.has_asset(asset_id), "%s is indexed" % asset_id)
	for asset_id in ids:
		_expect(
			not String(asset_id).contains("world_shared_floor")
				and not String(asset_id).contains("world_wall_"),
			"%s is not a deferred map-surface asset" % asset_id
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
