extends SceneTree

var _failures: Array[String] = []
var _run_state: Node
var _profile_state: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_run_state = root.get_node_or_null("/root/RunState")
	_profile_state = root.get_node_or_null("/root/ProfileState")
	_expect(_run_state != null, "build preview fixture needs RunState")
	_expect(_profile_state != null, "build preview fixture needs ProfileState")
	if _run_state == null or _profile_state == null:
		_finish()
		return
	_expect(_run_state.start_new_run(0, 7319), "Warrior preview fixture run should start")
	_validate_loadout_previews()
	_validate_forge_preview_matches_commit()
	_finish()


func _validate_loadout_previews() -> void:
	var snapshot: Dictionary = _profile_state.get_character_loadout_snapshot(
		_run_state.selected_profile
	)
	_expect(not snapshot.get("base_stats", {}).is_empty(), "loadout snapshot should expose base stats")
	var current_stats: Dictionary = snapshot.get("effective_stats", {})
	var saw_changed_candidate := false
	for slot_row in snapshot.get("slots", []):
		for option in slot_row.get("options", []):
			_expect(option.has("projected_stats"), "equipment option should expose projected stats")
			_expect(option.has("stat_deltas"), "equipment option should expose stat deltas")
			if bool(option.get("equipped", false)):
				_expect(
					option.get("projected_stats", {}) == current_stats,
					"equipped item preview should match current build"
				)
			if not option.get("stat_deltas", []).is_empty():
				saw_changed_candidate = true
	_expect(saw_changed_candidate, "loadout should include a candidate with a visible stat change")


func _validate_forge_preview_matches_commit() -> void:
	_run_state.coins = 100
	var begin: Dictionary = _run_state.begin_rest_forge()
	_expect(bool(begin.get("ok", false)), "rest/forge should begin")
	var snapshot: Dictionary = begin.get("snapshot", {})
	var items: Array = snapshot.get("items", [])
	_expect(not items.is_empty(), "forge snapshot should expose equipped items")
	if items.is_empty():
		return
	var item: Dictionary = items[0]
	_expect(item.has("base_effects"), "forge item should expose its base effects")
	_expect(not String(item.get("description", "")).is_empty(), "forge item should expose its base description")
	var offer_result: Dictionary = _run_state.begin_forge_offer(StringName(item.get("id", "")))
	_expect(bool(offer_result.get("ok", false)), "equipped item should open a forge offer")
	snapshot = offer_result.get("snapshot", {})
	var offers: Array = snapshot.get("forge_offer", [])
	_expect(offers.size() == 3, "forge should expose exactly three previewed affixes")
	var chosen: Dictionary = {}
	for offer in offers:
		_expect(offer.has("projected_stats"), "forge offer should expose projected stats")
		_expect(offer.has("stat_deltas"), "forge offer should expose stat deltas")
		_expect(int(offer.get("final_coins", -1)) == 85, "forge offer should expose final coin balance")
		if chosen.is_empty() and not offer.get("stat_deltas", []).is_empty():
			chosen = offer
	_expect(not chosen.is_empty(), "forge offer should contain a measurable stat preview")
	if chosen.is_empty():
		return
	var commit: Dictionary = _run_state.commit_forge_affix(
		StringName(item.get("id", "")),
		StringName(chosen.get("id", "")),
		false
	)
	_expect(bool(commit.get("ok", false)), "previewed forge affix should commit")
	var applied_stats: Dictionary = _run_state.get_effective_stats()
	for delta in chosen.get("stat_deltas", []):
		var stat_id := String(delta.get("stat_id", ""))
		_expect(
			is_equal_approx(float(applied_stats.get(stat_id, 0.0)), float(delta.get("after", 0.0))),
			"forge preview should match applied stat '%s'" % stat_id
		)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("BUILD_PREVIEW_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
