class_name VehicleSlowTickReceiptBuffer
extends RefCounted

## Keeps only the slowest physics ticks in fixed scalar columns. Callers retain and
## reuse their input columns; Dictionaries exist only in the finalized report.

const CAPACITY := 32
const COARSE_FIELD_NAMES := [
	"player_and_rewards_ms",
	"encounter_and_pursuit_ms",
	"enemies_and_grid_ms",
	"combat_and_effects_ms",
	"progression_and_cleanup_ms",
]
const SCALAR_FIELD_NAMES := [
	"exact_enemy_count", "visible_enemy_count", "due_count", "critical_count",
	"decision_phase", "motion_phase", "pursuit_rebuild_state", "pursuit_processed_cells",
	"overlap_owner_count", "overlap_candidate_count", "spawn_count", "cue_count",
	"player_projectile_count", "hostile_projectile_count", "effect_count",
	"frame_aggregate_scans", "pressure_scans", "schedule_scans", "contact_scans",
	"overlap_scans", "anomaly_scans",
]

var _count := 0
var _serials := PackedInt64Array()
var _totals_ms := PackedFloat64Array()
var _coarse_columns: Array[PackedFloat64Array] = []
var _scalar_columns: Array[PackedInt64Array] = []


func _init() -> void:
	_serials.resize(CAPACITY)
	_totals_ms.resize(CAPACITY)
	for _field in COARSE_FIELD_NAMES:
		var column := PackedFloat64Array()
		column.resize(CAPACITY)
		_coarse_columns.append(column)
	for _field in SCALAR_FIELD_NAMES:
		var column := PackedInt64Array()
		column.resize(CAPACITY)
		_scalar_columns.append(column)


func clear() -> void:
	_count = 0


func retained_count() -> int:
	return _count


static func coarse_field_count() -> int:
	return COARSE_FIELD_NAMES.size()


static func scalar_field_count() -> int:
	return SCALAR_FIELD_NAMES.size()


func record(
	physics_serial: int,
	total_ms: float,
	coarse_ms: PackedFloat64Array,
	scalars: PackedInt32Array
) -> void:
	if coarse_ms.size() != COARSE_FIELD_NAMES.size() or scalars.size() != SCALAR_FIELD_NAMES.size():
		push_error("Slow tick receipt columns do not match the fixed schema")
		return
	var target := _count
	if target >= CAPACITY:
		target = _fastest_retained_index()
		if total_ms <= _totals_ms[target]:
			return
	else:
		_count += 1
	_serials[target] = physics_serial
	_totals_ms[target] = maxf(0.0, total_ms)
	for field_index in COARSE_FIELD_NAMES.size():
		_coarse_columns[field_index][target] = maxf(0.0, coarse_ms[field_index])
	for field_index in SCALAR_FIELD_NAMES.size():
		_scalar_columns[field_index][target] = scalars[field_index]


func finalized_receipts() -> Array[Dictionary]:
	var ordered_indices: Array[int] = []
	for index in _count:
		ordered_indices.append(index)
	ordered_indices.sort_custom(func(left: int, right: int) -> bool:
		if not is_equal_approx(_totals_ms[left], _totals_ms[right]):
			return _totals_ms[left] > _totals_ms[right]
		return _serials[left] < _serials[right]
	)
	var result: Array[Dictionary] = []
	for index in ordered_indices:
		var coarse := {}
		for field_index in COARSE_FIELD_NAMES.size():
			coarse[COARSE_FIELD_NAMES[field_index]] = _coarse_columns[field_index][index]
		var receipt := {
			"physics_serial":_serials[index],
			"total_ms":_totals_ms[index],
			"coarse_ms":coarse,
		}
		for field_index in SCALAR_FIELD_NAMES.size():
			receipt[SCALAR_FIELD_NAMES[field_index]] = _scalar_columns[field_index][index]
		result.append(receipt)
	return result


func _fastest_retained_index() -> int:
	var result := 0
	for index in range(1, CAPACITY):
		if _totals_ms[index] < _totals_ms[result]:
			result = index
	return result
