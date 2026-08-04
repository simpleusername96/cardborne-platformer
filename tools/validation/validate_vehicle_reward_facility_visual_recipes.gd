extends SceneTree

const Recipes = preload(
	"res://scripts/presentation/components/vehicle_reward_facility_visual_recipes.gd"
)
const RewardCatalog = preload(
	"res://scripts/presentation/components/vehicle_reward_visual_catalog.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const EXPECTED_REWARDS: Array[StringName] = [
	&"reward_crate",
	&"experience_small",
	&"experience_medium",
	&"experience_large",
	&"repair",
	&"experience_recall",
]

const EXPECTED_FACILITIES: Array[StringName] = [
	&"repair_field",
	&"transit_gate",
	&"overdrive_field",
	&"arc_surge_strip",
	&"breakable_bulkhead",
]

var _failures: Array[String] = []


func _initialize() -> void:
	for error in Recipes.validate_recipes():
		_failures.append(error)
	_validate_registry()
	_validate_catalog_adapters()
	_validate_adapter_commands()
	_validate_approved_grammars()
	_finish()


func _validate_registry() -> void:
	_expect(
		Recipes.reward_ids() == EXPECTED_REWARDS,
		"all six reward recipes retain stable IDs"
	)
	_expect(
		Recipes.facility_ids() == EXPECTED_FACILITIES,
		"all five facility recipes retain stable IDs"
	)
	_expect(
		Recipes.recipe_ids().size() == 11,
		"reward and facility recipes publish eleven total IDs"
	)
	_expect(
		Recipes.recipe(&"missing_recipe").is_empty()
			and Recipes.polygon_commands(&"missing_recipe").is_empty()
			and Recipes.signature(&"missing_recipe").is_empty(),
		"unknown IDs never fall back to generic geometry"
	)


func _validate_catalog_adapters() -> void:
	for reward_id in EXPECTED_REWARDS:
		var descriptor := RewardCatalog.descriptor(reward_id)
		_expect(
			StringName(descriptor.get("recipe", &"")) == reward_id
				and Recipes.has_recipe(reward_id),
			"%s reward descriptor resolves to its shared recipe" % reward_id
		)
	for facility_id in EXPECTED_FACILITIES:
		var descriptor := WorldCatalog.facility_descriptor(facility_id)
		_expect(
			StringName(descriptor.get("recipe", &"")) == facility_id
				and Recipes.has_recipe(facility_id),
			"%s facility descriptor resolves to its shared recipe" % facility_id
		)
func _validate_adapter_commands() -> void:
	var palette := {
		&"accent":Color(0.70, 0.42, 0.18, 1.0),
		&"perimeter":Color(0.05, 0.07, 0.09, 1.0),
		&"secondary":Color(0.36, 0.38, 0.42, 1.0),
		&"surface":Color(0.10, 0.12, 0.15, 1.0),
		&"highlight":Color(0.96, 0.92, 0.78, 1.0),
	}
	for recipe_id in Recipes.recipe_ids():
		var commands := Recipes.polygon_commands(recipe_id)
		var resolved := Recipes.resolved_polygon_commands(
			recipe_id,
			Vector2(17.0, 29.0),
			24.0,
			palette
		)
		_expect(
			not commands.is_empty() and resolved.size() == commands.size(),
			"%s exposes matching normalized and resolved polygon commands"
			% recipe_id
		)
		for command in resolved:
			var points := PackedVector2Array(
				command.get("points", PackedVector2Array())
			)
			_expect(
				points.size() >= 3
					and not Geometry2D.triangulate_polygon(points).is_empty(),
				"%s resolved polygon remains mesh-compilable" % recipe_id
			)
			_expect(
				command.get("color", null) is Color,
				"%s resolves caller palette colors" % recipe_id
			)
		var normalized := Recipes.normalized_bounds(recipe_id)
		var transformed := Recipes.transformed_bounds(
			recipe_id,
			Vector2(17.0, 29.0),
			24.0
		)
		_expect(
			transformed.position.is_equal_approx(
				Vector2(17.0, 29.0) + normalized.position * 24.0
			)
				and transformed.size.is_equal_approx(normalized.size * 24.0),
			"%s bounds transform with the adapter commands" % recipe_id
		)


func _validate_approved_grammars() -> void:
	_expect(
		Recipes.shape_id(&"repair") == &"layered_repair_plus_cut"
			and Recipes.plane_count(&"repair") == 5,
		"repair preserves the approved layered plus-cut grammar"
	)
	_expect(
		Recipes.shape_id(&"experience_recall")
			== &"three_way_inward_chevrons"
			and Recipes.signature(&"experience_recall").size() == 3,
		"recall preserves three discrete inward chevrons"
	)
	for tier in [&"experience_small", &"experience_medium", &"experience_large"]:
		_expect(
			String(Recipes.shape_id(tier)).begins_with("mechanical_shard_tier_"),
			"%s belongs to the scalable mechanical-shard family" % tier
		)
	_expect(
		Recipes.normalized_bounds(&"experience_small").size.length()
			< Recipes.normalized_bounds(&"experience_medium").size.length()
			and Recipes.normalized_bounds(&"experience_medium").size.length()
			< Recipes.normalized_bounds(&"experience_large").size.length(),
		"experience shard tiers grow monotonically"
	)
	for facility_id in EXPECTED_FACILITIES:
		_expect(
			Recipes.category(facility_id) == &"facility"
				and Recipes.signature(facility_id).size() >= 1,
			"%s exposes a shape-first facility signature" % facility_id
		)
	for pad_id in [&"repair_field", &"overdrive_field"]:
		var bounds := Recipes.normalized_bounds(pad_id)
		var footprint := Recipes.signature(pad_id)
		_expect(
			String(Recipes.shape_id(pad_id)).begins_with("circular_floor_pad_")
				and footprint.size() == 1
				and PackedVector2Array(footprint[0]).size() == 48
				and is_equal_approx(bounds.size.x, bounds.size.y),
			"%s uses one complete circular floor-pad footprint" % pad_id
		)
	_expect(
		Recipes.shape_id(&"repair_field") != Recipes.shape_id(&"overdrive_field"),
		"shared circular pads retain distinct function insets"
	)
	for recipe_id in Recipes.recipe_ids():
		var roles := Recipes.plane_roles(recipe_id)
		_expect(
			roles.size() >= 3
				and roles.size() <= 5
				and roles.has(&"perimeter")
				and roles.has(&"main_mass"),
			"%s uses the normalized three-to-five-plane contract" % recipe_id
		)


func _expect(condition: bool, message: String) -> void:
	if not condition and _failures.size() < 96:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_REWARD_FACILITY_VISUAL_RECIPES_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
