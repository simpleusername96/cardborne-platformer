class_name GameplayFeedbackRequest
extends RefCounted

# Copyable value contract accepted by FeedbackDirector and SignalBus.
const UNSET_FLOAT := -1.0
const BURST_DEFAULT := -1
const BURST_DISABLED := 0
const BURST_ENABLED := 1

var cue_id: StringName = &""
var strength := 1.0
var has_world_position := false
var world_position := Vector2.ZERO
var shake_strength := UNSET_FLOAT
var shake_duration := UNSET_FLOAT
var pause_duration := UNSET_FLOAT
var burst_mode := BURST_DEFAULT
var burst_radius := UNSET_FLOAT
var burst_color := Color.TRANSPARENT
var context: Dictionary = {}

var _conversion_errors := PackedStringArray()


static func from_value(value: Variant) -> GameplayFeedbackRequest:
	if value is GameplayFeedbackRequest:
		return (value as GameplayFeedbackRequest).duplicate_request()
	if value is Dictionary:
		return _from_dictionary(value as Dictionary)
	return null


static func _from_dictionary(value: Dictionary) -> GameplayFeedbackRequest:
	var request := GameplayFeedbackRequest.new()
	var raw_cue: Variant = value.get("cue_id", &"")
	if raw_cue is String or raw_cue is StringName:
		request.cue_id = StringName(raw_cue)
	else:
		request._conversion_errors.append("cue_id must be a string or StringName")

	request.strength = request._read_number(value, "strength", 1.0)
	request.shake_strength = request._read_number(
		value, "shake_strength", UNSET_FLOAT
	)
	request.shake_duration = request._read_number(
		value, "shake_duration", UNSET_FLOAT
	)
	request.pause_duration = request._read_number(
		value, "pause_duration", UNSET_FLOAT
	)
	request.burst_radius = request._read_number(
		value, "burst_radius", UNSET_FLOAT
	)

	if value.has("world_position"):
		if value["world_position"] is Vector2:
			request.has_world_position = true
			request.world_position = value["world_position"]
		else:
			request._conversion_errors.append("world_position must be a Vector2")
	if value.has("burst"):
		if value["burst"] is bool:
			request.burst_mode = BURST_ENABLED if value["burst"] else BURST_DISABLED
		else:
			request._conversion_errors.append("burst must be a bool")
	if value.has("burst_color"):
		if value["burst_color"] is Color:
			request.burst_color = value["burst_color"]
		else:
			request._conversion_errors.append("burst_color must be a Color")
	if value.has("context"):
		if value["context"] is Dictionary:
			request.context = (value["context"] as Dictionary).duplicate(true)
		else:
			request._conversion_errors.append("context must be a Dictionary")
	return request


func duplicate_request() -> GameplayFeedbackRequest:
	var copy := GameplayFeedbackRequest.new()
	copy.cue_id = cue_id
	copy.strength = strength
	copy.has_world_position = has_world_position
	copy.world_position = world_position
	copy.shake_strength = shake_strength
	copy.shake_duration = shake_duration
	copy.pause_duration = pause_duration
	copy.burst_mode = burst_mode
	copy.burst_radius = burst_radius
	copy.burst_color = burst_color
	copy.context = context.duplicate(true)
	copy._conversion_errors = _conversion_errors.duplicate()
	return copy


func validate() -> PackedStringArray:
	var errors := _conversion_errors.duplicate()
	if cue_id == &"":
		errors.append("cue_id is required")
	if not is_finite(strength) or strength < 0.0:
		errors.append("strength must be a finite non-negative number")
	_validate_optional_non_negative("shake_strength", shake_strength, errors)
	_validate_optional_non_negative("shake_duration", shake_duration, errors)
	_validate_optional_non_negative("pause_duration", pause_duration, errors)
	_validate_optional_non_negative("burst_radius", burst_radius, errors)
	if burst_mode not in [BURST_DEFAULT, BURST_DISABLED, BURST_ENABLED]:
		errors.append("burst mode is invalid")
	return errors


func to_dictionary() -> Dictionary:
	return {
		"cue_id": cue_id,
		"strength": strength,
		"has_world_position": has_world_position,
		"world_position": world_position,
		"shake_strength": shake_strength,
		"shake_duration": shake_duration,
		"pause_duration": pause_duration,
		"burst_mode": burst_mode,
		"burst_radius": burst_radius,
		"burst_color": burst_color,
		"context": context.duplicate(true),
	}


func _read_number(source: Dictionary, key: String, fallback: float) -> float:
	if not source.has(key):
		return fallback
	var value: Variant = source[key]
	if value is int or value is float:
		return float(value)
	_conversion_errors.append("%s must be numeric" % key)
	return fallback


func _validate_optional_non_negative(
	label: String,
	value: float,
	errors: PackedStringArray
) -> void:
	if not is_finite(value) or (value != UNSET_FLOAT and value < 0.0):
		errors.append("%s must be unset or a finite non-negative number" % label)
