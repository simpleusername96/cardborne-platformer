extends SceneTree

const Archetypes = preload("res://scripts/enemies/vehicle_enemy_archetypes.gd")
const Catalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const EncounterDirector = preload("res://scripts/encounters/vehicle_encounter_director.gd")
const GuidePanel = preload("res://scripts/ui/vehicle_guidebook_panel.gd")
const GuidePreview = preload("res://scripts/ui/vehicle_guidebook_preview.gd")
const StatAdapter = preload("res://scripts/progression/vehicle_guidebook_stat_adapter.gd")
const StageDifficulty = preload("res://scripts/enemies/vehicle_stage_difficulty.gd")
const Store = preload("res://scripts/autoload/vehicle_guidebook_store.gd")

const TEST_PATH := "user://vehicle-guidebook-validation.cfg"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_locale := TranslationServer.get_locale()
	var store := Store.new()
	store.save_path = TEST_PATH
	store.known.clear()
	_expect(store.discover(&"enemy_ordinary_pursuer_t1"), "first encounter unlocks one entry")
	_expect(not store.discover(&"enemy_ordinary_pursuer_t1"), "discovery is idempotent")
	_expect(not store.discover(&""), "empty discovery IDs are discarded")
	_expect(not store.discover(&"unknown_entry"), "unknown IDs are discarded")
	for entry_id in [
		&"boss_stage_01", &"object_transit_gate", &"object_mystery_device",
		&"object_trait_splitter",
	]:
		_expect(store.discover(entry_id), "%s unlocks" % entry_id)
	_validate_catalog_partition()

	var outside := store.snapshot({"health":120.0})
	_expect(
		Array(outside["category_order"]) == [
			&"ship", &"enemies", &"bosses", &"objects",
		],
		"Guidebook category order is Current Ship, Enemies, Bosses, Field Objects"
	)
	_expect(
		not JSON.stringify(outside).contains("???")
			and not JSON.stringify(outside).contains("movement_key")
			and not JSON.stringify(outside).contains("attack_key")
			and not JSON.stringify(outside).contains("counter_key")
			and not JSON.stringify(outside).contains("description_key"),
		"snapshot contains no fake unknown rows or generic prose fields"
	)
	for category in [&"enemies", &"bosses", &"objects"]:
		var summaries := Array(outside["categories"][category]).filter(
			func(value: Variant) -> bool:
				return bool(Dictionary(value).get("locked_summary", false))
		)
		_expect(
			summaries.size() <= 1
				and (summaries.is_empty() or int(summaries[0]["locked_count"]) > 0),
			"%s has at most one non-disclosing locked-count summary" % category
		)

	var active_ship := {
		"active":true,
		"run_state":{
			"level":3,
			"health":88.0,
			"max_health":120.0,
			"experience":4,
			"experience_required":6,
		},
		"stats":[],
		"secondaries":[],
		"upgrades":[],
	}
	var active := store.snapshot(active_ship, {"active_stage_index":1})
	_validate_stat_parity(outside, active)

	var compatibility_config := ConfigFile.new()
	_expect(
		compatibility_config.load(TEST_PATH) == OK,
		"discovery fixture is available for retired-ID compatibility"
	)
	var compatibility_ids := PackedStringArray(
		compatibility_config.get_value(
			"discovery", "known", PackedStringArray()
		)
	)
	compatibility_ids.append("object_crate")
	compatibility_ids.append("enemy_ordinary_%s_t2" % ["gun" + "ner"])
	compatibility_config.set_value("meta", "version", 1)
	compatibility_config.set_value("discovery", "known", compatibility_ids)
	_expect(
		compatibility_config.save(TEST_PATH) == OK,
		"retired crate fixture is written without changing the live catalog"
	)
	var loaded := Store.new()
	loaded.save_path = TEST_PATH
	loaded.load_discovery()
	_expect(
		loaded.known.has(&"enemy_ordinary_pursuer_t1")
			and loaded.known.has(&"enemy_ordinary_emitter_t2")
			and not loaded.known.has(&"object_crate")
			and loaded.known.size() == 6,
		"schema-v1 load migrates the renamed family and ignores retired IDs"
	)
	var migrated_config := ConfigFile.new()
	_expect(
		migrated_config.load(TEST_PATH) == OK
			and int(migrated_config.get_value("meta", "version", 0)) == 2,
		"schema-v1 discovery data is rewritten at the current version"
	)

	var panel := GuidePanel.new()
	get_root().add_child(panel)
	await process_frame
	panel.open(active)
	await process_frame
	var contract := panel.debug_contract()
	_expect(
		int(contract["categories"]) == 4
			and Array(contract["category_order"]) == [
				&"ship", &"enemies", &"bosses", &"objects",
			]
			and int(contract["command_height"]) >= 48
			and bool(contract["category_has_focus"]),
		"guide modal preserves four accessible categories in product order"
	)
	_expect(
		String(contract["close_text"]) == "←"
			and String(contract["close_accessible_name"]) == tr("COMMON_BACK")
			and String(contract["close_tooltip"]) == tr("COMMON_BACK"),
		"Guidebook Back is a 48px icon command with a localized accessible name"
	)
	_expect(bool(contract["ship_entry_column_hidden"]), "Current Ship removes the redundant entry column")
	_expect(
		bool(contract["ship_detail_full_width"])
			and StringName(contract["preview_shell_variation"]) == &"PreviewFrame"
			and bool(Dictionary(contract["preview"])["ship_nose_up"]),
		"Current Ship keeps its full-width shared PreviewWell"
	)
	var build_contract := Dictionary(contract["build_summary"])
	_expect(
		bool(build_contract["active"])
			and int(build_contract["summary_panel_count"]) == 0
			and int(build_contract["text_row_count"]) >= 5,
		"active ship summary keeps its useful build rows"
	)
	_expect(panel.debug_select_entry(&"bosses", &"boss_stage_01"), "discovered boss detail is selectable")
	contract = panel.debug_contract()
	_expect(
		bool(contract["entry_column_visible"])
			and bool(contract["structured_stats"])
			and int(contract["stat_rows"]) == 4
			and int(contract["row_panel_count"]) == 0
			and bool(Dictionary(contract["preview"])["semantic_provider"]),
		"unshielded boss detail renders four canonical stat rows without generic prose"
	)
	_expect(panel.debug_select_entry(&"enemies", &"enemy_ordinary_pursuer_t1"), "enemy detail is selectable")
	contract = panel.debug_contract()
	_expect(
		int(contract["stat_rows"]) == 3
			and int(contract["locked_summary_count"]) == 3,
		"enemy detail shows health, attack, and speed while locks stay summarized"
	)
	_expect(
		panel.debug_select_entry(&"objects", &"object_mystery_device"),
		"enemy upgrade-device detail is selectable"
	)
	contract = panel.debug_contract()
	_expect(
		Array(Dictionary(contract["preview"])["asset_ids"])
			== [&"world/enemy_upgrade_device"],
		"enemy upgrade-device preview hides retired facility identities"
	)
	var preview := GuidePreview.new()
	get_root().add_child(preview)
	await process_frame
	for archetype in [
		&"ordinary_pursuer_t1", &"ordinary_charger_t2", &"ordinary_emitter_t3",
		&"ordinary_defender_t1", &"ordinary_coordinator_t2",
	]:
		preview.show_preview({"kind":&"enemy", "id":archetype})
		_expect(
			Array(preview.debug_contract()["asset_ids"])
				== [StringName("actor/%s" % String(archetype))],
			"%s guidebook preview resolves its approved semantic actor image" % archetype
		)
	preview.queue_free()

	panel.set_compact_mode(true)
	panel.open(active)
	await process_frame
	_expect(panel.debug_select_entry(&"enemies", &"enemy_ordinary_pursuer_t1"), "compact list selects a discovered enemy")
	contract = panel.debug_contract()
	var ratios := Array(contract["entry_detail_ratios"])
	_expect(
		bool(contract["compact_selector_visible"])
			and not bool(contract["wide_rail_visible"])
			and int(contract["compact_selector_count"]) == 4
			and bool(contract["category_has_focus"])
			and int(contract["entry_focusables"]) == 2
			and is_equal_approx(float(ratios[0]), 0.34)
			and is_equal_approx(float(ratios[1]), 0.66)
			and bool(contract["independent_scroll"]),
		"compact guide keeps independent panes and excludes the locked summary from focus"
	)

	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		panel.open(active)
		contract = panel.debug_contract()
		_expect(
			String(contract["title"]) == tr("GUIDE_TITLE")
				and String(contract["close_text"]) == "←"
				and String(contract["close_accessible_name"]) == tr("COMMON_BACK"),
			"guidebook title and icon command refresh in %s" % locale
		)
	TranslationServer.set_locale(original_locale)
	panel.queue_free()
	await process_frame
	store.free()
	loaded.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_finish()


func _validate_catalog_partition() -> void:
	var entries_by_id := {}
	for entry in Catalog.ENTRIES:
		entries_by_id[StringName(entry["id"])] = entry
		if StringName(entry["category"]) == &"objects":
			_expect(
				StringName(entry["entry_kind"]) == &"object",
				"Field Objects contains only non-hostile world objects"
			)
	for archetype in Archetypes.ORDINARY_ARCHETYPES:
		var entry_id := Catalog.entry_id_for_enemy(archetype, archetype)
		_expect(
			not entry_id.is_empty()
				and entries_by_id.has(entry_id)
				and StringName(entries_by_id[entry_id]["category"]) == &"enemies",
			"%s appears under Enemies" % archetype
		)
	_expect(
		Catalog.ENEMY_ENTRY_IDS.size() == Archetypes.ORDINARY_ARCHETYPES.size(),
		"constant enemy discovery mapping covers every ordinary family tier"
	)
	_expect(
		Catalog.entry_id_for_enemy(&"boss_pattern_fixed_beam_01", &"boss_pattern_fixed_beam_01").is_empty(),
		"boss-owned fixed beam does not leak into ordinary enemy discovery"
	)
	var boss_stage_indices: Array[int] = []
	for entry in Catalog.ENTRIES:
		if StringName(entry["entry_kind"]) == &"boss":
			boss_stage_indices.append(int(entry["boss_stage_index"]))
	_expect(
		boss_stage_indices == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
		"twelve guidebook bosses map to all twelve campaign cycles"
	)
	_expect(
		not entries_by_id.has(&"object_crate")
			and not Catalog.valid_ids().has(&"object_crate"),
		"retired crates stay absent from active catalog and discovery"
	)
	for trait_id in [
		&"object_trait_splitter", &"object_trait_frenzy", &"object_trait_double",
		&"object_trait_self_destruct", &"object_trait_artillery", &"object_trait_slow",
		&"object_trait_bulwark", &"object_trait_reflector", &"object_trait_blink",
		&"object_trait_pack_feed",
	]:
		_expect(
			StringName(entries_by_id[trait_id]["category"]) == &"enemies"
				and StringName(entries_by_id[trait_id]["entry_kind"]) == &"trait",
			"%s family trait appears under Enemies" % trait_id
		)


func _validate_stat_parity(outside: Dictionary, active: Dictionary) -> void:
	var outside_pursuer := _entry(outside, &"enemies", &"enemy_ordinary_pursuer_t1")
	var active_pursuer := _entry(active, &"enemies", &"enemy_ordinary_pursuer_t1")
	var outside_health := Dictionary(Array(outside_pursuer["stat_rows"])[0])
	var active_health := Dictionary(Array(active_pursuer["stat_rows"])[0])
	var definition := Archetypes.definition(&"ordinary_pursuer_t1")
	var expected_stage_two_health := (
		float(definition["health"])
		* EncounterDirector.ENEMY_HEALTH_MULTIPLIER
		* StageDifficulty.ordinary_health_multiplier(1)
		* StageDifficulty.ORDINARY_HEALTH_MULTIPLIER
		* StageDifficulty.ORDINARY_DURABILITY_MULTIPLIER
	)
	_expect(
		String(outside_health["value_key"]) == "GUIDE_VALUE_HP_RANGE"
			and Array(outside_health["value_args"]).size() == 2
			and String(active_health["value_key"]) == "GUIDE_VALUE_HP"
			and int(Array(active_health["value_args"])[0])
				== roundi(expected_stage_two_health),
		"enemy health row derives the Cycle 2 exact value and outside-run Cycle 1–8 range"
	)
	var emitter_rows := StatAdapter.enemy_rows(
		&"ordinary_emitter_t1", {"active_stage_index":1}
	)
	var coordinator_rows := StatAdapter.enemy_rows(
		&"ordinary_coordinator_t1", {"active_stage_index":1}
	)
	var emitter_attack := Dictionary(emitter_rows[1])
	var coordinator_attack := Dictionary(coordinator_rows[1])
	_expect(
		String(emitter_attack["value_key"]) == "GUIDE_VALUE_DAMAGE_WITH_RANGE"
			and int(Array(emitter_attack["value_args"])[1]) == 700
			and String(coordinator_attack["value_key"])
				== "GUIDE_VALUE_DAMAGE_WITH_RANGE"
			and int(Array(coordinator_attack["value_args"])[1]) == 660,
		"Emitter and Coordinator guide rows publish their exact attack ranges"
	)
	var boss := _entry(active, &"bosses", &"boss_stage_01")
	var boss_rows := Array(boss["stat_rows"])
	_expect(
		boss_rows.size() == 4
			and int(Array(Dictionary(boss_rows[0])["value_args"])[0])
				== roundi(StageDifficulty.boss_health(0))
			and float(Array(Dictionary(boss_rows[1])["value_args"])[0]) > 0.0
			and String(Dictionary(boss_rows[2])["label_key"]) == "GUIDE_STAT_AUTONOMOUS_CADENCE",
		"unshielded boss rows derive exact HP, damage, cadence, and coverage"
	)
	var shielded_rows := StatAdapter.boss_rows(2)
	_expect(
		shielded_rows.size() == 6
			and int(Array(Dictionary(shielded_rows[2])["value_args"])[0]) == 85,
		"shield-owning Cycle 3 alone includes shield reduction and exposure rows"
	)
	_expect(
		StatAdapter.boss_rows(-1).is_empty()
			and StatAdapter.boss_rows(12).is_empty(),
		"boss rows fail closed outside the twelve-cycle campaign"
	)
	var anomaly := _entry(active, &"objects", &"object_mystery_device")
	_expect(
		String(anomaly["name_key"]) == "GUIDE_OBJECT_MYSTERY_DEVICE_NAME"
			and Array(anomaly["stat_rows"]).size() == 5
			and String(Dictionary(Array(anomaly["stat_rows"])[0])["value_key"])
				== "GUIDE_VALUE_HP",
		"enemy upgrade device exposes base HP, channel, and three future-enemy bonuses"
	)


func _entry(snapshot: Dictionary, category: StringName, entry_id: StringName) -> Dictionary:
	for value in Array(snapshot["categories"][category]):
		var entry := Dictionary(value)
		if StringName(entry.get("id", &"")) == entry_id:
			return entry
	return {}


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_GUIDEBOOK_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
