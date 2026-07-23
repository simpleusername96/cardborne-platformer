extends SceneTree

const MAIN_SCENE := "res://scenes/main/GameRoot.tscn"


class PauseProbe:
	extends Node

	var failures: Array[String] = []


	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		call_deferred("_run")


	func _run() -> void:
		var packed := load(MAIN_SCENE) as PackedScene
		_expect(packed != null, "main scene loads")
		if packed == null:
			_finish()
			return
		var game_root := packed.instantiate()
		get_tree().root.add_child(game_root)
		await get_tree().process_frame
		await get_tree().process_frame
		var run = game_root.get_node_or_null("VehicleRun")
		var ui = run.get_node_or_null("VehicleStageUI") if run != null else null
		_expect(run != null and ui != null, "pause runtime and UI are active")
		if run == null or ui == null:
			game_root.queue_free()
			_finish()
			return

		run.mode = run.RunMode.PLAYING
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_send_escape(true)
		await get_tree().process_frame
		_send_escape(false)
		await get_tree().process_frame
		_expect(get_tree().paused, "Escape pause freezes the complete scene tree")
		_expect(run.mode == run.RunMode.PAUSED, "pause enters the paused run mode")
		_expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause restores the system cursor")

		_send_escape(true)
		await get_tree().process_frame
		_send_escape(false)
		await get_tree().process_frame
		_expect(not get_tree().paused, "Escape resumes the scene tree from the pause surface")
		_expect(run.mode == run.RunMode.PLAYING, "Escape returns to gameplay mode")
		if get_tree().paused:
			run.call("_resume_run")
		game_root.queue_free()
		await get_tree().process_frame
		_finish()


	func _send_escape(pressed: bool) -> void:
		var escape := InputEventAction.new()
		escape.action = &"pause"
		escape.pressed = pressed
		Input.parse_input_event(escape)


	func _expect(condition: bool, message: String) -> void:
		if not condition:
			failures.append(message)


	func _finish() -> void:
		if failures.is_empty():
			print("VEHICLE_PAUSE_VALIDATION_OK")
			get_tree().quit(0)
		else:
			for failure in failures:
				push_error(failure)
			get_tree().quit(1)


func _initialize() -> void:
	root.add_child(PauseProbe.new())
