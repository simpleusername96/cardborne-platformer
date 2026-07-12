extends StageBase

const WORLD_WIDTH := 2400.0
const WORLD_BOTTOM := 900.0
# Required-route masses share exact x boundaries; optional ledges never carry progression.
const CRITICAL_SURFACES: Array[Dictionary] = [
	{"id": "entry", "x": 0.0, "width": 480.0, "top": 620.0},
	{"id": "first_rise", "x": 480.0, "width": 360.0, "top": 560.0},
	{"id": "upper_walk", "x": 840.0, "width": 420.0, "top": 500.0},
	{"id": "middle_drop", "x": 1260.0, "width": 360.0, "top": 550.0},
	{"id": "gate_rise", "x": 1620.0, "width": 420.0, "top": 480.0},
	{"id": "exit_walk", "x": 2040.0, "width": 360.0, "top": 540.0},
]

@onready var terrain_root: Node2D = $Terrain


func _ready() -> void:
	_build_critical_terrain()
	_build_optional_platforms()
	_build_exit_gate()
	super._ready()


func get_critical_surface_contract() -> Array[Dictionary]:
	return CRITICAL_SURFACES.duplicate(true)


func get_exit_surface_id() -> String:
	return "exit_walk"


func _build_critical_terrain() -> void:
	for surface_index in CRITICAL_SURFACES.size():
		_create_rock_mass(surface_index, CRITICAL_SURFACES[surface_index])


func _create_rock_mass(surface_index: int, surface: Dictionary) -> void:
	var width := float(surface["width"])
	var top := float(surface["top"])
	var height := WORLD_BOTTOM - top
	var body := StaticBody2D.new()
	body.name = "CriticalSurface_%02d_%s" % [surface_index, surface["id"]]
	body.position = Vector2(float(surface["x"]) + width * 0.5, top)
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("surface_id", surface["id"])
	body.set_meta("critical", true)
	body.set_meta("support_top", top)
	body.set_meta("support_width", width)
	terrain_root.add_child(body)

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, height)
	collision.position = Vector2(0.0, height * 0.5)
	collision.shape = rectangle
	body.add_child(collision)

	var visual := Polygon2D.new()
	visual.name = "RockVisual"
	visual.color = Color("344147")
	visual.polygon = PackedVector2Array([
		Vector2(-width * 0.5, 0.0),
		Vector2(width * 0.5, 0.0),
		Vector2(width * 0.5, height),
		Vector2(-width * 0.5, height),
	])
	body.add_child(visual)

	var cap := Polygon2D.new()
	cap.name = "SupportCap"
	cap.color = Color("718963") if surface_index % 2 == 0 else Color("57909a")
	cap.polygon = PackedVector2Array([
		Vector2(-width * 0.5, 0.0),
		Vector2(width * 0.5, 0.0),
		Vector2(width * 0.5, 8.0),
		Vector2(-width * 0.5, 8.0),
	])
	cap.z_index = 1
	body.add_child(cap)

	for groove_index in 3:
		var groove := Line2D.new()
		groove.width = 4.0
		groove.default_color = Color("283438")
		var inset := 42.0 + groove_index * 22.0
		groove.points = PackedVector2Array([
			Vector2(-width * 0.5 + inset, 52.0 + groove_index * 46.0),
			Vector2(width * 0.5 - inset, 52.0 + groove_index * 46.0),
		])
		body.add_child(groove)


func _build_optional_platforms() -> void:
	_create_one_way_platform("OptionalLedgeA", Vector2(1060.0, 390.0), 220.0)
	_create_one_way_platform("OptionalLedgeB", Vector2(1810.0, 340.0), 240.0)


func _create_one_way_platform(platform_name: String, position: Vector2, width: float) -> void:
	var body := StaticBody2D.new()
	body.name = platform_name
	body.position = position
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("critical", false)
	terrain_root.add_child(body)

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 12.0)
	collision.shape = rectangle
	collision.one_way_collision = true
	body.add_child(collision)

	var visual := Polygon2D.new()
	visual.color = Color("57909a")
	visual.polygon = PackedVector2Array([
		Vector2(-width * 0.5, -6.0),
		Vector2(width * 0.5, -6.0),
		Vector2(width * 0.5, 6.0),
		Vector2(-width * 0.5, 6.0),
	])
	body.add_child(visual)


func _build_exit_gate() -> void:
	var exit := Area2D.new()
	exit.name = "ExitGate"
	exit.position = Vector2(2250.0, 540.0)
	exit.collision_layer = 0
	exit.collision_mask = 4
	exit.set_meta("critical_exit", true)
	exit.set_script(preload("res://scripts/stages/ExitPortal.gd"))
	exit.set("prompt_text", "Enter gate")
	add_child(exit)

	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(92.0, 116.0)
	collision.position = Vector2(0.0, -58.0)
	collision.shape = rectangle
	exit.add_child(collision)

	var frame := Polygon2D.new()
	frame.color = Color("d4a33f")
	frame.polygon = PackedVector2Array([
		Vector2(-50.0, 0.0),
		Vector2(-50.0, -124.0),
		Vector2(-34.0, -146.0),
		Vector2(34.0, -146.0),
		Vector2(50.0, -124.0),
		Vector2(50.0, 0.0),
		Vector2(30.0, 0.0),
		Vector2(30.0, -112.0),
		Vector2(-30.0, -112.0),
		Vector2(-30.0, 0.0),
	])
	exit.add_child(frame)

	var interior := Polygon2D.new()
	interior.color = Color("172225")
	interior.polygon = PackedVector2Array([
		Vector2(-28.0, 0.0),
		Vector2(-28.0, -108.0),
		Vector2(28.0, -108.0),
		Vector2(28.0, 0.0),
	])
	interior.z_index = 1
	exit.add_child(interior)


func _after_player_respawned() -> void:
	if player == null or player.camera == null:
		return
	player.camera.limit_left = 0
	player.camera.limit_right = int(WORLD_WIDTH)
	player.camera.limit_top = 0
	player.camera.limit_bottom = 720
	player.camera.make_current()
	player.camera.reset_smoothing()
