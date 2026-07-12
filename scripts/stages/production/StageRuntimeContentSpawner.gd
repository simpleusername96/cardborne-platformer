class_name StageRuntimeContentSpawner
extends RefCounted

const GENERIC_REWARD_SCENE := preload("res://scenes/stages/components/StageRewardInteractable.tscn")
const CHEST_REWARD_SCENE := preload("res://scenes/stages/components/ChestInteractable.tscn")
const MATERIAL_REWARD_SCENE := preload("res://scenes/stages/components/MaterialNode.tscn")


static func spawn(
	plan: StagePlan,
	room_hosts: Dictionary,
	actors_root: Node2D,
	enemy_catalog: EnemyCatalog,
	enemy_scene_catalog: EnemySceneCatalog,
	hazard_catalog: HazardCatalog,
	world_bounds: Rect2,
	terminal_room_role: StringName = &"exit"
) -> StageRuntimeContentResult:
	var errors := PackedStringArray()
	if plan == null or actors_root == null:
		errors.append("Runtime content spawn needs a StagePlan and Actors root.")
		return StageRuntimeContentResult.new(false, [], [], [], [], null, null, errors)
	var spawned_nodes: Array[Node] = []
	var all_enemies: Array[EnemyBase] = []
	var required_enemies: Array[EnemyBase] = []
	var hazards: Array[Node2D] = []
	var rewards: Array[StageRewardInteractable] = []

	for placement in plan.get_encounters():
		var host := room_hosts.get(String(placement.room_id)) as RoomTemplateHost
		var anchor := host.get_anchor_by_id(&"Enemy", placement.anchor_id) if host != null else null
		var scene := enemy_scene_catalog.get_scene(placement.archetype_id, placement.variant_id)
		if host == null or anchor == null or scene == null:
			errors.append("Enemy placement '%s' cannot resolve its room, anchor, or scene." % placement.id)
			break
		var enemy := scene.instantiate() as EnemyBase
		if enemy == null:
			errors.append("Enemy placement '%s' scene has an invalid root." % placement.id)
			break
		enemy.name = String(placement.id).to_pascal_case()
		enemy.enemy_catalog = enemy_catalog
		enemy.archetype_id = placement.archetype_id
		enemy.variant_id = placement.variant_id
		enemy.stage_id = plan.profile_id
		enemy.auto_reset_on_defeat = false
		enemy.defeat_below_y = world_bounds.end.y + 320.0
		enemy.encounter_bounds = Rect2(
			host.global_position + host.template_data.bounds.position,
			host.template_data.bounds.size
		)
		enemy.position = actors_root.to_local(anchor.global_position)
		enemy.set_meta("planned_encounter_id", String(placement.id))
		var room := plan.get_room(placement.room_id)
		enemy.set_meta("required_route", room != null and room.required_route)
		actors_root.add_child(enemy)
		spawned_nodes.append(enemy)
		if enemy.resolved_spec == null:
			errors.append("Enemy placement '%s' did not resolve its exact variant." % placement.id)
			break
		all_enemies.append(enemy)
		if room != null and room.required_route:
			required_enemies.append(enemy)

	if errors.is_empty():
		for placement in plan.get_hazards():
			var host := room_hosts.get(String(placement.room_id)) as RoomTemplateHost
			var anchor := host.get_anchor_by_id(&"Hazard", placement.anchor_id) if host != null else null
			var definition := hazard_catalog.get_hazard(placement.hazard_id)
			var hazard := definition.scene.instantiate() as Node2D if definition != null else null
			if anchor == null or hazard == null:
				errors.append("Hazard placement '%s' cannot resolve its anchor or scene." % placement.id)
				break
			hazard.name = String(placement.id).to_pascal_case()
			hazard.position = actors_root.to_local(anchor.global_position)
			actors_root.add_child(hazard)
			spawned_nodes.append(hazard)
			hazards.append(hazard)

	if errors.is_empty():
		for placement in plan.get_rewards():
			var host := room_hosts.get(String(placement.room_id)) as RoomTemplateHost
			var planned_room := plan.get_room(placement.room_id)
			var anchor := host.get_anchor_by_id(&"Reward", placement.anchor_id) if host != null else null
			if anchor == null:
				errors.append("Reward placement '%s' cannot resolve its anchor." % placement.id)
				break
			var reward := instantiate_reward_source(placement.reward_role)
			if reward == null:
				errors.append("Reward placement '%s' has no valid source scene." % placement.id)
				break
			reward.name = String(placement.id).to_pascal_case()
			var transaction_id := StringName(
				"%d:%d:%s" % [plan.run_seed, plan.stage_index, placement.id]
			)
			var optional_route := (
				placement.reward_role in [&"optional_route", &"route_choice"]
				or (planned_room != null and not planned_room.required_route)
			)
			reward.configure_reward(
				placement.reward_role,
				placement.reward_table_id,
				transaction_id,
				null,
				null,
				{
					"request_id": transaction_id,
					"stage_index": plan.stage_index,
					"room_id": placement.room_id,
					"source_id": placement.id,
					"optional_route": optional_route,
				}
			)
			reward.position = actors_root.to_local(anchor.global_position)
			actors_root.add_child(reward)
			spawned_nodes.append(reward)
			rewards.append(reward)

	var checkpoint: StageCheckpoint
	if errors.is_empty():
		var terminal_host := _terminal_host(plan, room_hosts, terminal_room_role)
		var marker := terminal_host.get_anchor(&"Objective", &"Checkpoint") if terminal_host != null else null
		if marker == null:
			errors.append("Terminal room has no checkpoint marker.")
		else:
			checkpoint = StageCheckpoint.new()
			checkpoint.name = "ExitCheckpoint"
			checkpoint.checkpoint_id = "%s_terminal" % plan.profile_id
			checkpoint.position = actors_root.to_local(marker.global_position)
			actors_root.add_child(checkpoint)
			spawned_nodes.append(checkpoint)

	var fall_reset: FallResetZone
	if errors.is_empty():
		var definition := hazard_catalog.get_hazard(&"fall_reset")
		fall_reset = definition.scene.instantiate() as FallResetZone if definition != null else null
		if fall_reset == null:
			errors.append("Stage-wide fall reset scene is unavailable.")
		else:
			fall_reset.name = "StageFallReset"
			fall_reset.zone_size = Vector2(world_bounds.size.x + 480.0, 180.0)
			fall_reset.position = Vector2(world_bounds.get_center().x, world_bounds.end.y + 180.0)
			actors_root.add_child(fall_reset)
			spawned_nodes.append(fall_reset)

	if not errors.is_empty():
		_cleanup(spawned_nodes)
		return StageRuntimeContentResult.new(false, [], [], [], [], null, null, errors)
	return StageRuntimeContentResult.new(
		true,
		all_enemies,
		required_enemies,
		hazards,
		rewards,
		checkpoint,
		fall_reset,
		errors
	)


static func instantiate_reward_source(reward_role: StringName) -> StageRewardInteractable:
	var scene: PackedScene
	match reward_role:
		&"cache_reward", &"optional_route", &"route_choice":
			scene = CHEST_REWARD_SCENE
		&"material_node":
			scene = MATERIAL_REWARD_SCENE
		_:
			scene = GENERIC_REWARD_SCENE
	var source := scene.instantiate() as StageRewardInteractable
	if source != null:
		source.reward_role = reward_role
		source.set_meta("reward_role", reward_role)
	return source


static func _terminal_host(
	plan: StagePlan,
	room_hosts: Dictionary,
	terminal_room_role: StringName
) -> RoomTemplateHost:
	for room in plan.get_rooms():
		if room.role == terminal_room_role:
			return room_hosts.get(String(room.id)) as RoomTemplateHost
	return null


static func _cleanup(nodes: Array[Node]) -> void:
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.queue_free()
