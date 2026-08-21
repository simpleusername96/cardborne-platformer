class_name VehicleEnemySpeedProfile
extends RefCounted

## Canonical ordinary effective-speed calculation shared by birth reservation
## ETA estimation and VehicleRun actor initialization.

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const BossProfiles = preload("res://scripts/bosses/vehicle_boss_profile_catalog.gd")


static func effective_speed(archetype: StringName, stage_index: int, difficulty: StringName) -> float:
	var definition := Archetypes.definition(archetype)
	var difficulty_speed := float(RunDifficulty.profile(difficulty)["speed"])
	if archetype == &"boss_actor":
		return BossProfiles.move_speed(stage_index)
	return (
		float(definition["speed"])
		* EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER
		* float(StageDifficulty.multipliers(stage_index)["speed"])
		* difficulty_speed
	)
