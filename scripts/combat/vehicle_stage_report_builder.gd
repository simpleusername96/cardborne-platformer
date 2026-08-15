class_name VehicleStageReportBuilder
extends RefCounted

## Builds immutable, localized-key-only report rows from combat telemetry.

const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const DamageSources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")
const ATTRIBUTE_KEYS := {
	&"kinetic":"REPORT_ATTRIBUTE_KINETIC",
	&"thermal":"REPORT_ATTRIBUTE_THERMAL",
	&"toxin":"REPORT_ATTRIBUTE_TOXIN",
	&"cryo":"REPORT_ATTRIBUTE_CRYO",
	&"arc":"REPORT_ATTRIBUTE_ARC",
}


static func build(
	telemetry: Dictionary,
	stage_data: Dictionary,
	failure: bool = false
) -> Dictionary:
	var defeat_rows := _defeat_rows(Dictionary(telemetry.get("defeats", {})))
	var outgoing_values := Dictionary(telemetry.get("outgoing", {}))
	var attribute_values := Dictionary(telemetry.get("attributes", {}))
	_attach_elite_counts(
		defeat_rows,
		Dictionary(telemetry.get("elites", {}))
	)
	var incoming_rows := _damage_rows(Dictionary(telemetry.get("incoming", {})), true, 3)
	var damage_rows: Array[Dictionary] = _damage_rows(outgoing_values, false, 8)
	damage_rows.append_array(_attribute_rows(
		attribute_values,
		Dictionary(telemetry.get("status_applications", {}))
	))
	var stage_number := int(stage_data.get("number", 1))
	var has_boss := bool(stage_data.get("has_boss", false))
	var run_time_seconds := maxf(0.0, float(stage_data.get("run_time_seconds", 0.0)))
	var hull := maxf(0.0, float(stage_data.get("hull", 0.0)))
	var max_hull := maxf(0.0, float(stage_data.get("max_hull", 0.0)))
	var boss := Dictionary(telemetry.get("boss", {}))
	var pacing := Dictionary(stage_data.get("pacing", {}))
	var diagnostics := Dictionary(stage_data.get("diagnostics", {}))
	return {
		"failure":failure,
		"stage_number":stage_number,
		"stage_title_key":String(stage_data.get("title_key", "")),
		"has_boss":has_boss,
		"has_next_stage":bool(stage_data.get("has_next_stage", false)),
		"run_time_seconds":run_time_seconds,
		"hull":hull,
		"max_hull":max_hull,
		"defeats":defeat_rows,
		"outgoing":_damage_rows(outgoing_values, false, 8),
		"total_outgoing":_sum_damage(outgoing_values),
		"attributes":_attribute_rows(
			attribute_values,
			Dictionary(telemetry.get("status_applications", {}))
		),
		"total_attributes":_sum_damage(attribute_values),
		"incoming":incoming_rows,
		"last_incoming_source":StringName(telemetry.get("last_incoming_source", &"")),
		"last_incoming_damage":float(telemetry.get("last_incoming_damage", 0.0)),
		"outcome_rows":[
			{"title_key":"REPORT_ROW_STATUS", "value_key":"REPORT_VALUE_FAILURE" if failure else "REPORT_VALUE_CLEARED"},
			{"title_key":"REPORT_ROW_HULL", "value":"%.0f / %.0f" % [hull, max_hull]},
		],
		"cycle_progress_rows":[
			{"title_key":"REPORT_ROW_CYCLE", "value":str(stage_number)},
			{"title_key":"REPORT_ROW_ACTIVE_TIME", "value":_format_duration(run_time_seconds)},
		],
		"build_rows":Array(stage_data.get("build_rows", [])).duplicate(true),
		"damage_rows":damage_rows,
		"defense_rows":incoming_rows.duplicate(true),
		"enemy_rows":defeat_rows.duplicate(true),
		"boss_rows":_boss_rows(boss, has_boss),
		"pacing_rows":_pacing_rows(pacing, defeat_rows, Dictionary(telemetry.get("tactics", {}))),
		"diagnostic_limitations":_diagnostic_rows(diagnostics),
		"boss_report":boss.duplicate(true),
		"pacing_metrics":{
			"active_seconds":float(pacing.get("active_seconds", 0.0)),
			"visible_gap_count":maxi(0, int(pacing.get("visible_gap_count", 0))),
			"tactic_count":Dictionary(telemetry.get("tactics", {})).size(),
		},
		"diagnostic_metrics":diagnostics.duplicate(true),
}


static func build_rows(build_snapshot: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for upgrade_variant in Array(build_snapshot.get("upgrades", [])):
		var upgrade := Dictionary(upgrade_variant)
		rows.append({
			"title_key":String(upgrade.get("title_key", "REPORT_SOURCE_OTHER")),
			"value":"Lv. %d" % maxi(1, int(upgrade.get("level", 1))),
		})
	return rows


static func _format_duration(seconds: float) -> String:
	var total := maxi(0, floori(seconds))
	return "%d:%02d" % [total / 60, total % 60]


static func _sum_defeats(rows: Array[Dictionary]) -> int:
	var total := 0
	for row in rows:
		total += maxi(0, int(row.get("count", 0)))
	return total


static func _boss_rows(boss: Dictionary, has_boss: bool) -> Array[Dictionary]:
	var cleanup_completed := bool(boss.get("cleanup_completed", false))
	var rows: Array[Dictionary] = [{"title_key":"REPORT_ROW_BOSSES_DEFEATED", "count":1 if has_boss and cleanup_completed else 0}]
	var boss_id := StringName(boss.get("id", &""))
	if not boss_id.is_empty():
		rows.append({
			"name_key":String(boss_id),
			"value_key":"REPORT_VALUE_CLEARED" if cleanup_completed else "REPORT_VALUE_CLEANUP_IN_PROGRESS",
		})
	if bool(boss.get("cleanup_started", false)):
		rows.append({
			"title_key":"REPORT_ROW_BOSS_CLEANUP",
			"value_key":"REPORT_VALUE_CLEANUP_COMPLETED" if bool(boss.get("cleanup_completed", false)) else "REPORT_VALUE_CLEANUP_IN_PROGRESS",
		})
	if boss.has("owned_count"):
		rows.append({"title_key":"REPORT_ROW_BOSS_OWNED_RETIREMENTS", "count":maxi(0, int(boss["owned_count"]))})
	return rows


static func _pacing_rows(pacing: Dictionary, defeat_rows: Array[Dictionary], tactics: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = [{"title_key":"REPORT_ROW_ORDINARY_DEFEATS", "count":_sum_defeats(defeat_rows)}]
	rows.append({"title_key":"REPORT_ROW_STAGE_PACING_TIME", "value":_format_duration(float(pacing.get("active_seconds", 0.0)))})
	rows.append({"title_key":"REPORT_ROW_VISIBLE_GAPS", "count":maxi(0, int(pacing.get("visible_gap_count", 0)))})
	rows.append({"title_key":"REPORT_ROW_ENGAGEMENT_TACTICS", "count":tactics.size()})
	return rows


static func _diagnostic_rows(diagnostics: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = [{"title_key":"REPORT_ROW_DIAGNOSTIC_SCOPE", "value_key":"REPORT_VALUE_LOCAL_LATEST_TEN"}]
	if not bool(diagnostics.get("active", false)):
		rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_STATUS", "value_key":"REPORT_VALUE_DIAGNOSTIC_NOT_RECORDED"})
		return rows
	rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_EVENTS", "value":"%d / %d" % [maxi(0, int(diagnostics.get("event_count", 0))), maxi(0, int(diagnostics.get("event_cap", 0)))]})
	rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_SAMPLES", "value":"%d / %d" % [maxi(0, int(diagnostics.get("sample_count", 0))), maxi(0, int(diagnostics.get("sample_cap", 0)))]})
	rows.append({"title_key":"REPORT_ROW_DIAGNOSTIC_DROPPED", "count":maxi(0, int(diagnostics.get("event_dropped", 0)))})
	return rows


static func _attribute_rows(
	values: Dictionary,
	status_applications: Dictionary
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for attribute in ATTRIBUTE_KEYS:
		var damage := maxf(0.0, float(values.get(attribute, 0.0)))
		var applications := 0
		match StringName(attribute):
			&"toxin":
				applications = int(status_applications.get(&"poison", 0))
			&"cryo":
				applications = int(status_applications.get(&"chill", 0))
		if damage <= 0.0 and applications <= 0:
			continue
		rows.append({
			"id":StringName(attribute),
			"title_key":String(ATTRIBUTE_KEYS[attribute]),
			"damage":damage,
			"applications":applications,
		})
	rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if not is_equal_approx(float(a["damage"]), float(b["damage"])):
				return float(a["damage"]) > float(b["damage"])
			return String(a["id"]) < String(b["id"])
	)
	_assign_percentages(rows)
	return rows


static func _defeat_rows(values: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for archetype_value in values:
		var archetype := StringName(archetype_value)
		var definition := EnemyArchetypes.definition(archetype)
		rows.append({
			"id":archetype,
			"name_key":String(definition.get("name_key", "REPORT_SOURCE_OTHER")),
			"count":int(values[archetype]),
		})
	rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a["count"]) != int(b["count"]):
				return int(a["count"]) > int(b["count"])
			return String(a["id"]) < String(b["id"])
	)
	return rows


static func _attach_elite_counts(
	rows: Array[Dictionary],
	values: Dictionary
) -> void:
	var counts := {}
	for composite_value in values:
		var composite := String(composite_value)
		var separator := composite.find(":")
		if separator <= 0:
			continue
		var archetype := StringName(composite.left(separator))
		counts[archetype] = int(counts.get(archetype, 0)) + int(
			values[composite_value]
		)
	for row in rows:
		row["elite_count"] = int(counts.get(StringName(row["id"]), 0))


static func _damage_rows(
	values: Dictionary,
	incoming: bool,
	max_rows: int
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for source_value in values:
		var source_id := StringName(source_value)
		var damage := float(values[source_id])
		if damage <= 0.0:
			continue
		rows.append({
			"id":source_id,
			"title_key":DamageSources.title_key(source_id, incoming),
			"damage":damage,
		})
	rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if not is_equal_approx(float(a["damage"]), float(b["damage"])):
				return float(a["damage"]) > float(b["damage"])
			return String(a["id"]) < String(b["id"])
	)
	if rows.size() > max_rows:
		var retained := rows.slice(0, max_rows - 1)
		var other_damage := 0.0
		for index in range(max_rows - 1, rows.size()):
			other_damage += float(rows[index]["damage"])
		retained.append({
			"id":&"other",
			"title_key":"REPORT_SOURCE_OTHER",
			"damage":other_damage,
		})
		rows = retained
	_assign_percentages(rows)
	return rows


static func _sum_damage(values: Dictionary) -> float:
	var total := 0.0
	for damage in values.values():
		total += maxf(0.0, float(damage))
	return total


static func _assign_percentages(rows: Array[Dictionary]) -> void:
	var total := 0.0
	for row in rows:
		total += float(row["damage"])
	if total <= 0.0:
		for row in rows:
			row["percentage_tenths"] = 0
		return
	var assigned := 0
	var remainders: Array[Dictionary] = []
	for index in rows.size():
		var exact := float(rows[index]["damage"]) / total * 1000.0
		var tenths := floori(exact)
		rows[index]["percentage_tenths"] = tenths
		assigned += tenths
		remainders.append({
			"index":index,
			"remainder":exact - float(tenths),
			"id":String(rows[index]["id"]),
		})
	remainders.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if not is_equal_approx(float(a["remainder"]), float(b["remainder"])):
				return float(a["remainder"]) > float(b["remainder"])
			return String(a["id"]) < String(b["id"])
	)
	for cursor in 1000 - assigned:
		var row_index := int(remainders[cursor % remainders.size()]["index"])
		rows[row_index]["percentage_tenths"] = int(rows[row_index]["percentage_tenths"]) + 1
