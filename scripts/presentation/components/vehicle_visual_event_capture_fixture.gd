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
			&"mystery_projectile_purge",
		],
	},
]


static func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var captured := {}
	var authored_effects := 0
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
		var mode := StringName(descriptor.get("mode", &"suppressed"))
		if mode == &"authored_emp":
			authored_effects += 1
			if StringName(descriptor.get("asset", &"")) != &"effect/emp_release":
				errors.append("authored EMP event uses the wrong asset: %s" % event_id)
		if mode == &"authored_thermal":
			authored_effects += 1
			if StringName(descriptor.get("asset", &"")) != &"effect/thermal_burst_impact":
				errors.append("authored Thermal event uses the wrong asset: %s" % event_id)
		if not captured.has(event_id):
			errors.append("transient event has no capture fixture: %s" % event_id)
	if authored_effects != 2:
		errors.append("exactly one EMP and one Thermal event must request authored rasters")
	return errors
