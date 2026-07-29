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
var contagion := false

var chill_enabled := false
var chill_magnitude_per_stack := 0.06
var chill_duration := 2.0
var chill_max_stacks := 3


static func from_build(build: VehicleRunBuild) -> VehicleStatusProfile:
	var profile := VehicleStatusProfile.new()
	var thermal_level := build.level_of(&"thermal_compound")
	profile.burn_enabled = build.has(&"incendiary_core")
	profile.burn_dps_per_stack = 2.0 + 0.75 * float(thermal_level)
	profile.burn_duration = 3.0 + 0.5 * float(thermal_level)

	var toxin_level := build.level_of(&"concentrated_toxin")
	profile.poison_enabled = build.has(&"toxin_core")
	profile.poison_dps_per_stack = 2.0 + float(toxin_level)
	profile.poison_max_stacks = 3 + toxin_level
	profile.contagion = build.has(&"contagion")

	var freeze_level := build.level_of(&"deep_freeze")
	profile.chill_enabled = build.has(&"cryo_core")
	profile.chill_magnitude_per_stack = 0.06 + 0.02 * float(freeze_level)
	profile.chill_duration = 2.0 + 0.5 * float(freeze_level)
	return profile


func has_any_status() -> bool:
	return burn_enabled or poison_enabled or chill_enabled
