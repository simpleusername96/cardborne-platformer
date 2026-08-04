class_name VehicleCombatMeshIcon
extends Control

## Small semantic-v2 enemy silhouette used by reports and dense UI rows.

const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

var _view: TextureRect
var _asset_id: StringName = &""


func _ready() -> void:
	custom_minimum_size = Vector2(40.0, 40.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)


func set_enemy(archetype: StringName) -> void:
	_asset_id = StringName("actor/%s" % archetype)
	if not SemanticAssets.has_asset(_asset_id):
		_asset_id = &"boss/crown"
	if not is_instance_valid(_view):
		_view = TextureRect.new()
		_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_view)
	_view.texture = SemanticAssets.texture(_asset_id)
	_layout()


func debug_contract() -> Dictionary:
	return {
		"semantic_provider":true,
		"asset_id":_asset_id,
		"has_texture":is_instance_valid(_view) and _view.texture != null,
	}


func _layout() -> void:
	if is_instance_valid(_view):
		_view.position = Vector2.ZERO
		_view.size = size
