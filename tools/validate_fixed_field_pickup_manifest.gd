extends SceneTree

const MIN_SUPPORT_MARGIN := 16.0
const MIN_PICKUP_CLEARANCE := 20.0
const MAX_PICKUP_CLEARANCE := 44.0
const MIN_ANCHOR_DISTANCE := 44.0
const MANIFEST := [
	{
		"scene": "res://scenes/rooms/lower_ruins/LrPatrolGallery.tscn",
		"node": "PatrolIronBundle",
		"id": &"ruin_patrol_iron_01",
		"definition": "res://data/items/rusted_scrap_fragment.tres",
	},
	{
		"scene": "res://scenes/rooms/lower_ruins/LrPatrolGallery.tscn",
		"node": "PatrolTimberBundle",
		"id": &"ruin_patrol_timber_01",
		"definition": "res://data/items/common_timber_bundle.tres",
	},
	{
		"scene": "res://scenes/rooms/lower_ruins/LrPatrolGallery.tscn",
		"node": "PatrolVitalShard",
		"id": &"ruin_patrol_vital_01",
		"definition": "res://data/items/vital_shard.tres",
	},
	{
		"scene": "res://scenes/rooms/lower_ruins/LrShooterOverlook.tscn",
		"node": "OverlookArrowBundle",
		"id": &"ruin_overlook_arrows_01",
		"definition": "res://data/items/arrow_bundle.tres",
	},
	{
		"scene": "res://scenes/rooms/lower_ruins/LrLowerUpperChoice.tscn",
		"node": "BranchRoughFiber",
		"id": &"ruin_choice_fiber_01",
		"definition": "res://data/items/sky_thread_wisp.tres",
	},
	{
		"scene": "res://scenes/rooms/lower_ruins/LrDestructibleCache.tscn",
		"node": "CacheCartridgePouch",
		"id": &"ruin_cache_cartridges_01",
		"definition": "res://data/items/cartridge_pouch.tres",
	},
	{
		"scene": "res://scenes/rooms/lower_ruins/LrExitAscent.tscn",
		"node": "AscentCoinBundle",
		"id": &"ruin_exit_coin_01",
		"definition": "res://data/items/coin_bundle.tres",
	},
	{
		"scene": "res://scenes/rooms/flooded_works/FwPoisonTiming.tscn",
		"node": "SafeLaneVitalShard",
		"id": &"flooded_poison_vital_01",
		"definition": "res://data/items/vital_shard.tres",
	},
	{
		"scene": "res://scenes/rooms/flooded_works/FwLeaperBasin.tscn",
		"node": "EscapeFocusShard",
		"id": &"flooded_basin_focus_01",
		"definition": "res://data/items/focus_shard.tres",
	},
	{
		"scene": "res://scenes/rooms/flooded_works/FwSunkenCache.tscn",
		"node": "SunkenThreadWisp",
		"id": &"flooded_cache_thread_01",
		"definition": "res://data/items/sky_thread_wisp.tres",
	},
	{
		"scene": "res://scenes/rooms/flooded_works/FwPumpGallery.tscn",
		"node": "GallerySupplyCharge",
		"id": &"flooded_pump_supply_01",
		"definition": "res://data/items/supply_charge.tres",
	},
	{
		"scene": "res://scenes/rooms/broken_sanctum/BsRecoveryCloister.tscn",
		"node": "CloisterVitalShard",
		"id": &"sanctum_cloister_vital_01",
		"definition": "res://data/items/vital_shard.tres",
	},
	{
		"scene": "res://scenes/rooms/broken_sanctum/BsSentryCrossfire.tscn",
		"node": "CrossfireFocusShard",
		"id": &"sanctum_crossfire_focus_01",
		"definition": "res://data/items/focus_shard.tres",
	},
	{
		"scene": "res://scenes/rooms/broken_sanctum/BsReliquaryCache.tscn",
		"node": "ReliquaryResidueDroplet",
		"id": &"sanctum_reliquary_residue_01",
		"definition": "res://data/items/slime_residue_droplet.tres",
	},
	{
		"scene": "res://scenes/rooms/broken_sanctum/BsExitAscent.tscn",
		"node": "ExitSupplyCharge",
		"id": &"sanctum_exit_supply_01",
		"definition": "res://data/items/supply_charge.tres",
	},
]

var _failures: Array[String] = []
var _seen_ids: Dictionary = {}
var _stage_counts: Dictionary = {
	"lower_ruins": 0,
	"flooded_works": 0,
	"broken_sanctum": 0,
}
var _scene_counts: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for entry in MANIFEST:
		var scene_path := String(entry["scene"])
		_scene_counts[scene_path] = int(_scene_counts.get(scene_path, 0)) + 1
	for entry in MANIFEST:
		await _validate_entry(entry)
	_expect(_seen_ids.size() == MANIFEST.size(), "fixed pickup IDs must be globally unique")
	for stage_id in _stage_counts:
		var expected_count := 7 if stage_id == "lower_ruins" else 4
		_expect(
			int(_stage_counts[stage_id]) == expected_count,
			"%s should contain exactly %d authored field pickups" % [stage_id, expected_count]
		)
	_finish()


func _validate_entry(entry: Dictionary) -> void:
	var scene_path := String(entry["scene"])
	var packed := load(scene_path) as PackedScene
	_expect(packed != null, "%s should load" % scene_path)
	if packed == null:
		return
	var room := packed.instantiate() as Node2D
	root.add_child(room)
	var pickup := room.get_node_or_null("FieldPickups/%s" % entry["node"]) as Node2D
	_expect(pickup != null, "%s should contain %s" % [scene_path, entry["node"]])
	if pickup != null:
		var pickup_id := StringName(pickup.get("pickup_id"))
		_expect(pickup_id == entry["id"], "%s pickup ID should match the manifest" % scene_path)
		_expect(not _seen_ids.has(pickup_id), "pickup ID %s is duplicated" % pickup_id)
		_seen_ids[pickup_id] = true
		var definition := pickup.get("definition") as Resource
		_expect(definition != null, "%s pickup needs a definition" % scene_path)
		if definition != null:
			_expect(
				definition.resource_path == entry["definition"],
				"%s pickup definition should match the manifest" % scene_path
			)
		var local_position := room.to_local(pickup.global_position)
		_expect(_has_authored_support(room, local_position), "%s pickup needs authored support" % scene_path)
		_validate_anchor_clearance(room, local_position, scene_path)
		_increment_stage_count(scene_path)
	var pickups_root := room.get_node_or_null("FieldPickups")
	_expect(
		pickups_root != null
		and pickups_root.get_child_count() == int(_scene_counts.get(scene_path, 0)),
		"%s pickup nodes should match the fixed manifest" % scene_path
	)
	room.queue_free()
	await process_frame


func _has_authored_support(room: Node2D, pickup_position: Vector2) -> bool:
	for root_name in [&"Terrain", &"OneWay"]:
		var surfaces_root := room.get_node_or_null(String(root_name))
		if surfaces_root == null:
			continue
		for surface in surfaces_root.get_children():
			if not surface is Node2D or not surface.has_meta("support_width"):
				continue
			var surface_node := surface as Node2D
			var width := float(surface.get_meta("support_width"))
			var left: float = surface_node.position.x - width * 0.5 + MIN_SUPPORT_MARGIN
			var right: float = surface_node.position.x + width * 0.5 - MIN_SUPPORT_MARGIN
			var clearance := float(surface.get_meta("support_top")) - pickup_position.y
			if (
				pickup_position.x >= left
				and pickup_position.x <= right
				and clearance >= MIN_PICKUP_CLEARANCE
				and clearance <= MAX_PICKUP_CLEARANCE
			):
				return true
	return false


func _validate_anchor_clearance(room: Node2D, pickup_position: Vector2, scene_path: String) -> void:
	for group_name in [&"Enemy", &"Reward"]:
		var anchor_root := room.get_node_or_null("Anchors/%s" % group_name)
		if anchor_root == null:
			continue
		for anchor in anchor_root.get_children():
			if anchor is Node2D:
				_expect(
					pickup_position.distance_to(anchor.position) >= MIN_ANCHOR_DISTANCE,
					"%s pickup overlaps %s anchor %s" % [scene_path, group_name, anchor.name]
				)


func _increment_stage_count(scene_path: String) -> void:
	for stage_id in _stage_counts:
		if scene_path.contains("/%s/" % stage_id):
			_stage_counts[stage_id] = int(_stage_counts[stage_id]) + 1
			return
	_failures.append("pickup scene is outside an approved stage family: %s" % scene_path)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("FIXED_FIELD_PICKUP_MANIFEST_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
