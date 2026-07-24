class_name VehicleGuidebookPreview
extends Control

## Displays the same retained combat meshes used by the world renderer.

const Visuals = preload("res://scripts/presentation/vehicle_combat_visual_library.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var _instances: Array[MeshInstance2D] = []


func _ready() -> void:
	custom_minimum_size = Vector2(220.0, 150.0)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	match kind:
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
	draw_rect(Rect2(Vector2(8.0, 8.0), size - Vector2(16.0, 16.0)), Art.CERAMIC_GREEN, false, 3.0)


func _add_terrain(terrain_id: StringName) -> void:
	match terrain_id:
		&"flow_channel":
			_add_instance(
				Visuals.polygon_mesh([{"points":PackedVector2Array([
					Vector2(-1.0, -0.40), Vector2(1.0, -0.40),
					Vector2(1.0, 0.40), Vector2(-1.0, 0.40),
				]), "color":Color.WHITE}]),
				Art.COBALT_WATER,
				Vector2(72.0, 44.0)
			)
		&"arc_surge":
			_add_instance(Visuals.effect_mesh(&"beam"), Art.BOSS_MAGENTA, Vector2(78.0, 42.0))
		&"breakable_bulkhead":
			_add_instance(Visuals.health_bar_mesh(), Art.CERAMIC_GREEN, Vector2(74.0, 34.0))
		_:
			_add_instance(Visuals.effect_mesh(&"diamond"), Art.INK_MUTED, Vector2(42.0, 42.0))


func _add_facility(facility_id: StringName) -> void:
	var color := Art.MINT if facility_id != &"overdrive_field" else Art.MUSTARD
	_add_instance(Visuals.effect_mesh(&"ring"), color, Vector2(54.0, 54.0))
	if facility_id == &"transit_gate":
		_add_instance(Visuals.effect_mesh(&"diamond"), Art.IVORY_BRIGHT, Vector2(28.0, 28.0))
	elif facility_id == &"repair_basin":
		_add_instance(Visuals.health_bar_mesh(), Art.IVORY_BRIGHT, Vector2(10.0, 34.0))
		_add_instance(Visuals.health_bar_mesh(), Art.IVORY_BRIGHT, Vector2(34.0, 10.0))


func _add_instance(mesh: Mesh, color: Color, scale_value: Vector2) -> MeshInstance2D:
	var instance := MeshInstance2D.new()
	instance.mesh = mesh
	instance.modulate = color
	instance.scale = scale_value
	add_child(instance)
	_instances.append(instance)
	return instance


func _layout_instances() -> void:
	for instance in _instances:
		instance.position = size * 0.5


func _clear_instances() -> void:
	for instance in _instances:
		instance.queue_free()
	_instances.clear()
