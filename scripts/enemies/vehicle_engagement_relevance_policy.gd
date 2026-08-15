class_name VehicleEngagementRelevancePolicy
extends RefCounted

## Releases one-shot arrival gates that stop helping an enemy pressure the
## player. This policy owns only scalar evidence; route selection stays with
## the movement and pursuit owners.

const DIVERGENCE_SECONDS := 0.80
const DIRECTION_DOT_LIMIT := -0.20
const ROUTE_EXCESS_LIMIT := 300.0
const DISTANCE_GROWTH_EPSILON := 1.0


static func sample(
	enemy_position: Vector2,
	player_position: Vector2,
	gate_position: Vector2,
	previous_player_distance: float,
	divergence_started_at: float,
	now: float,
	engagement_started_at: float = 0.0
) -> Dictionary:
	var player_offset := player_position - enemy_position
	var gate_offset := gate_position - enemy_position
	var player_distance := player_offset.length()
	var gate_distance := gate_offset.length()
	var direction_dot := 1.0
	if player_distance > 0.001 and gate_distance > 0.001:
		direction_dot = gate_offset.normalized().dot(player_offset.normalized())
	var route_excess := gate_distance - player_distance
	var gate_age := maxf(0.0, now - engagement_started_at)
	if gate_age >= DIVERGENCE_SECONDS and route_excess > ROUTE_EXCESS_LIMIT:
		return {
			"release":true,
			"reason":&"route_excess",
			"player_distance":player_distance,
			"divergence_started_at":-1.0,
		}
	var diverging := (
		previous_player_distance >= 0.0
		and player_distance > previous_player_distance + DISTANCE_GROWTH_EPSILON
		and direction_dot < DIRECTION_DOT_LIMIT
	)
	var next_started_at := divergence_started_at
	if diverging:
		if next_started_at < 0.0:
			next_started_at = now
	elif direction_dot >= DIRECTION_DOT_LIMIT or player_distance < previous_player_distance:
		next_started_at = -1.0
	var stale := next_started_at >= 0.0 and now - next_started_at >= DIVERGENCE_SECONDS
	return {
		"release":stale,
		"reason":&"diverging" if stale else &"none",
		"player_distance":player_distance,
		"divergence_started_at":next_started_at,
	}
