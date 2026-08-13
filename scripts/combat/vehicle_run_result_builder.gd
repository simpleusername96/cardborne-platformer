class_name VehicleRunResultBuilder
extends RefCounted

## Reduces immutable completed-stage report records into the final run record.
## It deliberately owns no locale formatting or live gameplay references.

const ATTRIBUTE_ORDER: Array[StringName] = [
	&"kinetic", &"thermal", &"toxin", &"cryo", &"arc",
]
const REQUIRED_STAGE_COUNT := 5


static func build(stage_records: Array, final_state: Dictionary) -> Dictionary:
	if not _is_complete_run(stage_records):
		push_error("VehicleRunResultBuilder requires ordered Stage 1-5 records with a terminal Stage 5.")
		return {}
	var defeats := _merge_defeats(stage_records)
	var outgoing := _merge_damage(stage_records, &"outgoing")
	var attributes := _merge_attributes(stage_records)
	return {
		"stage_count": stage_records.size(),
		"complete_run": true,
		"final_stage_number": REQUIRED_STAGE_COUNT,
		"has_next_stage": false,
		"active_run_elapsed_seconds": maxf(0.0, float(final_state.get("active_run_elapsed_seconds", final_state.get("run_time_seconds", 0.0)))),
		# Kept for the existing report UI contract during the clock migration.
		"run_time_seconds": maxf(0.0, float(final_state.get("active_run_elapsed_seconds", final_state.get("run_time_seconds", 0.0)))),
		"hull": maxf(0.0, float(final_state.get("hull", 0.0))),
		"max_hull": maxf(0.0, float(final_state.get("max_hull", 0.0))),
		"health_ratio": clampf(float(final_state.get("health_ratio", 0.0)), 0.0, 1.0),
		"defeats": defeats,
		"total_defeats": _total_defeats(defeats),
		"outgoing": outgoing,
		"total_outgoing": _total_damage(outgoing),
		"attributes": attributes,
		"total_attributes": _total_damage(attributes),
		"primary_hits": maxi(0, int(final_state.get("primary_hits", 0))),
		"dash_uses": maxi(0, int(final_state.get("dash_uses", 0))),
		"installations": maxi(0, int(final_state.get("installations", 0))),
		"build_snapshot": Dictionary(final_state.get("build_snapshot", {})).duplicate(true),
		"loadout": Dictionary(final_state.get("loadout", {})).duplicate(true),
		"permanent_reward_key": String(final_state.get("permanent_reward_key", "RESULT_RELAY_MODULE")),
		"permanent_reward_detail_key": String(final_state.get("permanent_reward_detail_key", "RESULT_ROUTE_CONTINUES")),
	}


static func _is_complete_run(stage_records: Array) -> bool:
	if stage_records.size() != REQUIRED_STAGE_COUNT:
		return false
	for index in REQUIRED_STAGE_COUNT:
		var record := Dictionary(stage_records[index])
		if int(record.get("stage_number", 0)) != index + 1:
			return false
		if bool(record.get("has_next_stage", false)) != (index < REQUIRED_STAGE_COUNT - 1):
			return false
	return true


static func _merge_defeats(records: Array) -> Array[Dictionary]:
	var merged := {}
	for record_variant in records:
		for row_variant in Dictionary(record_variant).get("defeats", []):
			var row := Dictionary(row_variant)
			var id := StringName(row.get("id", &"other"))
			var current: Dictionary = merged.get(id, {
				"id": id,
				"name_key": String(row.get("name_key", "REPORT_SOURCE_OTHER")),
				"count": 0,
				"elite_count": 0,
			})
			current["count"] = int(current["count"]) + maxi(0, int(row.get("count", 0)))
			current["elite_count"] = int(current["elite_count"]) + maxi(0, int(row.get("elite_count", 0)))
			merged[id] = current
	var rows: Array[Dictionary] = []
	for value in merged.values():
		rows.append(Dictionary(value))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["count"]) > int(b["count"]) if int(a["count"]) != int(b["count"]) else String(a["id"]) < String(b["id"])
	)
	return rows


static func _merge_damage(records: Array, key: StringName) -> Array[Dictionary]:
	var merged := {}
	for record_variant in records:
		for row_variant in Dictionary(record_variant).get(key, []):
			var row := Dictionary(row_variant)
			var id := StringName(row.get("id", &"other"))
			var current: Dictionary = merged.get(id, {
				"id": id,
				"title_key": String(row.get("title_key", "REPORT_SOURCE_OTHER")),
				"damage": 0.0,
			})
			current["damage"] = float(current["damage"]) + maxf(0.0, float(row.get("damage", 0.0)))
			merged[id] = current
	var rows: Array[Dictionary] = []
	for value in merged.values():
		rows.append(Dictionary(value))
	_sort_damage(rows)
	_assign_percentages(rows)
	return rows


static func _merge_attributes(records: Array) -> Array[Dictionary]:
	var merged := {}
	for record_variant in records:
		for row_variant in Dictionary(record_variant).get("attributes", []):
			var row := Dictionary(row_variant)
			var id := StringName(row.get("id", &"kinetic"))
			var current: Dictionary = merged.get(id, {
				"id": id,
				"title_key": String(row.get("title_key", "REPORT_ATTRIBUTE_KINETIC")),
				"damage": 0.0,
				"applications": 0,
			})
			current["damage"] = float(current["damage"]) + maxf(0.0, float(row.get("damage", 0.0)))
			current["applications"] = int(current["applications"]) + maxi(0, int(row.get("applications", 0)))
			merged[id] = current
	var rows: Array[Dictionary] = []
	for id in ATTRIBUTE_ORDER:
		if merged.has(id):
			rows.append(Dictionary(merged[id]))
	_sort_damage(rows)
	_assign_percentages(rows)
	return rows


static func _sort_damage(rows: Array[Dictionary]) -> void:
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["damage"]) > float(b["damage"]) if not is_equal_approx(float(a["damage"]), float(b["damage"])) else String(a["id"]) < String(b["id"])
	)


static func _assign_percentages(rows: Array[Dictionary]) -> void:
	var total := _total_damage(rows)
	if total <= 0.0:
		return
	var assigned := 0
	var remainders: Array[Dictionary] = []
	for index in rows.size():
		var exact := float(rows[index]["damage"]) / total * 1000.0
		var tenths := floori(exact)
		rows[index]["percentage_tenths"] = tenths
		assigned += tenths
		remainders.append({"index":index, "remainder":exact - tenths, "id":String(rows[index]["id"])})
	remainders.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["remainder"]) > float(b["remainder"]) if not is_equal_approx(float(a["remainder"]), float(b["remainder"])) else String(a["id"]) < String(b["id"])
	)
	for cursor in 1000 - assigned:
		var row_index := int(remainders[cursor % remainders.size()]["index"])
		rows[row_index]["percentage_tenths"] = int(rows[row_index]["percentage_tenths"]) + 1


static func _total_damage(rows: Array[Dictionary]) -> float:
	var total := 0.0
	for row in rows:
		total += maxf(0.0, float(row.get("damage", 0.0)))
	return total


static func _total_defeats(rows: Array[Dictionary]) -> int:
	var total := 0
	for row in rows:
		total += maxi(0, int(row.get("count", 0)))
	return total
