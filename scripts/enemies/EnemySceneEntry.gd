class_name EnemySceneEntry
extends Resource

@export var archetype_id: StringName
@export var variant_id: StringName
@export var scene: PackedScene


func validate_definition() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy scene archetype ID", archetype_id)
	if not String(variant_id).is_empty():
		ContentId.validate(errors, "Enemy scene variant ID", variant_id)
	if scene == null:
		errors.append("Enemy scene entry '%s' needs a scene." % identity_key())
	return errors


func identity_key() -> String:
	return "%s:%s" % [archetype_id, variant_id]
