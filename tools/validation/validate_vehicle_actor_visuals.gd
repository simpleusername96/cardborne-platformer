extends SceneTree

const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const ActorRecipes = preload(
	"res://scripts/presentation/components/vehicle_actor_mesh_recipes.gd"
)
const Visuals = preload(
	"res://scripts/presentation/vehicle_combat_visual_library.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")

const APPROVED_MASTER_PATH := (
	"res://docs/design/component-sheets/00-general-sf-component-master-v1.png"
)
const APPROVED_MASTER_SHA256 := (
	"d91df76685480676e6695eeaab7db49e93c7de89e1950a9b3b3bc806c02ea7e7"
)
const BOSS_VARIANTS: Array[StringName] = [
	&"colossus", &"leviathan", &"titan", &"behemoth", &"crown",
]
const BOSS_MODULE_IDS: Array[StringName] = [
	&"boss_pylon",
	&"forge_plate",
	&"segment_lock",
	&"relay_positive",
	&"relay_negative",
	&"route_switch",
	&"armor_car",
	&"lattice_outer",
]

var _failures: Array[String] = []


func _initialize() -> void:
	_validate_approved_authority()
	_validate_player_recipe()
	_validate_ordinary_recipes()
	_validate_boss_recipes()
	_validate_no_generic_fallback()
	_finish()


func _validate_approved_authority() -> void:
	_expect(
		FileAccess.file_exists(APPROVED_MASTER_PATH),
		"approved general-SF component master exists"
	)
	if not FileAccess.file_exists(APPROVED_MASTER_PATH):
		return
	var absolute_path := ProjectSettings.globalize_path(APPROVED_MASTER_PATH)
	_expect(
		FileAccess.get_sha256(absolute_path) == APPROVED_MASTER_SHA256,
		"actor recipes target the approved master hash"
	)


func _validate_player_recipe() -> void:
	var descriptor := ActorCatalog.descriptor(&"player")
	var components := Dictionary(descriptor.get("components", {}))
	_expect(
		Array(descriptor.get("states", [])).has(&"dash"),
		"player descriptor preserves the dash presentation state"
	)
	for component_id in [&"hull", &"engine", &"engine_flare", &"aim_mount"]:
		var recipe_id := StringName(components.get(component_id, &""))
		var layers := ActorRecipes.player_component_layers(recipe_id)
		_expect(
			recipe_id in ActorRecipes.PLAYER_COMPONENT_RECIPES,
			"player %s maps to an approved component recipe" % component_id
		)
		_validate_layers(layers, "player/%s" % component_id, 2, 5)
	_expect(
		ActorRecipes.plane_count(
			ActorRecipes.player_component_layers(
				StringName(components.get(&"hull", &""))
			)
		) == 5,
		"player hull exposes five mechanical planes"
	)


func _validate_ordinary_recipes() -> void:
	var signatures := {}
	var grammar_coverage := {}
	var ordinary_count := 0
	for archetype in Visuals.ENEMY_ARCHETYPES:
		if archetype in [&"boss_pylon", &"stage_boss"]:
			continue
		ordinary_count += 1
		var descriptor := ActorCatalog.descriptor(archetype)
		var recipe_id := StringName(descriptor.get("recipe", &""))
		var grammar_id := StringName(descriptor.get("grammar", &""))
		var signature := ActorRecipes.enemy_signature(recipe_id)
		var layers := ActorRecipes.enemy_layers(recipe_id, grammar_id)
		_expect(
			recipe_id in ActorRecipes.ORDINARY_RECIPES,
			"%s owns an approved ordinary recipe" % archetype
		)
		_expect(
			grammar_id in ActorRecipes.ORDINARY_GRAMMARS,
			"%s derives from an approved role grammar" % archetype
		)
		grammar_coverage[grammar_id] = true
		var signature_text := var_to_str(signature)
		_expect(
			not signatures.has(signature_text),
			"%s keeps a unique grayscale outer contour" % archetype
		)
		signatures[signature_text] = archetype
		_validate_layers(layers, "enemy/%s" % archetype, 5, 5)
		_expect(
			Visuals.enemy_mesh(archetype).get_surface_count() == 1,
			"%s compiles into one retained mesh surface" % archetype
		)
		_expect(
			not _contains_generic_fallback(recipe_id),
			"%s does not use a generic production fallback" % archetype
		)
	_expect(ordinary_count == 18, "all 18 ordinary actors are validated")
	_expect(signatures.size() == 18, "all 18 ordinary contours remain distinct")
	_expect(
		grammar_coverage.size() == ActorRecipes.ORDINARY_GRAMMARS.size(),
		"all eight approved role grammars are represented"
	)
	var escort := ActorCatalog.descriptor(&"escort_drone")
	var escort_recipe := StringName(escort.get("recipe", &""))
	var escort_grammar := StringName(escort.get("grammar", &""))
	_expect(
		not ActorRecipes.enemy_layers(escort_recipe, escort_grammar).is_empty()
			and Visuals.enemy_mesh(&"escort_drone").get_surface_count() == 1,
		"escort drone resolves to a production chevron recipe"
	)
	_validate_role_grammar_fidelity()


func _validate_boss_recipes() -> void:
	var signatures := {}
	for variant in BOSS_VARIANTS:
		var descriptor := ActorCatalog.descriptor(variant)
		var recipe_id := StringName(descriptor.get("recipe", &""))
		var layers := ActorRecipes.boss_layers(recipe_id)
		var signature := ActorRecipes.boss_signature(recipe_id)
		_expect(
			recipe_id in ActorRecipes.BOSS_RECIPES,
			"%s owns an approved asymmetric boss recipe" % variant
		)
		_expect(
			Array(descriptor.get("states", [])).has(&"vulnerable"),
			"%s publishes its vulnerable state" % variant
		)
		_expect(
			_is_asymmetric(signature),
			"%s outer contour is intentionally asymmetric" % variant
		)
		_expect(
			_aspect_ratio(signature) >= 1.5,
			"%s boss body is intrinsically wide in runtime orientation" % variant
		)
		_expect(
			_layers_on_plane(layers, &"perimeter").size() >= 3
				and _layers_on_plane(layers, &"offset_module").size() >= 3,
			"%s composes its body with two external detachable pods" % variant
		)
		var channel_layers := _layers_on_plane(layers, &"vulnerable_channel")
		_expect(
			channel_layers.size() == 1
				and _aspect_ratio(
					PackedVector2Array(channel_layers[0].get(
						"points",
						PackedVector2Array()
					))
				) >= 1.8,
			"%s exposes a horizontal or diagonal vulnerable channel" % variant
		)
		var signature_text := var_to_str(signature)
		_expect(
			not signatures.has(signature_text),
			"%s keeps a unique boss contour" % variant
		)
		signatures[signature_text] = variant
		_validate_layers(layers, "boss/%s" % variant, 5, 5)
		_expect(
			Visuals.boss_mesh(variant).get_surface_count() == 1,
			"%s compiles into one retained boss surface" % variant
		)
		_expect(
			not _contains_generic_fallback(recipe_id),
			"%s does not use a generic boss fallback" % variant
		)
	for module_id in BOSS_MODULE_IDS:
		var descriptor := ActorCatalog.descriptor(module_id)
		var recipe_id := StringName(descriptor.get("recipe", &""))
		_expect(
			recipe_id in ActorRecipes.BOSS_MODULE_RECIPES,
			"%s maps to an authored objective-module recipe" % module_id
		)
		for state in [&"active", &"disabled"]:
			var layers := ActorRecipes.boss_module_layers(recipe_id, state)
			_validate_layers(
				layers,
				"boss_module/%s/%s" % [module_id, state],
				4,
				4
			)
			_expect(
				Visuals.boss_module_mesh(module_id, state).get_surface_count()
					== 1,
				"%s %s compiles into one retained module surface"
				% [module_id, state]
			)


func _validate_role_grammar_fidelity() -> void:
	var swarm_layers := ActorRecipes.enemy_layers(
		&"swarm_scrap_chevron",
		&"solid_chevron"
	)
	var swarm_inset := _layers_on_plane(swarm_layers, &"function_inset")
	_expect(
		swarm_inset.size() == 1
			and Color(swarm_inset[0].get("color", Color.TRANSPARENT))
				!= Art.WORLD_CANVAS
			and _layers_on_plane(swarm_layers, &"hard_highlight").size() == 1,
		"swarm reads as a solid chevron with a small center highlight"
	)
	var melee_layers := ActorRecipes.enemy_layers(
		&"melee_pursuit_split",
		&"split_spear"
	)
	var melee_gap := _layers_on_plane(melee_layers, &"function_inset")
	_expect(
		melee_gap.size() == 1
			and _bounds(
				PackedVector2Array(melee_gap[0].get(
					"points",
					PackedVector2Array()
				))
			).end.x >= 0.70,
		"melee exposes a deep forward split between spear prongs"
	)
	var ranged_layers := ActorRecipes.enemy_layers(
		&"ranged_gunship_bracket",
		&"open_bracket"
	)
	var ranged_opening := _layers_on_plane(ranged_layers, &"function_inset")
	_expect(
		ranged_opening.size() == 1
			and _bounds(
				PackedVector2Array(ranged_opening[0].get(
					"points",
					PackedVector2Array()
				))
			).end.x >= 1.0,
		"ranged exposes an open two-prong muzzle bracket"
	)
	var controller_layers := ActorRecipes.enemy_layers(
		&"command_twin_prong",
		&"twin_prong"
	)
	_expect(
		_layers_on_plane(controller_layers, &"main_mass").size() == 2
			and _layers_on_plane(controller_layers, &"perimeter").size() >= 3
			and _layers_on_plane(controller_layers, &"function_inset").size() == 1,
		"controller owns two separated prongs and an outlined command core"
	)
	var shield_signature := ActorRecipes.enemy_signature(&"shield_forward_slab")
	var forward_face_points := 0
	for point in shield_signature:
		if point.x >= 1.0:
			forward_face_points += 1
	_expect(
		forward_face_points >= 2,
		"shield grammar keeps an unmistakable flat forward slab"
	)
	_expect(
		_aspect_ratio(
			ActorRecipes.enemy_signature(&"artillery_long_rail")
		) >= 1.7,
		"artillery grammar keeps a long rail body"
	)
	var support_layers := ActorRecipes.enemy_layers(
		&"generator_open_cradle",
		&"open_cradle"
	)
	var support_opening := _layers_on_plane(
		support_layers,
		&"function_inset"
	)
	_expect(
		support_opening.size() == 1
			and _bounds(
				PackedVector2Array(support_opening[0].get(
					"points",
					PackedVector2Array()
				))
			).end.x >= 0.85,
		"support grammar keeps a visibly open forward cradle"
	)


func _validate_no_generic_fallback() -> void:
	_expect(
		ActorRecipes.enemy_signature(&"missing_actor").is_empty()
			and ActorRecipes.enemy_layers(
				&"missing_actor", &"solid_chevron"
			).is_empty(),
		"unknown ordinary actor recipes do not fall back to a polygon"
	)
	_expect(
		ActorRecipes.boss_signature(&"missing_boss").is_empty()
			and ActorRecipes.boss_layers(&"missing_boss").is_empty(),
		"unknown boss recipes do not fall back to a polygon"
	)
	_expect(
		ActorRecipes.boss_module_signature(&"missing_module").is_empty()
			and ActorRecipes.boss_module_layers(
				&"missing_module", &"active"
			).is_empty(),
		"unknown objective modules do not fall back to a diamond"
	)


func _validate_layers(
	layers: Array[Dictionary],
	label: String,
	minimum_planes: int,
	maximum_planes: int
) -> void:
	var plane_count := ActorRecipes.plane_count(layers)
	_expect(
		plane_count >= minimum_planes and plane_count <= maximum_planes,
		"%s uses %d..%d filled mechanical planes"
		% [label, minimum_planes, maximum_planes]
	)
	for layer in layers:
		var points := PackedVector2Array(
			layer.get("points", PackedVector2Array())
		)
		_expect(points.size() >= 3, "%s layer has a drawable polygon" % label)
		if points.size() >= 3:
			_expect(
				not Geometry2D.triangulate_polygon(points).is_empty(),
				"%s layer triangulates without self-intersection" % label
			)


func _is_asymmetric(points: PackedVector2Array) -> bool:
	for point in points:
		var mirrored := Vector2(point.x, -point.y)
		var found := false
		for candidate in points:
			if candidate.distance_to(mirrored) <= 0.001:
				found = true
				break
		if not found:
			return true
	return false


func _layers_on_plane(
	layers: Array[Dictionary],
	plane: StringName
) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for layer in layers:
		if StringName(layer.get("plane", &"")) == plane:
			matches.append(layer)
	return matches


func _bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var minimum := points[0]
	var maximum := points[0]
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


func _aspect_ratio(points: PackedVector2Array) -> float:
	var bounds := _bounds(points)
	if bounds.size.y <= 0.001:
		return 0.0
	return bounds.size.x / bounds.size.y


func _contains_generic_fallback(recipe_id: StringName) -> bool:
	var value := String(recipe_id).to_lower()
	for token in ["diamond", "octagon", "star", "regular_polygon"]:
		if token in value:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 96:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_ACTOR_VISUALS_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
