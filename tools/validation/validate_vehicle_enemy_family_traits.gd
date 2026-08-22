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
	var reached_families := {}
	var reached_traits := {}
	for stage_index in CombatStages.STAGE_IDS.size():
		var definition := CombatStages.definition(CombatStages.STAGE_IDS[stage_index])
		for packet_variant in Array(definition.get("packets", [])):
			for pack_variant in Array(Dictionary(packet_variant).get("packs", [])):
				var pack := Dictionary(pack_variant)
				if StringName(pack.get("composition_kind", &"")) != &"normal":
					continue
				var family := StringName(pack["family"])
				var trait_id := StringName(pack["trait"])
				reached_families[family] = true
				if stage_index == 0:
					_expect(trait_id.is_empty(), "cycle 1 normal packs remain base-only")
				elif not trait_id.is_empty():
					reached_traits[trait_id] = true
				for member_variant in Array(pack["members"]):
					var member := Dictionary(member_variant)
					var expected_trait := (
						trait_id
						if StringName(member["family"]) == family else &""
					)
					_expect(
						StringName(member["trait"]) == expected_trait,
						"only owning-family actors carry the pack trait body"
					)
	_expect(reached_families.size() == 5, "all five primary pack families are authored")
	_expect(reached_traits.size() == 10, "all ten family traits are reachable in authored later cycles")
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
