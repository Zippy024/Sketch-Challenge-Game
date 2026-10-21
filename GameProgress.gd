extends RefCounted
# Shared language and level progress. Works in desktop builds and in Web user:// storage.
const SAVE_PATH := "user://sketch_challenge_progress_v8.cfg"
static var _loaded: bool = false
static var _stage1_cleared: bool = false
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
		var saved_lang: String = str(config.get_value("settings", "language", "jp"))
		_language = saved_lang if saved_lang in ["jp", "mm"] else "jp"

static func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "stage1_cleared", _stage1_cleared)
	config.set_value("settings", "language", _language)
	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Could not save game progress: " + str(result))

static func get_language() -> String:
	_ensure_loaded()
	return _language

static func set_language(lang: String) -> void:
	_ensure_loaded()
	if lang not in ["jp", "mm"]:
		return
	_language = lang
	_save()

static func is_level_unlocked(level: int) -> bool:
	_ensure_loaded()
	return level == 1 or (level == 2 and _stage1_cleared)

static func unlock_level(level: int) -> void:
	_ensure_loaded()
	# Only the verified Stage 1 success path in Main.gd calls unlock_level(2).
	if level == 2 and not _stage1_cleared:
		_stage1_cleared = true
		_save()

static func get_highest_unlocked() -> int:
	_ensure_loaded()
	return 2 if _stage1_cleared else 1

# Testing option: reset level unlocks, keeping the chosen language.
static func reset_progress() -> void:
	_ensure_loaded()
	_stage1_cleared = false
	_save()
