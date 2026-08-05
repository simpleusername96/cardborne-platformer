extends SceneTree

## Focused diagnostic for the synchronous spawn-allocation owner. This does
## not measure rendering, complete frame pacing, or release performance.

const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const FieldLayoutGenerator = preload(
	"res://scripts/vehicle/vehicle_field_layout_generator.gd"
)
const SpawnAllocator = preload(
	"res://scripts/encounters/vehicle_spawn_allocator.gd"
)

const FIXED_SEED := 0xC4A2B0
const WARMUP_ROUNDS := 2
const SAMPLE_ROUNDS := 8


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var layout = FieldLayoutGenerator.generate(FIXED_SEED, StageCatalog.STAGE_IDS)
	if layout == null:
		push_error("Could not generate the fixed spawn-allocation layout.")
		quit(1)
		return
	var stage_id: StringName = StageCatalog.STAGE_IDS[0]
	var tactical = layout.tactical_layout(stage_id)
	var packets := StageCatalog.packets(stage_id)
	var packet: Dictionary = packets[1]
	var player_position: Vector2 = tactical.geometry_snapshot.player_start
	var visible_world := Rect2(
		player_position - Vector2(640.0, 360.0),
		Vector2(1280.0, 720.0)
	)
	var window_count := int(packet.get(
		"arrival_windows", SpawnAllocator.ARRIVAL_WINDOWS
	))

	var baseline := SpawnAllocator.new()
	baseline.configure(
		tactical.encounter_seed,
		tactical.ordinary_spawn_anchors,
		tactical.geometry_snapshot
	)
	var baseline_results: Array = []
	var baseline_first_call_ms := PackedFloat64Array()
	for arrival_window in window_count:
		var started := Time.get_ticks_usec()
		var allocations := baseline.allocate_window(
			packet,
			arrival_window,
			player_position,
			visible_world
		)
		baseline_first_call_ms.append(_elapsed_ms(started))
		baseline_results.append(allocations)

	var measured := SpawnAllocator.new()
	measured.configure(
		tactical.encounter_seed,
		tactical.ordinary_spawn_anchors,
		tactical.geometry_snapshot
	)
	var prewarm_ms: Variant = null
	if measured.has_method("prewarm_for_packets"):
		var prewarm_started := Time.get_ticks_usec()
		measured.call("prewarm_for_packets", packets)
		prewarm_ms = _elapsed_ms(prewarm_started)

	var fingerprints := PackedStringArray()
	var unit_counts := PackedInt32Array()
	var first_call_ms := PackedFloat64Array()
	for arrival_window in window_count:
		var started := Time.get_ticks_usec()
		var allocations := measured.allocate_window(
			packet,
			arrival_window,
			player_position,
			visible_world
		)
		first_call_ms.append(_elapsed_ms(started))
		if var_to_str(allocations) != var_to_str(baseline_results[arrival_window]):
			push_error(
				"Spawn allocation changed for arrival window %d."
				% arrival_window
			)
			quit(1)
			return
		fingerprints.append(var_to_str(allocations).sha256_text())
		unit_counts.append(_allocation_unit_count(allocations))

	for _round in WARMUP_ROUNDS:
		for arrival_window in window_count:
			measured.allocate_window(
				packet,
				arrival_window,
				player_position,
				visible_world
			)

	var samples_by_window: Array[PackedFloat64Array] = []
	for _arrival_window in window_count:
		samples_by_window.append(PackedFloat64Array())
	for _round in SAMPLE_ROUNDS:
		for arrival_window in window_count:
			var started := Time.get_ticks_usec()
			var allocations := measured.allocate_window(
				packet,
				arrival_window,
				player_position,
				visible_world
			)
			samples_by_window[arrival_window].append(_elapsed_ms(started))
			if var_to_str(allocations).sha256_text() != fingerprints[arrival_window]:
				push_error(
					"Spawn allocation became nondeterministic for arrival window %d."
					% arrival_window
				)
				quit(1)
				return

	var windows: Array[Dictionary] = []
	for arrival_window in window_count:
		windows.append({
			"arrival_window":arrival_window,
			"unit_count":unit_counts[arrival_window],
			"fingerprint":fingerprints[arrival_window],
			"baseline_first_call_ms":baseline_first_call_ms[arrival_window],
			"measured_first_call_ms":first_call_ms[arrival_window],
			"repeated_ms":_metric_summary(samples_by_window[arrival_window]),
		})
	var result := {
		"kind":"vehicle_spawn_allocation_profile",
		"diagnostic_only":true,
		"authoritative":false,
		"stage_id":String(stage_id),
		"packet_id":String(packet["id"]),
		"fixed_seed":FIXED_SEED,
		"warmup_rounds":WARMUP_ROUNDS,
		"sample_rounds":SAMPLE_ROUNDS,
		"prewarm_available":measured.has_method("prewarm_for_packets"),
		"prewarm_ms":prewarm_ms,
		"windows":windows,
	}
	print(JSON.stringify(result))
	quit(0)


func _allocation_unit_count(allocations: Array) -> int:
	var result := 0
	for allocation in allocations:
		result += Array(allocation.get("roles", [])).size()
	return result


func _metric_summary(samples: PackedFloat64Array) -> Dictionary:
	var sorted := Array(samples)
	sorted.sort()
	var total := 0.0
	for sample in sorted:
		total += float(sample)
	return {
		"samples":sorted.size(),
		"average":total / float(maxi(1, sorted.size())),
		"median":_percentile(sorted, 0.50),
		"p95":_percentile(sorted, 0.95),
		"max":float(sorted[-1]) if not sorted.is_empty() else 0.0,
	}


func _percentile(sorted: Array, fraction: float) -> float:
	if sorted.is_empty():
		return 0.0
	var index := clampi(
		ceili(clampf(fraction, 0.0, 1.0) * float(sorted.size())) - 1,
		0,
		sorted.size() - 1
	)
	return float(sorted[index])


func _elapsed_ms(started_usec: int) -> float:
	return float(Time.get_ticks_usec() - started_usec) / 1000.0
