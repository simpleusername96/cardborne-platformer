extends Node

# Owns profile-lifetime state; save I/O belongs to a separate persistence adapter.
signal profile_changed(section: StringName)
signal setting_changed(setting_id: StringName, value: Variant)

const EQUIPMENT_SLOTS: Array[String] = ["weapon", "armor", "charm", "relic"]
const CONSUMABLE_SLOT := "consumable"
const DEFAULT_SETTINGS: Dictionary = {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"screen_shake": true,
	"damage_flash": true,
}

var _materials: Dictionary = {}
var _owned_equipment: Dictionary = {}
var _loadout: Dictionary = {
	"weapon": "",
	"armor": "",
	"charm": "",
	"relic": "",
	"consumable": "",
}
var _mastery_unlocks: Dictionary = {}
var _durable_unlocks: Dictionary = {}
var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)


func reset_to_defaults() -> void:
	_materials.clear()
	_owned_equipment.clear()
	_mastery_unlocks.clear()
	_durable_unlocks.clear()
	_settings = DEFAULT_SETTINGS.duplicate(true)
	for slot_id in _loadout:
		_loadout[slot_id] = ""
	profile_changed.emit(&"all")


func get_profile_snapshot() -> Dictionary:
	return {
		"materials": get_materials(),
		"owned_equipment": get_owned_equipment(),
		"loadout": get_loadout(),
		"mastery_unlocks": _mastery_unlocks.duplicate(true),
		"durable_unlocks": get_durable_unlocks(),
		"settings": get_settings(),
	}


func get_materials() -> Dictionary:
	return _materials.duplicate(true)


func get_material_count(material_id: String) -> int:
	return int(_materials.get(material_id, 0))


func grant_material(material_id: String, amount: int) -> bool:
	if material_id.is_empty() or amount <= 0:
		return false
	_materials[material_id] = get_material_count(material_id) + amount
	profile_changed.emit(&"materials")
	return true


func spend_material(material_id: String, amount: int) -> bool:
	if material_id.is_empty() or amount <= 0 or get_material_count(material_id) < amount:
		return false
	var remaining := get_material_count(material_id) - amount
	if remaining == 0:
		_materials.erase(material_id)
	else:
		_materials[material_id] = remaining
	profile_changed.emit(&"materials")
	return true


func get_owned_equipment() -> Array[String]:
	var item_ids: Array[String] = []
	for item_id in _owned_equipment:
		item_ids.append(String(item_id))
	item_ids.sort()
	return item_ids


func owns_equipment(item_id: String) -> bool:
	return _owned_equipment.has(item_id)


func grant_equipment(item_id: String) -> bool:
	if item_id.is_empty() or owns_equipment(item_id):
		return false
	_owned_equipment[item_id] = true
	profile_changed.emit(&"equipment")
	return true


func get_loadout() -> Dictionary:
	return _loadout.duplicate(true)


func set_loadout_item(slot_id: String, item_id: String) -> bool:
	if not _is_loadout_slot(slot_id):
		return false
	if not item_id.is_empty() and not owns_equipment(item_id):
		return false
	if String(_loadout.get(slot_id, "")) == item_id:
		return true
	_loadout[slot_id] = item_id
	profile_changed.emit(&"loadout")
	return true


func unlock_mastery(character_id: String, node_id: String) -> bool:
	if character_id.is_empty() or node_id.is_empty():
		return false
	var character_nodes: Dictionary = _mastery_unlocks.get(character_id, {}).duplicate(true)
	if character_nodes.has(node_id):
		return false
	character_nodes[node_id] = true
	_mastery_unlocks[character_id] = character_nodes
	profile_changed.emit(&"mastery")
	return true


func has_mastery(character_id: String, node_id: String) -> bool:
	var character_nodes: Dictionary = _mastery_unlocks.get(character_id, {})
	return character_nodes.has(node_id)


func get_mastery_unlocks(character_id: String) -> Array[String]:
	var node_ids: Array[String] = []
	var character_nodes: Dictionary = _mastery_unlocks.get(character_id, {})
	for node_id in character_nodes:
		node_ids.append(String(node_id))
	node_ids.sort()
	return node_ids


func unlock_content(content_id: String) -> bool:
	if content_id.is_empty() or _durable_unlocks.has(content_id):
		return false
	_durable_unlocks[content_id] = true
	profile_changed.emit(&"unlocks")
	return true


func has_content_unlock(content_id: String) -> bool:
	return _durable_unlocks.has(content_id)


func get_durable_unlocks() -> Array[String]:
	var content_ids: Array[String] = []
	for content_id in _durable_unlocks:
		content_ids.append(String(content_id))
	content_ids.sort()
	return content_ids


func get_settings() -> Dictionary:
	return _settings.duplicate(true)


func get_setting(setting_id: String, fallback: Variant = null) -> Variant:
	return _settings.get(setting_id, fallback)


func set_setting(setting_id: String, value: Variant) -> bool:
	if not _settings.has(setting_id) or not _is_valid_setting_value(setting_id, value):
		return false
	var normalized_value: Variant = value
	if setting_id.ends_with("_volume"):
		normalized_value = float(value)
	if _settings[setting_id] == normalized_value:
		return true
	_settings[setting_id] = normalized_value
	setting_changed.emit(StringName(setting_id), normalized_value)
	profile_changed.emit(&"settings")
	return true


func _is_loadout_slot(slot_id: String) -> bool:
	return slot_id == CONSUMABLE_SLOT or EQUIPMENT_SLOTS.has(slot_id)


func _is_valid_setting_value(setting_id: String, value: Variant) -> bool:
	if setting_id.ends_with("_volume"):
		if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
			return false
		var numeric_value := float(value)
		return is_finite(numeric_value) and numeric_value >= 0.0 and numeric_value <= 1.0
	return typeof(value) == TYPE_BOOL
