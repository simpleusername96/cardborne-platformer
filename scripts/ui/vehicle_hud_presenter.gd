class_name VehicleHudPresenter
extends RefCounted

## Invalidates HUD channels independently so closed/static UI data does not
## allocate on the combat cooldown timer.

## HUD is presentation-only; ten hertz action state and five hertz world
## markers are sufficient for readability while avoiding a rebuild on every
## render frame under the peak-horde workload.
const ACTION_INTERVAL := 0.10
const WORLD_MARKER_INTERVAL := 0.20
const INITIAL_WORLD_PHASE_OFFSET := ACTION_INTERVAL * 0.5
const FAST_CLUSTERS := [
	[
		"health", "max_health", "level", "experience",
		"experience_required", "reduced_motion",
	],
	["objective", "objective_detail", "stage_title"],
	[
		"dash_available", "dash_ratio", "seeker_available", "seeker_ratio",
		"skill_available", "skill_ratio", "buff_text",
	],
	["target"],
	["boss"],
]

var _action_timer := 0.0
var _world_timer := 0.0
var _world_phase_seeded := false
var _static_minimap_dirty := true
var _guidebook_dirty := true
var _last_fast_snapshot: Dictionary = {}
var _update_frame: Dictionary = {}


func reset() -> void:
	_action_timer = 0.0
	_world_timer = 0.0
	_world_phase_seeded = false
	_static_minimap_dirty = true
	_guidebook_dirty = true
	_last_fast_snapshot.clear()
	_update_frame.clear()


func mark_guidebook_dirty() -> void:
	_guidebook_dirty = true


func mark_minimap_static_dirty() -> void:
	_static_minimap_dirty = true


func advance(
	delta: float,
	fast_builder: Callable,
	minimap_builder: Callable,
	threat_builder: Callable,
	guidebook_builder: Callable
) -> Dictionary:
	_update_frame.clear()
	_action_timer -= delta
	_world_timer -= delta
	if _action_timer <= 0.0:
		_action_timer = ACTION_INTERVAL
		var fast_snapshot: Dictionary = fast_builder.call()
		for cluster in FAST_CLUSTERS:
			if _cluster_changed(fast_snapshot, cluster):
				_publish_cluster(fast_snapshot, cluster)
	if _world_timer <= 0.0:
		_world_timer = (
			WORLD_MARKER_INTERVAL
			+ (INITIAL_WORLD_PHASE_OFFSET if not _world_phase_seeded else 0.0)
		)
		_world_phase_seeded = true
		_update_frame["minimap"] = minimap_builder.call(_static_minimap_dirty)
		_update_frame["threat_radar"] = threat_builder.call()
		_static_minimap_dirty = false
	if _guidebook_dirty:
		_update_frame["guidebook"] = guidebook_builder.call()
		_guidebook_dirty = false
	return _update_frame


func _cluster_changed(snapshot: Dictionary, keys: Array) -> bool:
	for key in keys:
		if (
			not snapshot.has(key)
			or not _last_fast_snapshot.has(key)
			or _last_fast_snapshot[key] != snapshot[key]
		):
			return true
	return false


func _publish_cluster(snapshot: Dictionary, keys: Array) -> void:
	for key in keys:
		if not snapshot.has(key):
			continue
		var value: Variant = snapshot[key]
		_update_frame[key] = value
		_last_fast_snapshot[key] = (
			Dictionary(value).duplicate(true) if value is Dictionary else value
		)
