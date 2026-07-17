class_name CombatSandbox
extends Node2D

@onready var traveler: Traveler = $Traveler
@onready var dummy: DamageableDummy = $DamageableDummy
@onready var training_pulse: TrainingPulse = $TrainingPulse


func _ready() -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("reset_training"):
		reset_fixture()


func reset_fixture() -> void:
	traveler.reset_training()
	dummy.reset_dummy()
	training_pulse.reset_pulse()


func _draw() -> void:
	# Large authored color masses preserve the chunk-based map direction while collision stays top-down.
	var room := PackedVector2Array([
		Vector2(160, 160), Vector2(1280, 160), Vector2(1440, 300),
		Vector2(1440, 740), Vector2(320, 740), Vector2(160, 600),
	])
	draw_polygon(room, PackedColorArray([Color("1c292d")]))

	var upper_slab := PackedVector2Array([
		Vector2(200, 190), Vector2(760, 190), Vector2(880, 300),
		Vector2(320, 300),
	])
	draw_polygon(upper_slab, PackedColorArray([Color("26383b")]))
	var center_slab := PackedVector2Array([
		Vector2(340, 330), Vector2(1180, 330), Vector2(1320, 460),
		Vector2(480, 460),
	])
	draw_polygon(center_slab, PackedColorArray([Color("304348")]))
	var lower_slab := PackedVector2Array([
		Vector2(260, 500), Vector2(1040, 500), Vector2(1220, 670),
		Vector2(440, 670),
	])
	draw_polygon(lower_slab, PackedColorArray([Color("25373a")]))

	var water_channel := PackedVector2Array([
		Vector2(170, 617), Vector2(300, 732), Vector2(438, 732), Vector2(290, 604),
	])
	draw_polygon(water_channel, PackedColorArray([Color("244e55")]))
	draw_polyline(PackedVector2Array([Vector2(170, 600), Vector2(320, 740), Vector2(1440, 740)]), Color("62a9b5"), 4.0)

	# Sparse machinery accents identify the drowned foundry without becoming gameplay noise.
	for anchor in [Vector2(260, 230), Vector2(1290, 260), Vector2(1330, 650)]:
		draw_set_transform(anchor, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 28.0, Color("12171a"))
		draw_circle(Vector2.ZERO, 16.0, Color("d4a33f"))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	draw_polyline(PackedVector2Array([Vector2(160, 600), Vector2(160, 160), Vector2(1280, 160), Vector2(1440, 300)]), Color("0b1114"), 34.0)
	draw_polyline(PackedVector2Array([Vector2(1440, 300), Vector2(1440, 740), Vector2(320, 740)]), Color("10181b"), 34.0)
