class_name VehicleRunBuild
extends RefCounted

const DAMAGE_ATTRIBUTE_IDS: Array[StringName] = [&"thermal_burst", &"bio_toxin"]
const UTILITY_ATTRIBUTE_IDS: Array[StringName] = [&"cryo_slow", &"shock_disruption"]
const ACTIVE_WEAPON_CARD_IDS: Array[StringName] = [
	&"gravity_collapse", &"kinetic_shockwave", &"piercing_lance",
]

var catalog: VehicleUpgradeCatalog
var levels: Dictionary = {}


func _init(source_catalog: VehicleUpgradeCatalog = null) -> void:
	catalog = source_catalog if source_catalog != null else VehicleUpgradeCatalog.new()


func reset() -> void:
	levels.clear()


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
	for definition in catalog.all_definitions():
		if (
			definition.category == &"secondary"
			and definition.secondary_slot_kind == &"optional"
			and has(definition.id)
		):
			count += 1
	return count


func active_damage_attribute_id() -> StringName:
	for upgrade_id in DAMAGE_ATTRIBUTE_IDS:
		if has(upgrade_id):
			return upgrade_id
	return &""


func active_utility_attribute_id() -> StringName:
	for upgrade_id in UTILITY_ATTRIBUTE_IDS:
		if has(upgrade_id):
			return upgrade_id
	return &""


func active_attribute_id(slot_kind: StringName) -> StringName:
	match slot_kind:
		&"damage": return active_damage_attribute_id()
		&"utility": return active_utility_attribute_id()
		_: return &""


func active_weapon_card_id() -> StringName:
	for upgrade_id in ACTIVE_WEAPON_CARD_IDS:
		if has(upgrade_id):
			return upgrade_id
	return &""


func active_weapon_id() -> StringName:
	match active_weapon_card_id():
		&"gravity_collapse": return &"black_hole"
		&"kinetic_shockwave": return &"shockwave"
		&"piercing_lance": return &"cross_beam"
		_: return &"emp"


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
		"category": definition.category,
	}


func apply(upgrade_id: StringName) -> Dictionary:
	var receipt := preview(upgrade_id)
	if not bool(receipt.get("valid", false)): return receipt
	levels[upgrade_id] = int(receipt["new_level"])
	receipt["applied"] = true
	return receipt
