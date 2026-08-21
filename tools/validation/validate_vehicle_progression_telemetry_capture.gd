extends SceneTree

const Capture = preload(
	"res://scripts/diagnostics/vehicle_progression_telemetry_capture.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	var identity := {
		"schema_version":1,
		"identity_status":"resolved",
		"commit":"a".repeat(40),
		"ref":"fixture",
		"source_cleanliness":"clean",
		"content_fingerprint":"b".repeat(64),
	}
	_expect(
		Capture.identity_matches_expected(
			identity, "a".repeat(40), "b".repeat(64)
		),
		"capture accepts the matching clean build identity"
	)
	_expect(
		not Capture.identity_matches_expected(
			identity, "c".repeat(40), "b".repeat(64)
		),
		"capture rejects a stale commit"
	)
	var bundle := Capture.new().build("progression-fixture", identity)
	var stages: Array = bundle.get("stages", [])
	var run := Dictionary(bundle.get("run", {}))
	var acceptance := Dictionary(bundle.get("acceptance", {}))
	_expect(
		String(bundle.get("kind", "")) == "progression_telemetry_capture"
			and stages.size() == 12
			and bool(acceptance.get("capture_valid", false)),
		"capture completes one valid twelve-stage progression trace"
	)
	var previous_level := 0
	var previous_xp := 0
	var total_defeats := 0
	for stage_variant in stages:
		var stage := Dictionary(stage_variant)
		_expect(
			int(stage.get("level_reached", 0)) > previous_level
				and int(stage.get("cumulative_xp", 0)) > previous_xp
				and not bool(stage.get("modal_timing_measured", true))
				and stage.get("modal_seconds", 0.0) == null,
			"each stage advances progression without fabricating modal timing"
		)
		previous_level = int(stage.get("level_reached", 0))
		previous_xp = int(stage.get("cumulative_xp", 0))
		total_defeats += int(stage.get("ordinary_defeats", 0))
	_expect(
		int(run.get("xp_collected", 0)) == previous_xp
			and int(run.get("level_reached", 0)) == previous_level
			and int(run.get("modal_opens", -1)) == previous_level - 1
			and total_defeats == 1674,
		"run totals match the route quota and level-up accounting"
	)
	_finish(bundle)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(bundle: Dictionary) -> void:
	if failures.is_empty():
		var stages: Array = bundle["stages"]
		var stage_levels: Array[int] = []
		var cumulative_xp: Array[int] = []
		for stage_variant in stages:
			var stage := Dictionary(stage_variant)
			stage_levels.append(int(stage["level_reached"]))
			cumulative_xp.append(int(stage["cumulative_xp"]))
		print(
			"VEHICLE_PROGRESSION_TELEMETRY_CAPTURE_VALIDATION_OK stage10=%d final=%d xp=%d levels=%s cumulative_xp=%s"
			% [
				int(Dictionary(stages[9])["level_reached"]),
				int(Dictionary(stages[-1])["level_reached"]),
				int(Dictionary(bundle["run"])["xp_collected"]),
				JSON.stringify(stage_levels),
				JSON.stringify(cumulative_xp),
			]
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
