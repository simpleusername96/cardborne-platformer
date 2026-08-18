class_name VehicleConditionalStatusSnapshot
extends RefCounted

## Builds language-neutral conditional-state receipts from gameplay truth.
## The HUD may cap presentation, while Ship Status receives the full owned set.

const ComboRuntime = preload("res://scripts/combat/vehicle_primary_combo_runtime.gd")
const MAX_VISIBLE := 5


static func build(
	overflow_level: int,
	barrier_strength: float,
	barrier_remaining: float,
	dash_level: int,
	dash_remaining: float,
	braced_level: int,
	braced_segments: int,
	braced_remaining: float,
	hit_level: int,
	hit_stacks: int,
	miss_level: int,
	miss_stacks: int,
	last_stand_level: int,
	last_stand_bonus: float
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if last_stand_level > 0:
		rows.append(_row(
			&"last_stand", &"active" if last_stand_bonus > 0.0 else &"inactive",
			0, 0, last_stand_bonus * 100.0, 0.0, 0.0
		))
	if overflow_level > 0:
		rows.append(_row(
			&"overflow_barrier",
			&"active" if barrier_strength > 0.0 and barrier_remaining > 0.0 else &"inactive",
			roundi(barrier_strength), 0, 0.0, barrier_remaining, 0.0
		))
	if dash_level > 0:
		rows.append(_row(
			&"dash_overdrive", &"active" if dash_remaining > 0.0 else &"inactive",
			0, 0, 0.0, dash_remaining, 0.0
		))
	if braced_level > 0:
		var braced_bonus := float(ComboRuntime.BRACED_BONUS[
			clampi(braced_level - 1, 0, ComboRuntime.BRACED_BONUS.size() - 1)
		]) * float(braced_segments) * 100.0
		rows.append(_row(
			&"braced_fire", &"active" if braced_remaining > 0.0 else &"inactive",
			braced_segments, ComboRuntime.BRACED_MAX, braced_bonus,
			braced_remaining, braced_bonus
		))
	if hit_level > 0:
		var hit_bonus := float(ComboRuntime.HIT_BONUS[
			clampi(hit_level - 1, 0, ComboRuntime.HIT_BONUS.size() - 1)
		]) * float(hit_stacks) * 100.0
		rows.append(_row(
			&"hit_chain", &"active" if hit_stacks > 0 else &"inactive",
			hit_stacks, ComboRuntime.HIT_MAX, hit_bonus, 0.0, hit_bonus
		))
	if miss_level > 0:
		var next_hit_bonus := float(ComboRuntime.MISS_BONUS[
			clampi(miss_level - 1, 0, ComboRuntime.MISS_BONUS.size() - 1)
		]) * float(miss_stacks) * 100.0
		rows.append(_row(
			&"miss_compensation", &"active" if miss_stacks > 0 else &"inactive",
			miss_stacks, ComboRuntime.MISS_MAX, 0.0, 0.0, next_hit_bonus
		))
	return rows


static func _row(
	id: StringName,
	phase: StringName,
	current_stacks: int,
	max_stacks: int,
	bonus_percent: float,
	remaining_seconds: float,
	next_hit_bonus_percent: float
) -> Dictionary:
	return {
		"id":id,
		"phase":phase,
		"current_stacks":current_stacks,
		"max_stacks":max_stacks,
		"bonus_percent":bonus_percent,
		"remaining_seconds":maxf(0.0, remaining_seconds),
		"next_hit_bonus_percent":next_hit_bonus_percent,
	}
