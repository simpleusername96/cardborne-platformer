extends Node

signal run_started
signal selected_profile_changed(profile_id: String, display_name: String, color: Color)
signal player_health_changed(current_health: int, max_health: int)
signal player_stats_changed(stats: Dictionary)
signal player_died
signal stage_started(stage_id: String, stage_display_name: String)
signal stage_cleared(stage_id: String)
signal interaction_prompt_changed(prompt_text: String, active: bool)
signal settings_visibility_changed(is_visible: bool)
signal status_message_changed(message: String)
signal testbed_metrics_changed(metrics: Dictionary)
signal testbed_flags_changed(flags: Dictionary)
signal testbed_objective_changed(objective: String)
signal testbed_route_status_changed(status: String)
