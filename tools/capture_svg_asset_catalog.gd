extends SceneTree

const OUTPUT_DIR := "res://.codex-runtime/uiux/svg-assets"
const VIEWPORTS: Array[Dictionary] = [
	{"name": "desktop", "size": Vector2i(1536, 1120), "shape_columns": 3, "button_columns": 4, "icon_columns": 11},
	{"name": "compact", "size": Vector2i(960, 1480), "shape_columns": 2, "button_columns": 2, "icon_columns": 8},
]
const SHAPES: Array[Dictionary] = [
	{"name": "PANEL SLAB", "path": "res://art/ui/production/shapes/panel_slab.svg"},
	{"name": "COMPACT PANEL", "path": "res://art/ui/production/shapes/panel_compact.svg"},
	{"name": "REWARD CARD", "path": "res://art/ui/production/shapes/panel_card.svg"},
	{"name": "OBJECTIVE BANNER", "path": "res://art/ui/production/shapes/banner_objective.svg"},
	{"name": "BUTTON PLATE", "path": "res://art/ui/production/shapes/button_plate.svg"},
	{"name": "ACTION SLOT", "path": "res://art/ui/production/shapes/slot_plate.svg"},
]
const ICONS: Array[Dictionary] = [
	{"name": "Back", "path": "res://art/ui/production/icons/icon_back.svg", "role": "navigation"},
	{"name": "Settings", "path": "res://art/ui/production/icons/icon_settings.svg", "role": "navigation"},
	{"name": "Exit", "path": "res://art/ui/production/icons/icon_exit.svg", "role": "navigation"},
	{"name": "Melee", "path": "res://art/ui/production/icons/icon_melee.svg", "role": "equipment"},
	{"name": "Ranged", "path": "res://art/ui/production/icons/icon_ranged.svg", "role": "equipment"},
	{"name": "Shield", "path": "res://art/ui/production/icons/icon_shield.svg", "role": "equipment"},
	{"name": "Armor", "path": "res://art/ui/production/icons/icon_armor.svg", "role": "equipment"},
	{"name": "Spirit", "path": "res://art/ui/production/icons/icon_spirit.svg", "role": "equipment"},
	{"name": "Potion", "path": "res://art/ui/production/icons/icon_potion.svg", "role": "equipment"},
	{"name": "Scrap", "path": "res://art/ui/production/icons/icon_scrap.svg", "role": "material"},
	{"name": "Timber", "path": "res://art/ui/production/icons/icon_timber.svg", "role": "material"},
	{"name": "Fiber", "path": "res://art/ui/production/icons/icon_fiber.svg", "role": "material"},
	{"name": "Steel", "path": "res://art/ui/production/icons/icon_steel.svg", "role": "material"},
	{"name": "Fabric", "path": "res://art/ui/production/icons/icon_fabric.svg", "role": "material"},
	{"name": "Arrows", "path": "res://art/ui/production/icons/icon_arrows.svg", "role": "supply"},
	{"name": "Cartridges", "path": "res://art/ui/production/icons/icon_cartridges.svg", "role": "supply"},
	{"name": "Boss Core", "path": "res://art/ui/production/icons/icon_boss_core.svg", "role": "reward"},
	{"name": "Speed", "path": "res://art/ui/production/icons/icon_speed.svg", "role": "reward"},
	{"name": "Health", "path": "res://art/ui/production/icons/icon_health.svg", "role": "reward"},
	{"name": "Force", "path": "res://art/ui/production/icons/icon_force.svg", "role": "reward"},
	{"name": "Cache", "path": "res://art/ui/production/icons/icon_cache.svg", "role": "interaction"},
	{"name": "Confirm", "path": "res://art/ui/production/icons/icon_confirm.svg", "role": "interaction"},
]

const BACKGROUND := Color("12171a")
const SURFACE := Color("1c2428")
const SURFACE_RAISED := Color("263136")
const SURFACE_SOFT := Color("303d42")
const TEXT := Color("f0f1e8")
const TEXT_MUTED := Color("a8b4ae")
const CYAN := Color("62a9b5")
const AMBER := Color("d4a33f")
const CORAL := Color("d9654f")
const MOSS := Color("6f8f62")
const GREEN := Color("63b987")
const CORE := Color("aa89cf")

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for viewport in VIEWPORTS:
		var viewport_size := viewport["size"] as Vector2i
		root.size = viewport_size
		DisplayServer.window_set_size(viewport_size)
		var catalog := _build_catalog(viewport)
		root.add_child(catalog)
		await _wait_frames(8)
		for _pass in 3:
			RenderingServer.force_draw(false)
			await RenderingServer.frame_post_draw
			await process_frame
		var image := root.get_texture().get_image()
		var output_path := "%s/%s_asset_catalog.png" % [OUTPUT_DIR, viewport["name"]]
		if image == null or image.save_png(output_path) != OK:
			push_error("Unable to save SVG asset catalog: %s" % output_path)
			_failed = true
		catalog.queue_free()
		await _wait_frames(3)
	print("SVG_ASSET_CATALOG_CAPTURE_%s" % ("FAILED" if _failed else "OK"))
	quit(1 if _failed else 0)


func _build_catalog(viewport: Dictionary) -> Control:
	var viewport_size := viewport["size"] as Vector2i
	var page := Control.new()
	page.set_size(Vector2(viewport_size))
	_add_rect(page, Rect2(Vector2.ZERO, Vector2(viewport_size)), BACKGROUND)

	var margin := 40.0 if viewport_size.x >= 1200 else 28.0
	var content_width := float(viewport_size.x) - margin * 2.0
	var header_height := 170.0
	_add_texture(
		page,
		"res://art/ui/production/shapes/panel_slab.svg",
		Rect2(margin, margin, content_width, header_height),
		Color("172024"),
		TextureRect.STRETCH_SCALE
	)
	_add_label(page, "CARDBORNE", Vector2(margin + 38.0, margin + 28.0), 42, TEXT)
	_add_label(page, "PRODUCTION UI · ORIGINAL SVG ASSET KIT", Vector2(margin + 40.0, margin + 78.0), 17, AMBER)
	_add_label(page, "28 tintable masks · no third-party source · no embedded raster, text, filter, or external URL", Vector2(margin + 40.0, margin + 116.0), 15, TEXT_MUTED)

	var y := margin + header_height + 34.0
	y = _add_shape_section(page, Rect2(margin, y, content_width, 0.0), int(viewport["shape_columns"]))
	y += 28.0
	y = _add_button_section(page, Rect2(margin, y, content_width, 0.0), int(viewport["button_columns"]))
	y += 28.0
	_add_icon_section(page, Rect2(margin, y, content_width, 0.0), int(viewport["icon_columns"]))
	return page


func _add_shape_section(parent: Control, bounds: Rect2, columns: int) -> float:
	_add_label(parent, "STRUCTURAL SHAPES", bounds.position, 19, CYAN)
	var top := bounds.position.y + 34.0
	var gap := 12.0
	var card_width := (bounds.size.x - gap * float(columns - 1)) / float(columns)
	var card_height := 152.0
	for index in SHAPES.size():
		var row := index / columns
		var column := index % columns
		var card_rect := Rect2(
			bounds.position.x + float(column) * (card_width + gap),
			top + float(row) * (card_height + gap),
			card_width,
			card_height
		)
		_add_rect(parent, card_rect, Color("182125"))
		var shape := SHAPES[index]
		var preview_rect := card_rect.grow(-20.0)
		preview_rect.size.y -= 24.0
		_add_texture(parent, shape["path"], preview_rect, SURFACE_RAISED, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
		_add_label(parent, shape["name"], Vector2(card_rect.position.x + 16.0, card_rect.end.y - 28.0), 12, TEXT_MUTED)
	var rows := ceili(float(SHAPES.size()) / float(columns))
	return top + float(rows) * card_height + float(rows - 1) * gap


func _add_button_section(parent: Control, bounds: Rect2, columns: int) -> float:
	_add_label(parent, "ONE BUTTON SVG · LIVE STATES", bounds.position, 19, CYAN)
	var states: Array[Dictionary] = [
		{"label": "NORMAL", "fill": SURFACE_RAISED, "accent": CYAN, "offset": 0.0, "focus": false},
		{"label": "FOCUSED", "fill": SURFACE_SOFT, "accent": CYAN, "offset": 0.0, "focus": true},
		{"label": "PRESSED", "fill": Color("1a2226"), "accent": AMBER, "offset": 3.0, "focus": false},
		{"label": "DISABLED", "fill": Color("182024"), "accent": Color("526068"), "offset": 0.0, "focus": false},
	]
	var top := bounds.position.y + 34.0
	var gap := 12.0
	var card_width := (bounds.size.x - gap * float(columns - 1)) / float(columns)
	var card_height := 96.0
	for index in states.size():
		var row := index / columns
		var column := index % columns
		var card_rect := Rect2(
			bounds.position.x + float(column) * (card_width + gap),
			top + float(row) * (card_height + gap),
			card_width,
			card_height
		)
		_add_rect(parent, card_rect, Color("182125"))
		var state := states[index]
		var button_rect := Rect2(card_rect.position + Vector2(12.0, 10.0 + float(state["offset"])), Vector2(card_width - 24.0, 52.0))
		if bool(state["focus"]):
			_add_texture(parent, "res://art/ui/production/shapes/button_plate.svg", button_rect.grow(3.0), CYAN, TextureRect.STRETCH_SCALE)
			button_rect = button_rect.grow(-2.0)
		_add_texture(parent, "res://art/ui/production/shapes/button_plate.svg", button_rect, state["fill"], TextureRect.STRETCH_SCALE)
		_add_rect(parent, Rect2(button_rect.position, Vector2(8.0 if not bool(state["focus"]) else 16.0, button_rect.size.y)), state["accent"])
		_add_label(parent, state["label"], Vector2(button_rect.position.x + 24.0, button_rect.position.y + 14.0), 14, TEXT if index < 3 else TEXT_MUTED)
	var rows := ceili(float(states.size()) / float(columns))
	return top + float(rows) * card_height + float(rows - 1) * gap


func _add_icon_section(parent: Control, bounds: Rect2, columns: int) -> float:
	_add_label(parent, "SEMANTIC ICONS", bounds.position, 19, CYAN)
	var top := bounds.position.y + 34.0
	var gap := 10.0
	var card_width := (bounds.size.x - gap * float(columns - 1)) / float(columns)
	var card_height := 96.0
	for index in ICONS.size():
		var row := index / columns
		var column := index % columns
		var card_rect := Rect2(
			bounds.position.x + float(column) * (card_width + gap),
			top + float(row) * (card_height + gap),
			card_width,
			card_height
		)
		_add_rect(parent, card_rect, SURFACE)
		var icon := ICONS[index]
		var icon_size := 42.0
		_add_texture(
			parent,
			icon["path"],
			Rect2(card_rect.position.x + (card_width - icon_size) * 0.5, card_rect.position.y + 10.0, icon_size, icon_size),
			_role_color(icon["role"]),
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		var label := _add_label(parent, icon["name"], Vector2(card_rect.position.x + 5.0, card_rect.position.y + 59.0), 12, TEXT_MUTED)
		label.set_size(Vector2(card_width - 10.0, 24.0))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rows := ceili(float(ICONS.size()) / float(columns))
	return top + float(rows) * card_height + float(rows - 1) * gap


func _role_color(role: String) -> Color:
	return {
		"navigation": TEXT_MUTED,
		"equipment": CYAN,
		"material": AMBER,
		"supply": MOSS,
		"reward": CORE,
		"interaction": GREEN,
	}.get(role, TEXT)


func _add_rect(parent: Control, rect: Rect2, color: Color) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	parent.add_child(node)
	return node


func _add_texture(parent: Control, path: String, rect: Rect2, tint: Color, stretch_mode: TextureRect.StretchMode) -> TextureRect:
	var texture := load(path) as Texture2D
	var node := TextureRect.new()
	node.position = rect.position
	node.size = rect.size
	node.texture = texture
	node.modulate = tint
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = stretch_mode
	parent.add_child(node)
	if texture == null:
		push_error("SVG texture failed to load: %s" % path)
		_failed = true
	return node


func _add_label(parent: Control, text: String, position: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _wait_frames(frame_count: int) -> void:
	for _frame in frame_count:
		await process_frame
