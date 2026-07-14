extends SceneTree

const HERO := preload("res://data/hero/traveler.tres")
const CARD_CATALOG := preload("res://data/cards/card_catalog.tres")
const EQUIPMENT_CATALOG := preload(
	"res://data/equipment/equipment_progression_catalog.tres"
)
const PROGRESSION_CATALOG := preload("res://data/progression/run_progression_catalog.tres")
const REWARD_CATALOG := preload("res://data/rewards/reward_catalog.tres")
const ENEMY_CATALOG := preload("res://data/enemies/enemy_catalog.tres")
const HAZARD_CATALOG := preload("res://data/hazards/hazard_catalog.tres")
const STAGES: Array[Dictionary] = [
	{
		"profile": preload("res://data/generation/ruin_approach_profile.tres"),
		"rooms": preload("res://data/generation/lower_ruins_room_catalog.tres"),
		"room_count": 10,
	},
	{
		"profile": preload("res://data/generation/flooded_works_profile.tres"),
		"rooms": preload("res://data/generation/flooded_works_room_catalog.tres"),
		"room_count": 9,
	},
	{
		"profile": preload("res://data/generation/broken_sanctum_profile.tres"),
		"rooms": preload("res://data/generation/broken_sanctum_room_catalog.tres"),
		"room_count": 11,
	},
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_catalogs()
	_validate_content_counts()
	_validate_live_ids()
	_validate_enemy_rewards()
	_validate_stage_references()
	_validate_generation_smoke()
	_expect(
		not DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path("res://data/design/first_slice")
		),
		"retired first-slice JSON directory must not return"
	)
	_finish()


func _validate_catalogs() -> void:
	_append_errors(HERO.validate_definition(), "Traveler definition")
	_append_errors(CARD_CATALOG.validate_catalog(), "Card catalog")
	_append_errors(EQUIPMENT_CATALOG.validate_catalog(), "Equipment catalog")
	_append_errors(PROGRESSION_CATALOG.validate_catalog(), "Progression catalog")
	_append_errors(REWARD_CATALOG.validate_catalog(), "Reward catalog")
	_append_errors(ENEMY_CATALOG.validate_catalog(), "Enemy catalog")
	_append_errors(HAZARD_CATALOG.validate_catalog(), "Hazard catalog")
	for stage in STAGES:
		var profile := stage["profile"] as StageProfile
		var rooms := stage["rooms"] as RoomCatalog
		_append_errors(profile.validate_definition(), "%s profile" % profile.id)
		_append_errors(rooms.validate_catalog(), "%s rooms" % profile.id)


func _validate_content_counts() -> void:
	_expect(String(HERO.id) == "traveler", "production needs one Traveler hero")
	_expect(CARD_CATALOG.cards.size() == 5, "production needs five live cards")
	_expect(EQUIPMENT_CATALOG.models.size() == 8, "production needs eight equipment models")
	_expect(EQUIPMENT_CATALOG.spirit_stones.size() == 2, "production needs two Spirit Stones")
	_expect(REWARD_CATALOG.tables.size() == 17, "production needs seventeen reward tables")
	_expect(ENEMY_CATALOG.archetypes.size() == 6, "first run needs six enemy archetypes")
	_expect(ENEMY_CATALOG.variants.size() == 14, "production needs fourteen enemy variants")
	_expect(ENEMY_CATALOG.tuning_profiles.size() == 3, "first run needs three tuning profiles")
	_expect(HAZARD_CATALOG.definitions.size() == 4, "first run needs four core hazards")
	_expect(
		PROGRESSION_CATALOG.level_xp_totals == PackedInt32Array([0, 20, 55, 100, 145, 185]),
		"run-level curve should match accepted complete-run tuning"
	)
	for stage in STAGES:
		var rooms := stage["rooms"] as RoomCatalog
		_expect(
			rooms.rooms.size() == int(stage["room_count"]),
			"%s should expose its exact authored room count" % rooms.id
		)


func _validate_live_ids() -> void:
	for card in CARD_CATALOG.cards:
		for compatibility_id in card.compatibility:
			_expect(
				compatibility_id in [&"shared", HERO.id],
				"card %s has unknown compatibility %s" % [card.id, compatibility_id]
			)


func _validate_enemy_rewards() -> void:
	for variant in ENEMY_CATALOG.variants:
		_expect(
			REWARD_CATALOG.get_table(variant.drop_source_id) != null,
			"enemy variant %s has missing drop source %s"
			% [variant.id, variant.drop_source_id]
		)
	for table in REWARD_CATALOG.tables:
		_expect(
			table.equipment_pool_id == &"" and is_zero_approx(table.equipment_pool_chance),
			"reward table %s should not use a legacy equipment discovery pool" % table.id
		)


func _validate_stage_references() -> void:
	for stage in STAGES:
		var profile := stage["profile"] as StageProfile
		var rooms := stage["rooms"] as RoomCatalog
		for archetype_id in profile.eligible_enemy_archetypes:
			_expect(
				ENEMY_CATALOG.get_archetype_by_id(archetype_id) != null,
				"stage %s has unknown enemy archetype %s" % [profile.id, archetype_id]
			)
			var has_stage_variant := false
			for variant in ENEMY_CATALOG.variants:
				has_stage_variant = has_stage_variant or (
					variant.stage_id == profile.id and variant.archetype_id == archetype_id
				)
			_expect(
				has_stage_variant,
				"stage %s has no variant for %s" % [profile.id, archetype_id]
			)
		for hazard_id in profile.eligible_hazards:
			_expect(
				HAZARD_CATALOG.get_hazard(hazard_id) != null,
				"stage %s has unknown hazard %s" % [profile.id, hazard_id]
			)
		for room in rooms.rooms:
			_expect(
				room.stage_tags.has(profile.id),
				"room %s should declare stage %s" % [room.id, profile.id]
			)
			for anchor in room.reward_anchors:
				for table_id in anchor.eligible_table_ids:
					_expect(
						REWARD_CATALOG.get_table(table_id) != null,
						"room %s reward anchor has unknown table %s" % [room.id, table_id]
					)
			for anchor in room.hazard_anchors:
				for hazard_id in anchor.allowed_hazard_ids:
					_expect(
						HAZARD_CATALOG.get_hazard(hazard_id) != null,
						"room %s hazard anchor has unknown hazard %s" % [room.id, hazard_id]
					)


func _validate_generation_smoke() -> void:
	var limits := MovementMetrics.route_limits_for_stats(
		HERO.to_base_stats_dictionary(), HERO.id, HERO.display_name
	)
	for stage_index in STAGES.size():
		var stage: Dictionary = STAGES[stage_index]
		var result := StageGenerationService.new().generate(
			stage["rooms"],
			stage["profile"],
			ENEMY_CATALOG,
			HAZARD_CATALOG,
			REWARD_CATALOG,
			73021,
			stage_index,
			limits
		)
		_expect(
			result.success and result.plan != null,
			"typed stage %d should generate without JSON input" % (stage_index + 1)
		)


func _append_errors(errors: PackedStringArray, label: String) -> void:
	for error in errors:
		_failures.append("%s: %s" % [label, error])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("DESIGN_CATALOG_VALIDATION_OK production_catalogs=7 stages=3 rooms=30")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
