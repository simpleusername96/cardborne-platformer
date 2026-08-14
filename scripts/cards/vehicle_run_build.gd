class_name VehicleRunBuild
extends RefCounted

const DAMAGE_ATTRIBUTE_IDS: Array[StringName] = [&"thermal_burst", &"bio_toxin"]
const UTILITY_ATTRIBUTE_IDS: Array[StringName] = [&"cryo_slow", &"shock_disruption"]
const ACTIVE_WEAPON_CARD_IDS: Array[StringName] = [
	&"gravity_collapse", &"kinetic_shockwave", &"piercing_lance",
]

var catalog: VehicleUpgradeCatalog
var levels: Dictionary = {}
## First-acquisition order is run truth for read-only build summaries. It is not
## an equipment limit and never changes when an existing card levels up.
var acquisition_order: Array[StringName] = []


func _init(source_catalog: VehicleUpgradeCatalog = null) -> void:
	catalog = source_catalog if source_catalog != null else VehicleUpgradeCatalog.new()


func reset() -> void:
	levels.clear()
	acquisition_order.clear()


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


## Acquisition order is used only to keep the two generic optional-weapon
## presentation positions stable. It does not control category or card order.
func optional_secondary_slot_key(upgrade_id: StringName) -> StringName:
	var optional_ids: Array[StringName] = []
	for acquired_id in acquisition_order:
		var definition := catalog.get_definition(acquired_id)
		if (
			definition != null
			and definition.category == &"secondary"
			and definition.secondary_slot_kind == &"optional"
			and has(acquired_id)
			and not optional_ids.has(acquired_id)
		):
			optional_ids.append(acquired_id)
	# Older in-memory builds can lack acquisition history. Keep their fallback
	# deterministic without letting arbitrary Dictionary order choose a position.
	if optional_ids.size() < 2:
		var legacy_optional_ids: Array[StringName] = []
		for level_id_variant in levels.keys():
			var level_id := StringName(level_id_variant)
			var legacy_definition := catalog.get_definition(level_id)
			if (
				legacy_definition != null
				and legacy_definition.category == &"secondary"
				and legacy_definition.secondary_slot_kind == &"optional"
				and has(level_id)
				and not optional_ids.has(level_id)
			):
				legacy_optional_ids.append(level_id)
		legacy_optional_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
		optional_ids.append_array(legacy_optional_ids)
	var index := optional_ids.find(upgrade_id)
	return StringName("optional_%d" % index) if index >= 0 and index < 2 else &""


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
	var first_acquisition := not has(upgrade_id)
	levels[upgrade_id] = int(receipt["new_level"])
	if first_acquisition:
		acquisition_order.append(upgrade_id)
	receipt["applied"] = true
	return receipt
