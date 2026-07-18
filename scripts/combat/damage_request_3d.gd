class_name DamageRequest3D
extends RefCounted

enum Team { PLAYER, ENEMY, ENVIRONMENT }

var damage: int
var stagger: int
var team: Team
var source_id: StringName
var blockable: bool


func _init(
	requested_damage: int,
	requested_stagger: int,
	requested_team: Team,
	requested_source_id: StringName,
	is_blockable: bool = true,
) -> void:
	damage = maxi(0, requested_damage)
	stagger = maxi(0, requested_stagger)
	team = requested_team
	source_id = requested_source_id
	blockable = is_blockable
