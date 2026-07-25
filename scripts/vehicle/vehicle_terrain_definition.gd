class_name VehicleTerrainDefinition
extends RefCounted

## Typed runtime form of an authored low-count field feature.

var id: StringName
var kind: StringName
var rect := Rect2()
var pos := Vector2.ZERO
var vector := Vector2.ZERO
var pair: StringName
var time := 0.0


static func support_schedule() -> Array[Dictionary]:
	return [
		{"slot_id":&"repair_a", "kind":&"repair", "radius":150.0, "warning":1.5, "active":18.0, "dormant":10.0, "initial":0.0},
		{"slot_id":&"repair_b", "kind":&"repair", "radius":150.0, "warning":1.5, "active":23.0, "dormant":11.0, "initial":12.0},
		{"slot_id":&"overdrive_a", "kind":&"overdrive", "radius":180.0, "warning":1.5, "active":12.0, "dormant":14.0, "initial":5.0},
		{"slot_id":&"overdrive_b", "kind":&"overdrive", "radius":180.0, "warning":1.5, "active":15.0, "dormant":16.0, "initial":19.0},
	]


static func from_blueprint(value: Dictionary) -> VehicleTerrainDefinition:
	var result := VehicleTerrainDefinition.new()
	result.id = StringName(value.get("id", &""))
	result.kind = StringName(value.get("kind", &""))
	result.rect = Rect2(value.get("rect", Rect2()))
	result.pos = Vector2(value.get("pos", Vector2.ZERO))
	result.vector = Vector2(value.get("vector", Vector2.ZERO))
	result.pair = StringName(value.get("pair", &""))
	return result


func snapshot() -> Dictionary:
	var result := {"id":id, "kind":kind, "time":time}
	if rect.has_area():
		result["rect"] = rect
	if pos != Vector2.ZERO:
		result["pos"] = pos
	if vector != Vector2.ZERO:
		result["vector"] = vector
	if not pair.is_empty():
		result["pair"] = pair
	return result
