class_name VehicleEnemyState
extends RefCounted

## Fixed-shape live enemy state. Frequently accessed simulation fields are
## declared properties so Web builds avoid per-field Dictionary hashing.

var id := ""
var role: StringName = &""
var archetype: StringName = &""
var family: StringName = &""
var tier := 0
var size_percent := 100
var family_trait: StringName = &""
var movement_family: StringName = &""
var name := ""
var pos := Vector2.ZERO
var home := Vector2.ZERO
var velocity := Vector2.ZERO
var desired_velocity := Vector2.ZERO
# Presentation consumes this simulation-owned effective facing. It never infers
# targets or attack phase from renderer-only state.
var presentation_facing := Vector2.RIGHT
var health := 0.0
var max_health := 0.0
var speed := 0.0
# Movement/contact radius stays compact so enlarged art does not reduce horde density.
var radius := 0.0
# Player projectiles use this separate swept-hit radius to match the visible target.
var projectile_hit_radius := 0.0
var visual_radius := 0.0
var health_class: StringName = &"standard"
var health_visible_timer := 0.0
var threat_cost := 1.0
var threat_kind: StringName = &"melee"
var counts_active_cap := false
var alive := false
var active := false
var phase: StringName = &"move"
var phase_time := 0.0
var attack_cooldown := 0.0
var committed_dir := Vector2.LEFT
var committed_target := Vector2.ZERO
var hit_committed := false
# Contact resolution snapshots the physics-start position and the attack motion
# that occurred this tick. The resolver remains the only owner of hull damage.
var contact_previous_position := Vector2.ZERO
var contact_cooldown := 0.0
var contact_attack: StringName = &""
var burst_left := 0
var burst_timer := 0.0
var stun := 0.0
var flash := 0.0
var shielded := false
# Causal diagnostics are fixed scalar values so normal simulation does not
# allocate when explaining the current movement or shield state.
var movement_reason: StringName = &"none"
var shield_source: StringName = &"none"
var support_tick := 0.0
var repair_target_id := ""
var intercept_charges := 0
var intercept_recharge := 0.0
var strafe_sign := 1.0
var stuck_time := 0.0
var reposition_time := 0.0
var reposition_dir := Vector2.ZERO
var zone := ""
var group_id := ""
var squad_id := ""
var squad_leader := false
var formation_slot := 0
var formation_size := 1
var collective_tactic_id: StringName = &""
var collective_beat_kind: StringName = &""
var collective_phase: StringName = &"dormant"
var collective_mode: StringName = &""
var collective_direction := Vector2.RIGHT
var collective_target := Vector2.ZERO
var collective_slot := 0
var collective_speed_multiplier := 1.0
var pack_trait_active := false
var pack_trait_phase: StringName = &"idle"
var pack_trait_ratio := 0.0
var pack_feed_stacks := 0
var pack_damage_multiplier := 1.0
var pack_speed_multiplier := 1.0
var packet_beat := 0
var carrier_id := ""
var summoned := false
var child_serial := 0
var carrier_wave_released := false
var beam_end := Vector2.ZERO
var leash_rect := Rect2()
var required := false
var optional := false
var ram_cooldown := 0.0
var pattern_index := 0
var boss_phase := 1
var boss_variant: StringName = &"boss_stage_01"
var boss_shield_state: StringName = &""
var boss_attack_damage_multiplier := 1.0
var pattern: StringName = &""
var last_pattern: StringName = &""
var pattern_timer := 0.0
var pattern_tick := 0.0
var pattern_volleys := 0
var vulnerable := 0.0
var mechanic_state: StringName = &""
var mechanic_cue_active := false
var mechanic_inner_radius := 0.0
var mechanic_outer_radius := 0.0
var elite_trait: StringName = &""
var armor_structure := 0.0
var guard_plate_structure := 0.0
var mine_armed_by_player := false
var mine_fast_cue_played := false
var splitter_spawned := false
var lane_centers: Array = []
var attack_telegraphs: Array[Dictionary] = []
var decision_bucket := 0
var statuses: Dictionary = {}
# Renderer-facing status receipts are fixed scalars. Presentation never walks
# the live status Dictionary on the frame hot path; pulse values are normalized.
var toxin_stack_ratio := 0.0
var cryo_stack_ratio := 0.0
var toxin_application_pulse := 0.0
var cryo_application_pulse := 0.0
var toxin_application_delay := 0.0
var cryo_application_delay := 0.0
var facility_barrier_strength := 0.0
var facility_barrier_max := 0.0
var facility_movement_multiplier := 1.0
var facility_acceleration_multiplier := 1.0
var facility_cadence_multiplier := 1.0
var facility_received_damage_multiplier := 1.0
var runtime_slot := -1
# Stable pool identity and reuse generation let spatial membership reject stale
# cell entries after swap retirement or pooled actor reuse.
var spatial_slot := -1
var runtime_generation := 0
var target_score := 0.0
var decision_elapsed := 0.0
var motion_elapsed := 0.0
# Immutable director reservation copied at materialization; no actor reference
# crosses this boundary, and pooled reuse clears every scalar below.
var engagement_slot := -1
var engagement_generation := 0
var engagement_gate := Vector2.ZERO
var engagement_expiry := 0.0
var engagement_active := false
var engagement_started_at := 0.0
var engagement_last_player_distance := -1.0
var engagement_divergence_started_at := -1.0


func reset_runtime_collections() -> void:
	statuses.clear()
	shielded = false
	movement_reason = &"none"
	shield_source = &"none"
	pack_trait_active = false
	pack_trait_phase = &"idle"
	pack_trait_ratio = 0.0
	pack_feed_stacks = 0
	pack_damage_multiplier = 1.0
	pack_speed_multiplier = 1.0
	contact_previous_position = pos
	contact_cooldown = 0.0
	contact_attack = &""
	toxin_stack_ratio = 0.0
	cryo_stack_ratio = 0.0
	toxin_application_pulse = 0.0
	cryo_application_pulse = 0.0
	toxin_application_delay = 0.0
	cryo_application_delay = 0.0
	facility_barrier_strength = 0.0
	facility_barrier_max = 0.0
	facility_movement_multiplier = 1.0
	facility_acceleration_multiplier = 1.0
	facility_cadence_multiplier = 1.0
	facility_received_damage_multiplier = 1.0
	lane_centers.clear()
	attack_telegraphs.clear()
	target_score = 0.0
	decision_elapsed = 0.0
	motion_elapsed = 0.0
	mechanic_state = &""
	mechanic_cue_active = false
	mechanic_inner_radius = 0.0
	mechanic_outer_radius = 0.0
	engagement_slot = -1
	engagement_generation = 0
	engagement_gate = Vector2.ZERO
	engagement_expiry = 0.0
	engagement_active = false
	engagement_started_at = 0.0
	engagement_last_player_distance = -1.0
	engagement_divergence_started_at = -1.0


func behavior_diagnostics() -> Dictionary:
	return {
		"movement_reason": movement_reason,
		"shield_source": shield_source,
	}
