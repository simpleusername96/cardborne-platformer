extends SceneTree

const CATALOG_PATH := "res://data/hazards/hazard_catalog.tres"

var _failures: Array[String] = []


class DamageProbe extends Area2D:
	var received: Array[DamageInfo] = []

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 64
		monitoring = true
		monitorable = true
		var collision := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(36.0, 48.0)
		collision.shape = rectangle
		add_child(collision)

	func receive_damage(damage_info: DamageInfo) -> void:
		received.append(damage_info)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(CATALOG_PATH) as HazardCatalog
	_expect(catalog != null and catalog.validate_catalog().is_empty(), "hazard catalog should validate")
	if catalog == null:
		_finish()
		return
	await _validate_poison_damage_window(catalog.get_hazard(&"timed_poison_vent"))
	_validate_poison_determinism(catalog.get_hazard(&"timed_poison_vent"))
	await _validate_crumble_cycle(catalog.get_hazard(&"crumbling_platform"))
	_validate_crumble_determinism(catalog.get_hazard(&"crumbling_platform"))
	_finish()


func _validate_poison_damage_window(definition: HazardDefinition) -> void:
	var vent := definition.scene.instantiate() as TimedPoisonVent if definition != null else null
	_expect(vent != null, "poison fixture should instantiate")
	if vent == null:
		return
	root.add_child(vent)
	vent.set_physics_process(false)
	var probe := DamageProbe.new()
	root.add_child(probe)
	for _frame in 3:
		await physics_frame
	_expect(probe.received.is_empty(), "poison warning must not damage")
	vent.advance_time(0.69)
	_expect(vent.get_runtime_snapshot()["state"] == &"warning", "poison warning should last 0.70s")
	_expect(probe.received.is_empty(), "poison should remain safe before activation")
	vent.advance_time(0.01)
	_expect(vent.get_runtime_snapshot()["state"] == &"active", "poison should activate after warning")
	_expect(probe.received.size() == 1, "poison activation should apply one exact tick")
	vent.advance_time(0.64)
	_expect(probe.received.size() == 1, "poison should not tick before 0.65s")
	vent.advance_time(0.01)
	_expect(probe.received.size() == 2, "poison should tick at 0.65s")
	vent.advance_time(0.55)
	_expect(vent.get_runtime_snapshot()["state"] == &"cooldown", "poison should enter cooldown after 1.20s")
	var hits_at_cooldown := probe.received.size()
	vent.advance_time(1.0)
	_expect(probe.received.size() == hits_at_cooldown, "poison cooldown must not damage")
	vent.reset_hazard()
	_expect(vent.get_runtime_snapshot()["state"] == &"warning", "poison reset should restore warning")
	_expect(not vent.get_runtime_snapshot()["damage_active"], "poison reset must be non-damaging")
	for hit in probe.received:
		_expect(hit.amount == 1, "every poison tick should deal exactly one damage")
	probe.queue_free()
	vent.queue_free()
	await process_frame


func _validate_poison_determinism(definition: HazardDefinition) -> void:
	if definition == null:
		return
	var first := _poison_trace(definition)
	var second := _poison_trace(definition)
	_expect(var_to_bytes(first) == var_to_bytes(second), "poison timing should be deterministic")
	_expect(first.has(&"warning") and first.has(&"cooldown"), "poison cycle must include non-active states")
	_expect(definition.requires_permanent_safe_zone, "poison placement must preserve a permanent safe zone")


func _poison_trace(definition: HazardDefinition) -> Array[StringName]:
	var vent := definition.scene.instantiate() as TimedPoisonVent
	vent.set_physics_process(false)
	root.add_child(vent)
	var trace: Array[StringName] = []
	for delta in [0.2, 0.5, 0.3, 0.9, 0.5, 1.0, 0.5]:
		vent.advance_time(delta)
		trace.append(vent.get_runtime_snapshot()["state"])
	vent.free()
	return trace


func _validate_crumble_cycle(definition: HazardDefinition) -> void:
	var platform := definition.scene.instantiate() as CrumblingPlatform if definition != null else null
	_expect(platform != null, "crumble fixture should instantiate")
	if platform == null:
		return
	root.add_child(platform)
	platform.set_physics_process(false)
	_expect(platform.trigger_collapse(), "stable crumble should accept a trigger")
	_expect(platform.get_runtime_snapshot()["state"] == &"warning", "crumble should warn first")
	_expect(platform.get_runtime_snapshot()["collision_enabled"], "warning platform must remain solid")
	platform.advance_time(0.44)
	_expect(platform.get_runtime_snapshot()["state"] == &"warning", "crumble warning should last 0.45s")
	platform.advance_time(0.01)
	await process_frame
	_expect(platform.get_runtime_snapshot()["state"] == &"disabled", "crumble should disable after warning")
	_expect(not platform.get_runtime_snapshot()["collision_enabled"], "disabled crumble must remove support")
	platform.advance_time(1.8)
	await process_frame
	_expect(platform.get_runtime_snapshot()["state"] == &"respawning", "crumble should respawn after 1.8s")
	_expect(not platform.get_runtime_snapshot()["collision_enabled"], "respawn warning must not restore support early")
	platform.advance_time(0.25)
	await process_frame
	_expect(platform.get_runtime_snapshot()["state"] == &"stable", "crumble should restore after 0.25s")
	_expect(platform.get_runtime_snapshot()["collision_enabled"], "restored crumble must provide support")
	platform.trigger_collapse()
	platform.advance_time(0.45)
	platform.reset_platform()
	await process_frame
	_expect(platform.get_runtime_snapshot()["state"] == &"stable", "room reset should restore crumble")
	platform.queue_free()
	await process_frame


func _validate_crumble_determinism(definition: HazardDefinition) -> void:
	if definition == null:
		return
	var first := _crumble_trace(definition)
	var second := _crumble_trace(definition)
	_expect(var_to_bytes(first) == var_to_bytes(second), "crumble timing should be deterministic")
	_expect(definition.requires_wait_pads_and_recovery, "crumble placement must require wait pads and recovery")


func _crumble_trace(definition: HazardDefinition) -> Array[StringName]:
	var platform := definition.scene.instantiate() as CrumblingPlatform
	platform.set_physics_process(false)
	root.add_child(platform)
	platform.trigger_collapse()
	var trace: Array[StringName] = []
	for delta in [0.2, 0.25, 0.9, 0.9, 0.1, 0.15]:
		platform.advance_time(delta)
		trace.append(platform.get_runtime_snapshot()["state"])
	platform.free()
	return trace


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FLOODED_HAZARD_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
