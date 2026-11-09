extends RefCounted
# MENU-ONLY user:// metadata. No changes to Stage 1/2/3 game scripts or scoring.
# Not an authentication system: display name is stored locally on this device/browser.
const SAVE_PATH := "user://sketch_challenge_menu_extras_v1.cfg"
static var _loaded: bool = false
static var _display_name: String = "Guest"
static var _stage1_starts: int = 0
static var _stage2_starts: int = 0
static var _stage3_starts: int = 0
static var _last_stage: int = 0
static var _last_date: String = ""
static var _volume: float = 0.85
static var _muted: bool = false

static func _load_data() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) != OK:
		return
	_display_name = str(c.get_value("profile", "display_name", "Guest")).strip_edges().substr(0, 24)
	if _display_name.is_empty():
		_display_name = "Guest"
	_stage1_starts = maxi(0, int(c.get_value("stats", "stage1_starts", 0)))
	_stage2_starts = maxi(0, int(c.get_value("stats", "stage2_starts", 0)))
	_stage3_starts = maxi(0, int(c.get_value("stats", "stage3_starts", 0)))
	_last_stage = clampi(int(c.get_value("stats", "last_stage", 0)), 0, 3)
	_last_date = str(c.get_value("stats", "last_date", ""))
	_volume = clampf(float(c.get_value("settings", "volume", 0.85)), 0.0, 1.0)
	_muted = bool(c.get_value("settings", "muted", false))

static func _save_data() -> void:
	var c := ConfigFile.new()
	c.set_value("profile", "display_name", _display_name)
	c.set_value("stats", "stage1_starts", _stage1_starts)
	c.set_value("stats", "stage2_starts", _stage2_starts)
	c.set_value("stats", "stage3_starts", _stage3_starts)
	c.set_value("stats", "last_stage", _last_stage)
	c.set_value("stats", "last_date", _last_date)
	c.set_value("settings", "volume", _volume)
	c.set_value("settings", "muted", _muted)
	var err := c.save(SAVE_PATH)
	if err != OK:
		push_warning("Menu-only profile/statistics could not be saved: " + str(err))

static func get_name() -> String:
	_load_data()
	return _display_name

static func set_name(value: String) -> void:
	_load_data()
	_display_name = value.strip_edges().substr(0, 24)
	if _display_name.is_empty():
		_display_name = "Guest"
	_save_data()

static func record_launch(level: int) -> void:
	_load_data()
	match level:
		1:
			_stage1_starts += 1
		2:
			_stage2_starts += 1
		3:
			_stage3_starts += 1
		_:
			return
	_last_stage = level
	_last_date = Time.get_date_string_from_system()
	_save_data()

static func count(level: int) -> int:
	_load_data()
	match level:
		1:
			return _stage1_starts
		2:
			return _stage2_starts
		3:
			return _stage3_starts
	return 0

static func total_count() -> int:
	_load_data()
	return _stage1_starts + _stage2_starts + _stage3_starts

static func last_stage() -> int:
	_load_data()
	return _last_stage

static func last_date() -> String:
	_load_data()
	return _last_date

static func reset_stats() -> void:
	_load_data()
	_stage1_starts = 0
	_stage2_starts = 0
	_stage3_starts = 0
	_last_stage = 0
	_last_date = ""
	_save_data()

static func volume() -> float:
	_load_data()
	return _volume

static func muted() -> bool:
	_load_data()
	return _muted

static func set_volume(value: float) -> void:
	_load_data()
	_volume = clampf(value, 0.0, 1.0)
	_save_data()

static func set_muted(value: bool) -> void:
	_load_data()
	_muted = value
	_save_data()

static func apply_audio() -> void:
	_load_data()
	var db: float = -80.0 if _volume <= 0.001 else linear_to_db(_volume)
	AudioServer.set_bus_volume_db(0, db)
	AudioServer.set_bus_mute(0, _muted)

# Only Stage 1 completion can currently be verified from the existing save data.
# Stage 2 and Stage 3 are intentionally NOT inferred from launch counts.
static func stage1_completed() -> bool:
	var c := ConfigFile.new()
	if c.load("user://sketch_challenge_progress_v8.cfg") != OK:
		return false
	return bool(c.get_value("progress", "stage1_cleared", false))
