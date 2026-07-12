class_name SlimeCourt
extends StageBase

signal intro_completed

const ARENA_BOUNDS := Rect2(0.0, 0.0, 1280.0, 720.0)
const GROUND_SURFACE := Rect2(100.0, 612.0, 1080.0, 28.0)
const PLATFORM_SURFACES: Array[Rect2] = [
	Rect2(200.0, 500.0, 260.0, 14.0),
	Rect2(830.0, 410.0, 240.0, 14.0),
]
const INTRO_DURATION := 0.90
const ENTRANCE_SAFE_X := 142.0

@onready var boss: SlimeKingActor = $Actors/SlimeKing
@onready var boss_spawn: Marker2D = $BossSpawn
@onready var ground: StaticBody2D = $Terrain/Ground
@onready var entrance_lock: StaticBody2D = $Terrain/EntranceLock
@onready var entrance_lock_shape: CollisionShape2D = $Terrain/EntranceLock/CollisionShape2D
@onready var entrance_lock_visual: Polygon2D = $Terrain/EntranceLock/Visual
@onready var low_platform: StaticBody2D = $OneWay/LowPlatform
@onready var high_platform: StaticBody2D = $OneWay/HighPlatform

var _setup_succeeded: bool = false
var _intro_time_remaining: float = INTRO_DURATION
var _intro_complete: bool = false
var _entrance_locked: bool = false
var _manual_simulation: bool = false


func _ready() -> void:
	stage_id = "slime_court"
	stage_display_name = "Slime Court"
	if not _validate_authored_scene():
		_abort_setup()
		return
	boss.set_external_clock(true)
	super._ready()
	if player == null:
		_abort_setup()
		return
	boss.set_target_actor(player)
	_configure_arena_camera()
	if not get_viewport().size_changed.is_connected(_configure_arena_camera):
		get_viewport().size_changed.connect(_configure_arena_camera)
	_set_entrance_locked(false)
	_setup_succeeded = true


func _exit_tree() -> void:
	if get_viewport() != null and get_viewport().size_changed.is_connected(_configure_arena_camera):
		get_viewport().size_changed.disconnect(_configure_arena_camera)
	if boss != null:
		boss.cancel_encounter(&"scene_exit")


func _physics_process(delta: float) -> void:
	if not _manual_simulation:
		_advance_runtime_internal(delta)


func advance_runtime(delta: float) -> void:
	if _manual_simulation:
		_advance_runtime_internal(delta)


func set_manual_simulation(enabled: bool) -> void:
	_manual_simulation = enabled
	set_physics_process(not enabled)
	boss.set_external_clock(true)


func is_setup_complete() -> bool:
	return _setup_succeeded


func is_intro_complete() -> bool:
	return _intro_complete


func is_entrance_locked() -> bool:
	return _entrance_locked


func get_world_bounds() -> Rect2:
	return ARENA_BOUNDS


func get_boss() -> SlimeKingActor:
	return boss


func get_arena_snapshot() -> Dictionary:
	return {
		"bounds": ARENA_BOUNDS,
		"ground_surface": GROUND_SURFACE,
		"usable_ground_width": GROUND_SURFACE.size.x,
		"platform_surfaces": PLATFORM_SURFACES.duplicate(),
		"player_spawn": player_spawn.global_position if player_spawn != null else Vector2.ZERO,
		"boss_spawn": boss_spawn.global_position if boss_spawn != null else Vector2.ZERO,
		"intro_duration": INTRO_DURATION,
		"intro_time_remaining": _intro_time_remaining,
		"intro_complete": _intro_complete,
		"entrance_locked": _entrance_locked,
		"camera_limits": Rect2(
			float(player.camera.limit_left),
			float(player.camera.limit_top),
			float(player.camera.limit_right - player.camera.limit_left),
			float(player.camera.limit_bottom - player.camera.limit_top)
		) if player != null and player.camera != null else Rect2(),
		"camera_center": player.camera.global_position if player != null and player.camera != null else Vector2.ZERO,
		"camera_zoom": player.camera.zoom if player != null and player.camera != null else Vector2.ZERO,
		"viewport_size": Vector2(get_viewport_rect().size),
		"camera_visible_world_size": (
			Vector2(get_viewport_rect().size) / player.camera.zoom
			if player != null and player.camera != null
			else Vector2.ZERO
		),
	}


func _after_player_respawned() -> void:
	_configure_arena_camera()


func _configure_arena_camera() -> void:
	if player == null or player.camera == null:
		return
	var viewport_size := Vector2(get_viewport_rect().size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale := minf(
		viewport_size.x / ARENA_BOUNDS.size.x,
		viewport_size.y / ARENA_BOUNDS.size.y
	)
	player.set_camera_limits(ARENA_BOUNDS)
	player.camera.top_level = true
	player.camera.global_position = ARENA_BOUNDS.get_center()
	player.camera.zoom = Vector2.ONE * maxf(fit_scale, 0.001)
	player.camera.position_smoothing_enabled = false
	player.camera.limit_smoothed = false
	player.camera.drag_horizontal_enabled = false
	player.camera.drag_vertical_enabled = false
	player.camera.reset_smoothing()
	player.camera.make_current()


func _advance_runtime_internal(delta: float) -> void:
	if not _setup_succeeded or not is_finite(delta) or delta <= 0.0:
		return
	var remaining := delta
	if not _intro_complete:
		var intro_step := minf(remaining, _intro_time_remaining)
		_intro_time_remaining = maxf(_intro_time_remaining - intro_step, 0.0)
		remaining -= intro_step
		if is_zero_approx(_intro_time_remaining):
			_complete_intro()
	if _intro_complete and remaining > 0.0:
		boss.advance_runtime(remaining)


func _complete_intro() -> void:
	if _intro_complete:
		return
	_intro_complete = true
	if player != null and player.global_position.x < ENTRANCE_SAFE_X:
		player.global_position.x = ENTRANCE_SAFE_X
		player.velocity.x = 0.0
	_set_entrance_locked(true)
	var run_state := get_node_or_null("/root/RunState")
	var seed := int(run_state.get("run_seed")) if run_state != null else SlimeKingActor.DEFAULT_SCHEDULER_SEED
	if not boss.activate_encounter(seed):
		_setup_succeeded = false
		return
	intro_completed.emit()


func _set_entrance_locked(locked: bool) -> void:
	_entrance_locked = locked
	entrance_lock.collision_layer = 1 if locked else 0
	entrance_lock_shape.set_deferred("disabled", not locked)
	entrance_lock_visual.color = (
		Color(0.82, 0.36, 0.22, 0.94)
		if locked
		else Color(0.32, 0.54, 0.58, 0.26)
	)


func _validate_authored_scene() -> bool:
	if boss == null or not boss.is_runtime_ready():
		return false
	if ground == null or entrance_lock == null or low_platform == null or high_platform == null:
		return false
	if player_spawn == null or boss_spawn == null or actors_container == null:
		return false
	var ground_shape := ground.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var low_shape := low_platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var high_shape := high_platform.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return (
		ground_shape != null
		and ground_shape.shape is RectangleShape2D
		and is_equal_approx((ground_shape.shape as RectangleShape2D).size.x, 1080.0)
		and low_shape != null
		and low_shape.one_way_collision
		and high_shape != null
		and high_shape.one_way_collision
		and not is_equal_approx(low_platform.global_position.y, high_platform.global_position.y)
		and boss.arena_ground_rect == GROUND_SURFACE
		and boss.arena_platform_rects == PLATFORM_SURFACES
	)


func _abort_setup() -> void:
	_setup_succeeded = false
	remove_from_group("active_stage")
	if boss != null:
		boss.cancel_encounter(&"setup_failed")
