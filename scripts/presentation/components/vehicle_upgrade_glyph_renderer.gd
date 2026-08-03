class_name VehicleUpgradeGlyphRenderer
extends Control

## Shared, presentation-only upgrade-family glyph recipes. Upgrade cards and
## production evidence draw through the same normalized command data.

const SemanticAssets = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

const FAMILY_IDS: Array[StringName] = [
	&"primary",
	&"seeker",
	&"secondary",
	&"defense",
	&"dash",
	&"skill",
	&"element",
	&"mobility",
]

const FAMILY_RECIPES := {
	&"primary":{
		"shape":&"forward_wedge",
		"color":&"player_reward",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(-1.00, -0.72), Vector2(0.18, -0.72),
					Vector2(1.00, 0.00), Vector2(0.18, 0.72),
					Vector2(-1.00, 0.72), Vector2(-0.52, 0.00),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(-0.58, -0.42), Vector2(0.10, -0.42),
					Vector2(0.62, 0.00), Vector2(0.10, 0.42),
					Vector2(-0.58, 0.42), Vector2(-0.30, 0.00),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"secondary",
				"points":[
					Vector2(-0.92, -0.22), Vector2(-0.38, -0.22),
					Vector2(-0.22, 0.00), Vector2(-0.38, 0.22),
					Vector2(-0.92, 0.22),
				],
			},
			{
				"kind":&"line",
				"tone":&"highlight",
				"from":Vector2(-0.42, -0.53),
				"to":Vector2(0.22, -0.53),
				"width":0.10,
			},
		],
	},
	&"seeker":{
		"shape":&"triple_core",
		"color":&"support",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(-0.92, -0.18), Vector2(0.92, -0.18),
					Vector2(0.92, 0.18), Vector2(-0.92, 0.18),
				],
			},
			{
				"kind":&"circle",
				"tone":&"accent",
				"center":Vector2(-0.64, 0.00),
				"radius":0.36,
			},
			{
				"kind":&"circle",
				"tone":&"secondary",
				"center":Vector2.ZERO,
				"radius":0.42,
			},
			{
				"kind":&"circle",
				"tone":&"accent",
				"center":Vector2(0.64, 0.00),
				"radius":0.36,
			},
			{
				"kind":&"circle",
				"tone":&"highlight",
				"center":Vector2.ZERO,
				"radius":0.12,
			},
		],
	},
	&"secondary":{
		"shape":&"diamond",
		"color":&"support",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(0.00, -0.94), Vector2(0.94, 0.00),
					Vector2(0.00, 0.94), Vector2(-0.94, 0.00),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"surface",
				"points":[
					Vector2(0.00, -0.58), Vector2(0.58, 0.00),
					Vector2(0.00, 0.58), Vector2(-0.58, 0.00),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"secondary",
				"points":[
					Vector2(-0.54, 0.00), Vector2(0.00, 0.54),
					Vector2(0.54, 0.00), Vector2(0.00, 0.24),
				],
			},
			{
				"kind":&"circle",
				"tone":&"accent",
				"center":Vector2.ZERO,
				"radius":0.24,
			},
			{
				"kind":&"line",
				"tone":&"highlight",
				"from":Vector2(0.10, -0.62),
				"to":Vector2(0.54, -0.18),
				"width":0.10,
			},
		],
	},
	&"defense":{
		"shape":&"open_brackets",
		"color":&"support",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(-1.00, -0.78), Vector2(-0.42, -0.78),
					Vector2(-0.42, -0.46), Vector2(-0.72, -0.46),
					Vector2(-0.72, 0.46), Vector2(-0.42, 0.46),
					Vector2(-0.42, 0.78), Vector2(-1.00, 0.78),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(1.00, -0.78), Vector2(0.42, -0.78),
					Vector2(0.42, -0.46), Vector2(0.72, -0.46),
					Vector2(0.72, 0.46), Vector2(0.42, 0.46),
					Vector2(0.42, 0.78), Vector2(1.00, 0.78),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(-0.86, -0.56), Vector2(-0.56, -0.56),
					Vector2(-0.56, 0.56), Vector2(-0.86, 0.56),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(0.86, -0.56), Vector2(0.56, -0.56),
					Vector2(0.56, 0.56), Vector2(0.86, 0.56),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"secondary",
				"points":[
					Vector2(-0.24, -0.44), Vector2(0.24, -0.44),
					Vector2(0.36, 0.00), Vector2(0.24, 0.44),
					Vector2(-0.24, 0.44), Vector2(-0.36, 0.00),
				],
			},
		],
	},
	&"dash":{
		"shape":&"solid_chevron",
		"color":&"system",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(1.00, 0.00), Vector2(-0.36, -0.82),
					Vector2(-0.88, -0.48), Vector2(-0.18, 0.00),
					Vector2(-0.88, 0.48), Vector2(-0.36, 0.82),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(0.62, 0.00), Vector2(-0.30, -0.50),
					Vector2(-0.56, -0.30), Vector2(-0.06, 0.00),
					Vector2(-0.56, 0.30), Vector2(-0.30, 0.50),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"secondary",
				"points":[
					Vector2(-1.00, -0.22), Vector2(-0.56, -0.22),
					Vector2(-0.32, 0.00), Vector2(-0.56, 0.22),
					Vector2(-1.00, 0.22), Vector2(-0.78, 0.00),
				],
			},
			{
				"kind":&"line",
				"tone":&"highlight",
				"from":Vector2(-0.30, -0.58),
				"to":Vector2(0.42, -0.12),
				"width":0.10,
			},
		],
	},
	&"skill":{
		"shape":&"bolt",
		"color":&"system",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(-0.18, -1.00), Vector2(0.74, -0.34),
					Vector2(0.22, -0.12), Vector2(0.48, 0.94),
					Vector2(-0.68, 0.26), Vector2(-0.16, 0.02),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(-0.08, -0.62), Vector2(0.38, -0.28),
					Vector2(0.04, -0.08), Vector2(0.20, 0.50),
					Vector2(-0.34, 0.18), Vector2(-0.02, -0.02),
				],
			},
			{
				"kind":&"circle",
				"tone":&"secondary",
				"center":Vector2(-0.62, -0.50),
				"radius":0.16,
			},
			{
				"kind":&"circle",
				"tone":&"secondary",
				"center":Vector2(0.62, 0.48),
				"radius":0.16,
			},
			{
				"kind":&"line",
				"tone":&"highlight",
				"from":Vector2(-0.02, -0.52),
				"to":Vector2(0.24, -0.32),
				"width":0.09,
			},
		],
	},
	&"element":{
		"shape":&"split_diamond",
		"color":&"arc",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(0.00, -1.00), Vector2(0.92, 0.00),
					Vector2(0.00, 1.00), Vector2(-0.92, 0.00),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(0.00, -0.70), Vector2(0.60, -0.04),
					Vector2(0.14, -0.14), Vector2(-0.60, -0.04),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"secondary",
				"points":[
					Vector2(0.00, 0.70), Vector2(0.60, 0.04),
					Vector2(-0.14, 0.14), Vector2(-0.60, 0.04),
				],
			},
			{
				"kind":&"line",
				"tone":&"surface",
				"from":Vector2(-0.58, 0.00),
				"to":Vector2(0.58, 0.00),
				"width":0.13,
			},
			{
				"kind":&"circle",
				"tone":&"highlight",
				"center":Vector2.ZERO,
				"radius":0.12,
			},
		],
	},
	&"mobility":{
		"shape":&"opposing_chevrons",
		"color":&"system",
		"commands":[
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(-1.00, -0.70), Vector2(-0.18, 0.00),
					Vector2(-1.00, 0.70), Vector2(-0.68, 0.70),
					Vector2(0.10, 0.00), Vector2(-0.68, -0.70),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"perimeter",
				"points":[
					Vector2(1.00, -0.70), Vector2(0.18, 0.00),
					Vector2(1.00, 0.70), Vector2(0.68, 0.70),
					Vector2(-0.10, 0.00), Vector2(0.68, -0.70),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(-0.82, -0.40), Vector2(-0.36, 0.00),
					Vector2(-0.82, 0.40), Vector2(-0.62, 0.40),
					Vector2(-0.16, 0.00), Vector2(-0.62, -0.40),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"accent",
				"points":[
					Vector2(0.82, -0.40), Vector2(0.36, 0.00),
					Vector2(0.82, 0.40), Vector2(0.62, 0.40),
					Vector2(0.16, 0.00), Vector2(0.62, -0.40),
				],
			},
			{
				"kind":&"polygon",
				"tone":&"secondary",
				"points":[
					Vector2(-0.14, -0.18), Vector2(0.14, -0.18),
					Vector2(0.14, 0.18), Vector2(-0.14, 0.18),
				],
			},
			{
				"kind":&"line",
				"tone":&"highlight",
				"from":Vector2(-0.50, -0.48),
				"to":Vector2(0.50, -0.48),
				"width":0.08,
			},
		],
	},
}

var _family := &"primary"
var _palette: Dictionary = {}


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(32.0, 28.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func configure(family: StringName, palette: Dictionary) -> void:
	_family = family if family in FAMILY_IDS else &"secondary"
	_palette = palette.duplicate(true)
	queue_redraw()


func _draw() -> void:
	var texture := SemanticAssets.texture(asset_id(_family))
	if texture == null:
		return
	var extent := minf(size.x, size.y)
	var image_size := Vector2.ONE * extent
	draw_texture_rect(
		texture,
		Rect2(size * 0.5 - image_size * 0.5, image_size),
		false,
		Color.WHITE
	)


func local_content_bounds() -> Rect2:
	var extent := minf(size.x, size.y)
	return Rect2(size * 0.5 - Vector2.ONE * extent * 0.5, Vector2.ONE * extent)


func debug_contract() -> Dictionary:
	var local_bounds := local_content_bounds()
	var semantic_asset_id := asset_id(_family)
	return {
		"family":_family,
		"asset_id":semantic_asset_id,
		"control_rect":get_global_rect(),
		"content_rect":Rect2(global_position + local_bounds.position, local_bounds.size),
		"command_count":Array(recipe(_family).get("commands", [])).size(),
		"semantic_asset":SemanticAssets.has_asset(semantic_asset_id),
		"texture_count":1 if SemanticAssets.has_asset(semantic_asset_id) else 0,
	}


static func family_ids() -> Array[StringName]:
	return FAMILY_IDS.duplicate()


static func asset_id(family: StringName) -> StringName:
	var normalized := family if family in FAMILY_IDS else &"secondary"
	if normalized == &"seeker":
		return &"hud/action_seeker"
	return StringName("hud/upgrade_%s" % normalized)


static func recipe(family: StringName) -> Dictionary:
	return Dictionary(
		FAMILY_RECIPES.get(family, FAMILY_RECIPES[&"secondary"])
	).duplicate(true)


static func color_role(family: StringName) -> StringName:
	return StringName(recipe(family).get("color", &"text_primary"))


## Emits CanvasItem draw commands and must be called from the target's draw pass.
static func draw_glyph(
	canvas_item: CanvasItem,
	family: StringName,
	center: Vector2,
	scale: float,
	palette: Dictionary
) -> Rect2:
	var glyph_recipe := recipe(family)
	for command_variant in Array(glyph_recipe.get("commands", [])):
		var command := Dictionary(command_variant)
		var color := _command_color(
			StringName(command.get("tone", &"accent")),
			palette
		)
		match StringName(command.get("kind", &"")):
			&"polygon":
				canvas_item.draw_colored_polygon(
					_scaled_points(
						Array(command.get("points", [])),
						center,
						scale
					),
					color
				)
			&"circle":
				canvas_item.draw_circle(
					center + Vector2(command.get("center", Vector2.ZERO)) * scale,
					float(command.get("radius", 0.0)) * scale,
					color
				)
			&"line":
				canvas_item.draw_line(
					center + Vector2(command.get("from", Vector2.ZERO)) * scale,
					center + Vector2(command.get("to", Vector2.ZERO)) * scale,
					color,
					float(command.get("width", 0.08)) * scale,
					true
				)
	return glyph_bounds(family, center, scale)


static func glyph_bounds(
	family: StringName,
	center: Vector2 = Vector2.ZERO,
	scale: float = 1.0
) -> Rect2:
	var normalized := _recipe_bounds(recipe(family))
	return Rect2(
		center + normalized.position * scale,
		normalized.size * scale
	)


static func validate_recipes() -> PackedStringArray:
	var errors := PackedStringArray()
	if FAMILY_RECIPES.size() != FAMILY_IDS.size():
		errors.append("upgrade glyph recipe count must match the eight family IDs")
	for family in FAMILY_IDS:
		if not FAMILY_RECIPES.has(family):
			errors.append("missing upgrade glyph family recipe: %s" % family)
			continue
		var glyph_recipe := recipe(family)
		var commands := Array(glyph_recipe.get("commands", []))
		if commands.size() < 3:
			errors.append("%s upgrade glyph needs at least three readable planes" % family)
		if not _recipe_bounds(glyph_recipe).has_area():
			errors.append("%s upgrade glyph has empty rendered bounds" % family)
		for command_variant in commands:
			var kind := StringName(Dictionary(command_variant).get("kind", &""))
			if kind not in [&"polygon", &"circle", &"line"]:
				errors.append("%s upgrade glyph has unsupported command %s" % [family, kind])
	return errors


func _draw_scale() -> float:
	return maxf(1.0, minf(size.x, size.y) * 0.42)


static func _scaled_points(
	points: Array,
	center: Vector2,
	scale: float
) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point_variant in points:
		result.append(center + Vector2(point_variant) * scale)
	return result


static func _command_color(tone: StringName, palette: Dictionary) -> Color:
	var accent := Color(palette.get(&"accent", Color.WHITE))
	match tone:
		&"perimeter":
			return Color(palette.get(&"perimeter", accent.darkened(0.72)))
		&"surface":
			return Color(palette.get(&"surface", accent.darkened(0.58)))
		&"secondary":
			return Color(palette.get(&"secondary", accent.darkened(0.30)))
		&"highlight":
			return Color(palette.get(&"highlight", accent.lightened(0.34)))
	return accent


static func _recipe_bounds(glyph_recipe: Dictionary) -> Rect2:
	var result := Rect2()
	var has_result := false
	for command_variant in Array(glyph_recipe.get("commands", [])):
		var command := Dictionary(command_variant)
		var command_rect := Rect2()
		match StringName(command.get("kind", &"")):
			&"polygon":
				command_rect = _points_bounds(Array(command.get("points", [])))
			&"circle":
				var radius := float(command.get("radius", 0.0))
				var circle_center := Vector2(command.get("center", Vector2.ZERO))
				command_rect = Rect2(
					circle_center - Vector2.ONE * radius,
					Vector2.ONE * radius * 2.0
				)
			&"line":
				var line_from := Vector2(command.get("from", Vector2.ZERO))
				var line_to := Vector2(command.get("to", Vector2.ZERO))
				var half_width := float(command.get("width", 0.08)) * 0.5
				var minimum := Vector2(
					minf(line_from.x, line_to.x),
					minf(line_from.y, line_to.y)
				) - Vector2.ONE * half_width
				var maximum := Vector2(
					maxf(line_from.x, line_to.x),
					maxf(line_from.y, line_to.y)
				) + Vector2.ONE * half_width
				command_rect = Rect2(minimum, maximum - minimum)
		if not command_rect.has_area():
			continue
		result = command_rect if not has_result else result.merge(command_rect)
		has_result = true
	return result


static func _points_bounds(points: Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var first := Vector2(points[0])
	var minimum := first
	var maximum := first
	for point_variant in points.slice(1):
		var point := Vector2(point_variant)
		minimum.x = minf(minimum.x, point.x)
		minimum.y = minf(minimum.y, point.y)
		maximum.x = maxf(maximum.x, point.x)
		maximum.y = maxf(maximum.y, point.y)
	return Rect2(minimum, maximum - minimum)
