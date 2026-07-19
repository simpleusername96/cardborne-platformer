class_name CombatSandboxHud3D
extends CanvasLayer

const HEALTH_WIDTH := 240.0
const RANGED_READY_WIDTH := 88.0

var trace_remaining := 0.0

@onready var traveler: Traveler3D = get_node("../Traveler")
@onready var health_fill: ColorRect = $Root/Status/HealthTrack/HealthFill
@onready var health_value: Label = $Root/Status/HealthValue
@onready var potion_pips: Array[ColorRect] = [
	$Root/Status/Potions/Potion1,
	$Root/Status/Potions/Potion2,
	$Root/Status/Potions/Potion3,
]
@onready var trace_label: Label = $Root/ActionTrace
@onready var ranged_value := get_node_or_null("Root/Status/RangedValue") as Label
@onready var ranged_ready_fill := get_node_or_null("Root/Status/RangedReadyTrack/RangedReadyFill") as ColorRect
@onready var pause_overlay: ColorRect = $Root/PauseOverlay
@onready var master_slider := get_node_or_null("Root/PauseOverlay/Settings/Master") as HSlider
@onready var sfx_slider := get_node_or_null("Root/PauseOverlay/Settings/SFX") as HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.visible = false
	traveler.health_changed.connect(_on_health_changed)
	traveler.potion_changed.connect(_on_potion_changed)
	traveler.action_traced.connect(_on_action_traced)
	_on_health_changed(traveler.health, traveler.max_health)
	_on_potion_changed(traveler.potion_charges)
	if master_slider != null and sfx_slider != null:
		var settings := get_node("/root/SettingsStore") as PivotSettingsStore
		master_slider.value = settings.master_volume * 100.0
		sfx_slider.value = settings.sfx_volume * 100.0
		master_slider.value_changed.connect(func(value: float) -> void: settings.set_master_volume(value / 100.0))
		sfx_slider.value_changed.connect(func(value: float) -> void: settings.set_sfx_volume(value / 100.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		get_tree().paused = not get_tree().paused
		pause_overlay.visible = get_tree().paused
		if get_tree().paused and master_slider != null:
			master_slider.grab_focus()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	get_tree().paused = false


func _process(delta: float) -> void:
	trace_remaining = maxf(0.0, trace_remaining - delta)
	trace_label.modulate.a = clampf(trace_remaining / 0.25, 0.0, 1.0) if trace_remaining < 0.25 else 1.0
	if ranged_value != null and ranged_ready_fill != null:
		var ready_ratio := 1.0 - traveler.ranged_cooldown_remaining / Traveler3D.RANGED_COOLDOWN
		ranged_ready_fill.size.x = RANGED_READY_WIDTH * clampf(ready_ratio, 0.0, 1.0)
		ranged_value.modulate.a = 1.0 if ready_ratio >= 1.0 else 0.58


func _on_health_changed(current: int, maximum: int) -> void:
	health_fill.size.x = HEALTH_WIDTH * float(current) / float(maximum)
	health_value.text = "%d / %d" % [current, maximum]


func _on_potion_changed(charges: int) -> void:
	for index in potion_pips.size():
		potion_pips[index].color = Color("d4a33f") if index < charges else Color("344348")


func _on_action_traced(label: String) -> void:
	trace_label.text = label
	trace_label.modulate.a = 1.0
	trace_remaining = 1.3
