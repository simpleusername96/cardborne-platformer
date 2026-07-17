class_name TravelerSpritePresenter3D
extends Sprite3D

## Selects raster poses from authoritative movement and action state only.

enum SpriteState {
	LOCOMOTION,
	MELEE,
	RANGED,
	GUARD,
	DASH,
}

const FRAME_COLUMNS := 4
const DIRECTION_ROWS := 2
const LOCOMOTION_FRAMES_PER_METER := 2.0
const LATERAL_DOMINANCE_RATIO := 1.5
const DASH_AFTERIMAGE_SPACING := 0.65
const DASH_AFTERIMAGE_LIFETIME := 0.16
const DASH_AFTERIMAGE_COLOR := Color(0.42, 0.84, 0.82, 0.46)
const MELEE_CONTACT_PROGRESS := 0.10 / 0.38
const RANGED_RELEASE_PROGRESS := 0.10 / 0.32

@export var locomotion_texture: Texture2D
@export var lateral_locomotion_texture: Texture2D
@export var dash_texture: Texture2D
@export var melee_texture: Texture2D
@export var ranged_texture: Texture2D
@export var guard_texture: Texture2D

var current_state := SpriteState.LOCOMOTION
var current_row := 0
var current_column := 0
var current_lateral := false
var locomotion_distance := 0.0
var guard_elapsed := 0.0
var dash_afterimage_distance := 0.0
var dash_was_active := false
var active_dash_afterimages: Array[Sprite3D] = []


func _ready() -> void:
	hframes = FRAME_COLUMNS
	vframes = DIRECTION_ROWS
	reset_presentation()


func present_state(
	facing: Vector3,
	camera: Camera3D,
	traveled_distance: float,
	dash_progress: float,
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
	elif dash_progress >= 0.0:
		guard_elapsed = 0.0
		_set_dash_frame(dash_progress, traveled_distance)
	else:
		guard_elapsed = 0.0
		dash_was_active = false
		dash_afterimage_distance = 0.0
		_set_locomotion_frame(traveled_distance)
	frame = current_row * FRAME_COLUMNS + current_column


func reset_presentation() -> void:
	current_state = SpriteState.LOCOMOTION
	current_row = 0
	current_column = 0
	current_lateral = false
	locomotion_distance = 0.0
	guard_elapsed = 0.0
	dash_afterimage_distance = 0.0
	dash_was_active = false
	_clear_dash_afterimages()
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
	var side_component := normalized_direction.dot(camera_right)
	var depth_component := normalized_direction.dot(camera_away)
	current_lateral = absf(side_component) >= absf(depth_component) * LATERAL_DOMINANCE_RATIO
	current_row = 0 if depth_component >= 0.0 else 1
	flip_h = side_component < 0.0


func _set_locomotion_frame(traveled_distance: float) -> void:
	current_state = SpriteState.LOCOMOTION
	if current_lateral:
		texture = lateral_locomotion_texture
		current_row = 0
	else:
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


func _set_dash_frame(progress: float, traveled_distance: float) -> void:
	current_state = SpriteState.DASH
	texture = dash_texture
	if progress < 0.18:
		current_column = 0
	elif progress < 0.42:
		current_column = 1
	elif progress < 0.78:
		current_column = 2
	else:
		current_column = 3

	if not dash_was_active:
		dash_was_active = true
		dash_afterimage_distance = 0.0
		_spawn_dash_afterimage()
	dash_afterimage_distance += traveled_distance
	while dash_afterimage_distance >= DASH_AFTERIMAGE_SPACING:
		dash_afterimage_distance -= DASH_AFTERIMAGE_SPACING
		_spawn_dash_afterimage()


func _spawn_dash_afterimage() -> void:
	var afterimage := Sprite3D.new()
	afterimage.name = "DashAfterimage"
	afterimage.texture = texture
	afterimage.hframes = hframes
	afterimage.vframes = vframes
	afterimage.frame = current_row * FRAME_COLUMNS + current_column
	afterimage.flip_h = flip_h
	afterimage.pixel_size = pixel_size
	afterimage.billboard = billboard
	afterimage.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	afterimage.no_depth_test = no_depth_test
	afterimage.render_priority = render_priority - 1
	afterimage.modulate = DASH_AFTERIMAGE_COLOR
	afterimage.add_to_group(&"traveler_dash_afterimages")
	get_parent().add_child(afterimage)
	afterimage.top_level = true
	afterimage.global_transform = global_transform
	active_dash_afterimages.append(afterimage)

	var tween := afterimage.create_tween()
	tween.tween_property(afterimage, "modulate:a", 0.0, DASH_AFTERIMAGE_LIFETIME).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_IN)
	tween.finished.connect(_retire_dash_afterimage.bind(afterimage))


func _retire_dash_afterimage(afterimage: Sprite3D) -> void:
	active_dash_afterimages.erase(afterimage)
	if is_instance_valid(afterimage):
		afterimage.queue_free()


func _clear_dash_afterimages() -> void:
	for afterimage in active_dash_afterimages:
		if is_instance_valid(afterimage):
			afterimage.queue_free()
	active_dash_afterimages.clear()
