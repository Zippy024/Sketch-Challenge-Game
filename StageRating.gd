extends RefCounted
# A stage attempt gets 1–3 stars; best results persist separately from level unlocks.
const SAVE_PATH := "user://stage_rating_v1.cfg"
const TARGET_SECONDS := {1: 300, 2: 180, 3: 360}
static var sessions: Dictionary = {}
static var latest: Dictionary = {}
static var _loaded: bool=false
static var _config:=ConfigFile.new()
static var _last_saved_msec: int=0
static var _dirty: bool=false
static var _visibility_checked_msec: int=-1000
static var _hidden: bool=false

static func _ensure_loaded() -> void:
	if _loaded:return
	_loaded=true
	_config=ConfigFile.new()
	_config.load(SAVE_PATH)
	sessions.clear()
	latest.clear()
	for stage in TARGET_SECONDS:
		var key: String="stage_%d"%stage
		var attempt: Variant=_config.get_value("attempts",key,{})
		if attempt is Dictionary and attempt.has("elapsed") and attempt.has("mistakes"):
			sessions[stage]={"elapsed":maxf(0,float(attempt.elapsed)),"mistakes":maxi(0,int(attempt.mistakes))}
		var result: Variant=_config.get_value("latest",key,{})
		if result is Dictionary and result.has("stars") and result.has("seconds") and result.has("mistakes"):
			latest[stage]=result

static func begin(stage: int,fresh: bool=false) -> void:
	_ensure_loaded()
	if not TARGET_SECONDS.has(stage):return
	if not fresh and sessions.has(stage):return
	if not fresh and latest.has(stage):return
	sessions[stage]={"elapsed":0.0,"mistakes":0}
	latest.erase(stage)
	_dirty=true
	checkpoint(true)

# Only a running game scene advances this clock. Pause menus and Home do not.
static func advance(stage: int,delta: float) -> void:
	_ensure_loaded()
	if not sessions.has(stage):return
	if OS.has_feature("web"):
		var now:=Time.get_ticks_msec()
		if now-_visibility_checked_msec>=250:
			var was_hidden:=_hidden
			_hidden=bool(JavaScriptBridge.eval("document.hidden",true))
			_visibility_checked_msec=now
			if was_hidden:return
		if _hidden:return
	sessions[stage]["elapsed"]=float(sessions[stage]["elapsed"])+maxf(0,delta)
	_dirty=true
	checkpoint()

static func checkpoint(force: bool=false) -> void:
	_ensure_loaded()
	if not _dirty:return
	if not force and Time.get_ticks_msec()-_last_saved_msec<2000:return
	for stage in TARGET_SECONDS:
		var key: String="stage_%d"%stage
		if sessions.has(stage):_config.set_value("attempts",key,sessions[stage])
		elif _config.has_section_key("attempts",key):_config.erase_section_key("attempts",key)
		if latest.has(stage):_config.set_value("latest",key,latest[stage])
		elif _config.has_section_key("latest",key):_config.erase_section_key("latest",key)
	_config.save(SAVE_PATH)
	_last_saved_msec=Time.get_ticks_msec()
	_dirty=false

static func reset_run(keep_best: bool=true) -> void:
	_ensure_loaded()
	sessions.clear()
	latest.clear()
	for section in ["attempts","latest"]:
		if _config.has_section(section):_config.erase_section(section)
	if not keep_best and _config.has_section("best"):_config.erase_section("best")
	_dirty=true
	checkpoint(true)

static func current(stage: int) -> Dictionary:
	_ensure_loaded()
	return sessions.get(stage,{}).duplicate(true)

static func best(stage: int) -> Dictionary:
	_ensure_loaded()
	return _config.get_value("best","stage_%d"%stage,{}).duplicate(true)

static func mistake(stage: int) -> void:
	_ensure_loaded()
	if not sessions.has(stage): begin(stage)
	if sessions.has(stage):
		var state: Dictionary = sessions[stage]
		state["mistakes"] = int(state["mistakes"]) + 1
		_dirty=true
		checkpoint(true)

static func stars_for(stage: int, elapsed: int, mistakes: int) -> int:
	var target: int = int(TARGET_SECONDS.get(stage, 300))
	if mistakes == 0 and elapsed <= target: return 3
	if mistakes <= 2 and elapsed <= target * 2: return 2
	return 1

static func finish(stage: int) -> Dictionary:
	_ensure_loaded()
	if not sessions.has(stage):
		if latest.has(stage): return latest[stage]
		begin(stage)
	if not sessions.has(stage): return {"stars": 1, "seconds": 0, "mistakes": 0}
	var state: Dictionary = sessions[stage]
	var elapsed: int = maxi(1, ceili(float(state["elapsed"])))
	var errors: int = int(state["mistakes"])
	var result := {"stars": stars_for(stage, elapsed, errors), "seconds": elapsed, "mistakes": errors}
	sessions.erase(stage)
	latest[stage] = result
	_store_best(stage, result)
	_dirty=true
	checkpoint(true)
	return result

static func _store_best(stage: int, result: Dictionary) -> void:
	var key := "stage_%d" % stage
	var old: Dictionary = _config.get_value("best", key, {})
	var improved := old.is_empty() or int(result["stars"]) > int(old.get("stars", 0))
	if not improved and int(result["stars"]) == int(old.get("stars", 0)):
		improved = int(result["seconds"]) < int(old.get("seconds", 999999))
	if improved:
		_config.set_value("best", key, result)
