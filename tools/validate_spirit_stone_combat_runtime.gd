extends SceneTree

const SpiritRuntime = preload("res://scripts/player/SpiritStoneCombatRuntime.gd")
const EMBER := preload("res://data/spirit_stones/ember_spirit_stone.tres")
const FROST := preload("res://data/spirit_stones/frost_spirit_stone.tres")

var _failures: PackedStringArray = []


func _initialize() -> void:
	_validate_ember_sequence()
	_validate_frost_deduplication()
	if _failures.is_empty():
		print("SPIRIT_STONE_COMBAT_RUNTIME_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)


func _validate_ember_sequence() -> void:
	var runtime: Variant = SpiritRuntime.new()
	runtime.configure(EMBER)
	for index in range(3):
		var early: Dictionary = runtime.record_direct_attack(StringName("attack_%d" % index))
		_expect(not bool(early["triggered"]), "Ember triggered before the fourth attack.")
	var fourth: Dictionary = runtime.record_direct_attack(&"attack_3")
	_expect(bool(fourth["triggered"]), "Ember did not trigger on the fourth attack.")
	var duplicate: Dictionary = runtime.record_direct_attack(&"attack_3")
	_expect(not bool(duplicate["triggered"]), "Ember accepted a duplicate combat event.")
	runtime.reset()
	runtime.record_direct_attack(&"window_0")
	runtime.update(EMBER.direct_attack_window_seconds + 0.01)
	for index in range(1, 4):
		var result: Dictionary = runtime.record_direct_attack(StringName("window_%d" % index))
		_expect(not bool(result["triggered"]), "Expired Ember hit remained in the window.")


func _validate_frost_deduplication() -> void:
	var runtime: Variant = SpiritRuntime.new()
	runtime.configure(FROST)
	var first: Dictionary = runtime.record_precise_guard(&"guard_1")
	var duplicate: Dictionary = runtime.record_precise_guard(&"guard_1")
	_expect(bool(first["triggered"]), "Frost did not trigger on precise guard.")
	_expect(not bool(duplicate["triggered"]), "Frost accepted a duplicate guard event.")
	_expect(
		not bool(runtime.record_direct_attack(&"attack_1")["triggered"]),
		"Frost should not subscribe to direct attacks."
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
