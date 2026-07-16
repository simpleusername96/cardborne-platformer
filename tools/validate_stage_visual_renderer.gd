extends SceneTree

const VISUAL_CATALOG: StageVisualCatalog = preload(
	"res://data/presentation/stage_visual_catalog.tres"
)
const BACKDROP_SCRIPT = preload(
	"res://scripts/stages/production/ProductionStageBackdrop.gd"
)

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for error in VISUAL_CATALOG.validation_errors():
		_failures.append(error)
	_expect(VISUAL_CATALOG.definitions.size() == 6, "Visual catalog should define six locations.")

	var backdrop := BACKDROP_SCRIPT.new() as ProductionStageBackdrop
	root.add_child(backdrop)
	backdrop.configure(Rect2(0.0, -760.0, 8960.0, 1600.0), &"flooded_works")
	var snapshot := backdrop.get_visual_snapshot()
	_expect(backdrop is Parallax2D, "Production backdrop should use Godot 4 Parallax2D.")
	_expect(snapshot["definition_id"] == "flooded_works", "Flooded definition should resolve.")
	_expect(snapshot["scroll_scale"] == Vector2(0.18, 0.18), "Flooded scale should be 0.18.")
	_expect(snapshot["minimum_panel_count"] == 2, "Measured Flooded Works should need two panels.")
	_expect(snapshot["loaded_panel_count"] == 2, "Flooded Works should load its two proof panels.")
	_expect(not snapshot["procedural_fallback_active"], "Produced panels should replace the fallback.")
	_expect(
		snapshot["estimated_loaded_rgba_bytes"] == 25165824,
		"Two 2048x1536 proof panels should expose a 24 MiB RGBA estimate."
	)
	_expect(snapshot["loading_policy"] == "current_location_only", "Backdrop should expose lazy policy.")
	backdrop.queue_free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("STAGE_VISUAL_RENDERER_VALIDATION_OK catalog=6 flooded_loaded=2 lazy=true")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
