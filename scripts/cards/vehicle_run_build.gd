class_name VehicleRunBuild
extends RefCounted

const DAMAGE_ATTRIBUTE_IDS: Array[StringName] = [&"thermal_burst", &"bio_toxin"]
const UTILITY_ATTRIBUTE_IDS: Array[StringName] = [&"cryo_slow"]
const ACTIVE_WEAPON_CARD_IDS: Array[StringName] = [
	&"emp", &"gravity_collapse", &"kinetic_shockwave", &"piercing_lance",
]
const AUTOMATIC_WEAPON_CARD_IDS: Array[StringName] = [
	&"homing_missiles", &"electric_field", &"orbiting_blades",
	&"drop_mines", &"auto_laser", &"storm_barrage",
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


func active_automatic_weapons() -> int:
	var count := 0
	for upgrade_id in AUTOMATIC_WEAPON_CARD_IDS:
		if has(upgrade_id):
			count += 1
	return count


## Acquisition order keeps the three equal automatic-weapon presentation cells
## stable. It does not control firing order or card order.
func automatic_weapon_slot_key(upgrade_id: StringName) -> StringName:
	var automatic_ids: Array[StringName] = []
	for acquired_id in acquisition_order:
		if (
			acquired_id in AUTOMATIC_WEAPON_CARD_IDS
			and has(acquired_id)
			and not automatic_ids.has(acquired_id)
		):
			automatic_ids.append(acquired_id)
	# Older in-memory builds can lack acquisition history. Keep their fallback
	# deterministic without letting arbitrary Dictionary order choose a position.
	if automatic_ids.size() < 3:
		var legacy_automatic_ids: Array[StringName] = []
		for level_id_variant in levels.keys():
			var level_id := StringName(level_id_variant)
			if (
				level_id in AUTOMATIC_WEAPON_CARD_IDS
				and has(level_id)
				and not automatic_ids.has(level_id)
			):
				legacy_automatic_ids.append(level_id)
		legacy_automatic_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
		automatic_ids.append_array(legacy_automatic_ids)
	var index := automatic_ids.find(upgrade_id)
	return StringName("weapon_%d" % index) if index >= 0 and index < 3 else &""


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
		&"emp": return &"emp"
		&"gravity_collapse": return &"black_hole"
		&"kinetic_shockwave": return &"shockwave"
		&"piercing_lance": return &"cross_beam"
		_: return &""


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
