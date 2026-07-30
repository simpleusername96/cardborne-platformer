extends SceneTree

## Verifies Phase 1 token authority, migration ownership, and deterministic
## provider-backed sheet publication.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ComponentMeshes = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)
const Registry = preload(
	"res://scripts/presentation/components/vehicle_visual_system_registry.gd"
)

const MANIFEST_PATH := (
	"res://docs/design/component-sheets/system-v1/manifest.json"
)
const ACTIVE_SPEC_PATH := "res://docs/design/UI_VISUAL_SYSTEM.md"
const SHEET_CANVAS_PATH := (
	"res://tools/design/vehicle_visual_sheet_canvas.gd"
)
const EXPECTED_SHEETS := [
	"01-foundation-tokens",
	"02-world-surfaces",
	"03-world-facilities",
	"04-player-components",
	"05-enemy-components",
	"06-boss-components",
	"07-projectile-telegraph-vfx",
	"08-reward-upgrade-glyphs",
	"09-hud-minimap-markers",
	"10-ui-controls-states",
	"11-modal-flow-contact-sheet",
	"12-pressure-accessibility",
]


func _init() -> void:
	var errors := Art.validate_contract()
	errors.append_array(Registry.validate_catalog_contract())
	errors.append_array(ComponentMeshes.validate_component_budget(3, 2, 1, 5))
	_validate_active_spec(errors)
	_validate_runtime_backed_ui_sheets(errors)
	_validate_manifest(errors)
	if errors.is_empty():
		print(
			"Vehicle visual-system foundation validation passed. "
			+ "token=%s catalog=%s"
			% [Art.provider_fingerprint(), Registry.provider_fingerprint()]
		)
		quit(0)
		return
	for message in errors:
		push_error(message)
	quit(1)


func _validate_active_spec(errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(ACTIVE_SPEC_PATH):
		errors.append("active visual spec is missing")
		return
	var content := FileAccess.get_file_as_string(ACTIVE_SPEC_PATH)
	for required in [
		"general SF",
		"VehicleStageVisualProfile",
		"engine mount",
		"directional afterimage",
		"960×540",
		"grayscale",
	]:
		if required not in content:
			errors.append("active visual spec is missing contract text: %s" % required)
	for retired_authority in [
		"Sunken Ceramic",
	]:
		if retired_authority in content:
			errors.append(
				"active visual spec still names retired authority: %s"
				% retired_authority
			)


func _validate_runtime_backed_ui_sheets(errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(SHEET_CANVAS_PATH):
		errors.append("visual sheet canvas is missing")
		return
	var content := FileAccess.get_file_as_string(SHEET_CANVAS_PATH)
	for required in [
		"VehicleGameplayHud",
		"VehicleDeploymentPanel",
		"VehicleSettingsPanel",
		"_build_actual_modals",
	]:
		if required not in content:
			errors.append(
				"UI sheet is missing runtime control evidence: %s" % required
			)
	for retired_mock in [
		"func _draw_modal_thumbnail",
		"func _draw_hud_zone",
		"func _draw_control_state",
	]:
		if retired_mock in content:
			errors.append(
				"UI sheet still owns a sheet-only control mock: %s"
				% retired_mock
			)


func _validate_manifest(errors: PackedStringArray) -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		errors.append("visual sheet manifest is missing")
		return
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(MANIFEST_PATH)
	)
	if not parsed is Dictionary:
		errors.append("visual sheet manifest is invalid")
		return
	var manifest := Dictionary(parsed)
	if int(manifest.get("schema_version", 0)) != 1:
		errors.append("visual sheet manifest schema must be 1")
	if String(manifest.get("publication_status", "")) != "complete-design-set":
		errors.append("visual sheet manifest must publish the complete design set")
	if not Array(manifest.get("planned_sheet_ids", [])).is_empty():
		errors.append("complete design set cannot retain planned sheet ids")
	var fingerprints := Dictionary(manifest.get("provider_fingerprints", {}))
	if String(fingerprints.get("tokens", "")) != Art.provider_fingerprint():
		errors.append("manifest token fingerprint does not match provider")
	if (
		String(fingerprints.get("catalog_registry", ""))
		!= Registry.provider_fingerprint()
	):
		errors.append("manifest catalog fingerprint does not match provider")
	var seen := {}
	for value in Array(manifest.get("sheets", [])):
		var sheet := Dictionary(value)
		var sheet_id := String(sheet.get("id", ""))
		seen[sheet_id] = true
		var resource_path := "res://%s" % String(sheet.get("path", ""))
		if not FileAccess.file_exists(resource_path):
			errors.append("published sheet is missing: %s" % sheet_id)
			continue
		var absolute_path := ProjectSettings.globalize_path(resource_path)
		if (
			FileAccess.get_sha256(absolute_path)
			!= String(sheet.get("sha256", ""))
		):
			errors.append("published sheet hash mismatch: %s" % sheet_id)
		var image := Image.load_from_file(absolute_path)
		if image == null or image.get_size() != Vector2i(2048, 1152):
			errors.append("published sheet dimensions must be 2048x1152: %s" % sheet_id)
	for sheet_id in EXPECTED_SHEETS:
		if not seen.has(sheet_id):
			errors.append("manifest is missing required sheet: %s" % sheet_id)
	if seen.size() != EXPECTED_SHEETS.size():
		errors.append(
			"manifest must contain exactly %d sheets"
			% EXPECTED_SHEETS.size()
		)
