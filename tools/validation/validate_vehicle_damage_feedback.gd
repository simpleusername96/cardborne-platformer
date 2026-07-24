extends SceneTree

const StageScene = preload("res://scenes/run/VehicleRun.tscn")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const AttackTelegraphs = preload("res://scripts/combat/vehicle_attack_telegraph_builder.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")
const SpecialistRuntime = preload("res://scripts/enemies/vehicle_enemy_specialist_runtime.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := root.get_node_or_null("SettingsStore")
	var original_reduced_motion := bool(settings.reduced_motion) if settings != null else false
	if settings != null:
		settings.reduced_motion = false

	var stage := StageScene.instantiate()
	root.add_child(stage)
	await process_frame
	stage.call("_start_deployed_run", &"pulse_cannon", RunDifficulty.HARD)
	stage.set("player_health", 120.0)
	stage.set("player_invulnerable", 0.0)
	stage.set("player_hit_flash", 0.0)
	stage.set("player_barrier_strength", 0.0)
	stage.set("player_barrier_timer", 0.0)
	stage.set("camera_shake", 0.0)
	stage.call("_damage_player", 10.0, "validation shot", true)
	_expect(float(stage.get("player_health")) < 120.0, "accepted hull damage reduces health")
	_expect(is_equal_approx(float(stage.get("player_hit_flash")), 0.20), "accepted hull damage starts the 0.20-second hit signal")
	_expect(is_equal_approx(float(stage.get("player_invulnerable")), 1.0), "accepted hull damage starts the one-second invulnerability window")
	_expect(float(stage.get("camera_shake")) > 0.0 and float(stage.get("camera_shake")) <= 3.0, "standard motion uses a bounded camera response")
	var presentation: Dictionary = stage.call("_combat_presentation_snapshot")
	_expect(is_equal_approx(float(presentation["player_hit_remaining"]), 0.20), "presentation receives the hit timer")
	_expect(is_equal_approx(float(presentation["player_invulnerable_remaining"]), 1.0), "presentation receives the invulnerability timer")

	var health_after_first_hit := float(stage.get("player_health"))
	stage.call("_damage_player", 10.0, "validation repeat", true)
	_expect(is_equal_approx(float(stage.get("player_health")), health_after_first_hit), "invulnerability rejects immediate repeat damage")

	stage.set("player_health", 120.0)
	stage.set("player_invulnerable", 0.0)
	stage.set("player_hit_flash", 0.0)
	stage.set("player_barrier_strength", 100.0)
	stage.set("player_barrier_timer", 1.0)
	stage.set("camera_shake", 0.0)
	stage.call("_damage_player", 10.0, "validation barrier", true)
	_expect(is_equal_approx(float(stage.get("player_health")), 120.0), "a fully absorbed barrier hit does not damage the hull")
	_expect(is_zero_approx(float(stage.get("player_hit_flash"))), "a fully absorbed barrier hit does not start hull feedback")
	_expect(is_zero_approx(float(stage.get("player_invulnerable"))), "a fully absorbed barrier hit does not start hull invulnerability")

	if settings != null:
		settings.reduced_motion = true
	stage.set("player_health", 120.0)
	stage.set("player_invulnerable", 0.0)
	stage.set("player_hit_flash", 0.0)
	stage.set("player_barrier_strength", 0.0)
	stage.set("player_barrier_timer", 0.0)
	stage.set("camera_shake", 0.0)
	stage.call("_damage_player", 10.0, "validation reduced motion", true)
	_expect(is_zero_approx(float(stage.get("camera_shake"))), "reduced motion removes camera shake")
	_expect(bool(stage.call("_combat_presentation_snapshot")["reduced_motion"]), "presentation receives reduced-motion state")

	var stage_ui: CanvasLayer = stage.get("_ui")
	var health_bar: Control = stage_ui.get("_health_bar")
	health_bar.call("set_values", 120.0, 120.0, 1, 0.0, 12.0, false)
	health_bar.call("set_values", 80.0, 120.0, 1, 0.0, 12.0, false)
	_expect(is_equal_approx(float(health_bar.get("trailing_health")), 120.0), "standard motion holds the previous health value")
	_expect(health_bar.is_processing(), "health loss animation processes only while active")
	health_bar.call("_process", 0.18)
	health_bar.call("_process", 0.45)
	_expect(is_equal_approx(float(health_bar.get("trailing_health")), 80.0), "health loss trail closes over the bounded decay")
	_expect(not health_bar.is_processing(), "health loss animation stops processing when settled")
	health_bar.call("set_values", 60.0, 120.0, 1, 0.0, 12.0, true)
	_expect(is_equal_approx(float(health_bar.get("trailing_health")), 60.0), "reduced motion replaces the trailing animation with a steady pulse")

	var projectile_store: RefCounted = stage.get("projectile_store")
	projectile_store.call("clear")
	stage.call(
		"_spawn_hostile_projectile",
		Vector2.ZERO,
		Vector2.RIGHT,
		4.0,
		500.0,
		"validation ordinary",
		AttackContract.KINETIC,
		false
	)
	var hostile_projectiles: Array = projectile_store.get("hostile_live")
	_expect(hostile_projectiles.size() == 1, "ordinary hostile projectile enters the retained store")
	if hostile_projectiles.size() == 1:
		_expect(is_equal_approx(float(hostile_projectiles[0].radius), 5.0), "ordinary hostile projectile uses a five-pixel collision radius")
		_expect(is_equal_approx(Vector2(hostile_projectiles[0].velocity).length(), 410.0), "ordinary hostile projectile uses the reduced effective speed contract")
		_expect(not bool(hostile_projectiles[0].wall_piercing), "ordinary hostile projectile cannot cross solid blockers")
	projectile_store.call("clear")
	stage.call(
		"_spawn_hostile_projectile",
		Vector2.ZERO,
		Vector2.RIGHT,
		12.0,
		500.0,
		"validation standard",
		AttackContract.THERMAL,
		true
	)
	hostile_projectiles = projectile_store.get("hostile_live")
	if hostile_projectiles.size() == 1:
		_expect(is_equal_approx(float(hostile_projectiles[0].radius), 6.0), "standard hostile damage uses a six-pixel collision radius")
		_expect(is_equal_approx(Vector2(hostile_projectiles[0].velocity).length(), 410.0), "boss prediction and motion share the reduced speed contract")
		_expect(hostile_projectiles[0].affinity == AttackContract.THERMAL, "hostile projectile retains its authored affinity")

	projectile_store.call("clear")
	stage.call(
		"_spawn_hostile_projectile",
		Vector2.ZERO,
		Vector2.RIGHT,
		20.0,
		500.0,
		"validation heavy",
		AttackContract.ARC,
		true
	)
	hostile_projectiles = projectile_store.get("hostile_live")
	if hostile_projectiles.size() == 1:
		_expect(is_equal_approx(float(hostile_projectiles[0].radius), 7.0), "heavy hostile damage uses a seven-pixel collision radius")
		_expect(hostile_projectiles[0].affinity == AttackContract.ARC, "heavy projectile retains its distinct affinity")

	projectile_store.call("clear")
	stage.call("_spawn_player_projectile", Vector2.ZERO, Vector2.RIGHT, 4.0, 500.0, 0)
	var player_projectiles: Array = projectile_store.get("player_live")
	_expect(player_projectiles.size() == 1, "default player projectile enters the retained store")
	if player_projectiles.size() == 1:
		_expect(is_equal_approx(float(player_projectiles[0].radius), 7.0), "default player projectile uses the larger seven-pixel collision radius")
		_expect(not bool(player_projectiles[0].wall_piercing), "default player projectile cannot cross solid blockers")

	var field_layout: Variant = stage.get("field_layout")
	var cover: Rect2 = field_layout.cover_rects[0]
	var cover_from := cover.get_center() - Vector2(cover.size.x * 0.5 + 80.0, 0.0)
	stage.set("player_position", cover.get_center() + Vector2(0.0, 250.0))
	projectile_store.call("clear")
	stage.call("_spawn_hostile_projectile", cover_from, Vector2.RIGHT, 4.0, 500.0, "validation cover")
	stage.call("_update_projectiles", 0.5)
	_expect(projectile_store.call("hostile_count") == 0, "default hostile projectile stops at runtime cover")

	projectile_store.call("clear")
	stage.call(
		"_spawn_hostile_projectile",
		cover_from,
		Vector2.RIGHT,
		4.0,
		500.0,
		"validation phase shot",
		AttackContract.KINETIC,
		false,
		true
	)
	stage.call("_update_projectiles", 0.5)
	_expect(projectile_store.call("hostile_count") == 1, "explicit wall-piercing projectile can cross runtime cover")

	var crates: Array = stage.get("crates")
	var crate: Dictionary = crates[0]
	var crate_position := Vector2(crate["pos"])
	var crate_health := float(crate["health"])
	var crate_from := crate_position - Vector2(100.0, 0.0)
	stage.set("player_position", crate_position + Vector2(0.0, 200.0))
	_expect(
		bool(stage.call("_segment_hits_live_crate", crate_from, crate_position + Vector2(100.0, 0.0), 5.0)),
		"crate broadphase reports the live movement blocker"
	)
	projectile_store.call("clear")
	stage.call("_spawn_hostile_projectile", crate_from, Vector2.RIGHT, 4.0, 500.0, "validation crate")
	stage.call("_update_projectiles", 0.5)
	_expect(projectile_store.call("hostile_count") == 0, "default hostile projectile stops at a live crate")
	_expect(is_equal_approx(float(crate["health"]), crate_health), "hostile projectile uses a crate as cover without destroying the reward")
	_expect(
		not bool(stage.call("_runtime_has_line_of_sight", crate_from, crate_position + Vector2(100.0, 0.0), 5.0)),
		"live crate blocks enemy projectile line of sight"
	)
	var crate_path_end := Vector2(stage.call(
		"_runtime_attack_path_end",
		crate_from,
		Vector2.RIGHT,
		200.0,
		5.0
	))
	_expect(
		is_equal_approx(crate_path_end.x, crate_position.x - 36.0),
		"projectile warning stops at the same live-crate contact boundary"
	)
	_check_attack_telegraphs(stage)

	_expect(
		is_equal_approx(EncounterDirector.HOSTILE_PROJECTILE_SPEED_MULTIPLIER, 0.82),
		"hostile projectile speed is reduced by the accepted global factor"
	)

	if settings != null:
		settings.reduced_motion = original_reduced_motion
	stage.queue_free()
	await process_frame
	_finish()


func _check_attack_telegraphs(stage: Node) -> void:
	var resolve_path := Callable(stage, "_runtime_attack_path_end")
	var resolve_charge_path := Callable(stage, "_runtime_charge_path_end")
	var boss = stage.call("_make_enemy", {
		"id":"telegraph_boss",
		"role":&"stage_boss",
		"pos":stage.player_position + Vector2(-520.0, 0.0),
		"active":true,
	})
	boss.phase = &"boss_startup"
	boss.committed_dir = Vector2.RIGHT
	boss.committed_target = stage.player_position
	boss.lane_centers = [-135.0, 135.0]

	AttackTelegraphs.refresh_boss(
		boss,
		"furnace_ring",
		resolve_path,
		resolve_charge_path
	)
	_expect(boss.attack_telegraphs.size() == 4, "furnace startup exposes its area and three aimed projectiles")
	_expect(
		StringName(boss.attack_telegraphs[0]["shape"]) == &"area"
			and is_equal_approx(float(boss.attack_telegraphs[0]["radius"]), 230.0),
		"furnace warning uses the exact direct-damage radius"
	)
	for warning in boss.attack_telegraphs:
		_expect(
			StringName(warning["affinity"]) == AttackContract.THERMAL,
			"furnace components share one truthful thermal affinity"
		)

	AttackTelegraphs.refresh_boss(
		boss,
		"foundry_ram",
		resolve_path,
		resolve_charge_path
	)
	_expect(boss.attack_telegraphs.size() == 4, "ram startup exposes contact travel and three aimed projectiles")
	_expect(
		is_equal_approx(
			float(boss.attack_telegraphs[0]["half_width"]),
			AttackContract.contact_danger_half_width(
				float(boss.radius),
				BossPatterns.BOSS_CONTACT_PADDING
			)
		),
		"ram corridor uses the exact player-center contact footprint"
	)
	var ram_endpoint := Vector2(resolve_charge_path.call(
		boss.pos,
		boss.committed_dir,
		BossPatterns.BOSS_CHARGE_SPEED
			* EncounterDirector.ENEMY_SPEED_MULTIPLIER
			* BossPatterns.active_seconds("foundry_ram"),
		boss.radius
	))
	_expect(
		Vector2(boss.attack_telegraphs[0]["to"]).is_equal_approx(ram_endpoint),
		"ram warning and committed straight-line movement share one blocker endpoint"
	)

	AttackTelegraphs.refresh_boss(
		boss,
		"pylon_overload",
		resolve_path,
		resolve_charge_path
	)
	_expect(boss.attack_telegraphs.size() == 4, "pylon startup exposes its area and three aimed projectiles")
	_expect(
		boss.attack_telegraphs.all(
			func(warning): return StringName(warning["affinity"]) == AttackContract.ARC
		),
		"pylon overload components use the arc visual family"
	)

	var beam = stage.call("_make_enemy", {
		"id":"telegraph_beam",
		"role":&"beam_sentinel",
		"pos":stage.player_position + Vector2(-400.0, 0.0),
		"active":true,
	})
	beam.phase = &"startup"
	beam.committed_dir = Vector2.RIGHT
	AttackTelegraphs.refresh_ordinary(
		beam,
		resolve_path,
		resolve_charge_path
	)
	_expect(
		beam.attack_telegraphs.size() == 1
			and is_equal_approx(
				float(beam.attack_telegraphs[0]["half_width"]),
				AttackContract.beam_danger_half_width(SpecialistRuntime.BEAM_WIDTH)
			)
			and is_equal_approx(
				float(beam.attack_telegraphs[0]["active_width"]),
				SpecialistRuntime.BEAM_WIDTH
			),
		"beam startup and active body share one exact collision footprint"
	)

	var mine = stage.call("_make_enemy", {
		"id":"telegraph_mine",
		"role":&"mine",
		"pos":stage.player_position + Vector2(280.0, 0.0),
		"active":true,
	})
	mine.phase = &"startup"
	mine.committed_dir = Vector2.LEFT
	AttackTelegraphs.refresh_ordinary(
		mine,
		resolve_path,
		resolve_charge_path
	)
	_expect(
		mine.attack_telegraphs.size() == 1
			and is_equal_approx(
				float(mine.attack_telegraphs[0]["radius"]),
				float(AttackContract.ORDINARY_ATTACKS[&"mine"]["radius"])
			),
		"mine warning uses its exact proximity damage radius"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_DAMAGE_FEEDBACK_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
