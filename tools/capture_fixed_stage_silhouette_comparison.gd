extends SceneTree

const OUTPUT_PATH := "res://.codex-runtime/uiux/fixed_stage/stage_silhouette_comparison.png"
const OUTPUT_SIZE := Vector2i(1600, 720)
const ENEMY_CATALOG: EnemyCatalog = preload("res://data/enemies/enemy_catalog.tres")
const HAZARD_CATALOG: HazardCatalog = preload("res://data/hazards/hazard_catalog.tres")
const FIXED_LAYOUT_SEED := 0x43415244
const FIXED_LAYOUT_VERSION := 6
const STAGES: Array[Dictionary] = [
	{
		"id": &"ruin_approach",
		"title": "RUIN APPROACH",
		"profile": "res://data/generation/ruin_approach_profile.tres",
		"catalog": "res://data/generation/lower_ruins_room_catalog.tres",
	},
	{
		"id": &"flooded_works",
		"title": "FLOODED WORKS",
		"profile": "res://data/generation/flooded_works_profile.tres",
		"catalog": "res://data/generation/flooded_works_room_catalog.tres",
	},
	{
		"id": &"broken_sanctum",
		"title": "BROKEN SANCTUM",
		"profile": "res://data/generation/broken_sanctum_profile.tres",
		"catalog": "res://data/generation/broken_sanctum_room_catalog.tres",
	},
]

var _failed := false


class SilhouetteCanvas:
	extends Control

	var rows: Array[Dictionary] = []

	func configure(next_rows: Array[Dictionary]) -> void:
		rows = next_rows.duplicate(true)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#101619"))
		var panel_gap := 24.0
		var outer_margin := 30.0
		var panel_width := (
			size.x - outer_margin * 2.0 - panel_gap * float(maxi(rows.size() - 1, 0))
		) / float(maxi(rows.size(), 1))
		for index in rows.size():
			var panel := Rect2(
				Vector2(outer_margin + float(index) * (panel_width + panel_gap), 26.0),
				Vector2(panel_width, size.y - 52.0)
			)
			_draw_stage(panel, rows[index])

	func _draw_stage(panel: Rect2, row: Dictionary) -> void:
		draw_rect(panel, Color("#182226"), true)
		draw_rect(panel, Color("#52636b"), false, 2.0)
		var world_bounds := row.get("world_bounds", Rect2()) as Rect2
		var map_rect := Rect2(
			panel.position + Vector2(18.0, 78.0),
			panel.size - Vector2(36.0, 126.0)
		)
		var scale_factor := minf(
			map_rect.size.x / maxf(world_bounds.size.x, 1.0),
			map_rect.size.y / maxf(world_bounds.size.y, 1.0)
		)
		var projected_size := world_bounds.size * scale_factor
		var origin := map_rect.position + (map_rect.size - projected_size) * 0.5
		var title_font := ThemeDB.fallback_font
		draw_string(
			title_font,
			panel.position + Vector2(18.0, 28.0),
			String(row.get("title", "")),
			HORIZONTAL_ALIGNMENT_LEFT,
			panel.size.x - 36.0,
			22,
			Color("#e8efe9")
		)
		draw_string(
			title_font,
			panel.position + Vector2(18.0, 54.0),
			"range %d · reversals %d · forward rejoins %d"
			% [
				roundi(float(row.get("range", 0.0))),
				int(row.get("reversals", 0)),
				int(row.get("forward_rejoins", 0)),
			],
			HORIZONTAL_ALIGNMENT_LEFT,
			panel.size.x - 36.0,
			14,
			Color("#9fb0b4")
		)
		for room_value in row.get("rooms", []):
			var room := room_value as Dictionary
			var room_rect := _project_rect(
				room.get("bounds", Rect2()) as Rect2,
				world_bounds,
				origin,
				scale_factor
			)
			var room_color := (
				Color(0.28, 0.78, 0.72, 0.32)
				if bool(room.get("required", false))
				else Color(0.84, 0.62, 0.24, 0.48)
			)
			draw_rect(room_rect, room_color, false, 1.0)
		for body_value in row.get("bodies", []):
			var body := body_value as Dictionary
			var body_rect := _project_rect(
				body.get("rect", Rect2()) as Rect2,
				world_bounds,
				origin,
				scale_factor
			)
			var body_color := (
				Color("#7e8f92")
				if bool(body.get("one_way", false))
				else Color("#d2c07a")
			)
			if bool(body.get("one_way", false)):
				draw_line(
					body_rect.position,
					body_rect.position + Vector2(body_rect.size.x, 0.0),
					body_color,
					maxf(body_rect.size.y, 1.5)
				)
			else:
				draw_rect(body_rect, body_color, true)

	func _project_rect(
		world_rect: Rect2,
		world_bounds: Rect2,
		origin: Vector2,
		scale_factor: float
	) -> Rect2:
		return Rect2(
			origin + (world_rect.position - world_bounds.position) * scale_factor,
			world_rect.size * scale_factor
		)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir())
	)
	var run_state := root.get_node_or_null("/root/RunState")
	if run_state == null:
		push_error("Silhouette comparison needs RunState.")
		quit(1)
		return
	var rows: Array[Dictionary] = []
	for stage_index in STAGES.size():
		var row := await _build_stage_row(stage_index, STAGES[stage_index], run_state)
		if row.is_empty():
			_failed = true
		else:
			rows.append(row)
	if _failed:
		quit(1)
		return

	var viewport := SubViewport.new()
	viewport.size = OUTPUT_SIZE
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var canvas := SilhouetteCanvas.new()
	canvas.size = Vector2(OUTPUT_SIZE)
	viewport.add_child(canvas)
	canvas.configure(rows)
	for _frame in 8:
		await process_frame
	for _pass in 3:
		RenderingServer.force_draw(false)
		await process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.save_png(OUTPUT_PATH) != OK:
		push_error("Unable to save fixed-stage silhouette comparison.")
		_failed = true
	else:
		print("FIXED_STAGE_SILHOUETTE_SAVED %s" % OUTPUT_PATH)
	viewport.queue_free()
	await process_frame
	quit(1 if _failed else 0)


func _build_stage_row(
	stage_index: int,
	config: Dictionary,
	run_state: Node
) -> Dictionary:
	var profile := load(String(config["profile"])) as StageProfile
	var catalog := load(String(config["catalog"])) as RoomCatalog
	if profile == null or catalog == null:
		push_error("%s data should load." % config["id"])
		return {}
	var generation := StageGenerationService.new().generate_curated(
		catalog,
		profile,
		ENEMY_CATALOG,
		HAZARD_CATALOG,
		run_state.get("reward_catalog") as RewardCatalog,
		FIXED_LAYOUT_SEED,
		FIXED_LAYOUT_VERSION,
		stage_index,
		run_state.call("get_required_route_limits") as Dictionary
	)
	if not generation.success or generation.plan == null:
		push_error("%s should generate." % config["id"])
		return {}
	var rooms_root := Node2D.new()
	root.add_child(rooms_root)
	var assembly := StageAssembler.assemble(generation.plan, catalog, rooms_root)
	if not assembly.success:
		push_error("%s should assemble." % config["id"])
		rooms_root.queue_free()
		await process_frame
		return {}
	var metrics := StageCompositionMetrics.analyze(
		generation.plan,
		assembly,
		run_state.call("get_required_route_limits") as Dictionary
	)
	var hosts := assembly.get_room_hosts()
	var rooms: Array[Dictionary] = []
	var bodies: Array[Dictionary] = []
	for planned_room in generation.plan.get_rooms():
		var host := hosts.get(String(planned_room.id)) as RoomTemplateHost
		if host == null or host.template_data == null:
			continue
		rooms.append({
			"bounds": Rect2(
				host.global_position + host.template_data.bounds.position,
				host.template_data.bounds.size
			),
			"required": planned_room.required_route,
		})
		for node in host.find_children("*", "StaticBody2D", true, false):
			var body := node as StaticBody2D
			if body == null or body.collision_layer == 0:
				continue
			for child in body.get_children():
				if not child is CollisionShape2D:
					continue
				var collision := child as CollisionShape2D
				if collision.disabled or not collision.shape is RectangleShape2D:
					continue
				var rectangle := collision.shape as RectangleShape2D
				var center := collision.global_position
				bodies.append({
					"rect": Rect2(center - rectangle.size * 0.5, rectangle.size),
					"one_way": collision.one_way_collision or (body.collision_layer & 2) != 0,
				})
	var row := {
		"id": String(config["id"]),
		"title": String(config["title"]),
		"world_bounds": assembly.world_bounds,
		"rooms": rooms,
		"bodies": bodies,
		"range": float(metrics.get("critical_route_vertical_range", 0.0)),
		"reversals": int(metrics.get("direction_reversals", 0)),
		"forward_rejoins": int(metrics.get("forward_rejoin_count", 0)),
	}
	rooms_root.queue_free()
	await process_frame
	return row
