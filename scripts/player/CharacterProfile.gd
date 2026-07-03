class_name CharacterProfile
extends Resource

@export var id: String = "base_adventurer"
@export var display_name: String = "Base Adventurer"
@export var visual_color: Color = Color(0.8, 0.9, 1.0, 1.0)

@export_group("Health And Combat")
@export var max_health: int = 5
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.35
@export var attack_label: String = "Strike"
@export var attack_active_time: float = 0.12
@export var attack_range: float = 38.0
@export var attack_height: float = 30.0
@export var attack_offset_x: float = 30.0
@export var attack_offset_y: float = -26.0
@export var attack_knockback_x: float = 160.0
@export var attack_knockback_y: float = -80.0

@export_group("Movement")
@export var move_speed: float = 220.0
@export var acceleration: float = 1800.0
@export var deceleration: float = 2200.0
@export var air_acceleration: float = 1200.0
@export var gravity: float = 1200.0
@export var max_fall_speed: float = 700.0
@export var jump_velocity: float = -420.0
@export var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer_time: float = 0.12

@export_group("Dash And Damage Response")
@export var dash_speed: float = 520.0
@export var dash_duration: float = 0.13
@export var dash_cooldown: float = 0.45
@export var dash_charges: int = 1
@export var post_hit_invulnerability: float = 1.0
@export var damage_knockback_x: float = 220.0
@export var damage_knockback_y: float = -220.0


func to_stats_dictionary() -> Dictionary:
	return {
		"max_health": max_health,
		"attack_damage": attack_damage,
		"attack_cooldown": attack_cooldown,
		"attack_label": attack_label,
		"attack_active_time": attack_active_time,
		"attack_range": attack_range,
		"attack_height": attack_height,
		"attack_offset_x": attack_offset_x,
		"attack_offset_y": attack_offset_y,
		"attack_knockback_x": attack_knockback_x,
		"attack_knockback_y": attack_knockback_y,
		"move_speed": move_speed,
		"acceleration": acceleration,
		"deceleration": deceleration,
		"air_acceleration": air_acceleration,
		"gravity": gravity,
		"max_fall_speed": max_fall_speed,
		"jump_velocity": jump_velocity,
		"jump_cut_multiplier": jump_cut_multiplier,
		"coyote_time": coyote_time,
		"jump_buffer_time": jump_buffer_time,
		"dash_speed": dash_speed,
		"dash_duration": dash_duration,
		"dash_cooldown": dash_cooldown,
		"dash_charges": dash_charges,
		"post_hit_invulnerability": post_hit_invulnerability,
		"damage_knockback_x": damage_knockback_x,
		"damage_knockback_y": damage_knockback_y,
	}
