class_name VehicleStageVisualProfile
extends RefCounted

## Presentation-only semantic color and scale contract for the vehicle stage.
## Gameplay code may consume these roles and sizes, but this profile owns no state,
## collision, progression, input, or persistence behavior.

const COBALT_VOID := Color("#0739A6")
const COBALT_ENERGY := Color("#0755C7")
const COBALT_DEEP := Color("#042B7B")
const IVORY := Color("#F3E8C9")
const IVORY_SHADE := Color("#D9CAA7")
const IVORY_BRIGHT := Color("#FFF6DC")
const STRUCTURE_BASE := Color("#07564C")
const BLOCKER_FILL := Color("#07564C")
const STRUCTURE_MID := Color("#0E6C5E")
const STRUCTURE_LIGHT := Color("#2F8170")
const MINT := Color("#75C4B2")
const MINT_SOFT := Color("#A8DACB")
const CORAL := Color("#C92F4E")
const CORAL_DARK := Color("#7B1733")
const MUSTARD := Color("#D79A17")
const MUSTARD_DARK := Color("#8A5B10")
const BOSS_MAGENTA := Color("#962754")
const ATTACK_THERMAL := Color("#E45F36")
const ATTACK_TOXIN := Color("#769A32")
const ATTACK_CRYO := Color("#3E91B7")
const ATTACK_ARC := Color("#9B59B6")
const INK := Color("#153B3A")
const INK_MUTED := Color("#4E6D67")
const DIM := Color(0.02, 0.12, 0.28, 0.82)

const PLAYER_VISUAL_RADIUS := 50.0
const ORDINARY_ENEMY_RADIUS := 44.0
const INSTALLATION_RADIUS := 62.0
const STAGE_BOSS_RADIUS := 146.0
const PICKUP_PLINTH_RADIUS := 42.0
const EXPERIENCE_RADII := {
	&"small":12.0,
	&"medium":16.0,
	&"large":22.0,
}
const HOSTILE_PROJECTILE_ENVELOPE_SCALE := 4.5
const PLAYER_PRIMARY_PROJECTILE_SCALE := 1.25
const CACHE_HALF_SIZE := Vector2(70.0, 52.0)
const COVER_EDGE_OFFSET := Vector2(14.0, 18.0)
const WALL_FILL := STRUCTURE_BASE
const WALL_SHADOW := COBALT_DEEP
const WALL_RAIL_WIDTH := 48.0
const WALL_SHADOW_OFFSET := Vector2(0.0, 12.0)


static func enemy_visual_radius(role: StringName) -> float:
	match role:
		&"turret", &"mine", &"interceptor_tower", &"beam_sentinel", &"generator", &"boss_pylon":
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
		"walkable": IVORY,
		"blocked": STRUCTURE_BASE,
		"void": COBALT_VOID,
		"player_reward": MUSTARD,
		"threat": CORAL,
		"recovery": MINT,
		"boss": BOSS_MAGENTA,
		"text_dark": INK,
		"text_light": IVORY_BRIGHT,
	}


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	var roles := required_color_roles()
	for role in ["walkable", "blocked", "void", "player_reward", "threat", "recovery", "boss"]:
		if not roles.has(role):
			errors.append("missing semantic color role: %s" % role)
	for affinity in [&"kinetic", &"thermal", &"toxin", &"cryo", &"arc", &"hybrid"]:
		if attack_color(affinity).a < 1.0:
			errors.append("attack affinity color must remain opaque: %s" % affinity)
	if not is_equal_approx(PLAYER_VISUAL_RADIUS, 50.0):
		errors.append("player visual radius must remain 50 px")
	if not is_equal_approx(ORDINARY_ENEMY_RADIUS, 44.0):
		errors.append("ordinary enemy visual radius must remain 44 px")
	if not is_equal_approx(INSTALLATION_RADIUS, 62.0):
		errors.append("installation visual radius must remain 62 px")
	if not is_equal_approx(PICKUP_PLINTH_RADIUS, 42.0):
		errors.append("pickup plinth radius must remain 42 px")
	if not is_equal_approx(STAGE_BOSS_RADIUS, 146.0):
		errors.append("stage boss visual radius must remain 146 px")
	if EXPERIENCE_RADII != {&"small":12.0, &"medium":16.0, &"large":22.0}:
		errors.append("experience visual radii must remain 12/16/22 px")
	if not is_equal_approx(HOSTILE_PROJECTILE_ENVELOPE_SCALE, 4.5):
		errors.append("hostile projectile envelope must remain 4.5x collision radius")
	if not is_equal_approx(PLAYER_PRIMARY_PROJECTILE_SCALE, 1.25):
		errors.append("player primary projectile visual must remain 1.25x")
	return errors
