class_name EnemyCatalog
extends Resource

const FLOAT_TOLERANCE := 0.0001

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var tags: Array[StringName] = []
@export var archetypes: Array[EnemyArchetypeDefinition] = []
@export var tuning_profiles: Array[EnemyTuningProfile] = []
@export var variants: Array[EnemyVariantDefinition] = []


func get_archetype_by_id(archetype_id: StringName) -> EnemyArchetypeDefinition:
	for archetype in archetypes:
		if archetype != null and archetype.id == archetype_id:
			return archetype
	return null


func get_tuning_profile_by_id(tuning_profile_id: StringName) -> EnemyTuningProfile:
	for tuning_profile in tuning_profiles:
		if tuning_profile != null and tuning_profile.id == tuning_profile_id:
			return tuning_profile
	return null


func get_variant_by_id(variant_id: StringName) -> EnemyVariantDefinition:
	for variant in variants:
		if variant != null and variant.id == variant_id:
			return variant
	return null


func has_archetype(archetype_id: StringName) -> bool:
	return get_archetype_by_id(archetype_id) != null


func has_tuning_profile(tuning_profile_id: StringName) -> bool:
	return get_tuning_profile_by_id(tuning_profile_id) != null


func has_variant(variant_id: StringName) -> bool:
	return get_variant_by_id(variant_id) != null


func resolve(
	archetype_id: StringName,
	variant_id: StringName,
	stage_id: StringName
) -> ResolvedEnemySpec:
	if not get_resolution_errors(archetype_id, variant_id, stage_id).is_empty():
		return null
	var archetype := get_archetype_by_id(archetype_id)
	var variant := get_variant_by_id(variant_id)
	var tuning_profile := get_tuning_profile_by_id(variant.tuning_profile_id)
	return ResolvedEnemySpec.from_definitions(
		archetype,
		variant,
		tuning_profile,
		content_version
	)


func all_eligible(stage_id: StringName) -> Array[ResolvedEnemySpec]:
	var resolved_specs: Array[ResolvedEnemySpec] = []
	if not validate_catalog().is_empty():
		return resolved_specs
	for variant in variants:
		if variant.stage_id != stage_id:
			continue
		var archetype := get_archetype_by_id(variant.archetype_id)
		var tuning_profile := get_tuning_profile_by_id(variant.tuning_profile_id)
		resolved_specs.append(
			ResolvedEnemySpec.from_definitions(
				archetype,
				variant,
				tuning_profile,
				content_version
			)
		)
	return resolved_specs


func get_resolution_errors(
	archetype_id: StringName,
	variant_id: StringName,
	stage_id: StringName
) -> PackedStringArray:
	var errors := validate_catalog()
	var archetype := get_archetype_by_id(archetype_id)
	var variant := get_variant_by_id(variant_id)
	if archetype == null:
		errors.append("Unknown enemy archetype ID '%s'." % archetype_id)
	if variant == null:
		errors.append("Unknown enemy variant ID '%s'." % variant_id)
		return errors
	if variant.archetype_id != archetype_id:
		errors.append(
			"Enemy variant '%s' belongs to archetype '%s', not requested archetype '%s'."
			% [variant.id, variant.archetype_id, archetype_id]
		)
	if variant.stage_id != stage_id:
		errors.append(
			"Enemy variant '%s' belongs to stage '%s', not requested stage '%s'."
			% [variant.id, variant.stage_id, stage_id]
		)
	var tuning_profile := get_tuning_profile_by_id(variant.tuning_profile_id)
	if tuning_profile != null and tuning_profile.stage_id != stage_id:
		errors.append(
			"Enemy variant '%s' tuning profile belongs to stage '%s', not requested stage '%s'."
			% [variant.id, tuning_profile.stage_id, stage_id]
		)
	return errors

func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Enemy catalog ID", id)
	if display_name.strip_edges().is_empty():
		errors.append("Enemy catalog '%s' needs a display name." % id)
	if content_version <= 0:
		errors.append("Enemy catalog '%s' needs a positive content version." % id)
	ContentId.validate_list(errors, "Enemy catalog '%s' tag" % id, tags, true)
	if archetypes.is_empty():
		errors.append("Enemy catalog '%s' needs at least one archetype." % id)
	if tuning_profiles.is_empty():
		errors.append("Enemy catalog '%s' needs at least one tuning profile." % id)
	if variants.is_empty():
		errors.append("Enemy catalog '%s' needs at least one variant." % id)

	var seen_archetype_ids: Dictionary = {}
	for archetype_index in archetypes.size():
		var archetype := archetypes[archetype_index]
		if archetype == null:
			errors.append("Enemy archetype at index %d is null." % archetype_index)
			continue
		var archetype_id := String(archetype.id)
		if seen_archetype_ids.has(archetype_id):
			errors.append("Duplicate enemy archetype ID '%s'." % archetype_id)
		seen_archetype_ids[archetype_id] = true
		for definition_error in archetype.validate_definition():
			errors.append("Enemy archetype '%s': %s" % [archetype.id, definition_error])

	var seen_tuning_ids: Dictionary = {}
	var seen_tuning_stages: Dictionary = {}
	for tuning_index in tuning_profiles.size():
		var tuning_profile := tuning_profiles[tuning_index]
		if tuning_profile == null:
			errors.append("Enemy tuning profile at index %d is null." % tuning_index)
			continue
		var tuning_id := String(tuning_profile.id)
		if seen_tuning_ids.has(tuning_id):
			errors.append("Duplicate enemy tuning profile ID '%s'." % tuning_id)
		seen_tuning_ids[tuning_id] = true
		var tuning_stage := String(tuning_profile.stage_id)
		if seen_tuning_stages.has(tuning_stage):
			errors.append("Stage '%s' has more than one enemy tuning profile." % tuning_stage)
		seen_tuning_stages[tuning_stage] = true
		for definition_error in tuning_profile.validate_definition():
			errors.append("Enemy tuning profile '%s': %s" % [tuning_profile.id, definition_error])

	var seen_variant_ids: Dictionary = {}
	var seen_presentations: Dictionary = {}
	for variant_index in variants.size():
		var variant := variants[variant_index]
		if variant == null:
			errors.append("Enemy variant at index %d is null." % variant_index)
			continue
		var variant_id := String(variant.id)
		if seen_variant_ids.has(variant_id):
			errors.append("Duplicate enemy variant ID '%s'." % variant_id)
		seen_variant_ids[variant_id] = true
		var presentation_key := String(variant.presentation_key)
		if seen_presentations.has(presentation_key):
			errors.append("Enemy presentation key '%s' is assigned to multiple variants." % presentation_key)
		seen_presentations[presentation_key] = true
		for definition_error in variant.validate_definition():
			errors.append("Enemy variant '%s': %s" % [variant.id, definition_error])

		var archetype := get_archetype_by_id(variant.archetype_id)
		if archetype == null:
			errors.append(
				"Enemy variant '%s' references missing archetype '%s'."
				% [variant.id, variant.archetype_id]
			)
		var tuning_profile := get_tuning_profile_by_id(variant.tuning_profile_id)
		if tuning_profile == null:
			errors.append(
				"Enemy variant '%s' references missing tuning profile '%s'."
				% [variant.id, variant.tuning_profile_id]
			)
		if archetype != null:
			for safety_error in _validate_variant_safety(archetype, variant):
				errors.append(safety_error)
		if archetype != null and tuning_profile != null:
			for tuning_error in tuning_profile.validate_authored_variant(archetype, variant):
				errors.append(tuning_error)

	return errors


func _validate_variant_safety(
	archetype: EnemyArchetypeDefinition,
	variant: EnemyVariantDefinition
) -> PackedStringArray:
	var errors := PackedStringArray()
	if variant.damage > archetype.maximum_damage:
		errors.append(
			"Enemy variant '%s' damage %d exceeds archetype '%s' safety ceiling %d."
			% [variant.id, variant.damage, archetype.id, archetype.maximum_damage]
		)
	if variant.warning_time + FLOAT_TOLERANCE < archetype.minimum_warning_time:
		errors.append(
			"Enemy variant '%s' warning %.3f is below archetype '%s' safety floor %.3f."
			% [variant.id, variant.warning_time, archetype.id, archetype.minimum_warning_time]
		)
	if variant.recovery_time + FLOAT_TOLERANCE < archetype.minimum_recovery_time:
		errors.append(
			"Enemy variant '%s' recovery %.3f is below archetype '%s' safety floor %.3f."
			% [variant.id, variant.recovery_time, archetype.id, archetype.minimum_recovery_time]
		)
	return errors
