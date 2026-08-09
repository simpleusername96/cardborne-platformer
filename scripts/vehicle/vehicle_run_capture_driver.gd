class_name VehicleRunCaptureDriver
extends RefCounted

## Owns capture requests, sequence, exact output contract, and terminal cleanup.

const CORE_CAPTURE_FILES := [
	"01-deployment.png",
	"01b-shared-settings.png",
	"01c-guidebook.png",
	"01d-gameplay-settings.png",
	"01e-guidebook-boss-preview.png",
	"01f-guidebook-locked.png",
	"01g-guidebook-enemy-counterplay.png",
	"01h-boss-practice.png",
	"02-safe-arrival.png",
	"02b-first-contact-cue.png",
	"02c-ship-status-active.png",
	"02d-action-cooldowns.png",
	"03-peak-horde.png",
	"03b-collective-lock.png",
	"03c-collective-break.png",
	"04-stage-4-xp-hud.png",
	"04b-stage-4-xp-collected.png",
	"04c-progression-max.png",
	"04d-ship-status-acquired-build.png",
	"04e-radar-minimap-roles.png",
	"05-two-field-items.png",
	"05b-reinforcement-facility.png",
	"05c-structural-health-bars.png",
	"06-thermal-first-acquisition.png",
	"06b-thermal-first-selected.png",
	"06c-thermal-enhancement.png",
	"06d-two-card-tail.png",
	"07-stage-boss-startup.png",
	"10-field-drowned-ruin-field.png",
	"10-field-storm-drydock-field.png",
	"10-field-tidal-archive-field.png",
	"90-pause.png",
	"91-stage-report.png",
	"92-failure-report.png",
	"93-final-result.png",
	"94-garage.png",
]

const FULL_CAPTURE_FILES := [
	"01-deployment.png",
	"01b-shared-settings.png",
	"01c-guidebook.png",
	"01d-gameplay-settings.png",
	"01e-guidebook-boss-preview.png",
	"01f-guidebook-locked.png",
	"01g-guidebook-enemy-counterplay.png",
	"01h-boss-practice.png",
	"02-safe-arrival.png",
	"02b-first-contact-cue.png",
	"02c-ship-status-active.png",
	"02d-action-cooldowns.png",
	"03-peak-horde.png",
	"03b-collective-lock.png",
	"03c-collective-break.png",
	"03d-movement-cover-approach.png",
	"03e-movement-cover-turn.png",
	"03f-movement-cover-standoff.png",
	"04-stage-4-xp-hud.png",
	"04b-stage-4-xp-collected.png",
	"04c-progression-max.png",
	"04d-ship-status-acquired-build.png",
	"04e-radar-minimap-roles.png",
	"05-two-field-items.png",
	"05b-reinforcement-facility.png",
	"05c-structural-health-bars.png",
	"06-thermal-first-acquisition.png",
	"06b-thermal-first-selected.png",
	"06c-thermal-enhancement.png",
	"06d-two-card-tail.png",
	"07-stage-boss-startup.png",
	"08-player-barrier-only.png",
	"08-player-hit-reduced-motion.png",
	"08-player-hit-standard.png",
	"09-effects-essential-transients.png",
	"09-effects-projectile-hostile-startup.png",
	"09-effects-projectile-hostile-flight.png",
	"09-effects-projectile-hostile-hit.png",
	"09-effects-arc-mine-startup.png",
	"09-effects-beam-sentinel-startup.png",
	"09-effects-beam-sentinel-active.png",
	"09b-element-status-application.png",
	"09c-element-status-persistent.png",
	"09d-element-status-hit-flash.png",
	"09e-element-status-reduced-motion.png",
	"09f-element-status-expired.png",
	"09g-electric-field-level-1.png",
	"09h-electric-field-level-2.png",
	"09i-electric-field-level-3.png",
	"10-field-drowned-ruin-field.png",
	"10-field-storm-drydock-field.png",
	"10-field-tidal-archive-field.png",
	"20-collision-01-stage-1-default.png",
	"20-collision-02-stage-2-default.png",
	"20-collision-03-stage-3-default.png",
	"20-collision-04-stage-4-default.png",
	"20-collision-05-stage-5-default.png",
	"30-boss-01-stage-1-active.png",
	"30-boss-01-stage-1-offscreen-furnace-active.png",
	"30-boss-01-stage-1-offscreen-furnace-imminent.png",
	"30-boss-01-stage-1-offscreen-furnace.png",
	"30-boss-01-stage-1-phase-two.png",
	"30-boss-01-stage-1-recovery.png",
	"30-boss-01-stage-1-shield-up-hit.png",
	"30-boss-01-stage-1-shield-restored.png",
	"30-boss-01-stage-1-startup-imminent.png",
	"30-boss-01-stage-1-startup.png",
	"30-boss-01-stage-1-arc-area-startup.png",
	"30-boss-02-stage-2-active.png",
	"30-boss-02-stage-2-phase-two.png",
	"30-boss-02-stage-2-recovery.png",
	"30-boss-02-stage-2-shield-restored.png",
	"30-boss-02-stage-2-startup-imminent.png",
	"30-boss-02-stage-2-startup.png",
	"30-boss-03-stage-3-active.png",
	"30-boss-03-stage-3-phase-two.png",
	"30-boss-03-stage-3-recovery.png",
	"30-boss-03-stage-3-shield-restored.png",
	"30-boss-03-stage-3-startup-imminent.png",
	"30-boss-03-stage-3-startup.png",
	"30-boss-04-stage-4-active.png",
	"30-boss-04-stage-4-phase-two.png",
	"30-boss-04-stage-4-recovery.png",
	"30-boss-04-stage-4-shield-restored.png",
	"30-boss-04-stage-4-startup-imminent.png",
	"30-boss-04-stage-4-startup.png",
	"30-boss-05-stage-5-active.png",
	"30-boss-05-stage-5-phase-two.png",
	"30-boss-05-stage-5-recovery.png",
	"30-boss-05-stage-5-shield-restored.png",
	"30-boss-05-stage-5-startup-imminent.png",
	"30-boss-05-stage-5-startup.png",
	"30-boss-05-stage-5-crown-beam-startup.png",
	"30-boss-05-stage-5-crown-beam-active.png",
	"90-pause.png",
	"91-stage-report.png",
	"92-failure-report.png",
	"93-final-result.png",
	"94-garage.png",
]

var directory := ""
var locale := ""
var viewport_size := Vector2i.ZERO
var text_scale := 1.0
var layout_seed_override: Variant = null
var field_id_override := &""
var failed := false

var _original_locale := ""
var _saved_counts: Dictionary = {}
var _finished := false


static func is_requested_from_command_line() -> bool:
	for argument in _command_line_arguments():
		if argument.begins_with("--capture-all="):
			return true
	return false


static func from_command_line() -> VehicleRunCaptureDriver:
	var driver := VehicleRunCaptureDriver.new()
	driver._original_locale = TranslationServer.get_locale()
	for argument in _command_line_arguments():
		if argument.begins_with("--capture-all="):
			driver.directory = argument.trim_prefix("--capture-all=")
		elif argument.begins_with("--capture-locale="):
			driver.locale = argument.trim_prefix("--capture-locale=")
		elif argument.begins_with("--capture-size="):
			var parts := argument.trim_prefix("--capture-size=").split("x")
			if parts.size() == 2:
				driver.viewport_size = Vector2i(
					maxi(640, int(parts[0])), maxi(360, int(parts[1]))
				)
		elif argument.begins_with("--capture-text-scale="):
			driver.text_scale = clampf(
				float(argument.trim_prefix("--capture-text-scale=")), 1.0, 2.0
			)
		elif argument.begins_with("--layout-seed="):
			driver.layout_seed_override = int(argument.trim_prefix("--layout-seed="))
		elif argument.begins_with("--field-id="):
			driver.field_id_override = StringName(argument.trim_prefix("--field-id="))
	return driver


static func _command_line_arguments() -> PackedStringArray:
	var arguments := OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	return arguments


func is_requested() -> bool:
	return not directory.is_empty()


func apply_locale() -> void:
	if locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)


func run(gateway: RefCounted) -> void:
	if not prepare_output():
		finish_capture(gateway, 1)
		return
	gateway.set_world_fixture({
		"kind":&"capture_environment",
		"viewport_size":viewport_size,
		"text_scale":text_scale,
	})
	if not await _capture_ui(gateway, &"deployment", "01-deployment.png", 0.0, 2):
		return
	if not await _capture_ui(gateway, &"settings", "01b-shared-settings.png"):
		return
	if not await _capture_ui(gateway, &"gameplay_settings", "01d-gameplay-settings.png"):
		return
	if not await _capture_ui(gateway, &"guidebook", "01c-guidebook.png"):
		return
	if not await _capture_ui(gateway, &"guidebook_boss", "01e-guidebook-boss-preview.png"):
		return
	if not await _capture_ui(gateway, &"guidebook_locked", "01f-guidebook-locked.png"):
		return
	if not await _capture_ui(gateway, &"guidebook_counterplay", "01g-guidebook-enemy-counterplay.png"):
		return
	if not await _capture_ui(gateway, &"boss_practice", "01h-boss-practice.png"):
		return

	gateway.prepare_stage(0)
	if not await _capture_viewport(gateway, "02-safe-arrival.png"):
		return
	gateway.set_player_fixture({"kind":&"cooldowns"})
	if not await _capture_viewport(gateway, "02d-action-cooldowns.png"):
		return
	gateway.set_player_fixture({"kind":&"cooldowns_clear"})
	if not await _capture_ui(gateway, &"ship_status_active", "02c-ship-status-active.png"):
		return
	if not await _capture_ui(gateway, &"first_contact", "02b-first-contact-cue.png"):
		return

	for fixture_kind in [
		&"pressure",
		&"collective_tactic",
		&"build_state",
		&"radar_minimap_roles",
		&"field_items",
		&"reinforcement_facility",
		&"structural_health_bars",
		&"level_up",
		&"boss_preview",
		&"stage_maps",
	]:
		if not await _run_world_fixture(gateway, fixture_kind):
			return
	if is_full_evidence(gateway.snapshot(&"viewport")):
		for fixture_kind in [
			&"movement_policy",
			&"visual_events",
			&"ordinary_projectile",
			&"arc_area_telegraphs",
			&"beam_sentinel",
			&"damage_feedback",
			&"elemental_status_feedback",
			&"electric_field_feedback",
			&"collision_overlays",
			&"all_bosses",
		]:
			if not await _run_world_fixture(gateway, fixture_kind):
				return

	gateway.prepare_stage(0, true)
	if not await _capture_ui(gateway, &"pause", "90-pause.png"):
		return
	if not await _capture_ui(gateway, &"stage_report", "91-stage-report.png", 0.36):
		return
	if not await _capture_ui(gateway, &"failure_report", "92-failure-report.png", 0.36):
		return
	if not await _capture_ui(gateway, &"result", "93-final-result.png"):
		return
	if not await _capture_ui(gateway, &"garage", "94-garage.png"):
		return
	finish_capture(gateway, 0)


func prepare_output() -> bool:
	if not is_requested():
		failed = true
		return false
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK or not DirAccess.dir_exists_absolute(directory):
		failed = true
		push_error("Capture directory creation failed: %s (%d)" % [directory, error])
		return false
	return true


func is_full_evidence(viewport: Viewport) -> bool:
	var width := viewport_size.x
	if width <= 0:
		width = roundi(viewport.get_visible_rect().size.x)
	return locale == "ko" and width == 1280


func save_viewport(viewport: Viewport, file_name: String) -> bool:
	var path := directory.path_join(file_name)
	RenderingServer.force_draw(true)
	var image := viewport.get_texture().get_image()
	if image == null:
		failed = true
		push_error("Could not read capture viewport for %s" % path)
		return false
	var error := image.save_png(path)
	if error != OK:
		failed = true
		push_error("Could not save capture %s: %s" % [path, error_string(error)])
		return false
	_saved_counts[file_name] = int(_saved_counts.get(file_name, 0)) + 1
	print("CAPTURE_SAVED %s" % path)
	return true


func finish_capture(gateway: RefCounted, exit_code: int) -> void:
	if _finished:
		return
	if exit_code == 0 and not failed and not _validate_manifest(gateway):
		exit_code = 1
	if exit_code == 0 and not failed and not _write_manifest(gateway):
		exit_code = 1
	TranslationServer.set_locale(_original_locale)
	gateway.restore_baseline()
	_finished = true
	if exit_code == 0:
		print("VEHICLE_STAGE_CAPTURE_COMPLETE dir=%s" % directory)
	var tree := gateway.snapshot(&"tree") as SceneTree
	if tree != null:
		tree.quit(exit_code)


func restore_on_exit(gateway: RefCounted) -> void:
	if _finished:
		return
	TranslationServer.set_locale(_original_locale)
	gateway.restore_baseline()
	_finished = true


func _capture_ui(
	gateway: RefCounted,
	fixture_kind: StringName,
	file_name: String,
	delay_seconds: float = 0.0,
	settle_frames: int = 4
) -> bool:
	gateway.show_ui_fixture({"kind":fixture_kind})
	if delay_seconds > 0.0:
		var tree := gateway.snapshot(&"tree") as SceneTree
		await tree.create_timer(delay_seconds).timeout
	return await _capture_viewport(gateway, file_name, settle_frames)


func _capture_viewport(
	gateway: RefCounted,
	file_name: String,
	settle_frames: int = 4
) -> bool:
	for frame in settle_frames:
		await (gateway.snapshot(&"tree") as SceneTree).process_frame
	gateway.refresh_capture_text_scale()
	for frame in 2:
		await (gateway.snapshot(&"tree") as SceneTree).process_frame
	var viewport := gateway.snapshot(&"viewport") as Viewport
	var logical_size := Vector2i(viewport.get_visible_rect().size)
	if viewport_size != Vector2i.ZERO and logical_size != viewport_size:
		failed = true
		push_error(
			"Capture logical viewport mismatch: requested=%s actual=%s"
			% [viewport_size, logical_size]
		)
		finish_capture(gateway, 1)
		return false
	if not save_viewport(viewport, file_name):
		finish_capture(gateway, 1)
		return false
	return true


func _run_world_fixture(
	gateway: RefCounted,
	fixture_kind: StringName
) -> bool:
	await gateway.set_world_fixture({"kind":fixture_kind})
	if failed:
		finish_capture(gateway, 1)
		return false
	return true


func _validate_manifest(gateway: RefCounted) -> bool:
	var expected: Array = (
		FULL_CAPTURE_FILES
		if is_full_evidence(gateway.snapshot(&"viewport"))
		else CORE_CAPTURE_FILES
	)
	var expected_set := {}
	for file_name_variant in expected:
		var file_name := String(file_name_variant)
		expected_set[file_name] = true
		if int(_saved_counts.get(file_name, 0)) != 1:
			push_error("Capture manifest count mismatch: %s" % file_name)
			failed = true
		var path := directory.path_join(file_name)
		if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path).is_empty():
			push_error("Capture manifest file missing or empty: %s" % path)
			failed = true
	var actual_set := {}
	for file_name in DirAccess.get_files_at(directory):
		if String(file_name).get_extension().to_lower() == "png":
			actual_set[String(file_name)] = true
	if actual_set != expected_set:
		push_error("Capture manifest filename set mismatch")
		failed = true
	return not failed


func _write_manifest(gateway: RefCounted) -> bool:
	var full_evidence := is_full_evidence(gateway.snapshot(&"viewport"))
	var files: Array = FULL_CAPTURE_FILES if full_evidence else CORE_CAPTURE_FILES
	var manifest := {
		"schema_version":1,
		"locale":locale,
		"viewport_size":[viewport_size.x, viewport_size.y],
		"text_scale":text_scale,
		"evidence_mode":"full" if full_evidence else "core",
		"files":files.duplicate(),
	}
	var path := directory.path_join("capture-manifest.json")
	var output := FileAccess.open(path, FileAccess.WRITE)
	if output == null:
		failed = true
		push_error("Could not write capture manifest: %s" % path)
		return false
	output.store_string(JSON.stringify(manifest, "\t", true) + "\n")
	output.close()
	if not FileAccess.file_exists(path) or FileAccess.get_file_as_bytes(path).is_empty():
		failed = true
		push_error("Capture manifest is missing or empty after write: %s" % path)
		return false
	print("CAPTURE_MANIFEST_SAVED %s" % path)
	return true
