extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const FamilyTraits = preload("res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd")
const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")

var failures: Array[String] = []


func _initialize() -> void:
	for error in Archetypes.validate_contract():
		failures.append(error)
	for error in FamilyTraits.validate_contract():
		failures.append(error)
	_expect(Archetypes.ORDINARY_ARCHETYPES.size() == 15, "exactly fifteen ordinary family-tier IDs are live")
	for family in FamilyTraits.FAMILIES:
		for tier in range(1, 4):
			var archetype := FamilyTraits.archetype(family, tier)
			var definition := Archetypes.definition(archetype)
			_expect(StringName(definition.get("family", &"")) == family, "%s T%d keeps family identity" % [family, tier])
			_expect(int(definition.get("tier", 0)) == tier, "%s T%d keeps integer tier" % [family, tier])
			_expect(int(definition.get("size_percent", 0)) == [100, 125, 150][tier - 1], "%s T%d keeps percentage scale" % [family, tier])
			_expect(is_equal_approx(Archetypes.projectile_target_radius(archetype), 48.0), "%s T%d keeps the 48-unit projectile target" % [family, tier])
	for stage_index in CombatStages.STAGE_IDS.size():
		var definition := CombatStages.definition(CombatStages.STAGE_IDS[stage_index])
		for packet_variant in Array(definition.get("packets", [])):
			for pack_variant in Array(Dictionary(packet_variant).get("packs", [])):
				var pack := Dictionary(pack_variant)
				_expect(FamilyTraits.trait_belongs_to_family(StringName(pack["family"]), StringName(pack["trait"])), "authored trait belongs to its family")
	for family in FamilyTraits.FAMILIES:
		var weighted_counts := {&"base":0, &"trait_1":0, &"trait_2":0}
		var family_traits := FamilyTraits.traits(family)
		for pack_ordinal in 100:
			var trait_id := FamilyTraits.trait_for_pack(family, 0, pack_ordinal)
			if trait_id.is_empty():
				weighted_counts[&"base"] += 1
			elif trait_id == family_traits[0]:
				weighted_counts[&"trait_1"] += 1
			elif trait_id == family_traits[1]:
				weighted_counts[&"trait_2"] += 1
		_expect(
			int(weighted_counts[&"base"]) >= 30
				and int(weighted_counts[&"base"]) <= 50
				and int(weighted_counts[&"trait_1"]) >= 20
				and int(weighted_counts[&"trait_1"]) <= 40
				and int(weighted_counts[&"trait_2"]) >= 20
				and int(weighted_counts[&"trait_2"]) <= 40,
			"%s applies the base/trait1/trait2 4/3/3 weighted rollout" % family
		)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_FAMILY_TRAITS_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
