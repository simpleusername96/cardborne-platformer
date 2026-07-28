class_name VehicleUiChromeFactory
extends RefCounted

## Builds the approved image-backed Theme once from the published recipe.
## Screens retain text, focus, selection, disabled, and changing-value truth.

const RECIPE_PATH := (
	"res://pixel-art-production/runtime/ui/space-hangar-v2/chrome-recipe.json"
)
const ASSET_ROOT := "res://pixel-art-production/runtime/ui/space-hangar-v2"
const LIGHT_TEXT := Color("#F1E6BE")
const MUTED_TEXT := Color("#B7C7C2")

var _theme: Theme
var _styles: Dictionary = {}
var _errors := PackedStringArray()
var _mapping_count := 0
var _recipe_sha256 := ""


func build(base_theme: Theme) -> Theme:
	if _theme != null:
		return _theme
	_theme = base_theme.duplicate(true) as Theme
	if _theme == null:
		_errors.append("Base vehicle Theme could not be duplicated.")
		return base_theme
	if not _load_recipe():
		for message in _errors:
			push_error(message)
		return _theme
	_apply_text_palette()
	_apply_additional_variations()
	return _theme


func debug_contract() -> Dictionary:
	return {
		"loaded":_theme != null and _errors.is_empty(),
		"recipe_path":RECIPE_PATH,
		"recipe_sha256":_recipe_sha256,
		"style_count":_styles.size(),
		"mapping_count":_mapping_count,
		"errors":_errors.duplicate(),
	}


func _load_recipe() -> bool:
	if not FileAccess.file_exists(RECIPE_PATH):
		_errors.append("Published UI chrome recipe is missing.")
		return false
	_recipe_sha256 = FileAccess.get_sha256(RECIPE_PATH)
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(RECIPE_PATH)
	)
	if not parsed is Dictionary:
		_errors.append("Published UI chrome recipe is invalid.")
		return false
	var recipe := Dictionary(parsed)
	var family_by_file := {}
	for family_value in Array(recipe.get("families", [])):
		var family := Dictionary(family_value)
		for output_value in Array(family.get("outputs", [])):
			family_by_file[String(output_value)] = family
	for target_value in Array(recipe.get("theme_targets", [])):
		var target := Dictionary(target_value)
		var target_name := StringName(target.get("target", ""))
		for style_value in Dictionary(target.get("mapping", {})):
			var style_name := StringName(style_value)
			var file_name := String(
				Dictionary(target["mapping"])[style_value]
			)
			if not family_by_file.has(file_name):
				_errors.append("UI mapping references an undeclared file: %s" % file_name)
				continue
			var style := _style_for(file_name, Dictionary(family_by_file[file_name]))
			if style != null:
				_theme.set_stylebox(style_name, target_name, style)
				_mapping_count += 1
	return _errors.is_empty()


func _style_for(file_name: String, family: Dictionary) -> StyleBoxTexture:
	if _styles.has(file_name):
		return _styles[file_name]
	var texture := load("%s/%s" % [ASSET_ROOT, file_name]) as Texture2D
	if texture == null:
		_errors.append("Published UI chrome texture is missing: %s" % file_name)
		return null
	var patch := Array(family.get("patch_margins", []))
	var insets := Array(family.get("content_insets", []))
	if patch.size() != 4 or insets.size() != 4:
		_errors.append("UI chrome margins are invalid: %s" % file_name)
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = float(patch[0])
	style.texture_margin_right = float(patch[1])
	style.texture_margin_top = float(patch[2])
	style.texture_margin_bottom = float(patch[3])
	style.content_margin_left = float(insets[0])
	style.content_margin_right = float(insets[1])
	style.content_margin_top = float(insets[2])
	style.content_margin_bottom = float(insets[3])
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_styles[file_name] = style
	return style


func _apply_text_palette() -> void:
	for type_name in [
		&"Label",
		&"Button",
		&"OptionButton",
		&"CheckButton",
	]:
		_theme.set_color(&"font_color", type_name, LIGHT_TEXT)
		_theme.set_color(&"font_hover_color", type_name, LIGHT_TEXT)
		_theme.set_color(&"font_pressed_color", type_name, LIGHT_TEXT)
		_theme.set_color(&"font_focus_color", type_name, LIGHT_TEXT)
		_theme.set_color(&"font_disabled_color", type_name, MUTED_TEXT)
	for type_name in [&"TabBar", &"TabContainer"]:
		_theme.set_color(&"font_unselected_color", type_name, LIGHT_TEXT)
		_theme.set_color(&"font_hovered_color", type_name, LIGHT_TEXT)
		_theme.set_color(&"font_selected_color", type_name, LIGHT_TEXT)


func _apply_additional_variations() -> void:
	var panel := _styles.get("panel-normal.png") as StyleBoxTexture
	var hud := _styles.get("hud-frame-normal.png") as StyleBoxTexture
	var normal := _styles.get("button-normal.png") as StyleBoxTexture
	var hover := _styles.get("button-hover.png") as StyleBoxTexture
	var pressed := _styles.get("button-pressed.png") as StyleBoxTexture
	var focus := _styles.get("button-focus.png") as StyleBoxTexture
	var disabled := _styles.get("button-disabled.png") as StyleBoxTexture
	var tab_normal := _styles.get("tab-normal.png") as StyleBoxTexture
	var tab_hovered := _styles.get("tab-hovered.png") as StyleBoxTexture
	var tab_selected := _styles.get("tab-selected.png") as StyleBoxTexture
	var tab_focus := _styles.get("tab-focus.png") as StyleBoxTexture
	for type_name in [&"ModalSurface", &"SummaryBand"]:
		_theme.set_stylebox(&"panel", type_name, panel)
		_mapping_count += 1
	for type_name in [&"FlatPanel", &"HudStatusGroup"]:
		_theme.set_stylebox(&"panel", type_name, hud)
		_mapping_count += 1
	for type_name in [
		&"PrimaryButton",
		&"SecondaryButton",
		&"ChoiceButton",
	]:
		_set_button_styles(type_name, normal, hover, pressed, focus, disabled)
		_set_button_text_colors(type_name)
	for type_name in [&"DangerButton", &"TertiaryDangerButton"]:
		_set_button_styles(type_name, normal, hover, pressed, focus, disabled)
	for type_name in [&"SelectedChoiceButton", &"SelectedRailButton"]:
		_set_button_styles(type_name, focus, focus, pressed, focus, disabled)
	_set_button_text_colors(&"SelectedChoiceButton")
	for type_name in [&"TabContainer", &"TabBar"]:
		_theme.set_stylebox(&"tab_unselected", type_name, tab_normal)
		_theme.set_stylebox(&"tab_hovered", type_name, tab_hovered)
		_theme.set_stylebox(&"tab_selected", type_name, tab_selected)
		_theme.set_stylebox(&"tab_focus", type_name, tab_focus)
		_mapping_count += 4
	_theme.set_stylebox(&"panel", &"TabContainer", panel)
	_mapping_count += 1


func _set_button_styles(
	type_name: StringName,
	normal: StyleBoxTexture,
	hover: StyleBoxTexture,
	pressed: StyleBoxTexture,
	focus: StyleBoxTexture,
	disabled: StyleBoxTexture
) -> void:
	_theme.set_stylebox(&"normal", type_name, normal)
	_theme.set_stylebox(&"hover", type_name, hover)
	_theme.set_stylebox(&"pressed", type_name, pressed)
	_theme.set_stylebox(&"focus", type_name, focus)
	_theme.set_stylebox(&"disabled", type_name, disabled)
	_mapping_count += 5


func _set_button_text_colors(type_name: StringName) -> void:
	for color_name in [
		&"font_color",
		&"font_hover_color",
		&"font_pressed_color",
		&"font_focus_color",
	]:
		_theme.set_color(color_name, type_name, LIGHT_TEXT)
	_theme.set_color(&"font_disabled_color", type_name, MUTED_TEXT)
