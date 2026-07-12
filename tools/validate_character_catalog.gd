extends SceneTree

const CATALOG_PATH := "res://data/characters/character_catalog.tres"
const CharacterCatalogScript := preload("res://scripts/player/CharacterCatalog.gd")
const CharacterProfileScript := preload("res://scripts/player/CharacterProfile.gd")
const MovementMetricsScript := preload("res://scripts/player/MovementMetrics.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var catalog := load(CATALOG_PATH) as CharacterCatalog
	_expect(catalog != null, "character catalog should load as CharacterCatalog")
	if catalog != null:
		_validate_valid_catalog(catalog)
		_validate_invalid_catalogs(catalog)
		_validate_base_stats(catalog.get_profile_by_id("warrior"))
		_validate_combat_kit(catalog.get_profile_by_id("warrior"), &"warrior_cleave", &"warrior_breaker")
		_validate_combat_kit(catalog.get_profile_by_id("archer"), &"archer_quick_shot", &"archer_power_shot")
		_validate_combat_kit(catalog.get_profile_by_id("assassin"), &"assassin_twin_cut", &"assassin_shadow_lunge")
		_validate_route_limits(catalog)

	if _failures.is_empty():
		print("CHARACTER_CATALOG_VALIDATION_OK")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_valid_catalog(catalog: CharacterCatalog) -> void:
	var expected_ids := PackedStringArray(["warrior", "archer", "assassin"])
	_expect(catalog.validate_catalog().is_empty(), "shipped character catalog should be valid")
	_expect(catalog.get_profile_count() == expected_ids.size(), "catalog should contain three profiles")

	for profile_index in expected_ids.size():
		var expected_id := expected_ids[profile_index]
		var indexed_profile := catalog.get_profile_by_index(profile_index)
		_expect(indexed_profile != null, "profile index %d should resolve" % profile_index)
		if indexed_profile == null:
			continue
		_expect(indexed_profile.id == expected_id, "profile index %d should be %s" % [profile_index, expected_id])
		_expect(catalog.get_profile_by_id(expected_id) == indexed_profile, "ID lookup should preserve resource identity for %s" % expected_id)
		_expect(catalog.get_profile_index(expected_id) == profile_index, "ID %s should map to index %d" % [expected_id, profile_index])

	_expect(catalog.get_profile_by_index(-1) == null, "negative profile index should not resolve")
	_expect(catalog.get_profile_by_index(expected_ids.size()) == null, "out-of-range profile index should not resolve")
	_expect(catalog.get_profile_by_id("missing") == null, "unknown profile ID should not resolve")
	_expect(catalog.get_profile_index("missing") == -1, "unknown profile ID should not have an index")


func _validate_invalid_catalogs(valid_catalog: CharacterCatalog) -> void:
	var duplicate_catalog := _copy_catalog(valid_catalog)
	duplicate_catalog.profiles.append(_profile_with_id("warrior"))
	_expect(_has_error(duplicate_catalog.validate_catalog(), "duplicate"), "duplicate profile IDs should fail validation")

	var blank_catalog := _copy_catalog(valid_catalog)
	blank_catalog.profiles.append(_profile_with_id("  "))
	_expect(_has_error(blank_catalog.validate_catalog(), "blank"), "blank profile IDs should fail validation")

	var null_catalog := _copy_catalog(valid_catalog)
	null_catalog.profiles.append(null)
	_expect(_has_error(null_catalog.validate_catalog(), "null"), "null profiles should fail validation")

	var missing_catalog: CharacterCatalog = CharacterCatalogScript.new()
	missing_catalog.profiles.append(valid_catalog.get_profile_by_id("warrior"))
	_expect(_has_error(missing_catalog.validate_catalog(), "missing required"), "missing required profiles should fail validation")

	var invalid_build_catalog: CharacterCatalog = CharacterCatalogScript.new()
	var invalid_warrior := _profile_with_id("warrior")
	invalid_warrior.move_speed = INF
	invalid_build_catalog.profiles.append(invalid_warrior)
	invalid_build_catalog.profiles.append(valid_catalog.get_profile_by_id("archer"))
	invalid_build_catalog.profiles.append(valid_catalog.get_profile_by_id("assassin"))
	_expect(
		_has_error(invalid_build_catalog.validate_catalog(), "finite"),
		"invalid character base stats should fail catalog validation"
	)

	var missing_kit_catalog := _copy_catalog(valid_catalog)
	var missing_kit_profile := (valid_catalog.get_profile_by_id("archer").duplicate() as CharacterProfile)
	missing_kit_profile.combat_kit = null
	missing_kit_catalog.profiles[1] = missing_kit_profile
	_expect(
		_has_error(missing_kit_catalog.validate_catalog(), "needs a combat kit"),
		"every shipped character should require a typed combat kit"
	)


func _validate_base_stats(profile: CharacterProfile) -> void:
	_expect(profile != null, "warrior profile should resolve for stat validation")
	if profile == null:
		return

	var base_stats := profile.to_base_stats_dictionary()
	var compatible_stats := profile.to_stats_dictionary()
	for key in base_stats:
		_expect(compatible_stats.has(key), "legacy stats should retain base key %s" % key)
		_expect(compatible_stats.get(key) == base_stats[key], "legacy stats should retain base value %s" % key)

	for presentation_key in [
		"trait_summary",
		"attack_label",
		"attack_motion_style",
		"attack_visual_color",
		"attack_projectile_size",
	]:
		_expect(not base_stats.has(presentation_key), "base stats should exclude %s" % presentation_key)
		_expect(compatible_stats.has(presentation_key), "legacy stats should retain %s" % presentation_key)


func _validate_combat_kit(
	profile: CharacterProfile,
	expected_basic_id: StringName,
	expected_heavy_id: StringName
) -> void:
	_expect(profile != null, "profile should resolve for combat kit validation")
	if profile == null:
		return
	_expect(profile.combat_kit != null, "%s should reference a typed combat kit" % profile.id)
	if profile.combat_kit == null:
		return
	_expect(profile.combat_kit.validate_definition().is_empty(), "%s combat kit should be valid" % profile.id)
	_expect(profile.combat_kit.profile_id == StringName(profile.id), "kit should target %s" % profile.id)
	_expect(
		profile.combat_kit.get_attack_for_action(&"attack").id == expected_basic_id,
		"%s basic action should resolve %s" % [profile.id, expected_basic_id]
	)
	_expect(
		profile.combat_kit.get_attack_for_action(&"heavy_attack").id == expected_heavy_id,
		"%s heavy action should resolve %s" % [profile.id, expected_heavy_id]
	)
	for slot in range(1, 4):
		_expect(profile.combat_kit.get_skill_by_slot(slot) != null, "%s should expose skill slot %d" % [profile.id, slot])


func _validate_route_limits(catalog: CharacterCatalog) -> void:
	var limits: Dictionary = MovementMetricsScript.route_limits_for_profiles(catalog.profiles)
	_expect(not limits.is_empty(), "character catalog should produce shared route limits")
	for profile in catalog.profiles:
		var metrics: Dictionary = MovementMetricsScript.calculate_for_profile(profile)
		var profile_gap_limit := floorf(
			float(metrics.get("route_reach", 0.0)) * MovementMetricsScript.REQUIRED_GAP_FACTOR
		)
		var profile_ledge_limit := floorf(
			float(metrics.get("route_ledge_height", 0.0)) * MovementMetricsScript.REQUIRED_LEDGE_FACTOR
		)
		_expect(int(metrics.get("extra_jumps", 0)) >= 1, "%s must retain baseline double jump" % profile.id)
		_expect(
			float(limits.get("max_required_gap", INF)) <= profile_gap_limit,
			"required gap must fit %s" % profile.id
		)
		_expect(
			float(limits.get("max_required_ledge", INF)) <= profile_ledge_limit,
			"required ledge must fit %s" % profile.id
		)


func _copy_catalog(source: CharacterCatalog) -> CharacterCatalog:
	var copy: CharacterCatalog = CharacterCatalogScript.new()
	for profile in source.profiles:
		copy.profiles.append(profile)
	return copy


func _profile_with_id(profile_id: String) -> CharacterProfile:
	var profile: CharacterProfile = CharacterProfileScript.new()
	profile.id = profile_id
	return profile


func _has_error(errors: PackedStringArray, fragment: String) -> bool:
	for error in errors:
		if error.to_lower().contains(fragment.to_lower()):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
