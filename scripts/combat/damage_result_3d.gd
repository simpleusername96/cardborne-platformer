class_name DamageResult3D
extends RefCounted

var accepted := false
var damage_applied := 0
var stagger_applied := 0
var defeated := false


static func rejected() -> DamageResult3D:
	return DamageResult3D.new()


static func applied(damage: int, stagger: int, is_defeated: bool) -> DamageResult3D:
	var result := DamageResult3D.new()
	result.accepted = true
	result.damage_applied = damage
	result.stagger_applied = stagger
	result.defeated = is_defeated
	return result
