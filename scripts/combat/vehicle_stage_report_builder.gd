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
	return {
		"failure":failure,
		"stage_number":int(stage_data.get("number", 1)),
		"stage_title_key":String(stage_data.get("title_key", "")),
		"has_next_stage":bool(stage_data.get("has_next_stage", false)),
		"clear_time":maxf(0.0, float(stage_data.get("clear_time", 0.0))),
		"hull":maxf(0.0, float(stage_data.get("hull", 0.0))),
		"max_hull":maxf(0.0, float(stage_data.get("max_hull", 0.0))),
		"defeats":defeat_rows,
		"outgoing":_damage_rows(outgoing_values, false, 8),
		"total_outgoing":_sum_damage(outgoing_values),
		"attributes":_attribute_rows(
			attribute_values,
			Dictionary(telemetry.get("status_applications", {}))
		),
		"total_attributes":_sum_damage(attribute_values),
		"incoming":_damage_rows(Dictionary(telemetry.get("incoming", {})), true, 3),
		"last_incoming_source":StringName(telemetry.get("last_incoming_source", &"")),
		"last_incoming_damage":float(telemetry.get("last_incoming_damage", 0.0)),
	}


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
