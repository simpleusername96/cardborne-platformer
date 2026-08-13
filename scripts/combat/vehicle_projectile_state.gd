class_name VehicleProjectileState
extends RefCounted

## Reusable hot-path projectile state. Every field is initialized on acquire so
## pooled objects never carry behavior from a previous shot.

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")

var pos := Vector2.ZERO
var spawn_origin := Vector2.ZERO
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
var reflected := false
var final_damage := false
var wall_piercing := false
var affinity: StringName = AttackContract.KINETIC
var threat_tier: StringName = AttackContract.THREAT_ORDINARY
var condition_mask := 0
var primary_payload: VehiclePrimaryPayloadProfile
var team: StringName = &""
var spawn_serial := 0
var combat_action_family: StringName = &""
var combat_action_serial := 0
var uses_boss_reserve := false
# Stable storage identity is assigned by VehicleProjectileStore. It survives
# swap retirement and changes generation whenever this pooled state is reused.
var storage_slot := -1
var storage_generation := 0


func configure(
	spec: Dictionary,
	team_value: StringName,
	serial: int,
	boss_reserve: bool = false
) -> void:
	pos = Vector2(spec.get("pos", Vector2.ZERO))
	spawn_origin = Vector2(spec.get("spawn_origin", pos))
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
	reflected = bool(spec.get("reflected", false))
	final_damage = bool(spec.get("final_damage", false))
	wall_piercing = bool(spec.get("wall_piercing", false))
	affinity = AttackContract.normalize_affinity(StringName(spec.get("affinity", AttackContract.KINETIC)))
	threat_tier = AttackContract.normalize_threat_tier(
		StringName(spec.get("threat_tier", AttackContract.THREAT_ORDINARY))
	)
	condition_mask = int(spec.get("condition_mask", 0)) & AttackContract.CONDITION_MASK
	primary_payload = spec.get("primary_payload") as VehiclePrimaryPayloadProfile
	team = team_value
	spawn_serial = serial
	combat_action_family = StringName(spec.get("combat_action_family", &""))
	combat_action_serial = int(spec.get("combat_action_serial", 0))
	uses_boss_reserve = boss_reserve
