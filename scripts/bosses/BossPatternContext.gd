class_name BossPatternContext
extends RefCounted

const TAG_JUMP_SLAM_LANDING_RESPONSE := &"jump_slam_landing_response_available"
const TAG_SIDE_RESPONSE := &"side_response_available"
const TAG_SUMMON_SPAWN_ZONES_SAFE := &"summon_spawn_zones_safe"
const TAG_POISON_SUMMON_ZONES_NON_OVERLAPPING := &"poison_summon_zones_non_overlapping"
const BLOCK_POISON_REMOVES_JUMP_LANDING := &"poison_removes_jump_slam_landing_response"
const BLOCK_TWO_ADDS_BLOCK_BOTH_SIDES := &"two_adds_block_both_side_responses"
const BLOCK_ACTIVE_ADD_CAP_REACHED := &"active_add_cap_reached"

var phase: int
var active_add_count: int
var active_add_cap: int
var safe_floor_fraction: float
var jump_slam_landing_response_available: bool
var poison_bands_active: bool
var left_side_response_available: bool
var right_side_response_available: bool
var summon_spawn_zones_safe: bool
var summon_spawn_zones_overlap_poison: bool


func _init(
	p_phase: int = BossPatternDefinition.PHASE_ONE,
	p_active_add_count: int = 0,
	p_active_add_cap: int = 2,
	p_safe_floor_fraction: float = 1.0,
	p_jump_slam_landing_response_available: bool = true,
	p_poison_bands_active: bool = false,
	p_left_side_response_available: bool = true,
	p_right_side_response_available: bool = true,
	p_summon_spawn_zones_safe: bool = true,
	p_summon_spawn_zones_overlap_poison: bool = false
) -> void:
	phase = p_phase
	active_add_count = p_active_add_count
	active_add_cap = p_active_add_cap
	safe_floor_fraction = p_safe_floor_fraction
	jump_slam_landing_response_available = p_jump_slam_landing_response_available
	poison_bands_active = p_poison_bands_active
	left_side_response_available = p_left_side_response_available
	right_side_response_available = p_right_side_response_available
	summon_spawn_zones_safe = p_summon_spawn_zones_safe
	summon_spawn_zones_overlap_poison = p_summon_spawn_zones_overlap_poison


func available_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	if jump_slam_landing_response_available:
		tags.append(TAG_JUMP_SLAM_LANDING_RESPONSE)
	if left_side_response_available or right_side_response_available:
		tags.append(TAG_SIDE_RESPONSE)
	if summon_spawn_zones_safe:
		tags.append(TAG_SUMMON_SPAWN_ZONES_SAFE)
	if not summon_spawn_zones_overlap_poison:
		tags.append(TAG_POISON_SUMMON_ZONES_NON_OVERLAPPING)
	return tags


func active_constraint_tags() -> Array[StringName]:
	var tags: Array[StringName] = []
	if poison_bands_active and not jump_slam_landing_response_available:
		tags.append(BLOCK_POISON_REMOVES_JUMP_LANDING)
	if (
		active_add_count >= 2
		and not left_side_response_available
		and not right_side_response_available
	):
		tags.append(BLOCK_TWO_ADDS_BLOCK_BOTH_SIDES)
	if active_add_count >= active_add_cap:
		tags.append(BLOCK_ACTIVE_ADD_CAP_REACHED)
	return tags


func validate_context() -> PackedStringArray:
	var errors := PackedStringArray()
	if not BossPatternDefinition.SUPPORTED_PHASES.has(phase):
		errors.append("Boss pattern context has unsupported phase %d." % phase)
	if active_add_cap <= 0:
		errors.append("Boss pattern context needs a positive active-add cap.")
	if active_add_count < 0 or active_add_count > active_add_cap:
		errors.append("Boss pattern context active-add count is outside its cap.")
	if (
		not is_finite(safe_floor_fraction)
		or safe_floor_fraction < 0.0
		or safe_floor_fraction > 1.0
	):
		errors.append("Boss pattern context safe-floor fraction must be between zero and one.")
	return errors
