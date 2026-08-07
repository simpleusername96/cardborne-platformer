class_name VehicleCombatCuePolicy
extends RefCounted

## Presentation-only policy for deciding which combat truths need an explicit
## cue. Gameplay continues to own attack geometry, damage, collision, and time.

const MODE_NONE: StringName = &"none"
const MODE_CHARGE_FOOTPRINT: StringName = &"charge_footprint"
const MODE_BEAM_WARNING: StringName = &"beam_warning"
const MODE_ACTIVE_BEAM: StringName = &"active_beam"
const MODE_AREA_FOOTPRINT: StringName = &"area_footprint"

const CONTACT_INCOMING_ATTACK: StringName = &"incoming_attack"
const CONTACT_BOSS_OBJECTIVE: StringName = &"boss_objective"
const CONTACT_BOSS_ARRIVAL: StringName = &"boss_arrival"


static func telegraph_mode(
	_source_position: Vector2,
	_source_radius: float,
	phase: StringName,
	telegraph: Dictionary,
	visible_world: Rect2
) -> StringName:
	if not _is_damaging(telegraph) or not telegraph_intersects_view(
		telegraph, visible_world
	):
		return MODE_NONE
	var shape := StringName(telegraph.get("shape", &""))
	var delivery := StringName(telegraph.get("delivery", &""))
	var startup := phase in [&"startup", &"boss_startup"]
	if startup and shape == &"area":
		return MODE_AREA_FOOTPRINT
	if startup and shape == &"corridor":
		match delivery:
			&"projectile":
				return MODE_NONE
			&"charge":
				return MODE_CHARGE_FOOTPRINT
			&"beam":
				return MODE_BEAM_WARNING
	if (
		phase in [&"active", &"boss_active"]
		and shape == &"corridor"
		and delivery == &"beam"
		and float(telegraph.get("active_width", 0.0)) > 0.0
	):
		return MODE_ACTIVE_BEAM
	if phase == &"boss_active" and shape == &"area":
		return MODE_AREA_FOOTPRINT
	return MODE_NONE


static func unseen_projectile_attack_readiness(
	source_position: Vector2,
	source_radius: float,
	phase: StringName,
	telegraphs: Array[Dictionary],
	visible_world: Rect2
) -> float:
	if (
		phase not in [&"startup", &"boss_startup"]
		or source_is_visible(source_position, source_radius, visible_world)
	):
		return -1.0
	var result := -1.0
	for telegraph in telegraphs:
		if (
			_is_damaging(telegraph)
			and StringName(telegraph.get("delivery", &"")) == &"projectile"
		):
			result = maxf(
				result,
				clampf(float(telegraph.get("readiness", 0.0)), 0.0, 1.0)
			)
	return result


static func telegraph_intersects_view(
	telegraph: Dictionary,
	visible_world: Rect2
) -> bool:
	var shape := StringName(telegraph.get("shape", &""))
	if shape == &"corridor":
		return _segment_intersects_rect(
			Vector2(telegraph.get("from", Vector2.ZERO)),
			Vector2(telegraph.get("to", Vector2.ZERO)),
			visible_world.grow(
				maxf(0.0, float(telegraph.get("half_width", 0.0)))
			)
		)
	if shape == &"area":
		return visible_world.grow(
			maxf(0.0, float(telegraph.get("radius", 0.0)))
		).has_point(Vector2(telegraph.get("center", Vector2.ZERO)))
	return false


static func source_is_visible(
	position: Vector2,
	radius: float,
	visible_world: Rect2
) -> bool:
	return visible_world.grow(maxf(0.0, radius)).has_point(position)


static func _is_damaging(telegraph: Dictionary) -> bool:
	return (
		float(telegraph.get("damage", 0.0)) > 0.0
		and StringName(telegraph.get("delivery", &"")) != &"support"
	)


static func _segment_intersects_rect(
	from: Vector2,
	to: Vector2,
	rect: Rect2
) -> bool:
	if rect.has_point(from) or rect.has_point(to):
		return true
	var top_left := rect.position
	var top_right := Vector2(rect.end.x, rect.position.y)
	var bottom_right := rect.end
	var bottom_left := Vector2(rect.position.x, rect.end.y)
	return (
		Geometry2D.segment_intersects_segment(from, to, top_left, top_right) != null
		or Geometry2D.segment_intersects_segment(
			from, to, top_right, bottom_right
		) != null
		or Geometry2D.segment_intersects_segment(
			from, to, bottom_right, bottom_left
		) != null
		or Geometry2D.segment_intersects_segment(
			from, to, bottom_left, top_left
		) != null
	)
