extends RefCounted
const Rating=preload("res://StageRating.gd")
const Parts=preload("res://Stage3Assets/Model/JapaneseParts.gd")
# Shared language and level progress. Works in desktop builds and in Web user:// storage.
const SAVE_PATH := "user://sketch_challenge_progress_v8.cfg"
static var _loaded: bool = false
static var _stage1_cleared: bool = false
static var _stage2_cleared: bool = false
static var _stage3_cleared: bool = false
static var _resume_stage: int = 0
static var _stage1_draft: Array[PackedVector2Array] = []
static var _stage1_zoom: float = 1.0
static var _stage1_pan := Vector2(72,60)
static var _stage2_draft: String = ""
static var _stage3_step: int = 0
static var _stage3_answers: Array[String]=["","","","","","","",""]
static var _stage3_solved: Array[bool]=[false,false,false,false,false,false,false,false]
static var _language: String = "jp"
static var show_levels_on_open: bool = false
static var show_home_on_open: bool = false
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
		_resume_stage = int(config.get_value("session","stage",0))
		_stage1_draft.clear()
		for segment in config.get_value("session","drawing",[]):
			if segment is PackedVector2Array and segment.size()==2: _stage1_draft.append(segment)
		_stage1_zoom = clampf(float(config.get_value("session","zoom",1.0)),0.1,8.0)
		_stage1_pan = config.get_value("session","pan",Vector2(72,60))
		_stage2_draft = str(config.get_value("session","answer",""))
		_stage3_step = clampi(int(config.get_value("session","step",0)),0,Parts.CHALLENGE_STEPS)
		_reset_kitchen_parts()
		var version: int=int(config.get_value("session","parts_version",0))
		if version in [1,2]:
			var answers: Variant=config.get_value("session","parts_answers",[])
			var solved: Variant=config.get_value("session","parts_solved",[])
			if answers is Array and solved is Array and answers.size()==solved.size() and answers.size() in [5,Parts.COUNT]:
				for i in range(mini(answers.size(),Parts.COUNT)):
					_stage3_answers[i]=str(answers[i])
					_stage3_solved[i]=bool(solved[i])
		else:
			# Preserve progress from the former sequential picture-selection challenge.
			var names: Array[String]=Parts.NAMES
			for i in range(clampi(_stage3_step-2,0,5)):
				_stage3_answers[i]=names[i]
				_stage3_solved[i]=true
		# Completed old attempts retain their results; partial attempts keep verified answers.
		if version<2 and _stage3_cleared and _stage3_step==7:
			_stage3_step=Parts.CHALLENGE_STEPS
		elif _stage3_step>=2 and _stage3_step<Parts.CHALLENGE_STEPS:
			_stage3_step=2+_stage3_solved.count(true)
		# Existing verified saves remain resumable after this update.
		if _resume_stage==0 and (_stage1_cleared or _stage2_cleared or _stage3_cleared):
			_resume_stage = next_stage()
			if _stage3_cleared and completed_count()==3: _stage3_step=Parts.CHALLENGE_STEPS

static func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "stage1_cleared", _stage1_cleared)
	config.set_value("progress", "stage2_cleared", _stage2_cleared)
	config.set_value("progress", "stage3_cleared", _stage3_cleared)
	config.set_value("settings", "language", _language)
	config.set_value("session","stage",_resume_stage)
	config.set_value("session","drawing",_stage1_draft)
	config.set_value("session","zoom",_stage1_zoom)
	config.set_value("session","pan",_stage1_pan)
	config.set_value("session","answer",_stage2_draft)
	config.set_value("session","step",_stage3_step)
	config.set_value("session","parts_version",2)
	config.set_value("session","parts_answers",_stage3_answers)
	config.set_value("session","parts_solved",_stage3_solved)
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
	if level==2: complete(1)

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
	_resume_stage = mini(stage+1,3)
	if stage==1:
		_stage1_draft.clear()
		_stage2_draft=""
	if stage==2:
		_stage2_draft=""
		_stage3_step=0
		_reset_kitchen_parts()
	if stage==3: _stage3_step=Parts.CHALLENGE_STEPS
	_save()

static func completed_count() -> int:
	_ensure_loaded()
	return int(_stage1_cleared)+int(_stage2_cleared)+int(_stage3_cleared)

static func next_stage() -> int:
	for stage in range(1,4):
		if not is_completed(stage): return stage
	return 3

# Testing option: reset level unlocks, keeping the chosen language.
static func reset_progress(keep_best_scores: bool=false) -> void:
	_ensure_loaded()
	Rating.reset_run(keep_best_scores)
	_stage1_cleared = false
	_stage2_cleared = false
	_stage3_cleared = false
	_resume_stage = 0
	_stage1_draft.clear()
	_stage1_zoom=1.0
	_stage1_pan=Vector2(72,60)
	_stage2_draft=""
	_stage3_step=0
	_reset_kitchen_parts()
	_save()

static func has_session() -> bool:
	_ensure_loaded()
	return _resume_stage in [1,2,3]

static func resume_stage() -> int:
	_ensure_loaded()
	return _resume_stage

static func start_new_game() -> void:
	reset_progress(true)
	open_stage(1)

static func open_stage(stage: int, resume: bool = false) -> void:
	_ensure_loaded()
	if stage not in [1,2,3]: return
	_resume_stage=stage
	if not resume:
		Rating.begin(stage,true)
		if stage==1:
			_stage1_draft.clear()
			_stage1_zoom=1.0
			_stage1_pan=Vector2(72,60)
		if stage==2: _stage2_draft=""
		if stage==3:
			_stage3_step=0
			_reset_kitchen_parts()
	_save()

static func save_drawing(lines: Array, zoom: float, pan: Vector2) -> void:
	_ensure_loaded()
	if _stage1_draft==lines and is_equal_approx(zoom,_stage1_zoom) and pan==_stage1_pan: return
	_stage1_draft.clear()
	for segment in lines: _stage1_draft.append(PackedVector2Array(segment))
	_stage1_zoom=zoom
	_stage1_pan=pan
	_save()

static func drawing() -> Array[PackedVector2Array]:
	_ensure_loaded()
	return _stage1_draft.duplicate(true)

static func drawing_view() -> Dictionary:
	_ensure_loaded()
	return {"zoom":_stage1_zoom,"pan":_stage1_pan}

static func save_answer(answer: String) -> void:
	_ensure_loaded()
	if _stage2_draft==answer: return
	_stage2_draft=answer
	_save()

static func answer() -> String:
	_ensure_loaded()
	return _stage2_draft

static func save_kitchen_step(step: int) -> void:
	_ensure_loaded()
	if _stage3_step==step: return
	_stage3_step=clampi(step,0,Parts.CHALLENGE_STEPS)
	_save()

static func kitchen_step() -> int:
	_ensure_loaded()
	return _stage3_step

static func _reset_kitchen_parts() -> void:
	_stage3_answers.assign(["","","","","","","",""])
	_stage3_solved.assign([false,false,false,false,false,false,false,false])

static func kitchen_parts() -> Dictionary:
	_ensure_loaded()
	return {"answers":_stage3_answers.duplicate(),"solved":_stage3_solved.duplicate()}

static func save_kitchen_parts(answers: Array[String], solved: Array[bool]) -> void:
	_ensure_loaded()
	if answers.size()!=Parts.COUNT or solved.size()!=Parts.COUNT:return
	if _stage3_answers==answers and _stage3_solved==solved:return
	_stage3_answers=answers.duplicate()
	_stage3_solved=solved.duplicate()
	if _stage3_step>=2:_stage3_step=2+_stage3_solved.count(true)
	_save()
