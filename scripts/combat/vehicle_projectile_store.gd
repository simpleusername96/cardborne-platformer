class_name VehicleProjectileStore
extends RefCounted

## Owns preallocated typed projectile pools. Each hot loop handles one team,
## and swap retirement never shifts surviving entries or allocates replacements.

const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const PLAYER_CAPACITY := 240
const HOSTILE_CAPACITY := 120
const HOSTILE_BOSS_RESERVE := 24

var player_live: Array[ProjectileState] = []
var hostile_live: Array[ProjectileState] = []
var rejected_player := 0
var rejected_hostile := 0

var _next_serial := 1
var _ordinary_hostile_count := 0
var _boss_hostile_count := 0
var _player_pool: Array[ProjectileState] = []
var _hostile_pool: Array[ProjectileState] = []


func _init() -> void:
	for _index in PLAYER_CAPACITY:
		_player_pool.append(ProjectileState.new())
	for _index in HOSTILE_CAPACITY:
		_hostile_pool.append(ProjectileState.new())


func clear() -> void:
	while not player_live.is_empty():
		_player_pool.append(player_live.pop_back())
	while not hostile_live.is_empty():
		_hostile_pool.append(hostile_live.pop_back())
	_next_serial = 1
	_ordinary_hostile_count = 0
	_boss_hostile_count = 0
	rejected_player = 0
	rejected_hostile = 0


func add_player(projectile: Dictionary) -> bool:
	if player_live.size() >= PLAYER_CAPACITY and not _retire_oldest_player():
		rejected_player += 1
		return false
	if _player_pool.is_empty():
		rejected_player += 1
		return false
	var state: ProjectileState = _player_pool.pop_back()
	state.configure(projectile, &"player", _next_serial)
	_next_serial += 1
	player_live.append(state)
	return true


func add_hostile(projectile: Dictionary, uses_boss_reserve: bool = false) -> bool:
	var ordinary_limit := HOSTILE_CAPACITY - HOSTILE_BOSS_RESERVE
	if (
		hostile_live.size() >= HOSTILE_CAPACITY
		or (not uses_boss_reserve and _ordinary_hostile_count >= ordinary_limit)
	):
		rejected_hostile += 1
		return false
	if _hostile_pool.is_empty():
		rejected_hostile += 1
		return false
	var state: ProjectileState = _hostile_pool.pop_back()
	state.configure(projectile, &"enemy", _next_serial, uses_boss_reserve)
	_next_serial += 1
	hostile_live.append(state)
	if uses_boss_reserve:
		_boss_hostile_count += 1
	else:
		_ordinary_hostile_count += 1
	return true


func remove_player_at_swap(index: int) -> void:
	var retired := _remove_at_swap(player_live, index)
	if retired != null:
		_player_pool.append(retired)


func remove_hostile_at_swap(index: int) -> void:
	if index < 0 or index >= hostile_live.size():
		return
	if hostile_live[index].uses_boss_reserve:
		_boss_hostile_count -= 1
	else:
		_ordinary_hostile_count -= 1
	var retired := _remove_at_swap(hostile_live, index)
	if retired != null:
		_hostile_pool.append(retired)


func retain_player_only() -> void:
	while not hostile_live.is_empty():
		_hostile_pool.append(hostile_live.pop_back())
	_ordinary_hostile_count = 0
	_boss_hostile_count = 0


func clear_hostiles_in_radius(center: Vector2, radius: float) -> int:
	var cleared := 0
	var radius_squared := radius * radius
	var index := 0
	while index < hostile_live.size():
		if hostile_live[index].pos.distance_squared_to(center) <= radius_squared:
			remove_hostile_at_swap(index)
			cleared += 1
		else:
			index += 1
	return cleared


func player_count() -> int:
	return player_live.size()


func hostile_count() -> int:
	return hostile_live.size()


func live_count() -> int:
	return player_live.size() + hostile_live.size()


func debug_snapshot() -> Dictionary:
	return {
		"live": live_count(),
		"player": player_live.size(),
		"hostile": hostile_live.size(),
		"ordinary_hostile": _ordinary_hostile_count,
		"boss_hostile": _boss_hostile_count,
		"player_pool": _player_pool.size(),
		"hostile_pool": _hostile_pool.size(),
		"rejected_player": rejected_player,
		"rejected_hostile": rejected_hostile,
	}


func validate_counts() -> bool:
	if player_live.size() > PLAYER_CAPACITY or hostile_live.size() > HOSTILE_CAPACITY:
		return false
	var ordinary_count := 0
	var boss_count := 0
	for projectile in player_live:
		if projectile.team != &"player":
			return false
	for projectile in hostile_live:
		if projectile.team != &"enemy":
			return false
		if projectile.uses_boss_reserve:
			boss_count += 1
		else:
			ordinary_count += 1
	return (
		ordinary_count == _ordinary_hostile_count
		and boss_count == _boss_hostile_count
		and ordinary_count <= HOSTILE_CAPACITY - HOSTILE_BOSS_RESERVE
		and player_live.size() + _player_pool.size() == PLAYER_CAPACITY
		and hostile_live.size() + _hostile_pool.size() == HOSTILE_CAPACITY
	)


func _remove_at_swap(
	buffer: Array[ProjectileState],
	index: int
) -> ProjectileState:
	if index < 0 or index >= buffer.size():
		return null
	var retired := buffer[index]
	var last_index := buffer.size() - 1
	if index != last_index:
		buffer[index] = buffer[last_index]
	buffer.pop_back()
	return retired


func _retire_oldest_player() -> bool:
	var oldest_index := -1
	var oldest_serial := 0x7FFFFFFFFFFFFFFF
	for index in player_live.size():
		var projectile := player_live[index]
		var serial := projectile.spawn_serial
		if serial < oldest_serial:
			oldest_serial = serial
			oldest_index = index
	if oldest_index < 0:
		return false
	remove_player_at_swap(oldest_index)
	return true
