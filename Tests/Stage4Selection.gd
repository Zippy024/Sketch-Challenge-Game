extends SceneTree
const P=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
const Catalog=preload("res://Stage4Assets/ProductCatalog.gd")
var game: Control
func _initialize() -> void:call_deferred("run")
func settle() -> void:
	await create_timer(.25).timeout
	await process_frame
func same_frame(rect: Rect2,view: Dictionary,fov: float) -> void:
	assert(game.model.get_global_rect().is_equal_approx(rect),"Product picker must not resize or move 3D")
	assert(game.model.view_state()==view,"Product picker must preserve camera")
	assert(is_equal_approx(game.model.camera.fov,fov),"Product picker must not reframe camera")
	assert(game.find_child("Stage4CustomerCard",true,false).is_visible_in_tree())
	assert(game.find_child("Stage4ReferencePlan",true,false).is_visible_in_tree())
func run() -> void:
	P.reset_progress();P.set_language("en")
	assert(P.is_level_unlocked(4) and not P.is_level_unlocked(5))
	for language in ["en","mm","jp"]:
		P.set_language(language);P.open_stage(4)
		change_scene_to_file("res://stage_4.tscn");await settle();game=current_scene
		assert(game.active==-1 and game.find_child("Stage4CheckAnswer",true,false).disabled)
		assert(game.find_child("Stage4Dialogue",true,false).text=="…")
		assert(Rating.current(4).is_empty() and not P.is_completed(4))
		var rect=game.model.get_global_rect();var view=game.model.view_state();var fov=game.model.camera.fov
		for category in range(4):
			for index in range(5):assert(Catalog.image(category,index)!=null)
			game._cards[category].pressed.emit();await settle()
			assert(game._options.size()==5 and game._picker.visible and not game._main.visible)
			same_frame(rect,view,fov)
			for index in range(5):
				game._options[index].pressed.emit()
				assert(game.model.choices[category]==index and game.choices[category]==0)
				var part=preload("res://Stage4Assets/ProductGeometry.gd").PARTS[category]
				assert(game.model._groups[part].get_child(0).name=="Product_%d_%d"%[category,index])
			game.find_child("Stage4CancelSelection",true,false).pressed.emit();await settle()
			assert(game.model.choices[category]==0 and not game.confirmed[category]);same_frame(rect,view,fov)
			game.open_picker(category);game.preview_selection(4-category);game.find_child("Stage4UseSelection",true,false).pressed.emit();await settle()
			assert(game.choices[category]==4-category and game.confirmed[category]);same_frame(rect,view,fov)
		assert(game._count.text=="4 / 4" and game.find_child("Stage4CheckAnswer",true,false).disabled)
		P._loaded=false
		assert(P.stage4_selection().choices==[4,3,2,1] and P.stage4_selection().confirmed==[true,true,true,true])
		game.find_child("Stage4ZoomIn",true,false).pressed.emit();assert(game.model.zoom<view.zoom)
		game.find_child("Stage4ViewFront",true,false).pressed.emit();assert(is_zero_approx(game.model.yaw))
		game.model.yaw=.51;game.model._update_camera();game._save_session()
		game._open_plan();assert(game.find_child("EnlargedReferencePlan",true,false)!=null)
		game.find_child("CloseReferencePlan",true,false).pressed.emit();await settle()
		game._open_game_menu();assert(paused)
		game._resume_from_game_menu();await settle();assert(not paused)
		game.find_child("GameHomeButton",true,false).pressed.emit();await settle()
		current_scene.find_child("ContinueGame",true,false).pressed.emit();await settle();game=current_scene
		assert(game.name=="Stage4" and game.choices==[4,3,2,1] and is_equal_approx(game.model.yaw,.51))
		game.find_child("GameHomeButton",true,false).pressed.emit();await settle()
		current_scene.call("_show_levels");await settle()
		var board=current_scene.find_child("LevelSelectionScreen",true,false)
		board.find_child("StageCard04",true,false).pressed.emit();await settle()
		board.find_child("SelectedPlayButton",true,false).pressed.emit();await settle();game=current_scene
		assert(game.name=="Stage4" and game.choices==[0,0,0,0] and game.confirmed==[false,false,false,false])
		print("STAGE4_LANGUAGE_OK ",language)
	print("STAGE4_SELECTION_OK: 20 options, preview/cancel/confirm, fixed 3D viewport and camera, independent saved choices, Home/Continue/Play, reference enlargement, no invented dialogue/grading, three languages")
	quit()
