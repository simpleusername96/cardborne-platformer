class_name EnemySceneCatalog
extends Resource

@export var id: StringName
@export var content_version: int = 1
@export var entries: Array[EnemySceneEntry] = []


func get_scene(
	archetype_id: StringName,
	variant_id: StringName = StringName()
) -> PackedScene:
	var archetype_fallback: PackedScene
	for entry in entries:
		if entry == null or entry.archetype_id != archetype_id:
			continue
		if archetype_fallback == null:
			archetype_fallback = entry.scene
		if not String(variant_id).is_empty() and entry.variant_id == variant_id:
			return entry.scene
		if String(entry.variant_id).is_empty():
			archetype_fallback = entry.scene
	return archetype_fallback


func get_scene_for_variant(variant_id: StringName, enemy_catalog: EnemyCatalog) -> PackedScene:
	var variant := enemy_catalog.get_variant_by_id(variant_id) if enemy_catalog != null else null
	return get_scene(variant.archetype_id, variant.id) if variant != null else null


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
		var key := entry.identity_key()
		if seen.has(key):
			errors.append("Enemy scene catalog repeats '%s'." % key)
		seen[key] = true
		if enemy_catalog != null and not enemy_catalog.has_archetype(entry.archetype_id):
			errors.append("Enemy scene entry references unknown archetype '%s'." % entry.archetype_id)
		if enemy_catalog != null and not String(entry.variant_id).is_empty():
			var variant := enemy_catalog.get_variant_by_id(entry.variant_id)
			if variant == null:
				errors.append("Enemy scene entry references unknown variant '%s'." % entry.variant_id)
			elif variant.archetype_id != entry.archetype_id:
				errors.append(
					"Enemy scene variant '%s' does not belong to archetype '%s'."
					% [entry.variant_id, entry.archetype_id]
				)
	return errors
