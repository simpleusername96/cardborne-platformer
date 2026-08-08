class_name VehicleTerrainDefinition
extends RefCounted

## Typed runtime form of an authored low-count field feature.
##
## Terrain visuals and collision remain owned by their callers.  This record
## only carries the stable authored footprint and the gameplay metadata that
## the terrain runtime needs for transit gates and structural-wall snapshots.

var id: StringName
var kind: StringName
var rect := Rect2()
var pos := Vector2.ZERO
var pair: StringName
var variant: StringName
var affinity: StringName


static func from_blueprint(value: Dictionary) -> VehicleTerrainDefinition:
	var result := VehicleTerrainDefinition.new()
	result.id = StringName(value.get("id", &""))
	result.kind = StringName(value.get("kind", &""))
	result.rect = Rect2(value.get("rect", Rect2()))
	result.pos = Vector2(value.get("pos", Vector2.ZERO))
	result.pair = StringName(value.get("pair", &""))
	result.variant = StringName(value.get("variant", &""))
	result.affinity = StringName(value.get("affinity", &""))
	if result.affinity.is_empty():
		result.affinity = (
			&"toxin" if result.variant == &"toxic_bog"
			else &"thermal" if result.variant == &"lava_pool"
			else &""
		)
	return result


func snapshot() -> Dictionary:
	var result := {"id":id, "kind":kind}
	if rect.has_area():
		result["rect"] = rect
	if pos != Vector2.ZERO:
		result["pos"] = pos
	if not pair.is_empty():
		result["pair"] = pair
	if not variant.is_empty():
		result["variant"] = variant
	if not affinity.is_empty():
		result["affinity"] = affinity
	return result
