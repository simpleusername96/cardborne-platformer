class_name VehicleProgressionTelemetryCapture
extends RefCounted

## Deterministic full-route progression evidence. It replays the production
## encounter composition and XP owners, but deliberately does not invent human
## card-selection time.

const SCHEMA_VERSION := 1
const FIXED_LAYOUT_SEED := 0xC4A2B0
const STAGE_10_TARGET_LEVEL := 50
const STAGE_10_TOLERANCE := 2
const BuildIdentity = preload("res://scripts/diagnostics/vehicle_build_identity.gd")
const ExperienceRuntime = preload(
	"res://scripts/progression/vehicle_experience_runtime.gd"
)
const FieldDropRules = preload(
	"res://scripts/rewards/vehicle_field_drop_rules.gd"
)
const Catalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const EnemyArchetypes = preload(
	"res://scripts/enemies/vehicle_enemy_archetypes.gd"
)
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SpawnComposition = preload(
	"res://scripts/encounters/vehicle_enemy_spawn_composition.gd"
)
const LayoutGenerator = preload(
	"res://scripts/vehicle/vehicle_field_layout_generator.gd"
)


static func identity_matches_expected(
	identity: Dictionary,
	expected_commit: String,
	expected_fingerprint: String
) -> bool:
	return (
		BuildIdentity.is_complete(identity)
		and String(identity.get("source_cleanliness", "")) == "clean"
		and expected_commit.length() == 40
		and expected_commit.is_valid_hex_number()
		and expected_fingerprint.length() == 64
		and expected_fingerprint.is_valid_hex_number()
		and String(identity.get("commit", "")).to_lower()
			== expected_commit.to_lower()
		and String(identity.get("content_fingerprint", "")).to_lower()
			== expected_fingerprint.to_lower()
	)


func build(evidence_id: String, identity: Dictionary) -> Dictionary:
	if evidence_id.is_empty() or not BuildIdentity.is_complete(identity):
		return {}
	var layout = LayoutGenerator.generate(FIXED_LAYOUT_SEED, Catalog.STAGE_IDS)
	if layout == null:
		return {}
	Catalog.activate_field(layout.field_id)
	var run_tactical = layout.tactical_layout(Catalog.STAGE_IDS[0])
	if run_tactical == null:
		return {}
	var runtime := ExperienceRuntime.new()
	var stages: Array[Dictionary] = []
	var cumulative_xp := 0
	var cumulative_upgrades := 0
	var trace_complete := true
	for stage_index in Catalog.STAGE_IDS.size():
		var stage_id: StringName = Catalog.STAGE_IDS[stage_index]
		var packets := SpawnComposition.compose_packets(
			Catalog.packets(stage_id),
			stage_index,
			run_tactical.encounter_seed
		)
		var trace := _quota_limited_defeat_trace(
			packets, Catalog.quota(stage_id)
		)
		if int(trace.get("defeats", 0)) != Catalog.quota(stage_id):
			trace_complete = false
			break
		# The connected run keeps the initial field objects. Cycle continuation
		# does not repopulate a new tactical layout's authored pickups.
		var authored_xp := (
			_authored_pickup_experience(run_tactical.pickup_blueprint())
			if stage_index == 0 else 0
		)
		var enemy_xp := int(trace.get("enemy_xp", 0))
		var stage_xp := enemy_xp + authored_xp
		var level_before := runtime.run_level
		runtime.spawn_shard(Vector2.ZERO, stage_xp, &"progression_capture")
		var receipt := runtime.advance(0.0, Vector2.ZERO, 100.0, 0.0)
		var levels_gained := runtime.run_level - level_before
		if int(receipt.get("experience", 0)) != stage_xp:
			trace_complete = false
			break
		while runtime.consume_pending_level():
			pass
		cumulative_xp += stage_xp
		cumulative_upgrades += levels_gained
		stages.append({
			"stage_id":String(stage_id),
			"stage_number":stage_index + 1,
			"ordinary_defeats":int(trace["defeats"]),
			"family_defeats":Dictionary(trace["family_defeats"]).duplicate(),
			"trait_defeats":Dictionary(trace["trait_defeats"]).duplicate(),
			"enemy_xp":enemy_xp,
			"authored_pickup_xp":authored_xp,
			"stage_xp":stage_xp,
			"cumulative_xp":cumulative_xp,
			"level_before":level_before,
			"level_reached":runtime.run_level,
			"upgrades_opened":levels_gained,
			"upgrades_confirmed":levels_gained,
			"cumulative_upgrades":cumulative_upgrades,
			"experience_carried":runtime.experience,
			"next_requirement":runtime.required_experience(),
			"modal_timing_measured":false,
			"modal_seconds":null,
			"last_confirmation_seconds":null,
		})
	var stage_10_level := (
		int(stages[9].get("level_reached", 0)) if stages.size() >= 10 else 0
	)
	var final_level := (
		int(stages[-1].get("level_reached", 0)) if not stages.is_empty() else 0
	)
	var target_checks := {
		"stage_10_within_two_levels":abs(stage_10_level - STAGE_10_TARGET_LEVEL)
			<= STAGE_10_TOLERANCE,
		"stage_10_level":stage_10_level,
		"stage_10_target":STAGE_10_TARGET_LEVEL,
		"final_level":final_level,
	}
	return {
		"schema_version":SCHEMA_VERSION,
		"kind":"progression_telemetry_capture",
		"evidence_id":evidence_id,
		"build_identity":identity.duplicate(true),
		"provenance":{
			"schema_version":1,
			"artifact_kind":"progression_telemetry_capture",
			"scenario":"deterministic_authored_defeat_trace",
			"layout_seed":FIXED_LAYOUT_SEED,
			"boss_xp_included":false,
			"boss_add_xp_included":false,
			"authored_map_xp_policy":"collect_initial_field_once",
			"encounter_seed_policy":"connected_run_initial_tactical_layout",
			"defeat_order":"composed_packet_member_order",
			"modal_timing_policy":"not_measured",
			"utc_finished":Time.get_datetime_string_from_system(true, true),
		},
		"stages":stages,
		"run":{
			"xp_collected":cumulative_xp,
			"level_reached":final_level,
			"modal_opens":cumulative_upgrades,
			"upgrades_confirmed":cumulative_upgrades,
			"modal_timing_measured":false,
			"modal_seconds":null,
		},
		"acceptance":{
			"capture_valid":trace_complete
				and stages.size() == Catalog.STAGE_IDS.size()
				and cumulative_upgrades == maxi(0, final_level - 1),
			"target_checks":target_checks,
		},
	}


func _quota_limited_defeat_trace(
	packets: Array[Dictionary], quota: int
) -> Dictionary:
	var defeats := 0
	var enemy_xp := 0
	var family_defeats := {}
	var trait_defeats := {"base":0}
	for packet in packets:
		for pack_variant in Array(packet.get("packs", [])):
			for member_variant in Array(Dictionary(pack_variant).get("members", [])):
				if defeats >= quota:
					break
				var member := Dictionary(member_variant)
				var definition := EnemyArchetypes.definition(
					StringName(member.get("role", &"ordinary_pursuer_t1"))
				)
				var enemy := EnemyState.new()
				enemy.role = StringName(definition.get("behavior", &"ordinary_edge_01"))
				enemy.health_class = StringName(
					definition.get("health_class", &"standard")
				)
				enemy.family = StringName(member.get("family", &"pursuer"))
				enemy.family_trait = StringName(member.get("trait", &""))
				enemy_xp += FieldDropRules.experience_for_enemy(enemy)
				family_defeats[enemy.family] = int(
					family_defeats.get(enemy.family, 0)
				) + 1
				var trait_key := (
					"base" if enemy.family_trait.is_empty() else String(enemy.family_trait)
				)
				trait_defeats[trait_key] = int(
					trait_defeats.get(trait_key, 0)
				) + 1
				defeats += 1
			if defeats >= quota:
				break
		if defeats >= quota:
			break
	return {
		"defeats":defeats,
		"enemy_xp":enemy_xp,
		"family_defeats":family_defeats,
		"trait_defeats":trait_defeats,
	}


func _authored_pickup_experience(pickups: Array[Dictionary]) -> int:
	var result := 0
	for pickup in pickups:
		if StringName(pickup.get("kind", &"")) == &"experience_shard":
			result += int(pickup.get("experience", 0))
	return result
