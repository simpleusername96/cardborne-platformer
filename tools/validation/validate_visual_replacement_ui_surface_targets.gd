extends SceneTree

## Validates the Phase 5 foundational UI surface families against their locked
## manifest geometry and palette before any TO-BE bytes reach production.

const WORKBENCH_PATH := (
	"res://docs/design/visual-replacement-workbench/replacement-workbench.json"
)
const UI_MANIFEST_PATH := "res://art/visuals/production/ui/ui-asset-manifest.json"
const TO_BE_PREFIX := (
	"res://docs/design/visual-replacement-workbench/to-be/assets/"
)
const PRODUCTION_UI_PREFIX := "res://art/visuals/production/ui/"
const SURFACE_UNIT_IDS := ["modal_master", "content_plate", "hud_plate"]
const READY_STATES := ["switch_ready", "approved_for_switch"]
const PRODUCTION_STATES := ["applied", "keep_current"]
const APPROVED_PALETTE := [
	Color8(0x07, 0x0b, 0x11),
	Color8(0x10, 0x19, 0x23),
	Color8(0x18, 0x24, 0x31),
	Color8(0x24, 0x34, 0x45),
	Color8(0x46, 0x5a, 0x6e),
	Color8(0xee, 0xf3, 0xf7),
	Color8(0x9e, 0xad, 0xbc),
	Color8(0xf2, 0xb7, 0x35),
	Color8(0xf0, 0x5a, 0x5f),
	Color8(0xd4, 0x3f, 0x8d),
	Color8(0x72, 0xd6, 0xc4),
	Color8(0x58, 0xbf, 0xea),
]
const SEMANTIC_ACCENTS := [
	Color8(0xf2, 0xb7, 0x35),
	Color8(0xf0, 0x5a, 0x5f),
	Color8(0xd4, 0x3f, 0x8d),
	Color8(0x72, 0xd6, 0xc4),
	Color8(0x58, 0xbf, 0xea),
]

var _failures: Array[String] = []


func _initialize() -> void:
	var workbench := _read_json(WORKBENCH_PATH)
	var manifest := _read_json(UI_MANIFEST_PATH)
	var components := Dictionary(manifest.get("components", {}))
	var units := _units_by_id(Array(workbench.get("units", [])))
	for unit_id in SURFACE_UNIT_IDS:
		_expect(units.has(unit_id), "missing workbench unit: %s" % unit_id)
		_expect(components.has(unit_id), "missing UI manifest component: %s" % unit_id)
		if not units.has(unit_id) or not components.has(unit_id):
			continue
		_validate_family(
			unit_id,
			Dictionary(units[unit_id]),
			Dictionary(components[unit_id])
		)
	_finish()


func _validate_family(
	unit_id: String,
	unit: Dictionary,
	component: Dictionary
) -> void:
	var status := String(unit.get("status", ""))
	_expect(
		status in READY_STATES or status in PRODUCTION_STATES,
		"%s is not ready for surface validation: %s" % [unit_id, status]
	)
	if status not in READY_STATES and status not in PRODUCTION_STATES:
		return
	var canvas := _vector2i(component.get("canvas", []))
	var safe_inset := _int_array(component.get("safe_inset", []))
	var states := Dictionary(component.get("states", {}))
	var deliverables := _deliverables_by_target(
		Array(unit.get("deliverables", []))
	)
	if status in READY_STATES:
		_expect(
			deliverables.size() == states.size(),
			"%s deliverable count differs from manifest state count" % unit_id
		)
	var grayscale_signatures: Dictionary = {}
	for state_id in states:
		var relative_path := String(states[state_id])
		var target_path := "art/visuals/production/ui/%s" % relative_path
		if status in READY_STATES:
			_expect(
				deliverables.has(target_path),
				"%s/%s lacks its exact target declaration" % [unit_id, state_id]
			)
			if not deliverables.has(target_path):
				continue
			_validate_deliverable_geometry(
				unit_id,
				state_id,
				Dictionary(deliverables[target_path]),
				canvas,
				safe_inset,
				int(component.get("patch_margin", 0))
			)
		var image_path := (
			TO_BE_PREFIX + target_path
			if status in READY_STATES
			else PRODUCTION_UI_PREFIX + relative_path
		)
		var image := _load_image(image_path)
		if image == null:
			continue
		_validate_image(
			unit_id, String(state_id), image_path, image, canvas, safe_inset
		)
		var grayscale := image.duplicate()
		grayscale.convert(Image.FORMAT_LA8)
		var signature := _sha256(grayscale.get_data())
		_expect(
			not grayscale_signatures.has(signature),
			"%s/%s is not structurally distinct in grayscale"
			% [unit_id, state_id]
		)
		grayscale_signatures[signature] = state_id


func _validate_deliverable_geometry(
	unit_id: String,
	state_id: String,
	deliverable: Dictionary,
	canvas: Vector2i,
	safe_inset: Array[int],
	patch_margin: int
) -> void:
	_expect(
		Vector2i(
			int(deliverable.get("width", 0)),
			int(deliverable.get("height", 0))
		) == canvas,
		"%s/%s deliverable canvas differs from manifest" % [unit_id, state_id]
	)
	_expect(
		int(deliverable.get("patch_margin", 0)) == patch_margin,
		"%s/%s patch margin differs from manifest" % [unit_id, state_id]
	)
	_expect(
		_int_array(deliverable.get("safe_inset", [])) == safe_inset,
		"%s/%s safe inset differs from manifest" % [unit_id, state_id]
	)


func _validate_image(
	unit_id: String,
	state_id: String,
	image_path: String,
	image: Image,
	canvas: Vector2i,
	safe_inset: Array[int]
) -> void:
	_expect(
		image.get_size() == canvas,
		"%s/%s decoded canvas differs from manifest: %s"
		% [unit_id, state_id, image_path]
	)
	if image.get_size() != canvas or safe_inset.size() != 4:
		return
	for corner in [
		Vector2i(0, 0),
		Vector2i(canvas.x - 1, 0),
		Vector2i(0, canvas.y - 1),
		Vector2i(canvas.x - 1, canvas.y - 1),
	]:
		_expect(
			image.get_pixelv(corner).a < 0.05,
			"%s/%s must retain transparent exterior corners"
			% [unit_id, state_id]
		)
	var accent_count := 0
	var unsafe_accent_count := 0
	var first_palette_violation := Vector2i(-1, -1)
	for y in canvas.y:
		for x in canvas.x:
			var color := image.get_pixel(x, y)
			if color.a <= 0.0:
				continue
			if (
				first_palette_violation == Vector2i(-1, -1)
				and not _palette_contains(color, APPROVED_PALETTE)
			):
				first_palette_violation = Vector2i(x, y)
			if _palette_contains(color, SEMANTIC_ACCENTS):
				accent_count += 1
				if (
					x >= safe_inset[0]
					and x < canvas.x - safe_inset[2]
					and y >= safe_inset[1]
					and y < canvas.y - safe_inset[3]
				):
					unsafe_accent_count += 1
	_expect(
		first_palette_violation == Vector2i(-1, -1),
		"%s/%s contains a color outside the fixed palette at %d,%d"
		% [
			unit_id,
			state_id,
			first_palette_violation.x,
			first_palette_violation.y,
		]
	)
	_expect(
		accent_count > 0,
		"%s/%s lacks a semantic accent rail" % [unit_id, state_id]
	)
	_expect(
		unsafe_accent_count == 0,
		"%s/%s places semantic accent pixels inside the content-safe area"
		% [unit_id, state_id]
	)


func _palette_contains(color: Color, palette: Array) -> bool:
	for allowed in palette:
		if (
			roundi(color.r * 255.0) == roundi(allowed.r * 255.0)
			and roundi(color.g * 255.0) == roundi(allowed.g * 255.0)
			and roundi(color.b * 255.0) == roundi(allowed.b * 255.0)
		):
			return true
	return false


func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	var error := context.start(HashingContext.HASH_SHA256)
	_expect(error == OK, "cannot initialize grayscale SHA-256")
	if error != OK:
		return ""
	context.update(bytes)
	return context.finish().hex_encode()


func _units_by_id(units: Array) -> Dictionary:
	var indexed := {}
	for unit_variant in units:
		var unit := Dictionary(unit_variant)
		indexed[String(unit.get("id", ""))] = unit
	return indexed


func _deliverables_by_target(deliverables: Array) -> Dictionary:
	var indexed := {}
	for deliverable_variant in deliverables:
		var deliverable := Dictionary(deliverable_variant)
		indexed[String(deliverable.get("target_path", ""))] = deliverable
	return indexed


func _load_image(path: String) -> Image:
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(path))
	_expect(error == OK, "cannot decode UI surface target: %s" % path)
	return image if error == OK else null


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_failures.append("missing JSON file: %s" % path)
		return {}
	var parser := JSON.new()
	var error := parser.parse(FileAccess.get_file_as_string(path))
	_expect(error == OK, "invalid JSON file: %s" % path)
	if error != OK or not parser.data is Dictionary:
		return {}
	return Dictionary(parser.data)


func _vector2i(value: Variant) -> Vector2i:
	var values := Array(value) if value is Array else []
	return (
		Vector2i(int(values[0]), int(values[1]))
		if values.size() >= 2
		else Vector2i.ZERO
	)


func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if value is Array:
		for item in Array(value):
			result.append(int(item))
	return result


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("VISUAL_REPLACEMENT_UI_SURFACE_TARGETS_OK families=3 states=10")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)
