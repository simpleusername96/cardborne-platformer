extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const Rail = preload("res://scripts/ui/vehicle_acquired_upgrade_rail.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := Catalog.new()
	var rail := Rail.new()
	root.add_child(rail)
	await process_frame
	for count in [0, 6, 12, 18]:
		var upgrades := _fixture_upgrades(catalog, count)
		rail.set_build_snapshot({"upgrades":upgrades})
		await process_frame
		var contract := rail.debug_contract()
		_expect(
			int(contract["acquired_count"]) == count
				and int(contract["row_count"]) == (0 if count == 0 else (1 if count <= 12 else 2))
				and int(contract["texture_count"]) == count
				and int(contract["empty_slot_count"]) == 0,
			"%d acquired upgrades render as dense texture-only rows" % count
		)
		_expect(
			bool(contract["panel_free"])
				and bool(contract["level_numerals"])
				and int(contract["maximum_per_row"]) == 12
				and int(contract["maximum_visible"]) == 18,
			"%d-upgrade fixture preserves the selected linear-rail grammar" % count
		)
		var rebuilds_before := int(contract["rebuild_count"])
		rail.set_build_snapshot({"upgrades":upgrades})
		_expect(
			int(rail.debug_contract()["rebuild_count"]) == rebuilds_before,
			"unchanged %d-upgrade receipts do not rebuild the live rail" % count
		)
	rail.set_layout_profile(false, true)
	rail.set_build_snapshot({"upgrades":_fixture_upgrades(catalog, 12)})
	await process_frame
	var accessibility_contract := rail.debug_contract()
	_expect(
		int(accessibility_contract["maximum_per_row"]) == 10
			and int(accessibility_contract["row_count"]) == 2
			and is_equal_approx(float(accessibility_contract["icon_size"]), 34.0),
		"200% text wraps twelve upgrades without crossing the center zone"
	)
	rail.set_layout_profile(false, false, true)
	rail.set_build_snapshot({"upgrades":_fixture_upgrades(catalog, 12)})
	await process_frame
	var large_contract := rail.debug_contract()
	_expect(
		int(large_contract["maximum_per_row"]) == 12
			and int(large_contract["row_count"]) == 1
			and is_equal_approx(float(large_contract["icon_size"]), 40.0),
		"large viewports enlarge the selected linear rail without adding a panel"
	)
	rail.queue_free()
	await process_frame
	_finish()


func _fixture_upgrades(catalog: VehicleUpgradeCatalog, count: int) -> Array[Dictionary]:
	var definitions := catalog.all_definitions()
	var result: Array[Dictionary] = []
	for index in count:
		var definition := definitions[index % definitions.size()]
		result.append({
			"id":StringName("fixture_%02d" % index),
			"title_key":definition.title_key,
			"artwork_asset_id":definition.artwork_asset_id,
			"level":1 + index % 3,
		})
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ACQUIRED_UPGRADE_RAIL_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
