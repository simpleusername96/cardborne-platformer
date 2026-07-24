class_name VehicleStageReportBuilder
extends RefCounted

## Builds immutable, localized-key-only report rows from combat telemetry.

const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const DamageSources = preload("res://scripts/combat/vehicle_damage_source_catalog.gd")


static func build(
	telemetry: Dictionary,
	stage_data: Dictionary,
	failure: bool = false
) -> Dictionary:
	return {
		"failure":failure,
		"stage_number":int(stage_data.get("number", 1)),
		"stage_title_key":String(stage_data.get("title_key", "")),
		"has_next_stage":bool(stage_data.get("has_next_stage", false)),
		"defeats":_defeat_rows(Dictionary(telemetry.get("defeats", {}))),
		"elites":_elite_rows(Dictionary(telemetry.get("elites", {}))),
		"outgoing":_damage_rows(Dictionary(telemetry.get("outgoing", {})), false, 8),
		"incoming":_damage_rows(Dictionary(telemetry.get("incoming", {})), true, 3),
		"last_incoming_source":StringName(telemetry.get("last_incoming_source", &"")),
		"last_incoming_damage":float(telemetry.get("last_incoming_damage", 0.0)),
	}


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


static func _elite_rows(values: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for trait_value in values:
		var trait_id := StringName(trait_value)
		rows.append({
			"id":trait_id,
			"name_key":"ELITE_%s" % String(trait_id).to_upper(),
			"count":int(values[trait_id]),
		})
	rows.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return String(a["id"]) < String(b["id"])
	)
	return rows


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


static func _assign_percentages(rows: Array[Dictionary]) -> void:
	var total := 0.0
	for row in rows:
		total += float(row["damage"])
	if total <= 0.0:
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
