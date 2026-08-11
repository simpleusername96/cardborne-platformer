class_name VehicleThreatRadar
extends Control

## Screen-space off-screen threat cues. Gameplay publishes one coherent
## five-hertz sector sample; this component rebases at most twelve retained
## representatives against the live player anchor.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)
const ThreatRadarFeed = preload(
	"res://scripts/presentation/vehicle_threat_radar_feed.gd"
)

const DIAMETER := 208.0
const OUTER_RADIUS := DIAMETER * 0.5
const ARC_RADIUS := 96.0
const SECTOR_COUNT := ThreatRadarFeed.SECTOR_COUNT
const ARC_HALF_WIDTH := PI / 18.0
const ARC_SEGMENTS := 12
const MIN_WIDTH_BUCKET := 3
const MAX_WIDTH_BUCKET := 15

var snapshot: Dictionary = {}
var _sample_sectors: Array[Dictionary] = []
var _display_sectors: Array[Dictionary] = []
var _arc_meshes: Dictionary = {}
var _triangle_mesh: ArrayMesh
var _live_world_position := Vector2.ZERO
var _live_screen_position := Vector2.ZERO
var _maximum_distance := 1200.0
var _visible := false
var _sample_generation := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for _sector_index in SECTOR_COUNT:
		_sample_sectors.append(_new_sector())
		_display_sectors.append(_new_sector())
	for width in range(MIN_WIDTH_BUCKET, MAX_WIDTH_BUCKET + 1):
		_arc_meshes[width] = _build_arc_mesh(float(width))
	_triangle_mesh = _build_triangle_mesh()
	resized.connect(queue_redraw)


func set_snapshot(value: Dictionary) -> void:
	snapshot = value
	_maximum_distance = maxf(1.0, float(value.get("max_distance", 1200.0)))
	_sample_generation = int(value.get("generation", _sample_generation))
	var source: Array = value.get("sectors", [])
	for index in SECTOR_COUNT:
		var target := _sample_sectors[index]
		_reset_sector(target)
		if index >= source.size():
			continue
		var incoming: Dictionary = source[index]
		if not bool(incoming.get("active", false)):
			continue
		target["active"] = true
		target["count"] = int(incoming.get("count", 1))
		target["world_position"] = Vector2(
			incoming.get("world_position", Vector2.ZERO)
		)
		target["kind"] = StringName(incoming.get(
			"kind", CombatCuePolicy.CONTACT_NEARBY_ENEMY
		))
		target["readiness"] = clampf(
			float(incoming.get("readiness", 0.0)), 0.0, 1.0
		)
	_rebase_sectors()
	queue_redraw()


func set_live_anchor(
	world_position: Vector2,
	screen_position: Vector2,
	is_visible: bool
) -> void:
	var world_changed := not _live_world_position.is_equal_approx(world_position)
	var screen_changed := not _live_screen_position.is_equal_approx(screen_position)
	var visibility_changed := _visible != is_visible
	if not world_changed and not screen_changed and not visibility_changed:
		return
	_live_world_position = world_position
	_live_screen_position = screen_position
	_visible = is_visible
	if world_changed:
		_rebase_sectors()
	queue_redraw()


func _draw() -> void:
	if not _visible:
		return
	var center := _live_screen_position
	center.x = clampf(center.x, OUTER_RADIUS + 8.0, size.x - OUTER_RADIUS - 8.0)
	center.y = clampf(center.y, OUTER_RADIUS + 8.0, size.y - OUTER_RADIUS - 8.0)
	for sector in _display_sectors:
		if not bool(sector["active"]):
			continue
		var angle := float(sector["angle"])
		var kind := StringName(sector["kind"])
		var readiness := clampf(float(sector["readiness"]), 0.0, 1.0)
		var proximity := 1.0 - clampf(
			float(sector["proximity_distance"]) / _maximum_distance,
			0.0,
			1.0
		)
		var density := minf(1.0, float(int(sector["count"]) - 1) / 5.0)
		var nearby := kind == CombatCuePolicy.CONTACT_NEARBY_ENEMY
		var width := (
			3.5 + density * 4.0 + proximity * 1.5
			if nearby
			else 5.0 + density * 5.0 + proximity * 2.0 + readiness * 2.0
		)
		var color := _kind_color(kind, readiness)
		var alpha := (
			0.26 + proximity * 0.18
			if nearby
			else 0.56 + proximity * 0.22 + readiness * 0.18
		)
		var transform := Transform2D(angle, center)
		draw_mesh(
			_mesh_for_width(width + 4.0),
			null,
			transform,
			Color(Art.COBALT_DEEP, 0.52 if nearby else 0.82)
		)
		draw_mesh(
			_mesh_for_width(width), null, transform, Color(color, alpha)
		)
		if CombatCuePolicy.contact_uses_triangle(kind):
			draw_mesh(_triangle_mesh, null, transform, color)


func _rebase_sectors() -> void:
	for sector in _display_sectors:
		_reset_sector(sector)
	for sample in _sample_sectors:
		if not bool(sample["active"]):
			continue
		var offset := Vector2(sample["world_position"]) - _live_world_position
		var distance := offset.length()
		if distance <= 0.001 or distance > _maximum_distance:
			continue
		var angle := offset.angle()
		var sector_index := posmod(
			floori((angle + PI) / TAU * float(SECTOR_COUNT)),
			SECTOR_COUNT
		)
		var target := _display_sectors[sector_index]
		var kind := StringName(sample["kind"])
		var readiness := float(sample["readiness"])
		var count := int(sample["count"])
		if not bool(target["active"]):
			target["active"] = true
			target["angle"] = angle
			target["distance"] = distance
			target["proximity_distance"] = distance
			target["count"] = count
			target["kind"] = kind
			target["readiness"] = readiness
			continue
		target["count"] = int(target["count"]) + count
		target["proximity_distance"] = minf(
			float(target["proximity_distance"]), distance
		)
		var priority := CombatCuePolicy.contact_priority(kind)
		var existing_priority := CombatCuePolicy.contact_priority(
			StringName(target["kind"])
		)
		if priority > existing_priority:
			target["kind"] = kind
			target["readiness"] = readiness
			target["angle"] = angle
			target["distance"] = distance
		elif priority == existing_priority:
			target["readiness"] = maxf(
				float(target["readiness"]), readiness
			)
			if distance < float(target["distance"]):
				target["angle"] = angle
				target["distance"] = distance


func _mesh_for_width(width: float) -> ArrayMesh:
	var bucket := clampi(roundi(width), MIN_WIDTH_BUCKET, MAX_WIDTH_BUCKET)
	return _arc_meshes[bucket]


func _build_arc_mesh(width: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var inner_radius := maxf(0.0, ARC_RADIUS - width * 0.5)
	var outer_radius := ARC_RADIUS + width * 0.5
	for segment in ARC_SEGMENTS:
		var ratio_a := float(segment) / float(ARC_SEGMENTS)
		var ratio_b := float(segment + 1) / float(ARC_SEGMENTS)
		var direction_a := Vector2.RIGHT.rotated(
			lerpf(-ARC_HALF_WIDTH, ARC_HALF_WIDTH, ratio_a)
		)
		var direction_b := Vector2.RIGHT.rotated(
			lerpf(-ARC_HALF_WIDTH, ARC_HALF_WIDTH, ratio_b)
		)
		var offset := vertices.size()
		for point in [
			direction_a * inner_radius,
			direction_a * outer_radius,
			direction_b * outer_radius,
			direction_b * inner_radius,
		]:
			vertices.append(Vector3(point.x, point.y, 0.0))
		for local_index in [0, 1, 2, 0, 2, 3]:
			indices.append(offset + local_index)
	return _mesh_from_arrays(vertices, indices)


func _build_triangle_mesh() -> ArrayMesh:
	var direction := Vector2.RIGHT
	var tangent := Vector2.DOWN
	var tip := direction * (ARC_RADIUS - 10.0)
	var vertices := PackedVector3Array()
	for point in [
		tip,
		tip - direction * 13.0 + tangent * 8.0,
		tip - direction * 13.0 - tangent * 8.0,
	]:
		vertices.append(Vector3(point.x, point.y, 0.0))
	return _mesh_from_arrays(vertices, PackedInt32Array([0, 1, 2]))


func _mesh_from_arrays(
	vertices: PackedVector3Array,
	indices: PackedInt32Array
) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _kind_color(kind: StringName, readiness: float) -> Color:
	match kind:
		CombatCuePolicy.CONTACT_BOSS_ARRIVAL:
			return Art.BOSS_COMMAND
		CombatCuePolicy.CONTACT_NEARBY_ENEMY:
			return Art.DANGER.lerp(Art.RAISED, 0.48)
		_:
			return Art.DANGER.lerp(Art.IVORY_BRIGHT, readiness * 0.36)


func _new_sector() -> Dictionary:
	return {
		"active":false,
		"angle":0.0,
		"distance":0.0,
		"proximity_distance":0.0,
		"count":0,
		"world_position":Vector2.ZERO,
		"kind":CombatCuePolicy.CONTACT_NEARBY_ENEMY,
		"readiness":0.0,
	}


func _reset_sector(sector: Dictionary) -> void:
	sector["active"] = false
	sector["angle"] = 0.0
	sector["distance"] = 0.0
	sector["proximity_distance"] = 0.0
	sector["count"] = 0
	sector["world_position"] = Vector2.ZERO
	sector["kind"] = CombatCuePolicy.CONTACT_NEARBY_ENEMY
	sector["readiness"] = 0.0


func debug_contract() -> Dictionary:
	var active_count := 0
	var first_active_angle := 0.0
	for sector in _display_sectors:
		if bool(sector["active"]):
			if active_count == 0:
				first_active_angle = float(sector["angle"])
			active_count += 1
	return {
		"diameter":DIAMETER,
		"sector_count":SECTOR_COUNT,
		"maximum_markers":SECTOR_COUNT,
		"offscreen_arcs":true,
		"objective_channel":true,
		"incoming_attack_only":false,
		"nearby_enemy_contact":true,
		"nearby_enemy_triangle":false,
		"contact_priorities":{
			"incoming_attack":CombatCuePolicy.contact_priority(
				CombatCuePolicy.CONTACT_INCOMING_ATTACK
			),
			"boss_arrival":CombatCuePolicy.contact_priority(
				CombatCuePolicy.CONTACT_BOSS_ARRIVAL
			),
			"nearby_enemy":CombatCuePolicy.contact_priority(
				CombatCuePolicy.CONTACT_NEARBY_ENEMY
			),
		},
		"retained_mesh_recipes":_arc_meshes.size() + 1,
		"mesh_recreated_per_anchor":false,
		"sample_generation":_sample_generation,
		"active_sector_count":active_count,
		"first_active_angle":first_active_angle,
		"live_anchor":_live_screen_position,
		"full_rect":is_zero_approx(anchor_left) and is_zero_approx(anchor_top) and is_equal_approx(anchor_right, 1.0) and is_equal_approx(anchor_bottom, 1.0),
		"mouse_ignored":mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}


func debug_aggregate_contacts(
	contacts: Array,
	maximum_distance: float = 1200.0
) -> Array[Dictionary]:
	var feed := ThreatRadarFeed.new(maximum_distance)
	feed.begin_sample(Vector2.ZERO)
	for contact_variant in contacts:
		var contact: Dictionary = contact_variant
		feed.append_offset(
			Vector2(contact.get("offset", Vector2.ZERO)),
			StringName(contact.get(
				"kind", CombatCuePolicy.CONTACT_INCOMING_ATTACK
			)),
			float(contact.get("readiness", 0.0))
		)
	feed.commit_sample()
	var result: Array[Dictionary] = []
	for sector_variant in Array(feed.snapshot()["sectors"]):
		var sector: Dictionary = sector_variant
		if not bool(sector["active"]):
			continue
		var offset := Vector2(sector["world_position"])
		result.append({
			"angle":offset.angle(),
			"distance":float(sector["distance"]),
			"proximity_distance":float(sector["proximity_distance"]),
			"count":int(sector["count"]),
			"kind":StringName(sector["kind"]),
			"readiness":float(sector["readiness"]),
		})
	return result
