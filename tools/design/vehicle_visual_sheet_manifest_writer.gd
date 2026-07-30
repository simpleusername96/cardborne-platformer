class_name VehicleVisualSheetManifestWriter
extends RefCounted

## Writes the deterministic publication record for runtime-backed visual sheets.


static func write(
	output_directory: String,
	sheets: Array[Dictionary],
	token_fingerprint: String,
	catalog_fingerprint: String,
	source_commit: String
) -> Error:
	var manifest := {
		"schema_version": 1,
		"system_id": "cardborne-general-sf-v1",
		"source_commit": source_commit,
		"providers": {
			"tokens": "res://scripts/vehicle/vehicle_stage_visual_profile.gd",
			"catalog_registry": (
				"res://scripts/presentation/components/vehicle_visual_system_registry.gd"
			),
			"font": (
				"res://art/ui/production/fonts/NotoSansKR-Variable.ttf"
			),
		},
		"provider_fingerprints": {
			"tokens": token_fingerprint,
			"catalog_registry": catalog_fingerprint,
		},
		"viewport": [2048, 1152],
		"locale": "ko",
		"sheets": sheets,
		"planned_sheet_ids": [
			"02-world-surfaces",
			"03-world-facilities",
			"04-player-components",
			"05-enemy-components",
			"06-boss-components",
			"07-projectile-telegraph-vfx",
			"08-reward-upgrade-glyphs",
			"09-hud-minimap-markers",
			"11-modal-flow-contact-sheet",
			"12-pressure-accessibility",
		],
	}
	var path := output_directory.path_join("manifest.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "\t", false))
	file.store_string("\n")
	return OK
