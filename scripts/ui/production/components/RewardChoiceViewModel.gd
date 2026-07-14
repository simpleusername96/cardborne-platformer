class_name RewardChoiceViewModel
extends RefCounted

const StatPresentation = preload("res://scripts/player/PlayerStatPresentation.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")


static func for_level_upgrade(
	upgrade: MicroUpgradeDefinition,
	preview: Dictionary,
	current_stack: int,
	current_health: int,
	current_max_health: int
) -> Dictionary:
	var mechanics: Array[String] = []
	var changes: Dictionary = preview.get("changes", {})
	var stat_ids := changes.keys()
	stat_ids.sort()
	for stat_id_value in stat_ids:
		var stat_id := StringName(stat_id_value)
		var values: Dictionary = changes[stat_id_value]
		if stat_id == &"max_health":
			mechanics.append("Max health %s -> %s" % [
				StatPresentation.format_value(stat_id, float(values.get("before", 0.0))),
				StatPresentation.format_value(stat_id, float(values.get("after", 0.0))),
			])
		else:
			mechanics.append(StatPresentation.format_transition(
				stat_id,
				float(values.get("before", 0.0)),
				float(values.get("after", 0.0))
			))
	var heal := int(preview.get("heal", 0))
	if heal > 0:
		var health_before := int(preview.get("current_health_before", current_health))
		var maximum_after := int(preview.get("max_health_after", current_max_health))
		var health_after := int(preview.get(
			"current_health_after",
			mini(health_before + heal, maximum_after)
		))
		var restored := health_after - health_before
		mechanics.append("Current health %d -> %d%s" % [
			health_before,
			health_after,
			" (+%d restored)" % restored if restored > 0 else " (already full)",
		])
	if mechanics.is_empty():
		mechanics.append(String(preview.get("message", "Upgrade unavailable.")))
	var presentation := _upgrade_presentation(upgrade, changes)
	var footer := (
		"IMMEDIATE RECOVERY"
		if upgrade.recovery_choice
		else "STACK %d -> %d / %d" % [current_stack, current_stack + 1, upgrade.max_stacks]
	)
	var view := _base_view_model(
		upgrade.id,
		presentation["category"],
		"RUN UPGRADE",
		upgrade.display_name,
		upgrade.description,
		mechanics,
		footer,
		"ADD UPGRADE",
		presentation["glyph"],
		presentation["accent"]
	)
	view["enabled"] = bool(preview.get("ok", false))
	return view


static func for_card(
	card: CardDefinition,
	current_stack: int,
	next_stack: int
) -> Dictionary:
	var compatibility := "SHARED"
	if not card.compatibility.has(&"shared") and not card.compatibility.is_empty():
		compatibility = String(card.compatibility[0]).to_upper()
	var preview := _card_mechanics(card, next_stack)
	var mechanics: Array[String] = preview["lines"]
	mechanics.push_front("Stack %d -> %d / %d" % [
		current_stack,
		next_stack,
		card.max_stacks,
	])
	var view := _base_view_model(
		card.id,
		"%s CARD" % compatibility,
		String(card.rarity),
		card.display_name,
		card.description,
		mechanics,
		"NO COIN COST",
		"ADD CARD",
		&"card",
		_rarity_color(card.rarity)
	)
	view["enabled"] = bool(preview["complete"])
	return view


static func _upgrade_presentation(
	upgrade: MicroUpgradeDefinition,
	changes: Dictionary
) -> Dictionary:
	if upgrade.recovery_choice:
		return {"category": "RECOVERY", "glyph": &"recovery", "accent": Styles.MOSS}
	if changes.has("max_health"):
		return {"category": "SURVIVAL", "glyph": &"survival", "accent": Styles.MOSS}
	if changes.has("direct_damage_multiplier"):
		return {"category": "OFFENSE", "glyph": &"offense", "accent": Styles.AMBER}
	if changes.has("move_speed") or changes.has("air_acceleration"):
		return {"category": "MOBILITY", "glyph": &"mobility", "accent": Styles.CYAN}
	if changes.has("dash_cooldown"):
		return {"category": "TEMPO", "glyph": &"tempo", "accent": Color("c5b45c")}
	return {"category": "UPGRADE", "glyph": &"card", "accent": Styles.CYAN}


static func _base_view_model(
	id: StringName,
	category: String,
	rarity: String,
	title: String,
	description: String,
	mechanics: Array[String],
	footer: String,
	action: String,
	glyph: StringName,
	accent: Color
) -> Dictionary:
	return {
		"id": id,
		"category": category,
		"rarity": rarity,
		"title": title,
		"description": description,
		"value": "\n".join(mechanics),
		"footer": footer,
		"action": action,
		"glyph": glyph,
		"accent": accent,
		"enabled": id != &"",
	}


static func _card_mechanics(card: CardDefinition, next_stack: int) -> Dictionary:
	var lines: Array[String] = []
	var complete := true
	for effect in card.effects:
		if effect != null:
			var line := _format_card_effect(effect, next_stack)
			if line.is_empty():
				complete = false
				line = "Effect details unavailable"
			lines.append(line)
	if card.internal_cooldown > 0.0:
		lines.append("Internal cooldown %ss" % _number(card.internal_cooldown))
	return {"lines": lines, "complete": complete}


static func _format_card_effect(effect: CardEffectDefinition, stack: int) -> String:
	match effect.effect_type:
		&"repeat_hit":
			return "%s%% damage + %s%% stagger after %ss" % [
				_number(effect.damage_scale * 100.0),
				_number(effect.stagger_scale * 100.0),
				_number(effect.delay),
			]
		&"spawn_damage_trail":
			return "%d damage / %ss trail / %d hit per target" % [
				_stack_int(effect.damage_by_stack, stack),
				_number(effect.duration),
				effect.hits_per_target,
			]
		&"add_damage":
			return "+%d damage" % effect.damage
		&"add_stagger":
			return "+%d stagger" % effect.stagger
		&"area_damage":
			return "%d damage / %spx radius" % [
				effect.damage,
				_number(_stack_float(effect.radius_by_stack, stack)),
			]
		&"ground_shockwave":
			return "%d damage / %d stagger / %spx reach" % [
				effect.damage,
				effect.stagger,
				_number(effect.distance),
			]
		&"arm_next_heavy":
			return "%ss window / %s%% faster / uninterruptible" % [
				_number(effect.duration),
				_number((1.0 - effect.startup_scale) * 100.0),
			]
		&"split_projectile":
			return "%d arrows x %d damage / +/- %s degrees" % [
				effect.projectile_count,
				effect.damage,
				_number(effect.angle_degrees),
			]
		&"delayed_target_strike":
			return "%d damage after %ss" % [effect.damage, _number(effect.delay)]
		&"repeat_attack_path":
			return "Repeat resolved hits at %s%% damage" % _number(effect.damage_scale * 100.0)
		&"detonation_mark":
			return "%d damage / %ss mark / %spx range" % [
				effect.damage,
				_number(effect.duration),
				_number(effect.distance),
			]
		&"heal_player":
			return "Restore %d health" % effect.health
		&"grant_invulnerability":
			return "Invulnerable for %ss" % _number(effect.seconds)
		_:
			return ""


static func _stack_int(values: PackedInt32Array, stack: int) -> int:
	if values.is_empty():
		return 0
	return values[clampi(stack - 1, 0, values.size() - 1)]


static func _stack_float(values: PackedFloat32Array, stack: int) -> float:
	if values.is_empty():
		return 0.0
	return values[clampi(stack - 1, 0, values.size() - 1)]


static func _rarity_color(rarity: StringName) -> Color:
	match rarity:
		&"legendary":
			return Styles.AMBER
		&"rare":
			return Styles.CYAN
	return Styles.MOSS


static func _number(value: float) -> String:
	var formatted := "%.2f" % value
	while formatted.contains(".") and formatted.ends_with("0"):
		formatted = formatted.trim_suffix("0")
	return formatted.trim_suffix(".")
