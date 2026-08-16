extends SceneTree

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const Telegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const CuePolicy = preload("res://scripts/presentation/components/vehicle_combat_cue_policy.gd")
const Patterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")

var failures: Array[String] = []


func _initialize() -> void:
	var boss := _boss()
	Telegraphs.refresh_boss(boss, "archive_cross", Callable(self, "_resolve_path"), Callable(), 1)
	var cross_contract := boss.attack_telegraphs.size() == 2
	for cue in boss.attack_telegraphs:
		cross_contract = cross_contract and (
			StringName(cue["shape"]) == &"corridor"
			and StringName(cue["delivery"]) == &"beam"
			and is_equal_approx(float(cue["active_width"]), Patterns.width("archive_cross", 1))
		)
	_expect(
		cross_contract,
		"Archive Cross publishes exactly two committed X corridors"
	)
	if boss.attack_telegraphs.size() == 2:
		var first_axis := (Vector2(boss.attack_telegraphs[0]["to"]) - Vector2(boss.attack_telegraphs[0]["from"])).normalized()
		var second_axis := (Vector2(boss.attack_telegraphs[1]["to"]) - Vector2(boss.attack_telegraphs[1]["from"])).normalized()
		_expect(absf(first_axis.dot(second_axis)) <= 0.001, "Archive Cross corridors are perpendicular and form one X")
	boss = _boss()
	Telegraphs.refresh_boss(boss, "common_broad_barrage", Callable(self, "_resolve_path"), Callable(), 0)
	var barrage_contract := boss.attack_telegraphs.size() == 12
	for cue in boss.attack_telegraphs:
		barrage_contract = barrage_contract and (
			StringName(cue["delivery"]) == &"projectile"
			and not cue.has("show_path")
			and cue.has("row_delay")
		)
	_expect(
		barrage_contract,
		"opening broad barrage publishes all three four-shot startup rows"
	)
	if not boss.attack_telegraphs.is_empty():
		_expect(
			CuePolicy.telegraph_mode(
				boss.pos, boss.visual_radius, boss.phase,
				boss.attack_telegraphs[0], Rect2(-2000.0, -2000.0, 4000.0, 4000.0)
			) == CuePolicy.MODE_NONE,
			"broad barrage relies on muzzle anticipation and projectile bodies"
		)
		_expect(
			CuePolicy.unseen_committed_attack_readiness(
				Vector2(-2200.0, 0.0), boss.visual_radius, boss.phase,
				boss.attack_telegraphs, Rect2(-640.0, -360.0, 1280.0, 720.0)
			) >= 0.0,
			"broad barrage descriptors still drive off-screen threat-radar readiness"
		)
	var run_source := FileAccess.get_file_as_string("res://scripts/vehicle/vehicle_run.gd")
	_expect(
		run_source.contains("func _append_boss_cross_corridors")
			and run_source.contains("\"single_hit\":true")
			and run_source.contains("BossPatterns.BEAM_RANGE"),
		"Archive Cross gameplay creates two clipped one-hit corridor zones"
	)
	_expect(Patterns.startup_seconds("common_broad_barrage") >= 1.30, "broad barrage keeps the high-threat minimum warning")
	_finish()


func _boss() -> EnemyState:
	var boss := EnemyState.new()
	boss.id = "cue_boss"
	boss.role = &"stage_boss"
	boss.archetype = &"stage_boss"
	boss.pos = Vector2.ZERO
	boss.visual_radius = 88.0
	boss.phase = &"boss_startup"
	boss.phase_time = 1.30
	boss.committed_dir = Vector2.RIGHT
	boss.committed_target = Vector2(600.0, 0.0)
	return boss


func _resolve_path(origin: Vector2, direction: Vector2, distance: float, _padding: float) -> Vector2:
	return origin + direction.normalized() * distance


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_BOSS_IDENTITY_CUES_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
