extends SceneTree

const PLAYER_SCENE := "res://scenes/player/Player.tscn"
const ENEMY_SCENES := [
	"res://scenes/enemies/WalkerSanctum.tscn",
	"res://scenes/enemies/ChargerSanctum.tscn",
	"res://scenes/enemies/ShooterSanctum.tscn",
	"res://scenes/enemies/LeaperFlooded.tscn",
	"res://scenes/enemies/ShieldGuardSanctum.tscn",
	"res://scenes/enemies/SentrySanctum.tscn",
	"res://scenes/enemies/SummonNode.tscn",
	"res://scenes/enemies/SmallSlime.tscn",
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_validate_player_profiles()
	await _validate_enemy_archetypes()
	_finish()


func _validate_player_profiles() -> void:
	var packed := load(PLAYER_SCENE) as PackedScene
	_expect(packed != null, "player presentation scene should load")
	if packed == null:
		return
	var player := packed.instantiate()
	var overlay := player.get_node_or_null("Visual/PlayerVisualOverlay") as PlayerVisualOverlay
	_expect(overlay != null, "player should own the procedural identity overlay")
	var facing := player.get_node_or_null("Visual/FacingMarker") as Polygon2D
	_expect(facing != null and not facing.visible, "placeholder facing arrow should stay retired")
	if overlay != null:
		for profile_id in [&"warrior", &"archer", &"assassin"]:
			overlay.configure(profile_id, Color.WHITE)
			_expect(
				overlay.get_visual_contract().get("profile_id") == String(profile_id),
				"player overlay should retain %s identity" % profile_id
			)
	player.free()


func _validate_enemy_archetypes() -> void:
	var seen: Dictionary = {}
	var world := Node2D.new()
	root.add_child(world)
	for scene_path in ENEMY_SCENES:
		var packed := load(scene_path) as PackedScene
		_expect(packed != null, "enemy presentation scene should load: %s" % scene_path)
		if packed == null:
			continue
		var enemy := packed.instantiate()
		world.add_child(enemy)
		await process_frame
		var overlay := enemy.get_node_or_null("EnemyDetailOverlay") as EnemyDetailOverlay
		_expect(overlay != null, "%s should own detail overlay" % enemy.name)
		if overlay != null:
			var contract := overlay.get_visual_contract()
			var archetype := String(contract.get("archetype_id", ""))
			seen[archetype] = true
			_expect(contract.get("accent") is Color, "%s should resolve a stage accent" % enemy.name)
		enemy.queue_free()
		await process_frame
	for archetype in ["walker", "charger", "shooter", "leaper", "shield_guard", "sentry", "summon_node", "small_slime"]:
		_expect(seen.has(archetype), "presentation fixture should cover %s" % archetype)
	world.queue_free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("ACTOR_PRESENTATION_VALIDATION_OK profiles=3 archetypes=8")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
