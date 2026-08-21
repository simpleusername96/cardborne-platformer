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
	for role in [
		&"ordinary_lane_01", &"ordinary_edge_01", &"ordinary_gap_01", &"ordinary_fixed_ranged_01", &"ordinary_fixed_area_01",
		&"ordinary_growth_01", &"ordinary_fixed_beam_01",
	]:
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
			_expect(StringName(descriptor.get("shape", &"")) in [&"source", &"corridor", &"area"], "%s route uses a supported footprint" % role)
			_expect(float(descriptor.get("readiness", -1.0)) >= 0.0, "%s route carries readiness" % role)
			if descriptor.get("delivery", &"") == &"projectile":
				var expected_origin := enemy.pos
				var attack := AttackContract.ordinary_attack(role)
				expected_origin += enemy.committed_dir * float(attack.get("origin_offset", 0.0))
				_expect(StringName(descriptor["shape"]) == &"source", "%s projectile warning is source-only" % role)
				_expect(Vector2(descriptor["origin"]) == expected_origin, "%s projectile source remains committed" % role)
				_expect(Vector2(descriptor["direction"]).is_equal_approx(enemy.committed_dir), "%s projectile source keeps its committed direction" % role)
				_expect(not descriptor.has("from") and not descriptor.has("to") and not descriptor.has("half_width"), "%s projectile warning contains no future path geometry" % role)
			elif descriptor.get("shape", &"") == &"corridor":
				_expect(Vector2(descriptor["from"]) == enemy.pos, "%s route origin remains committed" % role)
				_expect(float(descriptor["half_width"]) > 0.0, "%s route exposes a nonzero danger half-width" % role)
				if role == &"ordinary_fixed_beam_01":
					_expect(
						is_equal_approx(
							float(descriptor["beam_growth_seconds"]),
							AttackContract.EMITTED_BEAM_GROWTH_SECONDS
						),
						"Fixed Beam Ordinary Enemy Lv.1 publishes collision-owned emitted-beam growth timing"
					)


func _validate_boss(resolve_path: Callable, resolve_charge: Callable, player: Vector2) -> void:
	var examples := {
		&"projectile": &"heated_fan",
		&"charge": &"direct_charge",
		&"beam": &"switch_sweep",
		&"area": &"thermal_ring",
	}
	for delivery_variant in examples:
		var delivery := StringName(delivery_variant)
		var pattern := String(examples[delivery_variant])
		var enemy := EnemyState.new()
		enemy.role = &"boss"
		enemy.phase = &"boss_startup"
		# Keep the fixture inside the shared field's walkable center so route
		# resolution tests the authored blocker instead of the outer boundary.
		enemy.pos = player + Vector2(360.0, 0.0)
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
			elif delivery == &"projectile":
				_expect(StringName(descriptor["shape"]) == &"source", "boss projectile warning is source-only")
				_expect(Vector2(descriptor["origin"]).distance_to(enemy.pos) <= 90.0, "boss projectile origin stays within the committed muzzle envelope")
				_expect(Vector2(descriptor["direction"]).is_normalized(), "boss projectile source keeps a normalized committed direction")
				_expect(not descriptor.has("from") and not descriptor.has("to") and not descriptor.has("half_width"), "boss projectile warning contains no future path geometry")
			elif delivery in [&"beam", &"charge"]:
				var committed_origin := Vector2(
					descriptor.get("beam_emitter", descriptor["from"])
				)
				_expect(committed_origin.distance_to(enemy.pos) <= 90.0, "boss %s origin stays within the committed muzzle envelope" % delivery)
				_expect(Vector2(descriptor["to"]) != Vector2(descriptor["from"]), "boss %s endpoint remains visible" % delivery)
				if delivery == &"beam":
					_expect(
						is_equal_approx(
							float(descriptor["beam_growth_seconds"]),
							AttackContract.EMITTED_BEAM_GROWTH_SECONDS
						),
						"boss forward-emitted beam publishes its 0.30-second growth contract"
					)
					_expect(
						StringName(descriptor.get("beam_topology", &""))
							in AttackContract.HOSTILE_BEAM_TOPOLOGIES,
						"boss beam declares one of the three collision-owned topologies"
					)
	_validate_beam_topology_cycle(resolve_path, resolve_charge, player)
	_validate_offscreen_intersection()


func _validate_beam_topology_cycle(
	resolve_path: Callable, resolve_charge: Callable, player: Vector2
) -> void:
	for cycle_index in AttackContract.HOSTILE_BEAM_TOPOLOGIES.size():
		var enemy := EnemyState.new()
		enemy.role = &"boss"
		enemy.phase = &"boss_startup"
		enemy.pos = player + Vector2(360.0, 0.0)
		enemy.committed_dir = Vector2.LEFT
		enemy.committed_target = player
		enemy.pattern_index = cycle_index + 1
		AttackTelegraphs.refresh_boss(
			enemy, "switch_sweep", resolve_path, resolve_charge
		)
		var expected := AttackContract.HOSTILE_BEAM_TOPOLOGIES[cycle_index]
		var beams := enemy.attack_telegraphs.filter(
			func(value):
				return StringName(Dictionary(value).get("delivery", &"")) == &"beam"
		)
		_expect(beams.size() == 2, "%s beam topology owns exactly two collision branches" % expected)
		for descriptor_variant in beams:
			var descriptor := Dictionary(descriptor_variant)
			_expect(
				StringName(descriptor.get("beam_topology", &"")) == expected,
				"hostile beam cycle preserves the authored II -> X -> plus order"
			)
			_expect(
				is_equal_approx(
					float(descriptor.get("beam_growth_seconds", 0.0)),
					AttackContract.EMITTED_BEAM_GROWTH_SECONDS
				),
				"%s beam grows its collision length over 0.30 seconds" % expected
			)
			var expected_mode := (
				AttackContract.EMITTED_BEAM_FORWARD
				if expected == AttackContract.BEAM_TOPOLOGY_PARALLEL
				else AttackContract.EMITTED_BEAM_BIDIRECTIONAL
			)
			_expect(
				StringName(descriptor.get("beam_emission_mode", &"")) == expected_mode,
				"%s beam publishes the matching collision emission mode" % expected
			)


func _validate_offscreen_intersection() -> void:
	var visible := Rect2(0.0, 0.0, 1280.0, 720.0)
	var projectile := {
		"shape":&"source",
		"delivery":&"projectile",
		"origin":Vector2(-180.0, 360.0),
		"direction":Vector2.RIGHT,
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
	var charge := {
		"shape":&"corridor", "delivery":&"charge",
		"from":Vector2(300.0, 360.0), "to":Vector2(620.0, 360.0),
		"half_width":28.0, "damage":12.0, "readiness":0.5,
	}
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(300.0, 360.0), 26.0, &"startup", charge, visible
		) == CombatCuePolicy.MODE_NONE,
		"ordinary charge startup does not expose a movement route"
	)
	var beam := charge.duplicate()
	beam["delivery"] = &"beam"
	beam["active_width"] = 54.0
	beam["affinity"] = AttackContract.ARC
	beam["beam_growth_seconds"] = AttackContract.EMITTED_BEAM_GROWTH_SECONDS
	beam["active_seconds"] = 0.60
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(-180.0, 360.0), 50.0, &"startup", beam, visible
		) == CombatCuePolicy.MODE_NONE,
		"off-screen emitted-beam startup draws no world path or off-screen orb"
	)
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(300.0, 360.0), 50.0, &"startup", beam, visible
		) == CombatCuePolicy.MODE_BEAM_STARTUP,
		"visible Fixed Beam Ordinary Enemy Lv.1 startup selects its source-attached orb mode"
	)
	var unseen_beam_descriptors: Array[Dictionary] = [beam]
	_expect(
		is_equal_approx(
			CombatCuePolicy.unseen_committed_attack_readiness(
				Vector2(-180.0, 360.0),
				50.0,
				&"startup",
				unseen_beam_descriptors,
				visible
			),
			0.5
		),
		"off-screen beam charging uses direction-only threat radar instead of a world path"
	)
	var ordinary_area := {
		"shape":&"area", "delivery":&"area",
		"center":Vector2(640.0, 360.0), "radius":180.0,
		"damage":14.0,
	}
	_expect(
		CombatCuePolicy.telegraph_mode(
			Vector2(300.0, 360.0), 26.0, &"startup", ordinary_area, visible
		) == CombatCuePolicy.MODE_AREA_FOOTPRINT
			and CombatCuePolicy.telegraph_mode(
				Vector2(300.0, 360.0), 112.0, &"boss_startup", ordinary_area, visible
			) == CombatCuePolicy.MODE_AREA_FOOTPRINT
			and CombatCuePolicy.telegraph_mode(
				Vector2(300.0, 360.0), 112.0, &"boss_active", ordinary_area, visible
			) == CombatCuePolicy.MODE_AREA_FOOTPRINT,
		"area attacks expose the exact impact footprint throughout warning and active phases"
	)
	var unseen_descriptors: Array[Dictionary] = [projectile]
	_expect(
		is_equal_approx(
			CombatCuePolicy.unseen_committed_attack_readiness(
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
	_expect(
		CombatCuePolicy.nearby_enemy_is_eligible(
			Vector2(-180.0, 360.0), 26.0, Vector2(640.0, 360.0), visible, 1200.0
		)
			and not CombatCuePolicy.nearby_enemy_is_eligible(
				Vector2(300.0, 360.0), 26.0, Vector2(640.0, 360.0), visible, 1200.0
			)
			and not CombatCuePolicy.nearby_enemy_is_eligible(
				Vector2(-800.0, 360.0), 26.0, Vector2(640.0, 360.0), visible, 1200.0
			),
		"nearby radar accepts only off-screen enemy bodies within 1,200 world units"
	)
	_expect(
		CombatCuePolicy.contact_priority(CombatCuePolicy.CONTACT_INCOMING_ATTACK) == 3
			and CombatCuePolicy.contact_priority(CombatCuePolicy.CONTACT_BOSS_ARRIVAL) == 2
			and CombatCuePolicy.contact_priority(CombatCuePolicy.CONTACT_NEARBY_ENEMY) == 1
			and not CombatCuePolicy.contact_uses_triangle(
				CombatCuePolicy.CONTACT_NEARBY_ENEMY
			),
		"radar contact priority and nearby no-triangle semantics remain centralized"
	)
	var renderer_source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_combat_renderer.gd"
	)
	_expect(
		renderer_source.contains("_sync_beam_startup")
			and renderer_source.contains("_sync_active_beam"),
		"beams retain distinct charge and damaging-interval presentations"
	)
	_expect(
		renderer_source.contains("_sync_area_telegraph")
			and renderer_source.get_slice("func _sync_area_telegraph", 1)
				.get_slice("func _sync_experience", 0)
				.contains("_write_disk(center, radius")
			and renderer_source.get_slice("func _sync_area_telegraph", 1)
				.get_slice("func _sync_experience", 0)
				.contains("_write_danger_ring(center, radius"),
		"active boss areas retain one exact full body and one boundary"
	)
	_expect(
		not renderer_source.contains("EMP_RELEASE_EXPAND_SECONDS")
			and not renderer_source.contains("EMP_RELEASE_INITIAL_SCALE")
			and not renderer_source.contains("impact_radius")
			and not renderer_source.contains("detonation_radius")
			and not renderer_source.contains("pulse_radius"),
		"instant area effects contain no renderer-owned radius interpolation"
	)
	_expect(
		not renderer_source.contains("_sync_projectile_path_telegraph")
			and not renderer_source.contains("_sync_projectile_telegraph")
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
