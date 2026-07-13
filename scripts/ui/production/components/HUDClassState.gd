class_name HUDClassState
extends Control

const Styles = preload("res://scripts/ui/production/ProductionUIStyles.gd")
const Glyph = preload("res://scripts/ui/production/components/HUDGlyph.gd")

var _profile_id: StringName = &"warrior"
var _state: Dictionary = {}
var _glyph: HUDGlyph
var _label: Label
var _meter_fraction: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(170.0, 19.0)
	_glyph = Glyph.new()
	_glyph.name = "ClassStateGlyph"
	add_child(_glyph)
	_label = Label.new()
	_label.name = "ClassStateText"
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Styles.configure_label(_label, 12, Styles.TEXT_MUTED)
	add_child(_label)
	_layout_children()
	_apply_state()


func configure(profile_id: StringName, state: Dictionary) -> void:
	_profile_id = profile_id if profile_id != &"" else &"warrior"
	_state = state.duplicate(true)
	_apply_state()


func get_display_snapshot() -> Dictionary:
	return {
		"profile_id": String(_profile_id),
		"text": _label.text if _label != null else "",
		"meter_fraction": _meter_fraction,
		"rect": get_rect(),
	}


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_children()
		queue_redraw()


func _draw() -> void:
	if _meter_fraction <= 0.0:
		return
	var rail := Rect2(24.0, size.y - 2.0, maxf(size.x - 26.0, 0.0), 2.0)
	draw_rect(rail, Color(Styles.OUTLINE, 0.56))
	draw_rect(
		Rect2(rail.position, Vector2(rail.size.x * _meter_fraction, rail.size.y)),
		Styles.class_accent(_profile_id)
	)


func _layout_children() -> void:
	if _glyph == null:
		return
	_glyph.position = Vector2(0.0, 0.0)
	_glyph.size = Vector2(19.0, 19.0)
	_label.position = Vector2(24.0, 0.0)
	_label.size = Vector2(maxf(size.x - 24.0, 0.0), size.y)


func _apply_state() -> void:
	if _label == null:
		return
	var text := ""
	_meter_fraction = 0.0
	match _profile_id:
		&"assassin":
			var flow := clampi(int(_state.get("flow_stacks", 0)), 0, 3)
			var marks := maxi(int(_state.get("death_mark_count", 0)), 0)
			text = "FLOW %d/3" % flow
			if marks > 0:
				text += " | MARK %d" % marks
			_meter_fraction = float(flow) / 3.0
		&"archer":
			var marks := maxi(int(_state.get("hunter_mark_count", 0)), 0)
			var charge := clampf(float(_state.get("charge_fraction", 0.0)), 0.0, 1.0)
			if charge > 0.0:
				text = "DRAW %d%% | MARK %d" % [int(round(charge * 100.0)), marks]
				_meter_fraction = charge
			elif bool(_state.get("quick_nock_ready", false)):
				text = "QUICK NOCK | MARK %d" % marks
				_meter_fraction = 1.0
			else:
				text = "HUNTER MARK %d" % marks
		&"warrior", _:
			var guard := maxf(float(_state.get("guarded_time", 0.0)), 0.0)
			var rearm := maxf(float(_state.get("guarded_rearm_time", 0.0)), 0.0)
			var rally := maxf(float(_state.get("rally_heavy_time", 0.0)), 0.0)
			if guard > 0.0:
				text = "RESOLVE GUARD %.1fs" % guard
				_meter_fraction = clampf(guard / 2.0, 0.0, 1.0)
			elif rally > 0.0:
				text = "RALLY %.1fs" % rally
				_meter_fraction = clampf(rally / 4.0, 0.0, 1.0)
			elif rearm > 0.0:
				text = "GUARD REARM %.1fs" % rearm
			else:
				text = "RESOLVE"
	_label.text = text
	_glyph.configure(_profile_id, Styles.class_accent(_profile_id))
	queue_redraw()
