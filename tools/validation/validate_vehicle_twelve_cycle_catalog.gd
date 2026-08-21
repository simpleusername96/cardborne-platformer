extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const Difficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const Tactics = preload("res://scripts/encounters/vehicle_collective_tactic_catalog.gd")
const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const FamilyTraits = preload("res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd")
const SpawnComposition = preload("res://scripts/encounters/vehicle_enemy_spawn_composition.gd")
const BossPhases = preload("res://scripts/bosses/vehicle_boss_phase_catalog.gd")
const BossPatterns = preload("res://scripts/bosses/vehicle_boss_patterns.gd")

var failures: Array[String] = []


func _init() -> void:
	var ids: Array[StringName] = []
	for number in range(1, 13):
		ids.append(StringName("stage_%d" % number))
	_expect(CombatStages.STAGE_IDS == ids, "the canonical registry contains twelve internal cycle IDs")
	_expect(CombatStages.QUOTAS == [90, 99, 108, 117, 126, 135, 144, 153, 162, 171, 180, 189], "quota progression is exactly 1.5x the previous sequence")
	_expect(CombatStages.AUTHORED_COUNTS == [260, 300, 340, 390, 440, 500, 560, 630, 700, 770, 840, 910], "authored populations are exact")
	_expect(Archetypes.validate_contract().is_empty(), "the fifteen family-tier actor catalog validates")
	_expect(FamilyTraits.validate_contract().is_empty(), "the five-family trait catalog validates")
	for index in ids.size():
		var stage_id := ids[index]
		var profile := CombatStages.profile(stage_id)
		_expect(not profile.is_empty(), "%s has a profile" % stage_id)
		_expect(bool(profile["has_boss"]), "%s has its quota-gated boss" % stage_id)
		_expect(not CombatStages.MOBILE_ROLES[index].is_empty(), "%s has an ordinary-enemy role arc" % stage_id)
		_validate_stage_packs(stage_id, index)
		_expect(not Tactics.assignment_for(index, 0, 3, 4).is_empty(), "%s has a tactic mapping" % stage_id)
	_expect(CombatStages.normalized_id(&"stage_13").is_empty(), "unknown stage IDs fail closed")
	_expect(StageCatalog.definition(&"stage_13").is_empty(), "catalog lookup fails closed")
	_expect(Difficulty.multipliers(12).is_empty(), "difficulty lookup fails closed")
	_expect(Difficulty.stage_index_from_id(&"stage_13") == -1, "unknown difficulty ID fails closed")
	_expect(Difficulty.HEALTH.size() == 12 and is_equal_approx(float(Difficulty.HEALTH[11]), 2.00), "cycle 12 has the final ordinary base health scale")
	_expect(is_equal_approx(Difficulty.boss_health(11), 136890.0), "cycle 12 has the final boss health")
	var expected_profiles: Array[StringName] = ids.duplicate()
	for boss_index in expected_profiles.size():
		var stage_id := ids[boss_index]
		_expect(CombatStages.boss_profile_id(stage_id) == expected_profiles[boss_index], "%s maps to its preserved boss arc" % stage_id)
		_expect(not BossPhases.definition(stage_id).is_empty(), "%s maps to a boss phase definition" % stage_id)
		_expect(not BossPatterns.sequence(stage_id).is_empty(), "%s maps to boss patterns" % stage_id)
	_expect(BossPhases.validate_contract().is_empty(), "all twelve boss phase packets validate")
	_finish()


func _validate_stage_packs(stage_id: StringName, stage_index: int) -> void:
	var definition := CombatStages.definition(stage_id)
	var authored_count := 0
	for packet_variant in Array(definition.get("packets", [])):
		var packet := Dictionary(packet_variant)
		var packs: Array = packet.get("packs", [])
		var squads: Array = packet.get("squads", [])
		_expect(packs.size() == squads.size(), "%s packet preserves one blueprint per pack" % stage_id)
		for pack_index in mini(packs.size(), squads.size()):
			var pack := Dictionary(packs[pack_index])
			var roles: Array = pack.get("roles", [])
			authored_count += roles.size()
			_expect(roles == Array(squads[pack_index]), "%s pack roles are the allocator input" % stage_id)
			_expect(roles.size() >= FamilyTraits.PACK_MIN_SIZE and roles.size() <= FamilyTraits.PACK_MAX_SIZE, "%s uses only 4-8 member packs" % stage_id)
			var family := StringName(pack.get("family", &""))
			var tier := int(pack.get("tier", 0))
			var trait_id := StringName(pack.get("trait", &""))
			_expect(tier == FamilyTraits.tier_for_stage(stage_index), "%s pack tier follows the four-stage ladder" % stage_id)
			_expect(FamilyTraits.trait_belongs_to_family(family, trait_id), "%s pack trait is family-exclusive" % stage_id)
			_expect(
				SpawnComposition.validate_pack(pack).is_empty(),
				"%s pack preserves legal per-enemy family and trait metadata" % stage_id
			)
	_expect(authored_count == int(CombatStages.AUTHORED_COUNTS[stage_index]), "%s family packs preserve authored population" % stage_id)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_TWELVE_CYCLE_CATALOG_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
