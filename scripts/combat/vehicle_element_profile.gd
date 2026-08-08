class_name VehicleElementProfile
extends RefCounted

## Build-revision elemental payload. Callers treat the populated profile as
## immutable; thermal is immediate burst damage while toxin/chill persist.

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


static func from_build(build: VehicleRunBuild) -> VehicleElementProfile:
	var profile := VehicleElementProfile.new()
	var active_element := build.active_element_id()
	var thermal_level := (
		clampi(build.level_of(&"thermal_burst"), 0, 3)
		if active_element == &"thermal_burst"
		else 0
	)
	profile.thermal_enabled = thermal_level > 0
	if thermal_level > 0:
		profile.thermal_burst_radius = [72.0, 84.0, 96.0][thermal_level - 1]
		profile.thermal_burst_damage = [4.0, 6.0, 8.0][thermal_level - 1]

	var poison_level := (
		clampi(build.level_of(&"bio_toxin"), 0, 3)
		if active_element == &"bio_toxin"
		else 0
	)
	profile.poison_enabled = poison_level > 0
	if poison_level > 0:
		profile.poison_dps_per_stack = [2.0, 3.0, 4.0][poison_level - 1]
		profile.poison_duration = [5.0, 6.0, 7.0][poison_level - 1]

	var chill_level := (
		clampi(build.level_of(&"cryo_slow"), 0, 3)
		if active_element == &"cryo_slow"
		else 0
	)
	profile.chill_enabled = chill_level > 0
	if chill_level > 0:
		profile.chill_magnitude_per_stack = [0.06, 0.08, 0.10][chill_level - 1]
		profile.chill_duration = [2.0, 2.5, 3.0][chill_level - 1]
	return profile


func affinity() -> StringName:
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
