class_name RewardChoiceViewModel
extends RefCounted

const StatPresentation = preload("res://scripts/player/PlayerStatPresentation.gd")
const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Text = preload("res://scripts/ui/localization/LocalizedText.gd")


static func for_level_upgrade(
	upgrade: MicroUpgradeDefinition,
	preview: Dictionary,
	current_stack: int,
	current_health: int,
	current_max_health: int,
	context: Node
) -> Dictionary:
	var mechanics: Array[String] = []
	var changes: Dictionary = preview.get("changes", {})
	var stat_ids := changes.keys()
	stat_ids.sort()
	for stat_id_value in stat_ids:
		var stat_id := StringName(stat_id_value)
		var values: Dictionary = changes[stat_id_value]
		mechanics.append(_t(context, "%s %s -> %s", [
			_t(context, StatPresentation.display_name(stat_id)),
			StatPresentation.format_value(stat_id, float(values.get("before", 0.0))),
			StatPresentation.format_value(stat_id, float(values.get("after", 0.0))),
		]))
	var heal := int(preview.get("heal", 0))
	if heal > 0:
		var health_before := int(preview.get("current_health_before", current_health))
		var maximum_after := int(preview.get("max_health_after", current_max_health))
		var health_after := int(preview.get(
			"current_health_after",
			mini(health_before + heal, maximum_after)
		))
		var restored := health_after - health_before
		mechanics.append(
			_t(
				context,
				"Current health %d -> %d (+%d restored)"
				if restored > 0
				else "Current health %d -> %d (already full)",
				[health_before, health_after, restored] if restored > 0 else [health_before, health_after]
			)
		)
	if mechanics.is_empty():
		mechanics.append(_t(context, preview.get("message", "Upgrade unavailable.")))
	var presentation := _upgrade_presentation(upgrade, changes)
	var footer := (
		_t(context, "IMMEDIATE RECOVERY")
		if upgrade.recovery_choice
		else _t(
			context,
			"STACK %d -> %d / %d",
			[current_stack, current_stack + 1, upgrade.max_stacks]
		)
	)
	var view := _base_view_model(
		upgrade.id,
		_t(context, presentation["category"]),
		_t(context, "RUN UPGRADE"),
		_t(context, upgrade.display_name),
		_t(context, upgrade.description),
		mechanics,
		footer,
		_t(context, "ADD UPGRADE"),
		presentation["glyph"],
		presentation["accent"]
	)
	view["enabled"] = bool(preview.get("ok", false))
	view["asset_id"] = _upgrade_asset_id(StringName(presentation["glyph"]))
	return view


static func for_card(
	card: CardDefinition,
	current_stack: int,
	next_stack: int,
	context: Node
) -> Dictionary:
	var preview := _card_mechanics(card, next_stack, context)
	var mechanics: Array[String] = preview["lines"]
	mechanics.push_front(_t(
		context,
		"Stack %d -> %d / %d",
		[current_stack, next_stack, card.max_stacks]
	))
	var view := _base_view_model(
		card.id,
		_t(context, "RUN CARD"),
		_t(context, String(card.rarity)),
		_t(context, card.display_name),
		_t(context, card.description),
		mechanics,
		_t(context, "NO COIN COST"),
		_t(context, "ADD CARD"),
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


static func _upgrade_asset_id(glyph: StringName) -> StringName:
	match glyph:
		&"survival", &"recovery":
			return &"health"
		&"mobility", &"tempo":
			return &"speed"
		&"offense":
			return &"force"
	return &"confirm"


static func _card_mechanics(
	card: CardDefinition,
	next_stack: int,
	context: Node
) -> Dictionary:
	var lines: Array[String] = []
	var complete := true
	for effect in card.effects:
		if effect != null:
			var line := _format_card_effect(effect, next_stack, context)
			if line.is_empty():
				complete = false
				line = _t(context, "Effect details unavailable")
			lines.append(line)
	if card.internal_cooldown > 0.0:
		lines.append(_t(
			context,
			"Internal cooldown %ss",
			[_number(card.internal_cooldown)]
		))
	return {"lines": lines, "complete": complete}


static func _format_card_effect(
	effect: CardEffectDefinition,
	stack: int,
	context: Node
) -> String:
	match effect.effect_type:
		&"repeat_hit":
			return _t(context, "%s%% damage + %s%% stagger after %ss", [
				_number(effect.damage_scale * 100.0),
				_number(effect.stagger_scale * 100.0),
				_number(effect.delay),
			])
		&"spawn_damage_trail":
			return _t(context, "%d damage / %ss trail / %d hit per target", [
				_stack_int(effect.damage_by_stack, stack),
				_number(effect.duration),
				effect.hits_per_target,
			])
		&"add_damage":
			return _t(context, "+%d damage", [effect.damage])
		&"add_stagger":
			return _t(context, "+%d stagger", [effect.stagger])
		&"area_damage":
			return _t(context, "%d damage / %spx radius", [
				effect.damage,
				_number(_stack_float(effect.radius_by_stack, stack)),
			])
		&"ground_shockwave":
			return _t(context, "%d damage / %d stagger / %spx reach", [
				effect.damage,
				effect.stagger,
				_number(effect.distance),
			])
		&"arm_next_heavy":
			return _t(context, "%ss window / %s%% faster / uninterruptible", [
				_number(effect.duration),
				_number((1.0 - effect.startup_scale) * 100.0),
			])
		&"split_projectile":
			return _t(context, "%d arrows x %d damage / +/- %s degrees", [
				effect.projectile_count,
				effect.damage,
				_number(effect.angle_degrees),
			])
		&"delayed_target_strike":
			return _t(context, "%d damage after %ss", [effect.damage, _number(effect.delay)])
		&"repeat_attack_path":
			return _t(
				context,
				"Repeat resolved hits at %s%% damage",
				[_number(effect.damage_scale * 100.0)]
			)
		&"detonation_mark":
			return _t(context, "%d damage / %ss mark / %spx range", [
				effect.damage,
				_number(effect.duration),
				_number(effect.distance),
			])
		&"heal_player":
			return _t(context, "Restore %d health", [effect.health])
		&"grant_invulnerability":
			return _t(context, "Invulnerable for %ss", [_number(effect.seconds)])
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


static func _t(context: Node, source_value: Variant, values: Array = []) -> String:
	return Text.resolve(context, source_value, values)
