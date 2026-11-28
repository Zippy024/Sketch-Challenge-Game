extends SceneTree
const P=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
func _initialize() -> void:call_deferred("run")
func settle() -> void:await create_timer(.3).timeout
func header(game: Node) -> Node:
	return game.find_child("Stage1Header",true,false) if game.has_method("_on_again_pressed") else game.find_child("GameHeader",true,false)
func click_tile(h: Node,stage: int) -> void:
	var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
	h.find_child("ReachNode%02d"%stage,true,false).gui_input.emit(event)
func run() -> void:
	P.reset_progress();Rating.begin(1,true);Rating.finish(1);P.complete(1)
	for language in ["en","jp","mm"]:
		P.set_language(language)
		for stage in range(1,5):
			if current_scene and current_scene.has_method("_suspend_session_save"):current_scene.call("_suspend_session_save")
			P.open_stage(stage);P.launch_from_level_menu=stage==1
			change_scene_to_file(P.scene_for_stage(stage));await settle()
			var game=current_scene;var h=header(game)
			assert(h!=null and h.find_child("GameHomeButton",true,false)==null)
			assert(h.find_children("*","MenuButton",true,false).is_empty())
			assert(h.find_child("LanguageCaption",true,false).text=={"en":"English","jp":"Japan","mm":"Myanmar"}[language])
			assert(h.find_child("LanguageFlag",true,false).texture!=null)
			assert(game.find_child("Stage1ResetDrawing",true,false)==null)
			var retry=h.find_child("Stage%dRetry"%stage,true,false)
			var stages=h.find_child("Stage1MenuButton" if stage==1 else "GameMenuButton",true,false)
			var status=h.find_child("GameLanguageStatus",true,false)
			assert(retry.global_position.x<stages.global_position.x and stages.get_global_rect().end.x<status.global_position.x)
			assert(h.find_child("ReachNode01",true,false).size.x<60)
			assert(h.get_global_rect().encloses(retry.get_global_rect()) and h.get_global_rect().encloses(stages.get_global_rect()))
			if stage==1:
				game.canvas.lines.append(PackedVector2Array([Vector2.ZERO,Vector2(100,0)]));game._save_session()
			if stage==2:game.answer_input.text="saved PS draft";game._save_session()
			if stage==4:game.open_picker(0);game.preview_selection(3);game.use_selection()
			var drawing=P.drawing().duplicate(true);var answer=P.answer();var selections=P.stage4_selection().duplicate(true)
			var elapsed=float(Rating.current(stage).get("elapsed",0))
			click_tile(h,stage);await settle()
			var popup=game.find_child("StageCardPicker",true,false)
			assert(paused and popup!=null and popup.selected_stage==stage)
			var panel=popup.find_child("StagePickerPanel",true,false)
			assert(panel.size.is_equal_approx(Vector2(520,560)), "Popup size %s (%s, stage %d), minimum %s"%[panel.size,language,stage,panel.get_combined_minimum_size()])
			assert(panel.position.is_equal_approx(((popup.size-panel.size)*.5).round()))
			assert(game.find_child("LevelSelectionScreen",true,false)==null)
			if stage==2:
				game.answer_input.grab_focus();await process_frame;await process_frame
				assert(popup.is_ancestor_of(root.gui_get_focus_owner()))
			assert(game.find_children("StagePreviewCard","PanelContainer",true,false).size()==1)
			# Decorative rail, crown and check marks must not intercept real clicks.
			var clicked_choice=popup.find_child("StagePopupChoice03",true,false)
			for down in [true,false]:
				var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=clicked_choice.get_global_rect().get_center();root.push_input(event,true);await process_frame
			assert(popup.selected_stage==3)

			for choice in range(1,11):
				popup.find_child("StagePopupChoice%02d"%choice,true,false).pressed.emit();await process_frame
				assert(panel.size.is_equal_approx(Vector2(520,560)), "Popup size %s (%s, stage %d), minimum %s"%[panel.size,language,stage,panel.get_combined_minimum_size()])
				assert(panel.position.is_equal_approx(((popup.size-panel.size)*.5).round()))
				assert(popup.selected_stage==choice and popup.find_child("StageCardTitle",true,false).text==preload("res://KitchenUI.gd").text("Stage %02d")%choice)
				assert(popup.find_child("StageCardStart",true,false).disabled==(choice>4))
				assert(popup.find_child("StageCardStars",true,false).visible==(choice<=3))
				if choice>4:
					popup.find_child("StageCardStart",true,false).pressed.emit()
					assert(current_scene==game and paused)
			popup.find_child("StagePopupChoice01",true,false).pressed.emit()
			assert(popup.find_child("StageCardStars",true,false).get_meta("stars")==int(Rating.best(1).get("stars",0)))
			assert(P.resume_stage()==stage and P.get_language()==language)
			assert(P.drawing()==drawing and P.answer()==answer and P.stage4_selection()==selections)
			await create_timer(.5).timeout
			assert(absf(float(Rating.current(stage).get("elapsed",0))-elapsed)<.1)
			popup.find_child("StagePickerReturn",true,false).pressed.emit();await settle()
			assert(not paused and game.find_child("StageCardPicker",true,false)==null)
			if stage==4:
				retry.pressed.emit();await settle();game=current_scene;h=header(game)
				assert(game.choices==[0,0,0,0] and game.confirmed==[false,false,false,false])
			click_tile(h,2);await settle();popup=game.find_child("StageCardPicker",true,false)
			popup.find_child("StageCardStart",true,false).pressed.emit();await settle()
			assert(not paused and current_scene.get_script().resource_path=="res://Stage2.gd")
			assert(P.get_language()==language and P.resume_stage()==2 and P.answer().is_empty())
			current_scene.answer_input.text="resume me";current_scene._save_session()
			header(current_scene).call("_open_stage_card",1);await settle()
			current_scene.find_child("StagePickerMainMenu",true,false).pressed.emit();await settle()
			assert(not paused and current_scene.find_child("KitchenHomeScreen",true,false)!=null)
			current_scene.find_child("ContinueGame",true,false).pressed.emit();await settle()
			assert(current_scene.get_script().resource_path=="res://Stage2.gd" and current_scene.answer_input.text=="resume me")
	print("HEADER_NAVIGATION_OK: compact tiles, Retry/Stage/read-only flag language, single-card popup, real stars, locked starts, pause/return, saved drafts, fresh start, Stage4 Retry and Home/Continue across three languages")
	quit()
