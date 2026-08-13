class_name VehicleEngagementTelemetry
extends RefCounted

## Fixed-capacity engagement observation for explicit diagnostic runs only.
## It aggregates actor direction at 4 Hz and never retains actor identities.

const SAMPLE_INTERVAL := 0.25
const EVENT_BUCKET_SECONDS := 0.5
const SECTOR_COUNT := 8
const EVENT_BUCKET_CAPACITY := 7200
const MOVING_SPEED_MINIMUM := 80.0
const MAX_SAMPLES_PER_ADVANCE := 4
const ENGAGEMENT_SHELL_RADIUS := 900.0
const REAR_TAIL_MINIMUM_ACTORS := 3
const REAR_TAIL_SHARE_MINIMUM := 0.60
const REAR_TAIL_DIRECTION_SHARE_MINIMUM := 0.35
const REAR_SECTORS := [0, 1, 6, 7]

var _elapsed := 0.0
var _next_sample_at := SAMPLE_INTERVAL
var _sample_count := 0
var _moving_sample_count := 0
var _stationary_sample_count := 0
var _rear_share_sum := 0.0
var _rear_share_max := 0.0
var _sector_counts := PackedInt32Array()
var _largest_empty_gap := 0
var _rear_tail_started_at := -1.0
var _longest_rear_tail_interval := 0.0
var _birth_buckets := PackedInt32Array()
var _gate_completion_buckets := PackedInt32Array()
var _event_buckets_dropped := 0
var _active_reservations_max := 0
var _expiry_count := 0
var _cancel_count := 0
var _director_cpu_ms_total := 0.0
var _director_cpu_ms_max := 0.0
var _director_cpu_samples := 0
var _skipped_sample_count := 0
var _runtime_metrics := {}
var _sample_sector_counts := PackedInt32Array()


func _init() -> void:
	_sector_counts.resize(SECTOR_COUNT)
	_birth_buckets.resize(EVENT_BUCKET_CAPACITY)
	_gate_completion_buckets.resize(EVENT_BUCKET_CAPACITY)
	_sample_sector_counts.resize(SECTOR_COUNT)


func reset() -> void:
	_elapsed = 0.0
	_next_sample_at = SAMPLE_INTERVAL
	_sample_count = 0
	_moving_sample_count = 0
	_stationary_sample_count = 0
	_rear_share_sum = 0.0
	_rear_share_max = 0.0
	_sector_counts.fill(0)
	_largest_empty_gap = 0
	_rear_tail_started_at = -1.0
	_longest_rear_tail_interval = 0.0
	_birth_buckets.fill(0)
	_gate_completion_buckets.fill(0)
	_event_buckets_dropped = 0
	_active_reservations_max = 0
	_expiry_count = 0
	_cancel_count = 0
	_director_cpu_ms_total = 0.0
	_director_cpu_ms_max = 0.0
	_director_cpu_samples = 0
	_skipped_sample_count = 0
	_runtime_metrics.clear()
	_sample_sector_counts.fill(0)


func advance(
	delta: float,
	encounter_runtime: Variant,
	active_enemies: Array,
	player_position: Vector2,
	player_velocity: Vector2
) -> void:
	var step := maxf(0.0, delta)
	_elapsed += step
	if encounter_runtime != null and encounter_runtime.has_method("consume_engagement_telemetry"):
		encounter_runtime.consume_engagement_telemetry(_runtime_metrics)
	_consume_runtime_metrics(_runtime_metrics)
	var sampled := 0
	while _elapsed + 0.0001 >= _next_sample_at and sampled < MAX_SAMPLES_PER_ADVANCE:
		_sample(active_enemies, player_position, player_velocity)
		_next_sample_at += SAMPLE_INTERVAL
		sampled += 1
	if _elapsed + 0.0001 >= _next_sample_at:
		_skipped_sample_count += floori((_elapsed - _next_sample_at) / SAMPLE_INTERVAL) + 1
		_next_sample_at = _elapsed + SAMPLE_INTERVAL


func snapshot() -> Dictionary:
	var moving_average: Variant = null
	if _moving_sample_count > 0:
		moving_average = _rear_share_sum / float(_moving_sample_count)
	return {
		"sample_hz":1.0 / SAMPLE_INTERVAL,
		"max_samples_per_advance":MAX_SAMPLES_PER_ADVANCE,
		"skipped_samples":_skipped_sample_count,
		"engagement_population_source":"active_cap_counting_within_900_px",
		"engagement_shell_radius":ENGAGEMENT_SHELL_RADIUS,
		"samples":_sample_count,
		"moving_samples":_moving_sample_count,
		"stationary_samples":_stationary_sample_count,
		"rear_hemisphere_engaged_share":{
			"mean":moving_average,
			"maximum":_rear_share_max if _moving_sample_count > 0 else null,
		},
		"engagement_sector_counts":_sector_counts,
		"largest_empty_gap_sectors":_largest_empty_gap,
		"births_per_half_second":_event_bucket_snapshot(_birth_buckets),
		"gate_completions_per_half_second":_event_bucket_snapshot(_gate_completion_buckets),
		"longest_rear_tail_interval_seconds":_longest_rear_tail_interval,
		"active_reservations_max":_active_reservations_max,
		"expiry_count":_expiry_count,
		"cancel_count":_cancel_count,
		"director_cpu_ms":{
			"samples":_director_cpu_samples,
			"total":_director_cpu_ms_total,
			"maximum":_director_cpu_ms_max if _director_cpu_samples > 0 else null,
		},
	}


func _consume_runtime_metrics(metrics: Dictionary) -> void:
	var bucket_index := floori(_elapsed / EVENT_BUCKET_SECONDS)
	if bucket_index >= EVENT_BUCKET_CAPACITY:
		_event_buckets_dropped += 1
	else:
		_birth_buckets[bucket_index] += maxi(0, int(metrics.get("births", 0)))
		_gate_completion_buckets[bucket_index] += maxi(0, int(metrics.get("gate_completions", 0)))
	_active_reservations_max = maxi(
		_active_reservations_max, maxi(0, int(metrics.get("active_reservations", 0)))
	)
	_expiry_count += maxi(0, int(metrics.get("expiries", 0)))
	_cancel_count += maxi(0, int(metrics.get("cancellations", 0)))
	var cpu_ms := maxf(0.0, float(metrics.get("director_cpu_ms", 0.0)))
	if cpu_ms > 0.0:
		_director_cpu_samples += 1
		_director_cpu_ms_total += cpu_ms
		_director_cpu_ms_max = maxf(_director_cpu_ms_max, cpu_ms)


func _sample(active_enemies: Array, player_position: Vector2, player_velocity: Vector2) -> void:
	_sample_count += 1
	if player_velocity.length_squared() < MOVING_SPEED_MINIMUM * MOVING_SPEED_MINIMUM:
		_stationary_sample_count += 1
		_close_rear_tail()
		return
	_moving_sample_count += 1
	var heading := player_velocity.normalized()
	var right := Vector2(-heading.y, heading.x)
	_sample_sector_counts.fill(0)
	var engaged := 0
	var rear := 0
	for enemy in active_enemies:
		if not _is_engaged_enemy(enemy):
			continue
		var offset := _enemy_position(enemy) - player_position
		var distance_squared := offset.length_squared()
		if (
			distance_squared <= 0.0001
			or distance_squared > ENGAGEMENT_SHELL_RADIUS * ENGAGEMENT_SHELL_RADIUS
		):
			continue
		engaged += 1
		if offset.dot(heading) < 0.0:
			rear += 1
		var angle := atan2(offset.dot(right), offset.dot(heading))
		var sector := (floori((angle + PI) / (TAU / float(SECTOR_COUNT))) % SECTOR_COUNT + SECTOR_COUNT) % SECTOR_COUNT
		_sample_sector_counts[sector] += 1
		_sector_counts[sector] += 1
	var rear_share := float(rear) / float(engaged) if engaged > 0 else 0.0
	_rear_share_sum += rear_share
	_rear_share_max = maxf(_rear_share_max, rear_share)
	_largest_empty_gap = maxi(_largest_empty_gap, _largest_empty_gap_for(_sample_sector_counts))
	var dominant_rear_direction := 0
	for sector in REAR_SECTORS:
		dominant_rear_direction = maxi(dominant_rear_direction, _sample_sector_counts[sector])
	var rear_tail_active := (
		engaged >= REAR_TAIL_MINIMUM_ACTORS
		and rear_share >= REAR_TAIL_SHARE_MINIMUM
		and float(dominant_rear_direction) / float(engaged)
			>= REAR_TAIL_DIRECTION_SHARE_MINIMUM
	)
	if rear_tail_active:
		if _rear_tail_started_at < 0.0:
			_rear_tail_started_at = _elapsed
	else:
		_close_rear_tail()


func _close_rear_tail() -> void:
	if _rear_tail_started_at < 0.0:
		return
	_longest_rear_tail_interval = maxf(
		_longest_rear_tail_interval, _elapsed - _rear_tail_started_at
	)
	_rear_tail_started_at = -1.0


func _event_bucket_snapshot(values: PackedInt32Array) -> Dictionary:
	_close_rear_tail()
	var count := mini(ceili(_elapsed / EVENT_BUCKET_SECONDS), EVENT_BUCKET_CAPACITY)
	var buckets: Array[int] = []
	buckets.resize(count)
	for index in count:
		buckets[index] = values[index]
	return {
		"bucket_seconds":EVENT_BUCKET_SECONDS,
		"buckets":buckets,
		"dropped_buckets":_event_buckets_dropped,
	}


static func _largest_empty_gap_for(sectors: PackedInt32Array) -> int:
	var largest := 0
	var current := 0
	for index in range(SECTOR_COUNT * 2):
		if sectors[index % SECTOR_COUNT] == 0:
			current += 1
			largest = maxi(largest, current)
		else:
			current = 0
	return mini(SECTOR_COUNT, largest)


static func _is_engaged_enemy(enemy: Variant) -> bool:
	if enemy is Dictionary:
		return bool(enemy.get("alive", false)) and bool(enemy.get("active", false)) and bool(enemy.get("counts_active_cap", false))
	return enemy != null and bool(enemy.alive) and bool(enemy.active) and bool(enemy.counts_active_cap)


static func _enemy_position(enemy: Variant) -> Vector2:
	return Vector2(enemy.get("pos", Vector2.ZERO)) if enemy is Dictionary else Vector2(enemy.pos)
