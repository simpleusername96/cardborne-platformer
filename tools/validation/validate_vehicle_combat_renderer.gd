extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const EnemyUpgradeRenderer = preload(
	"res://scripts/presentation/vehicle_enemy_upgrade_combat_renderer.gd"
)
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
const EffectState = preload("res://scripts/combat/vehicle_effect_state.gd")
const DashUpgradeRuntime = preload(
	"res://scripts/player/vehicle_dash_upgrade_runtime.gd"
)
const AssetProvider = preload(
	"res://scripts/presentation/components/vehicle_semantic_asset_provider.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var renderer := Renderer.new()
	root.add_child(renderer)
	await process_frame
	var snapshot: Dictionary = renderer.debug_snapshot()
	_expect(int(snapshot["enemy_capacity"]) == 320, "renderer shares the 320-hostile store capacity")
	_expect(
		int(snapshot["batches"]) <= 80,
		"combat presentation remains inside the retained eighty-batch ceiling (actual %d)"
		% int(snapshot["batches"])
	)
	_expect(
		int(snapshot["allocated_instances"]) < int(snapshot["maximum_instances"]),
		"component batches reserve bounded working buffers and retain their full growth ceiling"
	)
	var semantic_layer := renderer.get_node_or_null("SemanticTextureLayer") as Node2D
	_expect(
		semantic_layer != null and semantic_layer.z_index == 2,
		"one shared semantic layer draws symbols above body batches without per-object nodes"
	)
	_expect(Art.validate_contract().is_empty(), "combat visual profile satisfies the locked readability contract")
	_validate_primitive_batches(renderer)
	_validate_emp_presentation(renderer)
	_validate_active_weapon_presentation(renderer)
	_validate_health_bar_geometry(renderer)
	_validate_enemy_presentation(renderer)
	_expect(
		AttackContract.LIGHT_PROJECTILE_RADIUS == 6.0
			and AttackContract.STANDARD_PROJECTILE_RADIUS == 7.5
			and AttackContract.HEAVY_PROJECTILE_RADIUS == 9.0,
		"hostile projectile collision radii remain 6/7.5/9 world units"
	)
	_expect(
		renderer.get_node_or_null("Projectile_player_primary") != null
			and renderer.get_node_or_null("Projectile_player_seeker") != null
			and renderer.get_node_or_null("Projectile_hostile_barbed_bolt") != null,
		"primary, seeker, and hostile projectiles own separate semantic batches"
	)
	_expect(
		renderer.get_node_or_null("Player_craft_body") != null
			and renderer.get_node_or_null("Player_hull") == null
			and renderer.get_node_or_null("Player_engine") == null
			and renderer.get_node_or_null("Player_engine_flare") == null
			and renderer.get_node_or_null("Player_primary_mount") == null,
		"one integrated player craft batch replaces fixed sub-parts while thrust reuses the overlay beam"
	)
	_expect(
		renderer.get_node_or_null("Boss_active") != null,
		"all boss appearances reuse one active semantic texture batch"
	)
	_expect(
		renderer.get_node_or_null("Projectile_shared_energy_teardrop") == null
			and renderer.get_node_or_null("Projectile_enemy_arc") == null,
		"the shared and affinity-specific legacy projectile batches are retired"
	)
	for pair in [
		[&"ordinary_pursuer_t1", &"ordinary_pursuer_t2"],
		[&"ordinary_charger_t1", &"ordinary_charger_t2"],
		[&"ordinary_emitter_t1", &"ordinary_defender_t1"],
		[&"ordinary_coordinator_t1", &"ordinary_pursuer_t1"],
		[&"boss_pattern_fixed_beam_01", &"ordinary_emitter_t1"],
	]:
		_expect(
			AssetProvider.texture(StringName("actor/%s" % String(pair[0])))
				!= AssetProvider.texture(StringName("actor/%s" % String(pair[1]))),
			"%s and %s bind distinct authored silhouette textures" % pair
		)
		_expect(
			renderer.get_node_or_null("Enemy_%s" % String(pair[0])) != null
				and renderer.get_node_or_null("Enemy_%s" % String(pair[1])) != null,
			"%s and %s own descriptor mesh batches" % pair
		)
	var enemy := EnemyState.new()
	enemy.id = "renderer_enemy"
	enemy.role = &"ordinary_edge_01"
	enemy.archetype = &"ordinary_pursuer_t1"
	enemy.pos = Vector2(300.0, 300.0)
	enemy.alive = true
	enemy.active = true
	enemy.visual_radius = 26.0
	enemy.shielded = true
	enemy.health_class = &"priority"
	enemy.health = 20.0
	enemy.max_health = 40.0
	enemy.health_visible_timer = 1.0
	enemy.phase = &"startup"
	# Deliberately conflicting live status data proves the renderer consumes only
	# the fixed presentation scalars.
	enemy.statuses = {&"chill":{"stacks":3}}
	enemy.toxin_stack_ratio = 2.0 / 3.0
	enemy.toxin_application_pulse = 1.0
	enemy.committed_dir = Vector2.RIGHT
	enemy.committed_target = Vector2(500.0, 300.0)
	enemy.presentation_facing = Vector2.UP
	_expect(
		is_equal_approx(
			float(renderer.call(
				"_enemy_angle", enemy.archetype, enemy, Vector2.LEFT * 500.0, 0.0
			)),
			Vector2.UP.angle()
		),
		"enemy rendering consumes the published facing instead of inferring a target"
	)
	enemy.attack_telegraphs = [{
		"shape":&"corridor",
		"delivery":&"beam",
		"from":Vector2(300.0, 300.0),
		"to":Vector2(500.0, 300.0),
		"half_width":31.0,
		"damage":14.0,
		"affinity":AttackContract.KINETIC,
		"active_width":0.0,
	}]
	var enemies: Array[EnemyState] = [enemy]
	var projectile_direction := Vector2(3.0, 4.0).normalized()
	var projectile := ProjectileState.new()
	projectile.configure({
		"pos":Vector2(330.0,300.0), "velocity":projectile_direction * 200.0,
		"radius":5.0, "team":&"player", "color":Color.WHITE,
		"affinity":AttackContract.TOXIN,
	}, &"player", 1)
	var projectiles: Array[ProjectileState] = [projectile]
	var hostile_projectile := ProjectileState.new()
	hostile_projectile.configure({
		"pos":Vector2(390.0,300.0), "velocity":Vector2.LEFT * 180.0,
		"radius":5.0, "team":&"enemy", "color":Color.WHITE,
		"affinity":AttackContract.ARC,
	}, &"enemy", 2)
	var hostile_projectiles: Array[ProjectileState] = [hostile_projectile]
	var no_projectiles: Array[ProjectileState] = []
	var no_enemies: Array[EnemyState] = []
	var no_shards: Array[ExperienceShard] = []
	var shard := ExperienceShard.new()
	shard.configure(1, Vector2(340.0, 320.0), 1, &"")
	var shards: Array[ExperienceShard] = [shard]
	var effect_store := EffectStore.new()
	var rendered_effect = effect_store.add_emp_footprint(
		EffectStore.EMP_RELEASE_KIND,
		Vector2(360.0, 320.0),
		Color.WHITE,
		1.0,
		20.0,
		24.0
	)
	rendered_effect.time = 0.5
	var thermal_effect = effect_store.add_thermal_burst_impact(
		Vector2(420.0, 320.0), Color.WHITE, 0.18, 84.0
	)
	thermal_effect.time = 0.18
	var mine_effect = effect_store.add_drop_mine_detonation(
		Vector2(500.0, 340.0), Color.WHITE, 0.18, 108.0
	)
	mine_effect.time = 0.18
	var seeker_effect = effect_store.add_explosive_seeker_impact(
		Vector2(560.0, 300.0), Art.MUSTARD, 0.18, 95.0
	)
	seeker_effect.time = 0.18
	var presentation := {
		"zones":[], "player_position":Vector2(260.0,300.0),
		"hull_direction":Vector2.RIGHT, "aim_direction":Vector2.DOWN,
		"player_hit":false, "muzzle_flash":0.0, "barrier_strength":10.0,
		"player_barrier_hit_remaining":0.0,
		"reduced_motion":true, "run_time":1.0,
		"orbiting_blade_level":0, "secondary":{},
		"cursor_position":Vector2(460.0,300.0),
	}
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effect_store.live,
		Rect2(0,0,1280,720),
		Vector2(260.0,300.0), 1.0, true, "renderer_enemy",
		presentation
	)
	_expect(
		renderer.get_node_or_null("Effect_thermal_burst_impact") == null
			and renderer.get_node_or_null("Effect_drop_mine_detonation") == null
			and renderer.get_node_or_null("Effect_explosive_seeker_impact") == null,
		"instant impacts use the shared primitive batch without dedicated raster nodes"
	)
	var effect_disks := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var effect_disk_buffer := effect_disks.multimesh.buffer
	var expected_effect_disk_radii := [20.0, 84.0, 108.0, 95.0]
	_expect(
		effect_disks.multimesh.visible_instance_count == expected_effect_disk_radii.size(),
		"EMP damage, Thermal, Drop Mine, and Explosive Seeker publish four complete retained area bodies"
	)
	for index in expected_effect_disk_radii.size():
		var offset := index * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
		_expect(
			is_equal_approx(
				Vector2(
					effect_disk_buffer[offset],
					effect_disk_buffer[offset + 4]
				).length(),
				expected_effect_disk_radii[index]
			),
			"transient area body %d starts at its exact final radius" % (index + 1)
		)
	_expect(
		Vector2(
			effect_disk_buffer[Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 3],
			effect_disk_buffer[Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 7]
		).is_equal_approx(Vector2(420.0, 320.0))
			and Vector2(
				effect_disk_buffer[2 * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 3],
				effect_disk_buffer[2 * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 7]
			).is_equal_approx(Vector2(500.0, 340.0))
			and Vector2(
				effect_disk_buffer[3 * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 3],
				effect_disk_buffer[3 * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 7]
			).is_equal_approx(Vector2(560.0, 300.0)),
		"instant-impact disks preserve gameplay-owned origins"
	)
	thermal_effect.time = 0.09
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effect_store.live,
		Rect2(0,0,1280,720),
		Vector2(260.0,300.0), 1.0, true, "renderer_enemy",
		presentation
	)
	effect_disk_buffer = effect_disks.multimesh.buffer
	var thermal_offset := Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
	_expect(
		is_equal_approx(
			Vector2(
				effect_disk_buffer[thermal_offset],
				effect_disk_buffer[thermal_offset + 4]
			).length(),
			84.0
		)
			and is_equal_approx(effect_disk_buffer[thermal_offset + 11], 0.20),
		"Thermal primitive keeps its complete gameplay radius through the hold point"
	)
	snapshot = renderer.debug_snapshot()
	var status_enemy_batch := renderer.get_node("Enemy_ordinary_pursuer_t1") as MultiMeshInstance2D
	var peer_enemy_batch := renderer.get_node("Enemy_ordinary_emitter_t1") as MultiMeshInstance2D
	_expect(
		status_enemy_batch.multimesh.is_using_custom_data()
			and status_enemy_batch.material is ShaderMaterial
			and is_same(status_enemy_batch.material, peer_enemy_batch.material),
		"enemy roles share one custom-data status compositor without a new batch or material per actor"
	)
	var status_enemy_buffer := status_enemy_batch.multimesh.buffer
	var actual_body_modulate := Color(
		status_enemy_buffer[8],
		status_enemy_buffer[9],
		status_enemy_buffer[10],
		status_enemy_buffer[11]
	)
	var actual_status_overlay := Color(
		status_enemy_buffer[12],
		status_enemy_buffer[13],
		status_enemy_buffer[14],
		status_enemy_buffer[15]
	)
	_expect(
		actual_body_modulate.is_equal_approx(Color(0.72, 1.0, 0.88, 1.0))
			and actual_status_overlay.is_equal_approx(Color(Art.TOXIN, 0.76)),
		"reduced motion keeps base protection modulation separate from staged static Toxin colorization"
	)
	presentation["reduced_motion"] = false
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effect_store.live,
		Rect2(0,0,1280,720), Vector2(260.0,300.0), 1.0, true,
		"renderer_enemy", presentation
	)
	effect_disk_buffer = effect_disks.multimesh.buffer
	var mine_offset := 2 * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
	_expect(
		is_equal_approx(
			Vector2(
				effect_disk_buffer[mine_offset],
				effect_disk_buffer[mine_offset + 4]
			).length(),
			108.0
		)
		and is_equal_approx(effect_disk_buffer[mine_offset + 11], 0.099),
		"standard motion starts the Drop Mine primitive at its exact final radius"
	)
	status_enemy_buffer = status_enemy_batch.multimesh.buffer
	actual_status_overlay = Color(
		status_enemy_buffer[12], status_enemy_buffer[13],
		status_enemy_buffer[14], status_enemy_buffer[15]
	)
	_expect(
		actual_status_overlay.is_equal_approx(Color(Art.TOXIN, 0.94)),
		"standard motion raises only the same-size application colorization to the bounded pulse weight"
	)
	enemy.flash = 0.11
	mine_effect.time = 0.09
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effect_store.live,
		Rect2(0,0,1280,720), Vector2(260.0,300.0), 1.0, true,
		"renderer_enemy", presentation
	)
	effect_disk_buffer = effect_disks.multimesh.buffer
	_expect(
		is_equal_approx(
			Vector2(
				effect_disk_buffer[mine_offset],
				effect_disk_buffer[mine_offset + 4]
			).length(),
			108.0
		)
		and is_equal_approx(effect_disk_buffer[mine_offset + 11], 0.18),
		"Drop Mine keeps its exact gameplay radius through the shared hold point"
	)
	status_enemy_buffer = status_enemy_batch.multimesh.buffer
	_expect(
		Color(
			status_enemy_buffer[8], status_enemy_buffer[9],
			status_enemy_buffer[10], status_enemy_buffer[11]
		).is_equal_approx(Color(1.0, 0.66, 0.66, 1.0))
			and is_zero_approx(status_enemy_buffer[15]),
		"generic direct-damage flash wins before the persistent status tint"
	)
	enemy.flash = 0.0
	presentation["reduced_motion"] = true
	var repeated_counts_stable := true
	for _sync_index in 128:
		renderer.sync(
			enemies, projectiles, hostile_projectiles, shards, effect_store.live,
			Rect2(0,0,1280,720),
			Vector2(260.0,300.0), 1.0, true, "renderer_enemy",
			presentation
		)
	var repeated_snapshot: Dictionary = renderer.debug_snapshot()
	for key in [
		"visible_instances", "batch_counts", "health_bar_count",
		"priority_marker_count",
		"semantic_texture_draw_count",
		"floating_damage_draw_count",
	]:
		repeated_counts_stable = (
			repeated_counts_stable and snapshot[key] == repeated_snapshot[key]
		)
	_expect(
		repeated_counts_stable,
		"128 borrowed-frame syncs preserve actor, projectile, shard, effect, and overlay counts"
	)
	snapshot = repeated_snapshot
	_expect(
		int(snapshot["floating_damage_draw_count"]) == 0,
		"combat presentation does not render floating damage text"
	)
	var experience_batch := renderer.get_node_or_null(
		"Experience_master"
	) as MultiMeshInstance2D
	_expect(
		experience_batch != null
			and experience_batch.texture == AssetProvider.texture(
				&"pickup/experience_master"
			)
			and experience_batch.multimesh.visible_instance_count == 1,
		"all experience values share one authored master batch"
	)
	_expect(
		renderer.get_node_or_null("Experience_small") == null
			and renderer.get_node_or_null("Experience_medium") == null
			and renderer.get_node_or_null("Experience_large") == null,
		"legacy tier-specific experience batches stay retired"
	)
	_expect(int(snapshot["visible_instances"]) >= 10, "renderer publishes bodies and semantic overlays as retained instances")
	_expect(
		int(snapshot["semantic_texture_draw_count"])
			<= int(snapshot["semantic_texture_draw_capacity"]),
		"semantic texture draws stay inside the preallocated record capacity"
	)
	var corridor_caps := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var corridor_boundaries := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	_expect(
		corridor_caps.multimesh.visible_instance_count == 4
			and corridor_boundaries.multimesh.visible_instance_count == 0,
		"ordinary startup corridors add no area geometry beyond active effect bodies"
	)
	var enemy_batch := renderer.get_node("Enemy_ordinary_pursuer_t1") as MultiMeshInstance2D
	var enemy_buffer := enemy_batch.multimesh.buffer
	_expect(
		enemy_batch.material is ShaderMaterial
			and (enemy_batch.material as ShaderMaterial).shader.resource_path
				== "res://scripts/presentation/shaders/vehicle_enemy_status_overlay.gdshader",
		"authored actor batch uses only the shared alpha-clipped status compositor"
	)
	_expect(
		Vector2(enemy_buffer[3], enemy_buffer[7]).is_equal_approx(Vector2(300.0, 300.0)),
		"batched buffer preserves enemy position"
	)
	_expect(
		is_equal_approx(
			Vector2(enemy_buffer[0], enemy_buffer[4]).length(),
			26.0
		),
		"batched buffer preserves the selected enemy presentation scale"
	)
	var projectile_visual := renderer.get_node(
		"Projectile_player_primary"
	) as MultiMeshInstance2D
	var projectile_buffer := projectile_visual.multimesh.buffer
	_expect(
		Vector2(projectile_buffer[3], projectile_buffer[7]).is_equal_approx(
			Vector2(330.0, 300.0)
		),
		"projectile semantic pivot remains centered on collision state"
	)
	_expect(
		Vector2(projectile_buffer[0], projectile_buffer[4]).is_equal_approx(
		projectile_direction * 5.0 * Art.PLAYER_PRIMARY_PROJECTILE_SCALE
			* Art.PROJECTILE_LENGTH_FACTOR
		),
		"player primary image uses the reduced presentation length"
	)
	_expect(
		projectile_visual.texture != null,
		"player primary batch binds its approved raster image"
	)
	var player_craft := renderer.get_node("Player_craft_body") as MultiMeshInstance2D
	var craft_buffer := player_craft.multimesh.buffer
	_expect(
		player_craft.multimesh.visible_instance_count == 1
			and Vector2(craft_buffer[3], craft_buffer[7]).is_equal_approx(
				Vector2(260.0, 300.0)
			)
			and Vector2(craft_buffer[0], craft_buffer[4]).normalized()
				.is_equal_approx(Vector2.RIGHT)
			and player_craft.texture != null,
		"one authored craft body remains centered and follows the hull direction"
	)
	for status_id in [&"poison", &"chill"]:
		_expect(
			renderer.get_node_or_null("Status_%s" % status_id) == null,
			"%s does not create a raster orbit icon" % status_id
		)
	var renderer_source := FileAccess.get_file_as_string(
		"res://scripts/presentation/vehicle_combat_renderer.gd"
	)
	var arc_area_section := renderer_source.get_slice(
		"func _sync_area_telegraph", 1
	).get_slice("func _sync_experience", 0)
	_expect(
		arc_area_section.count("_write_danger_ring(") == 2
			and arc_area_section.contains("radial_band_boundaries")
			and not arc_area_section.contains("_write_diamond("),
		"every damaging area uses gameplay-owned concentric bands and one exact outer ring"
	)
	var hostile_visual := renderer.get_node(
		"Projectile_hostile_barbed_bolt"
	) as MultiMeshInstance2D
	var hostile_buffer := hostile_visual.multimesh.buffer
	_expect(
		Vector2(hostile_buffer[0], hostile_buffer[4]).is_equal_approx(
			Vector2.LEFT * 5.0 * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
				* Art.PROJECTILE_LENGTH_FACTOR
		),
		"hostile visual envelope uses the reduced presentation length"
	)
	_expect(
		Vector2(hostile_buffer[3], hostile_buffer[7]).is_equal_approx(
			Vector2(390.0, 300.0)
		),
		"hostile projectile remains centered on collision state"
	)
	_expect(
		is_equal_approx(
			Vector2(hostile_buffer[1], hostile_buffer[5]).length(),
			5.0 * Art.HOSTILE_PROJECTILE_ENVELOPE_SCALE
				* Art.HOSTILE_PROJECTILE_THICKNESS_FACTOR
		),
		"hostile visual envelope uses twice the previous presentation thickness"
	)
	_expect(
		projectile_visual.texture != null
			and projectile_visual.multimesh.mesh is QuadMesh
			and projectile_visual.multimesh.visible_instance_count == 1
			and hostile_visual.texture != null
			and hostile_visual.multimesh.visible_instance_count == 1,
		"player and hostile projectiles retain distinct texture-capable surfaces"
	)
	_validate_mystery_device_presentation(renderer, no_enemies, no_projectiles, no_shards)
	await _validate_enemy_upgrade_device_presentation(
		no_enemies, no_projectiles, no_shards, effect_store.live
	)
	_validate_conditional_attack_footprints(
		renderer, no_enemies, no_projectiles, no_shards
	)
	_validate_player_directional_cues(
		renderer,
		no_enemies,
		no_projectiles,
		no_shards
	)
	enemy.family_trait = &"splitter"
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effect_store.live,
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 1.0, true,
		"renderer_enemy", presentation
	)
	var base_pursuer_batch := renderer.get_node("Enemy_ordinary_pursuer_t1") as MultiMeshInstance2D
	var splitter_pursuer_batch := renderer.get_node("Enemy_ordinary_pursuer_t1_splitter") as MultiMeshInstance2D
	_expect(
		base_pursuer_batch.multimesh.visible_instance_count == 0
			and splitter_pursuer_batch.multimesh.visible_instance_count == 1
			and splitter_pursuer_batch.texture == AssetProvider.texture(
				&"actor/ordinary_pursuer_splitter_t1"
			)
			and splitter_pursuer_batch.texture != base_pursuer_batch.texture,
		"a family trait resolves its own authored body batch instead of the base-family image"
	)
	var crowd: Array[EnemyState] = []
	for index in 320:
		var crowd_enemy := EnemyState.new()
		crowd_enemy.id = "crowd_%02d" % index
		crowd_enemy.role = &"ordinary_edge_01"
		crowd_enemy.archetype = &"ordinary_pursuer_t1"
		crowd_enemy.pos = Vector2(
			40.0 + float(index % 20) * 62.0,
			40.0 + float(index / 20) * 40.0
		)
		crowd_enemy.alive = true
		crowd_enemy.active = true
		crowd_enemy.visual_radius = 26.0
		crowd_enemy.health_class = &"priority"
		crowd_enemy.health = 20.0
		crowd_enemy.max_health = 40.0
		crowd_enemy.health_visible_timer = 1.0
		crowd_enemy.phase = &"move"
		crowd.append(crowd_enemy)
	renderer.sync(
		crowd, no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2(640.0,360.0), 2.0, true,
		"crowd_39"
	)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["health_bar_count"]) == 320
			and int(snapshot["ordinary_health_bar_count"]) == 320
			and int(snapshot["fixed_health_bar_count"]) == 0
			and int(snapshot["health_bar_overflow"]) == 0,
		"all 320 visible ordinary enemies receive world health bars without overflow"
	)
	_expect(
		int(snapshot["batch_allocations"]["Overlay_health"])
			== Renderer.HEALTH_BAR_INSTANCE_CAPACITY,
		"the structural world-health batch preallocates two instances for every hostile slot"
	)
	var crowd_health := renderer.get_node("Overlay_health") as MultiMeshInstance2D
	_expect(
		crowd_health.multimesh.visible_instance_count == 640,
		"320 visible enemies consume exactly 640 retained health-bar instances"
	)
	_expect(
		int(snapshot["priority_marker_count"]) == 0,
		"ordinary priority-target markers are removed"
	)
	var crowd_body := renderer.get_node("Enemy_ordinary_pursuer_t1") as MultiMeshInstance2D
	_expect(
		crowd_body.multimesh.visible_instance_count == 320
			and crowd_body.multimesh.instance_count >= 320,
		"adaptive component buffers grow without hiding ordinary enemy bodies"
	)
	var installations: Array[EnemyState] = []
	var installation_roles: Array[StringName] = [&"ordinary_fixed_beam_01"]
	for index in 16:
		var installation := EnemyState.new()
		var role: StringName = installation_roles[
			index % installation_roles.size()
		]
		installation.id = "installation_%02d" % index
		installation.role = role
		installation.archetype = &"boss_pattern_fixed_beam_01"
		installation.runtime_slot = index
		installation.pos = Vector2(
			100.0 + float(index % 8) * 140.0,
			160.0 + float(index / 8) * 300.0
		)
		installation.alive = true
		installation.active = true
		installation.visual_radius = 34.0
		installation.health = 40.0
		installation.max_health = 80.0
		installations.append(installation)
	renderer.sync(
		installations, no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2(640.0,360.0), 2.0, true
	)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["fixed_health_bar_count"]) == 16
			and int(snapshot["health_bar_count"]) == 16
			and int(snapshot["health_bar_overflow"]) == 0,
		"all visible fixed enemies receive world health bars"
	)
	var projectile_attacker := EnemyState.new()
	projectile_attacker.id = "projectile_attacker"
	projectile_attacker.role = &"ordinary_lane_01"
	projectile_attacker.archetype = &"ordinary_emitter_t1"
	projectile_attacker.pos = Vector2(300.0, 360.0)
	projectile_attacker.visual_radius = 26.0
	projectile_attacker.alive = true
	projectile_attacker.active = true
	projectile_attacker.phase = &"startup"
	projectile_attacker.attack_telegraphs = [{
		"shape":&"source",
		"delivery":&"projectile",
		"origin":Vector2(330.0, 360.0),
		"direction":Vector2.RIGHT,
		"damage":12.0,
		"affinity":AttackContract.KINETIC,
		"readiness":0.7,
	}]
	renderer.sync(
		[projectile_attacker], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	_expect(
		beam_batch.multimesh.visible_instance_count == 0,
		"visible projectile attacks rely on muzzle direction and the projectile body"
	)
	projectile_attacker.pos = Vector2(-120.0, 360.0)
	projectile_attacker.attack_telegraphs[0]["origin"] = Vector2(-90.0, 360.0)
	renderer.sync(
		[projectile_attacker], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 0,
		"an off-screen projectile startup does not draw a predicted route"
	)
	var incoming_projectile := ProjectileState.new()
	incoming_projectile.configure({
		"pos":Vector2(-120.0, 360.0),
		"velocity":Vector2.RIGHT * 500.0,
		"radius":6.0,
		"damage":12.0,
		"affinity":AttackContract.KINETIC,
	}, &"enemy", 3)
	var incoming_projectiles: Array[ProjectileState] = [incoming_projectile]
	renderer.sync(
		[], no_projectiles, incoming_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 0,
		"an unseen live projectile does not draw an entry path"
	)
	var open_boss := EnemyState.new()
	open_boss.id = "open_boss"
	open_boss.role = &"boss"
	open_boss.archetype = &"boss_actor"
	open_boss.boss_variant = &"boss_stage_01"
	open_boss.boss_shield_state = &"shield_up"
	open_boss.pos = Vector2(700.0, 360.0)
	open_boss.visual_radius = Art.STAGE_BOSS_RADIUS
	open_boss.health = 160.0
	open_boss.max_health = 320.0
	open_boss.alive = true
	open_boss.active = true
	var shield_presentation := _player_presentation(Vector2.ZERO, false)
	shield_presentation["orbiting_blade_level"] = 0
	shield_presentation["secondary"]["blade_count"] = 0
	shield_presentation["boss_shield"] = {
		"shield_kind":&"segmented_guard",
		"effect":&"guard",
		"state":&"shield_up",
		"segment_count":3,
		"segment_arc":deg_to_rad(80.0),
		"gap_arc":deg_to_rad(40.0),
		"rotation":0.0,
	}
	renderer.sync(
		[open_boss], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true, "open_boss",
		shield_presentation
	)
	var diamond_batch := renderer.get_node("Overlay_diamond") as MultiMeshInstance2D
	_expect(
		diamond_batch.multimesh.visible_instance_count == 5,
		"boss shield state adds no diamond beyond the shared five-part player cursor"
	)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["boss_health_bar_count"]) == 1
			and int(snapshot["ordinary_health_bar_count"]) == 0
			and int(snapshot["installation_health_bar_count"]) == 0
			and int(snapshot["health_bar_count"]) == 1,
		"the boss owns one large world-attached health bar without consuming the installation budget"
	)
	var boss_health_batch := renderer.get_node("Overlay_health") as MultiMeshInstance2D
	_expect(
		boss_health_batch.multimesh.buffer[7] < open_boss.pos.y,
		"the boss health bar is positioned above its world body"
	)
	var boss_ring_batch := renderer.get_node("Overlay_ring") as MultiMeshInstance2D
	_expect(
		boss_ring_batch.multimesh.visible_instance_count == 0
			and beam_batch.multimesh.visible_instance_count == 30
			and Renderer.BOSS_SHIELD_SEGMENT_THICKNESS >= 12.0,
		"Stage 3 boss renders three collision-matched shield segments without a full ring"
	)
	var destruction_presentation := _player_presentation(Vector2.ZERO, false)
	destruction_presentation["dying_boss_id"] = open_boss.id
	destruction_presentation["boss_destruction"] = {
		"body_alpha":0.75,
		"body_tint":Color(0.48, 0.50, 0.54),
	}
	renderer.sync(
		[open_boss], no_projectiles, no_projectiles, [], [],
		Rect2(0, 0, 1280, 720), Vector2.ZERO, 0.0, true, "",
		destruction_presentation
	)
	var death_explosions := renderer.debug_semantic_texture_draws(
		&"effect/boss_death_explosion"
	)
	var dying_boss_batch := renderer.get_node("Boss_active") as MultiMeshInstance2D
	_expect(
		death_explosions.is_empty()
			and is_equal_approx(float(dying_boss_batch.multimesh.buffer[11]), 0.75)
			and int(renderer.debug_snapshot()["boss_health_bar_count"]) == 0,
		"boss death uses only the retained tinted body fade without an explosion overlay"
	)
	var run_source := FileAccess.get_file_as_string(
		"res://scripts/vehicle/vehicle_run.gd"
	)
	_expect(
		not renderer_source.contains("_sync_projectile_telegraph")
			and not renderer_source.contains("_sync_incoming_projectile_cue")
			and not renderer_source.contains("_sync_collective_tactic_module"),
		"decorative projectile-entry and collective route helpers stay removed"
	)
	_expect(
		not run_source.contains('&"cue/crosshair", position')
			and renderer_source.contains(
				"cursor_position + direction * 18.0, 6.0, Art.SYSTEM"
			),
		"enemy vulnerability has no crosshair and the independent aim cursor is neutral"
	)
	var offscreen_enemy := EnemyState.new()
	offscreen_enemy.id = "offscreen_attacker"
	offscreen_enemy.role = &"ordinary_gap_01"
	offscreen_enemy.archetype = &"ordinary_coordinator_t1"
	offscreen_enemy.pos = Vector2(1800.0, 300.0)
	offscreen_enemy.alive = true
	offscreen_enemy.active = true
	offscreen_enemy.phase = &"startup"
	offscreen_enemy.attack_telegraphs = [{
		"shape":&"area",
		"center":Vector2(640.0, 360.0),
		"radius":175.0,
		"damage":24.0,
		"affinity":AttackContract.THERMAL,
		"readiness":0.0,
	}]
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var offscreen_enemy_batch := renderer.get_node(
		"Enemy_ordinary_coordinator_t1"
	) as MultiMeshInstance2D
	var area_disk := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var area_ring := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	_expect(
		offscreen_enemy_batch.multimesh.visible_instance_count == 0,
		"off-screen attacker body remains culled"
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 1
			and area_ring.multimesh.visible_instance_count == 3,
		"off-screen artillery draws one full-area fill and three exact boundaries"
	)
	var early_area_buffer := area_disk.multimesh.buffer
	var early_area_radius := Vector2(early_area_buffer[0], early_area_buffer[4]).length()
	var early_area_alpha := early_area_buffer[11]
	offscreen_enemy.attack_telegraphs[0]["readiness"] = 0.5
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var middle_area_buffer := area_disk.multimesh.buffer
	_expect(
		is_equal_approx(early_area_radius, 175.0)
			and is_equal_approx(
				Vector2(middle_area_buffer[0], middle_area_buffer[4]).length(),
				175.0
			)
			and is_equal_approx(early_area_alpha, 0.06)
			and is_equal_approx(middle_area_buffer[11], 0.18),
		"radial readiness darkens the same full footprint from start to midpoint"
	)
	var armed_mine := EnemyState.new()
	armed_mine.id = "armed_mine"
	armed_mine.role = &"ordinary_fixed_area_01"
	armed_mine.archetype = &"ordinary_charger_t1"
	armed_mine.pos = Vector2(640.0, 360.0)
	armed_mine.visual_radius = 42.0
	armed_mine.alive = true
	armed_mine.active = true
	armed_mine.phase = &"mine_armed"
	armed_mine.phase_time = 0.25
	renderer.sync(
		[armed_mine], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		area_ring.multimesh.visible_instance_count == 0,
		"armed mines use their body state without a proximity or damage ring"
	)
	offscreen_enemy.role = &"boss"
	offscreen_enemy.phase = &"boss_startup"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 1
			and area_ring.multimesh.visible_instance_count == 3,
		"boss bombardment startup keeps one exact full-area body and band boundaries"
	)
	offscreen_enemy.attack_telegraphs[0]["readiness"] = 1.0
	offscreen_enemy.phase = &"boss_active"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var late_disk_buffer := area_disk.multimesh.buffer
	var late_disk_color := Color(
		late_disk_buffer[8],
		late_disk_buffer[9],
		late_disk_buffer[10],
		late_disk_buffer[11]
	)
	var late_area_buffer := area_ring.multimesh.buffer
	var late_area_color := Color(
		late_area_buffer[8],
		late_area_buffer[9],
		late_area_buffer[10],
		late_area_buffer[11]
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 1
			and area_ring.multimesh.visible_instance_count == 3
			and Vector2(late_disk_buffer[3], late_disk_buffer[7])
				.is_equal_approx(Vector2(640.0, 360.0))
			and is_equal_approx(
				Vector2(late_disk_buffer[0], late_disk_buffer[4]).length(),
				175.0
			)
			and is_equal_approx(late_disk_color.a, 0.30)
			and Color(late_disk_color, 1.0).is_equal_approx(Color(Art.DANGER, 1.0))
			and Color(late_area_color, 1.0).is_equal_approx(Color(Art.SPACE_BLACK, 1.0))
			and is_equal_approx(late_area_color.a, 0.82),
		"boss active area reaches the darkest full-footprint readiness state"
	)
	offscreen_enemy.phase = &"active"
	offscreen_enemy.role = &"ordinary_gap_01"
	offscreen_enemy.pos = Vector2(180.0, 360.0)
	offscreen_enemy.visual_radius = 50.0
	offscreen_enemy.attack_telegraphs = [{
		"shape":&"corridor",
		"delivery":&"beam",
		"from":Vector2(180.0, 360.0),
		"to":Vector2(900.0, 360.0),
		"half_width":58.0,
		"damage":28.0,
		"affinity":AttackContract.ARC,
		"active_width":54.0,
		"readiness":0.72,
		"beam_growth_seconds":AttackContract.EMITTED_BEAM_GROWTH_SECONDS,
		"active_seconds":0.60,
	}]
	offscreen_enemy.phase = &"startup"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 0
			and area_disk.multimesh.visible_instance_count == 2
			and area_ring.multimesh.visible_instance_count == 0,
		"forward-emitted beam startup draws only its source-attached charge orb"
	)
	var startup_disk_buffer := area_disk.multimesh.buffer
	var startup_intensity := smoothstep(0.0, 1.0, 0.72)
	_expect(
		Vector2(startup_disk_buffer[3], startup_disk_buffer[7])
			.is_equal_approx(Vector2(216.0, 360.0))
			and is_equal_approx(
				Vector2(startup_disk_buffer[0], startup_disk_buffer[4]).length(),
				54.0 * 0.68 * lerpf(0.84, 1.0, startup_intensity)
			)
			and Color(
				startup_disk_buffer[8], startup_disk_buffer[9],
				startup_disk_buffer[10], 1.0
			).is_equal_approx(Color(Art.DANGER, 1.0)),
		"startup charge orb sits at the committed muzzle without any path geometry"
	)
	offscreen_enemy.phase = &"active"
	offscreen_enemy.phase_time = 0.45
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 3
			and area_disk.multimesh.visible_instance_count == 6,
		"growing forward-emitted beam uses three borderless rounded energy planes"
	)
	var active_beam_buffer := beam_batch.multimesh.buffer
	_expect(
		is_equal_approx(
			Vector2(active_beam_buffer[0], active_beam_buffer[4]).length(),
			252.0
		)
			and is_equal_approx(active_beam_buffer[5], 54.0 * 0.5)
			and is_equal_approx(active_beam_buffer[17], minf(20.0, 54.0 * 0.34) * 0.5)
			and is_equal_approx(active_beam_buffer[29], minf(7.0, 54.0 * 0.10) * 0.5)
			and is_equal_approx(active_beam_buffer[11], 0.92)
			and is_equal_approx(active_beam_buffer[23], 0.88)
			and is_equal_approx(active_beam_buffer[35], 1.0),
		"at 0.15 seconds the visible beam reaches the collision-owned three-quarter length"
	)
	offscreen_enemy.pos = Vector2(540.0, 360.0)
	offscreen_enemy.attack_telegraphs = [{
		"shape":&"corridor",
		"delivery":&"beam",
		"from":Vector2(180.0, 360.0),
		"to":Vector2(900.0, 360.0),
		"half_width":58.0,
		"damage":28.0,
		"affinity":AttackContract.ARC,
		"active_width":54.0,
		"readiness":0.72,
		"beam_growth_seconds":AttackContract.EMITTED_BEAM_GROWTH_SECONDS,
		"beam_emission_mode":AttackContract.EMITTED_BEAM_BIDIRECTIONAL,
		"active_seconds":0.60,
	}]
	offscreen_enemy.phase = &"startup"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 0
			and area_disk.multimesh.visible_instance_count == 4,
		"bidirectional beam startup draws one charge orb at each boss-side muzzle"
	)
	offscreen_enemy.phase = &"active"
	offscreen_enemy.phase_time = 0.45
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 6
			and area_disk.multimesh.visible_instance_count == 12,
		"bidirectional beam grows two rounded branches from the boss without a path warning"
	)
	renderer.sync([], no_projectiles, no_projectiles, [], [], Rect2(0,0,1280,720), Vector2.ZERO, 0.0, false)
	snapshot = renderer.debug_snapshot()
	_expect(
		int(snapshot["visible_instances"]) == 0,
		"inactive presentation hides all retained instances"
	)
	_expect(
		int(snapshot["health_bar_count"]) == 0
			and int(snapshot["priority_marker_count"]) == 0,
		"inactive presentation clears semantic overlay diagnostics"
	)
	renderer.queue_free()
	await process_frame
	_finish()


func _validate_primitive_batches(renderer: Renderer) -> void:
	for node_name in [
		"Overlay_health",
		"Overlay_ring",
		"Overlay_danger_ring",
		"Overlay_beam",
		"Overlay_disk",
		"Overlay_diamond",
		"FacilityEffect_ring",
	]:
		var batch := renderer.get_node(node_name) as MultiMeshInstance2D
		_expect(
			batch != null
				and batch.texture == null
				and batch.multimesh.mesh != null,
			"%s uses retained code-native geometry without a texture" % node_name
		)


func _validate_health_bar_geometry(renderer: Renderer) -> void:
	var health_batch := renderer.get_node("Overlay_health") as MultiMeshInstance2D
	var mesh_bounds := health_batch.multimesh.mesh.get_aabb()
	_expect(
		is_equal_approx(mesh_bounds.position.x, -1.0)
			and is_equal_approx(mesh_bounds.position.y, -0.5)
			and is_equal_approx(mesh_bounds.size.x, 2.0)
			and is_equal_approx(mesh_bounds.size.y, 1.0),
		"health bars use normalized full-height geometry"
	)
	var expected_left := NAN
	for ratio in [0.0, 0.25, 0.5, 0.75, 1.0]:
		renderer.call("_reset_counts")
		renderer.call(
			"_sync_health_bar",
			Vector2(20.0, 10.0),
			50.0,
			ratio * 100.0,
			100.0,
			1.8,
			42.0,
			72.0,
			16.0,
			16.0,
			Art.CORAL,
			Rect2(0.0, 0.0, 200.0, 120.0)
		)
		renderer.call("_apply_visible_counts")
		var buffer := health_batch.multimesh.buffer
		var fill_offset := Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
		var fill_left := (
			buffer[fill_offset + 3] - absf(buffer[fill_offset])
		)
		if is_nan(expected_left):
			expected_left = fill_left
		_expect(
			is_equal_approx(fill_left, expected_left),
			"health fill keeps its left edge fixed at ratio %.2f" % ratio
		)
		_expect(
			is_equal_approx(absf(buffer[5]) * mesh_bounds.size.y, 20.0)
				and is_equal_approx(
					absf(buffer[fill_offset + 5]) * mesh_bounds.size.y,
					16.0
				)
				and buffer[3] >= 74.0
				and buffer[7] > 10.0,
			"installation bar preserves 16-unit fill, 2-unit backing, and safe below placement"
		)
	renderer.call("_reset_counts")
	renderer.call(
		"_sync_health_bar",
		Vector2(1260.0, 710.0),
		112.0,
		50.0,
		100.0,
		1.9,
		96.0,
		120.0,
		18.0,
		18.0,
		Art.BOSS_COMMAND,
		Rect2(0.0, 0.0, 1280.0, 720.0)
	)
	renderer.call("_apply_visible_counts")
	var edge_buffer := health_batch.multimesh.buffer
	_expect(
		is_equal_approx(absf(edge_buffer[0]), 122.0)
			and edge_buffer[3] <= 1158.0
			and edge_buffer[7] <= 709.0,
		"boss bar clamps its 120-unit half-width and complete backing inside the viewport"
	)


func _validate_enemy_presentation(renderer: Renderer) -> void:
	var no_projectiles: Array[ProjectileState] = []
	var no_shards: Array[ExperienceShard] = []
	var moving := EnemyState.new()
	moving.id = "interpolation_probe"
	moving.role = &"ordinary_edge_01"
	moving.archetype = &"ordinary_pursuer_t1"
	moving.pos = Vector2(100.0, 240.0)
	moving.visual_radius = 26.0
	moving.speed = 190.0
	moving.spatial_slot = 0
	moving.runtime_generation = 1
	moving.alive = true
	moving.active = true
	moving.shielded = true
	var moving_enemies: Array[EnemyState] = [moving]
	renderer.sync(
		moving_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 0.0, true, "", {},
		1.0 / 60.0
	)
	moving.pos = Vector2(100.0 + 190.0 / 30.0, 240.0)
	renderer.sync(
		moving_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 0.0, true, "", {},
		1.0 / 60.0
	)
	var enemy_batch := renderer.get_node("Enemy_ordinary_pursuer_t1") as MultiMeshInstance2D
	var body_position := Vector2(
		enemy_batch.multimesh.buffer[3], enemy_batch.multimesh.buffer[7]
	)
	var shield_batch := renderer.get_node("Overlay_ring") as MultiMeshInstance2D
	var shield_position := Vector2(
		shield_batch.multimesh.buffer[3], shield_batch.multimesh.buffer[7]
	)
	_expect(
		body_position.x > 100.0
			and body_position.x < moving.pos.x
			and shield_position.is_equal_approx(body_position)
			and moving.pos.is_equal_approx(Vector2(106.333333, 240.0)),
		"30 Hz simulation samples interpolate without mutating gameplay position and attached shields follow"
	)
	renderer.sync(
		moving_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 0.0, true, "", {},
		1.0 / 60.0
	)
	body_position = Vector2(
		enemy_batch.multimesh.buffer[3], enemy_batch.multimesh.buffer[7]
	)
	_expect(
		body_position.is_equal_approx(moving.pos),
		"presentation reaches a 30 Hz target after two 60 Hz frames"
	)
	moving.pos = Vector2(500.0, 240.0)
	renderer.sync(
		moving_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 0.0, true, "", {},
		1.0 / 60.0
	)
	_expect(
		Vector2(enemy_batch.multimesh.buffer[3], enemy_batch.multimesh.buffer[7])
			.is_equal_approx(moving.pos),
		"large discontinuities snap instead of crossing the field"
	)
	moving.runtime_generation = 2
	moving.pos = Vector2(220.0, 240.0)
	renderer.sync(
		moving_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 0.0, true, "", {},
		1.0 / 60.0
	)
	_expect(
		Vector2(enemy_batch.multimesh.buffer[3], enemy_batch.multimesh.buffer[7])
			.is_equal_approx(moving.pos),
		"pooled generation reuse resets presentation history"
	)
	var repairer := EnemyState.new()
	repairer.id = "repairer"
	repairer.role = &"ordinary_support_01"
	repairer.archetype = &"ordinary_coordinator_t1"
	repairer.pos = Vector2(300.0, 300.0)
	repairer.visual_radius = 32.0
	repairer.spatial_slot = 1
	repairer.runtime_generation = 1
	repairer.alive = true
	repairer.active = true
	repairer.repair_target_id = "recipient"
	var recipient := EnemyState.new()
	recipient.id = "recipient"
	recipient.role = &"ordinary_edge_01"
	recipient.archetype = &"ordinary_pursuer_t1"
	recipient.pos = Vector2(500.0, 300.0)
	recipient.visual_radius = 26.0
	recipient.spatial_slot = 2
	recipient.runtime_generation = 1
	recipient.alive = true
	recipient.active = true
	var support_pair: Array[EnemyState] = [repairer, recipient]
	renderer.sync(
		support_pair, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 1.0, true, "", {},
		1.0 / 60.0
	)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	_expect(
		beam_batch.multimesh.visible_instance_count
			== Renderer.REPAIR_LINK_SEGMENTS + 2
			and int(renderer.debug_snapshot()["repair_link_count"]) == 1,
		"Support Ordinary Enemy Lv.1 uses five directional packets plus one open recipient chevron"
	)
	recipient.active = false
	renderer.sync(
		support_pair, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(640.0, 360.0), 1.0, true, "", {},
		1.0 / 60.0
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 0
			and int(renderer.debug_snapshot()["repair_link_count"]) == 0,
		"repair presentation retires when its recipient is inactive"
	)


func _validate_emp_presentation(renderer: Renderer) -> void:
	var no_enemies: Array[EnemyState] = []
	var no_projectiles: Array[ProjectileState] = []
	var no_shards: Array[ExperienceShard] = []
	var player_position := Vector2(260.0, 300.0)
	var release_position := Vector2(360.0, 320.0)
	var release_radius := 285.0
	var clear_radius := 325.0
	var release_store := EffectStore.new()
	var release = release_store.add_emp_footprint(
		EffectStore.EMP_RELEASE_KIND,
		release_position,
		Color.WHITE,
		0.55,
		release_radius,
		clear_radius
	)
	var presentation := _player_presentation(player_position, false)
	presentation["reduced_motion"] = false
	release.time = 0.55
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		release_store.live,
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	var release_draws := renderer.debug_semantic_texture_draws(&"effect/emp_release")
	var release_disks := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var utility_segments := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	var emp_rings := renderer.get_node("Overlay_ring") as MultiMeshInstance2D
	var release_disk_buffer := release_disks.multimesh.buffer
	_expect(
		release_draws.is_empty(),
		"standard-motion EMP requests no authored effect raster"
	)
	_expect(
		release_disks.multimesh.visible_instance_count == 1
		and Vector2(release_disk_buffer[3], release_disk_buffer[7])
			.is_equal_approx(release_position)
		and is_equal_approx(
			Vector2(release_disk_buffer[0], release_disk_buffer[4]).length(),
			release_radius
		)
		and is_equal_approx(release_disk_buffer[11], 0.20)
		and emp_rings.multimesh.visible_instance_count == 0
		and _emp_fringe_matches(
			utility_segments, release_position, release_radius, clear_radius, 0.34
		),
		"EMP release starts with one complete 285 damage disk and a segmented 285-325 utility fringe"
	)
	release.time = 0.35
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		release_store.live,
		Rect2(0, 0, 1280, 720),
		player_position,
		0.20,
		true,
		"",
		presentation
	)
	release_draws = renderer.debug_semantic_texture_draws(&"effect/emp_release")
	release_disk_buffer = release_disks.multimesh.buffer
	_expect(
		release_draws.is_empty()
			and is_equal_approx(
				Vector2(release_disk_buffer[0], release_disk_buffer[4]).length(),
				release_radius
			)
			and release_disk_buffer[11] < 0.20
			and utility_segments.multimesh.buffer[11] < 0.34,
		"standard-motion EMP keeps its fixed footprint and fades both semantic regions"
	)
	presentation["reduced_motion"] = true
	release.time = 0.55
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		release_store.live,
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	release_draws = renderer.debug_semantic_texture_draws(&"effect/emp_release")
	release_disk_buffer = release_disks.multimesh.buffer
	_expect(
		release_draws.is_empty()
			and is_equal_approx(
				Vector2(release_disk_buffer[0], release_disk_buffer[4]).length(),
				release_radius
			)
			and _emp_fringe_matches(
				utility_segments, release_position, release_radius, clear_radius, 0.34
			),
		"reduced-motion EMP starts with the same damage disk and utility fringe"
	)
	var charge_store := EffectStore.new()
	var charge = charge_store.add_emp_footprint(
		EffectStore.EMP_CHARGE_KIND,
		Vector2(-1200.0, -900.0),
		Art.SYSTEM,
		0.42,
		release_radius,
		clear_radius
	)
	charge.time = 0.42
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		charge_store.live,
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	var charge_disks := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var charge_disk_buffer := charge_disks.multimesh.buffer
	_expect(
		charge_disks.multimesh.visible_instance_count == 1
		and emp_rings.multimesh.visible_instance_count == 0
		and Vector2(charge_disk_buffer[3], charge_disk_buffer[7])
			.is_equal_approx(player_position)
		and is_equal_approx(
			Vector2(charge_disk_buffer[0], charge_disk_buffer[4]).length(),
			release_radius
		)
		and is_equal_approx(charge_disk_buffer[11], 0.12)
		and _emp_fringe_matches(
			utility_segments, player_position, release_radius, clear_radius, 0.24
		),
		"EMP charge culls and draws from the live player center despite its stale stored center"
	)
	var moved_player_position := player_position + Vector2(37.0, -19.0)
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, charge_store.live,
		Rect2(0, 0, 1280, 720), moved_player_position, 0.0, true, "", presentation
	)
	charge_disk_buffer = charge_disks.multimesh.buffer
	_expect(
		Vector2(charge_disk_buffer[3], charge_disk_buffer[7])
			.is_equal_approx(moved_player_position)
		and _emp_fringe_matches(
			utility_segments, moved_player_position, release_radius, clear_radius, 0.24
		),
		"the EMP charge disk and utility fringe follow the current player center"
	)
	var emp_source := FileAccess.get_file_as_string(
		"res://data/weapons/vehicle/active/emp.tres"
	)
	_expect(
		 emp_source.contains("startup_seconds = 0.42")
			and emp_source.contains(
				"size_by_level = Array[float]([285.0, 315.0, 345.0, 375.0, 405.0, 435.0, 465.0])"
			)
			and emp_source.contains(
				"auxiliary_size_by_level = Array[float]([325.0, 355.0, 385.0, 415.0, 445.0, 475.0, 505.0])"
			),
		"EMP definition publishes its exact stun and projectile-clear footprints"
	)


func _validate_active_weapon_presentation(renderer: Renderer) -> void:
	var no_enemies: Array[EnemyState] = []
	var no_projectiles: Array[ProjectileState] = []
	var no_shards: Array[ExperienceShard] = []
	var center := Vector2(640.0, 360.0)
	var presentation := _player_presentation(center, false)
	var visible_world := Rect2(0.0, 0.0, 1280.0, 720.0)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	var disk_batch := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var ring_batch := renderer.get_node("Overlay_ring") as MultiMeshInstance2D
	presentation["active_weapon"] = {
		"weapon_id":&"cross_beam", "center":center,
		"direction":Vector2.RIGHT, "size":48.0,
		"startup_remaining":0.30, "active_remaining":0.0,
		"release_remaining":0.0,
	}
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		visible_world, center, 0.0, true, "", presentation
	)
	var beam_buffer := beam_batch.multimesh.buffer
	var cross_widths_match := beam_batch.multimesh.visible_instance_count == 2
	for index in beam_batch.multimesh.visible_instance_count:
		var offset := index * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
		cross_widths_match = cross_widths_match and is_equal_approx(
			Vector2(beam_buffer[offset + 1], beam_buffer[offset + 5]).length(),
			48.0
		)
	_expect(
		cross_widths_match,
		"Cross Beam startup renders both exact half-width-48 corridors"
	)
	presentation["active_weapon"] = {
		"weapon_id":&"black_hole", "center":center,
		"direction":Vector2.RIGHT, "size":225.0,
		"startup_remaining":0.0, "active_remaining":1.0,
		"release_remaining":0.0,
	}
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		visible_world, center, 0.0, true, "", presentation
	)
	var disk_buffer := disk_batch.multimesh.buffer
	var ring_buffer := ring_batch.multimesh.buffer
	var second_ring_offset := Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
	_expect(
		disk_batch.multimesh.visible_instance_count == 1
			and ring_batch.multimesh.visible_instance_count == 2
			and is_equal_approx(Vector2(disk_buffer[0], disk_buffer[4]).length(), 225.0)
			and is_equal_approx(Vector2(ring_buffer[0], ring_buffer[4]).length(), 225.0)
			and is_equal_approx(
				Vector2(
					ring_buffer[second_ring_offset],
					ring_buffer[second_ring_offset + 4]
				).length(),
				94.5
			),
		"Black Hole active phase renders its exact full disk and bounded core"
	)
	presentation["active_weapon"] = {
		"weapon_id":&"shockwave", "center":center,
		"direction":Vector2.RIGHT, "size":270.0,
		"startup_remaining":0.0, "active_remaining":0.0,
		"release_remaining":0.18,
	}
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		visible_world, center, 0.0, true, "", presentation
	)
	disk_buffer = disk_batch.multimesh.buffer
	ring_buffer = ring_batch.multimesh.buffer
	_expect(
		disk_batch.multimesh.visible_instance_count == 1
			and ring_batch.multimesh.visible_instance_count == 1
			and is_equal_approx(Vector2(disk_buffer[0], disk_buffer[4]).length(), 270.0)
			and is_equal_approx(Vector2(ring_buffer[0], ring_buffer[4]).length(), 270.0),
		"Shockwave release renders one complete radius-270 footprint"
	)


func _emp_fringe_matches(
	batch: MultiMeshInstance2D,
	center: Vector2,
	inner_radius: float,
	outer_radius: float,
	expected_alpha: float
) -> bool:
	if batch.multimesh.visible_instance_count != 12:
		return false
	var buffer := batch.multimesh.buffer
	var band_radius := (inner_radius + outer_radius) * 0.5
	for index in 12:
		var offset := index * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
		var origin := Vector2(buffer[offset + 3], buffer[offset + 7])
		if not is_equal_approx(origin.distance_to(center), band_radius):
			return false
		if not is_equal_approx(buffer[offset + 11], expected_alpha):
			return false
		var segment_color := Color(
			buffer[offset + 8], buffer[offset + 9], buffer[offset + 10], 1.0
		)
		if not segment_color.is_equal_approx(Color(Art.SYSTEM, 1.0)):
			return false
	return true


func _validate_mystery_device_presentation(
	renderer: Renderer,
	no_enemies: Array[EnemyState],
	no_projectiles: Array[ProjectileState],
	no_shards: Array[ExperienceShard]
) -> void:
	var device_position := Vector2(420.0, 260.0)
	var resolved_position := Vector2(620.0, 260.0)
	var weakpoint_position := Vector2(820.0, 260.0)
	var presentation := _player_presentation(Vector2(260.0, 300.0), false)
	presentation["reduced_motion"] = true
	presentation["mystery_devices"] = [
		{
			"id":"device-a",
			"state":&"dormant",
			"position":device_position,
			"outcome":&"lava",
			"effect_radius":360.0,
		},
		{"id":"device-b", "state":&"active", "visible":true, "position":resolved_position, "outcome":&"cryo", "effect_radius":360.0, "active_ratio":0.5},
		{"id":"device-c", "state":&"active", "visible":true, "position":weakpoint_position, "outcome":&"weakpoint", "effect_radius":420.0, "active_ratio":0.25},
		{"id":"device-d", "state":&"expired", "visible":true, "position":Vector2(960.0, 260.0)},
	]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)


	var lava_contour := renderer.get_node(
		"MysteryDeviceContour_lava"
	) as MultiMeshInstance2D
	var cryo_contour := renderer.get_node(
		"MysteryDeviceContour_cryo"
	) as MultiMeshInstance2D
	var weakpoint_contour := renderer.get_node(
		"MysteryDeviceContour_weakpoint"
	) as MultiMeshInstance2D
	var repair_contour := renderer.get_node(
		"MysteryDeviceContour_repair"
	) as MultiMeshInstance2D
	var rings := renderer.get_node("FacilityEffect_ring") as MultiMeshInstance2D
	var disks := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var lava_symbols := renderer.debug_semantic_texture_draws(&"world/mystery_device_lava")
	var cryo_symbols := renderer.debug_semantic_texture_draws(&"world/mystery_device_cryo")
	var weakpoint_symbols := renderer.debug_semantic_texture_draws(&"world/mystery_device_weakpoint")
	_expect(
		lava_contour.multimesh.instance_count == Renderer.MYSTERY_DEVICE_CAPACITY
			and cryo_contour.multimesh.instance_count == Renderer.MYSTERY_DEVICE_CAPACITY
			and weakpoint_contour.multimesh.instance_count == Renderer.MYSTERY_DEVICE_CAPACITY
			and lava_contour.multimesh.visible_instance_count == 1
			and cryo_contour.multimesh.visible_instance_count == 1
			and weakpoint_contour.multimesh.visible_instance_count == 1,
		"each visible Anomaly outcome uses one bounded breathing contour"
	)
	_expect(
		lava_symbols.size() == 1
			and cryo_symbols.size() == 1
			and weakpoint_symbols.size() == 1
			and Vector2(lava_symbols[0]["position"]).is_equal_approx(device_position)
			and Vector2(cryo_symbols[0]["position"]).is_equal_approx(resolved_position)
			and Vector2(weakpoint_symbols[0]["position"]).is_equal_approx(weakpoint_position),
		"assigned outcome symbols are visible before damage and remain visible after resolution"
	)
	_expect(
		is_equal_approx(lava_contour.multimesh.buffer[12], 1.0)
		and is_equal_approx(lava_contour.multimesh.buffer[13], 0.0)
		and is_equal_approx(cryo_contour.multimesh.buffer[12], 0.5)
		and is_equal_approx(cryo_contour.multimesh.buffer[13], 1.0)
		and is_equal_approx(
			lava_contour.multimesh.buffer[15],
			Renderer.INTERACTION_EDGE_ALPHA_REDUCED
		)
		and is_equal_approx(
			Vector2(
				lava_contour.multimesh.buffer[0],
				lava_contour.multimesh.buffer[4]
			).length(),
			Renderer.MYSTERY_DEVICE_SYMBOL_RADIUS
				+ Renderer.INTERACTION_CONTOUR_WORLD_UNITS
		),
		"dormant facilities show a full contour and active facilities clip it to remaining time"
	)
	_expect(
		rings.z_index == -1
			and rings.multimesh.visible_instance_count == 2
			and disks.multimesh.visible_instance_count == 2,
		"only active cryo and weakpoint facilities publish full-area footprints"
	)
	var health_snapshot := renderer.debug_snapshot()
	_expect(
		int(health_snapshot["mystery_health_bar_count"]) == 0
			and int(health_snapshot["health_bar_count"]) == 0,
		"Anomaly Devices omit combat health bars"
	)
	var expected_radii := [360.0, 420.0]
	var expected_alphas := [0.12, 0.10]
	for index in expected_radii.size():
		var offset := index * Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE
		_expect(
			is_equal_approx(
				Vector2(
					rings.multimesh.buffer[offset],
					rings.multimesh.buffer[offset + 4]
				).length(),
				expected_radii[index]
			)
			and is_equal_approx(
				Vector2(
					disks.multimesh.buffer[offset],
					disks.multimesh.buffer[offset + 4]
				).length(),
				expected_radii[index]
			)
			and is_equal_approx(disks.multimesh.buffer[offset + 11], expected_alphas[index]),
			"mystery effect %d preserves its exact full-area radius and locked alpha"
			% (index + 1)
		)
	presentation["mystery_devices"] = [
		{"id":"device-repair", "state":&"active", "visible":true, "position":device_position, "outcome":&"repair", "effect_radius":420.0, "active_ratio":1.0},
		{"id":"device-lava", "state":&"active", "visible":true, "position":resolved_position, "outcome":&"lava", "effect_radius":360.0, "active_ratio":0.5},
	]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	var repair_symbols := renderer.debug_semantic_texture_draws(&"world/facility_repair_beacon")
	var active_lava_symbols := renderer.debug_semantic_texture_draws(&"world/mystery_device_lava")
	_expect(
		repair_contour.multimesh.visible_instance_count == 1
			and lava_contour.multimesh.visible_instance_count == 1
			and repair_symbols.size() == 1
			and active_lava_symbols.size() == 1
			and Vector2(repair_symbols[0]["position"]).is_equal_approx(device_position)
			and Vector2(active_lava_symbols[0]["position"]).is_equal_approx(resolved_position)
			and rings.multimesh.visible_instance_count == 2
			and disks.multimesh.visible_instance_count == 2,
		"repair and Lava facilities use bounded semantic bodies, contours, and full-area footprints"
	)
	presentation["mystery_devices"] = [
		{"id":"device-a", "state":&"dormant", "visible":true, "position":device_position, "outcome":&"lava", "effect_radius":360.0},
		{"id":"device-b", "state":&"dormant", "visible":true, "position":resolved_position, "outcome":&"cryo", "effect_radius":360.0},
		{"id":"device-c", "state":&"dormant", "visible":true, "position":weakpoint_position, "outcome":&"weakpoint", "effect_radius":420.0},
	]
	var pickup_position := Vector2(340.0, 420.0)
	presentation["map_pickups"] = [
		{"id":"recall-a", "kind":&"experience_recall", "pos":pickup_position, "active":true},
		{"id":"xp-ignored", "kind":&"experience_small", "pos":Vector2(500.0, 420.0), "active":true},
	]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	var recall := renderer.get_node("MapPickup_experience_recall") as MultiMeshInstance2D
	var recall_contour := renderer.get_node(
		"MapPickupContour_experience_recall"
	) as MultiMeshInstance2D
	_expect(
		recall.multimesh.visible_instance_count == 1
			and recall_contour.multimesh.visible_instance_count == 1
			and Vector2(
				recall.multimesh.buffer[3], recall.multimesh.buffer[7]
			).is_equal_approx(pickup_position)
			and is_equal_approx(
				recall_contour.multimesh.buffer[15],
				Renderer.INTERACTION_EDGE_ALPHA_REDUCED
			),
		"only bounded map pickups receive the static reduced-motion contour"
	)
	var first := renderer.debug_snapshot()
	for _sync_index in 16:
		renderer.sync(
			no_enemies, no_projectiles, no_projectiles, no_shards, [],
			Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
		)
	var repeated := renderer.debug_snapshot()
	_expect(
		first["batch_counts"] == repeated["batch_counts"],
		"repeated mystery-device syncs keep retained batch counts stable"
	)
	presentation["reduced_motion"] = false
	presentation["run_time"] = 0.37
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	var pickup_phase := Renderer._stable_interaction_phase("recall-a")
	var device_phase := Renderer._stable_interaction_phase("device-c")
	var expected_pickup_position := pickup_position + Vector2.DOWN * (
		sin(float(presentation["run_time"]) * TAU / Renderer.MAP_PICKUP_BOB_PERIOD + pickup_phase)
		* Renderer.MAP_PICKUP_BOB_AMPLITUDE
	)
	var expected_device_position := weakpoint_position + Vector2.DOWN * (
		sin(float(presentation["run_time"]) * TAU / Renderer.MYSTERY_DEVICE_BOB_PERIOD + device_phase)
		* Renderer.MYSTERY_DEVICE_BOB_AMPLITUDE
	)
	_expect(
		Vector2(recall.multimesh.buffer[3], recall.multimesh.buffer[7])
			.is_equal_approx(expected_pickup_position)
			and Vector2(weakpoint_contour.multimesh.buffer[3], weakpoint_contour.multimesh.buffer[7])
			.is_equal_approx(expected_device_position)
			and is_equal_approx(
				recall_contour.multimesh.buffer[15],
				Renderer._interaction_edge_alpha(
					float(presentation["run_time"]), pickup_phase, false
				)
			)
			and is_equal_approx(
				weakpoint_contour.multimesh.buffer[15],
				Renderer._interaction_edge_alpha(
					float(presentation["run_time"]), device_phase, false
				)
			),
		"standard motion applies each pickup/device bob period and breathing-contour alpha"
	)
	presentation["reduced_motion"] = true
	presentation["mystery_devices"] = [
		{
			"id":"device-edge",
			"state":&"dormant",
			"visible":true,
			"position":Vector2(-120.0, 260.0),
			"outcome":&"lava",
			"effect_radius":360.0,
		},
	]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	var edge_symbols := renderer.debug_semantic_texture_draws(&"world/mystery_device_lava")
	_expect(
		edge_symbols.size() == 1
			and Vector2(edge_symbols[0]["position"]).is_equal_approx(Vector2(-120.0, 260.0)),
		"large outcome symbols stay rendered while their visible edge intersects the viewport"
	)
	presentation["mystery_devices"] = []
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	_expect(
		lava_contour.multimesh.visible_instance_count == 0
			and cryo_contour.multimesh.visible_instance_count == 0
			and weakpoint_contour.multimesh.visible_instance_count == 0
			and rings.multimesh.visible_instance_count == 0
			and disks.multimesh.visible_instance_count == 0,
		"inactive mystery device and timed-effect inputs clear their retained instances"
	)
func _validate_enemy_upgrade_device_presentation(
	no_enemies: Array[EnemyState],
	no_projectiles: Array[ProjectileState],
	no_shards: Array[ExperienceShard],
	no_effects: Array[EffectState]
) -> void:
	var renderer := EnemyUpgradeRenderer.new()
	root.add_child(renderer)
	await process_frame
	var position := Vector2(520.0, 300.0)
	var presentation := _player_presentation(Vector2(260.0, 300.0), false)
	presentation["mystery_devices"] = [{
		"id":"upgrade-device-a",
		"state":&"dormant",
		"visible":true,
		"position":position,
		"visual_radius":100.8,
		"capture_ratio":0.0,
		"capture_count":0,
		"hit_flash_remaining":0.14,
	}]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, no_effects,
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 1.0, true, "",
		presentation
	)
	var draws := renderer.debug_semantic_texture_draws(
		&"world/enemy_upgrade_device"
	)
	_expect(
		draws.size() == 1
			and Vector2(draws[0]["position"]).is_equal_approx(position)
			and is_equal_approx(float(draws[0]["radius"]), 100.8),
		"enemy upgrade device uses the approved Triad Forge production PNG"
	)
	if not draws.is_empty():
		var hit_color := Color(draws[0]["modulate"])
		_expect(
			hit_color.get_luminance() >= Art.TEXT_PRIMARY.get_luminance() * 0.90,
			"device damage publishes a bright body-wide hit flash"
		)
	renderer.queue_free()


func _validate_conditional_attack_footprints(
	renderer: Renderer,
	no_enemies: Array[EnemyState],
	no_projectiles: Array[ProjectileState],
	no_shards: Array[ExperienceShard]
) -> void:
	var player_position := Vector2(640.0, 360.0)
	var presentation := _player_presentation(player_position, false)
	var trail := DashUpgradeRuntime.TrailState.new()
	trail.start = Vector2(300.0, 360.0)
	trail.end = Vector2(700.0, 360.0)
	trail.remaining = DashUpgradeRuntime.TRAIL_DURATION
	trail.level = 1
	presentation["dash_afterburn_trails"] = [trail]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "", presentation
	)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	var disk_batch := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var beam_buffer := beam_batch.multimesh.buffer
	var disk_buffer := disk_batch.multimesh.buffer
	_expect(
		beam_batch.multimesh.visible_instance_count == 1
			and disk_batch.multimesh.visible_instance_count == 2
			and is_equal_approx(
				Vector2(beam_buffer[0], beam_buffer[4]).length(), 200.0
			)
			and is_equal_approx(
				Vector2(beam_buffer[1], beam_buffer[5]).length(), 72.0
			)
			and Vector2(disk_buffer[3], disk_buffer[7]) == trail.start
			and Vector2(
				disk_buffer[Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 3],
				disk_buffer[Renderer.BASE_BUFFER_FLOATS_PER_INSTANCE + 7]
			) == trail.end,
		"dash afterburn renders the full actual path as one radius-72 capsule"
	)

	presentation["dash_afterburn_trails"] = []
	presentation["secondary"] = {
		"mines":[],
		"electric_field_radius":0.0,
		"auto_laser_active_remaining":0.14,
		"auto_laser_origin":Vector2(600.0, 360.0),
		"auto_laser_end":Vector2(200.0, 360.0),
		"storm_pending":false,
		"storm_impact_remaining":0.0,
	}
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "", presentation
	)
	beam_buffer = beam_batch.multimesh.buffer
	_expect(
		beam_batch.multimesh.visible_instance_count == 1
			and is_equal_approx(
				Vector2(beam_buffer[0], beam_buffer[4]).length(), 200.0
			)
			and is_equal_approx(
				Vector2(beam_buffer[1], beam_buffer[5]).length(), 18.0
			)
			and Vector2(beam_buffer[3], beam_buffer[7])
				== Vector2(400.0, 360.0),
		"auto laser renders its exact corridor without a startup ring"
	)

	var storm_position := Vector2(900.0, 360.0)
	presentation["secondary"]["auto_laser_active_remaining"] = 0.0
	presentation["secondary"]["storm_pending"] = true
	presentation["secondary"]["storm_position"] = storm_position
	presentation["secondary"]["storm_warning_remaining"] = 0.55
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "", presentation
	)
	disk_buffer = disk_batch.multimesh.buffer
	_expect(
		disk_batch.multimesh.visible_instance_count == 1
			and Vector2(disk_buffer[3], disk_buffer[7]) == storm_position
			and is_equal_approx(disk_buffer[0], 280.0)
			and is_equal_approx(disk_buffer[5], 280.0),
		"storm warning shows its full radius-280 footprint on the first frame"
	)

	presentation["secondary"]["storm_pending"] = false
	presentation["secondary"]["storm_warning_remaining"] = 0.0
	presentation["secondary"]["storm_impact_remaining"] = 0.18
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "", presentation
	)
	beam_buffer = beam_batch.multimesh.buffer
	_expect(
		disk_batch.multimesh.visible_instance_count == 1
			and beam_batch.multimesh.visible_instance_count == 1
			and is_equal_approx(
				Vector2(beam_buffer[0], beam_buffer[4]).length(), 280.0
			)
			and is_equal_approx(
				Vector2(beam_buffer[1], beam_buffer[5]).length(), 12.0
			),
		"storm impact uses one final disk and one wide accent"
	)


func _validate_player_directional_cues(
	renderer: Renderer,
	no_enemies: Array[EnemyState],
	no_projectiles: Array[ProjectileState],
	no_shards: Array[ExperienceShard]
) -> void:
	var player_position := Vector2(640.0, 360.0)
	var presentation := _player_presentation(player_position, false)
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		[],
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	var beam_batch := renderer.get_node("Overlay_beam") as MultiMeshInstance2D
	_expect(
		beam_batch.multimesh.visible_instance_count == 0,
		"idle and ordinary movement render no engine thrust cue"
	)
	presentation["dash_active"] = true
	renderer.sync(
		no_enemies,
		no_projectiles,
		no_projectiles,
		no_shards,
		[],
		Rect2(0, 0, 1280, 720),
		player_position,
		0.0,
		true,
		"",
		presentation
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 1,
		"dash renders exactly one rear engine thrust cue"
	)
	presentation["player_hit_remaining"] = 0.10
	presentation["run_time"] = 1.37
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "",
		presentation
	)
	var craft_batch := renderer.get_node("Player_craft_body") as MultiMeshInstance2D
	_expect(
		Vector2(
			craft_batch.multimesh.buffer[3],
			craft_batch.multimesh.buffer[7]
		).is_equal_approx(player_position),
		"craft-only hit recoil cannot displace the craft during dash"
	)
	presentation["player_hit_remaining"] = 0.0
	presentation["dash_active"] = false
	presentation["player_barrier_hit_remaining"] = 0.16
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "",
		presentation
	)
	var ring_batch := renderer.get_node("Overlay_ring") as MultiMeshInstance2D
	_expect(
		ring_batch.multimesh.visible_instance_count == 1,
		"absorbed barrier damage uses one direct player-state ring flash"
	)
	presentation["player_barrier_hit_remaining"] = 0.0
	presentation["secondary"]["electric_field_radius"] = 280.0
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "",
		presentation
	)
	var field_batch := renderer.get_node("ElectricField_area") as MultiMeshInstance2D
	var field_buffer := field_batch.multimesh.buffer
	var field_mesh_bounds := field_batch.multimesh.mesh.get_aabb()
	var field_arrays := field_batch.multimesh.mesh.surface_get_arrays(0)
	var field_vertices: PackedVector3Array = field_arrays[Mesh.ARRAY_VERTEX]
	var field_colors: PackedColorArray = field_arrays[Mesh.ARRAY_COLOR]
	var fill_reaches_boundary := false
	var field_geometry_inside_radius := true
	var field_alpha_contract := {0.18:false, 0.045:false}
	var has_perimeter_alpha := false
	for vertex_index in field_vertices.size():
		var vertex_radius := Vector2(
			field_vertices[vertex_index].x, field_vertices[vertex_index].y
		).length()
		field_geometry_inside_radius = (
			field_geometry_inside_radius and vertex_radius <= 1.0001
		)
		var alpha := field_colors[vertex_index].a
		for expected_alpha in field_alpha_contract:
			if absf(alpha - float(expected_alpha)) <= 0.005:
				field_alpha_contract[expected_alpha] = true
		if absf(alpha - 0.18) <= 0.005 and vertex_radius >= 0.999:
			fill_reaches_boundary = true
		if absf(alpha - 0.30) <= 0.005:
			has_perimeter_alpha = true
	_expect(
		field_batch.z_index == -1
			and field_batch.multimesh.visible_instance_count == 1
			and Vector2(field_buffer[3], field_buffer[7]).is_equal_approx(
				player_position
			)
			and is_equal_approx(float(field_buffer[0]), 280.0)
			and is_equal_approx(float(field_buffer[5]), 280.0)
			and is_equal_approx(field_mesh_bounds.position.x, -1.0)
			and is_equal_approx(field_mesh_bounds.position.y, -1.0)
			and is_equal_approx(field_mesh_bounds.size.x, 2.0)
			and is_equal_approx(field_mesh_bounds.size.y, 2.0)
			and fill_reaches_boundary
			and field_geometry_inside_radius
			and not has_perimeter_alpha
			and field_alpha_contract.values().all(func(value): return bool(value)),
		"one below-actor Electric Field instance fills its exact radius without a perimeter"
	)
	for expected_radius in [240.0, 280.0, 320.0]:
		presentation["secondary"]["electric_field_radius"] = expected_radius
		renderer.sync(
			no_enemies, no_projectiles, no_projectiles, no_shards, [],
			Rect2(0, 0, 1280, 720), player_position, 0.0, true, "", presentation
		)
		_expect(
			is_equal_approx(
				float(renderer.debug_snapshot()["electric_field_radius"]),
				expected_radius
			),
			"Electric Field renders level radius %.0f without presentation drift"
			% expected_radius
		)
	presentation["secondary"]["electric_field_radius"] = 0.0
	presentation["secondary"]["mines"] = [
		{"pos":player_position + Vector2.RIGHT * 120.0, "life":4.0},
	]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), player_position, 0.0, true, "",
		presentation
	)
	var mine_draws := renderer.debug_semantic_texture_draws(&"secondary/wake_mine")
	_expect(
		mine_draws.size() == 1
			and is_equal_approx(
				float(mine_draws[0]["radius"]),
				Art.PLAYER_DROP_MINE_HALF_SIZE
			),
		"drop mine uses the enlarged presentation-only half-size"
	)
	for asset_id in [&"secondary/orbit_blade"]:
		var draws := renderer.debug_semantic_texture_draws(asset_id)
		_expect(not draws.is_empty(), "%s owns a rendered directional fixture" % asset_id)
		for draw in draws:
			var radial := Vector2(draw["position"]) - player_position
			var texture_forward := Vector2.RIGHT.rotated(float(draw["angle"]))
			_expect(
				not radial.is_zero_approx()
					and radial.normalized().dot(texture_forward) >= 0.999,
				"%s faces radially outward" % asset_id
			)


func _player_presentation(
	player_position: Vector2,
	dash_active: bool
) -> Dictionary:
	return {
		"zones":[],
		"player_position":player_position,
		"hull_direction":Vector2.RIGHT,
		"aim_direction":Vector2.UP,
		"player_speed":280.0,
		"dash_active":dash_active,
		"dash_progress":0.5 if dash_active else 0.0,
		"dash_direction":Vector2.RIGHT,
		"player_hit":false,
		"player_hit_remaining":0.0,
		"player_barrier_hit_remaining":0.0,
		"protection_sources":{},
		"muzzle_flash":0.0,
		"barrier_strength":0.0,
		"reduced_motion":false,
		"run_time":1.0,
		"secondary_visual_tier":0,
		"orbiting_blade_level":1,
		"secondary":{
			"orbit_angle":0.37,
			"orbit_radius":112.0,
			"blade_radius":Art.PLAYER_ORBIT_BLADE_HALF_SIZE,
			"blade_count":2,
			"mines":[],
			"electric_field_radius":0.0,
		},
		"cursor_position":player_position + Vector2.UP * 230.0,
	}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_COMBAT_RENDERER_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
