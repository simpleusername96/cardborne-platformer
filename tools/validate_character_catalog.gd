extends SceneTree

const CATALOG_PATH := "res://data/characters/character_catalog.tres"
const CharacterCatalogScript := preload("res://scripts/player/CharacterCatalog.gd")
const CharacterProfileScript := preload("res://scripts/player/CharacterProfile.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var catalog := load(CATALOG_PATH) as CharacterCatalog
	_expect(catalog != null, "character catalog should load as CharacterCatalog")
	if catalog != null:
		_validate_valid_catalog(catalog)
		_validate_invalid_catalogs(catalog)
		_validate_base_stats(catalog.get_profile_by_id("warrior"))

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
