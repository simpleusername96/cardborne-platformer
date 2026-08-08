extends SceneTree

const Renderer = preload("res://scripts/presentation/vehicle_combat_renderer.gd")
const Art = preload("res://scripts/vehicle/vehicle_stage_visual_profile.gd")
const AttackContract = preload("res://scripts/combat/vehicle_attack_contract.gd")
const EnemyState = preload("res://scripts/enemies/vehicle_enemy_state.gd")
const ProjectileState = preload("res://scripts/combat/vehicle_projectile_state.gd")
const ExperienceShard = preload("res://scripts/progression/vehicle_experience_shard.gd")
const EffectStore = preload("res://scripts/combat/vehicle_effect_store.gd")
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
		int(snapshot["batches"]) <= 50,
		"combat presentation remains inside the retained fifty-batch ceiling (actual %d)"
		% int(snapshot["batches"])
	)
	_expect(
		int(snapshot["allocated_instances"]) < int(snapshot["maximum_instances"]),
		"component batches reserve bounded working buffers and retain their full growth ceiling"
	)
	_expect(Art.validate_contract().is_empty(), "combat visual profile satisfies the locked readability contract")
	_validate_area_cue_asset()
	_expect(
		AttackContract.LIGHT_PROJECTILE_RADIUS == 5.0
			and AttackContract.STANDARD_PROJECTILE_RADIUS == 6.0
			and AttackContract.HEAVY_PROJECTILE_RADIUS == 7.0,
		"hostile projectile collision radii remain 5/6/7 world units"
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
	for variant in [&"colossus", &"leviathan", &"titan", &"behemoth", &"crown"]:
		_expect(
			renderer.get_node_or_null("Boss_%s" % String(variant)) != null,
			"%s boss owns a semantic texture batch" % variant
		)
	_expect(
		renderer.get_node_or_null("Projectile_shared_energy_teardrop") == null
			and renderer.get_node_or_null("Projectile_enemy_arc") == null,
		"the shared and affinity-specific legacy projectile batches are retired"
	)
	for pair in [
		[&"shooter", &"artillery_spotter"],
		[&"shooter", &"beam_sentinel"],
		[&"controller", &"shield_escort"],
		[&"controller", &"repair_tender"],
		[&"turret", &"interceptor_tower"],
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
	enemy.role = &"chaser"
	enemy.archetype = &"chaser"
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
	enemy.statuses = {
		&"burn":{"stacks":3},
		&"poison":{"stacks":2},
		&"chill":{"stacks":1},
	}
	enemy.committed_dir = Vector2.RIGHT
	enemy.committed_target = Vector2(500.0, 300.0)
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
	var rendered_effect = effect_store.add(
		&"player_emp_release",
		Vector2(360.0, 320.0),
		Color.WHITE,
		1.0,
		20.0,
		Vector2.RIGHT,
		0.0,
		1.0
	)
	rendered_effect.time = 0.5
	var presentation := {
		"zones":[], "player_position":Vector2(260.0,300.0),
		"hull_direction":Vector2.RIGHT, "aim_direction":Vector2.DOWN,
		"player_hit":false, "muzzle_flash":0.0, "barrier_strength":10.0,
		"player_barrier_hit_remaining":0.0,
		"reduced_motion":true, "run_time":1.0, "electric_field_level":0,
		"orbiting_blade_level":0, "secondary":{},
		"cursor_position":Vector2(460.0,300.0),
	}
	renderer.sync(
		enemies, projectiles, hostile_projectiles, shards, effect_store.live,
		Rect2(0,0,1280,720),
		Vector2(260.0,300.0), 1.0, true, "renderer_enemy",
		presentation
	)
	snapshot = renderer.debug_snapshot()
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
		corridor_caps.multimesh.visible_instance_count == 0
			and corridor_boundaries.multimesh.visible_instance_count == 0,
		"ordinary startup corridors do not draw attack lines or routes"
	)
	var enemy_batch := renderer.get_node("Enemy_chaser") as MultiMeshInstance2D
	var enemy_buffer := enemy_batch.multimesh.buffer
	_expect(
		enemy_batch.material == null,
		"authored actor perimeters do not add a runtime outline shader"
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
	for status_id in [&"burn", &"poison", &"chill"]:
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
		arc_area_section.count("_write_danger_ring(") == 1
			and not arc_area_section.contains("_write_diamond("),
		"every damaging area uses one exact outer ring without affinity ornaments"
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
	_validate_player_directional_cues(
		renderer,
		no_enemies,
		no_projectiles,
		no_shards
	)
	var crowd: Array[EnemyState] = []
	for index in 110:
		var crowd_enemy := EnemyState.new()
		crowd_enemy.id = "crowd_%02d" % index
		crowd_enemy.role = &"chaser"
		crowd_enemy.archetype = &"chaser"
		crowd_enemy.pos = Vector2(
			120.0 + float(index % 10) * 92.0,
			80.0 + float(index / 10) * 52.0
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
		int(snapshot["health_bar_count"]) == 0
			and int(snapshot["ordinary_health_bar_count"]) == 0
			and int(snapshot["installation_health_bar_count"]) == 0,
		"mobile enemies never receive world health bars"
	)
	_expect(
		int(snapshot["batch_allocations"]["Overlay_health"])
			== Renderer.HEALTH_BAR_INSTANCE_CAPACITY,
		"the structural world-health batch preallocates its exact twenty-eight-instance ceiling"
	)
	_expect(
		int(snapshot["priority_marker_count"]) == 0,
		"ordinary priority-target markers are removed"
	)
	var crowd_body := renderer.get_node("Enemy_chaser") as MultiMeshInstance2D
	_expect(
		crowd_body.multimesh.visible_instance_count == 110
			and crowd_body.multimesh.instance_count >= 110,
		"adaptive component buffers grow without hiding ordinary enemy bodies"
	)
	var installations: Array[EnemyState] = []
	for index in 16:
		var installation := EnemyState.new()
		var role: StringName = Renderer.HEALTH_BAR_INSTALLATION_ROLES[
			index % Renderer.HEALTH_BAR_INSTALLATION_ROLES.size()
		]
		installation.id = "installation_%02d" % index
		installation.role = role
		installation.archetype = role
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
		int(snapshot["installation_health_bar_count"])
			== Renderer.MAX_INSTALLATION_HEALTH_BARS
			and int(snapshot["health_bar_count"])
				== Renderer.MAX_INSTALLATION_HEALTH_BARS,
		"fixed installations own the deterministic twelve-bar structural budget"
	)
	var projectile_attacker := EnemyState.new()
	projectile_attacker.id = "projectile_attacker"
	projectile_attacker.role = &"shooter"
	projectile_attacker.archetype = &"shooter"
	projectile_attacker.pos = Vector2(300.0, 360.0)
	projectile_attacker.visual_radius = 26.0
	projectile_attacker.alive = true
	projectile_attacker.active = true
	projectile_attacker.phase = &"startup"
	projectile_attacker.attack_telegraphs = [{
		"shape":&"corridor",
		"delivery":&"projectile",
		"from":Vector2(330.0, 360.0),
		"to":Vector2(510.0, 360.0),
		"half_width":28.0,
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
	projectile_attacker.attack_telegraphs[0]["from"] = Vector2(-90.0, 360.0)
	projectile_attacker.attack_telegraphs[0]["to"] = Vector2(90.0, 360.0)
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
	open_boss.role = &"stage_boss"
	open_boss.archetype = &"stage_boss"
	open_boss.boss_variant = &"colossus"
	open_boss.boss_shield_state = &"shield_up"
	open_boss.pos = Vector2(700.0, 360.0)
	open_boss.visual_radius = Art.STAGE_BOSS_RADIUS
	open_boss.health = 160.0
	open_boss.max_health = 320.0
	open_boss.alive = true
	open_boss.active = true
	renderer.sync(
		[open_boss], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true, "open_boss"
	)
	var diamond_batch := renderer.get_node("Overlay_diamond") as MultiMeshInstance2D
	_expect(
		diamond_batch.multimesh.visible_instance_count == 0,
		"boss shield state does not add a yellow target overlay"
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
	offscreen_enemy.role = &"controller"
	offscreen_enemy.archetype = &"controller"
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
		"Enemy_controller"
	) as MultiMeshInstance2D
	var area_disk := renderer.get_node("Overlay_disk") as MultiMeshInstance2D
	var area_ring := renderer.get_node("Overlay_danger_ring") as MultiMeshInstance2D
	_expect(
		offscreen_enemy_batch.multimesh.visible_instance_count == 0,
		"off-screen attacker body remains culled"
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 0
			and area_ring.multimesh.visible_instance_count == 0,
		"ordinary enemies do not draw circular ranged bombardment footprints"
	)
	var armed_mine := EnemyState.new()
	armed_mine.id = "armed_mine"
	armed_mine.role = &"mine"
	armed_mine.archetype = &"mine"
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
	offscreen_enemy.role = &"stage_boss"
	offscreen_enemy.phase = &"boss_startup"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var early_area_buffer := area_ring.multimesh.buffer
	var early_area_color := Color(
		early_area_buffer[8],
		early_area_buffer[9],
		early_area_buffer[10],
		early_area_buffer[11]
	)
	offscreen_enemy.attack_telegraphs[0]["readiness"] = 1.0
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	var late_area_buffer := area_ring.multimesh.buffer
	var late_area_color := Color(
		late_area_buffer[8],
		late_area_buffer[9],
		late_area_buffer[10],
		late_area_buffer[11]
	)
	_expect(
		Color(early_area_color, 1.0).is_equal_approx(Color(Art.THERMAL, 1.0))
			and Color(late_area_color, 1.0).is_equal_approx(Color(Art.THERMAL, 1.0))
			and late_area_color.a > early_area_color.a,
		"all boss bombardment rings share one orange hue and strengthen toward impact"
	)
	offscreen_enemy.phase = &"boss_active"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		area_disk.multimesh.visible_instance_count == 0
			and area_ring.multimesh.visible_instance_count == 1,
		"boss area outline stays visible for its complete damaging window"
	)
	offscreen_enemy.phase = &"active"
	offscreen_enemy.role = &"controller"
	offscreen_enemy.attack_telegraphs = [{
		"shape":&"corridor",
		"delivery":&"beam",
		"from":Vector2(-120.0, 360.0),
		"to":Vector2(900.0, 360.0),
		"half_width":58.0,
		"damage":28.0,
		"affinity":AttackContract.ARC,
		"active_width":54.0,
		"readiness":0.72,
	}]
	offscreen_enemy.phase = &"startup"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 2,
		"Beam Sentinel startup draws one exact-width charge plane and one hot core"
	)
	offscreen_enemy.phase = &"active"
	renderer.sync(
		[offscreen_enemy], no_projectiles, no_projectiles, [], [],
		Rect2(0,0,1280,720), Vector2.ZERO, 0.0, true
	)
	_expect(
		beam_batch.multimesh.visible_instance_count == 3,
		"active off-screen beam draws a three-plane hot damaging body"
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


func _validate_area_cue_asset() -> void:
	var texture := AssetProvider.texture(&"cue/ring")
	_expect(texture != null, "area telegraph ring texture resolves")
	if texture == null:
		return
	var image := texture.get_image()
	_expect(
		Vector2i(image.get_size()) == Vector2i(128, 128),
		"area telegraph ring keeps its 128x128 canvas"
	)
	var opaque_pixels := 0
	var dark_pixels := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.05:
				continue
			opaque_pixels += 1
			if pixel.r < 0.90 or pixel.g < 0.90 or pixel.b < 0.90:
				dark_pixels += 1
	_expect(opaque_pixels > 4000, "area telegraph ring retains a readable annulus")
	_expect(dark_pixels == 0, "area telegraph ring has no black RGB fringe")


func _validate_mystery_device_presentation(
	renderer: Renderer,
	no_enemies: Array[EnemyState],
	no_projectiles: Array[ProjectileState],
	no_shards: Array[ExperienceShard]
) -> void:
	var device_position := Vector2(420.0, 260.0)
	var resolved_position := Vector2(620.0, 260.0)
	var presentation := _player_presentation(Vector2(260.0, 300.0), false)
	presentation["mystery_devices"] = [
		{
			"state":&"intact",
			"visible":true,
			"position":device_position,
			"health":45.0,
			"max_health":90.0,
			"health_visible_timer":1.0,
		},
		{"state":&"resolved", "visible":true, "position":resolved_position},
		{"state":&"retired", "visible":true, "position":Vector2(760.0, 260.0)},
	]
	presentation["reinforcement_facility"] = {
		"visible":true,
		"position":Vector2(900.0, 360.0),
		"radius":112.0,
		"health":120.0,
		"max_health":240.0,
	}
	presentation["mystery_effects"] = [
		{"effect_id":&"gravity_pull", "position":device_position, "radius":144.0},
		{"effect_id":&"cryo_lock", "position":resolved_position, "radius":108.0},
		{"effect_id":&"decoy_signal", "position":Vector2(760.0, 260.0), "radius":72.0},
	]
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	var intact := renderer.get_node("MysteryDevice_intact") as MultiMeshInstance2D
	var resolved := renderer.get_node("MysteryDevice_resolved") as MultiMeshInstance2D
	var rings := renderer.get_node("MysteryEffect_ring") as MultiMeshInstance2D
	_expect(
		intact.multimesh.instance_count == Renderer.MYSTERY_DEVICE_CAPACITY
			and resolved.multimesh.instance_count == Renderer.MYSTERY_DEVICE_CAPACITY
			and intact.multimesh.visible_instance_count == 1
			and resolved.multimesh.visible_instance_count == 1,
		"intact and resolved mystery devices use capacity-three retained batches while retired devices stay omitted"
	)
	var intact_buffer := intact.multimesh.buffer
	var resolved_buffer := resolved.multimesh.buffer
	_expect(
		Vector2(intact_buffer[3], intact_buffer[7]).is_equal_approx(device_position)
			and Vector2(intact_buffer[0], intact_buffer[4]).length() == Renderer.MYSTERY_DEVICE_VISUAL_RADIUS
			and Vector2(resolved_buffer[3], resolved_buffer[7]).is_equal_approx(resolved_position)
			and Vector2(resolved_buffer[0], resolved_buffer[4]).length() == Renderer.MYSTERY_DEVICE_VISUAL_RADIUS,
		"mystery device batches preserve gameplay positions and the 96-unit visual scale"
	)
	_expect(
		rings.z_index == -1
			and rings.multimesh.visible_instance_count == 3,
		"gravity, cryo, and decoy each publish one restrained ground-level retained ring"
	)
	var health_snapshot := renderer.debug_snapshot()
	_expect(
		int(health_snapshot["mystery_health_bar_count"]) == 0
			and int(health_snapshot["facility_health_bar_count"]) == 1
			and int(health_snapshot["crate_health_bar_count"]) == 0
			and int(health_snapshot["health_bar_count"]) == 1,
		"devices and crates omit health bars while the active facility always owns one"
	)
	var health_buffer := (
		(renderer.get_node("Overlay_health") as MultiMeshInstance2D).multimesh.buffer
	)
	_expect(
		health_buffer[7] < 360.0
			and is_equal_approx(absf(health_buffer[5]), 20.0)
			and is_equal_approx(
				absf(health_buffer[Renderer.BUFFER_FLOATS_PER_INSTANCE + 5]),
				16.0
			),
		"the facility owns a visibly thick sixteen-unit bar with a four-unit frame"
	)
	var expected_radii := [144.0, 108.0, 72.0]
	for index in expected_radii.size():
		var offset := index * Renderer.BUFFER_FLOATS_PER_INSTANCE
		_expect(
			is_equal_approx(Vector2(rings.multimesh.buffer[offset], rings.multimesh.buffer[offset + 4]).length(), expected_radii[index]),
			"mystery effect ring %d preserves its exact gameplay radius" % (index + 1)
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
	presentation["mystery_devices"] = []
	presentation["mystery_effects"] = []
	presentation["reinforcement_facility"] = {}
	renderer.sync(
		no_enemies, no_projectiles, no_projectiles, no_shards, [],
		Rect2(0, 0, 1280, 720), Vector2(260.0, 300.0), 0.0, true, "", presentation
	)
	_expect(
		intact.multimesh.visible_instance_count == 0
			and resolved.multimesh.visible_instance_count == 0
			and rings.multimesh.visible_instance_count == 0,
		"inactive mystery device and timed-effect inputs clear their retained instances"
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
		"electric_field_level":0,
		"orbiting_blade_level":1,
		"secondary":{
			"orbit_angle":0.37,
			"mines":[],
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
