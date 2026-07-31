extends SceneTree

## Completeness gate for the image-backed visual replacement. It follows
## producer event -> catalog -> animation/frame and UI component -> state file,
## rather than treating source image counts as runtime acceptance.

const GAMEPLAY_MANIFEST_PATH := (
	"res://art/gameplay/semantic-v2/asset-manifest.json"
)
const UI_MANIFEST_PATH := (
	"res://art/ui/production/semantic-v2/ui-asset-manifest.json"
)
const EVENT_CATALOG_PATH := (
	"res://scripts/presentation/components/vehicle_visual_event_catalog.gd"
)

const EXPECTED_ANIMATIONS := [
	"muzzle_player_primary",
	"dash_start",
	"emp_release",
	"wake_mine_detonation",
	"boss_module_disabled",
	"hostile_summon_arrival",
	"bulkhead_destroy",
	"impact_damage",
	"reflect_deflection",
	"barrier_contact",
	"hull_hit",
	"seeker_impact",
	"escort_drone_impact",
	"orbit_blade_impact",
	"enemy_destroy_light",
	"enemy_destroy_heavy",
	"crate_destroy",
	"pickup_intake",
	"support_heal",
	"lifesteal_pulse",
	"transit_shift",
	"boss_reduced_hit",
]

const EXPECTED_EVENT_IDS := [
	"player_primary_muzzle",
	"player_dash_start",
	"player_dash_afterimage",
	"player_hull_hit",
	"player_barrier_hit",
	"player_emp_charge",
	"player_emp_release",
	"player_emp_aftershock",
	"secondary_seeker_impact",
	"secondary_escort_impact",
	"secondary_orbit_blade_impact",
	"secondary_wake_mine_detonation",
	"hostile_projectile_impact",
	"projectile_reflected",
	"hostile_arrival",
	"hostile_summon_arrival",
	"enemy_destroy_light",
	"enemy_destroy_heavy",
	"boss_core_reduced_hit",
	"boss_module_resolved",
	"pickup_experience",
	"pickup_repair",
	"pickup_reward",
	"support_heal",
	"lifesteal_transfer",
	"transit_complete",
	"bulkhead_destroy",
	"crate_destroy",
	"group_clear",
]

const EXPECTED_UI_COMPONENT_STATES := {
	"modal_master": ["normal", "compact_safe"],
	"content_plate": ["normal", "inset", "summary"],
	"hud_plate": [
		"health_resource",
		"objective_boss",
		"minimap_target",
		"action_rail",
		"toast",
	],
	"upgrade_card": [
		"normal",
		"hover",
		"pressed",
		"focus",
		"selected",
		"disabled",
	],
	"button_primary": [
		"normal", "hover", "pressed", "focus", "disabled",
	],
	"button_secondary": [
		"normal", "hover", "pressed", "focus", "disabled",
	],
	"button_danger": [
		"normal", "hover", "pressed", "focus", "disabled",
	],
	"tab_option": [
		"normal", "hover", "selected", "focus", "disabled",
	],
	"toggle": ["off", "on", "focus"],
	"slider": ["lane", "fill", "grabber"],
	"meter": [
		"background", "health", "boss", "resource", "cooldown",
	],
	"preview": ["normal", "locked", "focused"],
	"small_state": [
		"pip_empty",
		"pip_available",
		"pip_filled",
		"warning",
		"disabled",
		"selection_rail",
	],
}

var _failures: Array[String] = []


func _initialize() -> void:
	var gameplay_manifest := _read_json(GAMEPLAY_MANIFEST_PATH)
	var animations := Dictionary(gameplay_manifest.get("animations", {}))
	for animation_id in EXPECTED_ANIMATIONS:
		if not animations.has(animation_id):
			_failures.append("missing gameplay animation: %s" % animation_id)
			continue
		_validate_animation(animation_id, Dictionary(animations[animation_id]))

	if not FileAccess.file_exists(EVENT_CATALOG_PATH):
		_failures.append("missing visual event catalog: %s" % EVENT_CATALOG_PATH)
	else:
		var catalog_source := FileAccess.get_file_as_string(EVENT_CATALOG_PATH)
		for event_id in EXPECTED_EVENT_IDS:
			_expect(
				catalog_source.contains('"%s"' % event_id)
					or catalog_source.contains('&"%s"' % event_id),
				"missing visual event mapping: %s" % event_id
			)

	if not FileAccess.file_exists(UI_MANIFEST_PATH):
		_failures.append("missing UI asset manifest: %s" % UI_MANIFEST_PATH)
	else:
		_validate_ui_manifest(_read_json(UI_MANIFEST_PATH))
	_finish()


func _validate_animation(animation_id: String, animation: Dictionary) -> void:
	var frame_count := int(animation.get("frame_count", 0))
	var frame_pattern := String(animation.get("frames", ""))
	_expect(frame_count > 0, "%s has no animation frames" % animation_id)
	_expect(
		not frame_pattern.is_empty(),
		"%s has no animation frame path" % animation_id
	)
	_expect(
		int(animation.get("fps", 0)) > 0,
		"%s has no animation FPS" % animation_id
	)
	_expect(
		not bool(animation.get("loop", true)),
		"%s must be a non-looping semantic effect" % animation_id
	)
	for index in frame_count:
		var path := frame_pattern.replace("{index:02}", "%02d" % index)
		if not path.begins_with("res://"):
			path = "res://art/gameplay/semantic-v2/%s" % path
		_expect(
			FileAccess.file_exists(path),
			"missing %s frame: %s" % [animation_id, path]
		)


func _validate_ui_manifest(manifest: Dictionary) -> void:
	var components := Dictionary(manifest.get("components", {}))
	for component_id in EXPECTED_UI_COMPONENT_STATES:
		var required_states := Array(EXPECTED_UI_COMPONENT_STATES[component_id])
		if not components.has(component_id):
			_failures.append("missing UI component: %s" % component_id)
			continue
		var component := Dictionary(components[component_id])
		var states := Dictionary(component.get("states", {}))
		_expect(
			_vector2i(component.get("canvas", [])) != Vector2i.ZERO,
			"%s has no canvas metadata" % component_id
		)
		_expect(
			int(component.get("patch_margin", 0)) > 0,
			"%s has no 9-slice patch margin" % component_id
		)
		var safe_inset := Array(component.get("safe_inset", []))
		_expect(safe_inset.size() == 4, "%s has no text-safe inset" % component_id)
		for state_id in required_states:
			if not states.has(state_id):
				_failures.append(
					"missing UI state: %s/%s" % [component_id, state_id]
				)
				continue
			var path := String(states[state_id])
			if not path.begins_with("res://"):
				path = "res://art/ui/production/semantic-v2/%s" % path
			_expect(
				FileAccess.file_exists(path),
				"missing UI state image: %s/%s -> %s"
				% [component_id, state_id, path]
			)


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(path))
	_expect(error == OK, "invalid JSON manifest: %s" % path)
	if error != OK or not parser.data is Dictionary:
		return {}
	return Dictionary(parser.data)


func _vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		return Vector2i(value)
	if value is Array and Array(value).size() >= 2:
		return Vector2i(int(Array(value)[0]), int(Array(value)[1]))
	return Vector2i.ZERO


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VEHICLE_VISUAL_REPLACEMENT_COVERAGE_VALIDATION_OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
