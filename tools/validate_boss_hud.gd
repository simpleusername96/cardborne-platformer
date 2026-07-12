extends SceneTree

const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(960, 540)
	var packed := load(HUD_SCENE) as PackedScene
	_expect(packed != null, "production HUD should load")
	if packed == null:
		_finish()
		return
	var hud := packed.instantiate() as Control
	root.add_child(hud)
	await process_frame
	hud.call("_on_stage_started", "slime_court", "Slime Court")
	hud.call("_on_boss_snapshot", _boss_snapshot(&"jump_slam", &"startup"))
	await process_frame

	var panel := hud.find_child("BossPanel", true, false) as Control
	var name_label := hud.find_child("BossName", true, false) as Label
	var status_label := hud.find_child("BossStatus", true, false) as Label
	var health_bar := hud.find_child("BossHealth", true, false) as ProgressBar
	var stagger_bar := hud.find_child("BossStagger", true, false) as ProgressBar
	var combat_panel := hud.find_child("CombatPanel", true, false) as Control
	_expect(panel != null and panel.visible, "Slime Court should reveal boss HUD")
	_expect(name_label != null and name_label.text.contains("64 / 80"), "boss HUD should show exact health")
	_expect(name_label != null and name_label.text.contains("PHASE II"), "boss HUD should show phase")
	_expect(status_label != null and status_label.text == "SHADOW - MOVE", "Jump Slam startup should name its response")
	_expect(health_bar != null and is_equal_approx(health_bar.value, 64.0), "health bar should consume boss snapshot")
	_expect(stagger_bar != null and is_equal_approx(stagger_bar.value, 35.0), "stagger bar should consume boss snapshot")
	_expect(
		combat_panel != null
		and is_equal_approx(combat_panel.anchor_top, 0.0)
		and combat_panel.offset_right - combat_panel.offset_left <= 220.0,
		"boss mode should keep player actions in a narrow non-occluding column"
	)

	hud.call("_on_boss_snapshot", _boss_snapshot(&"poison_bands", &"active"))
	_expect(status_label.text == "HOLD SAFE FLOOR", "active Poison should retain its learned response")
	var staggered := _boss_snapshot(&"", &"idle")
	staggered["actor_state"] = &"staggered"
	hud.call("_on_boss_snapshot", staggered)
	_expect(status_label.text == "STAGGERED - ATTACK", "stagger should expose the punish window")

	hud.call("_on_stage_started", "ruin_approach", "Ruin Approach")
	_expect(not panel.visible, "normal stages should hide boss HUD")
	_expect(is_equal_approx(combat_panel.anchor_top, 0.0), "normal stages should restore top action layout")
	hud.queue_free()
	await process_frame
	_finish()


func _boss_snapshot(pattern_id: StringName, state: StringName) -> Dictionary:
	return {
		"actor_state": &"active",
		"health": 64,
		"max_health": 80,
		"phase": 2,
		"stagger_capacity": 100,
		"stagger_meter": 35,
		"pattern": {"pattern_id": pattern_id, "state": state},
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BOSS_HUD_VALIDATION_OK viewport=960x540")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
