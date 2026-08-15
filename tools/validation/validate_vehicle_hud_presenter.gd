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
var fast_level := 4
var fast_experience := 19
var fast_experience_required := 27
var fast_experience_complete := false
var fast_reduced_motion := false
var fast_stage_number := 2
var fast_stage_total := 8
var fast_cumulative_defeated := 86
var fast_dash_available := true
var fast_dash_remaining := 0.0


func _initialize() -> void:
	var presenter := Presenter.new()
	var first := presenter.advance(
		0.0, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_hull_fields_present(first)
			and _all_stage_progress_fields_present(first)
			and _all_action_fields_present(first)
			and not first.has("target")
			and not first.has("boss")
			and first.has("minimap")
			and first.has("threat_radar")
			and first.has("guidebook"),
		"initial publication includes the minimal atomic HUD clusters and every dirty channel"
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
		and not damage_update.has("stage_number")
		and not damage_update.has("dash_available"),
		"a hull-only change omits unchanged stage-progress and action clusters"
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
	fast_reduced_motion = true
	var motion_update := state_presenter.advance(
		0.10, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_hull_fields_present(motion_update)
		and bool(motion_update.get("reduced_motion", false))
		and int(motion_update["level"]) == 4
		and int(motion_update["experience"]) == 19,
		"reduced-motion changes publish the complete hull-and-XP cluster"
	)
	fast_experience = 20
	var experience_update := state_presenter.advance(
		0.10, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_hull_fields_present(experience_update)
			and int(experience_update["experience"]) == 20
			and not experience_update.has("stage_number"),
		"XP collection republishes the complete center meter cluster only"
	)
	fast_cumulative_defeated = 87
	var progress_update := state_presenter.advance(
		0.10, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_stage_progress_fields_present(progress_update)
		and int(progress_update["stage_number"]) == 2
		and int(progress_update["stage_total"]) == 8
		and int(progress_update["cumulative_defeated"]) == 87
		and not progress_update.has("health"),
		"one defeat republishes the complete numeric stage-progress cluster only"
	)
	fast_dash_available = false
	fast_dash_remaining = 0.5
	var action_update := state_presenter.advance(
		0.10, _fast, _minimap, _threat, _guide
	)
	_expect(
		_all_action_fields_present(action_update)
		and not action_update.has("health")
		and not action_update.has("stage_number"),
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
	health_pips.free()
	_finish()


func _fast() -> Dictionary:
	fast_calls += 1
	return {
		"health":fast_health,
		"max_health":fast_max_health,
		"level":fast_level,
		"experience":fast_experience,
		"experience_required":fast_experience_required,
		"experience_complete":fast_experience_complete,
		"reduced_motion":fast_reduced_motion,
		"stage_number":fast_stage_number,
		"stage_total":fast_stage_total,
		"cumulative_defeated":fast_cumulative_defeated,
		"dash_available":fast_dash_available,
		"dash_remaining":fast_dash_remaining,
		"skill_owned":true,
		"skill_available":true,
		"skill_remaining":0.0,
		"active_weapon_id":&"emp",
	}


func _all_hull_fields_present(update: Dictionary) -> bool:
	for key in [
		"health", "max_health", "level", "experience",
		"experience_required", "experience_complete", "reduced_motion",
	]:
		if not update.has(key):
			return false
	return true


func _all_action_fields_present(update: Dictionary) -> bool:
	for key in [
		"dash_available", "dash_remaining",
		"skill_owned", "skill_available", "skill_remaining", "active_weapon_id",
	]:
		if not update.has(key):
			return false
	return true


func _all_stage_progress_fields_present(update: Dictionary) -> bool:
	for key in ["stage_number", "stage_total", "cumulative_defeated"]:
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
