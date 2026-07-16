class_name ProductionAssetIcon
extends TextureRect

const Assets = preload("res://scripts/ui/production/ProductionUIAssets.gd")

var asset_id: StringName


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func configure(
	requested_asset_id: StringName,
	tint: Color = Color.WHITE,
	display_size: float = 32.0
) -> void:
	asset_id = requested_asset_id
	texture = Assets.texture(asset_id)
	self_modulate = tint
	custom_minimum_size = Vector2(display_size, display_size)
	visible = texture != null


func get_asset_id() -> StringName:
	return asset_id
