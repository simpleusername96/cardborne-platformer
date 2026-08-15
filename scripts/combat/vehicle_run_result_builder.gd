class_name VehicleRunResultBuilder
extends RefCounted

## Reduces immutable completed-stage report records into the final run record.
## It deliberately owns no locale formatting or live gameplay references.

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const StageReportBuilder = preload("res://scripts/combat/vehicle_stage_report_builder.gd")
const ATTRIBUTE_ORDER: Array[StringName] = [
	&"kinetic", &"thermal", &"toxin", &"cryo", &"arc",
]


static func build(stage_records: Array, final_state: Dictionary) -> Dictionary:
	if not _is_complete_run(stage_records):
		push_error("VehicleRunResultBuilder requires one ordered record for every configured boss cycle.")
		return {}
	var required_stage_count := CombatStages.STAGE_IDS.size()
	var defeats := _merge_defeats(stage_records)
	var outgoing := _merge_damage(stage_records, &"outgoing")
	var attributes := _merge_attributes(stage_records)
	var incoming := _merge_damage(stage_records, &"incoming")
	var damage_rows: Array[Dictionary] = outgoing.duplicate(true)
	damage_rows.append_array(attributes)
	var active_seconds := maxf(0.0, float(final_state.get("active_run_elapsed_seconds", final_state.get("run_time_seconds", 0.0))))
	var hull := maxf(0.0, float(final_state.get("hull", 0.0)))
	var max_hull := maxf(0.0, float(final_state.get("max_hull", 0.0)))
	var build_snapshot := Dictionary(final_state.get("build_snapshot", {})).duplicate(true)
	var build_rows := Array(final_state.get("build_rows", []))
	if build_rows.is_empty():
		build_rows = StageReportBuilder.build_rows(build_snapshot)
	return {
		"stage_count": stage_records.size(),
		"complete_run": true,
		"final_stage_number": required_stage_count,
		"boss_stage_count": _boss_stage_count(),
		"has_next_stage": false,
		"active_run_elapsed_seconds": active_seconds,
		# Kept for the existing report UI contract during the clock migration.
		"run_time_seconds": active_seconds,
		"hull": hull,
		"max_hull": max_hull,
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
		"build_snapshot": build_snapshot,
		"loadout": Dictionary(final_state.get("loadout", {})).duplicate(true),
		"permanent_reward_key": String(final_state.get("permanent_reward_key", "RESULT_RELAY_MODULE")),
		"permanent_reward_detail_key": String(final_state.get("permanent_reward_detail_key", "RESULT_ROUTE_CONTINUES")),
		"outcome_rows":[
			{"title_key":"REPORT_ROW_STATUS", "value_key":"REPORT_VALUE_RUN_CLEARED"},
			{"title_key":"REPORT_ROW_HULL", "value":"%.0f / %.0f" % [hull, max_hull]},
		],
		"cycle_progress_rows":[
			{"title_key":"REPORT_ROW_CYCLES_CLEARED", "count":stage_records.size()},
			{"title_key":"REPORT_ROW_ACTIVE_TIME", "value":_format_duration(active_seconds)},
		],
		"build_rows":build_rows.duplicate(true),
		"damage_rows":damage_rows,
		"defense_rows":incoming,
		"enemy_rows":defeats.duplicate(true),
		"boss_rows":_boss_rows(stage_records),
		"pacing_rows":_pacing_rows(stage_records, defeats),
		"diagnostic_limitations":_diagnostic_rows(stage_records),
	}


static func _format_duration(seconds: float) -> String:
	var total := maxi(0, floori(seconds))
	return "%d:%02d" % [total / 60, total % 60]


static func _is_complete_run(stage_records: Array) -> bool:
	var required_stage_count := CombatStages.STAGE_IDS.size()
	if stage_records.size() != required_stage_count:
		return false
	for index in required_stage_count:
		var record := Dictionary(stage_records[index])
		if int(record.get("stage_number", 0)) != index + 1:
			return false
		if bool(record.get("has_next_stage", false)) != (index < required_stage_count - 1):
			return false
		if bool(record.get("has_boss", false)) != CombatStages.has_boss(CombatStages.STAGE_IDS[index]):
			return false
	return true


static func _boss_stage_count() -> int:
	var total := 0
	for stage_id in CombatStages.STAGE_IDS:
		if CombatStages.has_boss(stage_id):
			total += 1
	return total


static func _boss_rows(records: Array) -> Array[Dictionary]:
	var completed_bosses := 0
	for record_variant in records:
		var boss := Dictionary(Dictionary(record_variant).get("boss_report", {}))
		if bool(boss.get("cleanup_completed", false)):
			completed_bosses += 1
	var rows: Array[Dictionary] = [{"title_key":"REPORT_ROW_BOSSES_DEFEATED", "count":completed_bosses}]
	for record_variant in records:
		var boss := Dictionary(Dictionary(record_variant).get("boss_report", {}))
		var boss_id := StringName(boss.get("id", &""))
		if boss_id.is_empty():
			continue
		rows.append({
			"name_key":String(boss_id),
			"value_key":"REPORT_VALUE_CLEARED" if bool(boss.get("cleanup_completed", false)) else "REPORT_VALUE_CLEANUP_IN_PROGRESS",
		})
		rows.append({
			"title_key":"REPORT_ROW_BOSS_CLEANUP",
			"value_key":"REPORT_VALUE_CLEANUP_COMPLETED" if bool(boss.get("cleanup_completed", false)) else "REPORT_VALUE_CLEANUP_IN_PROGRESS",
		})
		if boss.has("owned_count"):
			rows.append({"title_key":"REPORT_ROW_BOSS_OWNED_RETIREMENTS", "count":maxi(0, int(boss["owned_count"]))})
	return rows


static func _pacing_rows(records: Array, defeats: Array[Dictionary]) -> Array[Dictionary]:
	var active_seconds := 0.0
	var visible_gaps := 0
	var slowest_first_preparation := -1.0
	var tactics := 0
	for record_variant in records:
		var metrics := Dictionary(Dictionary(record_variant).get("pacing_metrics", {}))
		active_seconds += maxf(0.0, float(metrics.get("active_seconds", 0.0)))
		visible_gaps += maxi(0, int(metrics.get("visible_gap_count", 0)))
		slowest_first_preparation = maxf(slowest_first_preparation, float(metrics.get("first_attack_preparation_seconds", -1.0)))
		tactics += maxi(0, int(metrics.get("tactic_count", 0)))
	return [
		{"title_key":"REPORT_ROW_ORDINARY_DEFEATS", "count":_total_defeats(defeats)},
		{"title_key":"REPORT_ROW_STAGE_PACING_TIME", "value":_format_duration(active_seconds)},
		{"title_key":"REPORT_ROW_VISIBLE_GAPS", "count":visible_gaps},
		{"title_key":"REPORT_ROW_FIRST_ATTACK_PREPARATION", "value":"%.2fs" % slowest_first_preparation if slowest_first_preparation >= 0.0 else "--"},
		{"title_key":"REPORT_ROW_ENGAGEMENT_TACTICS", "count":tactics},
	]


static func _diagnostic_rows(records: Array) -> Array[Dictionary]:
	var latest := {}
	for record_variant in records:
		var metrics := Dictionary(Dictionary(record_variant).get("diagnostic_metrics", {}))
		if not metrics.is_empty():
			latest = metrics
	var rows: Array[Dictionary] = [{"title_key":"REPORT_ROW_DIAGNOSTIC_SCOPE", "value_key":"REPORT_VALUE_LOCAL_LATEST_TEN"}]
	if not bool(latest.get("active", false)):
		rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_STATUS", "value_key":"REPORT_VALUE_DIAGNOSTIC_NOT_RECORDED"})
		return rows
	rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_EVENTS", "value":"%d / %d" % [maxi(0, int(latest.get("event_count", 0))), maxi(0, int(latest.get("event_cap", 0)))]})
	rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_SAMPLES", "value":"%d / %d" % [maxi(0, int(latest.get("sample_count", 0))), maxi(0, int(latest.get("sample_cap", 0)))]})
	rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_DROPPED", "count":maxi(0, int(latest.get("event_dropped", 0)))})
	return rows


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
