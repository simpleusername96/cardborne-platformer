class_name FieldPickupDefinition
extends Resource

const EFFECT_HEAL := &"heal"
const EFFECT_REFILL_CONSUMABLE := &"refill_consumable"
const EFFECT_REDUCE_SKILL_COOLDOWNS := &"reduce_skill_cooldowns"
const EFFECT_GRANT_CURRENCY := &"grant_currency"
const EFFECT_TYPES: Array[StringName] = [
	EFFECT_HEAL,
	EFFECT_REFILL_CONSUMABLE,
	EFFECT_REDUCE_SKILL_COOLDOWNS,
	EFFECT_GRANT_CURRENCY,
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var effect_type: StringName
@export_range(0.25, 20.0, 0.25) var amount: float = 1.0
@export var currency_id: StringName
@export var icon_id: StringName
@export var visual_color: Color = Color("70d69a")


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Field pickup ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Field pickup '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Field pickup '%s' needs a positive content version." % id)
	if effect_type not in EFFECT_TYPES:
		errors.append("Field pickup '%s' has an unsupported effect type." % id)
	if not is_finite(amount) or amount <= 0.0:
		errors.append("Field pickup '%s' needs a positive amount." % id)
	if effect_type != EFFECT_REDUCE_SKILL_COOLDOWNS and not is_equal_approx(amount, roundf(amount)):
		errors.append("Field pickup '%s' needs a whole-number amount." % id)
	ContentId.validate(errors, "Field pickup '%s' icon ID" % id, icon_id)
	if effect_type == EFFECT_GRANT_CURRENCY:
		ContentId.validate(errors, "Field pickup '%s' currency ID" % id, currency_id)
	elif currency_id != &"":
		errors.append("Field pickup '%s' declares currency for a non-currency effect." % id)
	if visual_color.a <= 0.0:
		errors.append("Field pickup '%s' needs a visible color." % id)
	return errors
