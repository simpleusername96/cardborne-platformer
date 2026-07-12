class_name CharacterCombatRuntime
extends RefCounted

# Character-owned combat state hook; the controller remains the timing and damage owner.
var controller: Node
var player: Node
var kit: Resource
var progression_effects: Array[ProgressionBehaviorEffect] = []


func configure(
	p_controller: Node,
	p_player: Node,
	p_kit: Resource,
	effects: Array[ProgressionBehaviorEffect]
) -> void:
	controller = p_controller
	player = p_player
	kit = p_kit
	progression_effects = effects.duplicate()


func begin_stage() -> void:
	pass


func reset() -> void:
	pass


func update(_delta: float) -> void:
	pass


func apply_movement(_delta: float) -> bool:
	return false


func prepare_attack(_definition: AttackDefinition, _modifiers: Dictionary) -> void:
	pass


func activate_attack(_definition: AttackDefinition) -> bool:
	return false


func prepare_damage(
	_definition: AttackDefinition,
	_target: Node,
	_target_state: Dictionary,
	_source_modifiers: Dictionary,
	_secondary_hit: bool,
	_event_context: Dictionary
) -> Dictionary:
	return {}


func modify_knockback(
	_definition: AttackDefinition,
	_target_state: Dictionary,
	knockback: Vector2
) -> Vector2:
	return knockback


func notify_target_hit(_event: Dictionary) -> void:
	pass


func notify_wall_collision() -> void:
	pass


func notify_attack_finished(_event: Dictionary) -> void:
	pass


func notify_attack_interrupted(_event: Dictionary) -> void:
	pass


func blocks_incoming_damage(_damage_info: DamageInfo) -> bool:
	return false


func resolve_incoming_damage(_amount: int, current_result: Dictionary) -> Dictionary:
	return current_result


func notify_health_changed(_previous_health: int, _current_health: int) -> void:
	pass


func notify_player_damaged(_resolved_damage: int) -> void:
	pass


func notify_extra_jump_performed() -> void:
	pass


func notify_dash_completed(_start_position: Vector2, _end_position: Vector2) -> void:
	pass


func get_state_snapshot() -> Dictionary:
	return {}
