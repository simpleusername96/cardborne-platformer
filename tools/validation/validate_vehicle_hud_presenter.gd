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
var fast_level := 1
var fast_experience := 0.0
var fast_experience_required := 12.0
var fast_reduced_motion := false
var fast_dash_available := true
var fast_dash_ratio := 0.0


func _initialize() -> void:
	var presenter := Presenter.new()
	var first := presenter.advance(
		0.0, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_hull_fields_present(first)
			and _all_objective_fields_present(first)
			and _all_action_fields_present(first)
			and first.has("target")
			and first.has("boss")
			and first.has("minimap")
			and first.has("threat_radar")
			and first.has("guidebook"),
		"initial publication includes every field in all five atomic clusters and every dirty channel"
	)
	_expect(fast_calls == 1 and minimap_calls == 1 and static_minimap_calls == 1 and guide_calls == 1, "initial channel builders run once")
	var quiet := presenter.advance(0.01, _fast, _minimap, _threat, _guide)
	_expect(
		is_same(first, quiet) and quiet.is_empty(),
		"presenter reuses one cleared update frame between synchronous publications"
	)
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
	var damage_snapshot := damage_update.duplicate(true)
	_expect(
		damage_update.get("health", -1.0) == 110.0
		and damage_update.get("max_health", -1.0) == 120.0,
		"health changes publish the coupled max_health value atomically"
	)
	_expect(
		_all_hull_fields_present(damage_update)
		and not damage_update.has("objective")
		and not damage_update.has("dash_available"),
		"a hull-only change omits unchanged objective and action clusters"
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
	fast_level = 2
	fast_experience = 3.0
	fast_experience_required = 16.0
	fast_reduced_motion = true
	var progression_update := state_presenter.advance(
		0.10, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_hull_fields_present(progression_update)
		and progression_update.get("level", 0) == 2
		and progression_update.get("experience", -1.0) == 3.0
		and progression_update.get("experience_required", -1.0) == 16.0
		and bool(progression_update.get("reduced_motion", false)),
		"XP, level, and reduced-motion changes publish the full hull/progression cluster"
	)
	fast_dash_available = false
	fast_dash_ratio = 0.5
	var action_update := state_presenter.advance(
		0.10, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_action_fields_present(action_update)
		and not action_update.has("health")
		and not action_update.has("objective"),
		"one action change publishes every action sibling and no unchanged cluster"
	)
	var health_pips := GameplayHud.HealthPips.new()
	health_pips.set_values(120.0, 120.0)
	health_pips.set_values(
		float(damage_snapshot["health"]), float(damage_snapshot["max_health"])
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
		"level":fast_level,
		"experience":fast_experience,
		"experience_required":fast_experience_required,
		"reduced_motion":fast_reduced_motion,
		"objective":"",
		"objective_detail":"",
		"stage_title":"",
		"dash_available":fast_dash_available,
		"dash_ratio":fast_dash_ratio,
		"seeker_available":true,
		"seeker_ratio":0.0,
		"skill_available":true,
		"skill_ratio":0.0,
		"buff_text":"",
		"target":{"visible":false},
		"boss":{"visible":false},
	}


func _all_hull_fields_present(update: Dictionary) -> bool:
	for key in [
		"health", "max_health", "level", "experience",
		"experience_required", "reduced_motion",
	]:
		if not update.has(key):
			return false
	return true


func _all_action_fields_present(update: Dictionary) -> bool:
	for key in [
		"dash_available", "dash_ratio", "seeker_available", "seeker_ratio",
		"skill_available", "skill_ratio", "buff_text",
	]:
		if not update.has(key):
			return false
	return true


func _all_objective_fields_present(update: Dictionary) -> bool:
	for key in ["objective", "objective_detail", "stage_title"]:
		if not update.has(key):
			return false
	return true


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
