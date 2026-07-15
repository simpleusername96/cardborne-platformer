class_name ProductionUIAssets
extends RefCounted

const EXPECTED_ASSET_COUNT := 52
const ROOT := "res://art/ui/production/"

const PATHS := {
	&"shell_main_menu": ROOT + "backgrounds/main_menu.png",
	&"shell_settings": ROOT + "backgrounds/settings.png",
	&"shell_hero_preparation": ROOT + "backgrounds/hero_preparation.png",
	&"shell_forge": ROOT + "backgrounds/forge.png",
	&"shell_run_result": ROOT + "backgrounds/run_result.png",
	&"portrait_traveler": ROOT + "illustrations/characters/traveler.png",
	&"equipment_traveler_sword": ROOT + "illustrations/equipment/traveler_sword.png",
	&"equipment_hunting_spear": ROOT + "illustrations/equipment/hunting_spear.png",
	&"equipment_hunting_bow": ROOT + "illustrations/equipment/hunting_bow.png",
	&"equipment_matchlock": ROOT + "illustrations/equipment/matchlock.png",
	&"equipment_round_shield": ROOT + "illustrations/equipment/round_shield.png",
	&"equipment_tower_shield": ROOT + "illustrations/equipment/tower_shield.png",
	&"equipment_traveler_coat": ROOT + "illustrations/equipment/traveler_coat.png",
	&"equipment_reinforced_coat": ROOT + "illustrations/equipment/reinforced_coat.png",
	&"spirit_ember": ROOT + "illustrations/spirit_stones/ember_spirit_stone.png",
	&"spirit_frost": ROOT + "illustrations/spirit_stones/frost_spirit_stone.png",
	&"consumable_small_potion": ROOT + "illustrations/consumables/small_potion.png",
	&"card_dash_wake": ROOT + "illustrations/cards/dash_wake.png",
	&"card_aerial_opener": ROOT + "illustrations/cards/aerial_opener.png",
	&"card_perfect_punish": ROOT + "illustrations/cards/perfect_punish.png",
	&"card_second_wind": ROOT + "illustrations/cards/second_wind.png",
	&"card_last_stand": ROOT + "illustrations/cards/last_stand.png",
	&"boss_slime_king": ROOT + "illustrations/bosses/slime_king.png",
	&"reward_boss_core": ROOT + "illustrations/rewards/boss_core.png",
	&"panel_slab": ROOT + "shapes/panel_slab.svg",
	&"panel_compact": ROOT + "shapes/panel_compact.svg",
	&"panel_card": ROOT + "shapes/panel_card.svg",
	&"banner_objective": ROOT + "shapes/banner_objective.svg",
	&"button_plate": ROOT + "shapes/button_plate.svg",
	&"slot_plate": ROOT + "shapes/slot_plate.svg",
	&"back": ROOT + "icons/icon_back.svg",
	&"settings": ROOT + "icons/icon_settings.svg",
	&"exit": ROOT + "icons/icon_exit.svg",
	&"melee": ROOT + "icons/icon_melee.svg",
	&"ranged": ROOT + "icons/icon_ranged.svg",
	&"shield": ROOT + "icons/icon_shield.svg",
	&"armor": ROOT + "icons/icon_armor.svg",
	&"spirit": ROOT + "icons/icon_spirit.svg",
	&"potion": ROOT + "icons/icon_potion.svg",
	&"scrap": ROOT + "icons/icon_scrap.svg",
	&"timber": ROOT + "icons/icon_timber.svg",
	&"fiber": ROOT + "icons/icon_fiber.svg",
	&"steel": ROOT + "icons/icon_steel.svg",
	&"fabric": ROOT + "icons/icon_fabric.svg",
	&"arrows": ROOT + "icons/icon_arrows.svg",
	&"cartridges": ROOT + "icons/icon_cartridges.svg",
	&"boss_core": ROOT + "icons/icon_boss_core.svg",
	&"speed": ROOT + "icons/icon_speed.svg",
	&"health": ROOT + "icons/icon_health.svg",
	&"force": ROOT + "icons/icon_force.svg",
	&"cache": ROOT + "icons/icon_cache.svg",
	&"confirm": ROOT + "icons/icon_confirm.svg",
}

const OWNER_ASSETS := {
	&"traveler": &"portrait_traveler",
	&"traveler_sword": &"equipment_traveler_sword",
	&"hunting_spear": &"equipment_hunting_spear",
	&"hunting_bow": &"equipment_hunting_bow",
	&"matchlock": &"equipment_matchlock",
	&"round_shield": &"equipment_round_shield",
	&"tower_shield": &"equipment_tower_shield",
	&"traveler_coat": &"equipment_traveler_coat",
	&"reinforced_coat": &"equipment_reinforced_coat",
	&"ember_spirit_stone": &"spirit_ember",
	&"frost_spirit_stone": &"spirit_frost",
	&"small_potion": &"consumable_small_potion",
	&"dash_wake": &"card_dash_wake",
	&"aerial_opener": &"card_aerial_opener",
	&"perfect_punish": &"card_perfect_punish",
	&"second_wind": &"card_second_wind",
	&"last_stand": &"card_last_stand",
	&"slime_king": &"boss_slime_king",
	&"boss_core": &"reward_boss_core",
}

const FALLBACKS := {
	&"portrait_traveler": &"melee",
	&"equipment_traveler_sword": &"melee",
	&"equipment_hunting_spear": &"melee",
	&"equipment_hunting_bow": &"ranged",
	&"equipment_matchlock": &"ranged",
	&"equipment_round_shield": &"shield",
	&"equipment_tower_shield": &"shield",
	&"equipment_traveler_coat": &"armor",
	&"equipment_reinforced_coat": &"armor",
	&"spirit_ember": &"spirit",
	&"spirit_frost": &"spirit",
	&"consumable_small_potion": &"potion",
	&"card_dash_wake": &"speed",
	&"card_aerial_opener": &"force",
	&"card_perfect_punish": &"force",
	&"card_second_wind": &"health",
	&"card_last_stand": &"health",
	&"boss_slime_king": &"boss_core",
	&"reward_boss_core": &"boss_core",
}

const DISPOSITIONS := {
	&"shell_main_menu": &"runtime",
	&"shell_settings": &"contextual",
	&"shell_hero_preparation": &"runtime",
	&"shell_forge": &"deferred",
	&"shell_run_result": &"runtime",
	&"portrait_traveler": &"runtime",
	&"equipment_traveler_sword": &"runtime",
	&"equipment_hunting_spear": &"runtime",
	&"equipment_hunting_bow": &"runtime",
	&"equipment_matchlock": &"runtime",
	&"equipment_round_shield": &"runtime",
	&"equipment_tower_shield": &"runtime",
	&"equipment_traveler_coat": &"runtime",
	&"equipment_reinforced_coat": &"runtime",
	&"spirit_ember": &"runtime",
	&"spirit_frost": &"runtime",
	&"consumable_small_potion": &"runtime",
	&"card_dash_wake": &"runtime",
	&"card_aerial_opener": &"runtime",
	&"card_perfect_punish": &"runtime",
	&"card_second_wind": &"runtime",
	&"card_last_stand": &"runtime",
	&"boss_slime_king": &"runtime",
	&"reward_boss_core": &"runtime",
	&"panel_slab": &"deferred",
	&"panel_compact": &"deferred",
	&"panel_card": &"deferred",
	&"banner_objective": &"deferred",
	&"button_plate": &"deferred",
	&"slot_plate": &"deferred",
	&"back": &"deferred",
	&"settings": &"deferred",
	&"exit": &"deferred",
	&"melee": &"fallback",
	&"ranged": &"fallback",
	&"shield": &"fallback",
	&"armor": &"fallback",
	&"spirit": &"fallback",
	&"potion": &"fallback",
	&"scrap": &"deferred",
	&"timber": &"deferred",
	&"fiber": &"deferred",
	&"steel": &"deferred",
	&"fabric": &"deferred",
	&"arrows": &"deferred",
	&"cartridges": &"deferred",
	&"boss_core": &"fallback",
	&"speed": &"fallback",
	&"health": &"fallback",
	&"force": &"fallback",
	&"cache": &"deferred",
	&"confirm": &"deferred",
}

const DISPOSITION_REASONS := {
	&"shell_settings": "Shell-only background; in-run Settings preserves the live stage.",
	&"shell_forge": "Retained for a measured internal crop; full-screen in-run use was rejected.",
	&"panel_slab": "Deferred to the shared Theme and measured NinePatch pass.",
	&"panel_compact": "Deferred to the shared Theme and measured NinePatch pass.",
	&"panel_card": "Deferred to the shared Theme and measured NinePatch pass.",
	&"banner_objective": "Deferred to the HUD composition pass.",
	&"button_plate": "Deferred to the shared Theme control-state pass.",
	&"slot_plate": "Deferred to the HUD and preparation slot pass.",
	&"back": "Deferred to the shell Theme pass; text navigation remains authoritative.",
	&"settings": "Deferred to the shell Theme pass; text navigation remains authoritative.",
	&"exit": "Deferred to the destructive-action hierarchy pass.",
	&"scrap": "Deferred to the merchant/material presentation pass.",
	&"timber": "Deferred to the merchant/material presentation pass.",
	&"fiber": "Deferred to the merchant/material presentation pass.",
	&"steel": "Deferred to the merchant/material presentation pass.",
	&"fabric": "Deferred to the merchant/material presentation pass.",
	&"arrows": "Deferred to the merchant and HUD supply pass.",
	&"cartridges": "Deferred to the merchant and HUD supply pass.",
	&"cache": "Deferred to the interaction and reward-receipt pass.",
	&"confirm": "Deferred to the shared focus/confirmation state pass.",
}


static func all_asset_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for asset_id in PATHS:
		ids.append(StringName(asset_id))
	ids.sort()
	return ids


static func asset_path(asset_id: StringName) -> String:
	return String(PATHS.get(asset_id, ""))


static func asset_id_for_owner(owner_id: StringName) -> StringName:
	return StringName(OWNER_ASSETS.get(owner_id, &""))


static func fallback_asset_id(asset_id: StringName) -> StringName:
	return StringName(FALLBACKS.get(asset_id, &""))


static func disposition(asset_id: StringName) -> StringName:
	return StringName(DISPOSITIONS.get(asset_id, &""))


static func disposition_reason(asset_id: StringName) -> String:
	return String(DISPOSITION_REASONS.get(asset_id, ""))


static func texture(asset_id: StringName, use_fallback: bool = true) -> Texture2D:
	var path := asset_path(asset_id)
	if not path.is_empty() and ResourceLoader.exists(path):
		var resource := load(path)
		if resource is Texture2D:
			return resource as Texture2D
	if use_fallback:
		var fallback := fallback_asset_id(asset_id)
		if fallback != &"" and fallback != asset_id:
			return texture(fallback, false)
	return null


static func texture_for_owner(
	owner_id: StringName,
	default_asset_id: StringName = &""
) -> Texture2D:
	var asset_id := asset_id_for_owner(owner_id)
	if asset_id == &"":
		asset_id = default_asset_id
	return texture(asset_id) if asset_id != &"" else null
