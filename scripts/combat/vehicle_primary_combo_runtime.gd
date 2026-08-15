class_name VehiclePrimaryComboRuntime
extends RefCounted

## Fixed-size primary shot-group state. VehicleRun supplies one final outcome
## per group, so split children cannot multiply card effects.

const MISS_MAX := 5
const HIT_MAX := 8
const BRACED_MAX := 5
const BRACED_SEGMENT_DISTANCE := 220.0
const BRACED_STILL_SPEED := 20.0
const BRACED_BREAK_SPEED := 60.0
const BRACED_STILL_SECONDS := 0.60
const BRACED_WINDOW_SECONDS := 4.0
const MISS_BONUS := [0.08, 0.11, 0.14]
const HIT_BONUS := [0.03, 0.04, 0.05]
const BRACED_BONUS := [0.06, 0.08, 0.10]

var miss_stacks := 0
var hit_stacks := 0
var braced_segments := 0
var braced_active_segments := 0
var braced_distance := 0.0
var still_seconds := 0.0
var braced_seconds := 0.0

func reset() -> void:
	miss_stacks = 0
	hit_stacks = 0
	braced_segments = 0
	braced_active_segments = 0
	braced_distance = 0.0
	still_seconds = 0.0
	braced_seconds = 0.0

func next_hit_multiplier(miss_level: int, hit_level: int) -> float:
	var multiplier := 1.0
	if miss_stacks > 0 and miss_level > 0:
		multiplier += float(miss_stacks) * MISS_BONUS[clampi(miss_level - 1, 0, 2)]
	if hit_level > 0:
		multiplier += float(mini(HIT_MAX, hit_stacks + 1)) * HIT_BONUS[clampi(hit_level - 1, 0, 2)]
	return multiplier

func record_shot_group(hostile_hit: bool, miss_level: int, hit_level: int) -> Dictionary:
	var multiplier := 1.0
	if hostile_hit:
		if miss_stacks > 0 and miss_level > 0:
			multiplier += float(miss_stacks) * MISS_BONUS[clampi(miss_level - 1, 0, 2)]
			miss_stacks = 0
		if hit_level > 0:
			hit_stacks = mini(HIT_MAX, hit_stacks + 1)
			multiplier += float(hit_stacks) * HIT_BONUS[clampi(hit_level - 1, 0, 2)]
	else:
		if miss_level > 0:
			miss_stacks = mini(MISS_MAX, miss_stacks + 1)
		if hit_level > 0:
			hit_stacks = 0
	return {"damage_multiplier": multiplier, "miss_stacks": miss_stacks, "hit_stacks": hit_stacks}

func advance_motion(delta: float, moved_distance: float, speed: float, braced_level: int) -> Dictionary:
	if braced_level <= 0:
		return snapshot()
	braced_distance += maxf(0.0, moved_distance)
	while braced_distance >= BRACED_SEGMENT_DISTANCE and braced_segments < BRACED_MAX:
		braced_distance -= BRACED_SEGMENT_DISTANCE
		braced_segments += 1
	# Once the five authored segments are armed, retaining unbounded travel
	# distance has no gameplay value and would let an idle state grow forever.
	if braced_segments >= BRACED_MAX:
		braced_distance = minf(braced_distance, BRACED_SEGMENT_DISTANCE)
	if speed < BRACED_STILL_SPEED and braced_segments > 0:
		still_seconds += maxf(0.0, delta)
		if still_seconds >= BRACED_STILL_SECONDS and braced_seconds <= 0.0:
			braced_seconds = BRACED_WINDOW_SECONDS
			braced_active_segments = braced_segments
			braced_segments = 0
			braced_distance = 0.0
	else:
		still_seconds = 0.0
	if speed > BRACED_BREAK_SPEED:
		braced_seconds = 0.0
		braced_active_segments = 0
	else:
		braced_seconds = maxf(0.0, braced_seconds - maxf(0.0, delta))
		if braced_seconds <= 0.0:
			braced_active_segments = 0
	return snapshot()

func braced_multiplier(braced_level: int, _consumed_segments: int = 0) -> float:
	if braced_seconds <= 0.0 or braced_level <= 0:
		return 1.0
	return 1.0 + float(braced_active_segments) * BRACED_BONUS[clampi(braced_level - 1, 0, 2)]

func snapshot() -> Dictionary:
	return {"miss_stacks": miss_stacks, "hit_stacks": hit_stacks, "braced_segments": braced_segments, "braced_active_segments": braced_active_segments, "braced_distance": braced_distance, "braced_seconds": braced_seconds}
