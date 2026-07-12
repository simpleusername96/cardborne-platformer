class_name CharacterKit
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var profile_id: StringName
@export var passive_id: StringName
@export_range(0.0, 10.0, 0.05) var guarded_duration: float = 0.0
@export_range(0.0, 60.0, 0.05) var guarded_rearm_cooldown: float = 0.0
@export var basic_attack: AttackDefinition
@export var heavy_attack: AttackDefinition
@export var skills: Array[SkillDefinition] = []


func get_attack_for_action(action_name: StringName) -> AttackDefinition:
	if basic_attack != null and basic_attack.input_action == action_name:
		return basic_attack
	if heavy_attack != null and heavy_attack.input_action == action_name:
		return heavy_attack
	for skill in skills:
		if skill != null and skill.input_action == action_name:
			return skill
	return null


func get_skill_by_slot(slot: int) -> SkillDefinition:
	for skill in skills:
		if skill != null and skill.skill_slot == slot:
			return skill
	return null


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	if String(id).strip_edges().is_empty():
		errors.append("Character kit ID cannot be blank.")
	if display_name.strip_edges().is_empty():
		errors.append("Character kit '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Character kit '%s' needs a positive content version." % id)
	if String(profile_id).strip_edges().is_empty():
		errors.append("Character kit '%s' needs a profile ID." % id)
	if basic_attack == null or heavy_attack == null:
		errors.append("Character kit '%s' needs basic and heavy attacks." % id)
	var seen_ids: Dictionary = {}
	var seen_slots: Dictionary = {}
	for attack in _all_attacks():
		if attack == null:
			continue
		for error in attack.validate_definition():
			errors.append("Character kit '%s': %s" % [id, error])
		var attack_id := String(attack.id)
		if seen_ids.has(attack_id):
			errors.append("Character kit '%s' repeats attack ID '%s'." % [id, attack_id])
		seen_ids[attack_id] = true
		if attack is SkillDefinition:
			var slot := (attack as SkillDefinition).skill_slot
			if seen_slots.has(slot):
				errors.append("Character kit '%s' repeats skill slot %d." % [id, slot])
			seen_slots[slot] = true
	return errors


func _all_attacks() -> Array[AttackDefinition]:
	var attacks: Array[AttackDefinition] = [basic_attack, heavy_attack]
	for skill in skills:
		attacks.append(skill)
	return attacks
