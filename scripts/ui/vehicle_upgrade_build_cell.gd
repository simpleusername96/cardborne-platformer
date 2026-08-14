class_name VehicleUpgradeBuildCell
extends PanelContainer

## One read-only current-build cell. The rail owns the single shared detail
## popover; this component only exposes its frozen record and focus intent.

signal preview_requested(record: Dictionary, anchor: Control)
signal pin_requested(record: Dictionary, anchor: Control)
signal preview_closed(anchor: Control)

const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)
const UiGlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

var _record: Dictionary = {}
var _button: Button
var _artwork: TextureRect
var _normal_frame: StyleBoxFlat
var _focused_frame: StyleBoxFlat
var _action_glyph_id: StringName = &""


func _ready() -> void:
	_build()


func set_record(record: Dictionary, cell_size: float, artwork_size: float) -> void:
	_record = record.duplicate(true)
	if not is_node_ready():
		return
	custom_minimum_size = Vector2(cell_size, cell_size)
	var filled := not _record.is_empty()
	_action_glyph_id = StringName(_record.get("action_glyph_id", &""))
	visible = true
	if not filled:
		theme_type_variation = &"PreviewFrame"
		_button.focus_mode = Control.FOCUS_NONE
		_button.disabled = true
		_button.accessibility_name = ""
		_artwork.texture = null
		queue_redraw()
		return
	theme_type_variation = &"PreviewFrame"
	_button.focus_mode = Control.FOCUS_ALL
	_button.disabled = false
	_button.accessibility_name = tr(String(_record.get("title_key", "")))
	_artwork.custom_minimum_size = Vector2(artwork_size, artwork_size)
	_artwork.texture = (
		null if not _action_glyph_id.is_empty()
		else SemanticAssets.texture(StringName(_record.get("artwork_asset_id", &"")))
	)
	queue_redraw()


func record() -> Dictionary:
	return _record.duplicate(true)


func is_filled() -> bool:
	return not _record.is_empty()


func _build() -> void:
	custom_minimum_size = Vector2(24.0, 24.0)
	theme_type_variation = &"PreviewFrame"
	_normal_frame = _make_frame(false)
	_focused_frame = _make_frame(true)
	add_theme_stylebox_override("panel", _normal_frame)
	_button = Button.new()
	_button.flat = true
	_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_button.focus_entered.connect(_request_preview)
	_button.focus_exited.connect(_request_close)
	_button.mouse_entered.connect(_request_preview)
	_button.mouse_exited.connect(_request_close)
	_button.pressed.connect(_request_pin)
	var empty_style := StyleBoxEmpty.new()
	for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		_button.add_theme_stylebox_override(style_name, empty_style)
	add_child(_button)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_button.add_child(center)
	_artwork = TextureRect.new()
	_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_artwork)


func _make_frame(focused: bool) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(Art.SPACE_BLACK, 0.60)
	frame.border_color = Art.IVORY_BRIGHT if focused else Art.LINE
	var border_width := Art.FOCUS_WIDTH if focused else Art.BORDER_WIDTH
	frame.set_border_width_all(border_width)
	frame.set_content_margin_all(1.0)
	return frame


func _draw() -> void:
	if _action_glyph_id.is_empty():
		return
	var glyph_scale := minf(size.x, size.y) * 0.34
	UiGlyphCatalog.draw_action_glyph(
		self,
		_action_glyph_id,
		size * 0.5,
		glyph_scale,
		{
			&"primary":Art.SYSTEM,
			&"secondary":Color(Art.SYSTEM, 0.72),
			&"highlight":Art.IVORY_BRIGHT,
		}
	)


func _request_preview() -> void:
	if is_filled():
		theme_type_variation = &"PreviewFocused"
		add_theme_stylebox_override("panel", _focused_frame)
		preview_requested.emit(record(), self)


func _request_pin() -> void:
	if is_filled():
		pin_requested.emit(record(), self)


func _request_close() -> void:
	if is_filled():
		preview_closed.emit(self)


func clear_focus_state() -> void:
	theme_type_variation = &"PreviewFrame"
	add_theme_stylebox_override("panel", _normal_frame)
