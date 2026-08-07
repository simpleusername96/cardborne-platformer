class_name VehicleAcquiredUpgradeRail
extends VBoxContainer

## Event-driven live-build receipt. The gameplay HUD owns placement while this
## component owns compact acquired-only icon rows and level numerals.

const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const MAX_PER_ROW := 12
const MAX_VISIBLE := 18
const STANDARD_ICON_SIZE := 30.0
const COMPACT_ICON_SIZE := 26.0
const ACCESSIBILITY_ICON_SIZE := 34.0

var _upgrades: Array[Dictionary] = []
var _signature := ""
var _icon_size := STANDARD_ICON_SIZE
var _rebuild_count := 0


func _ready() -> void:
	name = "AcquiredUpgradeRail"
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 3)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN


func set_build_snapshot(snapshot: Dictionary) -> void:
	var next_upgrades: Array[Dictionary] = []
	for value in Array(snapshot.get("upgrades", [])).slice(0, MAX_VISIBLE):
		next_upgrades.append(Dictionary(value).duplicate(true))
	var next_signature := var_to_str(next_upgrades)
	if next_signature == _signature:
		return
	_signature = next_signature
	_upgrades = next_upgrades
	_rebuild()


func set_layout_profile(compact: bool, accessibility: bool) -> void:
	var next_size := (
		ACCESSIBILITY_ICON_SIZE
		if accessibility
		else (COMPACT_ICON_SIZE if compact else STANDARD_ICON_SIZE)
	)
	if is_equal_approx(next_size, _icon_size):
		return
	_icon_size = next_size
	_rebuild()


func refresh_localized_content() -> void:
	if not _upgrades.is_empty():
		_rebuild()


func debug_contract() -> Dictionary:
	var texture_count := 0
	for node in find_children("*", "TextureRect", true, false):
		if (node as TextureRect).texture != null:
			texture_count += 1
	return {
		"acquired_count":_upgrades.size(),
		"row_count":get_child_count(),
		"maximum_per_row":MAX_PER_ROW,
		"maximum_visible":MAX_VISIBLE,
		"icon_size":_icon_size,
		"texture_count":texture_count,
		"empty_slot_count":0,
		"panel_free":true,
		"level_numerals":true,
		"rebuild_count":_rebuild_count,
	}


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if _upgrades.is_empty():
		visible = false
		_rebuild_count += 1
		return
	visible = true
	var row_start := 0
	while row_start < _upgrades.size():
		var row := HBoxContainer.new()
		row.name = "UpgradeRow%d" % (get_child_count() + 1)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)
		var row_end := mini(row_start + MAX_PER_ROW, _upgrades.size())
		for index in range(row_start, row_end):
			row.add_child(_icon_cell(_upgrades[index]))
		row_start = row_end
	_rebuild_count += 1


func _icon_cell(upgrade: Dictionary) -> Control:
	var cell := Control.new()
	cell.name = "Upgrade_%s" % String(upgrade.get("id", &"unknown"))
	cell.custom_minimum_size = Vector2(_icon_size, _icon_size + 13.0)
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var level := Label.new()
	level.name = "LevelNumeral"
	level.text = str(maxi(1, int(upgrade.get("level", 1))))
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level.position = Vector2(0.0, -1.0)
	level.size = Vector2(_icon_size, 14.0)
	level.add_theme_font_size_override("font_size", 13)
	level.add_theme_color_override("font_color", Color.WHITE)
	level.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.08, 0.94))
	level.add_theme_constant_override("shadow_offset_x", 1)
	level.add_theme_constant_override("shadow_offset_y", 1)
	level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(level)
	var artwork := TextureRect.new()
	artwork.name = "Artwork"
	artwork.texture = SemanticAssets.texture(
		StringName(upgrade.get("artwork_asset_id", &""))
	)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.position = Vector2(0.0, 13.0)
	artwork.size = Vector2.ONE * _icon_size
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(artwork)
	cell.tooltip_text = tr(String(upgrade.get("title_key", "")))
	return cell
