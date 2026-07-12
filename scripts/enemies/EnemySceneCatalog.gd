class_name EnemySceneCatalog
extends Resource

@export var id: StringName
@export var content_version: int = 1
@export var entries: Array[EnemySceneEntry] = []


func get_scene(archetype_id: StringName) -> PackedScene:
	for entry in entries:
		if entry != null and entry.archetype_id == archetype_id:
			return entry.scene
	return null


func validate_catalog(enemy_catalog: EnemyCatalog = null) -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy scene catalog ID", id)
	if content_version <= 0:
		errors.append("Enemy scene catalog needs a positive content version.")
	var seen: Dictionary = {}
	for entry_index in entries.size():
		var entry := entries[entry_index]
		if entry == null:
			errors.append("Enemy scene entry %d is null." % entry_index)
			continue
		for entry_error in entry.validate_definition():
			errors.append(entry_error)
		if seen.has(String(entry.archetype_id)):
			errors.append("Enemy scene catalog repeats '%s'." % entry.archetype_id)
		seen[String(entry.archetype_id)] = true
		if enemy_catalog != null and not enemy_catalog.has_archetype(entry.archetype_id):
			errors.append("Enemy scene entry references unknown archetype '%s'." % entry.archetype_id)
	return errors
