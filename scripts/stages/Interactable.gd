class_name Interactable
extends Area2D

signal interacted(player: Node)

@export var prompt_text: String = "Interact"
@export var interaction_enabled: bool = true
@export var disabled_prompt_text: String = ""

var _player: Node


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null or not interaction_enabled:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact(_player)


func interact(player: Node) -> void:
	if not interaction_enabled:
		return
	interacted.emit(player)


func set_interaction_enabled(enabled: bool) -> void:
	interaction_enabled = enabled
	if _player != null:
		SignalBus.interaction_prompt_changed.emit(_active_prompt(), not _active_prompt().is_empty())


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	var active_prompt := _active_prompt()
	SignalBus.interaction_prompt_changed.emit(active_prompt, not active_prompt.is_empty())


func _on_body_exited(body: Node) -> void:
	if body != _player:
		return

	_player = null
	SignalBus.interaction_prompt_changed.emit("", false)


func _active_prompt() -> String:
	return prompt_text if interaction_enabled else disabled_prompt_text
