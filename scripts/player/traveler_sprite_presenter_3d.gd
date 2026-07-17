class_name TravelerSpritePresenter3D
extends Sprite3D

## Selects raster poses from authoritative movement and action state only.

enum SpriteState {
	LOCOMOTION,
	MELEE,
	RANGED,
	GUARD,
}

const FRAME_COLUMNS := 4
const DIRECTION_ROWS := 2
const LOCOMOTION_FRAMES_PER_METER := 2.0
const MELEE_CONTACT_PROGRESS := 0.10 / 0.38
const RANGED_RELEASE_PROGRESS := 0.10 / 0.32

@export var locomotion_texture: Texture2D
@export var melee_texture: Texture2D
@export var ranged_texture: Texture2D
@export var guard_texture: Texture2D

var current_state := SpriteState.LOCOMOTION
var current_row := 0
var current_column := 0
var locomotion_distance := 0.0
var guard_elapsed := 0.0


func _ready() -> void:
	hframes = FRAME_COLUMNS
	vframes = DIRECTION_ROWS
	reset_presentation()


func present_state(
	facing: Vector3,
	camera: Camera3D,
	traveled_distance: float,
	melee_progress: float,
	ranged_progress: float,
	guarding: bool,
	delta: float,
) -> void:
	_update_direction(facing, camera)
	if melee_progress >= 0.0:
		guard_elapsed = 0.0
		_set_melee_frame(melee_progress)
	elif guarding:
		guard_elapsed += delta
		_set_guard_frame()
	elif ranged_progress >= 0.0:
		guard_elapsed = 0.0
		_set_ranged_frame(ranged_progress)
	else:
		guard_elapsed = 0.0
		_set_locomotion_frame(traveled_distance)
	frame = current_row * FRAME_COLUMNS + current_column


func reset_presentation() -> void:
	current_state = SpriteState.LOCOMOTION
	current_row = 0
	current_column = 0
	locomotion_distance = 0.0
	guard_elapsed = 0.0
	flip_h = false
	texture = locomotion_texture
	frame = 0


func _update_direction(direction: Vector3, camera: Camera3D) -> void:
	var normalized_direction := direction
	normalized_direction.y = 0.0
	if normalized_direction.length_squared() <= 0.0001:
		normalized_direction = Vector3.FORWARD
	normalized_direction = normalized_direction.normalized()

	var camera_right := camera.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var camera_away := -camera.global_basis.z
	camera_away.y = 0.0
	camera_away = camera_away.normalized()
	current_row = 0 if normalized_direction.dot(camera_away) >= 0.0 else 1
	flip_h = normalized_direction.dot(camera_right) < 0.0


func _set_locomotion_frame(traveled_distance: float) -> void:
	current_state = SpriteState.LOCOMOTION
	texture = locomotion_texture
	if traveled_distance > 0.0005:
		locomotion_distance += traveled_distance
		current_column = (
			int(floor(locomotion_distance * LOCOMOTION_FRAMES_PER_METER))
			% FRAME_COLUMNS
		)
	else:
		locomotion_distance = 0.0
		current_column = 0


func _set_melee_frame(progress: float) -> void:
	current_state = SpriteState.MELEE
	texture = melee_texture
	if progress < 0.18:
		current_column = 0
	elif progress < MELEE_CONTACT_PROGRESS:
		current_column = 1
	elif progress < 0.62:
		current_column = 2
	else:
		current_column = 3


func _set_ranged_frame(progress: float) -> void:
	current_state = SpriteState.RANGED
	texture = ranged_texture
	if progress < 0.15:
		current_column = 0
	elif progress < RANGED_RELEASE_PROGRESS:
		current_column = 1
	elif progress < 0.68:
		current_column = 2
	else:
		current_column = 3


func _set_guard_frame() -> void:
	current_state = SpriteState.GUARD
	texture = guard_texture
	if guard_elapsed < 0.08:
		current_column = 0
	elif guard_elapsed < 0.16:
		current_column = 1
	else:
		current_column = 2 + int(floor((guard_elapsed - 0.16) * 2.0)) % 2
