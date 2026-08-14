class_name VehicleCollectiveTacticCatalog
extends RefCounted

## Authored collective-tactic recipes and stage rollout beats. Damage, movement,
## visibility, and live membership remain runtime responsibilities.

const PHASE_DORMANT := &"dormant"
const PHASE_GATHER := &"gather"
const PHASE_LOCK := &"lock"
const PHASE_EXECUTE := &"execute"
const PHASE_BREAK := &"break"
const PHASE_COOLDOWN := &"cooldown"

const RECIPES := {
	&"spearhead": {
		"formation": &"spear",
		"mode": &"charge",
		"minimum_members": 4,
		"gather": 0.90,
		"lock": 1.15,
		"execute": 0.62,
		"break": 1.05,
		"cooldown": 5.0,
		"counterplay_key": "TACTIC_COUNTER_SPEARHEAD",
	},
	&"swarm_screen": {
		"formation": &"screen",
		"mode": &"screen",
		"minimum_members": 4,
		"gather": 0.85,
		"lock": 1.05,
		"execute": 0.80,
		"break": 0.95,
		"cooldown": 5.4,
		"counterplay_key": "TACTIC_COUNTER_SWARM_SCREEN",
	},
	&"shepherd_pack": {
		"formation": &"escort",
		"mode": &"escort",
		"minimum_members": 4,
		"gather": 1.00,
		"lock": 1.20,
		"execute": 0.90,
		"break": 1.00,
		"cooldown": 5.8,
		"counterplay_key": "TACTIC_COUNTER_SHEPHERD",
	},
	&"shielded_column": {
		"formation": &"column",
		"mode": &"shield",
		"minimum_members": 4,
		"gather": 1.00,
		"lock": 1.20,
		"execute": 0.90,
		"break": 1.10,
		"cooldown": 6.0,
		"counterplay_key": "TACTIC_COUNTER_SHIELDED_COLUMN",
	},
	&"fuse_pack": {
		"formation": &"fuse",
		"mode": &"fuse",
		"minimum_members": 4,
		"gather": 0.90,
		"lock": 1.25,
		"execute": 0.72,
		"break": 1.10,
		"cooldown": 6.2,
		"counterplay_key": "TACTIC_COUNTER_FUSE_PACK",
	},
	&"bulwark_fuse": {
		"formation": &"column",
		"mode": &"shield",
		"minimum_members": 4,
		"gather": 1.00,
		"lock": 1.25,
		"execute": 0.86,
		"break": 1.15,
		"cooldown": 6.4,
		"counterplay_key": "TACTIC_COUNTER_BULWARK_FUSE",
	},
	&"repair_network": {
		"formation": &"network",
		"mode": &"support",
		"minimum_members": 4,
		"gather": 1.10,
		"lock": 1.30,
		"execute": 1.00,
		"break": 1.20,
		"cooldown": 6.8,
		"counterplay_key": "TACTIC_COUNTER_REPAIR_NETWORK",
	},
	&"crossfire_convoy": {
		"formation": &"convoy",
		"mode": &"crossfire",
		"minimum_members": 4,
		"gather": 1.05,
		"lock": 1.30,
		"execute": 0.92,
		"break": 1.15,
		"cooldown": 6.6,
		"counterplay_key": "TACTIC_COUNTER_CROSSFIRE",
	},
	&"learned_remix": {
		"formation": &"spear",
		"mode": &"charge",
		"minimum_members": 4,
		"gather": 0.85,
		"lock": 1.10,
		"execute": 0.68,
		"break": 1.10,
		"cooldown": 6.0,
		"counterplay_key": "TACTIC_COUNTER_REMIX",
	},
}

const STAGE_ROLLOUT := [
	{"teach": &"spearhead", "combine": &"swarm_screen"},
	{"teach": &"spearhead", "combine": &"swarm_screen"},
	{"teach": &"shepherd_pack", "combine": &"shielded_column"},
	{"teach": &"shepherd_pack", "combine": &"shielded_column"},
	{"teach": &"fuse_pack", "combine": &"bulwark_fuse"},
	{"teach": &"fuse_pack", "combine": &"bulwark_fuse"},
	{"teach": &"repair_network", "combine": &"crossfire_convoy"},
	{"teach": &"repair_network", "combine": &"crossfire_convoy"},
	{"teach": &"learned_remix", "combine": &"learned_remix"},
	{"teach": &"learned_remix", "combine": &"learned_remix"},
]


static func recipe(tactic_id: StringName) -> Dictionary:
	return Dictionary(RECIPES.get(tactic_id, {})).duplicate(true)


static func assignment_for(
	stage_index: int,
	surge_index: int,
	surge_count: int,
	squad_count: int
) -> Dictionary:
	if squad_count <= 0 or surge_count <= 0:
		return {}
	if stage_index < 0 or stage_index >= STAGE_ROLLOUT.size():
		return {}
	var normalized_stage := stage_index
	var normalized_progress := float(surge_index) / float(maxi(1, surge_count - 1))
	var beat_kind := (
		&"teach"
		if normalized_progress < 0.34
		else (&"combine" if normalized_progress < 0.72 else &"power_test")
	)
	var rollout: Dictionary = STAGE_ROLLOUT[normalized_stage]
	var tactic_id := StringName(
		rollout["teach"] if beat_kind == &"teach" else rollout["combine"]
	)
	return {
		"id": tactic_id,
		"squad_index": posmod(surge_index + normalized_stage, squad_count),
		"beat_kind": beat_kind,
	}


static func validate_contract() -> PackedStringArray:
	var errors := PackedStringArray()
	for tactic_variant in RECIPES:
		var tactic_id := StringName(tactic_variant)
		var value: Dictionary = RECIPES[tactic_id]
		for key in [
			"formation",
			"mode",
			"minimum_members",
			"gather",
			"lock",
			"execute",
			"break",
			"cooldown",
			"counterplay_key",
		]:
			if not value.has(key):
				errors.append("%s missing %s" % [tactic_id, key])
		if int(value.get("minimum_members", 0)) < 4:
			errors.append("%s minimum membership is below four" % tactic_id)
	for stage in STAGE_ROLLOUT:
		for key in ["teach", "combine"]:
			if not RECIPES.has(StringName(stage[key])):
				errors.append("stage rollout references missing %s" % stage[key])
	return errors
