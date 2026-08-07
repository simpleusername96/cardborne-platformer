class_name VehicleStatusProfile
extends RefCounted

## Immutable elemental payload shared by every projectile fired at one build revision.

var burn_enabled := false
var burn_dps_per_stack := 2.0
var burn_duration := 3.0
var burn_max_stacks := 3

var poison_enabled := false
var poison_dps_per_stack := 2.0
var poison_duration := 5.0
var poison_max_stacks := 3

var chill_enabled := false
var chill_magnitude_per_stack := 0.06
var chill_duration := 2.0
var chill_max_stacks := 3


static func from_build(build: VehicleRunBuild) -> VehicleStatusProfile:
	var profile := VehicleStatusProfile.new()
	profile.burn_enabled = build.has(&"incendiary_core")

	profile.poison_enabled = build.has(&"toxin_core")

	profile.chill_enabled = build.has(&"cryo_core")
	return profile


func has_any_status() -> bool:
	return burn_enabled or poison_enabled or chill_enabled
