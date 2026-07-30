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
const Visuals = preload(
	"res://scripts/presentation/vehicle_combat_visual_library.gd"
)

var _failures: Array[String] = []
var _lookup: Dictionary = {}


func _initialize() -> void:
	_validate_catalog_and_stage_rollout()
	_validate_role_signatures()
	_validate_runtime_permissions()
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
		var beat_kinds := {}
		var tactic_ids := {}
		for packet_variant in packets:
			var packet := Dictionary(packet_variant)
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
			_expect(
				StringName(packet.get("arrival_mode", &""))
					== &"multi_sector",
				"%s tactic packet preserves multi-sector arrival" % stage_id
			)
			_expect(
				int(packet.get("pack_count", 0))
					== CombatStages.SURGE_PACKS,
				"%s tactic packet preserves four arrival packs" % stage_id
			)
		_expect(
			unit_count == int(CombatStages.AUTHORED_COUNTS[stage_index]),
			"%s authored unit count is unchanged" % stage_id
		)
		_expect(tactic_packets == packets.size() - 1, "%s tags one squad per surge" % stage_id)
		_expect(beat_kinds.has(&"teach"), "%s includes a Teach beat" % stage_id)
		_expect(beat_kinds.has(&"combine"), "%s includes a Combine beat" % stage_id)
		_expect(beat_kinds.has(&"power_test"), "%s includes a Power Test beat" % stage_id)
		_expect(
			tactic_ids.size() == (1 if stage_index == 4 else 2),
			"%s exposes the planned tactic family count" % stage_id
		)


func _validate_role_signatures() -> void:
	var signatures := {}
	for archetype in Visuals.ENEMY_ARCHETYPES:
		if archetype in [&"stage_boss", &"boss_pylon"]:
			continue
		var points := Visuals.debug_enemy_signature(archetype)
		var signature := var_to_str(points)
		_expect(
			not signatures.has(signature),
			"%s has a unique grayscale outer contour" % archetype
		)
		signatures[signature] = archetype
	_expect(signatures.size() == 18, "all 18 ordinary enemy silhouettes are unique")


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
	runtime.advance(0.01, Vector2(800.0, 400.0), visible, Callable(self, "_find_enemy"))
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
		0.01,
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


func _validate_source_boundaries() -> void:
	var runtime_source := FileAccess.get_file_as_string(
		"res://scripts/encounters/vehicle_collective_tactic_runtime.gd"
	)
	_expect(
		not runtime_source.contains("for enemy in enemies"),
		"tactic runtime never scans the complete enemy array"
	)
	var renderer_source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_combat_renderer.gd"
	)
	_expect(
		not renderer_source.contains("&\"mobile_enemy_set\""),
		"mobile enemy atlas fallback is removed"
	)
	_expect(
		not renderer_source.contains("&\"stationary_enemy_set\""),
		"stationary enemy atlas fallback is removed"
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
		_expect(guide_source.contains(key), "guidebook exposes %s" % key)


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
