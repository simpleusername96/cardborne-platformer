extends Node

## Generates production sheets from the runtime token/catalog providers.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Registry = preload(
	"res://scripts/presentation/components/vehicle_visual_system_registry.gd"
)
const SheetCanvas = preload("res://tools/design/vehicle_visual_sheet_canvas.gd")
const ManifestWriter = preload(
	"res://tools/design/vehicle_visual_sheet_manifest_writer.gd"
)

const DEFAULT_OUTPUT := "res://docs/design/component-sheets/system-v1"
const SHEET_SIZE := Vector2i(2048, 1152)


func _ready() -> void:
	call_deferred("_generate")


func _generate() -> void:
	var errors := Art.validate_contract()
	errors.append_array(Registry.validate_catalog_contract())
	if not errors.is_empty():
		for message in errors:
			push_error(message)
		get_tree().quit(1)
		return
	var output_path := _output_path()
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output)
	if directory_error != OK:
		push_error("Could not create sheet output directory: %s" % absolute_output)
		get_tree().quit(1)
		return
	var records: Array[Dictionary] = []
	for record in [
		{"id": &"01-foundation-tokens", "canvas": &"foundation"},
		{"id": &"02-world-surfaces", "canvas": &"world_surfaces"},
		{"id": &"03-world-facilities", "canvas": &"world_facilities"},
		{"id": &"04-player-components", "canvas": &"player"},
		{"id": &"05-enemy-components", "canvas": &"enemies"},
		{"id": &"06-boss-components", "canvas": &"bosses"},
		{
			"id": &"07-projectile-telegraph-vfx",
			"canvas": &"projectiles",
		},
		{"id": &"08-reward-upgrade-glyphs", "canvas": &"rewards"},
		{"id": &"09-hud-minimap-markers", "canvas": &"hud"},
		{"id": &"10-ui-controls-states", "canvas": &"controls"},
		{"id": &"11-modal-flow-contact-sheet", "canvas": &"modals"},
		{"id": &"12-pressure-accessibility", "canvas": &"pressure"},
	]:
		var result := await _capture_sheet(
			output_path,
			StringName(record["id"]),
			StringName(record["canvas"])
		)
		if result.is_empty():
			get_tree().quit(1)
			return
		records.append(result)
	var manifest_error := ManifestWriter.write(
		absolute_output,
		records,
		Art.provider_fingerprint(),
		Registry.provider_fingerprint(),
		_source_commit()
	)
	if manifest_error != OK:
		push_error("Could not write visual sheet manifest: %s" % manifest_error)
		get_tree().quit(1)
		return
	print(
		"Generated %d visual-system sheets at %s (token=%s catalog=%s)"
		% [
			records.size(),
			output_path,
			Art.provider_fingerprint(),
			Registry.provider_fingerprint(),
		]
	)
	get_tree().quit(0)


func _capture_sheet(
	output_path: String,
	sheet_name: StringName,
	canvas_id: StringName
) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = SHEET_SIZE
	viewport.disable_3d = true
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var canvas := SheetCanvas.new()
	canvas.sheet_id = canvas_id
	canvas.size = Vector2(SHEET_SIZE)
	viewport.add_child(canvas)
	for unused_frame in 4:
		await get_tree().process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.get_size() != SHEET_SIZE:
		push_error("Visual sheet capture failed: %s" % sheet_name)
		viewport.queue_free()
		return {}
	var file_name := "%s.png" % String(sheet_name)
	var resource_path := output_path.path_join(file_name)
	var absolute_path := ProjectSettings.globalize_path(resource_path)
	var save_error := image.save_png(absolute_path)
	viewport.queue_free()
	if save_error != OK:
		push_error("Could not save visual sheet %s: %s" % [sheet_name, save_error])
		return {}
	return {
		"id": String(sheet_name),
		"path": resource_path.trim_prefix("res://"),
		"sha256": FileAccess.get_sha256(absolute_path),
		"width": SHEET_SIZE.x,
		"height": SHEET_SIZE.y,
		"providers": [
			"VehicleStageVisualProfile",
			"VehicleVisualSystemRegistry",
			"NotoSansKR-Variable",
		],
	}


func _output_path() -> String:
	var arguments := OS.get_cmdline_user_args()
	for argument in OS.get_cmdline_args():
		if argument not in arguments:
			arguments.append(argument)
	for argument in arguments:
		if argument.begins_with("--visual-sheet-output="):
			var value := argument.trim_prefix("--visual-sheet-output=")
			if value.begins_with("res://"):
				return value.trim_suffix("/")
	return DEFAULT_OUTPUT


func _source_commit() -> String:
	var output := []
	var exit_code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	if exit_code == 0 and not output.is_empty():
		return String(output[0]).strip_edges()
	return "unavailable"
