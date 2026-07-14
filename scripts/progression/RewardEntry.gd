class_name RewardEntry
extends Resource

const TYPE_CURRENCY := &"currency"
const TYPE_EQUIPMENT_DISCOVERY := &"equipment_discovery"
const TYPE_BLUEPRINT_UNLOCK := &"blueprint_unlock"
const TYPE_SPIRIT_STONE_UNLOCK := &"spirit_stone_unlock"
const TYPES: Array[StringName] = [
	TYPE_CURRENCY,
	TYPE_EQUIPMENT_DISCOVERY,
	TYPE_BLUEPRINT_UNLOCK,
	TYPE_SPIRIT_STONE_UNLOCK,
]

@export var reward_type: StringName = TYPE_CURRENCY
@export var content_id: StringName
@export_range(0, 9999, 1) var minimum_amount: int = 1
@export_range(0, 9999, 1) var maximum_amount: int = 1
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if not TYPES.has(reward_type):
		errors.append("Reward entry uses unsupported type '%s'." % reward_type)
	ContentId.validate(errors, "Reward content ID", content_id)
	if minimum_amount <= 0 or maximum_amount < minimum_amount:
		errors.append("Reward '%s' amount range is invalid." % content_id)
	if (
		reward_type in [
			TYPE_EQUIPMENT_DISCOVERY,
			TYPE_BLUEPRINT_UNLOCK,
			TYPE_SPIRIT_STONE_UNLOCK,
		]
		and (minimum_amount != 1 or maximum_amount != 1)
	):
		errors.append("Permanent reward '%s' must resolve exactly once." % content_id)
	if not is_finite(chance) or chance < 0.0 or chance > 1.0:
		errors.append("Reward '%s' chance must be between zero and one." % content_id)
	return errors


func resolve_amount(rng: RandomNumberGenerator) -> int:
	if chance <= 0.0:
		return 0
	if chance < 1.0 and rng.randf() >= chance:
		return 0
	return rng.randi_range(minimum_amount, maximum_amount)
