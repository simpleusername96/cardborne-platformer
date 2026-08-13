class_name VehicleEnemySpeedProfile
extends RefCounted

## Canonical ordinary effective-speed calculation shared by birth reservation
## ETA estimation and VehicleRun actor initialization.

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const RunDifficulty = preload("res://scripts/vehicle/vehicle_run_difficulty.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")


static func effective_speed(archetype: StringName, stage_index: int, difficulty: StringName) -> float:
	var definition := Archetypes.definition(archetype)
	var multiplier := (
		EncounterDirector.ENEMY_SPEED_MULTIPLIER
		if archetype == &"stage_boss"
		else EncounterDirector.ORDINARY_MOVEMENT_SPEED_MULTIPLIER
	)
	var result := float(definition["speed"]) * multiplier * float(RunDifficulty.profile(difficulty)["speed"])
	if archetype != &"stage_boss":
		result *= float(StageDifficulty.multipliers(stage_index)["speed"])
	return result
