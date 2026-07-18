class_name PumpStation3D
extends Area3D

signal activated(pump: PumpStation3D)

const ACTIVATION_SECONDS := 1.0

var is_active := false
var progress := 0.0
var traveler_inside: Traveler3D
var previous_health := 0

@onready var visual: MeshInstance3D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if is_active or traveler_inside == null:
		return
	if Input.is_action_pressed("interact"):
		progress += delta
		traveler_inside.action_traced.emit("Pump · %d%%" % mini(100, int(progress * 100.0)))
		if progress >= ACTIVATION_SECONDS:
			_complete_activation()
	else:
		progress = 0.0


func restore_active(value: bool) -> void:
	is_active = value
	progress = ACTIVATION_SECONDS if value else 0.0
	_update_visual()


func _on_body_entered(body: Node3D) -> void:
	if body is Traveler3D:
		traveler_inside = body as Traveler3D
		previous_health = traveler_inside.health
		traveler_inside.health_changed.connect(_on_health_changed)
		traveler_inside.action_traced.emit("Hold V · restore pump")


func _on_body_exited(body: Node3D) -> void:
	if body == traveler_inside:
		if traveler_inside.health_changed.is_connected(_on_health_changed):
			traveler_inside.health_changed.disconnect(_on_health_changed)
		traveler_inside = null
		progress = 0.0


func _on_health_changed(current: int, _maximum: int) -> void:
	if current < previous_health:
		progress = 0.0
		traveler_inside.action_traced.emit("Pump interrupted")
	previous_health = current


func _complete_activation() -> void:
	is_active = true
	progress = ACTIVATION_SECONDS
	_update_visual()
	traveler_inside.action_traced.emit("Pump restored")
	activated.emit(self)


func _update_visual() -> void:
	var material := visual.material_override as StandardMaterial3D
	if material == null:
		material = StandardMaterial3D.new()
		visual.material_override = material
	material.albedo_color = Color("6ba5a1") if is_active else Color("29484a")
	material.emission_enabled = is_active
	material.emission = Color("8bc9bd")
	material.emission_energy_multiplier = 0.4
