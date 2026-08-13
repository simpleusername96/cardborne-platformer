class_name VehicleProjectileStore
extends RefCounted

## Owns fixed player/hostile projectile columns. The live state arrays are a
## compatibility facade; hot consumers must use slots plus generations and call
## sync_* after changing a facade state directly.

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

# Slot columns never move when live arrays use swap retirement. The parallel
# arrays intentionally contain only numeric/vector hot fields.
var player_position := PackedVector2Array()
var player_velocity := PackedVector2Array()
var player_radius := PackedFloat32Array()
var player_damage := PackedFloat32Array()
var player_life := PackedFloat32Array()
var player_generation := PackedInt32Array()
var player_live_flags := PackedByteArray()
var hostile_position := PackedVector2Array()
var hostile_velocity := PackedVector2Array()
var hostile_radius := PackedFloat32Array()
var hostile_damage := PackedFloat32Array()
var hostile_life := PackedFloat32Array()
var hostile_generation := PackedInt32Array()
var hostile_live_flags := PackedByteArray()


func _init() -> void:
	_resize_columns()
	for _index in PLAYER_CAPACITY:
		var state := ProjectileState.new()
		state.storage_slot = _index
		_player_pool.append(state)
	for _index in HOSTILE_CAPACITY:
		var state := ProjectileState.new()
		state.storage_slot = _index
		_hostile_pool.append(state)


func clear() -> void:
	while not player_live.is_empty():
		var player: ProjectileState = player_live.pop_back()
		_deactivate_player(player)
		_player_pool.append(player)
	while not hostile_live.is_empty():
		var hostile: ProjectileState = hostile_live.pop_back()
		_deactivate_hostile(hostile)
		_hostile_pool.append(hostile)
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
	_activate_player(state)
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
	_activate_hostile(state)
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
		_deactivate_player(retired)
		_player_pool.append(retired)


func remove_hostile_at_swap(index: int) -> void:
	if index < 0 or index >= hostile_live.size():
		return
	var state := hostile_live[index]
	if state.uses_boss_reserve:
		_boss_hostile_count -= 1
	else:
		_ordinary_hostile_count -= 1
	var retired := _remove_at_swap(hostile_live, index)
	if retired != null:
		_deactivate_hostile(retired)
		_hostile_pool.append(retired)


func retain_player_only() -> void:
	while not hostile_live.is_empty():
		var retired: ProjectileState = hostile_live.pop_back()
		_deactivate_hostile(retired)
		_hostile_pool.append(retired)
	_ordinary_hostile_count = 0
	_boss_hostile_count = 0


func retire_boss_hostiles() -> int:
	var retired_count := 0
	var index := 0
	while index < hostile_live.size():
		if hostile_live[index].uses_boss_reserve:
			remove_hostile_at_swap(index)
			retired_count += 1
		else:
			index += 1
	return retired_count


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


func player_handle_at(index: int) -> Vector2i:
	return _handle_at(player_live, index)


func hostile_handle_at(index: int) -> Vector2i:
	return _handle_at(hostile_live, index)


func resolves_player_handle(slot: int, generation: int) -> bool:
	return _resolves(player_live_flags, player_generation, slot, generation)


func resolves_hostile_handle(slot: int, generation: int) -> bool:
	return _resolves(hostile_live_flags, hostile_generation, slot, generation)


func player_for_handle(slot: int, generation: int) -> ProjectileState:
	return _state_for_handle(player_live, slot, generation, true)


func hostile_for_handle(slot: int, generation: int) -> ProjectileState:
	return _state_for_handle(hostile_live, slot, generation, false)


## Compatibility facade mutations do not update packed columns implicitly.
## VehicleRun integration must call this after each surviving player update.
func sync_player_at(index: int) -> void:
	if index >= 0 and index < player_live.size():
		_sync_player(player_live[index])


## VehicleRun integration must call this after each surviving hostile update.
func sync_hostile_at(index: int) -> void:
	if index >= 0 and index < hostile_live.size():
		_sync_hostile(hostile_live[index])


func sync_all() -> void:
	for state in player_live:
		_sync_player(state)
	for state in hostile_live:
		_sync_hostile(state)


## Caller-owned packed receipts avoid allocating candidate arrays in hot loops.
func fill_player_candidate_slots_into(output: PackedInt32Array) -> int:
	return _fill_candidate_slots(player_live, output)


func fill_hostile_candidate_slots_into(output: PackedInt32Array) -> int:
	return _fill_candidate_slots(hostile_live, output)


func fill_player_candidate_handles_into(slots: PackedInt32Array, generations: PackedInt32Array) -> int:
	return _fill_candidate_handles(player_live, slots, generations)


func fill_hostile_candidate_handles_into(slots: PackedInt32Array, generations: PackedInt32Array) -> int:
	return _fill_candidate_handles(hostile_live, slots, generations)


## `receipt` is caller-owned and may be reset and reused for every contact.
func write_hit_receipt(
	receipt: Dictionary, hostile: bool, index: int, contact_t: float, target_slot: int = -1
) -> bool:
	var source: Array[ProjectileState] = hostile_live if hostile else player_live
	if index < 0 or index >= source.size():
		return false
	var state := source[index]
	receipt[&"projectile_slot"] = state.storage_slot
	receipt[&"projectile_generation"] = state.storage_generation
	receipt[&"hostile"] = hostile
	receipt[&"contact_t"] = contact_t
	receipt[&"target_slot"] = target_slot
	return true


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
		if projectile.team != &"player" or not resolves_player_handle(
			projectile.storage_slot, projectile.storage_generation
		):
			return false
	for projectile in hostile_live:
		if projectile.team != &"enemy" or not resolves_hostile_handle(
			projectile.storage_slot, projectile.storage_generation
		):
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


func _resize_columns() -> void:
	player_position.resize(PLAYER_CAPACITY)
	player_velocity.resize(PLAYER_CAPACITY)
	player_radius.resize(PLAYER_CAPACITY)
	player_damage.resize(PLAYER_CAPACITY)
	player_life.resize(PLAYER_CAPACITY)
	player_generation.resize(PLAYER_CAPACITY)
	player_live_flags.resize(PLAYER_CAPACITY)
	hostile_position.resize(HOSTILE_CAPACITY)
	hostile_velocity.resize(HOSTILE_CAPACITY)
	hostile_radius.resize(HOSTILE_CAPACITY)
	hostile_damage.resize(HOSTILE_CAPACITY)
	hostile_life.resize(HOSTILE_CAPACITY)
	hostile_generation.resize(HOSTILE_CAPACITY)
	hostile_live_flags.resize(HOSTILE_CAPACITY)


func _activate_player(state: ProjectileState) -> void:
	state.storage_generation = _next_generation(player_generation[state.storage_slot])
	player_generation[state.storage_slot] = state.storage_generation
	player_live_flags[state.storage_slot] = 1
	_sync_player(state)


func _activate_hostile(state: ProjectileState) -> void:
	state.storage_generation = _next_generation(hostile_generation[state.storage_slot])
	hostile_generation[state.storage_slot] = state.storage_generation
	hostile_live_flags[state.storage_slot] = 1
	_sync_hostile(state)


func _deactivate_player(state: ProjectileState) -> void:
	player_live_flags[state.storage_slot] = 0


func _deactivate_hostile(state: ProjectileState) -> void:
	hostile_live_flags[state.storage_slot] = 0


func _sync_player(state: ProjectileState) -> void:
	var slot := state.storage_slot
	player_position[slot] = state.pos
	player_velocity[slot] = state.velocity
	player_radius[slot] = state.radius
	player_damage[slot] = state.damage
	player_life[slot] = state.life


func _sync_hostile(state: ProjectileState) -> void:
	var slot := state.storage_slot
	hostile_position[slot] = state.pos
	hostile_velocity[slot] = state.velocity
	hostile_radius[slot] = state.radius
	hostile_damage[slot] = state.damage
	hostile_life[slot] = state.life


func _handle_at(source: Array[ProjectileState], index: int) -> Vector2i:
	if index < 0 or index >= source.size():
		return Vector2i(-1, 0)
	var state := source[index]
	return Vector2i(state.storage_slot, state.storage_generation)


func _resolves(flags: PackedByteArray, generations: PackedInt32Array, slot: int, generation: int) -> bool:
	return slot >= 0 and slot < flags.size() and flags[slot] != 0 and generations[slot] == generation


func _state_for_handle(
	source: Array[ProjectileState], slot: int, generation: int, player: bool
) -> ProjectileState:
	if not (resolves_player_handle(slot, generation) if player else resolves_hostile_handle(slot, generation)):
		return null
	for state in source:
		if state.storage_slot == slot:
			return state
	return null


func _fill_candidate_slots(source: Array[ProjectileState], output: PackedInt32Array) -> int:
	output.resize(source.size())
	for index in source.size():
		output[index] = source[index].storage_slot
	return source.size()


func _fill_candidate_handles(
	source: Array[ProjectileState], slots: PackedInt32Array, generations: PackedInt32Array
) -> int:
	slots.resize(source.size())
	generations.resize(source.size())
	for index in source.size():
		var state := source[index]
		slots[index] = state.storage_slot
		generations[index] = state.storage_generation
	return source.size()


func _next_generation(current: int) -> int:
	return 1 if current >= 0x7ffffffe else current + 1


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
