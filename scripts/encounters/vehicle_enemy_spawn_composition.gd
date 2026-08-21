class_name VehicleEnemySpawnComposition
extends RefCounted

## Pure deterministic enemy composition. It owns teaching templates, normal
## shuffle bags, per-family trait bags, and legal mixed-family membership.

const FamilyTraits = preload(
	"res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd"
)

const NORMAL: StringName = &"normal"
const ONBOARDING_PURSUER: StringName = &"onboarding_pursuer"
const ONBOARDING_EMITTER: StringName = &"onboarding_emitter"
const ONBOARDING_CHARGER: StringName = &"onboarding_charger"
const ONBOARDING_DEFENDER: StringName = &"onboarding_defender"
const ONBOARDING_BRIDGE: StringName = &"onboarding_bridge"
const PAIRED: StringName = &"emitter_defender"

const NORMAL_PACK_BAG: Array[StringName] = [
	&"pursuer", &"pursuer", &"pursuer", &"pursuer",
	&"charger", &"charger", &"charger",
	PAIRED, PAIRED, PAIRED,
]
const TRAIT_BAG_SIZE := 10


static func placeholder_pack(
	composition_kind: StringName,
	tier: int,
	pack_size: int,
	composition_ordinal: int
) -> Dictionary:
	var members := (
		_onboarding_members(composition_kind, tier)
		if composition_kind != NORMAL
		else _single_family_members(&"pursuer", tier, pack_size)
	)
	var pack := _pack_from_members(members, composition_kind, composition_ordinal)
	pack["pack_size"] = members.size()
	return pack


static func compose_packets(
	source_packets: Array[Dictionary],
	stage_index: int,
	seed: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var family_occurrences := {}
	for family in FamilyTraits.FAMILIES:
		family_occurrences[family] = 0
	var fallback_ordinal := 0
	for packet_variant in source_packets:
		var packet := Dictionary(packet_variant).duplicate(true)
		if not bool(packet.get("spawn_composition", false)):
			result.append(packet)
			continue
		var source_packs: Array = packet.get("packs", [])
		var source_squads: Array = packet.get("squads", [])
		var packs: Array[Dictionary] = []
		var squads: Array[Array] = []
		for squad_index in source_squads.size():
			var source_pack := (
				Dictionary(source_packs[squad_index])
				if squad_index < source_packs.size()
				else {}
			)
			var kind := StringName(source_pack.get("composition_kind", NORMAL))
			var ordinal := int(source_pack.get("composition_ordinal", fallback_ordinal))
			var pack_size := Array(source_squads[squad_index]).size()
			var tier := int(source_pack.get(
				"tier", FamilyTraits.tier_for_stage(stage_index)
			))
			var members := (
				_onboarding_members(kind, tier)
				if kind != NORMAL
				else _normal_members(
					stage_index, ordinal, tier, pack_size, seed, family_occurrences
				)
			)
			var pack := _pack_from_members(members, kind, ordinal)
			pack["pack_size"] = members.size()
			packs.append(pack)
			squads.append(Array(pack["roles"]).duplicate())
			fallback_ordinal = maxi(fallback_ordinal, ordinal + 1)
		packet["packs"] = packs
		packet["squads"] = squads
		result.append(packet)
	return result


static func normal_pack_types(seed: int, stage_index: int, bag_index: int) -> Array[StringName]:
	var values: Array[StringName] = NORMAL_PACK_BAG.duplicate()
	_shuffle(values, "%d:stage:%d:pack-bag:%d" % [seed, stage_index, bag_index])
	# Continuation code can split the first pack to fill six opening slots. Keep
	# every bag's first pack free of pair and coordinator atomicity concerns.
	if values[0] == PAIRED:
		for index in range(1, values.size()):
			if values[index] != PAIRED:
				var replacement := values[index]
				values[index] = values[0]
				values[0] = replacement
				break
	return values


static func coordinator_overlay_position(
	seed: int,
	stage_index: int,
	bag_index: int,
	bag: Array[StringName]
) -> int:
	var eligible: Array[int] = []
	for index in bag.size():
		if index > 0 and bag[index] in [&"pursuer", &"charger"]:
			eligible.append(index)
	if eligible.is_empty():
		return -1
	return eligible[_stable_index(
		"%d:stage:%d:coordinator:%d" % [seed, stage_index, bag_index],
		eligible.size()
	)]


static func trait_for_occurrence(
	family: StringName,
	occurrence: int,
	seed: int,
	stage_index: int
) -> StringName:
	var family_traits := FamilyTraits.traits(family)
	if family_traits.size() != 2:
		return &""
	var bag: Array[StringName] = [
		&"", &"", &"", &"",
		family_traits[0], family_traits[0], family_traits[0],
		family_traits[1], family_traits[1], family_traits[1],
	]
	var bag_index := maxi(0, occurrence) / TRAIT_BAG_SIZE
	_shuffle(
		bag,
		"%d:stage:%d:trait:%s:%d" % [seed, stage_index, String(family), bag_index]
	)
	return bag[posmod(occurrence, TRAIT_BAG_SIZE)]


static func member(pack: Dictionary, index: int, fallback_role: StringName) -> Dictionary:
	var members: Array = pack.get("members", [])
	if index >= 0 and index < members.size():
		return Dictionary(members[index]).duplicate(true)
	var fallback_family := StringName(pack.get("family", &"pursuer"))
	return {
		"role":fallback_role,
		"family":fallback_family,
		"tier":int(pack.get("tier", 1)),
		"trait":StringName(pack.get("trait", &"")),
		"escort_member_index":-1,
	}


static func split_for_maintenance(pack: Dictionary, maximum_members: int) -> Dictionary:
	var source: Array = pack.get("members", [])
	if source.is_empty() or maximum_members <= 0:
		return {}
	var units: Array[Array] = []
	var coordinator_pair_start := -1
	if (
		source.size() >= 2
		and StringName(Dictionary(source[-1]).get("family", &"")) == &"coordinator"
	):
		coordinator_pair_start = source.size() - 2
	var index := 0
	while index < source.size():
		if index == coordinator_pair_start:
			units.append([
				Dictionary(source[index]).duplicate(true),
				Dictionary(source[index + 1]).duplicate(true),
			])
			index += 2
			continue
		var entry := Dictionary(source[index])
		if (
			StringName(entry.get("family", &"")) == &"emitter"
			and index + 1 < source.size()
			and StringName(Dictionary(source[index + 1]).get("family", &""))
				== &"defender"
		):
			units.append([
				entry.duplicate(true),
				Dictionary(source[index + 1]).duplicate(true),
			])
			index += 2
			continue
		units.append([entry.duplicate(true)])
		index += 1
	var selected: Array[Dictionary] = []
	var remaining: Array[Dictionary] = []
	for unit in units:
		if selected.size() + unit.size() <= maximum_members:
			for entry in unit:
				selected.append(Dictionary(entry))
		else:
			for entry in unit:
				remaining.append(Dictionary(entry))
	if selected.is_empty():
		return {}
	_normalize_escort_indices(selected)
	_normalize_escort_indices(remaining)
	var kind := StringName(pack.get("composition_kind", NORMAL))
	var ordinal := int(pack.get("composition_ordinal", -1))
	return {
		"group":_pack_from_members(selected, kind, ordinal),
		"remainder":(
			_pack_from_members(remaining, kind, ordinal)
			if not remaining.is_empty() else {}
		),
	}


static func validate_pack(pack: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var members: Array = pack.get("members", [])
	var roles: Array = pack.get("roles", [])
	if members.size() != roles.size():
		errors.append("member and role counts differ")
		return errors
	var family_counts := {}
	for index in members.size():
		var entry := Dictionary(members[index])
		var family := StringName(entry.get("family", &""))
		family_counts[family] = int(family_counts.get(family, 0)) + 1
		if StringName(entry.get("role", &"")) != StringName(roles[index]):
			errors.append("member role differs from allocator role")
		if not FamilyTraits.trait_belongs_to_family(
			family, StringName(entry.get("trait", &""))
		):
			errors.append("member trait does not belong to family")
	if StringName(pack.get("composition_kind", NORMAL)) == NORMAL:
		var emitters := int(family_counts.get(&"emitter", 0))
		var defenders := int(family_counts.get(&"defender", 0))
		var coordinators := int(family_counts.get(&"coordinator", 0))
		if emitters != defenders:
			errors.append("normal emitter and defender counts differ")
		if coordinators > 1:
			errors.append("normal pack contains more than one coordinator")
		if coordinators == 1 and (
			emitters > 0
			or defenders > 0
			or int(family_counts.get(&"pursuer", 0))
				+ int(family_counts.get(&"charger", 0)) <= 0
		):
			errors.append("coordinator overlay has no eligible companion")
	return errors


static func _normal_members(
	stage_index: int,
	ordinal: int,
	tier: int,
	pack_size: int,
	seed: int,
	family_occurrences: Dictionary
) -> Array[Dictionary]:
	var bag_index := maxi(0, ordinal) / NORMAL_PACK_BAG.size()
	var bag_position := posmod(ordinal, NORMAL_PACK_BAG.size())
	var bag := normal_pack_types(seed, stage_index, bag_index)
	var pack_kind := bag[bag_position]
	var members: Array[Dictionary] = []
	if pack_kind == PAIRED:
		for _pair_index in pack_size / 2:
			var emitter_index := members.size()
			members.append(_base_member(&"emitter", tier))
			var defender := _base_member(&"defender", tier)
			defender["escort_member_index"] = emitter_index
			members.append(defender)
		if pack_size % 2 == 1:
			members.append(_base_member(&"pursuer", tier))
	else:
		members = _single_family_members(pack_kind, tier, pack_size)
		if bag_position == coordinator_overlay_position(seed, stage_index, bag_index, bag):
			members[-1] = _base_member(&"coordinator", tier)
	for entry in members:
		var family := StringName(entry["family"])
		var occurrence := int(family_occurrences.get(family, 0))
		entry["trait"] = trait_for_occurrence(
			family, occurrence, seed, stage_index
		)
		family_occurrences[family] = occurrence + 1
	return members


static func _onboarding_members(kind: StringName, tier: int) -> Array[Dictionary]:
	var families: Array[StringName] = []
	match kind:
		ONBOARDING_PURSUER:
			families = [&"pursuer", &"pursuer", &"pursuer", &"pursuer", &"pursuer"]
		ONBOARDING_EMITTER:
			families = [&"pursuer", &"pursuer", &"pursuer", &"emitter", &"emitter"]
		ONBOARDING_CHARGER:
			families = [&"pursuer", &"pursuer", &"emitter", &"charger", &"charger"]
		ONBOARDING_DEFENDER:
			families = [&"pursuer", &"pursuer", &"charger", &"emitter", &"defender"]
		ONBOARDING_BRIDGE:
			families = [&"pursuer", &"pursuer", &"charger", &"charger", &"coordinator"]
		_:
			return []
	var members: Array[Dictionary] = []
	for family in families:
		members.append(_base_member(family, tier))
	if kind == ONBOARDING_DEFENDER:
		members[-1]["escort_member_index"] = 3
	return members


static func _single_family_members(
	family: StringName, tier: int, count: int
) -> Array[Dictionary]:
	var members: Array[Dictionary] = []
	for _index in count:
		members.append(_base_member(family, tier))
	return members


static func _base_member(family: StringName, tier: int) -> Dictionary:
	return {
		"role":FamilyTraits.archetype(family, tier),
		"family":family,
		"tier":tier,
		"trait":&"",
		"escort_member_index":-1,
	}


static func _pack_from_members(
	members: Array[Dictionary],
	composition_kind: StringName,
	composition_ordinal: int
) -> Dictionary:
	var roles: Array[StringName] = []
	var primary_family: StringName = &"pursuer"
	var tier := 1
	if not members.is_empty():
		primary_family = StringName(members[0].get("family", &"pursuer"))
		tier = int(members[0].get("tier", 1))
	for entry in members:
		roles.append(StringName(entry["role"]))
		if StringName(entry["family"]) == &"emitter":
			primary_family = &"emitter"
	return {
		"composition_kind":composition_kind,
		"composition_ordinal":composition_ordinal,
		"family":primary_family,
		"tier":tier,
		"trait":&"",
		"tactic_id":FamilyTraits.tactic_for_family(primary_family),
		"roles":roles,
		"members":members.duplicate(true),
	}


static func _normalize_escort_indices(members: Array[Dictionary]) -> void:
	for member_index in members.size():
		var entry := members[member_index]
		entry["escort_member_index"] = (
			member_index - 1
			if StringName(entry.get("family", &"")) == &"defender"
			and member_index > 0
			and StringName(members[member_index - 1].get("family", &"")) == &"emitter"
			else -1
		)


static func _shuffle(values: Array[StringName], seed_text: String) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := _stable_index("%s:%d" % [seed_text, index], index + 1)
		var held := values[index]
		values[index] = values[swap_index]
		values[swap_index] = held


static func _stable_index(seed_text: String, size: int) -> int:
	return posmod(seed_text.hash(), maxi(1, size))
