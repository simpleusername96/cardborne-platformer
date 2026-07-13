extends SceneTree

const HUD_SCENE := "res://scenes/ui/production/ProductionHUD.tscn"
const VIEWPORTS: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load(HUD_SCENE) as PackedScene
	_expect(packed != null, "gameplay HUD scene should load")
	if packed == null:
		_finish()
		return
	for viewport_size in VIEWPORTS:
		await _validate_viewport(packed, viewport_size)
	_finish()


func _validate_viewport(packed: PackedScene, viewport_size: Vector2i) -> void:
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	var hud := packed.instantiate() as Control
	root.add_child(hud)
	await process_frame
	hud.call("_on_run_state_changed", _run_snapshot(&"warrior", 4, 73, 19, 6, 7, 0))
	hud.call("_on_combat_state_changed", _combat_snapshot({
		"current_attack_id": "warrior_guard_breaker",
		"guarded_time": 1.4,
		"charge_fraction": 0.68,
	}))
	await process_frame

	var layout: Dictionary = hud.call("get_layout_snapshot")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var health_rect := layout["health_rect"] as Rect2
	var resources_rect := layout["resources_rect"] as Rect2
	var objective_rect := layout["objective_rect"] as Rect2
	var action_rect := layout["action_bar_rect"] as Rect2
	var safe_gap_rect := layout["action_center_gap_rect"] as Rect2
	var context_rect := layout["context_lane_rect"] as Rect2
	_expect(_inside(viewport_rect, health_rect), "%s health cluster should fit" % viewport_size)
	_expect(_inside(viewport_rect, resources_rect), "%s resource strip should fit" % viewport_size)
	_expect(_inside(viewport_rect, objective_rect), "%s objective band should fit" % viewport_size)
	_expect(_inside(viewport_rect, action_rect), "%s action bar should fit" % viewport_size)
	_expect(_inside(viewport_rect, safe_gap_rect), "%s action-bar safe gap should fit" % viewport_size)
	_expect(_inside(viewport_rect, context_rect), "%s context lane should fit" % viewport_size)
	_expect(not health_rect.intersects(objective_rect), "%s health and objective should not overlap" % viewport_size)
	_expect(not resources_rect.intersects(objective_rect), "%s resources and objective should not overlap" % viewport_size)
	_expect(not health_rect.intersects(context_rect), "%s context lane should not cover health" % viewport_size)
	_expect(not resources_rect.intersects(context_rect), "%s context lane should not cover resources" % viewport_size)
	_expect(not objective_rect.intersects(context_rect), "%s context lane should not cover the objective" % viewport_size)
	_expect(context_rect.end.y < action_rect.position.y, "%s context lane should stay above actions" % viewport_size)
	_expect(
		safe_gap_rect.position.x < viewport_size.x * 0.5
		and safe_gap_rect.end.x > viewport_size.x * 0.5,
		"%s action bar should leave the followed-player center unobstructed" % viewport_size
	)
	_expect(safe_gap_rect.size.x >= 120.0, "%s action-bar safe gap should be at least 120px" % viewport_size)
	_expect((layout["slots"] as Array).size() == 6, "%s HUD should expose six stable action slots" % viewport_size)
	_expect(hud.find_child("CombatPanel", true, false) == null, "legacy multiline combat panel should be absent")
	_expect(not _all_label_text(hud).contains("READY"), "routine readiness should not use READY text")

	var slots := layout["slots"] as Array
	for slot in slots:
		var slot_rect := slot["rect"] as Rect2
		_expect(slot_rect.size.x >= 92.0, "%s action slots should keep a 92px minimum width" % viewport_size)
		_expect(slot_rect.size.y >= 104.0, "%s action slots should keep a 104px minimum height" % viewport_size)
	_expect(slots[0]["state"] == "1.2s", "cooldown slot should show exact remaining seconds")
	_expect(slots[1]["state"] == "68%", "active charge slot should show exact charge percent")
	_expect(slots[5]["state"] == "EMPTY", "zero-charge consumable should show an unavailable state")
	_expect(slots[5]["count"] == "x0", "consumable slot should show exact zero charges")
	if viewport_size.x < 1100:
		_expect(slots[1]["label"] == "BREAKER", "compact heavy label should avoid a cramped second line")
		_expect(slots[3]["label"] == "SPLITTER", "compact skill label should avoid a cramped second line")
	else:
		_expect(slots[1]["label"] == "GUARD BREAKER", "wide HUD should preserve the full heavy label")
		_expect(slots[3]["label"] == "GROUND SPLITTER", "wide HUD should preserve the full skill label")
	_expect(String((layout["class_state"] as Dictionary)["text"]).contains("GUARD"), "Warrior state should expose Resolve guard")

	hud.call("_on_run_state_changed", _run_snapshot(&"assassin", 4, 73, 19, 6, 7, 1))
	var assassin_state := _combat_snapshot({"flow_stacks": 3, "flow_time": 2.4, "death_mark_count": 1})
	hud.call("_on_combat_state_changed", assassin_state)
	await process_frame
	layout = hud.call("get_layout_snapshot")
	_expect(String((layout["class_state"] as Dictionary)["text"]).contains("FLOW 3/3"), "Assassin state should expose Flow stacks")
	_expect(String((layout["class_state"] as Dictionary)["text"]).contains("MARK 1"), "Assassin state should expose Death Mark count")

	hud.call("_on_run_state_changed", _run_snapshot(&"archer", 4, 73, 19, 6, 7, 1))
	var archer_state := _combat_snapshot({"hunter_mark_count": 2, "charge_fraction": 0.84})
	archer_state["current_attack_id"] = "archer_power_shot"
	hud.call("_on_combat_state_changed", archer_state)
	await process_frame
	layout = hud.call("get_layout_snapshot")
	_expect(String((layout["class_state"] as Dictionary)["text"]).contains("DRAW 84%"), "Archer state should expose draw charge")
	_expect(String((layout["class_state"] as Dictionary)["text"]).contains("MARK 2"), "Archer state should expose Hunter's Mark count")

	hud.call("_on_interaction_prompt_changed", "Open cache", true)
	await process_frame
	layout = hud.call("get_layout_snapshot")
	_expect(bool(layout["prompt_visible"]), "active interaction should occupy the context lane")
	var receipt: RewardReceiptPresenter = hud.get("reward_receipt")
	var chest_view := receipt.build_view_model({
		"applied": true,
		"reward_role": &"cache_reward",
		"grants": {"coin": 7, "xp": 3, "rusted_scrap": 1},
		"equipment_discoveries": [],
	})
	_expect(chest_view["title"] == "CHEST OPENED", "reward receipt should preserve its committed title")
	_expect(String(chest_view["summary"]).contains("+7 Coins"), "reward receipt should preserve exact grant values")
	var signal_bus := root.get_node("/root/SignalBus")
	signal_bus.emit_signal("field_pickup_collected", {
		"applied": true,
		"effect_type": "heal",
		"amount": 2.0,
		"currency_id": "",
		"display_name": "Vital Shard",
		"message": "Vital Shard collected.",
	})
	await process_frame
	layout = hud.call("get_layout_snapshot")
	_expect(bool(layout["receipt_active"]), "field pickup receipt should occupy the context lane")
	_expect(not bool(layout["prompt_visible"]), "field pickup receipt should suppress the overlapping prompt")
	var receipt_view := receipt.get_display_snapshot()
	_expect(receipt_view["title"] == "VITAL RESTORED", "field pickup should use the Vital receipt title")
	_expect(receipt_view["summary"] == "Vital Shard  +2 HP", "field pickup should show the exact applied health")
	_expect(not String(receipt_view["summary"]).contains("heal"), "field pickup receipt should not expose effect IDs")
	_assert_field_pickup_view_models(receipt)

	var action_before_boss := (hud.call("get_layout_snapshot") as Dictionary)["action_bar_rect"] as Rect2
	hud.call("_on_stage_started", "slime_court", "Slime Court")
	hud.call("_on_boss_snapshot", {
		"actor_state": &"active",
		"health": 64,
		"max_health": 80,
		"phase": 2,
		"stagger_capacity": 100,
		"stagger_meter": 35,
		"pattern": {"pattern_id": &"jump_slam", "state": &"startup"},
	})
	await process_frame
	layout = hud.call("get_layout_snapshot")
	var boss_rect := layout["boss_rect"] as Rect2
	_expect(_inside(viewport_rect, boss_rect), "%s boss band should fit" % viewport_size)
	_expect(not health_rect.intersects(boss_rect), "%s boss band should not cover health" % viewport_size)
	_expect(not resources_rect.intersects(boss_rect), "%s boss band should not cover resources" % viewport_size)
	if viewport_size == Vector2i(960, 540):
		var health_gap := boss_rect.position.x - health_rect.end.x
		var resource_gap := resources_rect.position.x - boss_rect.end.x
		_expect(
			health_gap >= 6.0,
			"compact boss needs >=6px after health; gap=%.1f health=%s boss=%s" % [
				health_gap, health_rect, boss_rect,
			]
		)
		_expect(
			resource_gap >= 6.0,
			"compact boss needs >=6px before resources; gap=%.1f boss=%s resources=%s" % [
				resource_gap, boss_rect, resources_rect,
			]
		)
		var boss_name := hud.find_child("BossName", true, false) as Label
		_expect(boss_name.text == "SLIME KING  64/80  P2", "compact boss title should retain health and phase")
		var boss_title_width := boss_name.get_theme_font("font").get_string_size(
			boss_name.text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			boss_name.get_theme_font_size("font_size")
		).x
		_expect(
			boss_title_width <= boss_name.size.x + 0.1,
			"compact boss title should fit; text=%.1f available=%.1f" % [boss_title_width, boss_name.size.x]
		)
	_expect(action_before_boss.is_equal_approx(layout["action_bar_rect"]), "boss mode should not move action slots")

	hud.queue_free()
	await process_frame


func _run_snapshot(
	profile_id: StringName,
	level: int,
	xp: int,
	coins: int,
	health: int,
	max_health: int,
	consumable_charges: int
) -> Dictionary:
	return {
		"profile_id": String(profile_id),
		"level": level,
		"xp": xp,
		"coins": coins,
		"health": health,
		"max_health": max_health,
		"materials": {
			"rusted_scrap": 8,
			"sky_thread": 3,
			"slime_residue": 2,
			"boss_core": 1,
		},
		"consumable_id": "small_potion",
		"consumable_charges": consumable_charges,
	}


func _combat_snapshot(overrides: Dictionary = {}) -> Dictionary:
	var snapshot := {
		"phase": "idle",
		"current_attack_id": "",
		"guarded_time": 0.0,
		"guarded_rearm_time": 0.0,
		"rally_heavy_time": 0.0,
		"charge_fraction": 0.0,
		"actions": [
			{"id": "warrior_cleave", "label": "Cleave", "input_action": "attack", "cooldown": 1.2},
			{"id": "warrior_guard_breaker", "label": "Guard Breaker", "input_action": "heavy_attack", "cooldown": 0.0},
			{"id": "warrior_shield_rush", "label": "Shield Rush", "input_action": "skill_1", "cooldown": 0.0},
			{"id": "warrior_ground_splitter", "label": "Ground Splitter", "input_action": "skill_2", "cooldown": 0.0},
			{"id": "warrior_rally", "label": "Rally", "input_action": "skill_3", "cooldown": 0.0},
		],
	}
	snapshot.merge(overrides, true)
	return snapshot


func _assert_field_pickup_view_models(receipt: RewardReceiptPresenter) -> void:
	var focus := receipt.build_field_pickup_view_model({
		"effect_type": "reduce_skill_cooldowns",
		"amount": 1.25,
		"display_name": "Focus Shard",
	})
	_expect(focus["title"] == "FOCUS RESTORED", "Focus pickup should use the Focus receipt title")
	_expect(focus["summary"] == "Focus Shard  -1.25s Skill Cooldowns", "Focus pickup should keep exact seconds")
	var supply := receipt.build_field_pickup_view_model({
		"effect_type": "refill_consumable",
		"amount": 1.0,
		"display_name": "Supply Charge",
	})
	_expect(supply["title"] == "SUPPLY RESTOCKED", "Supply pickup should use the Supply receipt title")
	_expect(supply["summary"] == "Supply Charge  +1 Consumable Charge", "Supply pickup should keep exact charges")
	var currency := receipt.build_field_pickup_view_model({
		"effect_type": "grant_currency",
		"amount": 1.0,
		"currency_id": "rusted_scrap",
		"display_name": "Rusted Scrap",
	})
	_expect(currency["title"] == "CURRENCY COLLECTED", "Currency pickup should use the Currency receipt title")
	_expect(currency["summary"] == "Rusted Scrap  +1", "Currency pickup should keep exact grants")
	_expect(not String(currency["summary"]).contains("rusted_scrap"), "Currency receipt should not expose raw IDs")


func _inside(bounds: Rect2, rect: Rect2) -> bool:
	return (
		rect.position.x >= bounds.position.x - 0.1
		and rect.position.y >= bounds.position.y - 0.1
		and rect.end.x <= bounds.end.x + 0.1
		and rect.end.y <= bounds.end.y + 0.1
	)


func _all_label_text(node: Node) -> String:
	var parts: Array[String] = []
	if node is Label:
		parts.append((node as Label).text)
	for child in node.get_children():
		parts.append(_all_label_text(child))
	return "\n".join(parts)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("GAMEPLAY_HUD_VALIDATION_OK viewports=3 slots=6 field_pickup=signal>receipt>prompt")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
