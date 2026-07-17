extends SceneTree

const VIEWPORT_SIZES: Array[Vector2i] = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
]

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://scenes/main/PivotRoot.tscn")
	var pivot := packed.instantiate()
	root.add_child(pivot)
	await _physics_frames(3)

	var sandbox: CombatSandbox3D = pivot.get_node("CombatSandbox3D")
	var traveler: Traveler3D = sandbox.get_node("Traveler")
	var targets: Array[DamageableDummy3D] = [
		sandbox.get_node("NearTarget"),
		sandbox.get_node("RangedTarget"),
		sandbox.get_node("OccludedTarget"),
	]

	_validate_scene_contract(sandbox, traveler, targets)
	_validate_input_contract()
	_validate_numeric_contract()
	await _validate_raster_presentation(sandbox, traveler)
	await _validate_camera_and_arena(sandbox, traveler)
	_park_targets(targets)
	await _validate_movement_and_facing(traveler)
	await _validate_dash_and_action_precedence(traveler)
	await _validate_melee_assist(traveler, targets)
	await _validate_ranged_assist(traveler, targets)
	await _validate_stickiness_and_occlusion(traveler, targets, sandbox.get_node("TallCover"))
	await _validate_guard(traveler, targets)
	await _validate_potion(traveler)
	await _validate_pulse(traveler, sandbox.training_pulse)
	await _validate_reset(sandbox, traveler, targets)
	await _validate_pause(sandbox.get_node("HUD"))

	pivot.queue_free()
	await process_frame
	if _failures.is_empty():
		print(
			"PASS: raster world, diagonal/lateral locomotion, dedicated dash and afterimages, "
			+ "raster melee/ranged/guard, "
			+ "raster projectile, exact input, cutaway arena, follow camera, targeting, "
			+ "cover, potion, pulse, and pause contracts"
		)
		quit(0)
	else:
		for failure in _failures:
			push_error("FAIL: %s" % failure)
		quit(1)


func _validate_scene_contract(
	sandbox: CombatSandbox3D,
	traveler: Traveler3D,
	targets: Array[DamageableDummy3D],
) -> void:
	_expect(sandbox.has_node("Architecture/RoomLarge"), "Kenney room geometry is missing")
	_expect(sandbox.has_node("Architecture/NorthGate"), "Kenney gate geometry is missing")
	_expect(sandbox.has_node("Collision/Floor"), "3D floor collision is missing")
	_expect(sandbox.has_node("TallCover"), "projectile-blocking cover is missing")
	_expect(sandbox.has_node("TrainingPulse"), "timed damage pulse is missing")
	_expect(traveler is CharacterBody3D, "Traveler is not a real 3D character body")
	_expect(traveler.has_node("FacingFeedback/Notch"), "world-space facing notch is missing")
	_expect(traveler.has_node("TargetingAssist/TargetMarker"), "attack target marker is missing")
	_expect(sandbox.has_node("WorldBackdrop/Image"), "2D world backdrop is missing")
	_expect(sandbox.has_node("RasterSurfacePass"), "raster surface pass is missing")
	_expect(traveler.has_node("ActorSprite"), "Traveler Sprite3D presentation is missing")
	_expect(
		is_equal_approx(traveler.get_node("FacingFeedback").position.y, 0.03),
		"facing feedback is not anchored at y=0.03",
	)
	for target in targets:
		_expect(target.is_in_group(&"attack_targets"), "%s is not in attack_targets" % target.name)
		_expect(target.has_node("TargetPoint"), "%s has no TargetPoint" % target.name)
		_expect(target.has_method("is_targetable"), "%s has no is_targetable contract" % target.name)

	var room := sandbox.get_node("Architecture/RoomLarge") as Node3D
	_expect(
		room.scale.is_equal_approx(Vector3(1.1, 0.3, 1.1)),
		"room visual is not the accepted 1.10 x 0.30 x 1.10 cutaway",
	)
	_expect(room.scale.y * 4.233 <= 1.28, "scaled room visual exceeds the 1.28m cutaway limit")
	var floor_shape := (
		(sandbox.get_node("Collision/Floor/CollisionShape3D") as CollisionShape3D).shape
		as BoxShape3D
	)
	_expect(
		floor_shape.size.is_equal_approx(Vector3(19.8, 0.2, 19.8)),
		"walkable floor is not 19.8 x 19.8 metres",
	)
	var long_wall_shape := (
		(sandbox.get_node("Collision/NorthWall/CollisionShape3D") as CollisionShape3D).shape
		as BoxShape3D
	)
	var side_wall_shape := (
		(sandbox.get_node("Collision/EastWall/CollisionShape3D") as CollisionShape3D).shape
		as BoxShape3D
	)
	_expect(
		long_wall_shape.size.is_equal_approx(Vector3(20.9, 1.4, 0.88)),
		"north/south wall collision dimensions changed",
	)
	_expect(
		side_wall_shape.size.is_equal_approx(Vector3(0.88, 1.4, 20.9)),
		"east/west wall collision dimensions changed",
	)
	_expect(
		is_equal_approx(sandbox.get_node("Collision/NorthWall").position.z, -10.34)
		and is_equal_approx(sandbox.get_node("Collision/SouthWall").position.z, 10.34)
		and is_equal_approx(sandbox.get_node("Collision/WestWall").position.x, -10.34)
		and is_equal_approx(sandbox.get_node("Collision/EastWall").position.x, 10.34),
		"perimeter collision centers changed",
	)
	var tall_cover_shape := (
		(sandbox.get_node("TallCover/CollisionShape3D") as CollisionShape3D).shape
		as BoxShape3D
	)
	_expect(is_equal_approx(tall_cover_shape.size.y, 1.15), "tall cover did not adopt 1.15m cutaway height")
	var low_cover_shape := (
		(sandbox.get_node("LowCover/CollisionShape3D") as CollisionShape3D).shape
		as BoxShape3D
	)
	var low_cover_mesh := (sandbox.get_node("LowCover/MeshInstance3D") as MeshInstance3D).mesh
	_expect(is_equal_approx(low_cover_shape.size.y, 1.10), "low cover collision height changed")
	_expect(
		is_equal_approx(low_cover_mesh.get_aabb().size.y, low_cover_shape.size.y),
		"low cover visual and collision heights disagree",
	)

	var camera: Camera3D = sandbox.get_node("CameraRig/Camera3D")
	_expect(camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "camera is not orthographic")
	_expect(camera.current, "isometric camera is not current")
	_expect(is_equal_approx(camera.size, 15.5), "camera size is not 15.5")
	_expect(
		camera.position.is_equal_approx(Vector3(13, 16, 13)),
		"camera local isometric offset changed",
	)
	var imported_meshes := sandbox.get_node("Architecture").find_children("*", "MeshInstance3D", true, false)
	_expect(imported_meshes.size() >= 3, "imported architecture did not instantiate as 3D meshes")


func _validate_input_contract() -> void:
	var expected_keys := {
		&"move_left": KEY_LEFT,
		&"move_right": KEY_RIGHT,
		&"move_up": KEY_UP,
		&"move_down": KEY_DOWN,
		&"melee": KEY_SHIFT,
		&"ranged": KEY_Z,
		&"dash": KEY_SPACE,
		&"guard": KEY_X,
		&"potion": KEY_C,
		&"pause": KEY_ESCAPE,
	}
	for action: StringName in expected_keys:
		_expect(InputMap.has_action(action), "InputMap action %s is missing" % action)
		_expect(_has_physical_key(action, expected_keys[action]), "%s uses the wrong keyboard key" % action)
	_expect(_has_event_type(&"dash", "InputEventJoypadButton"), "dash gamepad binding is missing")
	_expect(_has_event_type(&"melee", "InputEventJoypadButton"), "melee gamepad binding is missing")
	_expect(_has_event_type(&"guard", "InputEventJoypadButton"), "guard gamepad binding is missing")
	_expect(_has_event_type(&"ranged", "InputEventJoypadMotion"), "ranged gamepad trigger is missing")
	_expect(not _has_physical_key(&"melee", KEY_Z), "stale Z melee alias remains in InputMap")
	_expect(not _has_physical_key(&"ranged", KEY_X), "stale X ranged alias remains in InputMap")
	_expect(not _has_physical_key(&"guard", KEY_SHIFT), "stale Shift guard alias remains in InputMap")


func _validate_numeric_contract() -> void:
	_expect(Traveler3D.MOVE_SPEED == 6.0, "3D movement baseline changed")
	_expect(Traveler3D.DASH_SPEED == 14.0, "3D dash speed baseline changed")
	_expect(Traveler3D.DASH_DURATION == 0.18, "3D dash duration baseline changed")
	_expect(ProofProjectile3D.SPEED == 18.0, "3D projectile speed baseline changed")
	_expect(TargetingAssist3D.MELEE_MAX_DISTANCE == 2.75, "melee assist range changed")
	_expect(TargetingAssist3D.RANGED_MAX_DISTANCE == 14.0, "ranged assist range changed")
	_expect(TargetingAssist3D.STICKINESS_SECONDS == 0.45, "target stickiness changed")
	_expect(TargetingAssist3D.ANGLE_SCORE_WEIGHT == 0.75, "target angle score weight changed")
	_expect(TargetingAssist3D.DISTANCE_SCORE_WEIGHT == 0.25, "target distance score weight changed")
	_expect(Traveler3D.RANGED_ACTION_DURATION == 0.32, "ranged sprite action duration changed")
	_expect(Traveler3D.RANGED_RELEASE_TIME == 0.10, "ranged projectile release time changed")
	_expect(TravelerSpritePresenter3D.FRAME_COLUMNS == 4, "Traveler sheet column contract changed")
	_expect(TravelerSpritePresenter3D.DIRECTION_ROWS == 2, "Traveler authored direction row contract changed")
	_expect(
		TravelerSpritePresenter3D.LOCOMOTION_FRAMES_PER_METER == 2.0,
		"Traveler distance-driven sprite cadence changed",
	)
	_expect(
		TravelerSpritePresenter3D.LATERAL_DOMINANCE_RATIO == 1.5,
		"Traveler lateral-sector threshold changed",
	)
	_expect(
		TravelerSpritePresenter3D.DASH_AFTERIMAGE_SPACING == 0.65,
		"Traveler dash afterimage spacing changed",
	)
	_expect(
		TravelerSpritePresenter3D.DASH_AFTERIMAGE_LIFETIME == 0.16,
		"Traveler dash afterimage lifetime changed",
	)
	_expect(
		is_equal_approx(
			TravelerSpritePresenter3D.MELEE_CONTACT_PROGRESS,
			Traveler3D.MELEE_HIT_TIME / Traveler3D.MELEE_DURATION,
		),
		"melee contact sprite no longer matches the authoritative hit time",
	)
	_expect(
		is_equal_approx(
			TravelerSpritePresenter3D.RANGED_RELEASE_PROGRESS,
			Traveler3D.RANGED_RELEASE_TIME / Traveler3D.RANGED_ACTION_DURATION,
		),
		"ranged release sprite no longer matches projectile spawn time",
	)


func _validate_raster_presentation(sandbox: CombatSandbox3D, traveler: Traveler3D) -> void:
	var backdrop := sandbox.get_node("WorldBackdrop/Image") as TextureRect
	var backdrop_environment := (sandbox.get_node("WorldEnvironment") as WorldEnvironment).environment
	_expect(backdrop.texture != null, "2D world backdrop has no texture")
	_expect(
		backdrop.texture.resource_path == "res://art/world/flooded_works/backgrounds/panel_01.png",
		"2D world backdrop no longer uses the approved Flooded Works panel",
	)
	_expect(
		backdrop_environment.background_mode == Environment.BG_CANVAS,
		"3D environment does not reveal the negative-layer Canvas backdrop",
	)

	var surface_pass := sandbox.get_node("RasterSurfacePass") as RasterSurfacePass3D
	_expect(surface_pass.albedo_texture != null, "raster surface pass has no albedo texture")
	_expect(
		surface_pass.albedo_texture.resource_path
		== "res://art/world/flooded_works/isometric/surfaces/foundry-architecture-albedo-v1.png",
		"raster surface pass no longer uses the project albedo",
	)
	_expect(surface_pass.albedo_texture.get_width() == 1024, "surface albedo is not 1024 px wide")
	_expect(surface_pass.albedo_texture.get_height() == 1024, "surface albedo is not 1024 px high")
	_expect(surface_pass.applied_mesh_count >= 5, "raster material did not reach all architecture and cover meshes")
	_expect(surface_pass.surface_material != null, "raster surface material was not created")
	_expect(surface_pass.surface_material.uv1_triplanar, "raster surface material lost triplanar projection")
	_expect(
		surface_pass.surface_material.uv1_world_triplanar,
		"raster surface material lost world-space projection",
	)
	for root_path in surface_pass.surface_roots:
		_assert_raster_material_recursive(surface_pass.get_node(root_path), surface_pass.surface_material)

	var actor_sprite: TravelerSpritePresenter3D = traveler.sprite_presenter
	_expect(actor_sprite.visible, "Traveler raster sprite is hidden")
	_expect(actor_sprite.hframes == 4 and actor_sprite.vframes == 2, "Traveler sheets are not wired as 4x2")
	_expect(is_equal_approx(actor_sprite.pixel_size, 0.005), "Traveler sprite scale changed")
	_expect(actor_sprite.no_depth_test, "Traveler sprite can be hidden by the foreground cutaway")
	_expect(not (traveler.get_node("Visual/Body") as MeshInstance3D).visible, "primitive Traveler body remains visible")
	_expect(not (traveler.get_node("Visual/Head") as MeshInstance3D).visible, "primitive Traveler head remains visible")
	_expect(not (traveler.get_node("Visual/SwordPivot") as Node3D).visible, "3D sword presentation remains visible")
	_expect(not (traveler.get_node("Visual/Shield") as MeshInstance3D).visible, "3D shield presentation remains visible")
	_assert_actor_sheet(
		actor_sprite.locomotion_texture,
		"res://art/world/flooded_works/isometric/actors/traveler-locomotion-sheet-v2.png",
		"locomotion",
	)
	_assert_actor_sheet(
		actor_sprite.lateral_locomotion_texture,
		"res://art/world/flooded_works/isometric/actors/traveler-lateral-sheet-v1.png",
		"lateral locomotion",
	)
	_assert_actor_sheet(
		actor_sprite.dash_texture,
		"res://art/world/flooded_works/isometric/actors/traveler-dash-sheet-v1.png",
		"dash",
	)
	_assert_actor_sheet(
		actor_sprite.melee_texture,
		"res://art/world/flooded_works/isometric/actors/traveler-melee-sheet-v1.png",
		"melee",
	)
	_assert_actor_sheet(
		actor_sprite.ranged_texture,
		"res://art/world/flooded_works/isometric/actors/traveler-ranged-sheet-v1.png",
		"ranged",
	)
	_assert_actor_sheet(
		actor_sprite.guard_texture,
		"res://art/world/flooded_works/isometric/actors/traveler-guard-sheet-v1.png",
		"guard",
	)

	var camera_right := traveler.camera.global_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var camera_away := -traveler.camera.global_basis.z
	camera_away.y = 0.0
	camera_away = camera_away.normalized()
	actor_sprite.present_state(
		camera_away + camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, false, 0.0
	)
	_expect(actor_sprite.current_row == 0 and not actor_sprite.flip_h, "away-right sprite mapping changed")
	_expect(not actor_sprite.current_lateral, "away-right diagonal incorrectly selected lateral art")
	actor_sprite.present_state(
		camera_away - camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, false, 0.0
	)
	_expect(actor_sprite.current_row == 0 and actor_sprite.flip_h, "away-left sprite mirror mapping changed")
	actor_sprite.present_state(
		-camera_away + camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, false, 0.0
	)
	_expect(actor_sprite.current_row == 1 and not actor_sprite.flip_h, "toward-right sprite mapping changed")
	actor_sprite.present_state(
		-camera_away - camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, false, 0.0
	)
	_expect(actor_sprite.current_row == 1 and actor_sprite.flip_h, "toward-left sprite mirror mapping changed")

	actor_sprite.present_state(camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, false, 0.0)
	_expect(
		actor_sprite.current_lateral
		and actor_sprite.current_row == 0
		and not actor_sprite.flip_h
		and actor_sprite.texture == actor_sprite.lateral_locomotion_texture,
		"pure screen-right facing did not select the dedicated lateral sheet",
	)
	actor_sprite.present_state(-camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, false, 0.0)
	_expect(
		actor_sprite.current_lateral
		and actor_sprite.current_row == 0
		and actor_sprite.flip_h
		and actor_sprite.texture == actor_sprite.lateral_locomotion_texture,
		"pure screen-left facing did not mirror the dedicated lateral sheet",
	)

	actor_sprite.present_state(camera_right, traveler.camera, 0.0, -1.0, 0.5, -1.0, false, 0.0)
	_expect(
		actor_sprite.current_state == TravelerSpritePresenter3D.SpriteState.MELEE
		and actor_sprite.current_column == 2
		and actor_sprite.texture == actor_sprite.melee_texture,
		"melee contact state did not select its raster frame",
	)
	actor_sprite.present_state(camera_right, traveler.camera, 0.0, -1.0, -1.0, 0.4, false, 0.0)
	_expect(
		actor_sprite.current_state == TravelerSpritePresenter3D.SpriteState.RANGED
		and actor_sprite.current_column == 2
		and actor_sprite.texture == actor_sprite.ranged_texture,
		"ranged release state did not select its raster frame",
	)
	actor_sprite.present_state(camera_right, traveler.camera, 0.0, -1.0, -1.0, -1.0, true, 0.2)
	_expect(
		actor_sprite.current_state == TravelerSpritePresenter3D.SpriteState.GUARD
		and actor_sprite.current_column == 2
		and actor_sprite.texture == actor_sprite.guard_texture,
		"guard hold state did not select its raster frame",
	)
	actor_sprite.present_state(camera_right, traveler.camera, 0.0, 0.55, -1.0, -1.0, false, 0.0)
	_expect(
		actor_sprite.current_state == TravelerSpritePresenter3D.SpriteState.DASH
		and actor_sprite.current_column == 2
		and actor_sprite.texture == actor_sprite.dash_texture,
		"dash progress did not select its dedicated raster frame",
	)

	traveler.reset_training()
	traveler.combat_facing = camera_right
	traveler.velocity = Vector3.ZERO
	traveler._update_sprite_presentation(0.0, 0.0)
	_expect(actor_sprite.current_column == 0, "idle Traveler does not hold sprite column zero")
	var idle_row := actor_sprite.current_row
	var raster_start := traveler.global_position
	_key_down(KEY_RIGHT)
	var saw_walk_frame := false
	var maximum_walk_column := 0
	for _index in 24:
		await physics_frame
		maximum_walk_column = maxi(maximum_walk_column, actor_sprite.current_column)
		if actor_sprite.current_column != 0:
			saw_walk_frame = true
	_key_up(KEY_RIGHT)
	_expect(
		saw_walk_frame,
		"moving Traveler did not advance its distance-driven walk frame (column=%d, phase=%.3f, distance=%.3f)"
		% [maximum_walk_column, actor_sprite.locomotion_distance, traveler.global_position.distance_to(raster_start)],
	)
	_expect(
		actor_sprite.current_lateral
		and actor_sprite.texture == actor_sprite.lateral_locomotion_texture,
		"real screen-right movement did not retain the lateral walk sheet",
	)
	_expect(actor_sprite.frame / 4 == actor_sprite.current_row, "sprite frame escaped its facing row")
	await _physics_frames(20)
	_expect(actor_sprite.current_column == 0, "stopped Traveler did not return to its idle column")
	_expect(is_zero_approx(actor_sprite.locomotion_distance), "idle did not reset locomotion distance phase")
	_expect(idle_row >= 0 and idle_row < 2, "idle sprite row escaped the two authored directions")
	traveler.reset_training()
	_key_down(KEY_UP)
	await _physics_frames(3)
	_key_up(KEY_UP)
	_expect(
		not actor_sprite.current_lateral and actor_sprite.texture == actor_sprite.locomotion_texture,
		"depth movement incorrectly selected the lateral walk sheet",
	)
	traveler.reset_training()
	var camera_rig := sandbox.get_node("CameraRig") as IsometricCameraRig3D
	camera_rig.global_position = traveler.spawn_position
	await process_frame


func _assert_actor_sheet(texture: Texture2D, expected_path: String, label: String) -> void:
	_expect(texture != null, "Traveler %s sheet is missing" % label)
	if texture == null:
		return
	_expect(texture.resource_path == expected_path, "Traveler %s sheet path changed" % label)
	_expect(texture.get_width() == 2048, "Traveler %s sheet is not 2048 px wide" % label)
	_expect(texture.get_height() == 1024, "Traveler %s sheet is not 1024 px high" % label)
	var sheet_image: Image = texture.get_image()
	_expect(sheet_image != null, "Traveler %s sheet pixels are unavailable" % label)
	if sheet_image == null:
		return
	_expect(sheet_image.detect_alpha() != Image.ALPHA_NONE, "Traveler %s sheet has no alpha" % label)
	_expect(sheet_image.get_pixel(0, 0).a <= 0.01, "Traveler %s top-left is not transparent" % label)
	_expect(sheet_image.get_pixel(2047, 1023).a <= 0.01, "Traveler %s bottom-right is not transparent" % label)
	for row in TravelerSpritePresenter3D.DIRECTION_ROWS:
		for column in TravelerSpritePresenter3D.FRAME_COLUMNS:
			var cell: Image = sheet_image.get_region(Rect2i(column * 512, row * 512, 512, 512))
			var bounds := cell.get_used_rect()
			_expect(bounds.has_area(), "Traveler %s cell %d,%d is empty" % [label, column, row])
			if bounds.has_area():
				_expect(
					bounds.position.x >= 48 and bounds.end.x <= 464,
					"Traveler %s cell %d,%d crosses its horizontal safety margin"
					% [label, column, row],
				)
				_expect(
					absi(bounds.end.y - 482) <= 3,
					"Traveler %s cell %d,%d lost the shared foot baseline (y=%d)"
					% [label, column, row, bounds.end.y],
				)


func _assert_raster_material_recursive(node: Node, expected_material: Material) -> void:
	if node is MeshInstance3D:
		var applied_material := (node as MeshInstance3D).material_override as StandardMaterial3D
		_expect(
			applied_material != null,
			"%s did not receive the shared raster surface material" % node.get_path(),
		)
		if applied_material != null:
			var applied_texture_path := (
				applied_material.albedo_texture.resource_path
				if applied_material.albedo_texture != null
				else "<none>"
			)
			_expect(
				applied_material.albedo_texture == (expected_material as StandardMaterial3D).albedo_texture
				and applied_material.uv1_triplanar
				and applied_material.uv1_world_triplanar,
				"%s raster material mismatch (texture=%s, triplanar=%s, world=%s)"
				% [
					node.get_path(),
					applied_texture_path,
					applied_material.uv1_triplanar,
					applied_material.uv1_world_triplanar,
				],
			)
	for child in node.get_children():
		_assert_raster_material_recursive(child, expected_material)


func _validate_camera_and_arena(sandbox: CombatSandbox3D, traveler: Traveler3D) -> void:
	var camera_rig: IsometricCameraRig3D = sandbox.get_node("CameraRig")
	var camera: Camera3D = camera_rig.camera
	traveler.global_position = Vector3(2.4, 0, -1.8)
	await _process_seconds(1.0)
	var settled_camera_error := camera_rig.global_position.distance_to(Vector3(2.4, 0, -1.8))
	_expect(
		settled_camera_error <= 0.15,
		"camera center did not settle within 0.15m after one second (error=%.3f)" % settled_camera_error,
	)
	_expect_player_screen_ratio(camera, traveler, 0.15, 0.85, "free-follow position")

	for edge_case: Vector3 in [
		Vector3(9.2, 0, 9.2),
		Vector3(-9.2, 0, 9.2),
		Vector3(9.2, 0, -9.2),
		Vector3(-9.2, 0, -9.2),
	]:
		traveler.global_position = edge_case
		await _process_seconds(1.0)
		_expect_player_screen_ratio(camera, traveler, 0.10, 0.90, "clamped edge %s" % edge_case)
		_expect(
			absf(camera_rig.global_position.x) <= 3.5001
			and absf(camera_rig.global_position.z) <= 3.5001
			and is_equal_approx(camera_rig.global_position.y, 0.0),
			"camera rig escaped its X/Z clamp or moved vertically at %s" % edge_case,
		)
		_expect_not_all_corners_visible(camera, root.size, "clamped edge %s" % edge_case)

	for viewport_size in VIEWPORT_SIZES:
		root.size = viewport_size
		await process_frame
		_expect_not_all_corners_visible(camera, viewport_size, "viewport %s" % viewport_size)

	root.size = Vector2i(1280, 720)
	traveler.reset_training()
	await _process_frames(60)


func _validate_movement_and_facing(traveler: Traveler3D) -> void:
	var movement_keys: Array[Key] = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]
	for keycode in movement_keys:
		traveler.reset_training()
		var start := traveler.global_position
		_key_down(keycode)
		await _physics_frames(18)
		_key_up(keycode)
		await _physics_frames(2)
		_expect(
			traveler.global_position.distance_to(start) > 0.9,
			"arrow key %s did not move the Traveler" % OS.get_keycode_string(keycode),
		)
		_expect(absf(traveler.global_position.y - start.y) < 0.05, "planar movement drifted vertically")

	traveler.reset_training()
	var cardinal_start := traveler.global_position
	_key_down(KEY_RIGHT)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	var cardinal_distance := traveler.global_position.distance_to(cardinal_start)
	var persisted_facing := traveler.combat_facing
	await _physics_frames(8)
	_expect(
		traveler.combat_facing.is_equal_approx(persisted_facing),
		"idle state did not preserve the last non-zero movement facing",
	)
	var visual_forward := traveler.facing_feedback.global_basis * Vector3.FORWARD
	visual_forward.y = 0.0
	_expect(
		visual_forward.normalized().dot(traveler.combat_facing) > 0.99,
		"world-facing notch points opposite combat_facing",
	)

	traveler.reset_training()
	var diagonal_start := traveler.global_position
	_key_down(KEY_RIGHT)
	_key_down(KEY_UP)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	_key_up(KEY_UP)
	var diagonal_distance := traveler.global_position.distance_to(diagonal_start)
	var cardinal_direction := traveler._camera_relative_direction(Vector2.RIGHT)
	var diagonal_direction := traveler._camera_relative_direction(Vector2(1, -1).normalized())
	_expect(is_equal_approx(cardinal_direction.length(), 1.0), "cardinal movement intent is not normalized")
	_expect(is_equal_approx(diagonal_direction.length(), 1.0), "diagonal movement intent is not normalized")
	_expect(
		absf(diagonal_distance - cardinal_distance) < cardinal_distance * 0.2,
		"diagonal arrow movement is not normalized (cardinal %.3f, diagonal %.3f)"
		% [cardinal_distance, diagonal_distance],
	)


func _validate_dash_and_action_precedence(traveler: Traveler3D) -> void:
	traveler.reset_training()
	traveler.combat_facing = Vector3.RIGHT
	var start := traveler.global_position
	_key_down(KEY_SPACE)
	_key_down(KEY_SHIFT)
	_key_down(KEY_Z)
	await _physics_frames(2)
	_key_up(KEY_SPACE)
	_key_up(KEY_SHIFT)
	_key_up(KEY_Z)
	_expect(
		traveler.dash_remaining > 0.0
		and traveler.melee_remaining <= 0.0
		and traveler.ranged_cooldown_remaining <= 0.0
		and traveler.ranged_action_remaining <= 0.0,
		"accepted dash did not outrank simultaneous melee and ranged input",
	)
	_expect(
		traveler.sprite_presenter.current_state == TravelerSpritePresenter3D.SpriteState.DASH
		and traveler.sprite_presenter.texture == traveler.sprite_presenter.dash_texture,
		"accepted Space dash did not enter the dedicated dash sheet",
	)
	var initial_afterimages := get_nodes_in_group(&"traveler_dash_afterimages")
	_expect(not initial_afterimages.is_empty(), "dash did not emit its initial raster afterimage")
	var first_afterimage := initial_afterimages[0] as Sprite3D if not initial_afterimages.is_empty() else null
	var first_afterimage_position := (
		first_afterimage.global_position if first_afterimage != null else Vector3.ZERO
	)
	var health_before := traveler.health
	var damage_applied := traveler.receive_damage(20, &"dash_validator")
	_expect(not damage_applied and traveler.health == health_before, "dash startup did not reject damage")
	await _physics_frames(4)
	var active_afterimages := get_nodes_in_group(&"traveler_dash_afterimages")
	_expect(active_afterimages.size() >= 2, "dash did not emit distance-spaced raster afterimages")
	if first_afterimage != null and is_instance_valid(first_afterimage):
		_expect(
			first_afterimage.global_position.distance_to(first_afterimage_position) <= 0.001,
			"dash afterimage followed the Traveler instead of staying in world space",
		)
	await _physics_frames(8)
	_expect(traveler.global_position.distance_to(start) > 1.5, "dash displacement is too short")
	await _process_seconds(0.25)
	_expect(
		get_nodes_in_group(&"traveler_dash_afterimages").is_empty(),
		"expired dash afterimages did not clean themselves up",
	)

	traveler.reset_training()
	_key_down(KEY_SHIFT)
	_key_down(KEY_Z)
	await _physics_frames(2)
	_key_up(KEY_SHIFT)
	_key_up(KEY_Z)
	_expect(
		traveler.melee_remaining > 0.0
		and traveler.ranged_cooldown_remaining <= 0.0
		and traveler.ranged_action_remaining <= 0.0,
		"Shift melee did not outrank simultaneous Z ranged input",
	)
	_key_down(KEY_Z)
	await _physics_frames(2)
	_key_up(KEY_Z)
	_expect(
		traveler.melee_remaining > 0.0
		and traveler.ranged_cooldown_remaining <= 0.0
		and traveler.ranged_action_remaining <= 0.0,
		"Z ranged started during a committed raster melee action",
	)
	await _physics_frames(24)


func _validate_melee_assist(
	traveler: Traveler3D,
	targets: Array[DamageableDummy3D],
) -> void:
	_park_targets(targets)
	var target := targets[0]
	traveler.reset_training()
	traveler.global_position = Vector3.ZERO
	traveler.combat_facing = Vector3.FORWARD
	var target_direction := Vector3(sin(deg_to_rad(70.0)), 0, -cos(deg_to_rad(70.0))).normalized()
	target.global_position = target_direction * 1.45
	target.reset_dummy()
	await _physics_frames(2)

	_key_down(KEY_SHIFT)
	await _physics_frames(2)
	_key_up(KEY_SHIFT)
	_expect(
		traveler.sprite_presenter.current_state == TravelerSpritePresenter3D.SpriteState.MELEE
		and traveler.sprite_presenter.texture == traveler.sprite_presenter.melee_texture,
		"Shift melee did not enter the raster melee sheet",
	)
	var cached_direction := traveler.resolved_attack_direction
	_expect(cached_direction.dot(target_direction) > 0.99, "near melee did not use its 160-degree assist cone")
	_expect(traveler.targeting_assist.target_marker.visible, "melee assist did not show the 0.35s target marker")
	traveler.combat_facing = Vector3.BACK
	await _physics_frames(10)
	_expect(target.health == DamageableDummy3D.MAX_HEALTH - 20, "Shift melee did not hit its assisted target once")
	_expect(
		traveler.resolved_attack_direction.is_equal_approx(cached_direction),
		"movement/facing changes bent the attack after melee startup",
	)
	target.global_position = target_direction * 2.0
	await _physics_frames(2)
	var far_angle_result := traveler.targeting_assist.resolve_attack(
		&"melee",
		traveler.global_position + Vector3.UP * 0.75,
		Vector3.FORWARD,
	)
	_expect(not far_angle_result.assisted, "70-degree melee target remained eligible beyond the near cone")
	_park_targets(targets)
	traveler.targeting_assist.reset_assist()
	var melee_fallback := traveler.targeting_assist.resolve_attack(
		&"melee",
		traveler.global_position + Vector3.UP * 0.75,
		Vector3.RIGHT,
	)
	_expect(
		not melee_fallback.assisted and melee_fallback.direction.dot(Vector3.RIGHT) >= 0.999,
		"melee fallback changed exact intended direction",
	)


func _validate_ranged_assist(
	traveler: Traveler3D,
	targets: Array[DamageableDummy3D],
) -> void:
	await _physics_frames(20)
	_park_targets(targets)
	var target := targets[1]
	traveler.reset_training()
	traveler.global_position = Vector3.ZERO
	traveler.combat_facing = Vector3.FORWARD
	var target_direction := Vector3(sin(deg_to_rad(20.0)), 0, -cos(deg_to_rad(20.0))).normalized()
	target.global_position = target_direction * 6.0
	target.reset_dummy()
	await _physics_frames(2)

	_key_down(KEY_Z)
	await _physics_frames(2)
	_key_up(KEY_Z)
	_expect(
		traveler.sprite_presenter.current_state == TravelerSpritePresenter3D.SpriteState.RANGED
		and traveler.sprite_presenter.texture == traveler.sprite_presenter.ranged_texture,
		"Z ranged did not enter the raster bow sheet",
	)
	_expect(_find_projectile(traveler) == null, "ranged projectile spawned before its raster release frame")
	var cached_direction := traveler.resolved_attack_direction
	_expect(cached_direction.dot(target_direction) > 0.99, "Z ranged did not resolve inside its 50-degree assist cone")
	_expect(traveler.targeting_assist.target_marker.visible, "ranged assist did not show the target marker")
	await _physics_frames(8)
	var projectile := _find_projectile(traveler)
	_expect(projectile != null, "ranged projectile did not spawn on its raster release frame")
	if projectile != null:
		_expect(projectile.visual != null, "ranged projectile has no raster Sprite3D presentation")
		if projectile.visual != null:
			_expect(
				projectile.visual.texture.resource_path
				== "res://art/world/flooded_works/isometric/effects/traveler-ranged-bolt-v1.png",
				"ranged projectile does not use the authored raster bolt",
			)
		_expect(
			projectile.find_children("*", "MeshInstance3D", true, false).is_empty(),
			"ranged projectile still exposes primitive 3D presentation",
		)
	traveler.combat_facing = Vector3.LEFT
	await _physics_frames(24)
	_expect(target.health == DamageableDummy3D.MAX_HEALTH - 16, "Z ranged projectile did not hit its assisted target once")
	_expect(
		traveler.resolved_attack_direction.is_equal_approx(cached_direction),
		"movement/facing changes bent a projectile after launch",
	)
	_expect(not traveler.targeting_assist.target_marker.visible, "target marker exceeded its 0.35s duration")
	target.global_position = Vector3(sin(deg_to_rad(30.0)), 0, -cos(deg_to_rad(30.0))).normalized() * 6.0
	await _physics_frames(2)
	var outside_cone := traveler.targeting_assist.resolve_attack(
		&"ranged",
		traveler.global_position + Vector3.UP * 0.75,
		Vector3.FORWARD,
	)
	_expect(not outside_cone.assisted, "30-degree ranged target passed the 50-degree full cone")


func _validate_stickiness_and_occlusion(
	traveler: Traveler3D,
	targets: Array[DamageableDummy3D],
	cover: StaticBody3D,
) -> void:
	await _physics_frames(20)
	_park_targets(targets)
	traveler.targeting_assist.reset_assist()
	traveler.reset_training()
	traveler.global_position = Vector3.ZERO
	var tie_direction_a := Vector3(sin(deg_to_rad(10.0)), 0, -cos(deg_to_rad(10.0))).normalized()
	var tie_direction_b := Vector3(-sin(deg_to_rad(10.0)), 0, -cos(deg_to_rad(10.0))).normalized()
	targets[0].global_position = tie_direction_a * 5.0
	targets[1].global_position = tie_direction_b * 5.0
	await _physics_frames(2)
	var tie_result := traveler.targeting_assist.resolve_attack(
		&"ranged",
		traveler.global_position + Vector3.UP * 0.75,
		Vector3.FORWARD,
	)
	var expected_tie_target := (
		targets[0]
		if targets[0].get_instance_id() < targets[1].get_instance_id()
		else targets[1]
	)
	_expect(tie_result.target == expected_tie_target, "equal target scores did not break by instance ID")

	_park_targets(targets)
	var sticky_target := targets[1]
	traveler.reset_training()
	traveler.global_position = Vector3.ZERO
	sticky_target.global_position = Vector3(0.7, 0, -5.0)
	sticky_target.reset_dummy()
	await _physics_frames(2)
	var origin := traveler.global_position + Vector3.UP * 0.75
	var first := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.FORWARD)
	var second := traveler.targeting_assist.resolve_attack(
		&"ranged",
		origin,
		Vector3(-0.1, 0, -1).normalized(),
	)
	_expect(first.assisted and second.target == first.target, "ranged target was not sticky for 0.45s")
	var reversed := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.BACK)
	_expect(not reversed.assisted, "intent reversal did not invalidate the sticky ranged target")
	_expect(reversed.direction.is_equal_approx(Vector3.BACK), "unassisted attack changed exact player intent")
	_expect(not traveler.targeting_assist.target_marker.visible, "unassisted attack left a target marker visible")

	traveler.targeting_assist.reset_assist()
	sticky_target.reset_dummy()
	sticky_target.global_position = Vector3(0.4, 0, -4.0)
	await _physics_frames(2)
	var target_before_kill := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.FORWARD)
	sticky_target.receive_hit(999, 0, &"validator")
	await process_frame
	var target_after_kill := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.FORWARD)
	_expect(target_before_kill.assisted and not target_after_kill.assisted, "dead sticky target remained eligible")
	_expect(not traveler.targeting_assist.target_marker.visible, "dead target marker was not hidden immediately")

	traveler.targeting_assist.reset_assist()
	sticky_target.reset_dummy()
	sticky_target.global_position = Vector3(0.4, 0, -4.0)
	await _physics_frames(2)
	var target_before_move := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.FORWARD)
	sticky_target.global_position = Vector3(0, 0, 5.0)
	await _physics_frames(2)
	var target_after_move := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.FORWARD)
	_expect(target_before_move.assisted and not target_after_move.assisted, "out-of-profile sticky target remained eligible")

	_park_targets(targets)
	var occluded_target := targets[2]
	traveler.global_position = Vector3(-3.0, 0, cover.global_position.z)
	traveler.combat_facing = Vector3.RIGHT
	occluded_target.global_position = Vector3(4.3, 0, cover.global_position.z)
	occluded_target.reset_dummy()
	await _physics_frames(2)
	origin = traveler.global_position + Vector3.UP * 0.75
	var blocked := traveler.targeting_assist.resolve_attack(&"ranged", origin, Vector3.RIGHT)
	_expect(not blocked.assisted, "targeting assist selected an enemy through solid cover")

	_key_down(KEY_Z)
	await _physics_frames(2)
	_key_up(KEY_Z)
	await _physics_frames(34)
	_expect(
		occluded_target.health == DamageableDummy3D.MAX_HEALTH,
		"ordinary ranged projectile pierced 1.15m solid cover",
	)


func _validate_guard(
	traveler: Traveler3D,
	targets: Array[DamageableDummy3D],
) -> void:
	_park_targets(targets)
	traveler.reset_training()
	_key_down(KEY_X)
	await _physics_frames(12)
	_expect(
		traveler.guarding
		and traveler.sprite_presenter.current_state == TravelerSpritePresenter3D.SpriteState.GUARD
		and traveler.sprite_presenter.texture == traveler.sprite_presenter.guard_texture
		and traveler.sprite_presenter.current_column >= 2,
		"X did not enter the raster guard hold state",
	)
	_key_down(KEY_SHIFT)
	_key_down(KEY_Z)
	_key_down(KEY_SPACE)
	await _physics_frames(2)
	_key_up(KEY_SHIFT)
	_key_up(KEY_Z)
	_key_up(KEY_SPACE)
	_expect(
		traveler.melee_remaining <= 0.0
		and traveler.ranged_cooldown_remaining <= 0.0
		and traveler.ranged_action_remaining <= 0.0
		and traveler.dash_remaining <= 0.0,
		"held X guard did not outrank melee, ranged, and dash actions",
	)
	traveler.receive_damage(20, &"guard_validator")
	_expect(traveler.health == 93, "guard did not reduce 20 damage to 7")
	var guarded_start := traveler.global_position
	_key_down(KEY_RIGHT)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	var guarded_distance := traveler.global_position.distance_to(guarded_start)
	_key_up(KEY_X)
	await _physics_frames(2)
	_expect(
		not traveler.guarding
		and traveler.sprite_presenter.current_state == TravelerSpritePresenter3D.SpriteState.LOCOMOTION
		and traveler.sprite_presenter.current_lateral
		and traveler.sprite_presenter.texture == traveler.sprite_presenter.lateral_locomotion_texture,
		"guard remained active after X release",
	)
	traveler.reset_training()
	var normal_start := traveler.global_position
	_key_down(KEY_RIGHT)
	await _physics_frames(18)
	_key_up(KEY_RIGHT)
	var normal_distance := traveler.global_position.distance_to(normal_start)
	_expect(guarded_distance < normal_distance * 0.7, "guard did not apply its movement-speed penalty")


func _validate_potion(traveler: Traveler3D) -> void:
	await _physics_frames(20)
	traveler.reset_training()
	traveler.receive_damage(50, &"validator")
	_key_down(KEY_C)
	await _physics_frames(2)
	_key_up(KEY_C)
	await _physics_frames(2)
	_expect(traveler.health == 85, "C potion did not restore 35 health")
	_expect(traveler.potion_charges == 2, "potion charge was not consumed exactly once")


func _validate_pulse(traveler: Traveler3D, pulse: TrainingPulse3D) -> void:
	traveler.reset_training()
	traveler.global_position = pulse.global_position - Vector3(0, pulse.global_position.y, 0)
	await _physics_frames(2)
	pulse.state = TrainingPulse3D.PulseState.STARTUP
	pulse.elapsed = 0.79
	await _physics_frames(3)
	_expect(traveler.health == traveler.max_health - 18, "active pulse did not damage the overlapping player")


func _validate_reset(
	sandbox: CombatSandbox3D,
	traveler: Traveler3D,
	targets: Array[DamageableDummy3D],
) -> void:
	_park_targets(targets)
	traveler.reset_training()
	traveler.global_position = Vector3.ZERO
	targets[0].global_position = Vector3(0, 0, -4.0)
	targets[0].receive_hit(20, 0, &"reset_validator")
	traveler.receive_damage(20, &"reset_validator")
	await _physics_frames(2)
	var assisted := traveler.targeting_assist.resolve_attack(
		&"ranged",
		traveler.global_position + Vector3.UP * 0.75,
		Vector3.FORWARD,
	)
	_expect(assisted.assisted and traveler.targeting_assist.target_marker.visible, "reset fixture did not create target state")
	_key_down(KEY_R)
	await _physics_frames(2)
	_key_up(KEY_R)
	await _physics_frames(2)
	_expect(traveler.global_position.is_equal_approx(traveler.spawn_position), "R did not restore Traveler spawn")
	_expect(traveler.health == traveler.max_health, "R did not restore Traveler health")
	_expect(not traveler.targeting_assist.target_marker.visible, "R did not clear targeting feedback")
	_expect(
		traveler.ranged_action_remaining <= 0.0
		and traveler.sprite_presenter.current_state == TravelerSpritePresenter3D.SpriteState.LOCOMOTION
		and traveler.sprite_presenter.current_column == 0,
		"R did not clear raster action state",
	)
	for target in targets:
		_expect(target.health == DamageableDummy3D.MAX_HEALTH, "R did not reset %s health" % target.name)
	_expect(
		sandbox.training_pulse.state == TrainingPulse3D.PulseState.RECOVERY,
		"R did not reset the training pulse",
	)


func _validate_pause(hud: CombatSandboxHud3D) -> void:
	_key_down(KEY_ESCAPE)
	await process_frame
	_key_up(KEY_ESCAPE)
	await process_frame
	_expect(paused and hud.pause_overlay.visible, "Esc did not pause and reveal the pause overlay")
	var paused_position := hud.traveler.global_position
	_key_down(KEY_RIGHT)
	for _index in 4:
		await process_frame
	_key_up(KEY_RIGHT)
	_expect(hud.traveler.global_position.is_equal_approx(paused_position), "Traveler moved while paused")
	_key_down(KEY_ESCAPE)
	await process_frame
	_key_up(KEY_ESCAPE)
	await process_frame
	_expect(not paused and not hud.pause_overlay.visible, "second Esc did not resume the scene")


func _expect_not_all_corners_visible(
	camera: Camera3D,
	viewport_size: Vector2i,
	context: String,
) -> void:
	var all_corners_visible := true
	for corner: Vector3 in [
		Vector3(-9.9, 0, -9.9),
		Vector3(9.9, 0, -9.9),
		Vector3(9.9, 0, 9.9),
		Vector3(-9.9, 0, 9.9),
	]:
		var screen := camera.unproject_position(corner)
		if not Rect2(Vector2.ZERO, Vector2(viewport_size)).has_point(screen):
			all_corners_visible = false
			break
	_expect(not all_corners_visible, "all room corners fit in %s" % context)


func _expect_player_screen_ratio(
	camera: Camera3D,
	traveler: Traveler3D,
	minimum: float,
	maximum: float,
	context: String,
) -> void:
	var screen := camera.unproject_position(traveler.global_position + Vector3.UP * 0.9)
	var ratio := Vector2(screen.x / root.size.x, screen.y / root.size.y)
	_expect(
		ratio.x >= minimum and ratio.x <= maximum and ratio.y >= minimum and ratio.y <= maximum,
		"player screen ratio %s escaped %.0f-%.0f%% in %s" % [ratio, minimum * 100, maximum * 100, context],
	)


func _park_targets(targets: Array[DamageableDummy3D]) -> void:
	for index in targets.size():
		targets[index].global_position = Vector3(40.0 + index * 3.0, 0, 40.0)
		targets[index].reset_dummy()


func _find_projectile(traveler: Traveler3D) -> ProofProjectile3D:
	for child in traveler.get_parent().get_children():
		if child is ProofProjectile3D:
			return child as ProofProjectile3D
	return null


func _physics_frames(count: int) -> void:
	for _index in count:
		await physics_frame


func _process_frames(count: int) -> void:
	for _index in count:
		await process_frame


func _process_seconds(duration: float) -> void:
	await create_timer(duration).timeout


func _key_down(keycode: Key) -> void:
	Input.parse_input_event(_key_event(keycode, true))


func _key_up(keycode: Key) -> void:
	Input.parse_input_event(_key_event(keycode, false))


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	return event


func _has_physical_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return true
	return false


func _has_event_type(action: StringName, expected_class: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event.get_class() == expected_class:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
