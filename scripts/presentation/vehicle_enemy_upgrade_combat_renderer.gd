class_name VehicleEnemyUpgradeCombatRenderer
extends "res://scripts/presentation/vehicle_combat_renderer.gd"

## Reuses the approved weakpoint-facility symbol at 70% of the retired facility size.

const UpgradeDeviceRuntime = preload(
	"res://scripts/vehicle/vehicle_enemy_upgrade_device_runtime.gd"
)
const UpgradeWorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const UpgradeArt = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const UPGRADE_DEVICE_BOB_PERIOD := 2.2
const UPGRADE_DEVICE_BOB_AMPLITUDE := 4.0
const UPGRADE_INTERACTION_CONTOUR := 2.0


func _sync_mystery_devices(state: Dictionary, visible_world: Rect2) -> void:
	var devices_variant: Variant = state.get("mystery_devices")
	if not devices_variant is Array:
		return
	var reduced_motion := bool(state.get("reduced_motion", false))
	var run_time := float(state.get("run_time", 0.0))
	for device_variant in devices_variant:
		var device := Dictionary(device_variant)
		if not bool(device.get("visible", true)):
			continue
		if StringName(device.get("state", &"")) != &"dormant":
			continue
		var outcome_id := StringName(device.get("outcome", &"weakpoint"))
		var symbol_descriptor := &"mystery_device_weakpoint"
		var symbol_asset := StringName(
			UpgradeWorldCatalog.world_object_descriptor(symbol_descriptor).get("asset", &"")
		)
		if symbol_asset == &"":
			continue
		var position := Vector2(device.get("position", Vector2.ZERO))
		var symbol_radius := float(device.get(
			"visual_radius", UpgradeDeviceRuntime.VISUAL_RADIUS
		))
		var phase_offset := _upgrade_interaction_phase(device.get("id", ""))
		if not reduced_motion:
			position.y += sin(
				run_time * TAU / UPGRADE_DEVICE_BOB_PERIOD + phase_offset
			) * UPGRADE_DEVICE_BOB_AMPLITUDE
		if not visible_world.grow(
			symbol_radius + UPGRADE_INTERACTION_CONTOUR
		).has_point(position):
			continue
		var capture_ratio := clampf(
			float(device.get("capture_ratio", 0.0)), 0.0, 1.0
		)
		var capture_count := int(device.get("capture_count", 0))
		var edge_alpha := maxf(
			_upgrade_interaction_edge_alpha(run_time, phase_offset, reduced_motion),
			lerpf(0.36, 0.86, capture_ratio)
		)
		var contour_batch = _mystery_device_contour_batches.get(outcome_id)
		if contour_batch == null:
			continue
		_write_instance(
			contour_batch,
			position,
			0.0,
			Vector2.ONE * (symbol_radius + UPGRADE_INTERACTION_CONTOUR),
			Color.WHITE,
			Color(
				1.0 - capture_ratio,
				1.0 if capture_count >= UpgradeDeviceRuntime.REQUIRED_ENEMY_COUNT else 0.0,
				0.0,
				edge_alpha
			)
		)
		var hit_ratio := clampf(
			float(device.get("hit_flash_remaining", 0.0))
			/ UpgradeDeviceRuntime.UPGRADE_HIT_FLASH_SECONDS,
			0.0,
			1.0
		)
		var danger_mix := clampf(
			0.18 + capture_ratio * 0.52 + hit_ratio * 0.72,
			0.0,
			1.0
		)
		_queue_semantic_texture(
			symbol_asset,
			position,
			0.0,
			symbol_radius,
			Color.WHITE.lerp(UpgradeArt.DANGER, danger_mix)
		)


static func _upgrade_interaction_phase(identity: Variant) -> float:
	return float(posmod(String(identity).hash(), 4096)) / 4096.0 * TAU


static func _upgrade_interaction_edge_alpha(
	run_time: float,
	phase_offset: float,
	reduced_motion: bool
) -> float:
	if reduced_motion:
		return 0.42
	var normalized := (
		sin(run_time * TAU / 2.4 + phase_offset) + 1.0
	) * 0.5
	return lerpf(0.32, 0.52, normalized)
