class_name VehicleVisualEventCaptureFixture
extends RefCounted

## Reviewed coverage for the minimal transient presentation surface.

const VisualEventCatalog = preload(
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)

const GROUPS := [
	{
		"id": &"essential_transients",
		"events": [
			&"player_dash_afterimage",
			&"player_emp_charge",
			&"player_emp_release",
			&"thermal_burst_impact",
			&"drop_mine_detonation",
			&"explosive_seeker_impact",
		],
	},
]


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var captured := {}
	for group in GROUPS:
		for event_variant in Array(group["events"]):
			var event_id := StringName(event_variant)
			if captured.has(event_id):
				errors.append("duplicate capture event: %s" % event_id)
			captured[event_id] = true
			if not VisualEventCatalog.has_event(event_id):
				errors.append("capture fixture event is unmapped: %s" % event_id)
	for event_id in VisualEventCatalog.event_ids():
		var descriptor := VisualEventCatalog.descriptor(event_id)
		if descriptor.has("asset"):
			errors.append("transient event must not request an effect raster: %s" % event_id)
		if not captured.has(event_id):
			errors.append("transient event has no capture fixture: %s" % event_id)
	return errors
