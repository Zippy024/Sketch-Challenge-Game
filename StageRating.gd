extends RefCounted
# A stage attempt gets 1–3 stars; best results persist separately from level unlocks.
const SAVE_PATH := "user://stage_rating_v1.cfg"
const TARGET_SECONDS := {1: 300, 2: 180, 3: 360}
static var sessions: Dictionary = {}
static var latest: Dictionary = {}

static func begin(stage: int) -> void:
	if TARGET_SECONDS.has(stage):
		sessions[stage] = {"started": Time.get_ticks_msec(), "mistakes": 0}

static func mistake(stage: int) -> void:
	if not sessions.has(stage): begin(stage)
	if sessions.has(stage):
		var state: Dictionary = sessions[stage]
		state["mistakes"] = int(state["mistakes"]) + 1

static func stars_for(stage: int, elapsed: int, mistakes: int) -> int:
	var target: int = int(TARGET_SECONDS.get(stage, 300))
	if mistakes == 0 and elapsed <= target: return 3
	if mistakes <= 2 and elapsed <= target * 2: return 2
	return 1

static func finish(stage: int) -> Dictionary:
	if not sessions.has(stage):
		if latest.has(stage): return latest[stage]
		begin(stage)
	if not sessions.has(stage): return {"stars": 1, "seconds": 0, "mistakes": 0}
	var state: Dictionary = sessions[stage]
	var elapsed: int = maxi(1, ceili(float(Time.get_ticks_msec() - int(state["started"])) / 1000.0))
	var errors: int = int(state["mistakes"])
	var result := {"stars": stars_for(stage, elapsed, errors), "seconds": elapsed, "mistakes": errors}
	sessions.erase(stage)
	latest[stage] = result
	_store_best(stage, result)
	return result

static func _store_best(stage: int, result: Dictionary) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	var key := "stage_%d" % stage
	var old: Dictionary = config.get_value("best", key, {})
	var improved := old.is_empty() or int(result["stars"]) > int(old.get("stars", 0))
	if not improved and int(result["stars"]) == int(old.get("stars", 0)):
		improved = int(result["seconds"]) < int(old.get("seconds", 999999))
	if improved:
		config.set_value("best", key, result)
		config.save(SAVE_PATH)
