class_name VehicleDashUpgradeRuntime
extends RefCounted

## Owns dash-completion buffs and at most two persistent path zones. The path
## uses the actual start/end positions, including a dash shortened by cover.

const OutgoingDamagePolicy = preload(
	"res://scripts/player/vehicle_outgoing_damage_policy.gd"
)

const OVERDRIVE_DURATION := 2.0
const TRAIL_HALF_WIDTH := 72.0
const TRAIL_DURATION := 3.0
const TRAIL_TICK := 0.5
const MAX_TRAILS := 2
const TRAIL_DAMAGE := [0.0, 10.0, 15.0, 20.0]

class TrailState:
	var start := Vector2.ZERO
	var end := Vector2.ZERO
	var remaining := 0.0
	var tick_remaining := TRAIL_TICK
	var tick_index := 0
	var level := 0
	var serial := 0


var overdrive_remaining := 0.0
var trails: Array[TrailState] = []
var _dash_start := Vector2.ZERO
var _dash_started := false
var _next_serial := 1
var _due_trails: Array[TrailState] = []


func reset() -> void:
	overdrive_remaining = 0.0
	trails.clear()
	_due_trails.clear()
	_dash_start = Vector2.ZERO
	_dash_started = false
	_next_serial = 1


func begin_dash(position: Vector2) -> void:
	_dash_start = position
	_dash_started = true


func complete_dash(
	position: Vector2,
	overdrive_level: int,
	trail_level: int
) -> void:
	if not _dash_started:
		return
	_dash_started = false
	if overdrive_level > 0:
		overdrive_remaining = OVERDRIVE_DURATION
	if trail_level <= 0 or _dash_start.distance_squared_to(position) <= 1.0:
		return
	var trail := TrailState.new()
	trail.start = _dash_start
	trail.end = position
	trail.remaining = TRAIL_DURATION
	trail.tick_remaining = TRAIL_TICK
	trail.tick_index = 0
	trail.level = clampi(trail_level, 1, 3)
	trail.serial = _next_serial
	_next_serial += 1
	trails.append(trail)
	while trails.size() > MAX_TRAILS:
		trails.pop_front()


func advance(delta: float) -> Array[TrailState]:
	_due_trails.clear()
	overdrive_remaining = maxf(0.0, overdrive_remaining - maxf(0.0, delta))
	for index in range(trails.size() - 1, -1, -1):
		var trail := trails[index]
		trail.remaining -= maxf(0.0, delta)
		trail.tick_remaining -= maxf(0.0, delta)
		if trail.tick_remaining <= 0.0:
			trail.tick_remaining += TRAIL_TICK
			trail.tick_index += 1
			_due_trails.append(trail)
		if trail.remaining <= 0.0:
			trails.remove_at(index)
	return _due_trails


func overdrive_active() -> bool:
	return overdrive_remaining > 0.0


func overdrive_bonus(level: int) -> float:
	return (
		OutgoingDamagePolicy.dash_bonus(level)
		if overdrive_active()
		else 0.0
	)


static func damage_per_tick(level: int) -> float:
	return float(TRAIL_DAMAGE[clampi(level, 0, 3)])


static func contains(trail: TrailState, point: Vector2, radius: float = 0.0) -> bool:
	return _point_segment_distance(point, trail.start, trail.end) <= TRAIL_HALF_WIDTH + radius


static func _point_segment_distance(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return point.distance_to(start)
	var amount := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * amount)
