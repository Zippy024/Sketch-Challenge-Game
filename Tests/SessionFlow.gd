extends SceneTree
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
func _initialize() -> void: call_deferred("_run")
func _wait() -> void: await create_timer(0.3).timeout
func _home() -> Control:
	var direct_home=current_scene.find_child("GameHomeButton",true,false) if current_scene else null
	if direct_home!=null:
		direct_home.pressed.emit()
		await _wait()
		assert(not paused and current_scene.find_child("LanguageSelectionScreen",true,false)==null)
		var saved_home=current_scene.find_child("KitchenHomeScreen",true,false)
		assert(saved_home!=null)
		return saved_home
	Progress.show_levels_on_open=true
	change_scene_to_file("res://GameMenu.tscn")
	await _wait()
	current_scene.call("_show_home")
	await _wait()
	return current_scene.find_child("KitchenHomeScreen",true,false)
func _run() -> void:
	Progress.reset_progress()
	Progress.set_language("en")
	var home=await _home()
	assert(home.find_child("ContinueGame",true,false).disabled)
	home.find_child("StartGame",true,false).pressed.emit()
	await _wait()
	var game=current_scene
	assert(Progress.resume_stage()==1 and Progress.completed_count()==0)
	var canvas=game.get("canvas")
	canvas.lines.append(PackedVector2Array([Vector2.ZERO,Vector2(1000,0)]))
	canvas.lines.append(PackedVector2Array([Vector2(1000,0),Vector2(1000,500)]))
	canvas.zoom_level=1.5
	canvas.pan=Vector2(88,97)
	game.call("_save_session")
	Rating.advance(1,125)
	Rating.mistake(1)
	Rating.checkpoint(true)
	Rating._loaded=false
	assert(float(Rating.current(1).elapsed)>=125 and int(Rating.current(1).mistakes)==1)
	Progress._loaded=false
	assert(Progress.drawing().size()==2 and Progress.drawing_view().pan==Vector2(88,97))
	# Continue in the pause menu resumes the same live game.
	var before_pause: float=float(Rating.current(1).elapsed)
	game.call("_open_game_menu")
	assert(paused)
	await _wait()
	Rating._loaded=false
	assert(absf(float(Rating.current(1).elapsed)-before_pause)<0.05)
	var overlay=game.get("_pause_menu")
	var levels_home=overlay.find_child("LevelsMainMenu",true,false)
	assert(levels_home!=null)
	levels_home.pressed.emit()
	await _wait()
	overlay.find_child("ContinueGame",true,false).pressed.emit()
	await _wait()
	assert(not paused and current_scene==game and canvas.lines.size()==2)
	# Continue after returning home restores the exact saved geometry and view.
	home=await _home()
	assert(not home.find_child("ContinueGame",true,false).disabled)
	home.find_child("ContinueGame",true,false).pressed.emit()
	await _wait()
	game=current_scene
	canvas=game.get("canvas")
	assert(canvas.lines.size()==2 and is_equal_approx(canvas.zoom_level,1.5) and canvas.pan==Vector2(88,97))
	assert(float(Rating.current(1).elapsed)>=125 and int(Rating.current(1).mistakes)==1)
	# Start Game from a paused scene discards its draft before the old scene exits.
	game.call("_open_game_menu")
	overlay=game.get("_pause_menu")
	overlay.call("_show_home")
	await _wait()
	overlay.find_child("StartGame",true,false).pressed.emit()
	await _wait()
	assert(not paused and current_scene.get("canvas").lines.is_empty() and Progress.drawing().is_empty())
	Progress.open_stage(2)
	change_scene_to_file("res://stage_2.tscn")
	await _wait()
	var draft="My answer: PS — လိုင်း ၁\nDo not translate player input."
	current_scene.get("answer_input").text=draft
	Rating.advance(2,77)
	Rating.mistake(2)
	current_scene.get("answer_input").text_changed.emit()
	await _wait()
	Progress._loaded=false
	assert(Progress.answer()==draft)
	home=await _home()
	home.find_child("ContinueGame",true,false).pressed.emit()
	await _wait()
	assert(current_scene.get("answer_input").text==draft and Progress.resume_stage()==2)
	assert(float(Rating.current(2).elapsed)>=77 and int(Rating.current(2).mistakes)==1)
	Progress.open_stage(3)
	change_scene_to_file("res://stage_3.tscn")
	await _wait()
	Rating.advance(3,14)
	current_scene.call("_choose",0)
	current_scene.call("_choose",2)
	current_scene.call("_choose",1)
	current_scene.call("_select_part",0)
	assert(current_scene.get("step")==3)
	Progress._loaded=false
	assert(Progress.kitchen_step()==3)
	home=await _home()
	home.find_child("ContinueGame",true,false).pressed.emit()
	await _wait()
	assert(current_scene.get("step")==3 and current_scene.find_child("KitchenPartsDiagram",true,false)!=null)
	assert(float(Rating.current(3).elapsed)>=14 and int(Rating.current(3).mistakes)==1)
	Progress.complete(1)
	Progress.complete(2)
	home=await _home()
	home.find_child("StartGame",true,false).pressed.emit()
	await _wait()
	assert(Progress.completed_count()==0 and Progress.resume_stage()==1 and current_scene.get("canvas").lines.is_empty())
	for stage in range(1,4):await _check_retry(stage)
	# Replaying an earlier stage must start a fresh attempt in the following stage.
	Progress.open_stage(2)
	change_scene_to_file("res://stage_2.tscn")
	await _wait()
	await _win(2)
	current_scene.find_child("CompletionNext",true,false).pressed.emit()
	await _wait()
	assert(current_scene.get("step")==0 and not Rating.current(3).is_empty())
	assert(int(Rating.current(3).mistakes)==0 and float(Rating.current(3).elapsed)<2)
	assert(int(Rating.best(3).stars)==3)
	print("SESSION_FLOW_OK: fresh start, saved inputs and active timers, pause exclusion, three-stage Retry, persisted mistakes and best stars")
	quit()

func _win(stage: int) -> void:
	var game=current_scene
	if stage==1:
		game.call("_stop_voice")
		game.call("_on_voice_finished")
		var points=[Vector2(0,0),Vector2(7380,0),Vector2(7380,2360),Vector2(7680,2360),Vector2(7680,3400),Vector2(0,3400)]
		var canvas=game.get("canvas")
		canvas.lines.clear()
		for i in range(6):canvas.lines.append(PackedVector2Array([points[i],points[(i+1)%6]]))
		game.call("_confirm")
	elif stage==2:
		game.get("answer_input").text="PS is a vertical shaft for water supply and drainage pipes and cannot easily be moved during renovation."
		game.call("_check_demo_answer")
	else:
		game.call("_choose",2)
		game.call("_choose",1)
		for i in range(5):game.call("_select_part",i)
	if stage<3:
		game.call("_stop_voice")
		game.call("_on_voice_finished")
	await create_timer(0.5).timeout

func _check_retry(stage: int) -> void:
	var scene=["res://main.tscn","res://stage_2.tscn","res://stage_3.tscn"][stage-1]
	Progress.open_stage(stage)
	Progress.launch_from_level_menu=true
	change_scene_to_file(scene)
	await _wait()
	Rating.advance(stage,float(Rating.TARGET_SECONDS[stage])-10.0)
	await _win(stage)
	var popup=current_scene.find_child("Stage%dCompleteOverlay"%stage,true,false)
	assert(popup!=null and int(Rating.latest[stage].stars)==3)
	var frozen: Dictionary=Rating.latest[stage].duplicate(true)
	await _wait()
	assert(Rating.latest[stage]==frozen)
	popup.find_child("CompletionRetry",true,false).pressed.emit()
	await _wait()
	assert(Progress.resume_stage()==stage and Progress.is_completed(stage))
	assert(float(Rating.current(stage).elapsed)<2 and int(Rating.current(stage).mistakes)==0)
	assert(int(Rating.best(stage).stars)==3)
	if stage==1:assert(current_scene.get("canvas").lines.is_empty())
	if stage==2:assert(current_scene.get("answer_input").text.is_empty())
	if stage==3:assert(current_scene.get("step")==0)
	for i in range(3):Rating.mistake(stage)
	await _win(stage)
	assert(int(Rating.latest[stage].stars)==1 and int(Rating.best(stage).stars)==3)
	Rating._loaded=false
	assert(int(Rating.best(stage).stars)==3)
