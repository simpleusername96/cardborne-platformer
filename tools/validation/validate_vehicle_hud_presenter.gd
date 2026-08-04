extends SceneTree

const Presenter = preload("res://scripts/ui/vehicle_hud_presenter.gd")

var failures: Array[String] = []
var fast_calls := 0
var minimap_calls := 0
var static_minimap_calls := 0
var guide_calls := 0


func _initialize() -> void:
	var presenter := Presenter.new()
	var first := presenter.advance(
		0.0, _fast, _minimap, _threat, _guide
	)
	_expect(first.has("health") and first.has("minimap") and first.has("guidebook"), "initial publication includes all dirty channels")
	_expect(fast_calls == 1 and minimap_calls == 1 and static_minimap_calls == 1 and guide_calls == 1, "initial channel builders run once")
	var quiet := presenter.advance(0.01, _fast, _minimap, _threat, _guide)
	_expect(quiet.is_empty(), "no channel republishes before its cadence or invalidation")
	presenter.advance(0.095, _fast, _minimap, _threat, _guide)
	_expect(fast_calls == 2 and minimap_calls == 1, "action channel waits for its ten-hertz boundary without rebuilding world markers")
	presenter.advance(0.02, _fast, _minimap, _threat, _guide)
	_expect(fast_calls == 2 and minimap_calls == 1, "action channel runs at ten hertz without rebuilding world markers")
	presenter.advance(0.14, _fast, _minimap, _threat, _guide)
	_expect(
		minimap_calls == 2 and static_minimap_calls == 1,
		"world markers phase-stagger after first publication, then run at five hertz while static geometry remains one-shot"
	)
	presenter.mark_guidebook_dirty()
	presenter.advance(0.0, _fast, _minimap, _threat, _guide)
	_expect(guide_calls == 2, "guidebook rebuilds only after explicit invalidation")
	_finish()


func _fast() -> Dictionary:
	fast_calls += 1
	return {"health":120.0}


func _minimap(include_static: bool) -> Dictionary:
	minimap_calls += 1
	if include_static:
		static_minimap_calls += 1
	return {"player":Vector2.ZERO}


func _threat() -> Dictionary:
	return {"contacts":[]}


func _guide() -> Dictionary:
	guide_calls += 1
	return {"categories":[]}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_HUD_PRESENTER_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
