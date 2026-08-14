extends SceneTree

const ContactRuntime = preload(
	"res://scripts/enemies/vehicle_enemy_contact_runtime.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const EnemyStore = preload("res://scripts/enemies/vehicle_enemy_store.gd")
const Rules = preload("res://scripts/vehicle/vehicle_stage_rules.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"

var failures: Array[String] = []
var _probe_accept := true
var _probe_calls := 0
var _probe_last_source := ""
var _probe_last_amount := 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_relative_sweep()
	_validate_role_and_repeat_contracts()
	_validate_pool_reuse_and_fixed_worklist()
	await _validate_run_damage_receipts_and_integration()
	_finish()


func _validate_relative_sweep() -> void:
	_expect(
		ContactRuntime.relative_sweep_hits(
			Vector2(-100.0, 0.0),
			Vector2.ZERO,
			Vector2(100.0, 0.0),
			Vector2(40.0, 0.0),
			40.0
		),
		"relative sweep accepts endpoint contact"
	)
	_expect(
		ContactRuntime.relative_sweep_hits(
			Vector2(-100.0, 0.0),
			Vector2(100.0, 0.0),
			Vector2(100.0, 0.0),
			Vector2(-100.0, 0.0),
			40.0
		),
		"relative sweep catches two bodies that cross between separated endpoints"
	)
	_expect(
		not ContactRuntime.relative_sweep_hits(
			Vector2(-100.0, 40.1),
			Vector2(100.0, 40.1),
			Vector2.ZERO,
			Vector2.ZERO,
			40.0
		),
		"relative sweep rejects a path 0.1 pixels outside the combined radius"
	)
	_expect(
		ContactRuntime.relative_sweep_hits(
			Vector2(-100.0, 40.0),
			Vector2(100.0, 40.0),
			Vector2.ZERO,
			Vector2.ZERO,
			40.0
		),
		"relative sweep accepts exact tangent contact"
	)


func _validate_role_and_repeat_contracts() -> void:
	var runtime := _configured_runtime()
	var active: Array[EnemyState] = []
	var chaser := _enemy(&"chaser", Vector2(120.0, 0.0), Vector2(-120.0, 0.0))
	chaser.contact_attack = ContactRuntime.ATTACK_CHASER
	active.append(chaser)
	_probe_accept = false
	_reset_probe()
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 1.0 / 60.0)
	_expect(
		_probe_calls == 1 and chaser.hit_committed,
		"Chaser contact is consumed once even when protection rejects damage"
	)
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 1.0 / 60.0)
	_expect(_probe_calls == 1, "consumed Chaser lunge cannot hit twice")

	var rammer := _enemy(&"rammer", Vector2(160.0, 0.0), Vector2(-160.0, 0.0))
	rammer.contact_attack = ContactRuntime.ATTACK_RAMMER
	active.assign([rammer])
	_probe_accept = true
	_reset_probe()
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 1.0 / 60.0)
	_expect(
		_probe_calls == 1
			and rammer.hit_committed
			and _probe_last_source == "Rammer charge",
		"Rammer charge uses the one-shot swept contact owner"
	)

	var collective := _enemy(&"chaser", Vector2(150.0, 0.0), Vector2(-150.0, 0.0))
	collective.contact_attack = ContactRuntime.ATTACK_COLLECTIVE
	active.assign([collective])
	_reset_probe()
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 1.0 / 60.0)
	_expect(
		_probe_calls == 1
			and collective.hit_committed
			and _probe_last_source == "Collective charge",
		"collective execute charge/fuse contact is committed once"
	)

	var guard := _enemy(&"bulkhead_guard", Vector2.ZERO, Vector2.ZERO)
	active.assign([guard])
	_probe_accept = false
	_reset_probe()
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.1)
	_expect(
		_probe_calls == 1 and is_zero_approx(guard.contact_cooldown),
		"guard persistent contact rejection stays armed"
	)
	_probe_accept = true
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.1)
	_expect(
		_probe_calls == 2
			and is_equal_approx(_probe_last_amount, 12.0)
			and is_equal_approx(guard.contact_cooldown, ContactRuntime.PERSISTENT_CONTACT_COOLDOWN),
		"guard persistent contact preserves twelve damage and its cooldown"
	)
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.79)
	_expect(_probe_calls == 2, "guard persistent contact cannot repeat inside cooldown")
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.02)
	_expect(_probe_calls == 3, "guard persistent contact retries after its cooldown expires")

	var shooter := _enemy(&"shooter", Vector2.ZERO, Vector2.ZERO)
	var controller := _enemy(&"controller", Vector2.ZERO, Vector2.ZERO)
	var artillery := _enemy(&"artillery_spotter", Vector2.ZERO, Vector2.ZERO)
	active.assign([shooter, controller, artillery])
	_probe_accept = false
	_reset_probe()
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.1)
	_expect(
		_probe_calls == 3
			and is_zero_approx(shooter.contact_cooldown)
			and is_zero_approx(controller.contact_cooldown)
			and is_zero_approx(artillery.contact_cooldown),
		"mobile ranged protection rejection leaves every hull contact armed"
	)
	_probe_accept = true
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.1)
	_expect(
		_probe_calls == 6
			and is_equal_approx(_probe_last_amount, 6.0)
			and is_equal_approx(shooter.contact_cooldown, ContactRuntime.MOBILE_RANGED_CONTACT_COOLDOWN)
			and is_equal_approx(controller.contact_cooldown, ContactRuntime.MOBILE_RANGED_CONTACT_COOLDOWN)
			and is_equal_approx(artillery.contact_cooldown, ContactRuntime.MOBILE_RANGED_CONTACT_COOLDOWN),
		"accepted mobile ranged hull contact deals six damage and starts the per-enemy cooldown"
	)
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.99)
	_expect(_probe_calls == 6, "mobile ranged persistent contact cannot repeat inside cooldown")
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 0.02)
	_expect(
		_probe_calls == 9,
		"continued mobile ranged overlap retries when accepted-contact cooldown expires"
	)

	var ordinary_chaser := _enemy(&"chaser", Vector2.ZERO, Vector2.ZERO)
	var ordinary_rammer := _enemy(&"rammer", Vector2.ZERO, Vector2.ZERO)
	var mine := _enemy(&"mine", Vector2.ZERO, Vector2.ZERO)
	var support := _enemy(&"repair_tender", Vector2.ZERO, Vector2.ZERO)
	var fixed := _enemy(&"turret", Vector2.ZERO, Vector2.ZERO)
	active.assign([ordinary_chaser, ordinary_rammer, mine, support, fixed])
	_reset_probe()
	runtime.advance(active, Vector2.ZERO, Vector2.ZERO, 1.0)
	_expect(
		_probe_calls == 0,
		"unwarned pursuit, fixed, support, and mine body overlap never deals contact damage"
	)


func _validate_pool_reuse_and_fixed_worklist() -> void:
	var store := EnemyStore.new()
	var pooled: EnemyState = store.acquire()
	pooled.id = "contact_pool_probe"
	pooled.alive = true
	pooled.active = true
	pooled.pos = Vector2(12.0, 8.0)
	pooled.contact_previous_position = Vector2(99.0, 99.0)
	pooled.contact_cooldown = 0.6
	pooled.contact_attack = ContactRuntime.ATTACK_RAMMER
	_expect(store.add(pooled), "contact pool probe enters the live store")
	pooled.alive = false
	store.queue_defeat(pooled)
	store.flush_defeated()
	var reused: EnemyState = store.acquire()
	_expect(
		reused == pooled
			and reused.contact_previous_position == pooled.pos
			and is_zero_approx(reused.contact_cooldown)
			and reused.contact_attack.is_empty(),
		"pooled enemy reuse clears every contact-resolution field"
	)

	var runtime := _configured_runtime()
	var fixed: Array[EnemyState] = []
	for index in 32:
		fixed.append(_enemy(&"shooter", Vector2(float(index), 80.0), Vector2(float(index), 80.0)))
	var first_identity := fixed[0]
	for tick in 240:
		runtime.advance(fixed, Vector2.ZERO, Vector2.ZERO, 1.0 / 60.0)
	var snapshot := runtime.debug_snapshot()
	_expect(
		fixed.size() == 32
			and fixed[0] == first_identity
			and int(snapshot["scanned"]) == 32
			and int(snapshot["fixed_capacity"]) == EnemyStore.MAX_LIVE_HOSTILES,
		"controlled diagnostic reuses one bounded worklist without container growth"
	)


func _validate_run_damage_receipts_and_integration() -> void:
	var packed := load(MAIN_SCENE) as PackedScene
	_expect(packed != null, "main scene loads for contact integration")
	if packed == null:
		return
	var root := packed.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var run = root.get_node_or_null("VehicleRun")
	_expect(run != null, "VehicleRun is active for contact integration")
	if run == null:
		root.queue_free()
		await process_frame
		return

	run.call("_reset_run", false)
	var inactive_health: float = run.player_health
	_expect(
		not bool(run.call("_damage_player", 8.0, "inactive", false, false))
			and is_equal_approx(run.player_health, inactive_health),
		"inactive simulation rejects player damage"
	)
	run.capture_set_mode(&"playing")
	run.stage_complete = true
	_expect(
		not bool(run.call("_damage_player", 8.0, "complete", false, false)),
		"completed stage rejects player damage"
	)
	run.stage_complete = false
	run.player_invulnerable = 1.0
	_expect(
		not bool(run.call("_damage_player", 8.0, "protected", false, false)),
		"hit protection rejects player damage"
	)
	run.player_invulnerable = 0.0
	_expect(
		not bool(run.call("_damage_player", 0.0, "zero", false, false)),
		"zero effective damage returns a rejected receipt"
	)

	run.player_health = 120.0
	run.player_barrier_strength = 10.0
	run.player_barrier_timer = 2.0
	_expect(
		bool(run.call("_damage_player", 8.0, "barrier", true, false))
			and is_equal_approx(run.player_health, 120.0)
			and is_equal_approx(run.player_barrier_strength, 2.0),
		"full barrier absorption returns an accepted receipt without hull damage"
	)
	run.player_invulnerable = 0.0
	run.player_health = 120.0
	run.player_barrier_strength = 5.0
	run.player_barrier_timer = 2.0
	_expect(
		bool(run.call("_damage_player", 8.0, "partial barrier", true, false))
			and is_equal_approx(run.player_health, 117.0)
			and is_zero_approx(run.player_barrier_strength),
		"partial barrier plus hull damage returns an accepted receipt"
	)
	run.player_invulnerable = 0.0
	run.player_health = 120.0
	run.player_barrier_strength = 0.0
	run.player_barrier_timer = 0.0
	_expect(
		bool(run.call("_damage_player", 8.0, "hull", false, false))
			and is_equal_approx(run.player_health, 112.0),
		"positive hull damage returns an accepted receipt"
	)

	# A Chaser finishes outside the player body after crossing it. The integrated
	# relative sweep must still accept exactly one hit before projectile damage.
	run.call("_reset_run", false)
	run.capture_set_mode(&"playing")
	run.call("_clear_enemies")
	var player_center: Vector2 = run.player_position
	var chaser: EnemyState = run.call("_make_enemy", {
		"id": "contact_integration_chaser",
		"role": &"chaser",
		"pos": player_center + Vector2(140.0, 0.0),
		"active": true,
	})
	chaser.phase = &"active"
	chaser.phase_time = 0.1
	chaser.committed_dir = Vector2.LEFT
	chaser.hit_committed = false
	_expect(run.call("_append_enemy", chaser), "integration Chaser enters runtime")
	var health_before: float = run.player_health
	run.call("_update_enemies", 0.32, player_center)
	var combined_radius := (
		Rules.PLAYER_RADIUS
		+ chaser.radius
		+ float(AttackContract.ORDINARY_ATTACKS[&"chaser"]["contact_padding"])
	)
	_expect(
		chaser.pos.distance_to(player_center) > combined_radius
			and chaser.hit_committed
			and run.player_health < health_before
			and run.player_hit_flash > 0.0,
		"60 Hz integrated relative sweep catches a Chaser that tunnels past both endpoints"
	)
	var health_after: float = run.player_health
	run.player_invulnerable = 0.0
	run.call("_update_enemies", 1.0 / 60.0, player_center)
	_expect(
		is_equal_approx(run.player_health, health_after),
		"integrated Chaser recovery has no competing legacy contact owner"
	)

	run.call("_clear_enemies")
	var rammer: EnemyState = run.call("_make_enemy", {
		"id": "contact_integration_rammer",
		"role": &"rammer",
		"pos": player_center + Vector2(220.0, 0.0),
		"active": true,
	})
	rammer.phase = &"active"
	rammer.phase_time = 0.1
	rammer.committed_dir = Vector2.LEFT
	rammer.hit_committed = false
	_expect(run.call("_append_enemy", rammer), "integration Rammer enters runtime")
	run.player_invulnerable = 0.0
	run.player_hit_flash = 0.0
	health_before = run.player_health
	run.call("_update_enemies", 0.40, player_center)
	_expect(
		rammer.hit_committed
			and run.player_health < health_before
			and run.player_hit_flash > 0.0,
		"integrated Rammer sweep damages once and publishes normal hit feedback"
	)

	# A ranged body is crossed by the player. Relative sweep must apply one hull
	# contact even when both endpoints finish outside the combined radius.
	run.call("_clear_enemies")
	var shooter: EnemyState = run.call("_make_enemy", {
		"id": "contact_integration_ranged_control",
		"role": &"shooter",
		"pos": player_center,
		"active": true,
	})
	shooter.stun = 10.0
	_expect(run.call("_append_enemy", shooter), "integration ranged control enters runtime")
	run.player_invulnerable = 0.0
	run.player_position = player_center + Vector2(100.0, 0.0)
	health_before = run.player_health
	run.call(
		"_update_enemies",
		1.0 / 60.0,
		player_center - Vector2(100.0, 0.0)
	)
	_expect(
		run.player_health < health_before
			and is_equal_approx(
				shooter.contact_cooldown,
				ContactRuntime.MOBILE_RANGED_CONTACT_COOLDOWN
			),
		"crossing a ranged enemy body resolves one persistent swept hull contact"
	)
	run.player_position = player_center

	run.call("_clear_enemies")
	var guard: EnemyState = run.call("_make_enemy", {
		"id": "contact_integration_guard",
		"role": &"bulkhead_guard",
		"pos": player_center,
		"active": true,
	})
	guard.stun = 10.0
	_expect(run.call("_append_enemy", guard), "integration guard enters runtime")
	run.player_invulnerable = 1.0
	run.player_barrier_strength = 100.0
	run.player_barrier_timer = 2.0
	run.call("_update_enemies", 1.0 / 60.0, player_center)
	_expect(
		is_zero_approx(guard.contact_cooldown)
			and is_equal_approx(run.player_barrier_strength, 100.0),
		"integrated guard persistent contact stays armed after protection rejection"
	)
	run.player_invulnerable = 0.0
	run.player_barrier_hit_flash = 0.0
	health_before = run.player_health
	run.call("_update_enemies", 1.0 / 60.0, player_center)
	_expect(
		is_equal_approx(run.player_health, health_before)
			and run.player_barrier_strength < 100.0
			and run.player_barrier_hit_flash > 0.0
			and is_equal_approx(
				guard.contact_cooldown,
				ContactRuntime.PERSISTENT_CONTACT_COOLDOWN
			),
		"integrated guard persistent contact accepts the next overlap through barrier feedback"
	)

	root.queue_free()
	await process_frame


func _configured_runtime() -> VehicleEnemyContactRuntime:
	var runtime := ContactRuntime.new()
	runtime.configure(
		Callable(self, "_damage_player_probe"),
		Callable(self, "_enemy_contact_damage_probe")
	)
	return runtime


func _enemy(
	role: StringName,
	from: Vector2,
	to: Vector2
) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = "%s_probe" % role
	enemy.role = role
	enemy.alive = true
	enemy.active = true
	enemy.radius = 20.0
	enemy.contact_previous_position = from
	enemy.pos = to
	return enemy


func _damage_player_probe(
	_amount: float,
	source: String,
	_blockable: bool
) -> bool:
	_probe_calls += 1
	_probe_last_source = source
	_probe_last_amount = _amount
	return _probe_accept


func _enemy_contact_damage_probe(
	_enemy_state: EnemyState,
	base_damage: float
) -> float:
	return base_damage


func _reset_probe() -> void:
	_probe_calls = 0
	_probe_last_source = ""
	_probe_last_amount = 0.0


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_CONTACT_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
