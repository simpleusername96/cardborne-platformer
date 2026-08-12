class_name VehicleStageVisualProfile
extends RefCounted

## Presentation-only semantic color and scale contract for the vehicle stage.
## Gameplay code may consume these roles and sizes, but this profile owns no state,
## collision, progression, input, or persistence behavior.

const SPACE_BLACK := Color("#070B11")
const WORLD_CANVAS := Color("#101923")
const SURFACE := Color("#182431")
const RAISED := Color("#243445")
const LINE := Color("#465A6E")
const TEXT_PRIMARY := Color("#EEF3F7")
const TEXT_MUTED := Color("#9EADBC")
const PLAYER_REWARD := Color("#F2B735")
const DANGER := Color("#F05A5F")
const BOSS_COMMAND := Color("#D43F8D")
const SUPPORT := Color("#72D6C4")
const SYSTEM := Color("#58BFEA")
const THERMAL := Color("#F47A3C")
const TOXIN := Color("#91B44B")
const CRYO := Color("#55BFE9")
const ARC := Color("#AA6DE0")

# Compatibility aliases keep current renderers stable while each family moves
# to the new catalogs. New presentation code must use the semantic names above.
const COBALT_VOID := SPACE_BLACK
const COBALT_ENERGY := SYSTEM
const COBALT_DEEP := WORLD_CANVAS
const IVORY := SURFACE
const IVORY_SHADE := RAISED
const IVORY_BRIGHT := TEXT_PRIMARY
const STRUCTURE_BASE := RAISED
const BLOCKER_FILL := RAISED
const STRUCTURE_MID := LINE
const STRUCTURE_LIGHT := TEXT_MUTED
const MINT := SUPPORT
const MINT_SOFT := Color("#9BE2D5")
const CORAL := DANGER
const CORAL_DARK := Color("#9C3A3E")
const MUSTARD := PLAYER_REWARD
const MUSTARD_DARK := Color("#9D7622")
const BOSS_MAGENTA := BOSS_COMMAND
const ATTACK_THERMAL := THERMAL
const ATTACK_TOXIN := TOXIN
const ATTACK_CRYO := CRYO
const ATTACK_ARC := ARC
const INK := SPACE_BLACK
const INK_MUTED := TEXT_MUTED
const DIM := Color(0.027, 0.043, 0.067, 0.82)

const TYPE_SCALE_COMPACT := [13, 15, 17, 22, 30]
const TYPE_SCALE_WIDE := [14, 16, 18, 24, 32, 40]
const SPACING_SCALE := [4, 8, 12, 16, 24, 32]
const BREAKPOINT_WIDE := 1100
const BREAKPOINT_THREE_COLUMN := 1180
const CONTROL_MIN_HEIGHT := 44
const PANEL_INSET_COMPACT := 16
const PANEL_INSET_WIDE := 24
const BORDER_WIDTH := 1
const FOCUS_WIDTH := 2
const SELECTED_RAIL_WIDTH := 3

const PLAYER_VISUAL_RADIUS := 35.0
const ORDINARY_ENEMY_RADIUS := 44.0
const INSTALLATION_RADIUS := 62.0
const STAGE_BOSS_RADIUS := 146.0
const PICKUP_PLINTH_RADIUS := 42.0
const EXPERIENCE_RADII := {
	&"small":17.0,
	&"medium":20.0,
	&"large":23.0,
}
## Visual envelopes are intentionally larger than collision truth. They are
## presentation-only and keep the shared teardrop readable at live speed.
const HOSTILE_PROJECTILE_ENVELOPE_SCALE := 3.85
const PLAYER_PRIMARY_PROJECTILE_SCALE := 4.375
const PLAYER_SEEKER_PROJECTILE_SCALE := 5.0
const PLAYER_OPENING_BREACH_PROJECTILE_SCALE := 4.55
const PROJECTILE_LENGTH_FACTOR := 0.70
const PROJECTILE_THICKNESS_FACTOR := 0.50
const HOSTILE_PROJECTILE_THICKNESS_FACTOR := 1.00
const PLAYER_DROP_MINE_HALF_SIZE := 44.0
const PLAYER_ORBIT_BLADE_HALF_SIZE := 52.0
const CACHE_HALF_SIZE := Vector2(70.0, 52.0)
const COVER_EDGE_OFFSET := Vector2(14.0, 18.0)
const WALL_FILL := STRUCTURE_BASE
const WALL_SHADOW := COBALT_DEEP
const WALL_RAIL_WIDTH := 48.0
const WALL_SHADOW_OFFSET := Vector2(0.0, 12.0)

# The flat map pass reuses established neutral tokens without changing shared
# UI semantics. Geometry remains owned by the field snapshot.
const MAP_SURFACE_FILL := TEXT_MUTED
const MAP_OUTER_WALL_FILL := SPACE_BLACK
const MAP_INNER_WALL_FILL := RAISED


static func enemy_visual_radius(role: StringName) -> float:
	match role:
		&"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"generator":
			return INSTALLATION_RADIUS
		&"stage_boss":
			return STAGE_BOSS_RADIUS
	return ORDINARY_ENEMY_RADIUS


static func attack_color(affinity: StringName, friendly: bool = false) -> Color:
	var color := CORAL
	match affinity:
		&"thermal":
			color = ATTACK_THERMAL
		&"toxin":
			color = ATTACK_TOXIN
		&"cryo":
			color = ATTACK_CRYO
		&"arc":
			color = ATTACK_ARC
		&"hybrid":
			color = IVORY_BRIGHT
		&"support":
			color = MINT
		_:
			color = MUSTARD if friendly else CORAL
	return color.lerp(IVORY_BRIGHT, 0.16) if friendly and affinity != &"kinetic" else color


static func attack_warning_color(affinity: StringName, readiness: float) -> Color:
	var progress := smoothstep(0.0, 1.0, clampf(readiness, 0.0, 1.0))
	var base := attack_color(affinity)
	var early := base.lerp(IVORY_BRIGHT, 0.52)
	var imminent := base.lerp(INK, 0.12)
	return early.lerp(imminent, progress)


static func stepped_rect(rect: Rect2, cut: float = 34.0) -> PackedVector2Array:
	var safe_cut := minf(cut, minf(rect.size.x, rect.size.y) * 0.22)
	return PackedVector2Array([
		rect.position + Vector2(safe_cut, 0.0),
		rect.end - Vector2(safe_cut, rect.size.y),
		rect.end - Vector2(0.0, rect.size.y - safe_cut),
		rect.end - Vector2(0.0, safe_cut),
		rect.end - Vector2(safe_cut, 0.0),
		rect.position + Vector2(safe_cut, rect.size.y),
		rect.position + Vector2(0.0, rect.size.y - safe_cut),
		rect.position + Vector2(0.0, safe_cut),
	])


static func required_color_roles() -> Dictionary:
	return {
		"space_black": SPACE_BLACK,
		"world_canvas": WORLD_CANVAS,
		"surface": SURFACE,
		"raised": RAISED,
		"line": LINE,
		"text_primary": TEXT_PRIMARY,
		"text_muted": TEXT_MUTED,
		"player_reward": PLAYER_REWARD,
		"danger": DANGER,
		"boss_command": BOSS_COMMAND,
		"support": SUPPORT,
		"system": SYSTEM,
		"thermal": THERMAL,
		"toxin": TOXIN,
		"cryo": CRYO,
		"arc": ARC,
	}


static func provider_fingerprint() -> String:
	var ordered := PackedStringArray()
	for role in required_color_roles():
		ordered.append("%s=%s" % [role, required_color_roles()[role].to_html(false)])
	ordered.append("compact_type=%s" % str(TYPE_SCALE_COMPACT))
	ordered.append("wide_type=%s" % str(TYPE_SCALE_WIDE))
	ordered.append("spacing=%s" % str(SPACING_SCALE))
	ordered.append(
		"layout=%d/%d/%d/%d/%d/%d"
		% [
			BREAKPOINT_WIDE,
			BREAKPOINT_THREE_COLUMN,
			CONTROL_MIN_HEIGHT,
			PANEL_INSET_COMPACT,
			PANEL_INSET_WIDE,
			SELECTED_RAIL_WIDTH,
		]
	)
	return "|".join(ordered).sha256_text()


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	var roles := required_color_roles()
	for role in [
		"space_black", "world_canvas", "surface", "raised", "line",
		"text_primary", "text_muted", "player_reward", "danger",
		"boss_command", "support", "system", "thermal", "toxin", "cryo", "arc",
	]:
		if not roles.has(role):
			errors.append("missing semantic color role: %s" % role)
	if TYPE_SCALE_COMPACT != [13, 15, 17, 22, 30]:
		errors.append("compact type scale must remain 13/15/17/22/30")
	if TYPE_SCALE_WIDE != [14, 16, 18, 24, 32, 40]:
		errors.append("wide type scale must remain 14/16/18/24/32/40")
	if SPACING_SCALE != [4, 8, 12, 16, 24, 32]:
		errors.append("spacing scale must remain 4/8/12/16/24/32")
	if CONTROL_MIN_HEIGHT < 44:
		errors.append("control minimum height must remain at least 44 px")
	for affinity in [&"kinetic", &"thermal", &"toxin", &"cryo", &"arc", &"hybrid"]:
		if attack_color(affinity).a < 1.0:
			errors.append("attack affinity color must remain opaque: %s" % affinity)
	if not is_equal_approx(PLAYER_VISUAL_RADIUS, 35.0):
		errors.append("player visual radius must remain 35 px")
	if not is_equal_approx(ORDINARY_ENEMY_RADIUS, 44.0):
		errors.append("ordinary enemy visual radius must remain 44 px")
	if not is_equal_approx(INSTALLATION_RADIUS, 62.0):
		errors.append("installation visual radius must remain 62 px")
	if not is_equal_approx(PICKUP_PLINTH_RADIUS, 42.0):
		errors.append("pickup plinth radius must remain 42 px")
	if not is_equal_approx(STAGE_BOSS_RADIUS, 146.0):
		errors.append("stage boss visual radius must remain 146 px")
	if EXPERIENCE_RADII != {&"small":17.0, &"medium":20.0, &"large":23.0}:
		errors.append("experience visual radii must remain 17/20/23 px")
	if (
		MAP_SURFACE_FILL == MAP_OUTER_WALL_FILL
		or MAP_SURFACE_FILL == MAP_INNER_WALL_FILL
		or MAP_OUTER_WALL_FILL == MAP_INNER_WALL_FILL
	):
		errors.append("map surface, outer wall, and inner wall fills must stay distinct")
	for map_color in [
		MAP_SURFACE_FILL,
		MAP_OUTER_WALL_FILL,
		MAP_INNER_WALL_FILL,
	]:
		if map_color.a < 1.0:
			errors.append("flat map role colors must remain opaque")
	if not is_equal_approx(HOSTILE_PROJECTILE_ENVELOPE_SCALE, 3.85):
		errors.append("hostile projectile envelope must remain 3.85x collision radius")
	if not is_equal_approx(PLAYER_PRIMARY_PROJECTILE_SCALE, 4.375):
		errors.append("player primary projectile visual must remain 4.375x collision radius")
	if not is_equal_approx(PLAYER_SEEKER_PROJECTILE_SCALE, 5.0):
		errors.append("player seeker projectile visual must remain 5x collision radius")
	if not is_equal_approx(PLAYER_OPENING_BREACH_PROJECTILE_SCALE, 4.55):
		errors.append("opening breach projectile visual must remain 4.55x collision radius")
	if not is_equal_approx(PROJECTILE_LENGTH_FACTOR, 0.70):
		errors.append("projectile visual length must remain at 70 percent")
	if not is_equal_approx(PROJECTILE_THICKNESS_FACTOR, 0.50):
		errors.append("player projectile visual thickness must remain at 50 percent")
	if not is_equal_approx(HOSTILE_PROJECTILE_THICKNESS_FACTOR, 1.00):
		errors.append("hostile projectile visual thickness must remain at 100 percent")
	if not is_equal_approx(PLAYER_DROP_MINE_HALF_SIZE, 44.0):
		errors.append("player drop-mine visual half-size must remain 44 world units")
	if not is_equal_approx(PLAYER_ORBIT_BLADE_HALF_SIZE, 52.0):
		errors.append("player orbit-blade visual half-size must remain 52 world units")
	return errors
