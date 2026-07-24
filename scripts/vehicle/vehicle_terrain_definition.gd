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
