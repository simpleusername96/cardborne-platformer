class_name CombatSandbox3D
extends Node3D

@onready var traveler: Traveler3D = $Traveler
@onready var dummy: DamageableDummy3D = $DamageableDummy
@onready var training_pulse: TrainingPulse3D = $TrainingPulse


func _ready() -> void:
	_apply_architecture_palette($Architecture)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_training"):
		traveler.reset_training()
		dummy.reset_dummy()
		training_pulse.reset_pulse()


func _apply_architecture_palette(root_node: Node) -> void:
	var architecture_material := StandardMaterial3D.new()
	architecture_material.albedo_color = Color("26383b")
	architecture_material.roughness = 0.92
	architecture_material.metallic = 0.08
	for child in root_node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		mesh_instance.material_override = architecture_material
