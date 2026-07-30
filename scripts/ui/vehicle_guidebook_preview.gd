class_name VehicleGuidebookPreview
extends Control

## Displays runtime component previews while guidebook text and locked-state
## ownership remain live UI. Unmigrated enemy/boss families may still use the
## atlas until their publication phases.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const PixelCatalog = preload("res://scripts/presentation/vehicle_pixel_asset_catalog.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var _instances: Array[MeshInstance2D] = []
var _pixel_catalog: VehiclePixelAssetCatalog
var _pixel_frame: Dictionary = {}
var _pixel_texture: Texture2D
var _pixel_size := Vector2(92.0, 92.0)


func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 150.0)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pixel_catalog = PixelCatalog.new()
	resized.connect(_layout_instances)
	queue_redraw()


func show_preview(preview: Dictionary) -> void:
	_clear_instances()
	if preview.is_empty():
		visible = false
		return
	visible = true
	var kind := StringName(preview.get("kind", &"enemy"))
	var preview_id := StringName(preview.get("id", &"chaser"))
	if _show_pixel_preview(kind, preview_id):
		queue_redraw()
		return
	match kind:
		&"locked":
			_add_instance(
				Visuals.enemy_mesh(&"chaser"),
				Art.INK_MUTED,
				Vector2(44.0, 44.0)
			)
		&"boss":
			_add_instance(
				Visuals.boss_mesh(preview_id),
				Art.BOSS_MAGENTA,
				Vector2(52.0, 52.0)
			)
		&"terrain":
			_add_terrain(preview_id)
		&"facility":
			_add_facility(preview_id)
		&"elite":
			_add_instance(Visuals.enemy_mesh(&"chaser"), Art.CORAL, Vector2(42.0, 42.0))
			var marker := _add_instance(Visuals.effect_mesh(&"diamond"), Art.IVORY_BRIGHT, Vector2(58.0, 58.0))
			marker.modulate.a = 0.85
		&"pickup":
			_add_instance(
				Visuals.experience_mesh(&"large") if preview_id == &"experience" else Visuals.effect_mesh(&"diamond"),
				Art.MINT if preview_id != &"repair" else Art.MUSTARD,
				Vector2(32.0, 32.0)
			)
		_:
			_add_instance(
				Visuals.enemy_mesh(preview_id),
				Visuals.enemy_color(preview_id),
				Vector2(44.0, 44.0)
			)
	_layout_instances()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Art.COBALT_VOID.lightened(0.04))
	draw_rect(Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0)), Art.STRUCTURE_BASE, false, 3.0)
	if _pixel_texture != null and not _pixel_frame.is_empty():
		var region := Array(_pixel_frame["region"])
		draw_texture_rect_region(
			_pixel_texture,
			Rect2(size * 0.5 - _pixel_size * 0.5, _pixel_size),
			Rect2(
				float(region[0]),
				float(region[1]),
				float(region[2]),
				float(region[3])
			)
		)


func _show_pixel_preview(kind: StringName, preview_id: StringName) -> bool:
	if _pixel_catalog == null or not _pixel_catalog.is_ready():
		return false
	if kind in [&"terrain", &"facility", &"pickup"]:
		return false
	var family := &""
	var variant := preview_id
	var preferred_state := &""
	var size_value := Vector2(92.0, 92.0)
	match kind:
		&"locked":
			family = &"guidebook_previews"
			variant = &"locked_silhouette"
			size_value = Vector2(84.0, 84.0)
		&"boss":
			family = &"boss_set"
			preferred_state = &"idle"
			size_value = Vector2(118.0, 118.0)
		&"enemy", &"elite":
			family = (
				&"stationary_enemy_set"
				if preview_id in [
					&"turret", &"mine", &"interceptor_tower",
					&"beam_sentinel", &"controller", &"artillery"
				]
				else &"mobile_enemy_set"
			)
			preferred_state = &"move"
			if kind == &"elite":
				variant = &"chaser"
		&"terrain":
			family = (
				&"arc_surge_strip"
				if preview_id == &"arc_surge"
				else &"breakable_bulkhead"
			)
			variant = (
				&"horizontal_segment"
				if preview_id == &"arc_surge"
				else &"horizontal"
			)
			preferred_state = &"active" if preview_id == &"arc_surge" else &"intact"
			size_value = Vector2(132.0, 82.0)
		&"facility":
			match preview_id:
				&"transit_gate":
					family = &"transit_gate"
					variant = &"pair_a"
					preferred_state = &"ready"
				&"repair_basin":
					family = &"repair_field"
					variant = &"center_fixture"
					preferred_state = &"active"
				&"overdrive_field":
					family = &"overdrive_field"
					variant = &"center_fixture"
					preferred_state = &"active"
		&"pickup":
			if preview_id == &"experience":
				family = &"experience_shards"
				variant = &"large"
			else:
				family = &"repair_pickup"
				variant = &"repair"
			preferred_state = &"idle"
	if family == &"" or not _pixel_catalog.has_family(family):
		return false
	var frame := _pixel_catalog.first_frame(family, variant, preferred_state)
	if frame.is_empty():
		return false
	var texture := _pixel_catalog.texture(family)
	if texture == null:
		return false
	_pixel_frame = frame
	_pixel_texture = texture
	_pixel_size = size_value
	return true


func _add_terrain(terrain_id: StringName) -> void:
	match terrain_id:
		&"arc_surge":
			_add_instance(Visuals.effect_mesh(&"beam"), Art.ARC, Vector2(78.0, 42.0))
		&"breakable_bulkhead":
			_add_instance(Visuals.health_bar_mesh(), Art.STRUCTURE_BASE, Vector2(74.0, 34.0))
		_:
			_add_instance(Visuals.effect_mesh(&"diamond"), Art.INK_MUTED, Vector2(42.0, 42.0))


func _add_facility(facility_id: StringName) -> void:
	var color := (
		Art.PLAYER_REWARD
		if facility_id == &"overdrive_field"
		else (Art.SYSTEM if facility_id == &"transit_gate" else Art.SUPPORT)
	)
	_add_instance(Visuals.effect_mesh(&"ring"), color, Vector2(54.0, 54.0))
	if facility_id == &"transit_gate":
		var left := _add_instance(Visuals.effect_mesh(&"diamond"), Art.IVORY_BRIGHT, Vector2(20.0, 20.0))
		left.set_meta("preview_offset", Vector2(-22.0, 0.0))
		var right := _add_instance(Visuals.effect_mesh(&"diamond"), Art.IVORY_BRIGHT, Vector2(20.0, 20.0))
		right.set_meta("preview_offset", Vector2(22.0, 0.0))
	elif facility_id == &"repair_basin":
		_add_instance(Visuals.health_bar_mesh(), Art.IVORY_BRIGHT, Vector2(10.0, 34.0))
		_add_instance(Visuals.health_bar_mesh(), Art.IVORY_BRIGHT, Vector2(34.0, 10.0))
	elif facility_id == &"overdrive_field":
		for index in 3:
			var arrow := _add_instance(
				Visuals.effect_mesh(&"diamond"),
				Art.IVORY_BRIGHT,
				Vector2(18.0, 12.0)
			)
			arrow.set_meta(
				"preview_offset",
				Vector2(0.0, 24.0 - float(index) * 24.0)
			)


func _add_instance(mesh: Mesh, color: Color, scale_value: Vector2) -> MeshInstance2D:
	var instance := MeshInstance2D.new()
	instance.mesh = mesh
	instance.modulate = color
	instance.scale = scale_value
	instance.set_meta("preview_offset", Vector2.ZERO)
	add_child(instance)
	_instances.append(instance)
	return instance


func _layout_instances() -> void:
	for instance in _instances:
		instance.position = size * 0.5 + Vector2(
			instance.get_meta("preview_offset", Vector2.ZERO)
		)


func _clear_instances() -> void:
	_pixel_frame.clear()
	_pixel_texture = null
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
