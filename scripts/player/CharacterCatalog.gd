class_name CharacterCatalog
extends Resource

const PlayerBuildScript = preload("res://scripts/player/PlayerBuild.gd")
const REQUIRED_PROFILE_IDS: PackedStringArray = ["warrior", "archer", "assassin"]

# Serialized order is the stable character-select index.
@export var profiles: Array[CharacterProfile] = []


func get_profile_count() -> int:
	return profiles.size()


func get_profile_by_index(profile_index: int) -> CharacterProfile:
	if profile_index < 0 or profile_index >= profiles.size():
		return null
	return profiles[profile_index]


func get_profile_by_id(profile_id: String) -> CharacterProfile:
	var profile_index := get_profile_index(profile_id)
	return get_profile_by_index(profile_index)


func get_profile_index(profile_id: String) -> int:
	for profile_index in profiles.size():
		var profile := profiles[profile_index]
		if profile != null and profile.id == profile_id:
			return profile_index
	return -1


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}

	for profile_index in profiles.size():
		var profile := profiles[profile_index]
		if profile == null:
			errors.append("Character profile at index %d is null." % profile_index)
			continue

		var profile_id := profile.id
		if profile_id.strip_edges().is_empty():
			errors.append("Character profile at index %d has a blank ID." % profile_index)
			continue
		if seen_ids.has(profile_id):
			errors.append(
				"Duplicate character profile ID '%s' at indexes %d and %d."
				% [profile_id, int(seen_ids[profile_id]), profile_index]
			)
			continue
		seen_ids[profile_id] = profile_index

		var build_snapshot = PlayerBuildScript.resolve(profile.to_base_stats_dictionary())
		for build_error in build_snapshot.get_validation_errors():
			errors.append(
				"Character profile '%s' has an invalid base build: %s"
				% [profile_id, build_error.get("message", "Unknown build error.")]
			)

		if profile.combat_kit == null:
			errors.append("Character profile '%s' needs a combat kit." % profile_id)
			continue
		if String(profile.combat_kit.profile_id) != profile_id:
			errors.append(
				"Character profile '%s' references kit for '%s'."
				% [profile_id, profile.combat_kit.profile_id]
			)
		for kit_error in profile.combat_kit.validate_definition():
			errors.append("Character profile '%s' has an invalid kit: %s" % [profile_id, kit_error])

	for required_profile_id in REQUIRED_PROFILE_IDS:
		if not seen_ids.has(required_profile_id):
			errors.append("Missing required character profile '%s'." % required_profile_id)

	return errors
