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

var _action_timer := 0.0
var _world_timer := 0.0
var _world_phase_seeded := false
var _static_minimap_dirty := true
var _guidebook_dirty := true
var _last_fast_snapshot: Dictionary = {}


func reset() -> void:
	_action_timer = 0.0
	_world_timer = 0.0
	_world_phase_seeded = false
	_static_minimap_dirty = true
	_guidebook_dirty = true
	_last_fast_snapshot.clear()


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
	var update := {}
	_action_timer -= delta
	_world_timer -= delta
	if _action_timer <= 0.0:
		_action_timer = ACTION_INTERVAL
		var fast_snapshot := Dictionary(fast_builder.call())
		# Publish a coherent snapshot whenever any fast value changes.  Per-key
		# diffs let consumers observe health without max_health (or another
		# coupled value), which makes the HUD fall back to presentation defaults.
		# The channel is still cadence-limited and unchanged snapshots are
		# suppressed, so this does not restore per-frame UI work.
		if _last_fast_snapshot != fast_snapshot:
			update.merge(fast_snapshot, true)
		_last_fast_snapshot = fast_snapshot
	if _world_timer <= 0.0:
		_world_timer = (
			WORLD_MARKER_INTERVAL
			+ (INITIAL_WORLD_PHASE_OFFSET if not _world_phase_seeded else 0.0)
		)
		_world_phase_seeded = true
		update["minimap"] = minimap_builder.call(_static_minimap_dirty)
		update["threat_radar"] = threat_builder.call()
		_static_minimap_dirty = false
	if _guidebook_dirty:
		update["guidebook"] = guidebook_builder.call()
		_guidebook_dirty = false
	return update
