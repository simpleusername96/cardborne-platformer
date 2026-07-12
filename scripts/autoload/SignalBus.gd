extends Node

signal run_started
signal run_state_changed(snapshot: Dictionary)
signal reward_applied(result: Dictionary)
signal level_reward_pending(pending_count: int)
signal level_choice_committed(result: Dictionary)
signal selected_profile_changed(profile_id: String, display_name: String, color: Color)
signal player_health_changed(current_health: int, max_health: int)
signal player_stats_changed(stats: Dictionary)
signal combat_state_changed(state: Dictionary)
signal encounter_state_changed(state: Dictionary)
signal required_room_encounter_started(context: Dictionary)
signal required_room_encounter_cleared(context: Dictionary)
signal optional_route_chest_claimed(context: Dictionary)
signal reward_preview_replacement_requested(request: Dictionary)
signal player_died
signal stage_started(stage_id: String, stage_display_name: String)
signal stage_cleared(stage_id: String)
signal interaction_prompt_changed(prompt_text: String, active: bool)
signal settings_visibility_changed(is_visible: bool)
signal input_bindings_changed
signal status_message_changed(message: String)
signal checkpoint_changed(checkpoint_id: String, checkpoint_position: Vector2)
