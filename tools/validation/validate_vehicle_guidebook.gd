extends SceneTree

const Catalog = preload("res://scripts/progression/vehicle_guidebook_catalog.gd")
const Store = preload("res://scripts/autoload/vehicle_guidebook_store.gd")
const GuidePanel = preload("res://scripts/ui/vehicle_guidebook_panel.gd")

var failures: Array[String] = []
const TEST_PATH := "user://vehicle-guidebook-validation.cfg"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var original_locale := TranslationServer.get_locale()
	var store := Store.new()
	store.save_path = TEST_PATH
	store.known.clear()
	_expect(store.discover(&"mobile_chaser"), "first encounter unlocks one entry")
	_expect(not store.discover(&"mobile_chaser"), "discovery is idempotent")
	_expect(not store.discover(&"unknown_entry"), "unknown IDs are discarded")
	_expect(Catalog.entry_id_for_enemy(&"spark_minelet", &"mine") == &"mobile_spark_minelet", "moving minelets stay in the mobile guide category")
	_expect(Catalog.entry_id_for_enemy(&"mine", &"mine") == &"stationary_mine", "authored mines stay in the stationary guide category")
	_expect(Catalog.valid_ids().has(&"mobile_bulkhead_guard"), "Bulkhead Guard has a stable guide entry")
	_expect(Catalog.valid_ids().has(&"object_transit_gate"), "Transit Gate has a stable guide entry")
	var locked := store.snapshot({"health":120.0})
	var mobile: Array = locked["categories"][&"mobile"]
	var hidden := mobile.filter(func(entry: Dictionary) -> bool: return bool(entry["locked"]))
	_expect(hidden.all(func(entry: Dictionary) -> bool: return entry.keys().all(func(key): return key in ["id", "locked", "name", "description"]) and entry["name"] == "???" and entry["description"] == ""), "locked entries contain no hidden copy")
	store.discover(&"stationary_mine")
	store.discover(&"boss_stage_2")
	store.discover(&"object_transit_gate")
	var active_ship := {
		"active":true,
		"run_state":{
			"level":3,
			"health":88.0,
			"max_health":120.0,
			"experience":4,
			"experience_required":12,
		},
		"stats":[],
		"secondaries":[],
		"upgrades":[],
	}
	var visual := store.snapshot(active_ship)
	for category in [&"stationary", &"bosses", &"objects"]:
		var unlocked: Array = visual["categories"][category].filter(
			func(entry: Dictionary) -> bool: return not bool(entry["locked"])
		)
		var complete := true
		for entry in unlocked:
			complete = (
				complete
				and not Dictionary(entry.get("preview", {})).is_empty()
				and not String(entry.get("counter_key", "")).is_empty()
			)
		_expect(
			complete,
			"%s unlocked entries expose preview and counterplay metadata" % category
		)
	var loaded := Store.new()
	loaded.save_path = TEST_PATH
	loaded.load_discovery()
	_expect(loaded.known.has(&"mobile_chaser") and loaded.known.size() == 4, "discovery save round-trips sanitized IDs")
	var panel := GuidePanel.new()
	get_root().add_child(panel)
	await process_frame
	panel.open(visual)
	await process_frame
	var contract := panel.debug_contract()
	_expect(
		int(contract["categories"]) == 5
			and Array(contract["category_order"]) == [
				&"ship", &"mobile", &"stationary", &"bosses", &"objects",
			]
			and int(contract["command_height"]) >= 44
			and bool(contract["category_has_focus"]),
		"guide modal preserves five accessible categories in product order"
	)
	_expect(bool(contract["ship_entry_column_hidden"]), "Current Ship removes the redundant entry column")
	_expect(
		bool(contract["ship_detail_full_width"])
			and StringName(contract["preview_shell_variation"]) == &"PreviewFrame"
			and bool(Dictionary(contract["preview"])["ship_nose_up"]),
		"Current Ship uses a full-width shared PreviewWell with nose-up craft asset"
	)
	var build_contract := Dictionary(contract["build_summary"])
	_expect(
		bool(build_contract["active"])
			and int(build_contract["summary_panel_count"]) == 0
			and int(build_contract["text_row_count"]) >= 5,
		"active ship summary uses shared rows without a summary panel"
	)
	_expect(panel.debug_select_entry(&"bosses", &"boss_stage_2"), "discovered boss detail is selectable")
	contract = panel.debug_contract()
	_expect(
		bool(contract["entry_column_visible"])
			and bool(contract["structured_counterplay"])
			and int(contract["counterplay_rows"]) == 3
			and int(contract["row_panel_count"]) == 0
			and bool(Dictionary(contract["preview"])["semantic_provider"]),
		"discovered detail restores the list and three unboxed counterplay rows"
	)
	var locked_id := &""
	for category in [&"mobile", &"stationary", &"bosses", &"objects"]:
		for entry_variant in Array(visual["categories"][category]):
			var entry := Dictionary(entry_variant)
			if bool(entry.get("locked", false)):
				locked_id = StringName(entry["id"])
				_expect(panel.debug_select_entry(category, locked_id), "locked entry remains selectable without disclosure")
				contract = panel.debug_contract()
				_expect(
					Array(Dictionary(contract["preview"])["asset_ids"])
						== [&"hud/minimap_marker_objective_locked"],
					"locked detail exposes only the approved locked silhouette"
				)
				break
		if not locked_id.is_empty():
			break
	_expect(not locked_id.is_empty(), "guide fixture includes a locked confidentiality state")
	panel.set_compact_mode(true)
	panel.open(visual)
	await process_frame
	_expect(panel.debug_select_entry(&"mobile", &"mobile_chaser"), "compact list selects a discovered mobile entry")
	contract = panel.debug_contract()
	var ratios := Array(contract["entry_detail_ratios"])
	_expect(
		bool(contract["compact_selector_visible"])
			and not bool(contract["wide_rail_visible"])
			and int(contract["compact_selector_count"]) == 5
			and bool(contract["category_has_focus"])
			and int(contract["entry_focusables"]) > 0
			and is_equal_approx(float(ratios[0]), 0.34)
			and is_equal_approx(float(ratios[1]), 0.66)
			and bool(contract["independent_scroll"]),
		"compact guide uses one five-option selector and independent 34/66 scroll panes"
	)
	panel.call("_select_category", &"ship")
	contract = panel.debug_contract()
	_expect(
		bool(contract["ship_entry_column_hidden"])
			and bool(contract["ship_detail_full_width"]),
		"Ship full-width detail restores after repeated compact category changes"
	)
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		panel.open(visual)
		contract = panel.debug_contract()
		_expect(
			String(contract["title"]) == tr("GUIDE_TITLE")
				and String(contract["close_text"]) == tr("SETTINGS_CLOSE"),
			"guidebook persistent controls refresh in %s" % locale
		)
	TranslationServer.set_locale(original_locale)
	panel.queue_free()
	await process_frame
	store.free()
	loaded.free()
	panel = null
	store = null
	loaded = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("VEHICLE_GUIDEBOOK_VALIDATION_OK")
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)
