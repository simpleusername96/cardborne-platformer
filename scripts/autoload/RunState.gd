extends Node

const CHARACTER_CATALOG_PATH := "res://data/characters/character_catalog.tres"

var character_catalog: CharacterCatalog
var profiles: Array[CharacterProfile] = []
var selected_profile_index: int = 0
var selected_profile: CharacterProfile
var effective_stats: Dictionary = {}
var effective_build_snapshot: PlayerBuildSnapshot

var current_health: int = 0
var max_health: int = 0
var current_stage_index: int = 0
var run_level: int = 1
var current_xp: int = 0
var coins: int = 0
var _unsettled_materials: Dictionary = {}
var owned_cards: Array[String] = []


func _ready() -> void:
	_load_profiles()
	start_new_run(selected_profile_index)


func _load_profiles() -> void:
	profiles.clear()
	var loaded_catalog := load(CHARACTER_CATALOG_PATH)
	if not loaded_catalog is CharacterCatalog:
		push_error("Unable to load the production character catalog.")
		return

	character_catalog = loaded_catalog
	var catalog_errors := character_catalog.validate_catalog()
	if not catalog_errors.is_empty():
		for error in catalog_errors:
			push_error("Invalid character catalog: %s" % error)
		return

	for profile in character_catalog.profiles:
		profiles.append(profile)

	if profiles.is_empty():
		push_error("No character profiles are available for RunState.")
		return

	selected_profile_index = clampi(selected_profile_index, 0, profiles.size() - 1)
	selected_profile = profiles[selected_profile_index]


func start_new_run(profile_index: int = -1) -> bool:
	if profiles.is_empty():
		_load_profiles()
	if profiles.is_empty():
		return false

	var candidate_index := selected_profile_index
	if profile_index >= 0:
		candidate_index = wrapi(profile_index, 0, profiles.size())
	var candidate_profile := profiles[candidate_index]
	var candidate_build := PlayerBuild.resolve(candidate_profile.to_base_stats_dictionary())
	if not _is_build_valid(candidate_profile, candidate_build):
		return false
	_apply_profile_build(candidate_index, candidate_profile, candidate_build)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	current_stage_index = 0
	run_level = 1
	current_xp = 0
	coins = 0
	_unsettled_materials.clear()
	owned_cards.clear()
	_publish_state()
	SignalBus.run_started.emit()
	return true


func select_profile(profile_index: int) -> bool:
	if profiles.is_empty():
		return false

	var candidate_index := wrapi(profile_index, 0, profiles.size())
	var candidate_profile := profiles[candidate_index]
	var candidate_build := PlayerBuild.resolve(candidate_profile.to_base_stats_dictionary())
	if not _is_build_valid(candidate_profile, candidate_build):
		return false
	_apply_profile_build(candidate_index, candidate_profile, candidate_build)
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	_publish_state()
	SignalBus.status_message_changed.emit("Profile: %s" % selected_profile.display_name)
	return true


func cycle_profile(step: int = 1) -> void:
	select_profile(selected_profile_index + step)


func get_effective_stat(stat_name: String, fallback: float = 0.0) -> float:
	return float(effective_stats.get(stat_name, fallback))


func get_effective_stats() -> Dictionary:
	return effective_stats.duplicate()


func get_effective_build_snapshot() -> PlayerBuildSnapshot:
	return effective_build_snapshot


func get_unsettled_materials() -> Dictionary:
	return _unsettled_materials.duplicate(true)


func grant_unsettled_material(material_id: String, amount: int) -> bool:
	if material_id.is_empty() or amount <= 0:
		return false
	_unsettled_materials[material_id] = int(_unsettled_materials.get(material_id, 0)) + amount
	return true


func get_movement_metrics() -> Dictionary:
	return MovementMetrics.calculate_for_profile(selected_profile)


func get_required_route_limits() -> Dictionary:
	return MovementMetrics.route_limits_for_profiles(profiles)


func damage_player(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	SignalBus.player_health_changed.emit(current_health, max_health)
	if current_health <= 0:
		SignalBus.player_died.emit()


func heal_player(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return

	current_health = mini(current_health + amount, max_health)
	SignalBus.player_health_changed.emit(current_health, max_health)


func revive_player() -> void:
	current_health = max_health
	SignalBus.player_health_changed.emit(current_health, max_health)


func set_setting(setting_name: String, value: Variant) -> void:
	if not ProfileState.set_setting(setting_name, value):
		push_warning("Rejected profile setting: %s" % setting_name)


func get_setting(setting_name: String, fallback: Variant = null) -> Variant:
	return ProfileState.get_setting(setting_name, fallback)


func _is_build_valid(profile: CharacterProfile, build_snapshot: PlayerBuildSnapshot) -> bool:
	if build_snapshot.is_valid():
		return true
	for error in build_snapshot.get_validation_errors():
		push_error(
			"Invalid player build for '%s': %s"
			% [profile.id, error.get("message", "Unknown error.")]
		)
	return false


func _apply_profile_build(
	profile_index: int,
	profile: CharacterProfile,
	build_snapshot: PlayerBuildSnapshot
) -> void:
	var resolved_stats := profile.to_stats_dictionary()
	for stat_id in profile.to_base_stats_dictionary():
		resolved_stats.erase(stat_id)
	for stat_id in build_snapshot.get_values():
		resolved_stats[stat_id] = build_snapshot.get_stat(stat_id)

	selected_profile_index = profile_index
	selected_profile = profile
	effective_build_snapshot = build_snapshot
	effective_stats = resolved_stats


func _publish_state() -> void:
	if selected_profile != null:
		SignalBus.selected_profile_changed.emit(
			selected_profile.id,
			selected_profile.display_name,
			selected_profile.visual_color
		)
	SignalBus.player_stats_changed.emit(get_effective_stats())
	SignalBus.player_health_changed.emit(current_health, max_health)
