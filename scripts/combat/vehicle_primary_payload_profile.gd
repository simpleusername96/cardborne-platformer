class_name VehiclePrimaryPayloadProfile
extends RefCounted

## Frozen primary-shot payload for one build revision. Any two acquired
## attributes can contribute their effects to the same projectile.

var thermal_enabled := false
var thermal_burst_radius := 72.0
var thermal_burst_damage := 4.0

var poison_enabled := false
var poison_dps_per_stack := 2.0
var poison_duration := 5.0
var poison_max_stacks := 3

var chill_enabled := false
var chill_magnitude_per_stack := 0.06
var chill_duration := 2.0
var chill_max_stacks := 3
var chill_shatter_damage := 18.0


static func from_build(build: VehicleRunBuild) -> VehiclePrimaryPayloadProfile:
	var profile := VehiclePrimaryPayloadProfile.new()
	var active_attributes := build.active_attribute_ids()
	var thermal_level := build.level_of(&"thermal_burst") if &"thermal_burst" in active_attributes else 0
	profile.thermal_enabled = thermal_level > 0
	if profile.thermal_enabled:
		profile.thermal_burst_radius = build.stat(&"thermal_burst_radius", 0.0)
		profile.thermal_burst_damage = build.stat(&"thermal_burst_damage", 0.0)

	var poison_level := build.level_of(&"bio_toxin") if &"bio_toxin" in active_attributes else 0
	profile.poison_enabled = poison_level > 0
	if profile.poison_enabled:
		profile.poison_dps_per_stack = build.stat(&"toxin_dps_per_stack", 0.0)
		profile.poison_duration = build.stat(&"toxin_duration", 0.0)

	var chill_level := build.level_of(&"cryo_slow") if &"cryo_slow" in active_attributes else 0
	profile.chill_enabled = chill_level > 0
	if profile.chill_enabled:
		profile.chill_magnitude_per_stack = build.stat(&"cryo_slow_per_stack", 0.0) / 100.0
		profile.chill_duration = build.stat(&"cryo_duration", 0.0)
		profile.chill_shatter_damage = build.stat(&"cryo_shatter_damage", 0.0)

	return profile


func affinity() -> StringName:
	if poison_enabled and chill_enabled:
		return &"hybrid"
	if thermal_enabled:
		return &"thermal"
	if poison_enabled:
		return &"toxin"
	if chill_enabled:
		return &"cryo"
	return &"kinetic"


func has_persistent_status() -> bool:
	return poison_enabled or chill_enabled


func can_trigger_thermal_burst(owner: String, reflected: bool) -> bool:
	return thermal_enabled and owner == "player_primary" and not reflected
