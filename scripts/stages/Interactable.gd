class_name Interactable
extends Area2D

signal interacted(player: Node)

@export var prompt_text: String = "Interact"

var _player: Node


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player == null:
		return

	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact(_player)


func interact(player: Node) -> void:
	interacted.emit(player)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	_player = body
	SignalBus.interaction_prompt_changed.emit(prompt_text, true)


func _on_body_exited(body: Node) -> void:
	if body != _player:
		return

	_player = null
	SignalBus.interaction_prompt_changed.emit("", false)
