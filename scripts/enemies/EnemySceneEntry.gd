class_name EnemySceneEntry
extends Resource

@export var archetype_id: StringName
@export var scene: PackedScene


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy scene archetype ID", archetype_id)
	if scene == null:
		errors.append("Enemy scene entry '%s' needs a scene." % archetype_id)
	return errors
