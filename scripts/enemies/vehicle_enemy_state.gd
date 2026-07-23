class_name VehicleEnemyState
extends RefCounted

## Fixed-shape live enemy state. Frequently accessed simulation fields are
## declared properties so Web builds avoid per-field Dictionary hashing.

var id := ""
var role: StringName = &""
var archetype: StringName = &""
var name := ""
var pos := Vector2.ZERO
var home := Vector2.ZERO
var velocity := Vector2.ZERO
var desired_velocity := Vector2.ZERO
var health := 0.0
var max_health := 0.0
var speed := 0.0
var radius := 0.0
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
var burst_left := 0
var burst_timer := 0.0
var stun := 0.0
var stagger := 0.0
var flash := 0.0
var shielded := false
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
var formation_offset := Vector2.ZERO
var target_sector := Vector2.RIGHT
var packet_beat := 0
var carrier_id := ""
var summoned := false
var child_serial := 0
var carrier_wave_released := false
var beam_end := Vector2.ZERO
var requires_reflection := false
var marked_time := 0.0
var shear_time := 0.0
var leash_rect := Rect2()
var required := false
var optional := false
var ram_cooldown := 0.0
var pattern_index := 0
var boss_phase := 1
var pattern: StringName = &""
var last_pattern: StringName = &""
var pattern_timer := 0.0
var pattern_tick := 0.0
var pattern_volleys := 0
var vulnerable := 0.0
var lane_centers: Array = []
var decision_bucket := 0
var statuses: Dictionary = {}
var runtime_slot := -1
var passive_score := 0.0


func reset_runtime_collections() -> void:
	statuses.clear()
	lane_centers.clear()
	passive_score = 0.0
