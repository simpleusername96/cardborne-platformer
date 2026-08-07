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
	var burn_level := clampi(build.level_of(&"thermal_burn"), 0, 3)
	profile.burn_enabled = burn_level > 0
	if burn_level > 0:
		profile.burn_dps_per_stack = [2.0, 3.0, 4.0][burn_level - 1]
		profile.burn_duration = [3.0, 4.0, 5.0][burn_level - 1]

	var poison_level := clampi(build.level_of(&"bio_toxin"), 0, 3)
	profile.poison_enabled = poison_level > 0
	if poison_level > 0:
		profile.poison_dps_per_stack = [2.0, 3.0, 4.0][poison_level - 1]
		profile.poison_duration = [5.0, 6.0, 7.0][poison_level - 1]

	var chill_level := clampi(build.level_of(&"cryo_slow"), 0, 3)
	profile.chill_enabled = chill_level > 0
	if chill_level > 0:
		profile.chill_magnitude_per_stack = [0.06, 0.08, 0.10][chill_level - 1]
		profile.chill_duration = [2.0, 2.5, 3.0][chill_level - 1]
	return profile


func has_any_status() -> bool:
	return burn_enabled or poison_enabled or chill_enabled
