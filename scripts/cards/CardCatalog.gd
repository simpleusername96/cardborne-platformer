class_name CardCatalog
extends Resource

@export var id: StringName
@export var display_name: String
@export var content_version: int = 1
@export var cards: Array[CardDefinition] = []


func get_card(card_id: StringName) -> CardDefinition:
	for card in cards:
		if card != null and card.id == card_id:
			return card
	return null


func validate_catalog() -> PackedStringArray:
	var errors := PackedStringArray()
	ContentId.validate(errors, "Card catalog ID", id)
	if display_name.strip_edges().is_empty() or content_version <= 0:
		errors.append("Card catalog needs a display name and positive version.")
	if cards.size() < 3:
		errors.append("Card catalog needs at least three cards for a complete offer.")
	var seen: Dictionary = {}
	for card_index in cards.size():
		var card := cards[card_index]
		if card == null:
			errors.append("Card at index %d is null." % card_index)
			continue
		if seen.has(card.id):
			errors.append("Card catalog repeats '%s'." % card.id)
		seen[card.id] = true
		for card_error in card.validate_definition():
			errors.append(card_error)
	return errors
