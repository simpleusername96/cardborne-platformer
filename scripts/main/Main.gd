extends Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.register_roots($StageRoot, $UILayer)
	RunDirector.register_ui_roots($UILayer/ScreenRoot, $UILayer/HUDRoot)
	RunDirector.start()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if Game.settings_open or Game.reward_choice_open:
		return
	if Game.pause_menu_open:
		get_viewport().set_input_as_handled()
		Game.set_pause_menu_open(false)
		return
	if RunDirector.phase not in [
		RunPhase.Value.TRIAL_ACTIVE,
		RunPhase.Value.STAGE_ACTIVE,
		RunPhase.Value.BOSS_ACTIVE,
	]:
		return
	get_viewport().set_input_as_handled()
	Game.set_pause_menu_open(true)
