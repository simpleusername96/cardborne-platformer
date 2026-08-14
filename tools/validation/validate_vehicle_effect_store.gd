extends SceneTree

const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
const EncounterDirector = preload(
	"res://scripts/encounters/vehicle_encounter_director.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	var store := EffectStore.new()
	var initial := store.debug_snapshot()
	_expect(
		store.validate_capacity()
		and EffectStore.MAX_LIVE_EFFECTS == EncounterDirector.EFFECT_CAP
		and int(initial["live"]) == 0
		and int(initial["pool"]) == EffectStore.MAX_LIVE_EFFECTS
		and int(initial["state_instances_created"])
			== EffectStore.MAX_LIVE_EFFECTS,
		"effect store preallocates exactly 96 reusable states"
	)
	var first = store.add(
		&"fixture_first",
		Vector2(11.0, 12.0),
		Color(0.1, 0.2, 0.3, 0.4),
		0.75,
		42.0,
		Vector2.LEFT,
		18.0,
		0.20
	)
	_expect(
		first != null
		and first.kind == &"fixture_first"
		and first.pos == Vector2(11.0, 12.0)
		and first.color == Color(0.1, 0.2, 0.3, 0.4)
		and is_equal_approx(first.time, 0.75)
		and is_equal_approx(first.duration, 0.75)
		and is_equal_approx(first.radius, 42.0)
		and is_equal_approx(first.secondary_radius, 0.0)
		and first.direction == Vector2.LEFT
		and is_equal_approx(first.value, 18.0)
		and is_equal_approx(first.multiplier, 0.20),
		"effect state preserves every renderer-visible field"
	)
	store.remove_at_swap(0)
	var reused = store.add(
		&"fixture_reused", Vector2.ZERO, Color.WHITE, 1.0, 10.0
	)
	_expect(
		is_same(first, reused)
		and reused.kind == &"fixture_reused"
		and is_equal_approx(reused.secondary_radius, 0.0)
		and is_equal_approx(reused.value, 0.0)
		and is_equal_approx(reused.multiplier, 1.0),
		"retired state is reset and reused without allocating a replacement"
	)
	store.clear()
	var emp_charge = store.add_emp_footprint(
		EffectStore.EMP_CHARGE_KIND,
		Vector2(31.0, 47.0),
		Color.WHITE,
		0.42,
		285.0,
		325.0
	)
	var emp_release = store.add_emp_footprint(
		EffectStore.EMP_RELEASE_KIND,
		Vector2(41.0, 57.0),
		Color.WHITE,
		0.55,
		285.0,
		325.0
	)
	_expect(
		emp_charge != null
		and emp_release != null
		and is_equal_approx(emp_charge.radius, 285.0)
		and is_equal_approx(emp_charge.secondary_radius, 325.0)
		and is_equal_approx(emp_release.radius, 285.0)
		and is_equal_approx(emp_release.secondary_radius, 325.0),
		"named EMP acquisition publishes exact damage/stun and projectile-clear radii"
	)
	store.remove_at_swap(0)
	var reset_emp_state = store.add(
		&"fixture_after_emp", Vector2.ZERO, Color.WHITE, 1.0, 12.0
	)
	_expect(
		is_same(emp_charge, reset_emp_state)
		and is_equal_approx(reset_emp_state.secondary_radius, 0.0),
		"EMP secondary radius resets before pooled state reuse"
	)

	store.clear()
	for serial in EffectStore.MAX_LIVE_EFFECTS:
		store.add(
			&"fixture_render",
			Vector2(float(serial), 0.0),
			Color.WHITE,
			2.0,
			24.0,
			Vector2.RIGHT,
			float(serial)
		)
	var overflow = store.add(
		&"fixture_overflow",
		Vector2(999.0, 0.0),
		Color.WHITE,
		3.0,
		36.0,
		Vector2.DOWN,
		999.0
	)
	_expect(
		overflow != null
		and store.live.size() == EffectStore.MAX_LIVE_EFFECTS
		and is_equal_approx(store.live[0].value, 95.0)
		and store.live[-1].kind == &"fixture_overflow"
		and is_equal_approx(store.live[-1].value, 999.0)
		and int(store.debug_snapshot()["evictions"]) == 1
		and int(store.debug_snapshot()["rejected_capacity"]) == 0,
		"full store retires the first presentation entry with swap eviction"
	)

	store.clear()
	store.add(&"swap_a", Vector2.ZERO, Color.WHITE, 1.0, 1.0, Vector2.ZERO, 1.0)
	store.add(&"swap_b", Vector2.ZERO, Color.WHITE, 1.0, 1.0, Vector2.ZERO, 2.0)
	store.add(&"swap_c", Vector2.ZERO, Color.WHITE, 1.0, 1.0, Vector2.ZERO, 3.0)
	store.remove_at_swap(0)
	_expect(
		store.live.size() == 2
		and is_equal_approx(store.live[0].value, 3.0)
		and is_equal_approx(store.live[1].value, 2.0),
		"ordinary retirement preserves historical swap order"
	)

	store.clear()
	for index in EffectStore.MAX_LIVE_THERMAL_IMPACTS:
		var impact = store.add_thermal_burst_impact(
			Vector2(float(index), 12.0), Color.WHITE, 0.18, 72.0
		)
		impact.time = 0.01 if index == 0 else 0.18
	var recycled = store.add_thermal_burst_impact(
		Vector2(999.0, 12.0), Color.WHITE, 0.18, 96.0
	)
	var thermal_snapshot := store.debug_snapshot()
	var oldest_thermal_survived := false
	for state in store.live:
		oldest_thermal_survived = (
			oldest_thermal_survived or state.pos == Vector2(0.0, 12.0)
		)
	_expect(
		recycled != null
		and store.count_kind(EffectStore.THERMAL_BURST_IMPACT_KIND)
			== EffectStore.MAX_LIVE_THERMAL_IMPACTS
		and not oldest_thermal_survived
		and int(thermal_snapshot["thermal_recycles"]) == 1,
		"the twenty-fifth Thermal receipt recycles only the oldest Thermal state"
	)

	store.clear()
	store.add_emp_footprint(
		EffectStore.EMP_CHARGE_KIND, Vector2.ZERO, Color.WHITE, 1.0, 100.0, 140.0
	)
	store.add_emp_footprint(
		EffectStore.EMP_RELEASE_KIND, Vector2.ZERO, Color.WHITE, 1.0, 100.0, 140.0
	)
	for index in 22:
		store.add_thermal_burst_impact(
			Vector2(float(index), 20.0), Color.WHITE, 0.18, 84.0
		)
	for index in EffectStore.MAX_LIVE_EFFECTS - 24:
		store.add(
			&"fixture_priority", Vector2(float(index), 30.0),
			Color.WHITE, 1.0, 10.0
		)
	var full_recycled = store.add_thermal_burst_impact(
		Vector2(1000.0, 20.0), Color.WHITE, 0.18, 84.0
	)
	_expect(
		full_recycled != null
		and store.live.size() == EffectStore.MAX_LIVE_EFFECTS
		and store.count_kind(&"player_emp_charge") == 1
		and store.count_kind(&"player_emp_release") == 1
		and store.count_kind(EffectStore.THERMAL_BURST_IMPACT_KIND) == 22
		and store.validate_capacity(),
		"a full store recycles Thermal while preserving both EMP states and total capacity"
	)

	store.clear()
	store.add_emp_footprint(
		EffectStore.EMP_CHARGE_KIND, Vector2.ZERO, Color.WHITE, 1.0, 100.0, 140.0
	)
	store.add_emp_footprint(
		EffectStore.EMP_RELEASE_KIND, Vector2.ZERO, Color.WHITE, 1.0, 100.0, 140.0
	)
	for index in EffectStore.MAX_LIVE_EFFECTS - 2:
		store.add(
			&"fixture_priority", Vector2(float(index), 40.0),
			Color.WHITE, 1.0, 10.0
		)
	var rejected_thermal = store.add_thermal_burst_impact(
		Vector2(1000.0, 40.0), Color.WHITE, 0.18, 72.0
	)
	_expect(
		rejected_thermal == null
		and store.live.size() == EffectStore.MAX_LIVE_EFFECTS
		and store.count_kind(&"player_emp_charge") == 1
		and store.count_kind(&"player_emp_release") == 1
		and int(store.debug_snapshot()["rejected_thermal_capacity"]) == 1,
		"Thermal drops its cosmetic receipt when a full store has no Thermal state to recycle"
	)

	store.clear()
	for index in EffectStore.MAX_LIVE_DROP_MINE_DETONATIONS:
		var mine_effect = store.add_drop_mine_detonation(
			Vector2(float(index), 50.0), Color.WHITE, 0.18, 96.0
		)
		mine_effect.time = 0.01 if index == 0 else 0.18
	var recycled_mine = store.add_drop_mine_detonation(
		Vector2(999.0, 50.0), Color.WHITE, 0.18, 120.0
	)
	var mine_snapshot := store.debug_snapshot()
	var oldest_mine_survived := false
	for state in store.live:
		oldest_mine_survived = (
			oldest_mine_survived or state.pos == Vector2(0.0, 50.0)
		)
	_expect(
		recycled_mine != null
		and store.count_kind(EffectStore.DROP_MINE_DETONATION_KIND)
			== EffectStore.MAX_LIVE_DROP_MINE_DETONATIONS
		and not oldest_mine_survived
		and int(mine_snapshot["drop_mine_recycles"]) == 1,
		"the ninth Drop Mine receipt recycles only the oldest Drop Mine cosmetic"
	)

	store.clear()
	store.add_emp_footprint(
		EffectStore.EMP_CHARGE_KIND, Vector2.ZERO, Color.WHITE, 1.0, 100.0, 140.0
	)
	store.add_emp_footprint(
		EffectStore.EMP_RELEASE_KIND, Vector2.ZERO, Color.WHITE, 1.0, 100.0, 140.0
	)
	for index in EffectStore.MAX_LIVE_EFFECTS - 2:
		store.add(
			&"fixture_priority", Vector2(float(index), 60.0),
			Color.WHITE, 1.0, 10.0
		)
	var rejected_mine = store.add_drop_mine_detonation(
		Vector2(1000.0, 60.0), Color.WHITE, 0.18, 108.0
	)
	_expect(
		rejected_mine == null
		and store.live.size() == EffectStore.MAX_LIVE_EFFECTS
		and store.count_kind(&"player_emp_charge") == 1
		and store.count_kind(&"player_emp_release") == 1
		and int(store.debug_snapshot()["rejected_drop_mine_capacity"]) == 1,
		"Drop Mine drops its cosmetic receipt when no mine slot can be recycled"
	)

	store.clear()
	for index in EffectStore.MAX_LIVE_EXPLOSIVE_SEEKER_IMPACTS:
		var seeker_effect = store.add_explosive_seeker_impact(
			Vector2(float(index), 65.0), Color.WHITE, 0.18, 95.0
		)
		seeker_effect.time = 0.01 if index == 0 else 0.18
	var recycled_seeker = store.add_explosive_seeker_impact(
		Vector2(999.0, 65.0), Color.WHITE, 0.18, 95.0
	)
	var seeker_snapshot := store.debug_snapshot()
	var oldest_seeker_survived := false
	for state in store.live:
		oldest_seeker_survived = (
			oldest_seeker_survived or state.pos == Vector2(0.0, 65.0)
		)
	_expect(
		recycled_seeker != null
		and store.count_kind(EffectStore.EXPLOSIVE_SEEKER_IMPACT_KIND)
			== EffectStore.MAX_LIVE_EXPLOSIVE_SEEKER_IMPACTS
		and not oldest_seeker_survived
		and int(seeker_snapshot["explosive_seeker_recycles"]) == 1
		and store.validate_capacity(),
		"the ninth Explosive Seeker receipt recycles only its oldest cosmetic"
	)

	store.clear()
	for iteration in 2048:
		store.add(
			&"soak",
			Vector2(float(iteration % 32), float(iteration % 17)),
			Color.WHITE,
			0.25,
			12.0
		)
		if store.live.size() >= EffectStore.MAX_LIVE_EFFECTS / 2:
			store.remove_at_swap(iteration % store.live.size())
	var final_snapshot := store.debug_snapshot()
	_expect(
		store.validate_capacity()
		and int(final_snapshot["state_instances_created"])
			== EffectStore.MAX_LIVE_EFFECTS
		and int(final_snapshot["live"]) + int(final_snapshot["pool"])
			== EffectStore.MAX_LIVE_EFFECTS
		and int(final_snapshot["rejected_capacity"]) == 0,
		"saturated effect soak creates no state after initialization"
	)
	store.clear()
	_expect(
		store.live.is_empty() and store.validate_capacity(),
		"reset returns every live state to the fixed pool"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_EFFECT_STORE_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
