extends SceneTree

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ActorCatalog = preload("res://scripts/presentation/components/vehicle_actor_visual_catalog.gd")
const AssetProvider = preload("res://scripts/presentation/components/vehicle_semantic_asset_provider.gd")
const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const Run = preload("res://scripts/vehicle/vehicle_run.gd")

var failures: PackedStringArray = []


func _initialize() -> void:
	var player := ActorCatalog.descriptor(&"player")
	_expect(not player.is_empty(), "player descriptor exists")
	var anchors := Array(player.get("rear_anchors", []))
	_expect(
		anchors.size() == 1 and Vector2(anchors[0]).is_equal_approx(Vector2(-0.84, 0.0)),
		"player keeps one hull-relative rear anchor"
	)
	var craft := AssetProvider.descriptor(&"attachment/player_craft_body")
	_expect(
		AssetProvider.texture(&"attachment/player_craft_body") != null
			and Vector2(craft.get("canvas", Vector2.ZERO)) == Vector2(160, 128)
			and Vector2(craft.get("pivot", Vector2.ZERO)) == Vector2(88, 64),
		"integrated craft resolves through its authored canvas and pivot"
	)
	for degrees in range(0, 360, 5):
		var angle := deg_to_rad(float(degrees))
		var origin := Vector2(940.0, 520.0)
		var anchor := Renderer.player_rear_anchors(origin, Vector2.RIGHT.rotated(angle))[0]
		_expect(
			(anchor - origin).rotated(-angle).distance_to(Vector2(-0.84, 0.0) * Art.PLAYER_VISUAL_RADIUS) <= 1.0,
			"rear anchor remains rigid at %d degrees" % degrees
		)
	for asset_id in [&"cue/beam_strip_9", &"cue/diamond_marker", &"cue/ring", &"cue/crosshair"]:
		_expect(AssetProvider.texture(asset_id) != null, "%s is an authored gameplay cue" % asset_id)
	_expect(Run.MAX_DASH_AFTERIMAGES <= 5, "dash afterimage cap is at most five")
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_PLAYER_PRESENTATION_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
