class_name NamedRngStreams
extends RefCounted

const DEFAULT_STREAM_NAMES: Array[StringName] = [
	&"room_graph",
	&"room_variant",
	&"encounter",
	&"enemy_variant",
	&"hazard",
	&"reward",
]

var _run_seed: int
var _stage_index: int
var _room_catalog_content_version: int
var _stage_profile_content_version: int
var _generation_attempt: int


func _init(
	run_seed: int = 0,
	stage_index: int = 0,
	room_catalog_content_version: int = 1,
	stage_profile_content_version: int = 1,
	generation_attempt: int = 0
) -> void:
	_run_seed = run_seed
	_stage_index = stage_index
	_room_catalog_content_version = room_catalog_content_version
	_stage_profile_content_version = stage_profile_content_version
	_generation_attempt = generation_attempt


func seed_for(stream_name: StringName) -> int:
	return stable_seed(
		_run_seed,
		_stage_index,
		_room_catalog_content_version,
		_stage_profile_content_version,
		_generation_attempt,
		stream_name
	)


func create_rng(stream_name: StringName) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_for(stream_name)
	return rng


func get_stream_seeds() -> Dictionary:
	var seeds: Dictionary = {}
	for stream_name in DEFAULT_STREAM_NAMES:
		seeds[String(stream_name)] = seed_for(stream_name)
	return seeds


static func stable_seed(
	run_seed: int,
	stage_index: int,
	room_catalog_content_version: int,
	stage_profile_content_version: int,
	generation_attempt: int,
	stream_name: StringName
) -> int:
	var value := run_seed & 0x7fffffff
	var key := "%d:%d:%d:%d:%s" % [
		stage_index,
		room_catalog_content_version,
		stage_profile_content_version,
		generation_attempt,
		stream_name,
	]
	for byte in key.to_utf8_buffer():
		value = int((value * 1664525 + int(byte) + 1013904223) & 0x7fffffff)
	return value
