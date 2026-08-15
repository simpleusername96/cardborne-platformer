extends SceneTree

const Catalog = preload("res://scripts/cards/vehicle_upgrade_catalog.gd")
const Build = preload("res://scripts/cards/vehicle_run_build.gd")
const Combo = preload("res://scripts/combat/vehicle_primary_combo_runtime.gd")
const Facilities = preload("res://scripts/vehicle/vehicle_mystery_device_runtime.gd")
const PrimaryWeapon = preload("res://scripts/player/vehicle_primary_weapon.gd")
const ActiveWeaponRuntime = preload("res://scripts/player/vehicle_active_weapon_runtime.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var catalog := Catalog.new()
	_expect(catalog.validate_contract().is_empty(), "catalog has 27 cards and 91 levels")
	var build := Build.new(catalog)
	var offer := catalog.offer(build, 77, 0, &"level_up", 0)
	_expect(offer.any(func(card): return card.category == &"activated") and offer.any(func(card): return card.category == &"secondary"), "missing weapon categories reserve offers")
	var combo := Combo.new()
	for _index in 5: combo.record_shot_group(false, 3, 0)
	_expect(is_equal_approx(combo.next_hit_multiplier(3, 0), 1.70), "miss compensation applies to the next hit group")
	_expect(is_equal_approx(float(combo.record_shot_group(true, 3, 0)["damage_multiplier"]), 1.70), "miss compensation caps at five")
	combo.reset()
	combo.record_shot_group(true, 0, 3)
	_expect(is_equal_approx(combo.next_hit_multiplier(0, 3), 1.10), "hit chain previews the next consecutive hit")
	combo.advance_motion(1.0, Combo.BRACED_SEGMENT_DISTANCE * 5.0, 100.0, 3)
	combo.advance_motion(Combo.BRACED_STILL_SECONDS, 0.0, 0.0, 3)
	_expect(is_equal_approx(combo.braced_multiplier(3), 1.50), "braced fire caps at five movement segments")
	combo.reset()
	combo.advance_motion(0.0, Combo.BRACED_SEGMENT_DISTANCE * 40.0, 100.0, 3)
	_expect(
		combo.braced_segments == Combo.BRACED_MAX
			and float(combo.snapshot()["braced_distance"]) <= Combo.BRACED_SEGMENT_DISTANCE,
		"braced fire bounds residual travel distance after its segment cap"
	)
	var primary := PrimaryWeapon.new()
	primary.consume_shot()
	primary.tick(PrimaryWeapon.BASE_INTERVAL * 0.70, true)
	_expect(
		is_equal_approx(primary.cooldown, PrimaryWeapon.BASE_INTERVAL * 0.30),
		"cryo-scaled player primary cadence advances at the authored multiplier"
	)
	var active_build := Build.new(catalog)
	_expect(bool(active_build.apply(&"emp").get("applied", false)), "active cadence fixture equips EMP")
	var active := ActiveWeaponRuntime.new()
	var started := active.try_start(Vector2.ZERO, Vector2.RIGHT, Rect2(-1000, -1000, 2000, 2000), active_build)
	var active_cooldown := active.cooldown_remaining
	active.advance(0.70, active_build)
	_expect(
		bool(started["started"])
			and is_equal_approx(active.cooldown_remaining, active_cooldown - 0.70),
		"cryo-scaled player active cooldown advances at the authored multiplier"
	)
	var runtime := Facilities.new()
	runtime.configure([{"id": &"a", "pos": Vector2.ZERO}, {"id": &"b", "pos": Vector2(900, 0)}, {"id": &"c", "pos": Vector2(1800, 0)}], 77, &"stage_1")
	_expect(runtime.snapshot()["devices"].size() == 3, "three distinct facilities configure")
	_expect(Facilities.accepts_damage(&"player", &"projectile") and Facilities.accepts_damage(&"hostile", &"projectile"), "both factions damage facilities")
	var receipt := {}
	_expect(not runtime.first_intact_segment_hit(Vector2(-100, 0), Vector2(100, 0), 0.0, receipt), "facilities pass projectiles")
	_expect(runtime.first_damageable_segment_hit(Vector2(-100, 0), Vector2(100, 0), 0.0, receipt), "passing projectiles still find a damage receipt")
	var device_id := StringName(receipt["device_id"])
	_expect(bool(runtime.receive_damage(device_id, 10.0, &"player", &"projectile")["accepted"]), "player projectiles damage facilities")
	_expect(bool(runtime.receive_damage(device_id, 10.0, &"hostile", &"projectile")["accepted"]), "hostile projectiles damage facilities")
	_finish()

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_UPGRADE_FACILITIES_VALIDATION_OK")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)
