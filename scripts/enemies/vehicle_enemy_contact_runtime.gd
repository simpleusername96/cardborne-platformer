class_name VehicleEnemyContactRuntime
extends RefCounted

## Resolves ordinary hull damage once per physics tick from relative swept
## motion. Movement code only publishes the committed attack kind; this runtime
## is the single owner that decides whether contact can damage the player.

const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const SpecialistRuntime = preload(
	"res://scripts/enemies/vehicle_enemy_specialist_runtime.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")

const ATTACK_CHASER: StringName = &"chaser"
const ATTACK_RAMMER: StringName = &"rammer"
const ATTACK_COLLECTIVE: StringName = &"collective"
const PERSISTENT_CONTACT_COOLDOWN := 0.8
const PERSISTENT_CONTACT_PADDING := 12.0
const PERSISTENT_CONTACT_DAMAGE := 12.0
const MOBILE_RANGED_CONTACT_COOLDOWN := 1.0
const MOBILE_RANGED_CONTACT_PADDING := 12.0
const MOBILE_RANGED_CONTACT_DAMAGE := 6.0
const COLLECTIVE_CONTACT_PADDING := 10.0
const COLLECTIVE_CONTACT_DAMAGE := 12.0
const PERSISTENT_ROLES: Array[StringName] = [
	&"bulkhead_guard", &"splitter_barge",
]
const MOBILE_RANGED_CONTACT_ROLES: Array[StringName] = [
	&"shooter", &"controller", &"artillery_spotter",
]

var _damage_player: Callable
var _enemy_contact_damage: Callable
var _last_scanned_count := 0
var _last_contact_attempts := 0


func configure(
	damage_player: Callable,
	enemy_contact_damage: Callable
) -> void:
	_damage_player = damage_player
	_enemy_contact_damage = enemy_contact_damage


func advance(
	active_enemies: Array[EnemyState],
	player_from: Vector2,
	player_to: Vector2,
	delta: float
) -> int:
	_last_scanned_count = active_enemies.size()
	_last_contact_attempts = 0
	for enemy in active_enemies:
		if enemy == null or not enemy.alive or not enemy.active:
			continue
		enemy.contact_cooldown = maxf(
			0.0, enemy.contact_cooldown - maxf(0.0, delta)
		)
		match enemy.contact_attack:
			ATTACK_CHASER:
				_resolve_one_shot(
					enemy,
					player_from,
					player_to,
					float(AttackContract.ORDINARY_ATTACKS[&"chaser"]["contact_padding"]),
					float(AttackContract.ORDINARY_ATTACKS[&"chaser"]["damage"]),
					"Rivet Chaser lunge"
				)
			ATTACK_RAMMER:
				_resolve_one_shot(
					enemy,
					player_from,
					player_to,
					SpecialistRuntime.RAMMER_CONTACT_PADDING,
					SpecialistRuntime.RAMMER_DAMAGE,
					"Rammer charge"
				)
			ATTACK_COLLECTIVE:
				_resolve_one_shot(
					enemy,
					player_from,
					player_to,
					COLLECTIVE_CONTACT_PADDING,
					COLLECTIVE_CONTACT_DAMAGE,
					"Collective charge"
				)
			_:
				if enemy.role in PERSISTENT_ROLES:
					_resolve_persistent(
						enemy,
						player_from,
						player_to,
						PERSISTENT_CONTACT_PADDING,
						PERSISTENT_CONTACT_DAMAGE,
						PERSISTENT_CONTACT_COOLDOWN,
						"Enemy hull impact"
					)
				elif enemy.role in MOBILE_RANGED_CONTACT_ROLES:
					_resolve_persistent(
						enemy,
						player_from,
						player_to,
						MOBILE_RANGED_CONTACT_PADDING,
						MOBILE_RANGED_CONTACT_DAMAGE,
						MOBILE_RANGED_CONTACT_COOLDOWN,
						"Mobile ranged hull impact"
					)
	return _last_contact_attempts


static func relative_sweep_hits(
	player_from: Vector2,
	player_to: Vector2,
	enemy_from: Vector2,
	enemy_to: Vector2,
	combined_radius: float
) -> bool:
	return AttackContract.segment_circle_first_t(
		player_from - enemy_from,
		player_to - enemy_to,
		Vector2.ZERO,
		combined_radius
	) != INF


func debug_snapshot() -> Dictionary:
	return {
		"scanned": _last_scanned_count,
		"attempts": _last_contact_attempts,
		"fixed_capacity": EnemyStore.MAX_LIVE_HOSTILES,
	}


func _resolve_one_shot(
	enemy: EnemyState,
	player_from: Vector2,
	player_to: Vector2,
	padding: float,
	base_damage: float,
	source: String
) -> void:
	if enemy.hit_committed or not _sweep_hits(
		enemy, player_from, player_to, padding
	):
		return
	# A warned one-shot attack is consumed on physical contact even when dash or
	# hit protection rejects its damage receipt.
	enemy.hit_committed = true
	_last_contact_attempts += 1
	_damage_player.call(
		float(_enemy_contact_damage.call(enemy, base_damage)), source, true
	)


func _resolve_persistent(
	enemy: EnemyState,
	player_from: Vector2,
	player_to: Vector2,
	padding: float,
	base_damage: float,
	cooldown: float,
	source: String
) -> void:
	if enemy.contact_cooldown > 0.0 or not _sweep_hits(
		enemy, player_from, player_to, padding
	):
		return
	_last_contact_attempts += 1
	var accepted := bool(_damage_player.call(
		float(_enemy_contact_damage.call(enemy, base_damage)),
		source,
		true
	))
	if accepted:
		enemy.contact_cooldown = cooldown


func _sweep_hits(
	enemy: EnemyState,
	player_from: Vector2,
	player_to: Vector2,
	padding: float
) -> bool:
	return relative_sweep_hits(
		player_from,
		player_to,
		enemy.contact_previous_position,
		enemy.pos,
		Rules.PLAYER_RADIUS + enemy.radius + padding
	)
