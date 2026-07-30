class_name VehicleVisualSheetCanvas
extends Control

## Deterministic design-sheet renderer fed by the runtime token and component
## providers. These sheets are inspection views, never runtime texture assets.

const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const ActorCatalog = preload(
	"res://scripts/presentation/components/vehicle_actor_visual_catalog.gd"
)
const ProjectileCatalog = preload(
	"res://scripts/presentation/components/vehicle_projectile_visual_catalog.gd"
)
const RewardCatalog = preload(
	"res://scripts/presentation/components/vehicle_reward_visual_catalog.gd"
)
const EffectCatalog = preload(
	"res://scripts/presentation/components/vehicle_effect_visual_catalog.gd"
)
const WorldCatalog = preload(
	"res://scripts/presentation/components/vehicle_world_visual_catalog.gd"
)
const SurfacePatternCompiler = preload(
	"res://scripts/presentation/vehicle_field_surface_pattern_compiler.gd"
)
const LayoutGenerator = preload(
	"res://scripts/vehicle/vehicle_field_layout_generator.gd"
)
const StageCatalog = preload("res://scripts/vehicle/vehicle_stage_catalog.gd")
const GlyphCatalog = preload(
	"res://scripts/presentation/components/vehicle_ui_glyph_catalog.gd"
)
const UpgradeGlyphRenderer = preload(
	"res://scripts/presentation/components/vehicle_upgrade_glyph_renderer.gd"
)
const RewardFacilityRecipes = preload(
	"res://scripts/presentation/components/vehicle_reward_facility_visual_recipes.gd"
)
const ComponentMeshes = preload(
	"res://scripts/presentation/components/vehicle_component_mesh_library.gd"
)
const Visuals = preload(
	"res://scripts/presentation/vehicle_combat_visual_library.gd"
)
const CombatRenderer = preload(
	"res://scripts/presentation/vehicle_combat_renderer.gd"
)
const EnemyState = preload(
	"res://scripts/enemies/vehicle_enemy_state.gd"
)
const ProjectileState = preload(
	"res://scripts/combat/vehicle_projectile_state.gd"
)
const ExperienceShard = preload(
	"res://scripts/progression/vehicle_experience_shard.gd"
)
const VEHICLE_THEME = preload(
	"res://art/ui/production/vehicle_stage_theme.tres"
)
const GameplayHud = preload("res://scripts/ui/vehicle_gameplay_hud.gd")
const ModalHost = preload("res://scripts/ui/vehicle_modal_host.gd")
const DeploymentPanel = preload(
	"res://scripts/ui/vehicle_deployment_panel.gd"
)
const UpgradePanel = preload(
	"res://scripts/ui/vehicle_upgrade_choice_panel.gd"
)
const PausePanel = preload("res://scripts/ui/vehicle_pause_panel.gd")
const GuidebookPanel = preload(
	"res://scripts/ui/vehicle_guidebook_panel.gd"
)
const SettingsPanel = preload(
	"res://scripts/ui/vehicle_settings_panel.gd"
)
const UpgradeCatalog = preload(
	"res://scripts/cards/vehicle_upgrade_catalog.gd"
)
const UpgradePresenter = preload(
	"res://scripts/cards/vehicle_upgrade_offer_presenter.gd"
)
const StageReportPanel = preload(
	"res://scripts/ui/vehicle_stage_report_panel.gd"
)
const ResultPanel = preload("res://scripts/ui/vehicle_result_panel.gd")
const GaragePanel = preload("res://scripts/ui/vehicle_garage_panel.gd")
const BossPracticePanel = preload(
	"res://scripts/ui/vehicle_boss_practice_panel.gd"
)
const UiFactory = preload(
	"res://scripts/ui/vehicle_ui_component_factory.gd"
)
const FONT_PATH := "res://art/ui/production/fonts/NotoSansKR-Variable.ttf"
const SHEET_LAYOUT_SEED := 0xC4A2B0

const SHEET_TITLES := {
	&"foundation": ["01  FOUNDATION TOKENS", "기본 토큰 · semantic roles · component grammar"],
	&"world_surfaces": ["02  WORLD SURFACES", "deterministic modular tiles · gameplay geometry preserved"],
	&"world_facilities": ["03  WORLD FACILITIES", "기능별 실루엣 · idle / warning / active / cooldown"],
	&"player": ["04  PLAYER COMPONENTS", "compact interceptor · rigid twin engines · independent aim"],
	&"enemies": ["05  ENEMY COMPONENTS", "역할별 외곽선 · target priority before decoration"],
	&"bosses": ["06  BOSS COMPONENTS", "다섯 arena exam · distinct body and objective module"],
	&"projectiles": ["07  PROJECTILE · TELEGRAPH · VFX", "collision-bounded core · affinity tail · directional feedback"],
	&"rewards": ["08  REWARD · UPGRADE GLYPHS", "보상과 위협의 즉시 구분 · shape remains meaningful in grayscale"],
	&"hud": ["09  HUD · MINIMAP MARKERS", "four-zone HUD · sparse center · shared world markers"],
	&"controls": ["10  UI CONTROL STATES", "mechanical frame · semantic state rail · 44 px minimum target"],
	&"modals": ["11  MODAL FLOW CONTACT SHEET", "nine surfaces · compact and wide composition contract"],
	&"pressure": ["12  PRESSURE · ACCESSIBILITY", "1× combat density · grayscale · reduced-motion proof layout"],
}

var sheet_id: StringName = &"foundation"
var _font_body: Font
var _font_strong: Font
var _white_texture: Texture2D
var _retained_draw_meshes: Array[Mesh] = []


func _ready() -> void:
	theme = VEHICLE_THEME
	var base_font := load(FONT_PATH) as Font
	_font_body = _font_variation(base_font, 650.0)
	_font_strong = _font_variation(base_font, 800.0)
	var white_image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	white_image.fill(Color.WHITE)
	_white_texture = ImageTexture.create_from_image(white_image)
	_build_runtime_control_evidence()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Art.SPACE_BLACK)
	_draw_header()
	match sheet_id:
		&"foundation":
			_draw_foundation()
		&"world_surfaces":
			_draw_world_surfaces()
		&"world_facilities":
			_draw_world_facilities()
		&"player":
			_draw_player_components()
		&"enemies":
			_draw_enemy_components()
		&"bosses":
			_draw_boss_components()
		&"projectiles":
			_draw_projectile_components()
		&"rewards":
			_draw_reward_components()
		&"hud":
			_draw_hud_components()
		&"controls":
			_draw_controls()
		&"modals":
			_draw_modal_contact_sheet()
		&"pressure":
			_draw_pressure_accessibility()


func _draw_header() -> void:
	var copy: Array = SHEET_TITLES.get(
		sheet_id,
		["VISUAL SYSTEM", "runtime-backed inspection sheet"]
	)
	_label(Vector2(72.0, 84.0), String(copy[0]), 36, Art.TEXT_PRIMARY)
	_label(Vector2(72.0, 126.0), String(copy[1]), 17, Art.TEXT_MUTED)
	_label(
		Vector2(1520.0, 84.0),
		"Cardborne · GENERAL SF v1",
		14,
		Art.SYSTEM
	)
	draw_line(Vector2(72.0, 154.0), Vector2(1976.0, 154.0), Art.LINE, 1.0)


func _draw_foundation() -> void:
	var roles := Art.required_color_roles()
	var role_order := [
		"space_black", "world_canvas", "surface", "raised", "line",
		"text_primary", "text_muted", "player_reward", "danger", "boss_command",
		"support", "system", "thermal", "toxin", "cryo", "arc",
	]
	for index in role_order.size():
		var column := index % 4
		var row := index / 4
		var rect := Rect2(72.0 + column * 310.0, 190.0 + row * 116.0, 278.0, 88.0)
		_draw_token(rect, role_order[index], Color(roles[role_order[index]]))
	var type_x := 1370.0
	_label(Vector2(type_x, 190.0), "TYPE SCALE / Noto Sans KR", 20, Art.TEXT_PRIMARY)
	var type_labels := ["caption", "body", "label", "section", "title", "display"]
	for index in Art.TYPE_SCALE_WIDE.size():
		var font_size := int(Art.TYPE_SCALE_WIDE[index])
		_label(
			Vector2(type_x, 242.0 + index * 72.0),
			"%s  %d  기체 상태 / SHIP STATUS" % [type_labels[index], font_size],
			font_size,
			Art.TEXT_PRIMARY if index > 1 else Art.TEXT_MUTED
		)
	_label(Vector2(72.0, 734.0), "SPACING", 20, Art.TEXT_PRIMARY)
	var spacing_x := 72.0
	for spacing in Art.SPACING_SCALE:
		draw_rect(Rect2(spacing_x, 774.0, float(spacing) * 4.0, 18.0), Art.SYSTEM)
		_label(Vector2(spacing_x, 826.0), str(spacing), 15, Art.TEXT_MUTED)
		spacing_x += float(spacing) * 4.0 + 34.0
	_label(Vector2(790.0, 734.0), "ROLE GRAMMAR", 20, Art.TEXT_PRIMARY)
	for index in 5:
		var primitives := [
			&"player_interceptor", &"split_spear", &"solid_chevron",
			&"diamond", &"slab",
		]
		var colors := [
			Art.PLAYER_REWARD, Art.DANGER, Art.SUPPORT,
			Art.BOSS_COMMAND, Art.SYSTEM,
		]
		var captions := ["player", "threat", "support", "boss", "system"]
		_draw_primitive(
			Vector2(900.0 + index * 234.0, 864.0),
			primitives[index],
			colors[index],
			58.0
		)
		_label(
			Vector2(836.0 + index * 234.0, 966.0),
			captions[index],
			13,
			Art.TEXT_MUTED
		)
	_footer("Shape + notch + rail pattern carry meaning; color is secondary.")


func _draw_world_surfaces() -> void:
	var fields := [
		{
			"id": &"drowned_ruin_field",
			"name": "FIELD 01 · CENTRAL COURT",
			"accent": Art.SYSTEM,
		},
		{
			"id": &"tidal_archive_field",
			"name": "FIELD 02 · PARALLEL BAYS",
			"accent": Art.SUPPORT,
		},
		{
			"id": &"storm_drydock_field",
			"name": "FIELD 03 · DIAGONAL DOCK",
			"accent": Art.PLAYER_REWARD,
		},
	]
	for index in fields.size():
		var rect := Rect2(72.0 + index * 628.0, 194.0, 580.0, 790.0)
		_draw_field_preview(rect, Dictionary(fields[index]))
		var descriptor := Dictionary(
			WorldCatalog.FIELD_DESCRIPTORS[fields[index]["id"]]
		)
		_label(
			rect.position + Vector2(22.0, rect.size.y - 36.0),
			"service rail ≤ %d · one retained tile batch"
			% int(descriptor["decoration_budget"]),
			13,
			Art.TEXT_MUTED
		)
	_footer("Runtime compiler proof · deterministic tiles change presentation only; geometry and navigation remain gameplay truth.")


func _draw_field_preview(rect: Rect2, field: Dictionary) -> void:
	_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Color(field["accent"]))
	_label(rect.position + Vector2(22.0, 38.0), String(field["name"]), 18, Art.TEXT_PRIMARY)
	var map_slot := Rect2(
		rect.position + Vector2(22.0, 70.0),
		rect.size - Vector2(44.0, 184.0)
	)
	var run_layout := LayoutGenerator.generate(
		SHEET_LAYOUT_SEED,
		StageCatalog.STAGE_IDS,
		StringName(field["id"])
	)
	if run_layout == null:
		_label(map_slot.position + Vector2(18.0, 34.0), "LAYOUT UNAVAILABLE", 15, Art.DANGER)
		return
	var tactical = run_layout.tactical_layout(&"stage_1")
	if tactical == null or tactical.geometry_snapshot == null:
		_label(map_slot.position + Vector2(18.0, 34.0), "SNAPSHOT UNAVAILABLE", 15, Art.DANGER)
		return
	var snapshot = tactical.geometry_snapshot
	var world_rect := Rect2(snapshot.world_rect)
	var map_rect := _fit_rect(world_rect.size, map_slot)
	draw_rect(map_rect, Art.SURFACE)
	var walkable_rects: Array[Rect2] = []
	walkable_rects.assign(snapshot.walkable_rects)
	var void_rects: Array[Rect2] = []
	void_rects.assign(snapshot.void_rects)
	var cover_rects: Array[Rect2] = []
	cover_rects.assign(tactical.cover_rects)
	var pattern := SurfacePatternCompiler.compile(
		StringName(field["id"]),
		tactical.fingerprint,
		walkable_rects,
		void_rects,
		cover_rects,
		snapshot.player_start
	)
	for layer_value in Array(pattern.get("layers", [])):
		var layer := Dictionary(layer_value)
		var transformed := PackedVector2Array()
		for point in PackedVector2Array(layer.get("points", PackedVector2Array())):
			transformed.append(
				_map_world_point(point, world_rect, map_rect)
			)
		if transformed.size() >= 3:
			draw_colored_polygon(
				transformed,
				Color(layer.get("color", Art.RAISED))
			)
	for void_rect in void_rects:
		draw_rect(_map_world_rect(void_rect, world_rect, map_rect), Art.SPACE_BLACK)
	for cover_rect in cover_rects:
		var preview_cover := _map_world_rect(
			cover_rect,
			world_rect,
			map_rect
		)
		draw_rect(
			Rect2(preview_cover.position + Vector2(1.0, 1.5), preview_cover.size),
			Color(Art.SPACE_BLACK, 0.86)
		)
		draw_rect(preview_cover, Art.RAISED)
		draw_rect(preview_cover, Art.LINE, false, 1.0)
	draw_rect(map_rect, Art.LINE, false, 2.0)
	_draw_world_marker(
		_map_world_point(snapshot.player_start, world_rect, map_rect),
		&"player",
		0.56
	)
	_label(
		rect.position + Vector2(22.0, rect.size.y - 88.0),
		"%d MODULES · 288 GRID · %s"
		% [
			int(pattern.get("module_count", 0)),
			String(pattern.get("fingerprint", "")).substr(0, 10),
		],
		13,
		Art.TEXT_PRIMARY
	)


func _fit_rect(source_size: Vector2, target: Rect2) -> Rect2:
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return target
	var scale_value := minf(
		target.size.x / source_size.x,
		target.size.y / source_size.y
	)
	var fitted_size := source_size * scale_value
	return Rect2(
		target.get_center() - fitted_size * 0.5,
		fitted_size
	)


func _map_world_point(
	point: Vector2,
	world_rect: Rect2,
	preview_rect: Rect2
) -> Vector2:
	var normalized := Vector2(
		(point.x - world_rect.position.x) / maxf(1.0, world_rect.size.x),
		(point.y - world_rect.position.y) / maxf(1.0, world_rect.size.y)
	)
	return preview_rect.position + preview_rect.size * normalized


func _map_world_rect(
	rectangle: Rect2,
	world_rect: Rect2,
	preview_rect: Rect2
) -> Rect2:
	return Rect2(
		_map_world_point(rectangle.position, world_rect, preview_rect),
		Vector2(
			rectangle.size.x / maxf(1.0, world_rect.size.x) * preview_rect.size.x,
			rectangle.size.y / maxf(1.0, world_rect.size.y) * preview_rect.size.y
		)
	)


func _draw_world_facilities() -> void:
	var facilities := [
		[&"repair_field", "REPAIR / 수리", Art.SUPPORT],
		[&"transit_gate", "TRANSIT / 이동", Art.SYSTEM],
		[&"overdrive_field", "OVERDRIVE / 가속", Art.PLAYER_REWARD],
		[&"arc_surge_strip", "ARC SURGE / 전격", Art.ARC],
		[&"breakable_bulkhead", "BULKHEAD / 파괴벽", Art.RAISED],
	]
	var states := ["IDLE", "WARNING", "ACTIVE", "COOLDOWN"]
	for row in facilities.size():
		var y := 206.0 + row * 164.0
		_label(Vector2(72.0, y + 30.0), String(facilities[row][1]), 16, Art.TEXT_PRIMARY)
		for column in states.size():
			var rect := Rect2(400.0 + column * 390.0, y, 350.0, 130.0)
			var alpha: float = [0.58, 0.82, 1.0, 0.28][column]
			_draw_panel(
				rect,
				Art.WORLD_CANVAS,
				Art.LINE,
				Color(facilities[row][2], alpha)
			)
			_draw_facility_glyph(
				rect.get_center() - Vector2(64.0, 0.0),
				StringName(facilities[row][0]),
				Color(facilities[row][2], alpha),
				42.0
			)
			_label(
				rect.position + Vector2(170.0, 55.0),
				states[column],
				14,
				Art.TEXT_PRIMARY if column != 3 else Art.TEXT_MUTED
			)
	_footer("Facility identity never depends on pulse, label, or hue alone.")


func _draw_player_components() -> void:
	var assembly_rect := Rect2(72.0, 194.0, 900.0, 690.0)
	_draw_panel(assembly_rect, Art.WORLD_CANVAS, Art.LINE, Art.PLAYER_REWARD)
	_label(assembly_rect.position + Vector2(24.0, 42.0), "ASSEMBLED / 조립 상태", 20, Art.TEXT_PRIMARY)
	_draw_player_assembly(Vector2(520.0, 535.0), 180.0, Vector2.RIGHT, Vector2.RIGHT.rotated(-0.42), 0.70)
	_draw_measure(
		Vector2(260.0, 800.0),
		Vector2(780.0, 800.0),
		"enlarged inspection view · gameplay 1× appears in MOTION STATES"
	)
	var exploded := Rect2(1010.0, 194.0, 966.0, 390.0)
	_draw_panel(exploded, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(exploded.position + Vector2(24.0, 42.0), "COMPONENT OWNERSHIP", 20, Art.TEXT_PRIMARY)
	_draw_mesh_at(Visuals.player_hull_mesh(), Vector2(1192.0, 390.0), Vector2.ONE * 96.0, 0.0, Art.PLAYER_REWARD)
	_draw_mesh_at(Visuals.player_engine_mesh(), Vector2(1480.0, 340.0), Vector2(44.0, 30.0), 0.0, Art.TEXT_MUTED)
	_draw_mesh_at(Visuals.player_engine_flare_mesh(), Vector2(1480.0, 434.0), Vector2(62.0, 20.0), 0.0, Art.SYSTEM)
	_draw_mesh_at(Visuals.player_primary_mesh(), Vector2(1760.0, 390.0), Vector2(80.0, 30.0), -0.42, Art.PLAYER_REWARD)
	_label(Vector2(1110.0, 536.0), "HULL", 14, Art.TEXT_MUTED)
	_label(Vector2(1400.0, 536.0), "RIGID TWIN ENGINE", 14, Art.TEXT_MUTED)
	_label(Vector2(1680.0, 536.0), "AIM MOUNT", 14, Art.TEXT_MUTED)
	var state_rect := Rect2(1010.0, 622.0, 966.0, 262.0)
	_draw_panel(state_rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(state_rect.position + Vector2(24.0, 40.0), "MOTION STATES", 20, Art.TEXT_PRIMARY)
	var state_names := ["NORMAL", "THRUST", "DASH", "HIT"]
	for index in state_names.size():
		var center := state_rect.position + Vector2(126.0 + index * 230.0, 150.0)
		_draw_player_assembly(
			center,
			48.0,
			Vector2.RIGHT,
			Vector2.RIGHT,
			[0.12, 0.72, 1.0, 0.22][index],
			Art.DANGER if index == 3 else Art.PLAYER_REWARD,
			index == 2
		)
		_label(center + Vector2(-38.0, 88.0), state_names[index], 13, Art.TEXT_MUTED)
	_footer("Engine modules rotate only with the hull; the aim mount rotates only with aim.")


func _draw_enemy_components() -> void:
	var ids := [
		&"scrap_drone", &"needle_drone", &"spark_minelet",
		&"chaser", &"shooter", &"controller",
		&"turret", &"mine", &"generator",
		&"shield_escort", &"artillery_spotter", &"interceptor_tower",
		&"rammer", &"bulkhead_guard", &"splitter_barge",
		&"repair_tender", &"drone_carrier", &"beam_sentinel",
	]
	for index in ids.size():
		var column := index % 6
		var row := index / 6
		var rect := Rect2(72.0 + column * 316.0, 190.0 + row * 288.0, 284.0, 252.0)
		var id := StringName(ids[index])
		var descriptor := ActorCatalog.descriptor(id)
		var role := StringName(descriptor.get("role", &"threat"))
		var color := _role_color(role)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, color)
		_draw_mesh_at(
			Visuals.enemy_mesh(id),
			rect.get_center() - Vector2(0.0, 22.0),
			Vector2.ONE * (54.0 if id not in [&"turret", &"generator"] else 62.0),
			0.0,
			color
		)
		_label(rect.position + Vector2(18.0, 30.0), String(id).to_upper(), 13, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(18.0, 226.0), String(role), 12, Art.TEXT_MUTED)
	_footer("18 role signatures · no role ring · command/support use body modules and shape.")


func _draw_boss_components() -> void:
	var bosses := [
		[&"colossus", "FOUNDRY COLOSSUS", "forge plate", &"forge_plate"],
		[&"leviathan", "ARCHIVE LEVIATHAN", "segment lock", &"segment_lock"],
		[&"titan", "DRYDOCK TITAN", "relay polarity", &"relay_positive"],
		[&"behemoth", "SWITCHYARD BEHEMOTH", "route switch", &"route_switch"],
		[&"crown", "CROWN ENGINE", "lattice command", &"lattice_outer"],
	]
	for index in bosses.size():
		var rect := Rect2(72.0 + index * 380.0, 196.0, 348.0, 730.0)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Art.BOSS_COMMAND)
		_label(rect.position + Vector2(20.0, 36.0), String(bosses[index][1]), 16, Art.TEXT_PRIMARY)
		_draw_mesh_at(
			Visuals.boss_mesh(StringName(bosses[index][0])),
			rect.get_center() - Vector2(0.0, 112.0),
			Vector2.ONE * 118.0,
			0.0,
			Art.BOSS_COMMAND
		)
		_draw_boss_modules(
			rect.get_center() + Vector2(0.0, 86.0),
			StringName(bosses[index][3])
		)
		_label(rect.position + Vector2(20.0, 612.0), "EXAM", 12, Art.TEXT_MUTED)
		_label(rect.position + Vector2(20.0, 642.0), String(bosses[index][2]), 15, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(20.0, 684.0), "P1 → P2 → P3", 13, Art.SYSTEM)
	_footer("Each boss owns a body, an objective module, and a sequential phase read.")


func _draw_projectile_components() -> void:
	var affinities := [
		[&"kinetic", "KINETIC", Art.DANGER],
		[&"thermal", "THERMAL", Art.THERMAL],
		[&"toxin", "TOXIN", Art.TOXIN],
		[&"cryo", "CRYO", Art.CRYO],
		[&"arc", "ARC", Art.ARC],
		[&"hybrid", "HYBRID", Art.TEXT_PRIMARY],
	]
	for index in affinities.size():
		var rect := Rect2(72.0 + (index % 3) * 628.0, 194.0 + (index / 3) * 214.0, 580.0, 178.0)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Color(affinities[index][2]))
		_label(rect.position + Vector2(20.0, 34.0), String(affinities[index][1]), 16, Art.TEXT_PRIMARY)
		_draw_mesh_at(
			Visuals.hostile_projectile_mesh(StringName(affinities[index][0])),
			rect.position + Vector2(310.0, 92.0),
			Vector2(26.0, 18.0),
			0.0,
			Color(affinities[index][2])
		)
		draw_circle(rect.position + Vector2(486.0, 92.0), 10.0, Art.SPACE_BLACK)
		draw_circle(rect.position + Vector2(486.0, 92.0), 6.0, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(430.0, 146.0), "core = hit", 12, Art.TEXT_MUTED)
	_label(Vector2(72.0, 668.0), "TELEGRAPH FOOTPRINTS", 20, Art.TEXT_PRIMARY)
	var telegraphs := [
		"CORRIDOR",
		"ACTIVE BEAM",
		"AREA",
		"SUPPORT",
		"COMMIT / IMPACT",
	]
	for index in telegraphs.size():
		var rect := Rect2(72.0 + index * 380.0, 706.0, 348.0, 276.0)
		_draw_panel(rect, Art.SURFACE, Art.LINE, Art.DANGER)
		_label(
			rect.position + Vector2(18.0, 248.0),
			String(telegraphs[index]),
			13,
			Art.TEXT_MUTED
		)
	_footer("Bright cores stop at collision truth; tails and telegraphs may extend beyond it.")


func _draw_reward_components() -> void:
	var rewards := [
		[&"experience_small", "XP · SMALL", Art.PLAYER_REWARD],
		[&"experience_medium", "XP · MEDIUM", Art.PLAYER_REWARD],
		[&"experience_large", "XP · LARGE", Art.PLAYER_REWARD],
		[&"repair", "REPAIR", Art.SUPPORT],
		[&"experience_recall", "RECALL", Art.SYSTEM],
		[&"reward_crate", "CRATE", Art.PLAYER_REWARD],
	]
	for index in rewards.size():
		var rect := Rect2(72.0 + index * 316.0, 194.0, 284.0, 310.0)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Color(rewards[index][2]))
		_draw_reward_glyph(
			rect.get_center() - Vector2(0.0, 18.0),
			StringName(rewards[index][0]),
			Color(rewards[index][2]),
			70.0
		)
		_label(rect.position + Vector2(18.0, 278.0), String(rewards[index][1]), 13, Art.TEXT_PRIMARY)
	_label(Vector2(72.0, 568.0), "UPGRADE FAMILIES", 20, Art.TEXT_PRIMARY)
	var families := GlyphCatalog.UPGRADE_FAMILY_GLYPHS.keys()
	families.sort_custom(func(a: Variant, b: Variant) -> bool: return String(a) < String(b))
	for index in families.size():
		var family := StringName(families[index])
		var descriptor := GlyphCatalog.upgrade_family_descriptor(family)
		var column := index % 4
		var row := index / 4
		var rect := Rect2(72.0 + column * 474.0, 612.0 + row * 180.0, 442.0, 148.0)
		var color := _semantic_color(StringName(descriptor["color"]))
		_draw_panel(rect, Art.SURFACE, Art.LINE, color)
		UpgradeGlyphRenderer.draw_glyph(
			self,
			family,
			rect.position + Vector2(76.0, 74.0),
			34.0,
			{
				&"accent":color,
				&"perimeter":Art.SPACE_BLACK,
				&"surface":Art.WORLD_CANVAS,
				&"secondary":color.lerp(Art.SPACE_BLACK, 0.34),
				&"highlight":Art.TEXT_PRIMARY,
			}
		)
		_label(rect.position + Vector2(146.0, 70.0), String(family).to_upper(), 15, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(146.0, 100.0), "family glyph", 12, Art.TEXT_MUTED)
	_footer("Rewards use gold/support/system; hostile red never appears on collectible bodies.")


func _draw_hud_components() -> void:
	var screen := Rect2(72.0, 194.0, 1260.0, 790.0)
	_draw_panel(screen, Art.WORLD_CANVAS, Art.LINE, Art.SYSTEM)
	_draw_mock_combat_field(screen.grow(-1.0), false)
	_label(
		Vector2(492.0, 282.0),
		"actual VehicleGameplayHud · 1280×720",
		13,
		Art.TEXT_MUTED
	)
	var marker_rect := Rect2(1370.0, 194.0, 606.0, 790.0)
	_draw_panel(marker_rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(marker_rect.position + Vector2(24.0, 42.0), "MINIMAP / TARGET MARKERS", 20, Art.TEXT_PRIMARY)
	var marker_ids := [&"player", &"enemy", &"elite", &"boss", &"stationary", &"pickup", &"crate", &"target"]
	for index in marker_ids.size():
		var center := marker_rect.position + Vector2(82.0 + (index % 2) * 292.0, 126.0 + (index / 2) * 146.0)
		_draw_world_marker(center, marker_ids[index], 1.0)
		_label(center + Vector2(50.0, 6.0), String(marker_ids[index]), 14, Art.TEXT_PRIMARY)
	_footer("HUD decoration yields to live combat; markers reuse world identity and add shape beyond hue.")


func _draw_controls() -> void:
	var states := [
		{"id": "normal", "rail": Color.TRANSPARENT},
		{"id": "hover", "rail": Art.SYSTEM},
		{"id": "focus", "rail": Art.SYSTEM},
		{"id": "selected", "rail": Art.PLAYER_REWARD},
		{"id": "disabled", "rail": Color.TRANSPARENT},
		{"id": "danger", "rail": Art.DANGER},
	]
	for index in states.size():
		var column := index % 3
		var row := index / 3
		var rect := Rect2(72.0 + column * 624.0, 210.0 + row * 176.0, 568.0, 132.0)
		_draw_panel(rect, Art.SURFACE, Art.LINE, Color(states[index]["rail"]))
		_label(
			rect.position + Vector2(20.0, 26.0),
			String(states[index]["id"]).to_upper(),
			12,
			Art.TEXT_MUTED
		)
	_label(Vector2(72.0, 620.0), "PANEL HIERARCHY", 20, Art.TEXT_PRIMARY)
	_label(Vector2(1340.0, 620.0), "CONTROL FAMILY", 20, Art.TEXT_PRIMARY)
	_footer("Selected, focus, disabled, and danger remain identifiable without hue alone.")


func _draw_modal_contact_sheet() -> void:
	var surfaces := [
		["DEPLOYMENT", "출격 준비", &"primary"],
		["UPGRADE", "업그레이드 선택", &"cards"],
		["PAUSE", "일시 정지", &"list"],
		["GUIDEBOOK", "도감", &"split"],
		["REPORT", "전투 보고", &"metrics"],
		["RESULT", "작전 결과", &"result"],
		["GARAGE", "격납고", &"split"],
		["SETTINGS", "설정", &"tabs"],
		["BOSS PRACTICE", "보스 훈련", &"debug"],
	]
	for index in surfaces.size():
		var column := index % 3
		var row := index / 3
		var rect := Rect2(
			72.0 + column * 634.0,
			194.0 + row * 284.0,
			604.0,
			260.0
		)
		_draw_panel(rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
		_label(
			rect.position + Vector2(18.0, 30.0),
			String(surfaces[index][0]),
			14,
			Art.TEXT_PRIMARY
		)
	_footer("Compact stacks content; wide may split. Every modal keeps one unmistakable primary action.")


func _build_runtime_control_evidence() -> void:
	match sheet_id:
		&"hud":
			_build_actual_hud()
		&"controls":
			_build_actual_controls()
		&"modals":
			_build_actual_modals()
		&"projectiles":
			_build_actual_telegraphs()


func _build_actual_hud() -> void:
	var frame := Control.new()
	frame.position = Vector2(96.0, 218.0)
	frame.size = Vector2(1280.0, 720.0)
	frame.scale = Vector2.ONE * 0.945
	add_child(frame)
	var hud := GameplayHud.new()
	frame.add_child(hud)
	hud.update_snapshot({
		"health":86.0,
		"max_health":120.0,
		"level":7,
		"experience":31.0,
		"experience_required":42.0,
		"objective":"STAGE 03 · 62%",
		"objective_detail":"SECURE THE RELAY",
		"dash_available":true,
		"passive_available":false,
		"passive_ratio":0.46,
		"skill_available":true,
		"boss":{
			"visible":false,
			"name":"",
		},
		"target":{
			"visible":true,
			"name":"ARTILLERY SPOTTER",
			"health":44.0,
			"max_health":80.0,
			"state":"COMMITTED",
		},
		"minimap":{
			"world_size":Vector2(5200.0, 2200.0),
			"player":Vector2(2600.0, 1100.0),
			"player_facing":Vector2.RIGHT,
			"markers":[
				{
					"kind":"boss",
					"position":Vector2(4200.0, 1100.0),
					"discovered":true,
				},
				{
					"kind":"pickup",
					"position":Vector2(3100.0, 900.0),
					"discovered":true,
				},
			],
		},
	})
	# Freeze transient HUD timers so repeated publication produces identical
	# evidence frames instead of capture-time-dependent health trails.
	hud.process_mode = Node.PROCESS_MODE_DISABLED


func _build_actual_controls() -> void:
	var records := [
		["기본 / NORMAL", &"SecondaryButton", false, false],
		["가리킴 / HOVER", &"SecondaryButton", false, false],
		["키보드 초점 / FOCUS", &"SecondaryButton", false, true],
		["선택 / SELECTED", &"SelectedChoiceButton", false, false],
		["비활성 / DISABLED", &"SecondaryButton", true, false],
		["위험 / DANGER", &"TertiaryDangerButton", false, false],
	]
	var focus_button: Button
	for index in records.size():
		var column := index % 3
		var row := index / 3
		var button := Button.new()
		button.position = Vector2(
			98.0 + column * 624.0,
			262.0 + row * 176.0
		)
		button.size = Vector2(516.0, 62.0)
		button.text = String(records[index][0])
		button.theme_type_variation = StringName(records[index][1])
		button.disabled = bool(records[index][2])
		button.focus_mode = Control.FOCUS_ALL
		add_child(button)
		if bool(records[index][3]):
			focus_button = button
	_build_actual_control_hierarchy()
	call_deferred("_focus_sheet_control", focus_button)


func _build_actual_control_hierarchy() -> void:
	var modal := UiFactory.modal_surface(Vector2(1190.0, 360.0))
	modal.position = Vector2(72.0, 660.0)
	modal.size = Vector2(1190.0, 360.0)
	add_child(modal)
	var content := Control.new()
	content.custom_minimum_size = modal.size
	modal.add_child(content)
	var title := UiFactory.label("함선 시스템 / SHIP SYSTEMS", 28)
	title.theme_type_variation = &"TitleLabel"
	title.position = Vector2(28.0, 24.0)
	title.size = Vector2(760.0, 42.0)
	content.add_child(title)
	var subtitle := UiFactory.label(
		"Title → content → action",
		15,
		Art.TEXT_MUTED
	)
	subtitle.position = Vector2(28.0, 70.0)
	subtitle.size = Vector2(760.0, 28.0)
	content.add_child(subtitle)
	var status_panel := UiFactory.flat_panel()
	status_panel.position = Vector2(28.0, 122.0)
	status_panel.size = Vector2(710.0, 180.0)
	content.add_child(status_panel)
	var status_content := Control.new()
	status_content.custom_minimum_size = status_panel.size
	status_panel.add_child(status_content)
	var status_title := UiFactory.label("현재 상태", 17)
	status_title.theme_type_variation = &"MetricLabel"
	status_title.position = Vector2(28.0, 22.0)
	status_title.size = Vector2(620.0, 30.0)
	status_content.add_child(status_title)
	var hull := UiFactory.label("장갑  100 / 100", 15, Art.TEXT_MUTED)
	hull.position = Vector2(28.0, 66.0)
	hull.size = Vector2(620.0, 28.0)
	status_content.add_child(hull)
	var thrust := UiFactory.label("추진  준비", 15, Art.SUPPORT)
	thrust.position = Vector2(28.0, 106.0)
	thrust.size = Vector2(620.0, 28.0)
	status_content.add_child(thrust)
	var confirm := UiFactory.command_button(
		"확인 / CONFIRM",
		&"PrimaryButton"
	)
	confirm.position = Vector2(790.0, 226.0)
	confirm.size = Vector2(348.0, 64.0)
	content.add_child(confirm)
	for record in [
		[Vector2(1340.0, 676.0), "주요 행동 / PRIMARY", &"PrimaryButton"],
		[Vector2(1340.0, 764.0), "보조 행동 / SECONDARY", &"SecondaryButton"],
		[Vector2(1340.0, 852.0), "위험 행동 / DANGER", &"TertiaryDangerButton"],
	]:
		var button := UiFactory.command_button(
			String(record[1]),
			StringName(record[2])
		)
		button.position = Vector2(record[0])
		button.size = Vector2(560.0, 64.0)
		add_child(button)
	var motion_toggle := CheckButton.new()
	motion_toggle.position = Vector2(1340.0, 948.0)
	motion_toggle.size = Vector2(560.0, 56.0)
	motion_toggle.text = "모션 감소 / REDUCED MOTION"
	motion_toggle.button_pressed = true
	motion_toggle.focus_mode = Control.FOCUS_ALL
	add_child(motion_toggle)


func _build_actual_telegraphs() -> void:
	var renderer := CombatRenderer.new()
	add_child(renderer)
	call_deferred("_sync_actual_telegraphs", renderer)


func _sync_actual_telegraphs(renderer: Node2D) -> void:
	if not is_instance_valid(renderer):
		return
	renderer.z_index = 2
	var enemies: Array[EnemyState] = []
	var centers: Array[Vector2] = []
	for index in 5:
		centers.append(
			Rect2(72.0 + index * 380.0, 706.0, 348.0, 276.0)
			.get_center() - Vector2(0.0, 12.0)
		)
	enemies.append(
		_telegraph_enemy(
			"sheet_corridor",
			&"startup",
			[{
				"shape":&"corridor",
				"from":centers[0] - Vector2(112.0, 0.0),
				"to":centers[0] + Vector2(112.0, 0.0),
				"half_width":32.0,
				"damage":14.0,
				"affinity":&"kinetic",
				"readiness":0.72,
			}]
		)
	)
	enemies.append(
		_telegraph_enemy(
			"sheet_active_beam",
			&"active",
			[{
				"shape":&"corridor",
				"from":centers[1] - Vector2(112.0, 0.0),
				"to":centers[1] + Vector2(112.0, 0.0),
				"half_width":28.0,
				"active_width":32.0,
				"damage":28.0,
				"affinity":&"arc",
				"readiness":1.0,
			}]
		)
	)
	enemies.append(
		_telegraph_enemy(
			"sheet_area",
			&"startup",
			[{
				"shape":&"area",
				"center":centers[2],
				"radius":82.0,
				"damage":28.0,
				"affinity":&"thermal",
				"readiness":0.76,
			}]
		)
	)
	enemies.append(
		_telegraph_enemy(
			"sheet_support",
			&"startup",
			[{
				"shape":&"support",
				"center":centers[3],
				"radius":82.0,
				"damage":0.0,
				"affinity":&"support",
			}]
		)
	)
	enemies.append(
		_telegraph_enemy(
			"sheet_commit",
			&"startup",
			[{
				"shape":&"area",
				"center":centers[4] - Vector2(58.0, 0.0),
				"radius":8.0,
				"damage":14.0,
				"affinity":&"kinetic",
				"readiness":1.0,
				"commit_mode":&"committed",
			}]
		)
	)
	var no_projectiles: Array[ProjectileState] = []
	var no_shards: Array[ExperienceShard] = []
	var effects: Array[Dictionary] = [{
		"pos":centers[4] + Vector2(58.0, 0.0),
		"duration":1.0,
		"time":0.45,
		"radius":58.0,
		"kind":"impact",
		"color":Art.TEXT_PRIMARY,
	}]
	renderer.sync(
		enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		effects,
		Rect2(Vector2.ZERO, size),
		Vector2.ZERO,
		0.0,
		true
	)


func _telegraph_enemy(
	enemy_id: String,
	phase: StringName,
	telegraphs: Array
) -> EnemyState:
	var enemy := EnemyState.new()
	enemy.id = enemy_id
	enemy.role = &"chaser"
	enemy.archetype = &"chaser"
	enemy.pos = Vector2(-128.0, -128.0)
	enemy.alive = true
	enemy.active = true
	enemy.visual_radius = 0.01
	enemy.health = 1.0
	enemy.max_health = 1.0
	enemy.phase = phase
	enemy.attack_telegraphs.clear()
	for telegraph_variant in telegraphs:
		enemy.attack_telegraphs.append(Dictionary(telegraph_variant))
	return enemy


func _focus_sheet_control(button: Button) -> void:
	if is_instance_valid(button):
		button.grab_focus()


func _build_actual_modals() -> void:
	var contents: Array[Control] = [
		DeploymentPanel.new(),
		UpgradePanel.new(),
		PausePanel.new(),
		GuidebookPanel.new(),
		StageReportPanel.new(),
		ResultPanel.new(),
		GaragePanel.new(),
		SettingsPanel.new(),
		BossPracticePanel.new(),
	]
	for index in contents.size():
		var column := index % 3
		var row := index / 3
		var cell_rect := Rect2(
			72.0 + column * 634.0,
			194.0 + row * 284.0,
			604.0,
			260.0
		)
		var inner_rect := Rect2(
			cell_rect.position + Vector2(14.0, 42.0),
			cell_rect.size - Vector2(28.0, 54.0)
		)
		var evidence_size := _modal_evidence_size(index)
		var evidence_viewport := evidence_size + Vector2(48.0, 24.0)
		var evidence_scale := minf(
			inner_rect.size.x / evidence_viewport.x,
			inner_rect.size.y / evidence_viewport.y
		)
		var wrapper := Control.new()
		wrapper.position = (
			inner_rect.position
			+ (inner_rect.size - evidence_viewport * evidence_scale) * 0.5
		)
		wrapper.size = evidence_viewport
		wrapper.scale = Vector2.ONE * evidence_scale
		add_child(wrapper)
		var host := ModalHost.new()
		host.configure(contents[index], evidence_size)
		wrapper.add_child(host)
		_open_modal_evidence(contents[index], index)


func _modal_evidence_size(index: int) -> Vector2:
	return [
		Vector2(1176.0, 636.0),
		Vector2(960.0, 626.0),
		Vector2(640.0, 380.0),
		Vector2(1160.0, 636.0),
		Vector2(1120.0, 600.0),
		Vector2(900.0, 560.0),
		Vector2(960.0, 560.0),
		Vector2(920.0, 570.0),
		Vector2(760.0, 620.0),
	][index]


func _open_modal_evidence(content: Control, index: int) -> void:
	match index:
		0:
			(content as VehicleDeploymentPanel).open(
				&"hard",
				"FIELD_DROWNED_RUIN"
			)
		1:
			var empty_cards: Array[Dictionary] = []
			var catalog := UpgradeCatalog.new()
			for definition in catalog.all_definitions().slice(0, 3):
				empty_cards.append(
					UpgradePresenter.snapshot(definition, 0)
				)
			(content as VehicleUpgradeChoicePanel).open(
				empty_cards,
				false
			)
		2:
			(content as VehiclePausePanel).open()
		3:
			(content as VehicleGuidebookPanel).open({})
		4:
			(content as VehicleStageReportPanel).open({})
		5:
			(content as VehicleResultPanel).open({
				"stage_number":3,
				"stage_title_key":"STAGE_STORM_DRYDOCK_3",
				"has_next_stage":true,
				"time":"1:18",
				"health_ratio":0.72,
				"upgrade":"UPGRADE_NONE",
			})
		6:
			(content as VehicleGaragePanel).open({})
		7:
			(content as VehicleSettingsPanel).open()
		8:
			(content as VehicleBossPracticePanel).open()


func _draw_pressure_accessibility() -> void:
	var live_rect := Rect2(72.0, 194.0, 1190.0, 790.0)
	_draw_panel(live_rect, Art.WORLD_CANVAS, Art.LINE, Art.DANGER)
	_draw_mock_combat_field(live_rect, true)
	_label(live_rect.position + Vector2(24.0, 38.0), "COMPOSITION TEST · GAMEPLAY 1×", 16, Art.TEXT_PRIMARY)
	var proof_rect := Rect2(1300.0, 194.0, 676.0, 790.0)
	_draw_panel(proof_rect, Art.SURFACE, Art.LINE, Art.SYSTEM)
	_label(proof_rect.position + Vector2(24.0, 40.0), "ACCESSIBILITY CHECKS", 20, Art.TEXT_PRIMARY)
	var checks := [
		["GRAYSCALE", "role contours remain distinct", true],
		["REDUCED MOTION", "static dash beam + short afterimage", true],
		["CORE / TAIL", "collision core stays bright", true],
		["TARGET PRIORITY", "committed attack precedes trim", true],
		["CENTER CLEAR", "HUD does not cover player space", true],
		["TEXT FIT", "ko/en labels remain inside panels", true],
	]
	for index in checks.size():
		var rect := Rect2(
			proof_rect.position + Vector2(24.0, 90.0 + index * 104.0),
			Vector2(proof_rect.size.x - 48.0, 82.0)
		)
		_draw_panel(rect, Art.WORLD_CANVAS, Art.LINE, Art.SUPPORT)
		_draw_check(rect.position + Vector2(28.0, 41.0), bool(checks[index][2]))
		_label(rect.position + Vector2(64.0, 34.0), String(checks[index][0]), 14, Art.TEXT_PRIMARY)
		_label(rect.position + Vector2(64.0, 60.0), String(checks[index][1]), 12, Art.TEXT_MUTED)
	_footer("Inspection composition · final sheet is regenerated with production capture evidence in Phase 8.")


func _draw_player_assembly(
	center: Vector2,
	radius: float,
	hull_direction: Vector2,
	aim_direction: Vector2,
	thrust: float,
	hull_color: Color = Art.PLAYER_REWARD,
	dashing: bool = false
) -> void:
	var hull_angle := hull_direction.angle()
	var side := hull_direction.rotated(PI * 0.5)
	var rear := -hull_direction
	var descriptor := ActorCatalog.descriptor(&"player")
	for socket_variant in Array(descriptor["rear_sockets"]):
		var socket := Vector2(socket_variant)
		var mount := (
			center
			+ hull_direction * socket.x * radius
			+ side * socket.y * radius
		)
		_draw_mesh_at(
			Visuals.player_engine_flare_mesh(),
			mount + rear * radius * (0.22 + thrust * 0.12),
			Vector2(radius * (0.22 + thrust * 0.24), radius * 0.10),
			hull_angle,
			Art.SYSTEM
		)
		_draw_mesh_at(
			Visuals.player_engine_mesh(),
			mount,
			Vector2(radius * 0.20, radius * 0.14),
			hull_angle,
			Art.TEXT_MUTED
		)
	_draw_mesh_at(
		Visuals.player_hull_mesh(),
		center,
		Vector2.ONE * radius,
		hull_angle,
		hull_color
	)
	_draw_mesh_at(
		Visuals.player_primary_mesh(),
		center + aim_direction * radius * 0.18,
		Vector2(radius * 0.45, radius * 0.18),
		aim_direction.angle(),
		hull_color
	)
	if dashing:
		for index in 3:
			var after_center := center + rear * radius * (0.65 + index * 0.38)
			_draw_mesh_at(
				Visuals.effect_mesh(&"afterimage"),
				after_center,
				Vector2.ONE * radius * (0.78 - index * 0.12),
				hull_angle,
				Color(Art.SYSTEM, 0.26 - index * 0.06)
			)


func _draw_mock_combat_field(rect: Rect2, dense: bool) -> void:
	var clip := rect.grow(-18.0)
	draw_rect(clip, Art.SURFACE)
	for index in 7:
		var x := clip.position.x + 40.0 + index * clip.size.x / 7.0
		draw_line(
			Vector2(x, clip.position.y),
			Vector2(x, clip.end.y),
			Color(Art.LINE, 0.22),
			1.0
		)
	for index in 5:
		var y := clip.position.y + 40.0 + index * clip.size.y / 5.0
		draw_line(
			Vector2(clip.position.x, y),
			Vector2(clip.end.x, y),
			Color(Art.LINE, 0.22),
			1.0
		)
	var player_center := clip.get_center()
	_draw_player_assembly(
		player_center,
		50.0,
		Vector2.RIGHT.rotated(-0.18),
		Vector2.RIGHT.rotated(-0.62),
		0.66
	)
	var enemy_ids := [
		&"chaser", &"shooter", &"controller", &"shield_escort",
		&"artillery_spotter", &"rammer", &"beam_sentinel",
	]
	var count := 22 if dense else 8
	for index in count:
		var angle := TAU * float(index) / float(count)
		var ring := 150.0 + float(index % 4) * 62.0
		var position := player_center + Vector2.RIGHT.rotated(angle) * ring
		if not clip.grow(-30.0).has_point(position):
			continue
		var id: StringName = enemy_ids[index % enemy_ids.size()]
		var color := _role_color(StringName(ActorCatalog.descriptor(id)["role"]))
		_draw_mesh_at(
			Visuals.enemy_mesh(id),
			position,
			Vector2.ONE * (28.0 if dense else 38.0),
			angle + PI,
			color
		)
	for index in (16 if dense else 6):
		var angle := -0.75 + float(index) * 0.09
		var position := player_center + Vector2.RIGHT.rotated(angle) * (100.0 + index * 19.0)
		_draw_mesh_at(
			Visuals.hostile_projectile_mesh(
				[&"kinetic", &"thermal", &"cryo", &"arc"][index % 4]
			),
			position,
			Vector2(7.0, 5.0),
			angle + PI,
			[Art.DANGER, Art.THERMAL, Art.CRYO, Art.ARC][index % 4]
		)


func _draw_facility_glyph(
	center: Vector2,
	facility_id: StringName,
	color: Color,
	scale: float
) -> void:
	var descriptor := WorldCatalog.facility_descriptor(facility_id)
	var recipe_id := StringName(
		descriptor.get("recipe", facility_id)
	)
	RewardFacilityRecipes.draw_recipe(
		self,
		recipe_id,
		center,
		scale,
		_reward_facility_palette(color)
	)


func _draw_reward_glyph(
	center: Vector2,
	reward_id: StringName,
	color: Color,
	scale: float
) -> void:
	var descriptor := RewardCatalog.descriptor(reward_id)
	var recipe_id := StringName(
		descriptor.get("recipe", reward_id)
	)
	RewardFacilityRecipes.draw_recipe(
		self,
		recipe_id,
		center,
		scale,
		_reward_facility_palette(color)
	)


func _draw_world_marker(center: Vector2, marker_id: StringName, scale: float) -> void:
	var color := Art.TEXT_PRIMARY
	match marker_id:
		&"player":
			color = Art.PLAYER_REWARD
			_draw_mesh_at(
				Visuals.player_hull_mesh(),
				center,
				Vector2.ONE * 25.0 * scale,
				0.0,
				color
			)
		&"enemy":
			color = Art.DANGER
			_draw_mesh_at(
				Visuals.enemy_mesh(&"chaser"),
				center,
				Vector2.ONE * 23.0 * scale,
				0.0,
				color
			)
		&"elite":
			color = Art.DANGER
			_draw_mesh_at(
				Visuals.enemy_mesh(&"controller"),
				center,
				Vector2.ONE * 25.0 * scale,
				0.0,
				color
			)
		&"boss":
			color = Art.BOSS_COMMAND
			_draw_mesh_at(
				Visuals.boss_mesh(&"colossus"),
				center,
				Vector2.ONE * 27.0 * scale,
				0.0,
				color
			)
		&"stationary":
			color = Art.DANGER
			_draw_mesh_at(
				Visuals.enemy_mesh(&"turret"),
				center,
				Vector2.ONE * 24.0 * scale,
				0.0,
				color
			)
		&"pickup":
			color = Art.SUPPORT
			_draw_reward_glyph(
				center,
				&"repair",
				color,
				23.0 * scale
			)
		&"crate":
			color = Art.PLAYER_REWARD
			_draw_reward_glyph(
				center,
				&"reward_crate",
				color,
				22.0 * scale
			)
		_:
			color = Art.SYSTEM
			draw_arc(center, 26.0 * scale, -2.4, 2.4, 24, color, 4.0 * scale)


func _reward_facility_palette(accent: Color) -> Dictionary:
	return {
		&"accent":accent,
		&"perimeter":Color(Art.SPACE_BLACK, accent.a),
		&"main_mass":accent,
		&"secondary_mass":Color(
			accent.lerp(Art.SPACE_BLACK, 0.28),
			accent.a
		),
		&"function_inset":Color(Art.SURFACE, accent.a),
		&"hard_highlight":Color(Art.TEXT_PRIMARY, accent.a),
	}


func _draw_boss_modules(center: Vector2, module_id: StringName) -> void:
	for index in 2:
		var module_center := center + Vector2((float(index) - 0.5) * 92.0, 0.0)
		_draw_mesh_at(
			Visuals.boss_module_mesh(module_id, &"active"),
			module_center,
			Vector2.ONE * 30.0,
			0.0,
			Color.WHITE
		)


func _draw_panel(rect: Rect2, fill: Color, line: Color, rail: Color) -> void:
	var cut := clampf(minf(rect.size.x, rect.size.y) * 0.055, 8.0, 16.0)
	var shadow_points := Art.stepped_rect(
		Rect2(rect.position + Vector2(4.0, 5.0), rect.size),
		cut
	)
	draw_colored_polygon(shadow_points, Color(Art.SPACE_BLACK, 0.86))
	var panel_points := Art.stepped_rect(rect, cut)
	draw_colored_polygon(panel_points, fill)
	var closed_panel := panel_points.duplicate()
	closed_panel.append(panel_points[0])
	draw_polyline(closed_panel, line, 2.0, true)
	draw_line(
		rect.position + Vector2(cut + 8.0, 6.0),
		Vector2(rect.end.x - cut - 8.0, rect.position.y + 6.0),
		Color(Art.TEXT_PRIMARY, 0.13),
		1.0,
		true
	)
	if rail.a > 0.0:
		draw_rect(
			Rect2(
				rect.position + Vector2(7.0, cut + 5.0),
				Vector2(3.0, maxf(0.0, rect.size.y - cut * 2.0 - 10.0))
			),
			rail
		)


func _draw_plate(rect: Rect2, cut: float, color: Color) -> void:
	var points := Art.stepped_rect(rect, cut)
	draw_colored_polygon(points, color)
	var closed_points := points.duplicate()
	closed_points.append(points[0])
	draw_polyline(closed_points, Art.LINE, 1.0, true)


func _draw_token(rect: Rect2, role: String, color: Color) -> void:
	draw_rect(rect, Art.SURFACE)
	draw_rect(Rect2(rect.position, Vector2(74.0, rect.size.y)), color)
	draw_rect(rect, Art.LINE, false, 1.0)
	_label(rect.position + Vector2(92.0, 34.0), role, 15, Art.TEXT_PRIMARY)
	_label(rect.position + Vector2(92.0, 63.0), "#%s" % color.to_html(false).to_upper(), 13, Art.TEXT_MUTED)


func _draw_primitive(
	center: Vector2,
	primitive_id: StringName,
	color: Color,
	scale: float
) -> void:
	var points := ComponentMeshes.primitive_points(primitive_id)
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(center + point * scale)
	if transformed.size() >= 3:
		draw_colored_polygon(transformed, color)


func _draw_mesh_at(
	mesh: Mesh,
	center: Vector2,
	mesh_scale: Vector2,
	rotation: float,
	modulate: Color
) -> void:
	if mesh == null:
		return
	if mesh not in _retained_draw_meshes:
		# Canvas draw commands execute after _draw returns, so sheet-local
		# runtime meshes must remain strongly referenced until capture.
		_retained_draw_meshes.append(mesh)
	draw_mesh(
		mesh,
		_white_texture,
		Transform2D(rotation, mesh_scale, 0.0, center),
		modulate
	)


func _draw_regular_polygon(
	center: Vector2,
	radius: float,
	sides: int,
	color: Color,
	rotation: float = 0.0
) -> void:
	var points := PackedVector2Array()
	for index in sides:
		points.append(
			center
			+ Vector2.RIGHT.rotated(
				rotation + TAU * float(index) / float(sides)
			) * radius
		)
	draw_colored_polygon(points, color)


func _draw_measure(from: Vector2, to: Vector2, text: String) -> void:
	draw_line(from, to, Art.SYSTEM, 1.0)
	draw_line(from - Vector2(0.0, 8.0), from + Vector2(0.0, 8.0), Art.SYSTEM, 1.0)
	draw_line(to - Vector2(0.0, 8.0), to + Vector2(0.0, 8.0), Art.SYSTEM, 1.0)
	_label((from + to) * 0.5 - Vector2(150.0, 12.0), text, 13, Art.TEXT_MUTED)


func _draw_check(center: Vector2, checked: bool) -> void:
	_draw_regular_polygon(center, 16.0, 4, Art.SUPPORT if checked else Art.DANGER, PI / 4.0)
	if checked:
		draw_line(center + Vector2(-7.0, 0.0), center + Vector2(-1.0, 7.0), Art.SPACE_BLACK, 3.0)
		draw_line(center + Vector2(-1.0, 7.0), center + Vector2(9.0, -7.0), Art.SPACE_BLACK, 3.0)


func _role_color(role: StringName) -> Color:
	if role in [&"support_structure", &"shield", &"repair"]:
		return Art.SUPPORT
	if role in [&"command", &"carrier", &"boss", &"boss_module"]:
		return Art.BOSS_COMMAND
	return Art.DANGER


func _semantic_color(role: StringName) -> Color:
	return Color(Art.required_color_roles().get(String(role), Art.TEXT_PRIMARY))


func _footer(text: String) -> void:
	_label(Vector2(72.0, 1082.0), text, 15, Art.TEXT_MUTED)


func _label(position: Vector2, text: String, font_size: int, color: Color) -> void:
	var font := _font_strong if font_size >= 20 else _font_body
	if font == null:
		return
	draw_string(
		font,
		position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		color
	)


func _font_variation(base_font: Font, weight: float) -> Font:
	if base_font == null:
		return null
	var variation := FontVariation.new()
	variation.base_font = base_font
	variation.variation_opentype = {"weight":weight}
	return variation
