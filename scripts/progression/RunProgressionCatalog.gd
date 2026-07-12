class_name RunProgressionCatalog
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var level_xp_totals: PackedInt32Array = PackedInt32Array([0, 20, 55, 105, 170, 250])
@export var micro_upgrades: Array[MicroUpgradeDefinition] = []
@export var recovery_choice: MicroUpgradeDefinition


func get_upgrade(upgrade_id: StringName) -> MicroUpgradeDefinition:
	for upgrade in micro_upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	if recovery_choice != null and recovery_choice.id == upgrade_id:
		return recovery_choice
	return null


func get_level_for_xp(total_xp: int) -> int:
	var level := 1
	for threshold_index in level_xp_totals.size():
		if total_xp >= level_xp_totals[threshold_index]:
			level = threshold_index + 1
	return level


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Run progression catalog ID", id)
	if display_name.strip_edges().is_empty() or content_version <= 0:
		errors.append("Run progression catalog needs a display name and positive version.")
	if level_xp_totals.size() < 2 or level_xp_totals[0] != 0:
		errors.append("Run progression catalog needs a level curve beginning at zero.")
	for threshold_index in range(1, level_xp_totals.size()):
		if level_xp_totals[threshold_index] <= level_xp_totals[threshold_index - 1]:
			errors.append("Run level XP totals must increase strictly.")
	var seen: Dictionary = {}
	for upgrade in micro_upgrades:
		if upgrade == null:
			errors.append("Run progression catalog contains a null upgrade.")
			continue
		if seen.has(upgrade.id):
			errors.append("Run progression catalog repeats '%s'." % upgrade.id)
		seen[upgrade.id] = true
		for upgrade_error in upgrade.validate_definition():
			errors.append(upgrade_error)
	if recovery_choice == null or not recovery_choice.recovery_choice:
		errors.append("Run progression catalog needs a recovery fallback choice.")
	elif seen.has(recovery_choice.id):
		errors.append("Recovery choice ID must be distinct from normal upgrades.")
	else:
		for recovery_error in recovery_choice.validate_definition():
			errors.append(recovery_error)
	return errors
