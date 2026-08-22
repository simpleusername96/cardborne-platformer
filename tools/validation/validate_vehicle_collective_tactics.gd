extends SceneTree

const Catalog = preload(
	"res://scripts/encounters/vehicle_collective_tactic_catalog.gd"
)
const Runtime = preload(
	"res://scripts/encounters/vehicle_collective_tactic_runtime.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const CombatStages = preload(
	"res://scripts/vehicle/stages/vehicle_combat_stages.gd"
)
const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const EnemyArchetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")

var _failures: Array[String] = []
var _lookup: Dictionary = {}


func _initialize() -> void:
	_validate_catalog_and_stage_rollout()
	_validate_role_signatures()
	_validate_runtime_visibility_arming()
	_validate_runtime_permissions()
	_validate_pack_trait_runtime()
	_validate_source_boundaries()
	_finish()


func _validate_catalog_and_stage_rollout() -> void:
	_expect(
		Catalog.validate_contract().is_empty(),
		"collective tactic catalog is complete"
	)
	for stage_index in CombatStages.STAGE_IDS.size():
		var stage_id := CombatStages.STAGE_IDS[stage_index]
		var definition := CombatStages.definition(stage_id)
		var packets: Array = definition["packets"]
		var unit_count := 0
		var tactic_packets := 0
		var expected_tactic_packets := 0
		var beat_kinds := {}
		var tactic_ids := {}
		for packet_variant in packets:
			var packet := Dictionary(packet_variant)
			if (
				(stage_index == 0 and String(packet.get("id", "")).begins_with("stage_1_packet_"))
				or (stage_index > 0 and packet != packets[0])
			):
				expected_tactic_packets += 1
			var squads: Array = packet["squads"]
			for squad in squads:
				unit_count += Array(squad).size()
			var tactic := Dictionary(packet.get("collective_tactic", {}))
			if tactic.is_empty():
				continue
			tactic_packets += 1
			var squad_index := int(tactic.get("squad_index", -1))
			_expect(
				squad_index >= 0 and squad_index < squads.size(),
				"%s tactic tags exactly one valid squad" % stage_id
			)
			var tactic_id := StringName(tactic.get("id", &""))
			_expect(
				not Catalog.recipe(tactic_id).is_empty(),
				"%s packet references a known tactic" % stage_id
			)
			tactic_ids[tactic_id] = true
			beat_kinds[StringName(tactic.get("beat_kind", &""))] = true
			var expected_arrival_windows := 12 if stage_index == 0 else 3
			var expected_squads_per_window := 1 if stage_index == 0 else 4
			_expect(
				int(packet.get("arrival_windows", 0)) == expected_arrival_windows,
				"%s tactic packet preserves its planned timing windows" % stage_id
			)
			_expect(
				int(packet.get("squads_per_window", 0)) == expected_squads_per_window,
				"%s tactic packet preserves its planned logical squads per window" % stage_id
			)
		_expect(
			unit_count == int(CombatStages.AUTHORED_COUNTS[stage_index]),
			"%s authored unit count is unchanged" % stage_id
		)
		_expect(
			tactic_packets == expected_tactic_packets,
			"%s tags one squad per post-opening surge" % stage_id
		)
		_expect(beat_kinds.has(&"teach"), "%s includes a Teach beat" % stage_id)
		_expect(beat_kinds.has(&"combine"), "%s includes a Combine beat" % stage_id)
		_expect(beat_kinds.has(&"power_test"), "%s includes a Power Test beat" % stage_id)
		var rollout: Dictionary = Catalog.STAGE_ROLLOUT[stage_index]
		var expected_tactic_families := (
			1 if rollout["teach"] == rollout["combine"] else 2
		)
		_expect(
			tactic_ids.size() == expected_tactic_families,
			"%s exposes the planned tactic family count" % stage_id
		)


func _validate_role_signatures() -> void:
	var family_assets := {}
	for archetype in EnemyArchetypes.ORDINARY_ARCHETYPES:
		var descriptor := ActorCatalog.descriptor(archetype)
		var asset := StringName(descriptor.get("asset", &""))
		_expect(
			not asset.is_empty() and not family_assets.has(asset),
			"%s owns one unique family-tier semantic asset" % archetype
		)
		family_assets[asset] = archetype
	_expect(
		family_assets.size() == 15,
		"five families each register one T1, T2, and T3 body"
	)
	_expect(
		StringName(ActorCatalog.descriptor(&"boss_pattern_fixed_beam_01").get("asset", &""))
			== &"actor/boss_pattern_fixed_beam_01",
		"boss-owned fixed beam stays outside the ordinary family catalog"
	)


func _validate_runtime_permissions() -> void:
	_lookup.clear()
	var runtime := Runtime.new()
	for squad_index in 2:
		var squad_id := "squad_%d" % squad_index
		for member_index in 4:
			var enemy := _enemy(
				"%s_member_%d" % [squad_id, member_index],
				squad_id,
				&"spearhead" if squad_index == 0 else &"repair_network",
				member_index,
				Vector2(
					300.0 + float(squad_index) * 260.0,
					280.0 + float(member_index) * 24.0
				)
			)
			_lookup[enemy.id] = enemy
			runtime.register_enemy(enemy)
	var visible := Rect2(0.0, 0.0, 1200.0, 800.0)
	runtime.advance(0.75, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	var snapshot := runtime.debug_snapshot()
	_expect(int(snapshot["gather_permission_count"]) == 1, "only one squad gathers at first")
	_expect(int(snapshot["active_permission_count"]) == 0, "Gather does not spend active permission")

	runtime.advance(1.30, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	_expect(int(snapshot["active_permission_count"]) == 1, "exactly one squad owns Lock permission")
	_expect(int(snapshot["gather_permission_count"]) == 1, "one additional squad may Gather")
	_expect(int(snapshot["maximum_active_permissions"]) <= 1, "global Lock/Execute permission never overlaps")

	runtime.advance(1.35, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	_expect(int(Dictionary(snapshot["phase_counts"]).get(&"execute", 0)) >= 1, "visible Lock advances to Execute")

	for enemy_variant in _lookup.values():
		var enemy: EnemyState = enemy_variant
		if enemy.squad_id == "squad_0":
			enemy.pos = Vector2(2400.0, 1800.0)
	runtime.advance(0.02, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	_expect(int(snapshot["offscreen_execute_count"]) == 0, "offscreen Execute count remains zero")
	_expect(int(snapshot["offscreen_cancellations"]) >= 1, "offscreen committed squad is cancelled")
	_expect(int(snapshot["active_permission_count"]) <= 1, "permission transfers without overlap")

	_lookup.erase("squad_1_member_0")
	runtime.advance(0.02, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	_expect(int(snapshot["stale_members_removed"]) >= 1, "invalid member IDs are pruned")
	_expect(int(snapshot["stale_member_count"]) == 0, "no stale member remains registered")
	_expect(int(Dictionary(snapshot["break_reasons"]).get(&"leader_lost", 0)) >= 1, "leader loss breaks a tactic")
	var external_runtime := Runtime.new()
	for member_index in 4:
		var enemy := _enemy(
			"external_member_%d" % member_index,
			"external_squad",
			&"spearhead",
			member_index,
			Vector2(420.0, 260.0 + float(member_index) * 24.0)
		)
		_lookup[enemy.id] = enemy
		external_runtime.register_enemy(enemy)
	external_runtime.advance(
		0.75,
		Vector2(800.0, 400.0),
		visible,
		Callable(self, "_find_enemy")
	)
	external_runtime.break_squad("external_squad", &"cover_collision")
	var deferred_events := external_runtime.advance(
		0.01,
		Vector2(800.0, 400.0),
		visible,
		Callable(self, "_find_enemy")
	)
	var external_break_seen := false
	for event in deferred_events:
		external_break_seen = external_break_seen or (
			StringName(event.get("kind", &"")) == &"break"
			and StringName(event.get("reason", &"")) == &"cover_collision"
		)
	_expect(
		external_break_seen,
		"external Break events survive until the next event handoff"
	)


func _validate_runtime_visibility_arming() -> void:
	_lookup.clear()
	var runtime := Runtime.new()
	for member_index in 4:
		var enemy := _enemy(
			"arming_member_%d" % member_index,
			"arming_squad",
			&"spearhead",
			member_index,
			Vector2(1800.0, 1200.0 + float(member_index) * 24.0)
		)
		_lookup[enemy.id] = enemy
		runtime.register_enemy(enemy)
	var visible := Rect2(0.0, 0.0, 1200.0, 800.0)
	runtime.advance(12.0, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	var snapshot := runtime.debug_snapshot()
	var eligibility: Dictionary = Dictionary(snapshot["eligibility"]).get("arming_squad", {})
	_expect(int(snapshot["gather_permission_count"]) == 0, "offscreen complete squad cannot claim Gather")
	_expect(
		int(Dictionary(snapshot["phases"]).get(&"dormant", 0)) == 1,
		"offscreen complete squad remains Dormant"
	)
	_expect(
		not bool(Dictionary(eligibility).get("visible_eligible", true))
			and is_zero_approx(float(Dictionary(eligibility).get("visible_dwell", -1.0))),
		"offscreen visibility resets dormant eligibility dwell"
	)
	var visible_index := 0
	for enemy_variant in _lookup.values():
		var enemy: EnemyState = enemy_variant
		enemy.pos = Vector2(360.0, 260.0 + float(visible_index) * 24.0)
		visible_index += 1
	runtime.advance(0.40, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	for enemy_variant in _lookup.values():
		var enemy: EnemyState = enemy_variant
		enemy.pos = Vector2(1800.0, 1200.0)
	runtime.advance(0.01, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	eligibility = Dictionary(snapshot["eligibility"]).get("arming_squad", {})
	_expect(
		is_zero_approx(float(Dictionary(eligibility).get("visible_dwell", -1.0))),
		"visibility loss resets partially armed dormant dwell"
	)
	visible_index = 0
	for enemy_variant in _lookup.values():
		var enemy: EnemyState = enemy_variant
		enemy.pos = Vector2(360.0, 260.0 + float(visible_index) * 24.0)
		visible_index += 1
	runtime.advance(0.74, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	eligibility = Dictionary(snapshot["eligibility"]).get("arming_squad", {})
	_expect(int(snapshot["gather_permission_count"]) == 0, "0.74 seconds visible is insufficient for Gather")
	_expect(
		bool(Dictionary(eligibility).get("visible_eligible", false))
			and is_equal_approx(float(Dictionary(eligibility).get("visible_dwell", 0.0)), 0.74),
		"debug snapshot reports active but incomplete visible eligibility"
	)
	runtime.advance(0.01, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
	snapshot = runtime.debug_snapshot()
	_expect(int(snapshot["gather_permission_count"]) == 1, "0.75 seconds continuous visibility permits Gather")
	_expect(
		int(Dictionary(snapshot["phases"]).get(&"gather", 0)) == 1,
		"visible dwell transitions only to Gather"
	)


func _validate_pack_trait_runtime() -> void:
	for trait_spec in [
		{&"family":&"defender", &"trait":&"bulwark", &"interval":8.0},
		{&"family":&"defender", &"trait":&"reflector", &"interval":7.0},
	]:
		_lookup.clear()
		var runtime := Runtime.new()
		var members := _register_trait_pack(
			runtime,
			"%s_pack" % String(trait_spec[&"trait"]),
			StringName(trait_spec[&"family"]),
			StringName(trait_spec[&"trait"]),
			&"shielded_column"
		)
		runtime.advance(
			float(trait_spec[&"interval"]),
			Vector2(800.0, 400.0),
			Rect2(0.0, 0.0, 1200.0, 800.0),
			Callable(self, "_find_enemy")
		)
		_expect(
			_all_members_trait_phase(members, &"active", true),
			"%s activates as shared pack state after its exact interval"
			% String(trait_spec[&"trait"])
		)

	_lookup.clear()
	var blink_runtime := Runtime.new()
	var blink_members := _register_trait_pack(
		blink_runtime, "blink_pack", &"coordinator", &"blink", &"shepherd_pack"
	)
	var blink_events := blink_runtime.advance(
		9.0,
		Vector2(800.0, 400.0),
		Rect2(0.0, 0.0, 1200.0, 800.0),
		Callable(self, "_find_enemy")
	)
	_expect(
		_events_have_action(blink_events, &"warning"),
		"Blink emits its shared warning event"
	)
	blink_events = blink_runtime.advance(
		0.9,
		Vector2(800.0, 400.0),
		Rect2(0.0, 0.0, 1200.0, 800.0),
		Callable(self, "_find_enemy")
	)
	_expect(
		_events_have_action(blink_events, &"blink_request"),
		"Blink emits a relocation request after the warning"
	)
	_expect(
		_all_members_trait_phase(blink_members, &"idle", false),
		"Blink returns the whole pack to idle after requesting relocation"
	)

	_lookup.clear()
	var feed_runtime := Runtime.new()
	var feed_members := _register_trait_pack(
		feed_runtime,
		"feed_pack",
		&"coordinator",
		&"pack_feed",
		&"shepherd_pack"
	)
	var first_receipt := feed_runtime.record_member_defeat(feed_members[1])
	_expect(
		int(first_receipt.get("stacks", 0)) == 1
			and is_equal_approx(float(first_receipt.get("heal_ratio", 0.0)), 0.10),
		"Pack Feed grants one capped stack and its survivor heal receipt"
	)
	var leader_receipt := feed_runtime.record_member_defeat(feed_members[0])
	_expect(
		bool(leader_receipt.get("leader_lost", false)),
		"Pack Feed recognizes the explicit Coordinator leader loss"
	)
	_expect(
		feed_runtime.record_member_defeat(feed_members[2]).is_empty(),
		"Pack Feed cannot gain stacks after the Coordinator leader is lost"
	)


func _register_trait_pack(
	runtime: Runtime,
	squad_id: String,
	pack_family: StringName,
	pack_trait: StringName,
	tactic_id: StringName
) -> Array[EnemyState]:
	var members: Array[EnemyState] = []
	for member_index in 4:
		var enemy := _enemy(
			"%s_member_%d" % [squad_id, member_index],
			squad_id,
			tactic_id,
			member_index,
			Vector2(360.0, 260.0 + float(member_index) * 24.0)
		)
		enemy.pack_family = pack_family
		enemy.pack_trait = pack_trait
		enemy.family = (
			pack_family
			if member_index == 0 else (&"emitter" if pack_family == &"defender" else &"pursuer")
		)
		enemy.family_trait = pack_trait if enemy.family == pack_family else &""
		members.append(enemy)
		_lookup[enemy.id] = enemy
	# Registration order is intentionally reversed so only explicit metadata and
	# the explicit leader flag can determine shared pack truth.
	for member_index in range(members.size() - 1, -1, -1):
		runtime.register_enemy(members[member_index])
	return members


func _all_members_trait_phase(
	members: Array[EnemyState],
	phase: StringName,
	require_active: bool
) -> bool:
	for enemy in members:
		if enemy.pack_trait_phase != phase:
			return false
		if require_active and not enemy.pack_trait_active:
			return false
	return true


func _events_have_action(events: Array[Dictionary], action: StringName) -> bool:
	for event in events:
		if StringName(event.get("action", &"")) == action:
			return true
	return false


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string(
		"res://scripts/encounters/vehicle_collective_tactic_runtime.gd"
	)
	_expect(
		not runtime_source.contains("for enemy in enemies"),
		"tactic runtime never scans the complete enemy array"
	)
	var director_source := FileAccess.get_file_as_string(
		"res://scripts/encounters/vehicle_encounter_director.gd"
	)
	_expect(
		not director_source.contains("cohesion_velocity")
			and not director_source.contains("squad_motion_snapshot"),
		"ordinary encounter movement has no dormant squad cohesion"
	)
	var guide_source := FileAccess.get_file_as_string(
		"res://scripts/progression/vehicle_guidebook_catalog.gd"
	)
	for key in [
		"TACTIC_COUNTER_SPEARHEAD",
		"TACTIC_COUNTER_FUSE_PACK",
		"TACTIC_COUNTER_REPAIR_NETWORK",
		"TACTIC_COUNTER_CROSSFIRE",
	]:
		_expect(
			not guide_source.contains(key),
			"guidebook keeps movement and counterplay prose out of stat entries: %s" % key
		)


func _enemy(
	enemy_id: String,
	squad_id: String,
	tactic_id: StringName,
	member_index: int,
	position: Vector2
) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.squad_id = squad_id
	enemy.collective_tactic_id = tactic_id
	enemy.collective_beat_kind = &"teach"
	enemy.squad_leader = member_index == 0
	enemy.alive = true
	enemy.active = true
	enemy.pos = position
	enemy.speed = 120.0
	return enemy


func _find_enemy(enemy_id: String) -> EnemyState:
	return _lookup.get(enemy_id)


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 64:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_COLLECTIVE_TACTICS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
