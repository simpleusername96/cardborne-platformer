class_name VehicleThreatRadar
extends Control

## Screen-space off-screen threat cues inspired by radial audio visualizers.
## Gameplay supplies sampled semantic contacts; this component only aggregates
## them into short project-styled arcs around the projected player.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const CombatCuePolicy = preload(
	"res://scripts/presentation/components/vehicle_combat_cue_policy.gd"
)

const DIAMETER := 208.0
const OUTER_RADIUS := DIAMETER * 0.5
const ARC_RADIUS := 96.0
const SECTOR_COUNT := 12
const ARC_HALF_WIDTH := PI / 18.0

var snapshot: Dictionary = {}
var _threat_mesh: ArrayMesh
var _mesh_dirty := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_invalidate_mesh)


func set_snapshot(value: Dictionary) -> void:
	# Run refreshes this borrowed wrapper only at the same five-hertz publication
	# boundary; draw never observes it being mutated between publications.
	snapshot = value
	_mesh_dirty = true
	queue_redraw()


func _draw() -> void:
	if not bool(snapshot.get("visible", false)):
		return
	var center: Vector2 = snapshot.get("center", size * 0.5)
	center.x = clampf(center.x, OUTER_RADIUS + 8.0, size.x - OUTER_RADIUS - 8.0)
	center.y = clampf(center.y, OUTER_RADIUS + 8.0, size.y - OUTER_RADIUS - 8.0)
	var sectors := _aggregate_contacts(snapshot.get("contacts", []), float(snapshot.get("max_distance", 1200.0)))
	if _mesh_dirty:
		_threat_mesh = _build_threat_mesh(
			center,
			sectors,
			float(snapshot.get("max_distance", 1200.0))
		)
		_mesh_dirty = false
	if _threat_mesh != null:
		draw_mesh(_threat_mesh, null)


func _aggregate_contacts(contacts: Array, maximum_distance: float) -> Array[Dictionary]:
	var buckets: Array[Dictionary] = []
	for _index in SECTOR_COUNT:
		buckets.append({})
	for contact_variant in contacts:
		var contact: Dictionary = contact_variant
		var offset: Vector2 = contact.get("offset", Vector2.ZERO)
		var distance := offset.length()
		if distance <= 0.001 or distance > maximum_distance:
			continue
		var angle := offset.angle()
		var sector_index := posmod(floori((angle + PI) / TAU * float(SECTOR_COUNT)), SECTOR_COUNT)
		var existing: Dictionary = buckets[sector_index]
		var kind := StringName(contact.get(
			"kind", CombatCuePolicy.CONTACT_INCOMING_ATTACK
		))
		var readiness := clampf(float(contact.get("readiness", 0.0)), 0.0, 1.0)
		if existing.is_empty():
			buckets[sector_index] = {
				"angle": angle,
				"distance": distance,
				"count": 1,
				"kind":kind,
				"readiness":readiness,
				"objective_id":String(contact.get("objective_id", "")),
			}
			continue
		existing["count"] = int(existing["count"]) + 1
		existing["readiness"] = maxf(float(existing["readiness"]), readiness)
		if _kind_priority(kind) > _kind_priority(StringName(existing["kind"])):
			existing["kind"] = kind
			existing["objective_id"] = String(contact.get("objective_id", ""))
		if distance < float(existing["distance"]):
			existing["angle"] = angle
			existing["distance"] = distance
		buckets[sector_index] = existing
	var result: Array[Dictionary] = []
	for bucket in buckets:
		if not bucket.is_empty():
			result.append(bucket)
	return result


func _build_threat_mesh(
	center: Vector2,
	sectors: Array[Dictionary],
	maximum_distance: float
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for sector in sectors:
		var angle := float(sector["angle"])
		var kind := StringName(sector["kind"])
		var readiness := clampf(float(sector["readiness"]), 0.0, 1.0)
		var proximity := 1.0 - clampf(
			float(sector["distance"]) / maxf(1.0, maximum_distance),
			0.0,
			1.0
		)
		var density := minf(1.0, float(int(sector["count"]) - 1) / 5.0)
		var width := 5.0 + density * 5.0 + proximity * 2.0 + readiness * 2.0
		var color := _kind_color(kind, readiness)
		var alpha := 0.56 + proximity * 0.22 + readiness * 0.18
		_append_arc_band(
			vertices, colors, indices, center, ARC_RADIUS + 2.0,
			angle - ARC_HALF_WIDTH, angle + ARC_HALF_WIDTH, width + 4.0,
			Color(Art.COBALT_DEEP, 0.82), 12
		)
		_append_arc_band(
			vertices, colors, indices, center, ARC_RADIUS,
			angle - ARC_HALF_WIDTH, angle + ARC_HALF_WIDTH, width,
			Color(color, alpha), 12
		)
		var direction := Vector2.RIGHT.rotated(angle)
		var tangent := direction.rotated(PI * 0.5)
		var tip := center + direction * (ARC_RADIUS - 10.0)
		if kind in [
			CombatCuePolicy.CONTACT_INCOMING_ATTACK,
			CombatCuePolicy.CONTACT_BOSS_ARRIVAL,
		]:
			_append_triangle(
				vertices,
				colors,
				indices,
				tip,
				tip - direction * 13.0 + tangent * 8.0,
				tip - direction * 13.0 - tangent * 8.0,
				color
			)
	if vertices.is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _kind_priority(kind: StringName) -> int:
	match kind:
		CombatCuePolicy.CONTACT_INCOMING_ATTACK:
			return 3
		CombatCuePolicy.CONTACT_BOSS_ARRIVAL:
			return 2
		CombatCuePolicy.CONTACT_BOSS_OBJECTIVE:
			return 1
	return 0


func _kind_color(kind: StringName, readiness: float) -> Color:
	match kind:
		CombatCuePolicy.CONTACT_BOSS_OBJECTIVE:
			return Art.PLAYER_REWARD
		CombatCuePolicy.CONTACT_BOSS_ARRIVAL:
			return Art.BOSS_COMMAND
		_:
			return Art.DANGER.lerp(Art.IVORY_BRIGHT, readiness * 0.36)


func _append_arc_band(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	center: Vector2,
	radius: float,
	from_angle: float,
	to_angle: float,
	width: float,
	color: Color,
	segments: int
) -> void:
	var inner_radius := maxf(0.0, radius - width * 0.5)
	var outer_radius := radius + width * 0.5
	for segment in segments:
		var ratio_a := float(segment) / float(segments)
		var ratio_b := float(segment + 1) / float(segments)
		var direction_a := Vector2.RIGHT.rotated(lerpf(from_angle, to_angle, ratio_a))
		var direction_b := Vector2.RIGHT.rotated(lerpf(from_angle, to_angle, ratio_b))
		var offset := vertices.size()
		for point in [
			center + direction_a * inner_radius,
			center + direction_a * outer_radius,
			center + direction_b * outer_radius,
			center + direction_b * inner_radius,
		]:
			vertices.append(Vector3(point.x, point.y, 0.0))
			colors.append(color)
		for local_index in [0, 1, 2, 0, 2, 3]:
			indices.append(offset + local_index)


func _append_triangle(
	vertices: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	point_a: Vector2,
	point_b: Vector2,
	point_c: Vector2,
	color: Color
) -> void:
	var offset := vertices.size()
	for point in [point_a, point_b, point_c]:
		vertices.append(Vector3(point.x, point.y, 0.0))
		colors.append(color)
	for local_index in [0, 1, 2]:
		indices.append(offset + local_index)


func _invalidate_mesh() -> void:
	_mesh_dirty = true
	queue_redraw()


func debug_contract() -> Dictionary:
	return {
		"diameter": DIAMETER,
		"sector_count": SECTOR_COUNT,
		"maximum_markers": SECTOR_COUNT,
		"offscreen_arcs": true,
		"objective_channel":true,
		"incoming_attack_only":true,
		"batched_mesh": true,
		"full_rect": is_zero_approx(anchor_left) and is_zero_approx(anchor_top) and is_equal_approx(anchor_right, 1.0) and is_equal_approx(anchor_bottom, 1.0),
		"mouse_ignored": mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}
