extends RefCounted
# Shared language and level progress. Works in desktop builds and in Web user:// storage.
const SAVE_PATH := "user://sketch_challenge_progress_v8.cfg"
static var _loaded: bool = false
static var _stage1_cleared: bool = false
static var _stage2_cleared: bool = false
static var _stage3_cleared: bool = false
static var _language: String = "jp"
static var show_levels_on_open: bool = false
# Set only by the Level Select button; skip the redundant Stage 1 intro screen.
static var launch_from_level_menu: bool = false

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		_stage1_cleared = bool(config.get_value("progress", "stage1_cleared", false))
		_stage2_cleared = bool(config.get_value("progress", "stage2_cleared", false))
		_stage3_cleared = bool(config.get_value("progress", "stage3_cleared", false))
		var saved_lang: String = str(config.get_value("settings", "language", "jp"))
		_language = saved_lang if saved_lang in ["jp", "mm", "en"] else "jp"

static func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "stage1_cleared", _stage1_cleared)
	config.set_value("progress", "stage2_cleared", _stage2_cleared)
	config.set_value("progress", "stage3_cleared", _stage3_cleared)
	config.set_value("settings", "language", _language)
	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Could not save game progress: " + str(result))

static func get_language() -> String:
	_ensure_loaded()
	return _language

static func set_language(lang: String) -> void:
	_ensure_loaded()
	if lang not in ["jp", "mm", "en"]:
		return
	_language = lang
	_save()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { localStorage.setItem('kitchenLanguage',"+JSON.stringify(lang)+"); } catch(e) {}",true)
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var manager := tree.root.get_node_or_null("LocaleManager")
		if manager != null: manager.call("set_language",lang)

static func is_level_unlocked(level: int) -> bool:
	_ensure_loaded()
	return level >= 1 and level <= 3

static func unlock_level(level: int) -> void:
	_ensure_loaded()
	# Only the verified Stage 1 success path in Main.gd calls unlock_level(2).
	if level == 2 and not _stage1_cleared:
		_stage1_cleared = true
		_save()

static func get_highest_unlocked() -> int:
	_ensure_loaded()
	return 3

static func is_completed(stage: int) -> bool:
	_ensure_loaded()
	return _stage1_cleared if stage == 1 else (_stage2_cleared if stage == 2 else (_stage3_cleared if stage == 3 else false))

static func complete(stage: int) -> void:
	_ensure_loaded()
	if stage == 1: _stage1_cleared = true
	elif stage == 2: _stage2_cleared = true
	elif stage == 3: _stage3_cleared = true
	else: return
	_save()

static func completed_count() -> int:
	_ensure_loaded()
	return int(_stage1_cleared)+int(_stage2_cleared)+int(_stage3_cleared)

static func next_stage() -> int:
	for stage in range(1,4):
		if not is_completed(stage): return stage
	return 3

# Testing option: reset level unlocks, keeping the chosen language.
static func reset_progress() -> void:
	_ensure_loaded()
	_stage1_cleared = false
	_stage2_cleared = false
	_stage3_cleared = false
	_save()
