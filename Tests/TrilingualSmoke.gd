extends SceneTree
const Progress = preload("res://GameProgress.gd")
var manager: Node
var report: Dictionary = {}
func _initialize() -> void:call_deferred("_run")
func _wait() -> void:await create_timer(0.25).timeout
func _collect(scene: Node, label: String) -> void:
	var values: Array[String] = []
	for node in scene.find_children("*","Control",true,false):
		if node is Label or node is Button or node is RichTextLabel:
			var value: String = node.text
			if not value.is_empty():values.append(value)
	report[Progress.get_language()+"/"+label]=values
func _run() -> void:
	manager=root.get_node("LocaleManager")
	for language in ["en","mm","jp"]:
		Progress.set_language(language)
		assert(manager.language==language)
		assert(manager.text("SETTINGS")=={"en":"Settings","mm":"ဆက်တင်များ","jp":"設定"}[language])
		assert("Mya" in manager.text("Welcome, Mya"))
		assert("5" in manager.text("Stage 5"))
		change_scene_to_file("res://GameMenu.tscn")
		await _wait()
		var menu=current_scene
		await create_timer(2.2).timeout
		var picker=menu.find_child("LanguageSelectionScreen",true,false)
		assert(picker!=null)
		var options=picker.find_child("LanguageDropdown",true,false)
		assert(not options.is_item_disabled(2))
		options.select({"jp":0,"mm":1,"en":2}[language])
		picker.find_child("LanguageContinue",true,false).pressed.emit()
		await _wait()
		_collect(menu,"home")
		menu.call("_show_levels")
		await _wait()
		var screen=menu.find_child("LevelSelectionScreen",true,false)
		assert(screen!=null)
		var cards=screen.find_children("StageCard*","Button",true,false)
		assert(cards.size()==10)
		for card in cards:assert(card.disabled==(int(card.get_meta("stage"))>3))
		_collect(menu,"levels")
		for page in ["_show_help","_show_settings","_show_profile","_show_progress","_show_achievements","_show_missions"]:
			menu.call(page)
			await _wait()
			_collect(menu,page)
		Progress.launch_from_level_menu=true
		change_scene_to_file("res://main.tscn")
		await _wait()
		var game=current_scene
		assert(game.get("current_lang")==language)
		assert(game.get("canvas")!=null)
		game.call("_stop_voice")
		game.call("_on_voice_finished")
		await _wait()
		_collect(game,"stage1")
		change_scene_to_file("res://stage_2.tscn")
		await _wait()
		game=current_scene
		assert(game.get("current_lang")==language)
		game.call("_stop_voice")
		game.call("_on_voice_finished")
		await _wait()
		_collect(game,"stage2")
		var input=game.get("answer_input")
		input.text="PS means Pipe Space."
		await _wait()
		assert(input.text=="PS means Pipe Space.")
		game.call("_check_demo_answer")
		assert(game.get("last_eval_state")=="needs")
		input.text="PS is a vertical shaft for water supply and drainage pipes and cannot easily be moved during renovation."
		game.call("_check_demo_answer")
		assert(game.get("last_eval_state")=="good")
		await _wait()
		_collect(game,"stage2-correct")
		change_scene_to_file("res://stage_3.tscn")
		await _wait()
		game=current_scene
		assert(game.get("current_lang")==language)
		_collect(game,"stage3-q1")
		game.call("_choose",0)
		assert(game.get("step")==0)
		await _wait()
		_collect(game,"stage3-wrong")
		game.call("_choose",2)
		assert(game.get("step")==1)
		game.call("_choose",1)
		await _wait()
		_collect(game,"stage3-parts")
		for i in range(5):game.call("_select_part",i)
		assert(game.get("step")==7)
		await _wait()
		_collect(game,"stage3-complete")
	var file=FileAccess.open("user://translation-audit.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("TRILINGUAL_SMOKE_OK: three languages across all menu pages and Stage 1/2/3; ten cards, preserved answer validation and player input")
	quit()
