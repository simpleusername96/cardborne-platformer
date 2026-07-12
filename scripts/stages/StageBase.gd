class_name StageBase
extends Node2D

signal stage_completed(stage_id: String)

@export var stage_id: String = "stage"
@export var stage_display_name: String = "Stage"
@export var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
@export var spawn_player_on_ready: bool = true
@export var respawn_invulnerability_time: float = 1.0

var player: PlayerController
var _completed: bool = false
var current_checkpoint_id: String = "spawn"
var current_checkpoint_position: Vector2 = Vector2.ZERO

@onready var player_spawn: Marker2D = get_node_or_null("PlayerSpawn")
@onready var actors_container: Node2D = get_node_or_null("Actors")


func _ready() -> void:
	add_to_group("active_stage")
	SignalBus.stage_started.emit(stage_id, stage_display_name)
	current_checkpoint_position = _default_spawn_position()
	if spawn_player_on_ready:
		spawn_player()


func spawn_player() -> void:
	if player_scene == null:
		push_error("StageBase has no player scene.")
		return

	player = player_scene.instantiate() as PlayerController
	if player == null:
		push_error("Player scene does not instantiate as PlayerController.")
		return

	var parent_node: Node = actors_container if actors_container != null else self
	parent_node.add_child(player)
	player.global_position = _default_spawn_position()
	_after_player_respawned()


func set_checkpoint(checkpoint_id: String, checkpoint_position: Vector2, announce: bool = true) -> void:
	if checkpoint_id.is_empty():
		checkpoint_id = "checkpoint"

	if current_checkpoint_id == checkpoint_id and current_checkpoint_position.is_equal_approx(checkpoint_position):
		return

	current_checkpoint_id = checkpoint_id
	current_checkpoint_position = checkpoint_position
	SignalBus.checkpoint_changed.emit(current_checkpoint_id, current_checkpoint_position)
	if announce:
		SignalBus.status_message_changed.emit("Checkpoint: %s" % current_checkpoint_id)


func respawn_player(reason: String = "respawn") -> void:
	if player == null or not is_instance_valid(player):
		spawn_player()
	if player == null or not is_instance_valid(player):
		return

	RunState.revive_player()
	if player.has_method("respawn_at"):
		player.respawn_at(current_checkpoint_position, respawn_invulnerability_time)
	else:
		player.global_position = current_checkpoint_position
		player.velocity = Vector2.ZERO
	_after_player_respawned()
	SignalBus.status_message_changed.emit("Respawned at %s (%s)" % [current_checkpoint_id, reason])


func respawn_player_after_defeat() -> void:
	respawn_player("defeated")


func _default_spawn_position() -> Vector2:
	return player_spawn.global_position if player_spawn != null else global_position


func _after_player_respawned() -> void:
	pass


func complete_stage() -> void:
	if _completed:
		return

	_completed = true
	stage_completed.emit(stage_id)
	SignalBus.stage_cleared.emit(stage_id)
	SignalBus.status_message_changed.emit("%s clear" % stage_display_name)
