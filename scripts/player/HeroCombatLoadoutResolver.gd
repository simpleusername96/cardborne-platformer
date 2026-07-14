class_name HeroCombatLoadoutResolver
extends RefCounted

const RuntimeResolver = preload(
	"res://scripts/progression/EquipmentRuntimeResolver.gd"
)


static func resolve(
	hero: HeroDefinition,
	profile: ProfileData,
	catalog: EquipmentProgressionCatalog
) -> Dictionary:
	if hero == null or profile == null or catalog == null:
		return _invalid(&"missing_source", "Hero combat loadout source is unavailable.")
	if String(hero.id) != profile.hero_id:
		return _invalid(&"hero_mismatch", "Profile does not belong to this hero.")

	var resolved_models: Dictionary = {}
	for slot_id in ["melee", "ranged", "shield", "armor"]:
		var model_id := StringName(profile.hero_loadout.get(slot_id, ""))
		var model := catalog.get_model(model_id)
		var raw_state: Variant = profile.crafted_equipment.get(String(model_id), null)
		if model == null or String(model.slot) != slot_id or not raw_state is Dictionary:
			return _invalid(
				&"invalid_equipment",
				"Hero %s equipment is unavailable or uncrafted." % slot_id
			)
		var runtime := RuntimeResolver.resolve(model, raw_state)
		if not bool(runtime.get("ok", false)):
			return _invalid(
				&"invalid_equipment_state",
				"Hero %s equipment state is invalid." % slot_id
			)
		resolved_models[slot_id] = {"model": model, "runtime": runtime}

	var melee := resolved_models["melee"] as Dictionary
	var ranged := resolved_models["ranged"] as Dictionary
	var shield := resolved_models["shield"] as Dictionary
	var armor := resolved_models["armor"] as Dictionary
	var melee_attack := _resolved_attack(melee["model"], melee["runtime"])
	var ranged_attack := _resolved_attack(ranged["model"], ranged["runtime"])
	if melee_attack == null or ranged_attack == null:
		return _invalid(&"missing_attack", "Equipped combat model has no attack definition.")

	var hero_stats := hero.to_base_stats_dictionary()
	var armor_runtime: Dictionary = armor["runtime"]
	hero_stats["max_health"] = (
		int(hero_stats.get("max_health", 5))
		+ int(armor_runtime.get("max_health_bonus", 0))
	)
	hero_stats["dash_cooldown"] = (
		float(hero_stats.get("dash_cooldown", 0.45))
		+ float(armor_runtime.get("dash_cooldown_addition_seconds", 0.0))
	)
	hero_stats["knockback_received_multiplier"] = (
		1.0 - float(armor_runtime.get("knockback_reduction_fraction", 0.0))
	)

	var ranged_runtime: Dictionary = ranged["runtime"]
	var resource_id := String(ranged_runtime.get("ranged_resource_id", ""))
	var shield_runtime: Dictionary = shield["runtime"]
	var spirit_id := StringName(profile.hero_loadout.get("spirit_stone", ""))
	var spirit := catalog.get_spirit_stone(spirit_id)
	if spirit == null or not profile.unlocked_spirit_stones.has(String(spirit_id)):
		return _invalid(&"invalid_spirit_stone", "Equipped Spirit Stone is unavailable.")
	return {
		"ok": true,
		"hero_id": String(hero.id),
		"display_name": hero.display_name,
		"visual_color": hero.visual_color,
		"stats": hero_stats,
		"loadout": profile.hero_loadout.duplicate(true),
		"melee": {
			"model": melee["model"],
			"runtime": melee["runtime"].duplicate(true),
			"attack": melee_attack,
			"intent_policy": {
				"tool_id": (melee["model"] as EquipmentModelDefinition).id,
				"hitbox_size": melee_attack.hitbox_size,
				"hitbox_offset": melee_attack.hitbox_offset,
			},
		},
		"ranged": {
			"model": ranged["model"],
			"runtime": ranged_runtime.duplicate(true),
			"attack": ranged_attack,
			"intent_policy": {
				"tool_id": (ranged["model"] as EquipmentModelDefinition).id,
				"range": ranged_attack.projectile_range,
				"resource_id": StringName(resource_id),
				"resource_cost": 1,
				"requires_line_of_sight": true,
			},
			"resource_count": int(profile.ranged_supplies.get(resource_id, 0)),
		},
		"shield": {
			"model": shield["model"],
			"runtime": shield_runtime.duplicate(true),
			"defense_policy": _shield_policy(shield["model"], shield_runtime),
		},
		"armor": {
			"model": armor["model"],
			"runtime": armor_runtime.duplicate(true),
		},
		"spirit_stone": spirit,
	}


static func _resolved_attack(
	model: EquipmentModelDefinition,
	runtime: Dictionary
) -> AttackDefinition:
	if model == null or model.attack_definition == null:
		return null
	var attack := model.attack_definition.duplicate(true) as AttackDefinition
	attack.base_damage = int(runtime.get("damage", attack.base_damage))
	attack.stagger = int(runtime.get("stagger_damage", attack.stagger))
	attack.startup_time = float(runtime.get("startup_seconds", attack.startup_time))
	attack.recovery_time = float(runtime.get("recovery_seconds", attack.recovery_time))
	attack.cooldown = maxf(attack.cooldown, attack.total_duration())
	return attack


static func _shield_policy(
	model: EquipmentModelDefinition,
	runtime: Dictionary
) -> Dictionary:
	return {
		"tool_id": model.id,
		"startup_time": float(runtime.get("startup_seconds", 0.0)),
		"recovery_time": float(runtime.get("recovery_seconds", 0.0)),
		"guard_angle_degrees": float(runtime.get("guard_angle_degrees", 0.0)),
		"precise_window": float(runtime.get("precise_guard_window_seconds", 0.0)),
		"stability": int(runtime.get("guard_stability", 0)),
		"condition": int(runtime.get("condition", 0)),
		"normal_condition_cost": int(runtime.get("normal_block_condition_cost", 0)),
		"heavy_condition_cost": int(runtime.get("heavy_block_condition_cost", 0)),
		"precise_condition_cost_scale": 0.0,
		"guard_move_speed_multiplier": float(runtime.get("guard_move_speed_multiplier", 1.0)),
		"blocks_jump_while_guarding": bool(runtime.get("blocks_jump_while_guarding", false)),
	}


static func _invalid(code: StringName, message: String) -> Dictionary:
	return {"ok": false, "code": String(code), "message": message}
