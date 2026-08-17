extends SceneTree

const SCOPE_COLOR := Color("ff3038")
const LINE_WIDTH := 4


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var input_path := args[0] if args.size() == 2 else OS.get_environment("CARDBORNE_HUD_SCOPE_INPUT")
	var output_path := args[1] if args.size() == 2 else OS.get_environment("CARDBORNE_HUD_SCOPE_OUTPUT")
	if input_path.is_empty() or output_path.is_empty():
		push_error("Usage: -- <input_png> <output_png>")
		quit(2)
		return
	var image := Image.load_from_file(input_path)
	if image == null or image.is_empty():
		push_error("Could not load HUD scope source: %s" % input_path)
		quit(3)
		return

	# The live top-left status row is the only HUD edit scope. The source pixels
	# stay untouched outside this evidence rail.
	_draw_rect(image, Rect2i(94, 104, 288, 72))

	var error := image.save_png(output_path)
	if error != OK:
		push_error("Could not save HUD scope template: %s" % error_string(error))
		quit(4)
		return
	quit()


func _draw_rect(image: Image, rect: Rect2i) -> void:
	image.fill_rect(Rect2i(rect.position, Vector2i(rect.size.x, LINE_WIDTH)), SCOPE_COLOR)
	image.fill_rect(
		Rect2i(rect.position + Vector2i(0, rect.size.y - LINE_WIDTH), Vector2i(rect.size.x, LINE_WIDTH)),
		SCOPE_COLOR
	)
	image.fill_rect(Rect2i(rect.position, Vector2i(LINE_WIDTH, rect.size.y)), SCOPE_COLOR)
	image.fill_rect(
		Rect2i(rect.position + Vector2i(rect.size.x - LINE_WIDTH, 0), Vector2i(LINE_WIDTH, rect.size.y)),
		SCOPE_COLOR
	)
