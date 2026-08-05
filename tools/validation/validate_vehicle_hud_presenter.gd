extends SceneTree

const Presenter = preload("res://scripts/ui/vehicle_hud_presenter.gd")
const GameplayHud = preload("res://scripts/ui/vehicle_gameplay_hud.gd")

var failures: Array[String] = []
var fast_calls := 0
var minimap_calls := 0
var static_minimap_calls := 0
var guide_calls := 0
var fast_health := 120.0
var fast_max_health := 120.0


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
	# Exercise coupled hull transitions on a fresh presenter so cadence assertions
	# above remain independent of the state-transition coverage.
	var state_presenter := Presenter.new()
	state_presenter.advance(0.0, _fast, _minimap, _threat, _guide)
	fast_health = 110.0
	var damage_update := state_presenter.advance(0.10, _fast, _minimap, _threat, _guide)
	_expect(
		damage_update.get("health", -1.0) == 110.0
		and damage_update.get("max_health", -1.0) == 120.0,
		"health changes publish the coupled max_health value atomically"
	)
	fast_health = 120.0
	var heal_update := state_presenter.advance(0.10, _fast, _minimap, _threat, _guide)
	_expect(
		heal_update.get("health", -1.0) == 120.0
		and heal_update.get("max_health", -1.0) == 120.0,
		"healing republishes the complete hull pair"
	)
	fast_max_health = 135.0
	fast_health = 135.0
	var max_hull_update := state_presenter.advance(0.10, _fast, _minimap, _threat, _guide)
	_expect(
		max_hull_update.get("health", -1.0) == 135.0
		and max_hull_update.get("max_health", -1.0) == 135.0,
		"max-hull changes publish current and maximum hull together"
	)
	var health_pips := GameplayHud.HealthPips.new()
	health_pips.set_values(120.0, 120.0)
	health_pips.set_values(
		float(damage_update["health"]), float(damage_update["max_health"])
	)
	_expect(
		is_equal_approx(health_pips.health, 110.0)
			and is_equal_approx(health_pips.maximum, 120.0),
		"HUD HealthPips consumes the atomic pair without falling back to 1/1"
	)
	_finish()


func _fast() -> Dictionary:
	fast_calls += 1
	return {
		"health":fast_health,
		"max_health":fast_max_health,
		"level":1,
		"experience":0.0,
		"experience_required":12.0,
		"objective":"",
		"objective_detail":"",
		"dash_available":true,
		"emp_available":true,
	}


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
