extends SceneTree
const Progress=preload("res://GameProgress.gd")
func _initialize() -> void:call_deferred("_run")
func _wait(seconds: float=0.25) -> void:await create_timer(seconds).timeout
func _finish_response(game: Node) -> void:
	var voice: AudioStreamPlayer=game.get("voice_player")
	if voice.stream!=null and voice.playing:
		assert(voice.stream.get_length()>0.2)
		voice.seek(voice.stream.get_length()-0.08)
		await _wait(1.0)
	else:
		# Retain a readable fallback if a future recording is unavailable.
		await _wait(3.7)
func _run() -> void:
	for lang in ["en","mm","jp"]:
		Progress.start_new_game()
		Progress.set_language(lang)
		Progress.launch_from_level_menu=true
		change_scene_to_file("res://main.tscn")
		await _wait()
		var game=current_scene
		if lang=="en":
			for kind in ["talk","wrong","correct"]:
				assert(ResourceLoader.exists(game.call("_voice_path",kind)))
		game.call("_stop_voice")
		game.call("_on_voice_finished")
		var drawing=game.get("canvas")
		var vertices=[Vector2(0,0),Vector2(7380,0),Vector2(7380,2360),Vector2(7680,2360),Vector2(7680,3400),Vector2(0,3400)]
		for i in range(6):drawing.lines.append(PackedVector2Array([vertices[i],vertices[(i+1)%6]]))
		game.call("_confirm")
		await _wait(0.2)
		assert(game.get("last_eval_state")=="correct")
		assert(game.find_child("Stage1CompleteOverlay",true,false)==null)
		if lang=="en":
			game.call("_open_game_menu")
			await _wait(0.45)
			assert(paused and game.find_child("Stage1CompleteOverlay",true,false)==null)
			var menu=game.get("_pause_menu")
			menu.find_child("LevelsMainMenu",true,false).pressed.emit()
			await _wait()
			assert(menu.find_child("KitchenHomeScreen",true,false)!=null)
			menu.find_child("ContinueGame",true,false).pressed.emit()
			await _wait()
			assert(not paused and current_scene==game)
		await _finish_response(game)
		assert(game.get("feedback_label").text==game.get_script().get_script_constant_map()["DIALOGUE_TEXTS"][lang]["correct"])
		assert(game.find_children("Stage1CompleteOverlay","Control",true,false).size()==1)
		game.call("_on_voice_finished")
		await _wait(0.4)
		assert(game.find_children("Stage1CompleteOverlay","Control",true,false).size()==1)
		Progress.open_stage(2)
		change_scene_to_file("res://stage_2.tscn")
		await _wait()
		game=current_scene
		if lang=="en":
			for kind in ["question","needs","good"]:
				assert(ResourceLoader.exists(game.call("_voice_path",kind)))
		game.get("answer_input").text="PS is a vertical shaft for water supply and drainage pipes and cannot easily be moved during renovation."
		game.call("_check_demo_answer")
		await _wait(0.2)
		assert(game.get("last_eval_state")=="good")
		assert(game.find_child("Stage2CompleteOverlay",true,false)==null)
		assert(not game.find_child("ContinueStage3",true,false).is_visible_in_tree())
		await _finish_response(game)
		assert(game.get("feedback_label").text==str(game.get_script().get_script_constant_map()["QUESTIONS"][lang]["good"]))
		assert(game.find_children("Stage2CompleteOverlay","Control",true,false).size()==1)
		assert(game.find_child("ContinueStage3",true,false).is_visible_in_tree())
		game.call("_on_voice_finished")
		await _wait(0.4)
		assert(game.find_children("Stage2CompleteOverlay","Control",true,false).size()==1)
	# Reset during the short post-dialogue pause must cancel the pending popup.
	Progress.open_stage(2)
	change_scene_to_file("res://stage_2.tscn")
	await _wait()
	var stage=current_scene
	stage.get("answer_input").text="PS is a vertical shaft for water supply and drainage pipes and cannot easily be moved during renovation."
	stage.call("_check_demo_answer")
	var player: AudioStreamPlayer=stage.get("voice_player")
	assert(player.stream!=null and player.playing)
	player.seek(player.stream.get_length()-0.08)
	await _wait(0.18)
	stage.call("_reset_answer")
	await _wait(0.6)
	assert(stage.find_child("Stage2CompleteOverlay",true,false)==null and stage.get("last_eval_state")=="none")
	print("COMPLETION_TIMING_OK: recorded audio and caption fallback in three languages, pause/home/continue, single popup and cancelled reset")
	quit()
