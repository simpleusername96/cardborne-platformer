class_name TiledRoomBuildCatalog
extends Resource

@export var schema_version := 1
@export var floor_height := 0.2
@export var boundary_height := 0.45
@export var boundary_thickness := 0.3
@export var standard_wall_height := 1.4
@export var cutaway_wall_height := 0.45
@export var low_cover_height := 1.1
@export var surface_albedo: Texture2D
@export var registered_archetypes := PackedStringArray(["low_cover", "wall"])
@export var registered_components := PackedStringArray([
	"waterlogged_crate",
	"pump_station",
	"pressure_vent_inert",
	"pressure_vent",
	"potion_if_low",
	"pressure_node",
])
@export var registered_enemy_roles := PackedStringArray([
	"player",
	"pursuer",
	"shooter",
	"controller",
	"slime_king",
])
@export var registered_objective_roles := PackedStringArray([
	"open_exit",
	"arena_clear",
	"pump_activation",
	"survival_45",
	"boss_defeat",
	"future_reward",
])
