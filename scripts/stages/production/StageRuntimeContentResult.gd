class_name StageRuntimeContentResult
extends RefCounted

var success: bool
var all_enemies: Array[EnemyBase]
var required_enemies: Array[EnemyBase]
var hazards: Array[Node2D]
var rewards: Array[StageRewardInteractable]
var checkpoint: StageCheckpoint
var fall_reset: FallResetZone
var errors: PackedStringArray


func _init(
	was_successful: bool = false,
	spawned_enemies: Array[EnemyBase] = [],
	spawned_required_enemies: Array[EnemyBase] = [],
	spawned_hazards: Array[Node2D] = [],
	spawned_rewards: Array[StageRewardInteractable] = [],
	spawned_checkpoint: StageCheckpoint = null,
	spawned_fall_reset: FallResetZone = null,
	spawn_errors: PackedStringArray = PackedStringArray()
) -> void:
	success = was_successful
	all_enemies = spawned_enemies.duplicate()
	required_enemies = spawned_required_enemies.duplicate()
	hazards = spawned_hazards.duplicate()
	rewards = spawned_rewards.duplicate()
	checkpoint = spawned_checkpoint
	fall_reset = spawned_fall_reset
	errors = spawn_errors.duplicate()
