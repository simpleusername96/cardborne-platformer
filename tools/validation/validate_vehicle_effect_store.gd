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
		and is_equal_approx(reused.value, 0.0)
		and is_equal_approx(reused.multiplier, 1.0),
		"retired state is reset and reused without allocating a replacement"
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
