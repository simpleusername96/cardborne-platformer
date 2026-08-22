extends SceneTree

const CombatStages = preload("res://scripts/vehicle/stages/vehicle_combat_stages.gd")
const Composition = preload("res://scripts/encounters/vehicle_enemy_spawn_composition.gd")
const Runtime = preload("res://scripts/encounters/vehicle_encounter_runtime.gd")
const Generator = preload("res://scripts/vehicle/vehicle_field_layout_generator.gd")
const Difficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const FamilyTraits = preload("res://scripts/enemies/vehicle_enemy_family_trait_catalog.gd")

const SEEDS := [7, 0xC4A2B0, 99173]

var failures: Array[String] = []


func _initialize() -> void:
	_validate_onboarding_authoring()
	_validate_normal_bags()
	_validate_pack_trait_rollout()
	_validate_runtime_gates()
	_finish()


func _validate_onboarding_authoring() -> void:
	var packets: Array = CombatStages.definition(&"stage_1")["packets"]
	_expect(packets.size() >= 6, "stage 1 contains onboarding and normal packets")
	var expected_kinds: Array[StringName] = []
	for kind in [
		Composition.ONBOARDING_PURSUER,
		Composition.ONBOARDING_EMITTER,
		Composition.ONBOARDING_CHARGER,
		Composition.ONBOARDING_DEFENDER,
	]:
		for _index in 3:
			expected_kinds.append(kind)
	expected_kinds.append(Composition.ONBOARDING_BRIDGE)
	var actual_kinds: Array[StringName] = []
	var onboarding_units := 0
	for packet_index in 5:
		for pack_variant in Array(Dictionary(packets[packet_index]).get("packs", [])):
			var pack := Dictionary(pack_variant)
			actual_kinds.append(StringName(pack["composition_kind"]))
			onboarding_units += Array(pack["members"]).size()
			for member_variant in Array(pack["members"]):
				_expect(
					StringName(Dictionary(member_variant).get("trait", &"")) == &"",
					"onboarding identities are base-only"
				)
	_expect(actual_kinds == expected_kinds, "onboarding emits four three-squad lessons and one bridge")
	_expect(onboarding_units == 65, "onboarding replaces exactly 65 authored slots")
	var bridge_pack := Dictionary(Array(Dictionary(packets[4])["packs"])[0])
	_expect(
		StringName(bridge_pack["family"]) == &"coordinator"
			and int(bridge_pack["leader_member_index"]) == 0
			and StringName(Dictionary(Array(bridge_pack["members"])[0])["family"])
				== &"coordinator"
			and StringName(bridge_pack["tactic_id"]) == &"shepherd_pack",
		"the onboarding bridge is explicitly Coordinator-led"
	)
	var expected_triggers := [0, 15, 30, 45, 60]
	for packet_index in 5:
		var trigger := Dictionary(Dictionary(packets[packet_index])["trigger"])
		_expect(
			int(trigger.get("at", 0)) == expected_triggers[packet_index],
			"onboarding trigger %d uses the exact defeat gate" % packet_index
		)


func _validate_normal_bags() -> void:
	for seed in SEEDS:
		for stage_index in [0, 5, 11]:
			var source_packs: Array[Dictionary] = []
			var source_squads: Array[Array] = []
			for ordinal in 10:
				var pack := Composition.placeholder_pack(
					Composition.NORMAL,
					FamilyTraits.tier_for_stage(stage_index),
					6,
					ordinal
				)
				source_packs.append(pack)
				source_squads.append(Array(pack["roles"]).duplicate())
			var packets := Composition.compose_packets([{
				"id":"validation",
				"spawn_composition":true,
				"packs":source_packs,
				"squads":source_squads,
			}], stage_index, seed)
			var packs: Array = Dictionary(packets[0])["packs"]
			var pack_counts := {&"pursuer":0, &"charger":0, Composition.PAIRED:0}
			var primary_counts := {
				&"pursuer":0, &"charger":0, &"emitter":0,
				&"defender":0, &"coordinator":0,
			}
			var family_counts := {}
			var coordinator_packs := 0
			for pack_index in packs.size():
				var pack := Dictionary(packs[pack_index])
				_expect(
					Composition.validate_pack(pack).is_empty(),
					"seed %d stage %d pack %d satisfies composition invariants"
					% [seed, stage_index, pack_index]
				)
				var counts := _family_counts(pack)
				var pack_kind: StringName
				if int(counts.get(&"emitter", 0)) > 0:
					pack_kind = Composition.PAIRED
				elif int(counts.get(&"charger", 0)) > int(counts.get(&"pursuer", 0)):
					pack_kind = &"charger"
				else:
					pack_kind = &"pursuer"
				pack_counts[pack_kind] = int(pack_counts[pack_kind]) + 1
				if int(counts.get(&"coordinator", 0)) == 1:
					coordinator_packs += 1
				var primary_family := StringName(pack["family"])
				primary_counts[primary_family] = int(primary_counts[primary_family]) + 1
				var leader_index := int(pack["leader_member_index"])
				_expect(
					StringName(Dictionary(Array(pack["members"])[leader_index])["family"])
						== primary_family,
					"seed %d stage %d pack %d leader belongs to the primary family"
					% [seed, stage_index, pack_index]
				)
				for family in counts:
					family_counts[family] = int(family_counts.get(family, 0)) + int(counts[family])
			_expect(
				pack_counts == {&"pursuer":4, &"charger":3, Composition.PAIRED:3},
				"seed %d stage %d has an exact 4:3:3 normal pack bag" % [seed, stage_index]
			)
			_expect(coordinator_packs == 1, "each normal bag has exactly one coordinator overlay")
			_expect(
				int(primary_counts[&"emitter"]) == 2
					and int(primary_counts[&"defender"]) == 1
					and int(primary_counts[&"coordinator"]) == 1
					and int(primary_counts[&"pursuer"])
						+ int(primary_counts[&"charger"]) == 6,
				"each bag exposes two Emitter, one Defender, one Coordinator, and six close-range primary owners"
			)
			var coordinator_pack: Dictionary = {}
			for pack_variant in packs:
				if StringName(Dictionary(pack_variant)["family"]) == &"coordinator":
					coordinator_pack = Dictionary(pack_variant)
					break
			_expect(
				not coordinator_pack.is_empty()
					and int(coordinator_pack["leader_member_index"]) == 0
					and StringName(coordinator_pack["tactic_id"])
						== &"shepherd_pack",
				"the Coordinator overlay owns pack leadership and its shepherd tactic"
			)
			_expect(
				int(family_counts.get(&"emitter", 0)) == 9
					and int(family_counts.get(&"defender", 0)) == 9,
				"size-six normal bag keeps exact emitter-defender equality"
			)
			var first_counts := _family_counts(Dictionary(packs[0]))
			_expect(
				int(first_counts.get(&"emitter", 0)) == 0
					and int(first_counts.get(&"coordinator", 0)) == 0,
				"the continuation-splittable first pack has no atomic pair or coordinator"
			)


func _validate_pack_trait_rollout() -> void:
	for family in FamilyTraits.FAMILIES:
		for ordinal in 12:
			_expect(
				FamilyTraits.trait_for_pack(family, 0, ordinal).is_empty(),
				"cycle 1 keeps every %s pack base-only" % family
			)
		var seen := {}
		for group_index in 4:
			var trait_count := 0
			for ordinal in range(group_index * 3, group_index * 3 + 3):
				var trait_id := FamilyTraits.trait_for_pack(family, 4, ordinal)
				trait_count += 0 if trait_id.is_empty() else 1
				if not trait_id.is_empty():
					seen[trait_id] = true
			_expect(
				trait_count == 1,
				"later-cycle %s packs apply one trait per three-pack window" % family
			)
		_expect(
			seen.size() == 2,
			"later-cycle %s pack windows alternate both family traits" % family
		)


func _validate_runtime_gates() -> void:
	var layout := Generator.generate(0xC4A2B0, CombatStages.STAGE_IDS)
	_expect(layout != null, "onboarding runtime fixture has deterministic geometry")
	if layout == null:
		return
	var tactical = layout.tactical_layout(&"stage_1")
	var runtime := Runtime.new()
	runtime.reset_run()
	runtime.configure(
		&"stage_1",
		CombatStages.definition(&"stage_1")["packets"],
		Difficulty.HARD,
		tactical.ordinary_spawn_anchors,
		tactical.encounter_seed,
		tactical.geometry_snapshot,
		0
	)
	var all_spawns: Array[Dictionary] = []
	_pump_until_pack_count(runtime, tactical, 3, all_spawns)
	_expect(
		Array(runtime.debug_snapshot()["stage_emitted_packs"]).size() == 3,
		"the second lesson stays blocked before 15 defeats"
	)
	for gate in [15, 30, 45, 60]:
		while int(runtime.debug_snapshot()["run_ordinary_defeats"]) < gate:
			runtime.record_ordinary_defeat(&"pursuer")
		var target_packs: int = 3 + int(gate) / 5
		_pump_until_pack_count(runtime, tactical, target_packs, all_spawns)
	var records: Array = runtime.debug_snapshot()["stage_emitted_packs"]
	_expect(records.size() >= 14, "bridge admission unlocks the first normal pack")
	if records.size() >= 14:
		_expect(
			StringName(Dictionary(records[12])["composition_kind"])
				== Composition.ONBOARDING_BRIDGE
				and StringName(Dictionary(records[13])["composition_kind"])
				== Composition.NORMAL,
			"normal admission follows the bridge and never precedes it"
		)
	_expect(bool(runtime.debug_snapshot()["onboarding_bridge_admitted"]), "bridge admission is typed run-global state")
	for spec in all_spawns:
		var definition := Archetypes.definition(StringName(spec["role"]))
		_expect(
			StringName(spec.get("family", &""))
				== StringName(definition.get("family", &"")),
			"spawn specs keep per-enemy family metadata"
		)
		_expect(
			FamilyTraits.trait_belongs_to_family(
				StringName(spec.get("family", &"")),
				StringName(spec.get("family_trait", &""))
			),
			"spawn specs keep per-enemy trait metadata"
		)
		_expect(
			not StringName(spec.get("pack_family", &"")).is_empty()
				and FamilyTraits.trait_belongs_to_family(
					StringName(spec.get("pack_family", &"")),
					StringName(spec.get("pack_trait", &""))
				),
			"spawn specs carry explicit pack family and trait truth"
		)


func _pump_until_pack_count(
	runtime: VehicleEncounterRuntime,
	tactical,
	target: int,
	spawns: Array[Dictionary]
) -> void:
	var visible := Rect2(
		tactical.geometry_snapshot.player_start - Vector2(640.0, 360.0),
		Vector2(1280.0, 720.0)
	)
	for _step in 2000:
		var result := runtime.tick(
			0.05, 0, [], tactical.geometry_snapshot.player_start, visible
		)
		for spec in Array(result["spawns"]):
			spawns.append(Dictionary(spec))
		if Array(runtime.debug_snapshot()["stage_emitted_packs"]).size() >= target:
			return
	_expect(false, "runtime reached emitted-pack target %d" % target)


func _family_counts(pack: Dictionary) -> Dictionary:
	var counts := {}
	for member_variant in Array(pack.get("members", [])):
		var family := StringName(Dictionary(member_variant).get("family", &""))
		counts[family] = int(counts.get(family, 0)) + 1
	return counts


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_ENEMY_SPAWN_COMPOSITION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
