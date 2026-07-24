class_name VehicleProjectileState
extends RefCounted

## Reusable hot-path projectile state. Every field is initialized on acquire so
## pooled objects never carry behavior from a previous shot.

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

var pos := Vector2.ZERO
var velocity := Vector2.ZERO
var radius := 5.0
var damage := 0.0
var structure_damage := 0.0
var life := 0.0
var color := Color.WHITE
var owner := ""
var pierce := 0
var bounces := 0
var homing := false
var target_id := ""
var explosive := false
var stagger := 0.0
var breach_token_available := false
var breach_visual := false
var unprimed_structure_damage := 0.0
var reflected := false
var final_damage := false
var wall_piercing := false
var affinity: StringName = AttackContract.KINETIC
var condition_mask := 0
var status_profile: VehicleStatusProfile
var team: StringName = &""
var spawn_serial := 0
var uses_boss_reserve := false


func configure(
	spec: Dictionary,
	team_value: StringName,
	serial: int,
	boss_reserve: bool = false
) -> void:
	pos = Vector2(spec.get("pos", Vector2.ZERO))
	velocity = Vector2(spec.get("velocity", Vector2.ZERO))
	radius = float(spec.get("radius", 5.0))
	damage = float(spec.get("damage", 0.0))
	structure_damage = float(spec.get("structure_damage", damage))
	life = float(spec.get("life", 0.0))
	color = Color(spec.get("color", Color.WHITE))
	owner = String(spec.get("owner", ""))
	pierce = int(spec.get("pierce", 0))
	bounces = int(spec.get("bounces", 0))
	homing = bool(spec.get("homing", false))
	target_id = String(spec.get("target_id", ""))
	explosive = bool(spec.get("explosive", false))
	stagger = float(spec.get("stagger", 0.0))
	breach_token_available = bool(spec.get("breach_token_available", false))
	breach_visual = bool(spec.get("breach_visual", breach_token_available))
	unprimed_structure_damage = float(spec.get("unprimed_structure_damage", structure_damage))
	reflected = bool(spec.get("reflected", false))
	final_damage = bool(spec.get("final_damage", false))
	wall_piercing = bool(spec.get("wall_piercing", false))
	affinity = AttackContract.normalize_affinity(StringName(spec.get("affinity", AttackContract.KINETIC)))
	condition_mask = int(spec.get("condition_mask", 0)) & AttackContract.CONDITION_MASK
	status_profile = spec.get("status_profile") as VehicleStatusProfile
	team = team_value
	spawn_serial = serial
	uses_boss_reserve = boss_reserve
