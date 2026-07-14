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
	hud.call("_on_run_state_changed", _run_snapshot(4, 73, 6, 7, 1))
	hud.call("_on_combat_state_changed", _combat_snapshot())
	await process_frame

	var layout: Dictionary = hud.call("get_layout_snapshot")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var health_rect := layout["health_rect"] as Rect2
	var objective_rect := layout["objective_rect"] as Rect2
	var dock_rect := layout["combat_dock_rect"] as Rect2
	var safe_gap_rect := layout["player_safe_gap_rect"] as Rect2
	var context_rect := layout["context_lane_rect"] as Rect2
	_expect(_inside(viewport_rect, health_rect), "%s health cluster should fit" % viewport_size)
	_expect(_inside(viewport_rect, objective_rect), "%s objective band should fit" % viewport_size)
	_expect(_inside(viewport_rect, dock_rect), "%s combat dock should fit" % viewport_size)
	_expect(_inside(viewport_rect, safe_gap_rect), "%s player-safe gap should fit" % viewport_size)
	_expect(_inside(viewport_rect, context_rect), "%s context lane should fit" % viewport_size)
	_expect(not health_rect.intersects(objective_rect), "%s health and objective should not overlap" % viewport_size)
	_expect(not health_rect.intersects(context_rect), "%s context lane should not cover health" % viewport_size)
	_expect(not objective_rect.intersects(context_rect), "%s context lane should not cover the objective" % viewport_size)
	_expect(context_rect.end.y < dock_rect.position.y, "%s context lane should stay above combat state" % viewport_size)
	_expect(
		safe_gap_rect.position.x < viewport_size.x * 0.5
		and safe_gap_rect.end.x > viewport_size.x * 0.5,
		"%s combat dock should leave the followed-player center unobstructed; gap=%s"
		% [viewport_size, safe_gap_rect]
	)
	_expect(safe_gap_rect.size.x >= 120.0, "%s player-safe gap should be at least 120px" % viewport_size)
	_expect(hud.find_child("CombatPanel", true, false) == null, "legacy multiline combat panel should be absent")
	var all_text := _all_label_text(hud).to_upper()
	for retired_text in ["SKILL 1", "SKILL 2", "SKILL 3", "WARRIOR", "ARCHER", "ASSASSIN", "READY"]:
		_expect(not all_text.contains(retired_text), "HUD should not expose retired text %s" % retired_text)
	var combat: Dictionary = layout["combat"]
	_expect(combat["intent"] == "ranged", "committed ranged intent should be highlighted")
	_expect(bool((combat["ranged"] as Dictionary)["active"]), "ranged half of Attack should be active")
	_expect(not bool((combat["melee"] as Dictionary)["active"]), "melee half should remain inactive")
	_expect((combat["melee"] as Dictionary)["state"] == "CND 72%", "melee condition should be exact")
	_expect((combat["ranged"] as Dictionary)["state"] == "ARROW 7/20", "ranged supply should show current and maximum")
	_expect((combat["guard"] as Dictionary)["condition"] == "Condition 84%", "shield condition should be exact")
	_expect((combat["guard"] as Dictionary)["stability"] == "Stability 65%", "guard stability should be exact")
	_expect((combat["spirit"] as Dictionary)["state"] == "3/4 direct hits", "passive Spirit progress should be visible")
	_expect((combat["potion"] as Dictionary)["count"] == "x1", "potion charges should be visible")
	_expect(String(layout["armor"]).contains("Traveler Coat"), "health cluster should identify current armor")

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

	var dock_before_boss := (hud.call("get_layout_snapshot") as Dictionary)["combat_dock_rect"] as Rect2
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
	if viewport_size == Vector2i(960, 540):
		var health_gap := boss_rect.position.x - health_rect.end.x
		_expect(
			health_gap >= 6.0,
			"compact boss needs >=6px after health; gap=%.1f health=%s boss=%s" % [
				health_gap, health_rect, boss_rect,
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
	_expect(dock_before_boss.is_equal_approx(layout["combat_dock_rect"]), "boss mode should not move the combat dock")

	hud.queue_free()
	await process_frame


func _run_snapshot(
	level: int,
	xp: int,
	health: int,
	max_health: int,
	consumable_charges: int
) -> Dictionary:
	return {
		"profile_id": "traveler",
		"profile_display_name": "Traveler",
		"level": level,
		"xp": xp,
		"health": health,
		"max_health": max_health,
		"consumable_id": "small_potion",
		"consumable_charges": consumable_charges,
	}


func _combat_snapshot() -> Dictionary:
	return {
		"phase": "idle",
		"shared_hero_mode": true,
		"committed_intent": {"mode": "ranged", "tool_id": "hunting_bow"},
		"guard": {"stability_fraction": 0.65, "guarding": false},
		"spirit": {
			"spirit_stone_id": "ember_spirit_stone",
			"trigger": "direct_attack_sequence",
			"direct_attack_count": 3,
		},
		"loadout": {
			"melee_display_name": "Traveler Sword",
			"melee_condition": 72,
			"melee_maximum_condition": 100,
			"ranged_display_name": "Hunting Bow",
			"ranged_resource_id": "arrows",
			"ranged_resource_count": 7,
			"ranged_resource_maximum": 20,
			"shield_display_name": "Round Shield",
			"shield_condition": 84,
			"shield_maximum_condition": 100,
			"armor_display_name": "Traveler Coat",
			"armor_health_bonus": 0,
			"spirit_stone_display_name": "Ember Spirit Stone",
		},
	}


func _assert_field_pickup_view_models(receipt: RewardReceiptPresenter) -> void:
	var focus := receipt.build_field_pickup_view_model({
		"effect_type": "reduce_skill_cooldowns",
		"amount": 0.4,
		"affected_skill_count": 2,
		"display_name": "Focus Shard",
	})
	_expect(focus["title"] == "FOCUS RESTORED", "Focus pickup should use the Focus receipt title")
	_expect(
		focus["summary"] == "Focus Shard  2 cooldowns, up to -0.4s",
		"Focus pickup should show the affected count and truthful maximum recovery"
	)
	var supply := receipt.build_field_pickup_view_model({
		"effect_type": "refill_consumable",
		"amount": 1.0,
		"display_name": "Supply Charge",
	})
	_expect(supply["title"] == "SUPPLY RESTOCKED", "Supply pickup should use the Supply receipt title")
	_expect(supply["summary"] == "Supply Charge  +1 Consumable Charge", "Supply pickup should keep exact charges")
	var currency := receipt.build_field_pickup_view_model({
		"effect_type": "grant_currency",
		"amount": 3.0,
		"currency_id": "rusted_scrap",
		"display_name": "Iron Scrap Bundle",
	})
	_expect(currency["title"] == "MATERIAL COLLECTED", "Material pickup should use the Material receipt title")
	_expect(currency["summary"] == "Iron Scrap Bundle  +3 Iron Scrap", "Material pickup should keep exact grants")
	_expect(not String(currency["summary"]).contains("rusted_scrap"), "Currency receipt should not expose raw IDs")
	var arrows := receipt.build_field_pickup_view_model({
		"effect_type": "grant_ranged_supply",
		"amount": 4.0,
		"supply_id": "arrows",
		"display_name": "Arrow Bundle",
	})
	_expect(arrows["title"] == "ARROWS RESTOCKED", "Arrow pickup should use a specific supply title")
	_expect(arrows["summary"] == "Arrow Bundle  +4 Arrows", "Arrow receipt should keep exact supply")


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
		print("GAMEPLAY_HUD_VALIDATION_OK viewports=3 contextual_attack=paired field_pickup=signal>receipt>prompt")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
