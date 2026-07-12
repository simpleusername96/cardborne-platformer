class_name RewardEntry
extends Resource

const TYPE_CURRENCY := &"currency"

@export var reward_type: StringName = TYPE_CURRENCY
@export var content_id: StringName
@export_range(0, 9999, 1) var minimum_amount: int = 1
@export_range(0, 9999, 1) var maximum_amount: int = 1
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if reward_type != TYPE_CURRENCY:
		errors.append("Reward entry uses unsupported type '%s'." % reward_type)
	ContentId.validate(errors, "Reward content ID", content_id)
	if minimum_amount <= 0 or maximum_amount < minimum_amount:
		errors.append("Reward '%s' amount range is invalid." % content_id)
	if not is_finite(chance) or chance < 0.0 or chance > 1.0:
		errors.append("Reward '%s' chance must be between zero and one." % content_id)
	return errors


func resolve_amount(rng: RandomNumberGenerator) -> int:
	if chance <= 0.0:
		return 0
	if chance < 1.0 and rng.randf() >= chance:
		return 0
	return rng.randi_range(minimum_amount, maximum_amount)
