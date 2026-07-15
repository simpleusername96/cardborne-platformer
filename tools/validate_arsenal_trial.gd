extends SceneTree

const TRIAL_SCENE_PATH := "res://scenes/stages/trial/ArsenalTrial.tscn"
const TRIAL_CONTROLLER_PATH := "res://scripts/stages/trial/ArsenalTrial.gd"
const EXPECTED_ROOM_IDS: Array[StringName] = [
	&"movement",
	&"context_attack",
	&"guard",
	&"pickup_interaction",
	&"exit",
]
const EXPECTED_GEOMETRY := {
	"Boundaries/LeftWall": {"position": Vector2(-20, 360), "size": Vector2(40, 720)},
	"Boundaries/RightWall": {"position": Vector2(3460, 360), "size": Vector2(40, 720)},
	"Rooms/01Movement/FloorStart": {"position": Vector2(150, 670), "size": Vector2(300, 60)},
	"Rooms/01Movement/JumpPlatform": {"position": Vector2(455, 620), "size": Vector2(130, 60)},
	"Rooms/01Movement/FloorEnd": {"position": Vector2(600, 670), "size": Vector2(160, 60)},
	"Rooms/01Movement/ExitGate": {"position": Vector2(680, 380), "size": Vector2(24, 520)},
	"Rooms/02ContextAttack/Floor": {"position": Vector2(1020, 670), "size": Vector2(680, 60)},
	"Rooms/02ContextAttack/ExitGate": {"position": Vector2(1360, 380), "size": Vector2(24, 520)},
	"Rooms/03Guard/Floor": {"position": Vector2(1700, 670), "size": Vector2(680, 60)},
	"Rooms/03Guard/ExitGate": {"position": Vector2(2040, 380), "size": Vector2(24, 520)},
	"Rooms/04PickupInteraction/Floor": {"position": Vector2(2380, 670), "size": Vector2(680, 60)},
	"Rooms/04PickupInteraction/ExitGate": {"position": Vector2(2720, 380), "size": Vector2(24, 520)},
	"Rooms/05Exit/Floor": {"position": Vector2(3080, 670), "size": Vector2(720, 60)},
}
const TRIAL_SOURCE_PATHS := [
	"res://scripts/stages/trial/ArsenalTrial.gd",
	"res://scripts/stages/trial/ArsenalTrialIntentTarget.gd",
	"res://scripts/stages/trial/ArsenalTrialGuardCheck.gd",
	"res://scripts/stages/trial/ArsenalTrialPickup.gd",
	TRIAL_SCENE_PATH,
]
const GENERATED_GEOMETRY_TOKENS := [
	"scripts/generation/",
	"StageAssembler",
	"CuratedStagePlanBuilder",
	"RoomTemplateHost",
	"RandomNumberGenerator",
	"randi(",
	"randf(",
	"StaticBody2D.new",
	"CollisionShape2D.new",
	"RectangleShape2D.new",
]


class BaselineProbe:
	extends Node

	var calls: Array[Dictionary] = []


	func resolve_tutorial(completed: bool, transaction_id: StringName) -> Dictionary:
		calls.append({"completed": completed, "transaction_id": transaction_id})
		return {
			"ok": true,
			"changed": true,
			"duplicate": false,
			"code": &"tutorial_completed" if completed else &"tutorial_skipped",
			"mechanical_snapshot": {
				"baseline_revision": 1,
				"tutorial_resolved": true,
			},
			"telemetry": {"completed": completed, "skipped": not completed},
		}


var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var localization := root.get_node_or_null("/root/UILocalization")
	if localization != null:
		localization.call("set_locale", "en")
	var packed := load(TRIAL_SCENE_PATH) as PackedScene
	if packed == null:
		_failures.append("Arsenal Trial scene could not be loaded.")
		_finish()
		return

	_validate_source_boundaries()
	await _validate_authored_layout(packed)
	await _validate_korean_ui(packed, localization)
	if localization != null:
		localization.call("set_locale", "en")
	await _validate_resolution_parity(packed)
	_finish()


func _validate_korean_ui(packed: PackedScene, localization: Node) -> void:
	_expect(localization != null, "Arsenal Trial localization owner should be available.")
	if localization == null:
		return
	localization.call("set_locale", "ko")
	var trial := await _instantiate_trial(packed, "KoreanTrial")
	if trial == null:
		return
	var beat := trial.get_node("TrialUI/PromptPanel/Margin/VBox/BeatLabel") as Label
	var prompt := trial.get_node("TrialUI/PromptPanel/Margin/VBox/PromptLabel") as Label
	var skip := trial.get_node("TrialUI/SkipButton") as Button
	_expect(beat.text == "움직여 보기", "Trial beat should localize to Korean.")
	_expect(prompt.text.contains("방향키"), "Trial prompt should explain Korean controls.")
	_expect(skip.text == "연습 건너뛰기", "Trial skip action should localize to Korean.")
	for viewport_size in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = viewport_size
		await process_frame
		_expect(
			_rect_fits((trial.get_node("TrialUI/PromptPanel") as Control).get_global_rect(), viewport_size),
			"Korean Trial prompt should fit %s." % viewport_size
		)
		_expect(_rect_fits(skip.get_global_rect(), viewport_size), "Korean Trial skip should fit %s." % viewport_size)
	trial.queue_free()
	await process_frame


func _validate_source_boundaries() -> void:
	for dependency in ResourceLoader.get_dependencies(TRIAL_SCENE_PATH):
		var dependency_path := String(dependency)
		for token in GENERATED_GEOMETRY_TOKENS:
			_expect(
				not dependency_path.contains(token),
				"Trial scene dependency must not reference generated geometry: %s" % dependency_path
			)

	for path in TRIAL_SOURCE_PATHS:
		_expect(FileAccess.file_exists(path), "Trial source should exist: %s" % path)
		if not FileAccess.file_exists(path):
			continue
		var source := FileAccess.get_file_as_string(path)
		for token in GENERATED_GEOMETRY_TOKENS:
			_expect(
				not source.contains(token),
				"Trial source %s must not construct or request generated geometry (%s)." % [
					path,
					token,
				]
			)

	var controller_source := FileAccess.get_file_as_string(TRIAL_CONTROLLER_PATH)
	_expect(
		controller_source.contains(
			"func request_complete() -> Dictionary:\n\treturn _request_resolution(OUTCOME_COMPLETED)"
		),
		"Completion should delegate directly to the shared resolution boundary."
	)
	_expect(
		controller_source.contains(
			"func request_skip() -> Dictionary:\n\treturn _request_resolution(OUTCOME_SKIPPED)"
		),
		"Skip should delegate directly to the shared resolution boundary."
	)
	for duplicated_reward_token in [
		"traveler_sword",
		"hunting_bow",
		"round_shield",
		"ember_spirit_stone",
		"crafted_equipment",
		"unlocked_blueprints",
	]:
		_expect(
			not controller_source.contains(duplicated_reward_token),
			"Trial controller must not duplicate baseline reward logic (%s)." % duplicated_reward_token
		)


func _validate_authored_layout(packed: PackedScene) -> void:
	var trial := await _instantiate_trial(packed, "AuthoredLayoutTrial")
	if trial == null:
		return

	var room_ids: Array[StringName] = trial.call("get_room_ids")
	_expect(room_ids == EXPECTED_ROOM_IDS, "Trial should expose the exact five authored room IDs.")
	var room_nodes: Array[Node] = []
	for child in trial.get_node("Rooms").get_children():
		if child.is_in_group("arsenal_trial_room"):
			room_nodes.append(child)
	_expect(room_nodes.size() == EXPECTED_ROOM_IDS.size(), "Trial should contain exactly five room nodes.")
	for index in mini(room_nodes.size(), EXPECTED_ROOM_IDS.size()):
		_expect(
			StringName(room_nodes[index].get_meta("room_id", &"")) == EXPECTED_ROOM_IDS[index],
			"Trial room %d should preserve authored order and identity." % (index + 1)
		)

	var before_count := _descendant_count(trial)
	await process_frame
	await process_frame
	_expect(
		_descendant_count(trial) == before_count,
		"Trial should not create runtime scene nodes when player spawning is disabled."
	)

	var first_signature := _geometry_signature(trial)
	_validate_geometry_signature(first_signature)
	await _validate_ui_fit(trial, Vector2i(960, 540))
	await _validate_ui_fit(trial, Vector2i(1280, 720))
	await _validate_ui_fit(trial, Vector2i(1920, 1080))

	trial.queue_free()
	await process_frame
	var repeated := await _instantiate_trial(packed, "RepeatedLayoutTrial")
	if repeated != null:
		_expect(
			_geometry_signature(repeated) == first_signature,
			"Repeated Trial instances should have an identical authored geometry signature."
		)
		repeated.queue_free()
		await process_frame


func _validate_resolution_parity(packed: PackedScene) -> void:
	var complete := await _exercise_resolution(packed, &"completed")
	var skip := await _exercise_resolution(packed, &"skipped")
	if complete.is_empty() or skip.is_empty():
		return

	_expect(bool(complete["result"].get("ok", false)), "Complete request should resolve.")
	_expect(bool(skip["result"].get("ok", false)), "Skip request should resolve.")
	_expect(complete["calls"].size() == 1, "Complete should call the baseline resolver once.")
	_expect(skip["calls"].size() == 1, "Skip should call the baseline resolver once.")
	if complete["calls"].size() == 1 and skip["calls"].size() == 1:
		var complete_call: Dictionary = complete["calls"][0]
		var skip_call: Dictionary = skip["calls"][0]
		_expect(bool(complete_call["completed"]), "Complete should pass completed=true.")
		_expect(not bool(skip_call["completed"]), "Skip should pass completed=false.")
		_expect(
			complete_call["transaction_id"] == skip_call["transaction_id"],
			"Complete and skip should use the same baseline transaction ID."
		)
		_expect(
			complete_call["transaction_id"] == &"tutorial:baseline",
			"Trial should use the canonical baseline transaction ID."
		)

	var complete_baseline: Dictionary = complete["result"].get("baseline", {})
	var skip_baseline: Dictionary = skip["result"].get("baseline", {})
	_expect(
		complete_baseline.get("mechanical_snapshot", {})
		== skip_baseline.get("mechanical_snapshot", {}),
		"Complete and skip should receive identical mechanical baseline snapshots."
	)
	_expect(
		complete["requested_transactions"] == skip["requested_transactions"],
		"Complete and skip should publish the same baseline transaction request."
	)
	_expect(
		complete["terminal_events"] == [&"completed", &"resolved:completed"],
		"Complete should publish one completed terminal path."
	)
	_expect(
		skip["terminal_events"] == [&"skipped", &"resolved:skipped"],
		"Skip should publish one skipped terminal path."
	)
	_expect(
		bool(complete["repeat"].get("duplicate", false))
		and bool(skip["repeat"].get("duplicate", false)),
		"Repeated terminal requests should be locally idempotent."
	)
	_expect(
		not bool(complete["premature"].get("ok", true))
		and complete["premature"].get("code") == &"trial_incomplete",
		"Completion should fail before the four teaching gates are cleared."
	)

	var unresolved := await _instantiate_trial(packed, "MissingResolverTrial")
	if unresolved != null:
		var failure_events: Array[StringName] = []
		unresolved.baseline_resolution_failed.connect(
			func(_outcome: StringName, code: StringName) -> void: failure_events.append(code)
		)
		var missing_result: Dictionary = unresolved.call("request_skip")
		_expect(not bool(missing_result.get("ok", true)), "A missing resolver should fail closed.")
		_expect(
			failure_events == [&"missing_baseline_resolver"],
			"A missing resolver should publish one stable failure code."
		)
		unresolved.queue_free()
		await process_frame


func _exercise_resolution(packed: PackedScene, outcome: StringName) -> Dictionary:
	var probe := BaselineProbe.new()
	probe.name = "BaselineProbe_%s" % outcome
	root.add_child(probe)
	var trial := await _instantiate_trial(packed, "ResolutionTrial_%s" % outcome)
	if trial == null:
		probe.queue_free()
		await process_frame
		return {}
	trial.call("configure_baseline_resolution_target", probe, &"resolve_tutorial")

	var terminal_events: Array[StringName] = []
	var requested_transactions: Array[StringName] = []
	trial.trial_completed.connect(func() -> void: terminal_events.append(&"completed"))
	trial.trial_skipped.connect(func() -> void: terminal_events.append(&"skipped"))
	trial.trial_resolved.connect(
		func(resolved_outcome: StringName) -> void:
			terminal_events.append(StringName("resolved:%s" % resolved_outcome))
	)
	trial.resolution_requested.connect(
		func(_requested_outcome: StringName, transaction_id: StringName) -> void:
			requested_transactions.append(transaction_id)
	)

	var premature: Dictionary = {}
	if outcome == &"completed":
		premature = trial.call("request_complete")
		_expect(probe.calls.is_empty(), "Premature completion must not call the baseline resolver.")
		await _advance_trial_to_exit(trial)

	var result: Dictionary = (
		trial.call("request_complete")
		if outcome == &"completed"
		else trial.call("request_skip")
	)
	var repeat: Dictionary = (
		trial.call("request_skip")
		if outcome == &"completed"
		else trial.call("request_complete")
	)
	var snapshot := {
		"result": result.duplicate(true),
		"repeat": repeat.duplicate(true),
		"premature": premature.duplicate(true),
		"calls": probe.calls.duplicate(true),
		"terminal_events": terminal_events.duplicate(),
		"requested_transactions": requested_transactions.duplicate(),
	}
	trial.queue_free()
	probe.queue_free()
	await process_frame
	return snapshot


func _advance_trial_to_exit(trial: Node) -> void:
	for room_id in EXPECTED_ROOM_IDS.slice(0, 4):
		trial.call("_complete_beat", room_id)
	await process_frame
	for gate_path in [
		"Rooms/01Movement/ExitGate/CollisionShape2D",
		"Rooms/02ContextAttack/ExitGate/CollisionShape2D",
		"Rooms/03Guard/ExitGate/CollisionShape2D",
		"Rooms/04PickupInteraction/ExitGate/CollisionShape2D",
	]:
		var gate := trial.get_node(gate_path) as CollisionShape2D
		_expect(gate.disabled, "Completed teaching beats should open gate %s." % gate_path)
	var prompt := trial.get_node("TrialUI/PromptPanel/Margin/VBox/PromptLabel") as Label
	_expect(prompt.text == "E opens the exit", "The fifth beat should direct the player to the exit.")


func _instantiate_trial(packed: PackedScene, node_name: String) -> Node:
	var trial := packed.instantiate()
	if trial == null:
		_failures.append("Trial instance %s could not be created." % node_name)
		return null
	for required_method in [
		"get_room_ids",
		"request_complete",
		"request_skip",
		"configure_baseline_resolution_target",
	]:
		if not trial.has_method(required_method):
			_failures.append(
				"Trial instance %s is missing method %s; its controller did not load." % [
					node_name,
					required_method,
				]
			)
			trial.free()
			return null
	trial.name = node_name
	trial.set("spawn_player_on_ready", false)
	root.add_child(trial)
	await process_frame
	return trial


func _geometry_signature(trial: Node) -> Dictionary:
	var signature: Dictionary = {}
	var static_bodies := trial.find_children("*", "StaticBody2D", true, false)
	for raw_body in static_bodies:
		var body := raw_body as StaticBody2D
		_expect(
			body.is_in_group("arsenal_trial_authored_geometry"),
			"Every Trial StaticBody2D should be marked as authored geometry: %s" % body.name
		)
		var collision := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
		_expect(collision != null, "Authored geometry needs a collision shape: %s" % body.name)
		if collision == null:
			continue
		_expect(
			collision.shape is RectangleShape2D,
			"Authored geometry should use explicit rectangle shapes: %s" % body.name
		)
		if not collision.shape is RectangleShape2D:
			continue
		var path := String(trial.get_path_to(body))
		signature[path] = {
			"position": body.global_position,
			"size": (collision.shape as RectangleShape2D).size,
			"disabled": collision.disabled,
		}
	return signature


func _validate_geometry_signature(signature: Dictionary) -> void:
	_expect(
		signature.size() == EXPECTED_GEOMETRY.size(),
		"Trial should have exactly %d authored geometry bodies, found %d." % [
			EXPECTED_GEOMETRY.size(),
			signature.size(),
		]
	)
	for path in EXPECTED_GEOMETRY:
		_expect(signature.has(path), "Authored geometry is missing: %s" % path)
		if not signature.has(path):
			continue
		var actual: Dictionary = signature[path]
		var expected: Dictionary = EXPECTED_GEOMETRY[path]
		_expect(
			(actual["position"] as Vector2).is_equal_approx(expected["position"]),
			"Authored geometry position changed for %s." % path
		)
		_expect(
			(actual["size"] as Vector2).is_equal_approx(expected["size"]),
			"Authored geometry size changed for %s." % path
		)
		_expect(not bool(actual["disabled"]), "Authored geometry should start enabled: %s" % path)


func _validate_ui_fit(trial: Node, viewport_size: Vector2i) -> void:
	root.size = viewport_size
	await process_frame
	var prompt := trial.get_node("TrialUI/PromptPanel") as Control
	var skip := trial.get_node("TrialUI/SkipButton") as Button
	_expect(_rect_fits(prompt.get_global_rect(), viewport_size), "Prompt panel should fit %s." % viewport_size)
	_expect(_rect_fits(skip.get_global_rect(), viewport_size), "Skip button should fit %s." % viewport_size)
	_expect(
		not prompt.get_global_rect().intersects(skip.get_global_rect()),
		"Prompt panel and skip button should not overlap at %s." % viewport_size
	)
	_expect(
		skip.size.x >= 120.0 and skip.size.y >= 48.0,
		"Skip button should keep a readable 48px target at %s." % viewport_size
	)
	_expect(skip.focus_mode == Control.FOCUS_ALL, "Skip button should remain keyboard-focusable.")
	_expect(skip.text == "Skip Trial", "Skip control should use short player-facing copy.")
	for label_path in [
		"TrialUI/PromptPanel/Margin/VBox/BeatLabel",
		"TrialUI/PromptPanel/Margin/VBox/PromptLabel",
		"TrialUI/PromptPanel/Margin/VBox/ProgressLabel",
	]:
		var label := trial.get_node(label_path) as Label
		_expect(not label.text.contains("\n"), "Trial prompt text should stay compact: %s" % label_path)
		_expect(label.text.length() <= 32, "Trial prompt text should stay game-like: %s" % label_path)
		_expect(
			label.get_theme_font_size("font_size") >= 16,
			"Trial prompt text should be at least 16px: %s" % label_path
		)


func _rect_fits(rect: Rect2, viewport_size: Vector2i) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	return viewport_rect.encloses(rect)


func _descendant_count(node: Node) -> int:
	var count := 1
	for child in node.get_children():
		count += _descendant_count(child)
	return count


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print(
			"ARSENAL_TRIAL_VALIDATION_OK "
			+ "rooms=5 outcomes=2 geometry=13 generated=none "
			+ "ui=960x540,1280x720,1920x1080"
		)
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
