class_name VehicleEnemyLocalSteering
extends RefCounted

## Resolves actual ordinary-enemy body penetration without maintaining spacing.

const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const SEARCH_RADIUS := 120.0
const MAX_OVERLAP_NEIGHBORS := 8
const ROLE_WEIGHT := 0.55
const SEPARATION_WEIGHT := 0.45
const CACHE_CAPACITY := 320

var _cached_generations := PackedInt32Array()
var _cached_valid := PackedByteArray()
var _cached_velocity := PackedVector2Array()


func _init() -> void:
	_cached_generations.resize(CACHE_CAPACITY)
	_cached_valid.resize(CACHE_CAPACITY)
	_cached_velocity.resize(CACHE_CAPACITY)


func adjusted_velocity(
	enemy: EnemyState,
	role_velocity: Vector2,
	spatial_grid,
	_live_enemies: Array[EnemyState],
	refresh_overlap: bool = true
) -> Vector2:
	if role_velocity.length_squared() <= 0.001:
		return role_velocity
	var slot := enemy.runtime_slot
	var generation := enemy.runtime_generation
	if (
		not refresh_overlap
		and slot >= 0
		and slot < CACHE_CAPACITY
		and _cached_valid[slot] != 0
		and _cached_generations[slot] == generation
	):
		var cached := _cached_velocity[slot]
		return cached.normalized() * role_velocity.length()
	if not refresh_overlap:
		_cache(slot, generation, role_velocity)
		return role_velocity
	var overlap_count: int = spatial_grid.cached_local_overlap_count(enemy)
	if overlap_count <= 0:
		_cache(slot, generation, role_velocity)
		return role_velocity
	var separation_direction: Vector2 = (
		spatial_grid.cached_local_separation_direction(enemy)
	)
	var separation_velocity := separation_direction * role_velocity.length()
	var adjusted := (
		role_velocity * ROLE_WEIGHT
		+ separation_velocity * SEPARATION_WEIGHT
	).limit_length(role_velocity.length())
	_cache(slot, generation, adjusted)
	return adjusted


func _cache(slot: int, generation: int, velocity: Vector2) -> void:
	if slot < 0 or slot >= CACHE_CAPACITY:
		return
	_cached_generations[slot] = generation
	_cached_valid[slot] = 1
	_cached_velocity[slot] = velocity
