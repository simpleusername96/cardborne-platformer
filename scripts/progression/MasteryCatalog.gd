class_name MasteryCatalog
extends Resource

const CHARACTER_IDS: Array[StringName] = [&"warrior", &"archer", &"assassin"]
const MATCHING_MATERIAL := {
	&"warrior": &"rusted_scrap",
	&"archer": &"sky_thread",
	&"assassin": &"slime_residue",
}
const DEPTH_ORDER := {&"root": 0, &"middle": 1, &"capstone": 2}
const EXPECTED_NODE_IDS: Array[StringName] = [
	&"warrior_broad_guard",
	&"warrior_driving_rush",
	&"warrior_fracture",
	&"warrior_aftershock",
	&"warrior_steady_feet",
	&"warrior_last_bastion",
	&"archer_quick_nock",
	&"archer_piercing_draw",
	&"archer_shared_mark",
	&"archer_airborne_hunter",
	&"archer_storm_pattern",
	&"archer_clean_release",
	&"assassin_serrated_second",
	&"assassin_slipstream",
	&"assassin_lingering_smoke",
	&"assassin_fan_return",
	&"assassin_opportunist",
	&"assassin_perfect_exit",
]

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var nodes: Array[MasteryNodeDefinition] = []


func get_node(node_id: StringName) -> MasteryNodeDefinition:
	for node in nodes:
		if node != null and node.id == node_id:
			return node
	return null


func has_node(node_id: StringName) -> bool:
	return get_node(node_id) != null


func get_for_character(character_id: StringName) -> Array[MasteryNodeDefinition]:
	var character_nodes: Array[MasteryNodeDefinition] = []
	if not CHARACTER_IDS.has(character_id):
		return character_nodes
	for node in nodes:
		if node != null and node.character_id == character_id:
			character_nodes.append(node)
	return character_nodes


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Mastery catalog ID", id)
	if display_name.strip_edges().is_empty() or content_version <= 0:
		errors.append("Mastery catalog needs a display name and positive version.")
	if nodes.size() != EXPECTED_NODE_IDS.size():
		errors.append("First-run mastery catalog needs exactly %d nodes." % EXPECTED_NODE_IDS.size())

	var seen: Dictionary = {}
	for node_index in nodes.size():
		var node := nodes[node_index]
		if node == null:
			errors.append("Mastery node at index %d is null." % node_index)
			continue
		if seen.has(node.id):
			errors.append("Mastery catalog repeats '%s'." % node.id)
		seen[node.id] = true
		for node_error in node.validate_definition():
			errors.append(node_error)
	for expected_id in EXPECTED_NODE_IDS:
		if not seen.has(expected_id):
			errors.append("Mastery catalog is missing required node '%s'." % expected_id)
	for actual_id in seen:
		if not EXPECTED_NODE_IDS.has(StringName(actual_id)):
			errors.append("Mastery catalog contains unexpected node '%s'." % actual_id)

	_validate_character_shapes(errors)
	_validate_prerequisites(errors)
	_validate_cycles(errors)
	return errors


func _validate_character_shapes(errors: PackedStringArray) -> void:
	for character_id in CHARACTER_IDS:
		var character_nodes := get_for_character(character_id)
		if character_nodes.size() != 6:
			errors.append("Character '%s' needs exactly six mastery nodes." % character_id)
		var depth_counts := {&"root": 0, &"middle": 0, &"capstone": 0}
		for node in character_nodes:
			if depth_counts.has(node.depth):
				depth_counts[node.depth] += 1
			_validate_cost(errors, node)
			match node.depth:
				&"root":
					if not node.requires_all.is_empty() or not node.requires_any.is_empty():
						errors.append("Root mastery '%s' cannot have prerequisites." % node.id)
				&"middle":
					var valid_gate := (
						node.requires_all.size() == 1 and node.requires_any.is_empty()
					) or (
						node.requires_all.is_empty() and node.requires_any.size() >= 2
					)
					if not valid_gate:
						errors.append("Middle mastery '%s' must require one node or one of multiple roots." % node.id)
				&"capstone":
					if node.requires_all.size() != 2 or not node.requires_any.is_empty():
						errors.append("Capstone mastery '%s' must require exactly two nodes." % node.id)
		if depth_counts[&"root"] != 2 or depth_counts[&"middle"] != 3 or depth_counts[&"capstone"] != 1:
			errors.append("Character '%s' mastery depths must be 2 root, 3 middle, and 1 capstone." % character_id)


func _validate_cost(errors: PackedStringArray, node: MasteryNodeDefinition) -> void:
	var material_id: StringName = MATCHING_MATERIAL.get(node.character_id, &"")
	var expected_amount := 0
	match node.depth:
		&"root":
			expected_amount = 4
		&"middle":
			expected_amount = 8
		&"capstone":
			expected_amount = 10
	var expected_key_count := 2 if node.depth == &"capstone" else 1
	if node.costs.size() != expected_key_count or int(node.costs.get(material_id, 0)) != expected_amount:
		errors.append("Mastery node '%s' has the wrong matching-material cost." % node.id)
	if node.depth == &"capstone":
		if int(node.costs.get(&"boss_core", 0)) != 1:
			errors.append("Capstone mastery '%s' needs one Boss Core." % node.id)
	elif node.costs.has(&"boss_core"):
		errors.append("Non-capstone mastery '%s' cannot cost a Boss Core." % node.id)


func _validate_prerequisites(errors: PackedStringArray) -> void:
	for node in nodes:
		if node == null:
			continue
		for prerequisite_id in node.get_prerequisite_ids():
			var prerequisite := get_node(prerequisite_id)
			if prerequisite == null:
				errors.append("Mastery node '%s' references missing prerequisite '%s'." % [node.id, prerequisite_id])
				continue
			if prerequisite.character_id != node.character_id:
				errors.append("Mastery node '%s' references another character's node '%s'." % [node.id, prerequisite_id])
			if int(DEPTH_ORDER.get(prerequisite.depth, 99)) >= int(DEPTH_ORDER.get(node.depth, -1)):
				errors.append("Mastery node '%s' prerequisite '%s' must be at a lower depth." % [node.id, prerequisite_id])


func _validate_cycles(errors: PackedStringArray) -> void:
	var states: Dictionary = {}
	for node in nodes:
		if node != null and int(states.get(node.id, 0)) == 0:
			_visit(node, states, errors)


func _visit(node: MasteryNodeDefinition, states: Dictionary, errors: PackedStringArray) -> void:
	states[node.id] = 1
	for prerequisite_id in node.get_prerequisite_ids():
		var prerequisite := get_node(prerequisite_id)
		if prerequisite == null:
			continue
		var state := int(states.get(prerequisite_id, 0))
		if state == 1:
			errors.append("Mastery prerequisite cycle includes '%s' and '%s'." % [node.id, prerequisite_id])
		elif state == 0:
			_visit(prerequisite, states, errors)
	states[node.id] = 2
