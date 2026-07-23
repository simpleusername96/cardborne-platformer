class_name VehicleRunBuild
extends RefCounted

var catalog: VehicleUpgradeCatalog
var levels: Dictionary = {}
var element_core: StringName = &""


func _init(source_catalog: VehicleUpgradeCatalog = null) -> void:
	catalog = source_catalog if source_catalog != null else VehicleUpgradeCatalog.new()


func reset() -> void:
	levels.clear()
	element_core = &""


func level_of(upgrade_id: StringName) -> int:
	return int(levels.get(upgrade_id, 0))


func has(upgrade_id: StringName) -> bool:
	return level_of(upgrade_id) > 0


func total_levels() -> int:
	var total := 0
	for level in levels.values():
		total += int(level)
	return total


func active_optional_secondaries() -> int:
	var count := 0
	for upgrade_id in VehicleUpgradeCatalog.SECONDARY_FAMILY_IDS:
		if has(upgrade_id):
			count += 1
	return count


func stat(stat_id: StringName, base_value: float) -> float:
	var value := base_value
	for upgrade_id in levels:
		var definition := catalog.get_definition(StringName(upgrade_id))
		if definition == null: continue
		for modifier in definition.modifiers:
			if modifier.stat_id != stat_id: continue
			var modifier_value := modifier.value_at(level_of(StringName(upgrade_id)))
			if modifier.operation == "add": value += modifier_value
			else: value *= modifier_value
	return value


func preview(upgrade_id: StringName) -> Dictionary:
	var definition := catalog.get_definition(upgrade_id)
	if definition == null: return {"valid": false, "reason": &"missing"}
	if not catalog.compatible(definition, self): return {"valid": false, "reason": &"incompatible"}
	return {
		"valid": true,
		"id": upgrade_id,
		"old_level": level_of(upgrade_id),
		"new_level": level_of(upgrade_id) + 1,
		"max_level": definition.max_level,
		"title_key": definition.title_key,
		"description_key": definition.description_key,
		"family": definition.family,
	}


func apply(upgrade_id: StringName) -> Dictionary:
	var receipt := preview(upgrade_id)
	if not bool(receipt.get("valid", false)): return receipt
	levels[upgrade_id] = int(receipt["new_level"])
	var definition := catalog.get_definition(upgrade_id)
	if definition.exclusion_group == &"element_core": element_core = upgrade_id
	receipt["applied"] = true
	return receipt


func behavior(behavior_id: StringName) -> bool:
	for upgrade_id in levels:
		var definition := catalog.get_definition(StringName(upgrade_id))
		if definition != null and behavior_id in definition.behavior_ids:
			return true
	return false
