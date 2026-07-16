extends SceneTree

const CanvasScript := preload("res://tools/FixedStageBlueprintCanvas.gd")
const OUTPUT_DIR := "res://docs/design/visuals"
const OUTPUT_SIZE := Vector2i(1840, 1120)

const BLUEPRINTS: Array[Dictionary] = [
	{
		"id": "ruin-approach",
		"title": "RUIN APPROACH · BROKEN ASCENT",
		"thesis": "Climb, read exposure, descend through the broken gallery, then rebuild height toward the gate.",
		"terminal_policy": "terminal_encounter",
		"target_time": "6–8 minutes · 8 required rooms + 1 optional",
		"landmarks": ["Broken arch", "Shooter watchtower", "Gate beacon"],
		"contract": [
			"Optional cache rejoins Broken Bridge, not its origin.",
			"Two meaningful descents interrupt the opening ascent.",
			"Exit Ascent owns the only terminal combat lock.",
			"All required transitions leave baseline input margin.",
		],
		"minimap": [
			"All room envelopes start dark.",
			"Exit is visible from stage start.",
			"Cache marker appears only after room discovery.",
			"Current room and player use shape + accent.",
		],
		"rooms": [
			{"id": "lr_start_shelf", "role": &"start", "rhythm": "preview", "grid": Vector2(0.0, 3.2), "route_index": 0, "required": true, "beats": ["preview", "move"]},
			{"id": "lr_rise_steps", "role": &"traversal", "rhythm": "teach", "grid": Vector2(1.0, 2.3), "route_index": 1, "required": true, "beats": ["approach", "climb", "recover"]},
			{"id": "lr_patrol_gallery", "role": &"combat", "rhythm": "transform", "grid": Vector2(2.0, 1.3), "route_index": 2, "required": true, "beats": ["observe", "transfer", "punish"]},
			{"id": "lr_shooter_overlook", "role": &"combat", "rhythm": "peak", "grid": Vector2(3.0, 0.4), "route_index": 3, "required": true, "beats": ["cover", "expose", "flank"]},
			{"id": "lr_lower_upper_choice", "role": &"choice", "rhythm": "decision", "grid": Vector2(4.0, 1.3), "route_index": 4, "required": true, "beats": ["preview", "choose", "commit"]},
			{"id": "lr_destructible_cache", "role": &"optional", "rhythm": "optional", "grid": Vector2(4.4, 3.4), "route_index": -1, "required": false, "beats": ["drop", "break", "reward"]},
			{"id": "lr_broken_bridge", "role": &"traversal", "rhythm": "release", "grid": Vector2(5.2, 2.5), "route_index": 5, "required": true, "beats": ["vista", "descend", "recover"]},
			{"id": "lr_charge_lane", "role": &"combat", "rhythm": "combine", "grid": Vector2(6.2, 1.5), "route_index": 6, "required": true, "beats": ["read", "evade", "reengage"]},
			{"id": "lr_exit_ascent", "role": &"exit", "rhythm": "test", "grid": Vector2(7.2, 0.5), "route_index": 7, "required": true, "beats": ["climb", "priority", "exit"]},
		],
		"connections": [
			{"from": "lr_start_shelf", "to": "lr_rise_steps", "role": &"critical"},
			{"from": "lr_rise_steps", "to": "lr_patrol_gallery", "role": &"critical"},
			{"from": "lr_patrol_gallery", "to": "lr_shooter_overlook", "role": &"critical"},
			{"from": "lr_shooter_overlook", "to": "lr_lower_upper_choice", "role": &"critical"},
			{"from": "lr_lower_upper_choice", "to": "lr_broken_bridge", "role": &"critical"},
			{"from": "lr_broken_bridge", "to": "lr_charge_lane", "role": &"critical"},
			{"from": "lr_charge_lane", "to": "lr_exit_ascent", "role": &"critical"},
			{"from": "lr_lower_upper_choice", "to": "lr_destructible_cache", "role": &"optional"},
			{"from": "lr_destructible_cache", "to": "lr_broken_bridge", "role": &"return"},
		],
	},
	{
		"id": "flooded-works",
		"title": "FLOODED WORKS · DESCEND AND PUMP UP",
		"thesis": "Commit into the flooded basin, survive timing pressure, then climb the pump spine to shelter.",
		"terminal_policy": "arrival",
		"target_time": "7–9 minutes · 7 required rooms + 1 optional",
		"landmarks": ["Flooded intake", "Pump spine", "Shelter lamp"],
		"contract": [
			"Rope descent and ascent use the same input language.",
			"Sunken Cache rejoins Pump Gallery forward.",
			"Pump cover blocks basic projectiles.",
			"Shelter arrival never checks a global enemy count.",
		],
		"minimap": [
			"Basin depth and pump ascent keep true relative height.",
			"Active checkpoint replaces the previous marker.",
			"Cache markers stay hidden until discovery.",
			"Shelter exit is always visible and ready.",
		],
		"rooms": [
			{"id": "fw_flooded_entry", "role": &"start", "rhythm": "preview", "grid": Vector2(0.0, 0.4), "route_index": 0, "required": true, "beats": ["preview", "commit"]},
			{"id": "fw_rope_shaft", "role": &"combat", "rhythm": "teach", "grid": Vector2(1.1, 1.2), "route_index": 1, "required": true, "beats": ["mount", "descend", "transfer"]},
			{"id": "fw_poison_timing", "role": &"hazard", "rhythm": "transform", "grid": Vector2(2.2, 2.1), "route_index": 2, "required": true, "beats": ["wait", "cross", "recover"]},
			{"id": "fw_leaper_basin", "role": &"combat", "rhythm": "peak", "grid": Vector2(3.3, 3.2), "route_index": 3, "required": true, "beats": ["preview", "drop", "escape"]},
			{"id": "fw_lower_upper_choice", "role": &"choice", "rhythm": "decision", "grid": Vector2(4.4, 2.4), "route_index": 4, "required": true, "beats": ["read", "choose", "commit"]},
			{"id": "fw_sunken_cache", "role": &"optional", "rhythm": "optional", "grid": Vector2(4.7, 4.1), "route_index": -1, "required": false, "beats": ["manage", "reward", "climb"]},
			{"id": "fw_pump_gallery", "role": &"combat", "rhythm": "combine", "grid": Vector2(5.6, 1.3), "route_index": 5, "required": true, "beats": ["cover", "climb", "pressure", "recover"]},
			{"id": "fw_exit_shelter", "role": &"safe", "rhythm": "release", "grid": Vector2(7.0, 0.4), "route_index": 6, "required": true, "beats": ["vista", "exit"]},
		],
		"connections": [
			{"from": "fw_flooded_entry", "to": "fw_rope_shaft", "role": &"critical"},
			{"from": "fw_rope_shaft", "to": "fw_poison_timing", "role": &"critical"},
			{"from": "fw_poison_timing", "to": "fw_leaper_basin", "role": &"critical"},
			{"from": "fw_leaper_basin", "to": "fw_lower_upper_choice", "role": &"critical"},
			{"from": "fw_lower_upper_choice", "to": "fw_pump_gallery", "role": &"critical"},
			{"from": "fw_pump_gallery", "to": "fw_exit_shelter", "role": &"critical"},
			{"from": "fw_lower_upper_choice", "to": "fw_sunken_cache", "role": &"optional"},
			{"from": "fw_sunken_cache", "to": "fw_pump_gallery", "role": &"return"},
		],
	},
	{
		"id": "broken-sanctum",
		"title": "BROKEN SANCTUM · INTERLOCKED NAVE",
		"thesis": "Open the seal, revisit the nave at new heights, and distribute two optional loops around the final crossfire.",
		"terminal_policy": "terminal_encounter",
		"target_time": "8–10 minutes · 9 required rooms + 2 optional",
		"landmarks": ["Seal gate", "Fractured rose window", "Reliquary crown"],
		"contract": [
			"Material Crypt branches at the gate and rejoins the nave.",
			"Reliquary Cache branches at recovery and rejoins crossfire.",
			"Gate state opens a visible intra-room shortcut.",
			"Exit Ascent owns the only terminal combat lock.",
		],
		"minimap": [
			"Gate and shortcut use closed/open shapes.",
			"Only active checkpoint remains prominent.",
			"Optional rewards reveal on room discovery.",
			"Exit lock follows the terminal encounter only.",
		],
		"rooms": [
			{"id": "bs_breach_entry", "role": &"start", "rhythm": "preview", "grid": Vector2(0.0, 3.2), "route_index": 0, "required": true, "beats": ["preview", "enter"]},
			{"id": "bs_shield_choke", "role": &"combat", "rhythm": "teach", "grid": Vector2(1.0, 2.3), "route_index": 1, "required": true, "beats": ["read", "flank", "punish"]},
			{"id": "bs_gate_switch_loop", "role": &"objective", "rhythm": "transform", "grid": Vector2(2.0, 1.3), "route_index": 2, "required": true, "beats": ["gate", "switch", "shortcut"]},
			{"id": "bs_material_crypt", "role": &"optional", "rhythm": "optional", "grid": Vector2(2.4, 4.1), "route_index": -1, "required": false, "beats": ["drop", "reward", "return"]},
			{"id": "bs_volatile_nave", "role": &"hazard", "rhythm": "peak", "grid": Vector2(3.2, 2.6), "route_index": 3, "required": true, "beats": ["preview", "time", "recover"]},
			{"id": "bs_twin_reliquary_choice", "role": &"choice", "rhythm": "transfer", "grid": Vector2(4.2, 1.6), "route_index": 4, "required": true, "beats": ["climb", "transfer"]},
			{"id": "bs_fractured_gallery", "role": &"combat", "rhythm": "combine", "grid": Vector2(5.2, 2.5), "route_index": 5, "required": true, "beats": ["priority", "transfer", "escape"]},
			{"id": "bs_recovery_cloister", "role": &"safe", "rhythm": "release", "grid": Vector2(6.2, 3.5), "route_index": 6, "required": true, "beats": ["recover", "clue"]},
			{"id": "bs_reliquary_cache", "role": &"optional", "rhythm": "optional", "grid": Vector2(6.5, 0.2), "route_index": -1, "required": false, "beats": ["mastery", "reward", "return"]},
			{"id": "bs_sentry_crossfire", "role": &"combat", "rhythm": "test", "grid": Vector2(7.3, 1.5), "route_index": 7, "required": true, "beats": ["cover", "transfer", "flank"]},
			{"id": "bs_exit_ascent", "role": &"exit", "rhythm": "final", "grid": Vector2(8.2, 0.4), "route_index": 8, "required": true, "beats": ["combine", "priority", "exit"]},
		],
		"connections": [
			{"from": "bs_breach_entry", "to": "bs_shield_choke", "role": &"critical"},
			{"from": "bs_shield_choke", "to": "bs_gate_switch_loop", "role": &"critical"},
			{"from": "bs_gate_switch_loop", "to": "bs_volatile_nave", "role": &"critical"},
			{"from": "bs_volatile_nave", "to": "bs_twin_reliquary_choice", "role": &"critical"},
			{"from": "bs_twin_reliquary_choice", "to": "bs_fractured_gallery", "role": &"critical"},
			{"from": "bs_fractured_gallery", "to": "bs_recovery_cloister", "role": &"critical"},
			{"from": "bs_recovery_cloister", "to": "bs_sentry_crossfire", "role": &"critical"},
			{"from": "bs_sentry_crossfire", "to": "bs_exit_ascent", "role": &"critical"},
			{"from": "bs_gate_switch_loop", "to": "bs_material_crypt", "role": &"optional"},
			{"from": "bs_material_crypt", "to": "bs_volatile_nave", "role": &"return"},
			{"from": "bs_recovery_cloister", "to": "bs_reliquary_cache", "role": &"optional"},
			{"from": "bs_reliquary_cache", "to": "bs_sentry_crossfire", "role": &"return"},
		],
	},
]

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for blueprint in BLUEPRINTS:
		if not _validate_blueprint(blueprint):
			continue
		await _render_blueprint(blueprint)
	if not _failed:
		print("FIXED_STAGE_BLUEPRINTS_OK count=%d" % BLUEPRINTS.size())
	quit(1 if _failed else 0)


func _render_blueprint(blueprint: Dictionary) -> void:
	var viewport := SubViewport.new()
	viewport.size = OUTPUT_SIZE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var canvas := CanvasScript.new() as Control
	canvas.size = Vector2(OUTPUT_SIZE)
	viewport.add_child(canvas)
	canvas.call("configure", blueprint)
	for _frame in 8:
		await process_frame
	for _pass in 3:
		RenderingServer.force_draw(false)
		await process_frame
	var image := viewport.get_texture().get_image()
	var output_path := "%s/stage-map-blueprint-%s.png" % [OUTPUT_DIR, blueprint["id"]]
	if image == null or image.save_png(output_path) != OK:
		push_error("Unable to save blueprint %s." % output_path)
		_failed = true
	else:
		print("FIXED_STAGE_BLUEPRINT_SAVED %s" % output_path)
	viewport.queue_free()
	await process_frame


func _validate_blueprint(blueprint: Dictionary) -> bool:
	var room_ids := {}
	for room_value in blueprint.get("rooms", []):
		var room := room_value as Dictionary
		var room_id := String(room.get("id", ""))
		if room_id.is_empty() or room_ids.has(room_id):
			push_error("Blueprint '%s' has invalid or repeated room '%s'." % [blueprint["id"], room_id])
			_failed = true
			return false
		room_ids[room_id] = true
	for connection_value in blueprint.get("connections", []):
		var connection := connection_value as Dictionary
		if (
			not room_ids.has(String(connection.get("from", "")))
			or not room_ids.has(String(connection.get("to", "")))
		):
			push_error("Blueprint '%s' has a connection with a missing endpoint." % blueprint["id"])
			_failed = true
			return false
	return true
