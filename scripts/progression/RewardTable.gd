class_name RewardTable
extends Resource

const EQUIPMENT_POOL_STAGE_CACHE := &"stage_cache"
const EQUIPMENT_POOL_COMPATIBLE_NON_BOSS := &"compatible_non_boss_equipment"
const EQUIPMENT_POOL_IDS: Array[StringName] = [
	EQUIPMENT_POOL_STAGE_CACHE,
	EQUIPMENT_POOL_COMPATIBLE_NON_BOSS,
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var entries: Array[RewardEntry] = []
# Legacy resource fields; active reward tables leave both values empty.
@export_group("Legacy Equipment Discovery")
@export var equipment_pool_id: StringName
@export_range(0.0, 1.0, 0.01) var equipment_pool_chance: float = 0.0


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Reward table ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Reward table '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Reward table '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Reward table '%s' tag" % id, tags, false)
	if entries.is_empty():
		errors.append("Reward table '%s' needs at least one entry." % id)
	for entry_index in entries.size():
		var entry := entries[entry_index]
		if entry == null:
			errors.append("Reward table '%s' entry %d is null." % [id, entry_index])
			continue
		for entry_error in entry.validate_definition():
			errors.append("Reward table '%s': %s" % [id, entry_error])
	if equipment_pool_id == &"":
		if not is_zero_approx(equipment_pool_chance):
			errors.append("Reward table '%s' has equipment chance without a pool." % id)
	elif not EQUIPMENT_POOL_IDS.has(equipment_pool_id):
		errors.append(
			"Reward table '%s' uses unsupported equipment pool '%s'."
			% [id, equipment_pool_id]
		)
	elif not is_finite(equipment_pool_chance) or equipment_pool_chance <= 0.0:
		errors.append("Reward table '%s' equipment pool needs a positive chance." % id)
	return errors
