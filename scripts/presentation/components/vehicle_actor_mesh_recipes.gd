class_name VehicleActorMeshRecipes
extends RefCounted

## Approved actor geometry recipes. Catalogs select a recipe; this owner defines
## only layered presentation geometry and never gameplay or collision truth.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const Components = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)

const ORDINARY_GRAMMARS: Array[StringName] = [
	&"solid_chevron",
	&"split_spear",
	&"open_bracket",
	&"twin_prong",
	&"forward_slab",
	&"long_rail",
	&"open_cradle",
	&"service_cross",
]

const PLAYER_COMPONENT_RECIPES: Array[StringName] = [
	&"player_craft_body",
	&"player_engine_flare",
]

const ORDINARY_RECIPES: Array[StringName] = [
	&"swarm_scrap_chevron",
	&"swarm_needle_chevron",
	&"melee_minelet_split",
	&"melee_pursuit_split",
	&"ranged_gunship_bracket",
	&"command_twin_prong",
	&"ranged_turret_bracket",
	&"mine_open_cradle",
	&"generator_open_cradle",
	&"shield_forward_slab",
	&"artillery_long_rail",
	&"interceptor_twin_prong",
	&"rammer_split_spear",
	&"guard_forward_slab",
	&"splitter_chevron",
	&"repair_service_cross",
	&"carrier_open_cradle",
	&"beam_long_rail",
]

const BOSS_RECIPES: Array[StringName] = [
	&"boss_colossus",
	&"boss_leviathan",
	&"boss_titan",
	&"boss_behemoth",
	&"boss_crown",
]

const BOSS_MODULE_RECIPES: Array[StringName] = [
	&"boss_pylon_anchor",
	&"objective_forge_plate",
	&"objective_segment_lock",
	&"objective_relay_positive",
	&"objective_relay_negative",
	&"objective_route_switch",
	&"objective_armor_car",
	&"objective_lattice_outer",
]


static func player_component_layers(recipe_id: StringName) -> Array[Dictionary]:
	match recipe_id:
		&"player_craft_body":
			var outer := player_signature()
			return [
				_layer(outer, Art.INK, &"perimeter"),
				_layer(
					Components.scaled_points(outer, Vector2(0.91, 0.91)),
					Color.WHITE,
					&"main_mass"
				),
				_layer(
					PackedVector2Array([
						Vector2(0.34, -0.42),
						Vector2(-0.10, -0.64),
						Vector2(-0.50, -0.52),
						Vector2(-0.34, -0.28),
						Vector2(-0.15, -0.16),
						Vector2(-0.15, 0.16),
						Vector2(-0.34, 0.28),
						Vector2(-0.50, 0.52),
						Vector2(-0.10, 0.64),
						Vector2(0.34, 0.42),
						Vector2(0.12, 0.30),
						Vector2(0.02, 0.0),
						Vector2(0.12, -0.30),
					]),
					Color(0.72, 0.68, 0.58, 1.0),
					&"secondary_mass"
				),
				_layer(
					PackedVector2Array([
						Vector2(0.82, 0.0),
						Vector2(0.48, -0.095),
						Vector2(-0.30, -0.11),
						Vector2(-0.55, 0.0),
						Vector2(-0.30, 0.11),
						Vector2(0.48, 0.095),
					]),
					Art.TEXT_PRIMARY,
					&"center_spine"
				),
				_layer(
					PackedVector2Array([
						Vector2(0.38, -0.065),
						Vector2(-0.18, -0.075),
						Vector2(-0.38, 0.0),
						Vector2(-0.18, 0.075),
						Vector2(0.38, 0.065),
					]),
					Art.WORLD_CANVAS,
					&"rear_socket"
				),
			]
		&"player_engine_flare":
			return [
				_layer(
					PackedVector2Array([
						Vector2(0.34, -0.50),
						Vector2(0.34, 0.50),
						Vector2(-1.0, 0.20),
						Vector2(-0.72, 0.0),
						Vector2(-1.0, -0.20),
					]),
					Color.WHITE,
					&"thrust"
				),
				_layer(
					PackedVector2Array([
						Vector2(0.28, -0.22),
						Vector2(0.28, 0.22),
						Vector2(-0.72, 0.08),
						Vector2(-0.54, 0.0),
						Vector2(-0.72, -0.08),
					]),
					Art.TEXT_PRIMARY,
					&"thrust_core"
				),
			]
	return []


static func player_signature() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(1.00, 0.00),
		Vector2(0.58, -0.22),
		Vector2(0.26, -0.52),
		Vector2(-0.20, -0.76),
		Vector2(-0.58, -0.70),
		Vector2(-0.72, -0.48),
		Vector2(-0.66, -0.27),
		Vector2(-0.90, -0.22),
		Vector2(-0.90, -0.04),
		Vector2(-0.54, -0.03),
		Vector2(-0.48, 0.00),
		Vector2(-0.54, 0.03),
		Vector2(-0.90, 0.04),
		Vector2(-0.90, 0.22),
		Vector2(-0.66, 0.27),
		Vector2(-0.72, 0.48),
		Vector2(-0.58, 0.70),
		Vector2(-0.20, 0.76),
		Vector2(0.26, 0.52),
		Vector2(0.58, 0.22),
	])


static func enemy_layers(
	recipe_id: StringName,
	grammar_id: StringName
) -> Array[Dictionary]:
	if recipe_id not in ORDINARY_RECIPES and recipe_id != &"boss_pylon_anchor":
		return []
	var outer := enemy_signature(recipe_id)
	if outer.is_empty():
		return []
	if grammar_id == &"twin_prong":
		return _twin_prong_layers(recipe_id)
	var secondary := _enemy_secondary(grammar_id)
	var accent := _enemy_accent(grammar_id)
	var highlight := _enemy_highlight(grammar_id)
	return [
		_layer(outer, Art.INK, &"perimeter"),
		_layer(
			Components.scaled_points(outer, Vector2(0.90, 0.88)),
			Color(0.88, 0.88, 0.90, 1.0),
			&"main_mass"
		),
		_layer(secondary, Color(0.58, 0.60, 0.64, 1.0), &"secondary_mass"),
		_layer(accent, _enemy_accent_color(grammar_id), &"function_inset"),
		_layer(highlight, Color.WHITE, &"hard_highlight"),
	]


static func enemy_signature(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"swarm_scrap_chevron":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.12, -0.58),
				Vector2(-0.68, -0.46), Vector2(-0.92, 0.0),
				Vector2(-0.58, 0.56), Vector2(0.18, 0.48),
			])
		&"swarm_needle_chevron":
			return PackedVector2Array([
				Vector2(1.18, 0.0), Vector2(0.18, -0.38),
				Vector2(-0.78, -0.62), Vector2(-0.48, 0.0),
				Vector2(-0.72, 0.58), Vector2(0.22, 0.34),
			])
		&"melee_minelet_split":
			return PackedVector2Array([
				Vector2(1.0, -0.24), Vector2(0.18, -0.72),
				Vector2(-0.72, -0.48), Vector2(-0.42, -0.06),
				Vector2(0.20, 0.0), Vector2(-0.42, 0.06),
				Vector2(-0.72, 0.48), Vector2(0.18, 0.72),
				Vector2(1.0, 0.24), Vector2(0.48, 0.08),
				Vector2(0.48, -0.08),
			])
		&"melee_pursuit_split":
			return PackedVector2Array([
				Vector2(1.18, -0.12), Vector2(0.24, -0.74),
				Vector2(-0.70, -0.50), Vector2(-0.42, -0.08),
				Vector2(0.32, 0.0), Vector2(-0.42, 0.08),
				Vector2(-0.68, 0.58), Vector2(0.24, 0.82),
				Vector2(1.08, 0.18), Vector2(0.52, 0.05),
				Vector2(0.52, -0.05),
			])
		&"ranged_gunship_bracket":
			return PackedVector2Array([
				Vector2(1.12, -0.66), Vector2(0.46, -0.78),
				Vector2(-0.70, -0.58), Vector2(-0.92, -0.28),
				Vector2(-0.92, 0.28), Vector2(-0.70, 0.58),
				Vector2(0.46, 0.78), Vector2(1.12, 0.66),
				Vector2(0.92, 0.34), Vector2(0.10, 0.30),
				Vector2(-0.26, 0.0), Vector2(0.10, -0.30),
				Vector2(0.92, -0.34),
			])
		&"command_twin_prong":
			return PackedVector2Array([
				Vector2(1.08, -0.62), Vector2(0.42, -0.86),
				Vector2(-0.54, -0.66), Vector2(-0.82, -0.28),
				Vector2(-0.24, -0.12), Vector2(-0.24, 0.12),
				Vector2(-0.78, 0.30), Vector2(-0.50, 0.68),
				Vector2(0.38, 0.88), Vector2(1.06, 0.60),
				Vector2(0.46, 0.24), Vector2(0.10, 0.0),
				Vector2(0.48, -0.24),
			])
		&"ranged_turret_bracket":
			return PackedVector2Array([
				Vector2(1.18, -0.42), Vector2(0.48, -0.42),
				Vector2(0.48, -0.66), Vector2(-0.62, -0.66),
				Vector2(-0.94, -0.34), Vector2(-0.94, 0.34),
				Vector2(-0.62, 0.66), Vector2(0.48, 0.66),
				Vector2(0.48, 0.42), Vector2(1.18, 0.42),
				Vector2(0.94, 0.18), Vector2(0.10, 0.18),
				Vector2(-0.06, 0.0), Vector2(0.10, -0.18),
				Vector2(0.94, -0.18),
			])
		&"mine_open_cradle":
			return PackedVector2Array([
				Vector2(0.98, -0.28), Vector2(0.56, -0.68),
				Vector2(-0.20, -0.86), Vector2(-0.82, -0.48),
				Vector2(-0.88, 0.40), Vector2(-0.22, 0.84),
				Vector2(0.54, 0.68), Vector2(1.0, 0.28),
				Vector2(0.62, 0.16), Vector2(0.06, 0.20),
				Vector2(-0.34, 0.0), Vector2(0.06, -0.20),
				Vector2(0.62, -0.16),
			])
		&"generator_open_cradle":
			return PackedVector2Array([
				Vector2(1.0, -0.48), Vector2(0.52, -0.84),
				Vector2(-0.48, -0.82), Vector2(-0.94, -0.38),
				Vector2(-0.94, 0.38), Vector2(-0.48, 0.82),
				Vector2(0.52, 0.84), Vector2(1.0, 0.48),
				Vector2(0.66, 0.24), Vector2(0.02, 0.26),
				Vector2(-0.36, 0.0), Vector2(0.02, -0.26),
				Vector2(0.66, -0.24),
			])
		&"shield_forward_slab":
			return PackedVector2Array([
				Vector2(1.10, -0.65), Vector2(0.88, -0.88),
				Vector2(-0.20, -0.86), Vector2(-0.80, -0.54),
				Vector2(-0.94, -0.18), Vector2(-0.94, 0.34),
				Vector2(-0.48, 0.78), Vector2(0.62, 0.86),
				Vector2(1.10, 0.62),
			])
		&"artillery_long_rail":
			return PackedVector2Array([
				Vector2(1.38, -0.12), Vector2(0.58, -0.22),
				Vector2(0.24, -0.42), Vector2(-0.72, -0.56),
				Vector2(-1.0, -0.34), Vector2(-0.84, 0.0),
				Vector2(-1.0, 0.34), Vector2(-0.72, 0.56),
				Vector2(0.24, 0.42), Vector2(0.58, 0.22),
				Vector2(1.38, 0.12),
			])
		&"interceptor_twin_prong":
			return PackedVector2Array([
				Vector2(1.16, -0.22), Vector2(0.42, -0.70),
				Vector2(0.08, -0.92), Vector2(-0.42, -0.62),
				Vector2(-0.82, -0.12), Vector2(-0.24, 0.0),
				Vector2(-0.82, 0.10), Vector2(-0.36, 0.56),
				Vector2(0.02, 0.94), Vector2(0.46, 0.66),
				Vector2(1.12, 0.20), Vector2(0.46, 0.08),
				Vector2(0.46, -0.08),
			])
		&"rammer_split_spear":
			return PackedVector2Array([
				Vector2(1.30, -0.14), Vector2(0.36, -0.82),
				Vector2(-0.54, -0.88), Vector2(-0.94, -0.34),
				Vector2(-0.34, -0.06), Vector2(0.34, 0.0),
				Vector2(-0.34, 0.06), Vector2(-0.86, 0.48),
				Vector2(-0.26, 0.90), Vector2(0.52, 0.72),
				Vector2(1.22, 0.18), Vector2(0.56, 0.05),
				Vector2(0.56, -0.05),
			])
		&"guard_forward_slab":
			return PackedVector2Array([
				Vector2(1.14, -0.72), Vector2(0.82, -0.94),
				Vector2(-0.46, -0.84), Vector2(-1.02, -0.38),
				Vector2(-1.02, 0.28), Vector2(-0.56, 0.82),
				Vector2(0.70, 0.92), Vector2(1.14, 0.66),
			])
		&"splitter_chevron":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.36, -0.52),
				Vector2(-0.18, -0.88), Vector2(-0.84, -0.48),
				Vector2(-0.48, 0.0), Vector2(-0.90, 0.32),
				Vector2(-0.28, 0.90), Vector2(0.40, 0.58),
			])
		&"repair_service_cross":
			return PackedVector2Array([
				Vector2(0.36, -1.0), Vector2(-0.28, -1.0),
				Vector2(-0.40, -0.56), Vector2(-0.76, -0.60),
				Vector2(-1.0, -0.30), Vector2(-1.0, 0.30),
				Vector2(-0.60, 0.44), Vector2(-0.62, 0.76),
				Vector2(-0.30, 1.0), Vector2(0.30, 1.0),
				Vector2(0.46, 0.62), Vector2(0.78, 0.58),
				Vector2(1.0, 0.28), Vector2(1.0, -0.28),
				Vector2(0.62, -0.44), Vector2(0.60, -0.78),
			])
		&"carrier_open_cradle":
			return PackedVector2Array([
				Vector2(1.12, -0.58), Vector2(0.56, -0.78),
				Vector2(-0.84, -0.74), Vector2(-1.06, -0.36),
				Vector2(-1.06, 0.36), Vector2(-0.84, 0.74),
				Vector2(0.56, 0.78), Vector2(1.12, 0.58),
				Vector2(0.74, 0.30), Vector2(0.12, 0.28),
				Vector2(-0.30, 0.0), Vector2(0.12, -0.28),
				Vector2(0.74, -0.30),
			])
		&"beam_long_rail":
			return PackedVector2Array([
				Vector2(1.42, -0.10), Vector2(0.40, -0.34),
				Vector2(-0.46, -0.48), Vector2(-1.04, -0.22),
				Vector2(-0.82, 0.0), Vector2(-1.04, 0.22),
				Vector2(-0.46, 0.48), Vector2(0.40, 0.34),
				Vector2(1.42, 0.10), Vector2(0.56, 0.0),
			])
		&"boss_pylon_anchor":
			return PackedVector2Array([
				Vector2(1.0, -0.20), Vector2(0.42, -0.28),
				Vector2(0.30, -0.92), Vector2(-0.26, -1.0),
				Vector2(-0.38, -0.28), Vector2(-0.96, -0.18),
				Vector2(-1.0, 0.34), Vector2(-0.32, 0.28),
				Vector2(-0.20, 0.92), Vector2(0.34, 0.82),
				Vector2(0.40, 0.24), Vector2(0.96, 0.30),
			])
	return PackedVector2Array()


static func boss_layers(recipe_id: StringName) -> Array[Dictionary]:
	if recipe_id not in BOSS_RECIPES:
		return []
	var outer := boss_signature(recipe_id)
	var layers: Array[Dictionary] = [
		_layer(outer, Art.INK, &"perimeter"),
		_layer(
			Components.scaled_points(outer, Vector2(0.92, 0.88)),
			Color(0.90, 0.90, 0.92, 1.0),
			&"main_mass"
		),
		_layer(_boss_offset_plane(recipe_id), Color(0.62, 0.48, 0.58, 1.0), &"offset_module"),
		_layer(_boss_channel(recipe_id), Art.WORLD_CANVAS, &"vulnerable_channel"),
		_layer(_boss_socket(recipe_id), Color.WHITE, &"objective_socket"),
	]
	for module in _boss_detached_modules(recipe_id):
		layers.append(_layer(module, Art.INK, &"perimeter"))
		layers.append(
			_layer(
				_scale_about_centroid(module, Vector2(0.72, 0.72)),
				Color(0.62, 0.48, 0.58, 1.0),
				&"offset_module"
			)
		)
	return layers


static func boss_signature(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"boss_colossus":
			return PackedVector2Array([
				Vector2(1.30, -0.12), Vector2(0.82, -0.30),
				Vector2(0.70, -0.58), Vector2(0.15, -0.60),
				Vector2(-0.12, -0.82), Vector2(-0.88, -0.66),
				Vector2(-1.18, -0.30), Vector2(-0.94, -0.04),
				Vector2(-1.24, 0.20), Vector2(-0.82, 0.66),
				Vector2(-0.18, 0.72), Vector2(0.08, 0.54),
				Vector2(0.58, 0.62), Vector2(0.82, 0.30),
				Vector2(1.30, 0.16),
			])
		&"boss_leviathan":
			return PackedVector2Array([
				Vector2(1.30, -0.08), Vector2(0.82, -0.26),
				Vector2(0.46, -0.54), Vector2(-0.38, -0.64),
				Vector2(-1.22, -0.42), Vector2(-1.02, -0.10),
				Vector2(-1.30, 0.12), Vector2(-0.92, 0.50),
				Vector2(-0.22, 0.76), Vector2(0.12, 0.56),
				Vector2(0.72, 0.48), Vector2(1.24, 0.18),
			])
		&"boss_titan":
			return PackedVector2Array([
				Vector2(1.32, -0.34), Vector2(0.92, -0.58),
				Vector2(0.10, -0.62), Vector2(-0.18, -0.78),
				Vector2(-1.08, -0.66), Vector2(-1.28, -0.26),
				Vector2(-1.12, 0.08), Vector2(-1.24, 0.52),
				Vector2(-0.36, 0.72), Vector2(0.04, 0.56),
				Vector2(0.80, 0.62), Vector2(1.28, 0.28),
			])
		&"boss_behemoth":
			return PackedVector2Array([
				Vector2(1.26, -0.16), Vector2(0.72, -0.54),
				Vector2(0.24, -0.76), Vector2(-0.50, -0.72),
				Vector2(-1.16, -0.36), Vector2(-0.98, -0.04),
				Vector2(-1.24, 0.28), Vector2(-0.72, 0.70),
				Vector2(0.04, 0.64), Vector2(0.42, 0.48),
				Vector2(0.94, 0.52), Vector2(1.30, 0.20),
			])
		&"boss_crown":
			return PackedVector2Array([
				Vector2(1.28, -0.04), Vector2(0.70, -0.26),
				Vector2(0.66, -0.62), Vector2(0.16, -0.48),
				Vector2(-0.04, -0.80), Vector2(-0.72, -0.60),
				Vector2(-1.20, -0.22), Vector2(-0.96, 0.06),
				Vector2(-1.26, 0.34), Vector2(-0.62, 0.70),
				Vector2(-0.12, 0.56), Vector2(0.18, 0.78),
				Vector2(0.48, 0.46), Vector2(0.98, 0.36),
			])
	return PackedVector2Array()


static func boss_module_layers(
	recipe_id: StringName,
	state: StringName
) -> Array[Dictionary]:
	if recipe_id not in BOSS_MODULE_RECIPES:
		return []
	var outer := boss_module_signature(recipe_id)
	var cue := Art.PLAYER_REWARD if state == &"active" else Art.TEXT_MUTED
	return [
		_layer(outer, Art.INK, &"perimeter"),
		_layer(
			Components.scaled_points(outer, Vector2(0.88, 0.88)),
			Art.BOSS_COMMAND,
			&"main_mass"
		),
		_layer(_boss_module_inset(recipe_id), Art.WORLD_CANVAS, &"function_inset"),
		_layer(_boss_module_cue(recipe_id), cue, &"state_cue"),
	]


static func boss_module_signature(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"boss_pylon_anchor":
			return enemy_signature(recipe_id)
		&"objective_forge_plate":
			return PackedVector2Array([
				Vector2(0.92, -0.54), Vector2(1.0, -0.28),
				Vector2(0.82, 0.62), Vector2(-0.62, 0.70),
				Vector2(-1.0, 0.28), Vector2(-0.88, -0.58),
			])
		&"objective_segment_lock":
			return PackedVector2Array([
				Vector2(1.0, 0.0), Vector2(0.18, -0.68),
				Vector2(-0.82, -0.54), Vector2(-0.42, 0.0),
				Vector2(-0.68, 0.72), Vector2(0.30, 0.56),
			])
		&"objective_relay_positive":
			return PackedVector2Array([
				Vector2(0.22, -1.0), Vector2(-0.22, -1.0),
				Vector2(-0.22, -0.26), Vector2(-0.94, -0.26),
				Vector2(-0.94, 0.22), Vector2(-0.18, 0.22),
				Vector2(-0.18, 0.90), Vector2(0.30, 0.90),
				Vector2(0.30, 0.20), Vector2(1.0, 0.20),
				Vector2(1.0, -0.30), Vector2(0.22, -0.30),
			])
		&"objective_relay_negative":
			return PackedVector2Array([
				Vector2(0.94, -0.30), Vector2(0.72, -0.54),
				Vector2(-0.88, -0.46), Vector2(-1.0, -0.12),
				Vector2(-0.82, 0.42), Vector2(0.84, 0.50),
				Vector2(1.0, 0.16),
			])
		&"objective_route_switch":
			return PackedVector2Array([
				Vector2(1.0, -0.62), Vector2(0.34, -0.70),
				Vector2(-0.08, -0.16), Vector2(-0.92, -0.18),
				Vector2(-1.0, 0.30), Vector2(-0.02, 0.28),
				Vector2(0.42, 0.78), Vector2(0.98, 0.58),
				Vector2(0.36, 0.0),
			])
		&"objective_armor_car":
			return PackedVector2Array([
				Vector2(0.84, -0.82), Vector2(0.24, -0.94),
				Vector2(0.12, -0.30), Vector2(-0.42, -0.28),
				Vector2(-0.56, -0.76), Vector2(-0.98, -0.56),
				Vector2(-0.82, 0.70), Vector2(-0.20, 0.88),
				Vector2(-0.08, 0.26), Vector2(0.48, 0.32),
				Vector2(0.58, 0.82), Vector2(1.0, 0.60),
			])
		&"objective_lattice_outer":
			return PackedVector2Array([
				Vector2(0.98, -0.62), Vector2(0.24, -0.88),
				Vector2(-0.72, -0.66), Vector2(-1.0, -0.20),
				Vector2(-0.90, 0.48), Vector2(-0.18, 0.84),
				Vector2(0.92, 0.58), Vector2(0.58, 0.18),
				Vector2(-0.18, 0.32), Vector2(-0.48, 0.0),
				Vector2(-0.12, -0.34), Vector2(0.60, -0.20),
			])
	return PackedVector2Array()


static func plane_count(layers: Array[Dictionary]) -> int:
	var planes := {}
	for layer in layers:
		planes[StringName(layer.get("plane", &""))] = true
	planes.erase(&"")
	return planes.size()


static func _twin_prong_layers(recipe_id: StringName) -> Array[Dictionary]:
	var prongs := _twin_prong_polygons(recipe_id)
	if prongs.is_empty():
		return []
	var layers: Array[Dictionary] = []
	for prong in prongs:
		layers.append(_layer(prong, Art.INK, &"perimeter"))
		layers.append(
			_layer(
				_scale_about_centroid(prong, Vector2(0.84, 0.78)),
				Color(0.88, 0.88, 0.90, 1.0),
				&"main_mass"
			)
		)
	for facet in _twin_prong_facets(recipe_id):
		layers.append(
			_layer(
				facet,
				Color(0.58, 0.60, 0.64, 1.0),
				&"secondary_mass"
			)
		)
	var core := _twin_prong_core(recipe_id)
	layers.append(_layer(core, Art.INK, &"perimeter"))
	layers.append(
		_layer(
			_scale_about_centroid(core, Vector2(0.74, 0.74)),
			Color(0.70, 0.72, 0.76, 1.0),
			&"function_inset"
		)
	)
	layers.append(
		_layer(
			Components.rect_points(
				Vector2(-0.02, -0.08),
				Vector2(0.075, 0.055)
			),
			Color.WHITE,
			&"hard_highlight"
		)
	)
	return layers


static func _twin_prong_polygons(
	recipe_id: StringName
) -> Array[PackedVector2Array]:
	match recipe_id:
		&"command_twin_prong":
			return [
				PackedVector2Array([
					Vector2(-0.72, -0.28), Vector2(-0.54, -0.64),
					Vector2(0.42, -0.86), Vector2(1.08, -0.62),
					Vector2(0.84, -0.34), Vector2(0.18, -0.22),
					Vector2(-0.18, -0.12),
				]),
				PackedVector2Array([
					Vector2(-0.70, 0.30), Vector2(-0.50, 0.68),
					Vector2(0.38, 0.88), Vector2(1.06, 0.60),
					Vector2(0.82, 0.34), Vector2(0.16, 0.22),
					Vector2(-0.20, 0.12),
				]),
			]
		&"interceptor_twin_prong":
			return [
				PackedVector2Array([
					Vector2(-0.82, -0.12), Vector2(-0.42, -0.62),
					Vector2(0.08, -0.92), Vector2(0.42, -0.70),
					Vector2(1.16, -0.22), Vector2(0.48, -0.28),
					Vector2(0.12, -0.18),
				]),
				PackedVector2Array([
					Vector2(-0.82, 0.10), Vector2(-0.36, 0.56),
					Vector2(0.02, 0.94), Vector2(0.46, 0.66),
					Vector2(1.12, 0.20), Vector2(0.46, 0.26),
					Vector2(0.08, 0.18),
				]),
			]
	return []


static func _twin_prong_facets(
	recipe_id: StringName
) -> Array[PackedVector2Array]:
	if recipe_id == &"command_twin_prong":
		return [
			PackedVector2Array([
				Vector2(-0.42, -0.38), Vector2(0.32, -0.70),
				Vector2(0.74, -0.56), Vector2(0.12, -0.34),
			]),
			PackedVector2Array([
				Vector2(-0.38, 0.40), Vector2(0.28, 0.72),
				Vector2(0.72, 0.54), Vector2(0.10, 0.34),
			]),
		]
	return [
		PackedVector2Array([
			Vector2(-0.28, -0.52), Vector2(0.08, -0.78),
				Vector2(0.68, -0.36), Vector2(0.18, -0.30),
		]),
		PackedVector2Array([
			Vector2(-0.26, 0.48), Vector2(0.02, 0.80),
				Vector2(0.66, 0.34), Vector2(0.16, 0.28),
		]),
	]


static func _twin_prong_core(recipe_id: StringName) -> PackedVector2Array:
	if recipe_id == &"interceptor_twin_prong":
		return PackedVector2Array([
			Vector2(0.30, 0.0), Vector2(0.0, -0.28),
				Vector2(-0.30, 0.0), Vector2(0.0, 0.28),
		])
	return _regular_polygon(Vector2(-0.02, 0.0), 0.34, 6, PI / 6.0)


static func _enemy_secondary(grammar_id: StringName) -> PackedVector2Array:
	match grammar_id:
		&"solid_chevron":
			return PackedVector2Array([
				Vector2(0.48, -0.02), Vector2(-0.16, -0.34),
				Vector2(-0.64, -0.30), Vector2(-0.28, -0.02),
			])
		&"split_spear":
			return PackedVector2Array([
				Vector2(0.84, -0.16), Vector2(0.08, -0.58),
				Vector2(-0.48, -0.42), Vector2(-0.16, -0.12),
			])
		&"open_bracket":
			return PackedVector2Array([
				Vector2(0.84, -0.52), Vector2(0.28, -0.64),
				Vector2(-0.58, -0.44), Vector2(-0.42, -0.26),
				Vector2(0.50, -0.30),
			])
		&"forward_slab":
			return PackedVector2Array([
				Vector2(1.0, -0.56), Vector2(0.58, -0.70),
				Vector2(0.58, 0.70), Vector2(1.0, 0.56),
			])
		&"long_rail":
			return PackedVector2Array([
				Vector2(1.08, -0.16), Vector2(-0.30, -0.24),
				Vector2(-0.62, -0.06), Vector2(-0.62, 0.06),
				Vector2(-0.30, 0.24), Vector2(1.08, 0.16),
			])
		&"open_cradle":
			return PackedVector2Array([
				Vector2(0.52, -0.56), Vector2(-0.34, -0.66),
				Vector2(-0.72, -0.36), Vector2(-0.42, -0.18),
				Vector2(0.24, -0.26),
			])
		&"service_cross":
			return PackedVector2Array([
				Vector2(0.22, -0.62), Vector2(-0.18, -0.62),
				Vector2(-0.20, 0.56), Vector2(0.24, 0.56),
			])
		&"objective_anchor":
			return PackedVector2Array([
				Vector2(0.52, -0.20), Vector2(-0.42, -0.28),
				Vector2(-0.50, 0.20), Vector2(0.42, 0.30),
			])
	return PackedVector2Array()


static func _enemy_accent(grammar_id: StringName) -> PackedVector2Array:
	match grammar_id:
		&"solid_chevron":
			return PackedVector2Array([
				Vector2(0.26, 0.0), Vector2(-0.06, -0.15),
				Vector2(-0.34, 0.0), Vector2(-0.06, 0.15),
			])
		&"split_spear":
			return PackedVector2Array([
				Vector2(0.76, -0.07), Vector2(0.16, -0.14),
				Vector2(-0.42, -0.05), Vector2(-0.58, 0.0),
				Vector2(-0.40, 0.05), Vector2(0.16, 0.14),
				Vector2(0.76, 0.07), Vector2(0.44, 0.0),
			])
		&"open_bracket":
			return PackedVector2Array([
				Vector2(1.02, -0.24), Vector2(0.14, -0.20),
					Vector2(-0.34, 0.0), Vector2(0.14, 0.20),
				Vector2(1.02, 0.24), Vector2(0.78, 0.0),
			])
		&"forward_slab":
			return Components.rect_points(Vector2(0.72, 0.0), Vector2(0.16, 0.42))
		&"long_rail":
			return Components.rect_points(Vector2(0.38, 0.0), Vector2(0.70, 0.075))
		&"open_cradle":
			return PackedVector2Array([
				Vector2(0.90, -0.18), Vector2(0.12, -0.22),
				Vector2(-0.40, 0.0), Vector2(0.12, 0.22),
				Vector2(0.90, 0.18), Vector2(0.58, 0.0),
			])
		&"service_cross":
			return PackedVector2Array([
				Vector2(0.18, -0.18), Vector2(0.18, -0.48),
				Vector2(-0.18, -0.48), Vector2(-0.18, -0.18),
				Vector2(-0.48, -0.18), Vector2(-0.48, 0.18),
				Vector2(-0.18, 0.18), Vector2(-0.18, 0.48),
				Vector2(0.18, 0.48), Vector2(0.18, 0.18),
				Vector2(0.48, 0.18), Vector2(0.48, -0.18),
			])
		&"objective_anchor":
			return _regular_polygon(Vector2.ZERO, 0.30, 6, PI / 6.0)
	return PackedVector2Array()


static func _enemy_accent_color(grammar_id: StringName) -> Color:
	if grammar_id == &"solid_chevron":
		return Color(0.42, 0.44, 0.48, 1.0)
	return Art.WORLD_CANVAS


static func _enemy_highlight(grammar_id: StringName) -> PackedVector2Array:
	match grammar_id:
		&"solid_chevron":
			return Components.rect_points(Vector2(0.08, 0.0), Vector2(0.06, 0.17))
		&"split_spear":
			return PackedVector2Array([
				Vector2(0.12, -0.10), Vector2(0.22, 0.0),
				Vector2(0.10, 0.10), Vector2(-0.02, 0.0),
			])
		&"open_bracket":
			return Components.rect_points(Vector2(-0.30, -0.10), Vector2(0.10, 0.06))
		&"long_rail":
			return Components.rect_points(Vector2(-0.20, -0.13), Vector2(0.15, 0.055))
		&"forward_slab":
			return Components.rect_points(Vector2(0.78, -0.34), Vector2(0.09, 0.14))
		&"open_cradle":
			return PackedVector2Array([
				Vector2(0.80, -0.28), Vector2(0.56, -0.34),
				Vector2(0.48, -0.24), Vector2(0.72, -0.20),
			])
		&"service_cross":
			return Components.rect_points(Vector2(0.36, -0.28), Vector2(0.13, 0.06))
		_:
			return PackedVector2Array([
				Vector2(0.52, -0.16), Vector2(0.18, -0.28),
				Vector2(0.02, -0.19), Vector2(0.38, -0.09),
			])


static func _boss_offset_plane(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"boss_colossus":
			return PackedVector2Array([
				Vector2(0.78, -0.24), Vector2(0.56, -0.52),
				Vector2(0.10, -0.52), Vector2(-0.18, -0.72),
				Vector2(-0.76, -0.54), Vector2(-0.38, -0.22),
				Vector2(0.26, -0.14),
			])
		&"boss_leviathan":
			return PackedVector2Array([
				Vector2(0.86, 0.18), Vector2(0.54, 0.42),
				Vector2(-0.18, 0.58), Vector2(-0.72, 0.42),
				Vector2(-0.40, 0.14), Vector2(0.22, 0.04),
			])
		&"boss_titan":
			return PackedVector2Array([
				Vector2(0.72, -0.44), Vector2(0.02, -0.48),
				Vector2(-0.26, -0.64), Vector2(-0.92, -0.54),
				Vector2(-0.74, -0.18), Vector2(0.34, -0.18),
			])
		&"boss_behemoth":
			return PackedVector2Array([
				Vector2(0.74, -0.42), Vector2(0.14, -0.64),
				Vector2(-0.52, -0.58), Vector2(-0.86, -0.32),
				Vector2(-0.28, -0.16), Vector2(0.42, -0.18),
			])
		&"boss_crown":
			return PackedVector2Array([
				Vector2(0.84, 0.10), Vector2(0.44, 0.34),
				Vector2(0.12, 0.66), Vector2(-0.10, 0.44),
				Vector2(-0.56, 0.56), Vector2(-0.82, 0.30),
				Vector2(-0.32, 0.08), Vector2(0.30, -0.02),
			])
	return PackedVector2Array()


static func _boss_channel(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"boss_colossus":
			return PackedVector2Array([
				Vector2(0.98, -0.05), Vector2(0.26, -0.12),
				Vector2(-0.58, -0.06), Vector2(-0.72, 0.04),
				Vector2(-0.54, 0.14), Vector2(0.28, 0.12),
				Vector2(0.98, 0.05),
			])
		&"boss_leviathan":
			return PackedVector2Array([
				Vector2(0.88, 0.18), Vector2(0.54, 0.08),
				Vector2(-0.18, -0.34), Vector2(-0.72, -0.40),
				Vector2(-0.54, -0.24), Vector2(0.18, 0.18),
				Vector2(0.68, 0.32),
			])
		&"boss_titan":
			return PackedVector2Array([
				Vector2(1.02, -0.04), Vector2(0.34, -0.10),
				Vector2(-0.70, -0.08), Vector2(-0.88, 0.02),
				Vector2(-0.68, 0.12), Vector2(0.34, 0.10),
				Vector2(1.02, 0.04),
			])
		&"boss_behemoth":
			return PackedVector2Array([
				Vector2(0.72, -0.12), Vector2(0.18, -0.20),
				Vector2(-0.28, -0.06), Vector2(-0.52, 0.34),
				Vector2(-0.34, 0.42), Vector2(-0.10, 0.08),
				Vector2(0.70, 0.02),
			])
		&"boss_crown":
			return PackedVector2Array([
				Vector2(0.90, 0.12), Vector2(0.34, 0.02),
				Vector2(0.02, -0.32), Vector2(-0.46, -0.38),
				Vector2(-0.30, -0.18), Vector2(0.04, 0.18),
				Vector2(0.76, 0.26),
			])
	return PackedVector2Array()


static func _boss_socket(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"boss_colossus":
			return PackedVector2Array([
				Vector2(0.62, -0.12), Vector2(0.82, -0.04),
					Vector2(0.82, 0.10), Vector2(0.58, 0.16),
				Vector2(0.42, 0.06), Vector2(0.44, -0.08),
			])
		&"boss_leviathan":
			return _regular_polygon(Vector2(0.06, -0.18), 0.19, 4, PI / 4.0)
		&"boss_titan":
			return Components.rect_points(Vector2(0.46, 0.0), Vector2(0.22, 0.10))
		&"boss_behemoth":
			return _regular_polygon(Vector2(-0.22, 0.18), 0.20, 5, -PI / 2.0)
		&"boss_crown":
			return _regular_polygon(Vector2(0.30, -0.24), 0.18, 6, PI / 6.0)
	return PackedVector2Array()


static func _boss_detached_modules(
	recipe_id: StringName
) -> Array[PackedVector2Array]:
	match recipe_id:
		&"boss_colossus":
			return [
				_module_pod(Vector2(-0.82, -0.78), Vector2(0.28, 0.16)),
				_module_pod(Vector2(-0.62, 0.80), Vector2(0.24, 0.15)),
			]
		&"boss_leviathan":
			return [
				_module_pod(Vector2(-1.02, -0.62), Vector2(0.22, 0.14)),
				_module_pod(Vector2(0.58, 0.70), Vector2(0.26, 0.14)),
			]
		&"boss_titan":
			return [
				_module_pod(Vector2(-0.80, -0.78), Vector2(0.30, 0.13)),
				_module_pod(Vector2(-0.52, 0.78), Vector2(0.30, 0.13)),
			]
		&"boss_behemoth":
			return [
				_module_pod(Vector2(-1.02, 0.66), Vector2(0.24, 0.16)),
				_module_pod(Vector2(0.62, -0.76), Vector2(0.22, 0.15)),
			]
		&"boss_crown":
			return [
				_module_pod(Vector2(-0.96, -0.70), Vector2(0.22, 0.15)),
				_module_pod(Vector2(-0.82, 0.72), Vector2(0.24, 0.14)),
			]
	return []


static func _module_pod(
	center: Vector2,
	half_extent: Vector2
) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-half_extent.x, -half_extent.y * 0.45),
		center + Vector2(-half_extent.x * 0.58, -half_extent.y),
		center + Vector2(half_extent.x * 0.62, -half_extent.y),
		center + Vector2(half_extent.x, -half_extent.y * 0.30),
		center + Vector2(half_extent.x, half_extent.y * 0.40),
		center + Vector2(half_extent.x * 0.52, half_extent.y),
		center + Vector2(-half_extent.x * 0.62, half_extent.y),
		center + Vector2(-half_extent.x, half_extent.y * 0.36),
	])


static func _boss_module_inset(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"objective_forge_plate":
			return Components.rect_points(Vector2(-0.08, 0.0), Vector2(0.48, 0.12))
		&"objective_segment_lock":
			return PackedVector2Array([
				Vector2(0.62, 0.0), Vector2(-0.26, -0.30),
				Vector2(-0.08, 0.0), Vector2(-0.26, 0.30),
			])
		&"objective_relay_positive", &"objective_relay_negative":
			return Components.rect_points(Vector2.ZERO, Vector2(0.48, 0.12))
		&"objective_route_switch":
			return PackedVector2Array([
				Vector2(-0.60, -0.08), Vector2(-0.02, -0.08),
				Vector2(0.52, -0.46), Vector2(0.62, -0.30),
				Vector2(0.08, 0.08), Vector2(-0.60, 0.08),
			])
		&"objective_armor_car":
			return Components.rect_points(Vector2(-0.18, 0.0), Vector2(0.13, 0.48))
		&"objective_lattice_outer":
			return PackedVector2Array([
				Vector2(0.56, -0.18), Vector2(0.02, -0.30),
				Vector2(-0.30, 0.0), Vector2(0.02, 0.30),
				Vector2(0.56, 0.18), Vector2(0.30, 0.0),
			])
		_:
			return Components.rect_points(Vector2.ZERO, Vector2(0.30, 0.16))


static func _boss_module_cue(recipe_id: StringName) -> PackedVector2Array:
	match recipe_id:
		&"objective_relay_positive":
			return PackedVector2Array([
				Vector2(0.10, -0.44), Vector2(-0.10, -0.44),
				Vector2(-0.10, -0.10), Vector2(-0.44, -0.10),
				Vector2(-0.44, 0.10), Vector2(-0.10, 0.10),
				Vector2(-0.10, 0.44), Vector2(0.10, 0.44),
				Vector2(0.10, 0.10), Vector2(0.44, 0.10),
				Vector2(0.44, -0.10), Vector2(0.10, -0.10),
			])
		&"objective_relay_negative":
			return Components.rect_points(Vector2.ZERO, Vector2(0.44, 0.09))
		&"objective_armor_car":
			return Components.rect_points(Vector2(0.26, 0.0), Vector2(0.10, 0.46))
		&"objective_lattice_outer":
			return _regular_polygon(Vector2(0.10, 0.0), 0.22, 6, PI / 6.0)
		_:
			return Components.rect_points(Vector2(0.20, 0.0), Vector2(0.24, 0.08))


static func _regular_polygon(
	origin: Vector2,
	radius: float,
	sides: int,
	rotation: float = 0.0
) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in sides:
		points.append(
			origin
			+ Vector2.RIGHT.rotated(
				rotation + TAU * float(index) / float(sides)
			) * radius
		)
	return points


static func _scale_about_centroid(
	points: PackedVector2Array,
	scale: Vector2
) -> PackedVector2Array:
	if points.is_empty():
		return PackedVector2Array()
	var centroid := Vector2.ZERO
	for point in points:
		centroid += point
	centroid /= float(points.size())
	var result := PackedVector2Array()
	for point in points:
		result.append(centroid + (point - centroid) * scale)
	return result


static func _layer(
	points: PackedVector2Array,
	color: Color,
	plane: StringName
) -> Dictionary:
	return {"points": points, "color": color, "plane": plane}
