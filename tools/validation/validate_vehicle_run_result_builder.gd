extends SceneTree

const Builder = preload("res://scripts/combat/vehicle_run_result_builder.gd")

var _failures: Array[String] = []


func _init() -> void:
	var records: Array = [
		{
			"stage_number":1, "has_boss":true, "has_next_stage":true,
			"defeats":[{"id":&"scrap_drone", "name_key":"ENEMY_SCRAP_DRONE", "count":3, "elite_count":1}],
			"outgoing":[{"id":&"primary", "title_key":"REPORT_SOURCE_PRIMARY", "damage":30.0}],
			"attributes":[{"id":&"kinetic", "title_key":"REPORT_ATTRIBUTE_KINETIC", "damage":30.0, "applications":0}],
		},
		{
			"stage_number":2, "has_boss":true, "has_next_stage":true,
			"defeats":[{"id":&"scrap_drone", "name_key":"ENEMY_SCRAP_DRONE", "count":2, "elite_count":0}],
			"outgoing":[{"id":&"seeker", "title_key":"REPORT_SOURCE_SEEKER", "damage":10.0}],
			"attributes":[{"id":&"cryo", "title_key":"REPORT_ATTRIBUTE_CRYO", "damage":10.0, "applications":2}],
		},
	]
	for stage_number in range(3, 9):
		records.append({
			"stage_number":stage_number,
			"has_boss":true,
			"has_next_stage":stage_number < 8,
			"defeats":[], "outgoing":[], "attributes":[],
		})
	var result := Builder.build(records, {
		"active_run_elapsed_seconds":91.5,
		"hull":84.0,
		"max_hull":120.0,
		"build_snapshot":{"upgrades":[]},
	})
	_expect(bool(result.get("complete_run", false)) and int(result.get("final_stage_number", 0)) == 8, "final result requires an ordered terminal eight-cycle record")
	_expect(int(result.get("boss_stage_count", 0)) == 8, "final result records all eight bosses")
	_expect(int(result["total_defeats"]) == 5, "final result sums defeats")
	_expect(int(result["defeats"][0]["elite_count"]) == 1, "final result sums elite defeats")
	_expect(is_equal_approx(float(result["total_outgoing"]), 40.0), "final result preserves outgoing total")
	_expect(is_equal_approx(float(result["total_attributes"]), 40.0), "final result preserves attribute total")
	_expect(int(result["outgoing"][0]["percentage_tenths"]) + int(result["outgoing"][1]["percentage_tenths"]) == 1000, "final result percentages are deterministic")
	_expect(is_equal_approx(float(result["active_run_elapsed_seconds"]), 91.5), "final result preserves active run time")
	_expect(is_equal_approx(float(result["hull"]), 84.0) and is_equal_approx(float(result["max_hull"]), 120.0), "final result preserves exact current and maximum Hull")
	_expect(records[0]["defeats"][0]["count"] == 3, "builder does not mutate stage records")
	if _failures.is_empty():
		print("VEHICLE_RUN_RESULT_BUILDER_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
