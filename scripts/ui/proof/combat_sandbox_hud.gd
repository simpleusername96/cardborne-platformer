class_name CombatSandboxHud
extends CanvasLayer

const HEALTH_WIDTH := 240.0

var _trace_remaining := 0.0

@onready var traveler: Traveler = get_node("../Traveler")
@onready var health_fill: ColorRect = $Root/Status/HealthTrack/HealthFill
@onready var health_value: Label = $Root/Status/HealthValue
@onready var potion_pips: Array[ColorRect] = [
	$Root/Status/Potions/Potion1,
	$Root/Status/Potions/Potion2,
	$Root/Status/Potions/Potion3,
]
@onready var trace_label: Label = $Root/ActionTrace


func _ready() -> void:
	traveler.health_changed.connect(_on_health_changed)
	traveler.potion_changed.connect(_on_potion_changed)
	traveler.action_traced.connect(_on_action_traced)
	_on_health_changed(traveler.health, traveler.max_health)
	_on_potion_changed(traveler.actions.potion_charges)


func _process(delta: float) -> void:
	_trace_remaining = maxf(0.0, _trace_remaining - delta)
	trace_label.modulate.a = clampf(_trace_remaining / 0.25, 0.0, 1.0) if _trace_remaining < 0.25 else 1.0


func _on_health_changed(current: int, maximum: int) -> void:
	health_fill.size.x = HEALTH_WIDTH * float(current) / float(maximum)
	health_value.text = "%d / %d" % [current, maximum]


func _on_potion_changed(charges: int) -> void:
	for index in potion_pips.size():
		potion_pips[index].color = Color("d4a33f") if index < charges else Color("344348")


func _on_action_traced(label: String) -> void:
	trace_label.text = label
	trace_label.modulate.a = 1.0
	_trace_remaining = 1.3
