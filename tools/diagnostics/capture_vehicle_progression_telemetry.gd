extends SceneTree

const Capture = preload(
	"res://scripts/diagnostics/vehicle_progression_telemetry_capture.gd"
)
const BuildIdentity = preload(
	"res://scripts/diagnostics/vehicle_build_identity.gd"
)
const OUTPUT_DIRECTORY := "res://build/performance/"


func _initialize() -> void:
	var request := _request_from_arguments()
	if bool(request.get("invalid", true)):
		push_error("Progression telemetry requires bounded output, evidence ID, commit, and fingerprint.")
		quit(1)
		return
	var output_path := String(request["output"])
	var absolute_path := ProjectSettings.globalize_path(output_path)
	if FileAccess.file_exists(absolute_path):
		push_error("Refusing to overwrite progression telemetry: %s" % output_path)
		quit(1)
		return
	var identity := BuildIdentity.evidence_identity()
	if not Capture.identity_matches_expected(
		identity,
		String(request["expected_commit"]),
		String(request["expected_fingerprint"])
	):
		push_error("Progression telemetry build identity is stale or dirty.")
		quit(1)
		return
	var bundle := Capture.new().build(String(request["evidence_id"]), identity)
	if (
		bundle.is_empty()
		or not bool(Dictionary(bundle.get("acceptance", {})).get("capture_valid", false))
	):
		push_error("Progression telemetry did not complete the twelve-stage trace.")
		quit(1)
		return
	if DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir()) != OK:
		push_error("Could not create progression telemetry output directory.")
		quit(1)
		return
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write progression telemetry: %s" % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(bundle, "\t") + "\n")
	file.flush()
	print("PROGRESSION_TELEMETRY_CAPTURE_READY %s" % output_path)
	quit(0)


func _request_from_arguments() -> Dictionary:
	var output_path := ""
	var evidence_id := ""
	var expected_commit := ""
	var expected_fingerprint := ""
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for argument in arguments:
		if argument.begins_with("--progression-output="):
			output_path = argument.trim_prefix("--progression-output=")
		elif argument.begins_with("--progression-evidence-id="):
			evidence_id = argument.trim_prefix("--progression-evidence-id=")
		elif argument.begins_with("--progression-expected-commit="):
			expected_commit = argument.trim_prefix("--progression-expected-commit=")
		elif argument.begins_with("--progression-expected-fingerprint="):
			expected_fingerprint = argument.trim_prefix(
				"--progression-expected-fingerprint="
			)
	var file_name := output_path.trim_prefix(OUTPUT_DIRECTORY)
	var safe_output := (
		output_path.begins_with(OUTPUT_DIRECTORY)
		and not file_name.is_empty()
		and not file_name.contains("/")
		and not file_name.contains("\\")
		and file_name.ends_with(".json")
	)
	var invalid := (
		not safe_output
		or evidence_id.is_empty()
		or expected_commit.length() != 40
		or not expected_commit.is_valid_hex_number()
		or expected_fingerprint.length() != 64
		or not expected_fingerprint.is_valid_hex_number()
	)
	return {
		"invalid":invalid,
		"output":output_path,
		"evidence_id":evidence_id,
		"expected_commit":expected_commit.to_lower(),
		"expected_fingerprint":expected_fingerprint.to_lower(),
	}
