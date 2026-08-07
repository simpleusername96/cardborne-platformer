extends SceneTree

## Regression contract for committed approach/attack-route geometry. This keeps
## the runtime path resolver and telegraph builder in lockstep without adding a
## second navigation or presentation owner.

const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const RunScene = preload("res://scenes/run/VehicleRun.tscn")
const Gateway = preload("res://scripts/vehicle/vehicle_run_capture_gateway.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run := RunScene.instantiate()
	root.add_child(run)
	await process_frame
	var gateway := Gateway.new(run)
	gateway.prepare_stage(0)
	var blocker := Rect2(run.player_position + Vector2(160.0, -48.0), Vector2(48.0, 96.0))
	run._runtime_blockers.clear()
	run._runtime_blockers.append(blocker)
	var resolve_path: Callable = run._runtime_attack_path_callable
	var resolve_charge: Callable = run._runtime_charge_path_callable
	_validate_ordinary(resolve_path, resolve_charge, run.player_position)
	_validate_boss(resolve_path, resolve_charge, run.player_position)
	_validate_live_caller_contract()
	run.queue_free()
	await process_frame
	_finish()


func _validate_ordinary(resolve_path: Callable, resolve_charge: Callable, player: Vector2) -> void:
	for role in [&"shooter", &"chaser", &"controller", &"turret", &"mine", &"artillery_spotter"]:
		var enemy := EnemyState.new()
		enemy.role = role
		enemy.phase = &"startup"
		enemy.pos = player + Vector2(620.0, 0.0)
		enemy.committed_dir = Vector2.LEFT
		enemy.committed_target = player
		enemy.phase_time = 0.0
		AttackTelegraphs.refresh_ordinary(enemy, resolve_path, resolve_charge)
		_expect(not enemy.attack_telegraphs.is_empty(), "%s produces a committed startup route" % role)
		for descriptor_variant in enemy.attack_telegraphs:
			var descriptor := Dictionary(descriptor_variant)
			_expect(StringName(descriptor.get("shape", &"")) in [&"corridor", &"area"], "%s route uses a supported footprint" % role)
			_expect(float(descriptor.get("readiness", -1.0)) >= 0.0, "%s route carries readiness" % role)
			if descriptor.get("shape", &"") == &"corridor":
				var expected_origin := enemy.pos
				var attack := AttackContract.ordinary_attack(role)
				if StringName(attack.get("kind", &"")) == &"projectile":
					expected_origin += enemy.committed_dir * float(attack.get("origin_offset", 0.0))
				_expect(Vector2(descriptor["from"]) == expected_origin, "%s route origin remains committed" % role)
				_expect(float(descriptor["half_width"]) > 0.0, "%s route exposes a nonzero danger half-width" % role)


func _validate_boss(resolve_path: Callable, resolve_charge: Callable, player: Vector2) -> void:
	var examples := {
		&"projectile": &"foundry_burst",
		&"charge": &"foundry_ram",
		&"beam": &"switch_sweep",
		&"area": &"furnace_ring",
	}
	for delivery_variant in examples:
		var delivery := StringName(delivery_variant)
		var pattern := String(examples[delivery_variant])
		var enemy := EnemyState.new()
		enemy.role = &"stage_boss"
		enemy.phase = &"boss_startup"
		enemy.pos = player + Vector2(720.0, 0.0)
		enemy.committed_dir = Vector2.LEFT
		enemy.committed_target = player
		enemy.phase_time = 0.0
		AttackTelegraphs.refresh_boss(enemy, pattern, resolve_path, resolve_charge)
		var matches := enemy.attack_telegraphs.filter(
			func(value):
				var record := Dictionary(value)
				return StringName(record.get("delivery", &"")) == delivery
		)
		_expect(not matches.is_empty(), "boss %s example produces a matching route" % delivery)
		for descriptor_variant in matches:
			var descriptor := Dictionary(descriptor_variant)
			_expect(float(descriptor.get("damage", 0.0)) >= 0.0, "boss %s route retains authored damage" % delivery)
			if delivery == &"area":
				_expect(Vector2(descriptor["center"]) == enemy.committed_target, "boss area center stays committed")
				_expect(is_equal_approx(float(descriptor["radius"]), BossPatterns.radius(pattern)), "boss area radius matches pattern")
			elif delivery in [&"projectile", &"beam", &"charge"]:
				_expect(Vector2(descriptor["from"]).distance_to(enemy.pos) <= 90.0, "boss %s origin stays within the committed muzzle envelope" % delivery)
				_expect(Vector2(descriptor["to"]) != Vector2(descriptor["from"]), "boss %s endpoint remains visible" % delivery)
	_validate_offscreen_intersection()


func _validate_offscreen_intersection() -> void:
	var visible := Rect2(0.0, 0.0, 1280.0, 720.0)
	var projectile := {
		"shape":&"corridor",
		"delivery":&"projectile",
		"from":Vector2(-180.0, 360.0),
		"to":Vector2(160.0, 360.0),
		"half_width":28.0,
		"damage":12.0,
		"readiness":0.5,
	}
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(-180.0, 360.0), 26.0, &"startup", projectile, visible
		) == CombatCuePolicy.MODE_NONE,
		"off-screen projectile startup does not expose a predicted path"
	)
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(300.0, 360.0), 26.0, &"startup", projectile, visible
		) == CombatCuePolicy.MODE_NONE,
		"visible projectile source relies on its muzzle and projectile body"
	)
	var charge := projectile.duplicate()
	charge["delivery"] = &"charge"
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(300.0, 360.0), 26.0, &"startup", charge, visible
		) == CombatCuePolicy.MODE_NONE,
		"ordinary charge startup does not expose a movement route"
	)
	var ordinary_area := {
		"shape":&"area", "delivery":&"area",
		"center":Vector2(640.0, 360.0), "radius":180.0,
		"damage":14.0,
	}
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(300.0, 360.0), 26.0, &"startup", ordinary_area, visible
		) == CombatCuePolicy.MODE_NONE
			and CombatCuePolicy.telegraph_mode(
				Vector2(300.0, 360.0), 112.0, &"boss_startup", ordinary_area, visible
			) == CombatCuePolicy.MODE_AREA_FOOTPRINT,
		"only boss startup exposes a circular bombardment footprint"
	)
	var unseen_descriptors: Array[Dictionary] = [projectile]
	_expect(
		is_equal_approx(
			CombatCuePolicy.unseen_projectile_attack_readiness(
				Vector2(-180.0, 360.0),
				26.0,
				&"startup",
				unseen_descriptors,
				visible
			),
			0.5
		),
		"radar owns the off-screen projectile warning without a world route"
	)
	var renderer_source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_combat_renderer.gd"
	)
	_expect(
		renderer_source.contains("_sync_active_beam"),
		"active beams retain a damaging-interval presentation"
	)
	_expect(
		renderer_source.contains("_sync_area_telegraph"),
		"active boss areas retain a damaging-interval presentation"
	)
	_expect(
		not renderer_source.contains("_sync_projectile_telegraph")
			and not renderer_source.contains("_sync_incoming_projectile_cue")
			and not renderer_source.contains("_sync_collective_tactic_module")
			and not renderer_source.contains("_sync_commit_marker")
			and not renderer_source.contains("_sync_support_telegraph")
			and not renderer_source.contains("_sync_charge_telegraph")
			and not renderer_source.contains("_sync_corridor_telegraph"),
		"decorative routes, commit markers, and support warnings stay retired"
	)


func _validate_live_caller_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	for token in [
		"AttackTelegraphs.refresh_ordinary",
		"AttackTelegraphs.refresh_boss",
		"_runtime_attack_path_callable",
		"_runtime_charge_path_callable",
		"_runtime_first_cover_hit",
	]:
		_expect(source.contains(token), "VehicleRun caller retains live route ownership: %s" % token)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ATTACK_ROUTE_READABILITY_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
