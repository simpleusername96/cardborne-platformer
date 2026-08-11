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
		ui.show_gameplay()
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		await _tap_escape()
		_expect(get_tree().paused, "Escape pause freezes the complete scene tree")
		_expect(run.mode == run.RunMode.PAUSED, "pause enters the paused run mode")
		_expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause restores the system cursor")
		_expect(
			ui.debug_surface_visible("pause"),
			"pause surface is visible"
		)

		ui.call("_show_settings", "pause")
		await _tap_escape()
		_expect(get_tree().paused, "closing pause settings keeps gameplay frozen")
		_expect(
			ui.debug_surface_visible("pause"),
			"Escape returns from settings to pause"
		)

		ui.call("_show_guidebook", "pause")
		await _tap_escape()
		_expect(get_tree().paused, "closing the guidebook keeps gameplay frozen")
		_expect(
			ui.debug_surface_visible("pause"),
			"Escape returns from the guidebook to pause"
		)

		await _tap_escape()
		_expect(not get_tree().paused, "Escape resumes the scene tree from the pause surface")
		_expect(run.mode == run.RunMode.PLAYING, "Escape returns to gameplay mode")
		_expect(ui._hud.visible, "gameplay HUD returns after resume")
		await _tap_escape()
		ui._pause_panel.abort_button.pressed.emit()
		await get_tree().process_frame
		_expect(not get_tree().paused, "Abort releases the paused scene tree")
		_expect(run.mode == run.RunMode.DEPLOYMENT, "Abort routes directly to Deployment")
		_expect(ui.debug_surface_visible("deployment"), "Deployment replaces the removed Garage detour")
		if get_tree().paused:
			run.call("_resume_run")
		game_root.queue_free()
		await get_tree().process_frame
		_finish()


	func _tap_escape() -> void:
		_send_escape(true)
		await get_tree().process_frame
		_send_escape(false)
		await get_tree().process_frame


	func _send_escape(pressed: bool) -> void:
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = pressed
		get_tree().root.push_input(escape)


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
