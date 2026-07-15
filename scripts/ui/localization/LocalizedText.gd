class_name LocalizedText
extends RefCounted

## Resolves translated UI copy without depending on autoload parse order.
static func resolve(context: Node, source_value: Variant, values: Array = []) -> String:
	var source := String(source_value)
	if source.is_empty():
		return ""
	var localization := context.get_node_or_null("/root/UILocalization")
	if localization != null and localization.has_method("text"):
		return String(localization.call("text", StringName(source), values))
	var translated := String(TranslationServer.translate(StringName(source)))
	if translated.is_empty():
		translated = source
	if values.is_empty():
		return translated
	return translated % values if translated.contains("%") else translated.format(values)
