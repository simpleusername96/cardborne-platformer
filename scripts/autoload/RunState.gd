extends Node

const PROFILE_PATHS: Array[String] = [
	"res://data/characters/warrior_profile.tres",
	"res://data/characters/archer_profile.tres",
	"res://data/characters/assassin_profile.tres",
]

var profiles: Array[CharacterProfile] = []
var selected_profile_index: int = 0
var selected_profile: CharacterProfile
var effective_stats: Dictionary = {}

var current_health: int = 0
var max_health: int = 0
var current_stage_index: int = 0
var run_level: int = 1
var current_xp: int = 0
var coins: int = 0
var materials: Dictionary = {}
var owned_cards: Array[String] = []
var settings: Dictionary = {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"sfx_volume": 0.8,
	"screen_shake": true,
	"damage_flash": true,
}
var testbed_ability_flags: Dictionary = {
	"double_jump_enabled": false,
	"extra_dash_enabled": false,
	"air_dash_enabled": true,
	"rope_climb_enabled": true,
	"wall_climb_enabled": false,
	"wall_slide_enabled": false,
	"wall_jump_enabled": false,
}


func _ready() -> void:
	_load_profiles()
	start_new_run(selected_profile_index)


func _load_profiles() -> void:
	profiles.clear()
	for profile_path in PROFILE_PATHS:
		var loaded_profile := load(profile_path)
		if loaded_profile is CharacterProfile:
			profiles.append(loaded_profile)
		else:
			push_warning("Unable to load character profile: %s" % profile_path)

	if profiles.is_empty():
		push_error("No character profiles are available for RunState.")
		return

	selected_profile_index = clampi(selected_profile_index, 0, profiles.size() - 1)
	selected_profile = profiles[selected_profile_index]


func start_new_run(profile_index: int = -1) -> void:
	if profiles.is_empty():
		_load_profiles()
	if profiles.is_empty():
		return

	if profile_index >= 0:
		selected_profile_index = wrapi(profile_index, 0, profiles.size())

	selected_profile = profiles[selected_profile_index]
	effective_stats = selected_profile.to_stats_dictionary()
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	current_stage_index = 0
	run_level = 1
	current_xp = 0
	coins = 0
	materials.clear()
	owned_cards.clear()
	_publish_state()
	SignalBus.run_started.emit()


func select_profile(profile_index: int) -> void:
	if profiles.is_empty():
		return

	selected_profile_index = wrapi(profile_index, 0, profiles.size())
	selected_profile = profiles[selected_profile_index]
	effective_stats = selected_profile.to_stats_dictionary()
	max_health = int(effective_stats.get("max_health", 5))
	current_health = max_health
	_publish_state()
	SignalBus.status_message_changed.emit("Profile: %s" % selected_profile.display_name)


func cycle_profile(step: int = 1) -> void:
	select_profile(selected_profile_index + step)


func get_effective_stat(stat_name: String, fallback: float = 0.0) -> float:
	return float(effective_stats.get(stat_name, fallback))


func get_effective_stats() -> Dictionary:
	return effective_stats.duplicate()


func get_testbed_ability_flags() -> Dictionary:
	return testbed_ability_flags.duplicate()


func is_testbed_ability_enabled(flag_name: String) -> bool:
	return bool(testbed_ability_flags.get(flag_name, false))


func set_testbed_ability_flag(flag_name: String, enabled: bool) -> void:
	if not testbed_ability_flags.has(flag_name):
		push_warning("Unknown testbed ability flag: %s" % flag_name)
		return

	testbed_ability_flags[flag_name] = enabled
	_publish_testbed_state()


func get_movement_metrics() -> Dictionary:
	return MovementMetrics.calculate_for_profile(selected_profile, testbed_ability_flags)


func get_required_route_limits() -> Dictionary:
	return MovementMetrics.route_limits_for_profiles(profiles, testbed_ability_flags)


func get_testbed_metrics_snapshot() -> Dictionary:
	return {
		"active": get_movement_metrics(),
		"route_limits": get_required_route_limits(),
	}


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
	if not settings.has(setting_name):
		push_warning("Unknown setting: %s" % setting_name)
		return
	settings[setting_name] = value


func get_setting(setting_name: String, fallback: Variant = null) -> Variant:
	return settings.get(setting_name, fallback)


func _publish_state() -> void:
	if selected_profile != null:
		SignalBus.selected_profile_changed.emit(
			selected_profile.id,
			selected_profile.display_name,
			selected_profile.visual_color
		)
	SignalBus.player_stats_changed.emit(get_effective_stats())
	SignalBus.player_health_changed.emit(current_health, max_health)
	_publish_testbed_state()


func _publish_testbed_state() -> void:
	SignalBus.testbed_flags_changed.emit(get_testbed_ability_flags())
	SignalBus.testbed_metrics_changed.emit(get_testbed_metrics_snapshot())
