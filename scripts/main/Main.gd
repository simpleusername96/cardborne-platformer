extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.register_roots($StageRoot, $UILayer)
	RunDirector.register_ui_roots($UILayer/ScreenRoot, $UILayer/HUDRoot)
	RunDirector.start()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if RunDirector.phase not in [RunPhase.Value.STAGE_ACTIVE, RunPhase.Value.BOSS_ACTIVE]:
		return
	get_viewport().set_input_as_handled()
	Game.toggle_settings_popup()
