extends Node

signal run_started
signal run_state_changed(snapshot: Dictionary)
# Accepts GameplayFeedbackRequest or its Dictionary representation.
signal gameplay_feedback_requested(request: Variant)
signal reward_applied(result: Dictionary)
signal interactive_reward_claimed(receipt: Dictionary)
signal field_pickup_collected(receipt: Dictionary)
signal level_reward_pending(pending_count: int)
signal level_choice_committed(result: Dictionary)
signal hero_changed(hero_id: String, display_name: String, color: Color)
signal player_health_changed(current_health: int, max_health: int)
signal player_stats_changed(stats: Dictionary)
signal combat_state_changed(state: Dictionary)
signal encounter_state_changed(state: Dictionary)
signal required_room_encounter_started(context: Dictionary)
signal required_room_encounter_cleared(context: Dictionary)
signal player_died
signal stage_started(stage_id: String, stage_display_name: String)
signal stage_cleared(stage_id: String)
signal boss_defeated(reward_table_id: StringName)
signal run_settled(settlement: Dictionary)
signal interaction_prompt_changed(prompt_text: String, active: bool)
signal forge_requested(context: Dictionary)
signal pause_visibility_changed(is_visible: bool)
signal settings_visibility_changed(is_visible: bool)
signal input_bindings_changed
signal status_message_changed(message: String)
signal checkpoint_changed(checkpoint_id: String, checkpoint_position: Vector2)
