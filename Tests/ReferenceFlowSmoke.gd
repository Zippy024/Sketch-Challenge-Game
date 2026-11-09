extends SceneTree
const Progress = preload("res://GameProgress.gd")
var shots: String = OS.get_environment("DESIGN_SCREENSHOTS")
func _initialize() -> void:
	call_deferred("_run")
func _frames() -> void:
	for i in range(8): await process_frame
func _capture(file: String) -> void:
	await _frames()
	if not shots.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(shots.path_join(file + ".png"))
func _run() -> void:
	change_scene_to_file("res://GameMenu.tscn")
	await _frames()
	var menu = current_scene
	assert(menu.get("_menu_backdrop").texture.resource_path == "res://Modern Blue-White Kitchen Interior.png")
	await _capture("01-loading")
	menu.call("_show_language")
	await _frames()
	assert(menu.get("_menu_backdrop").texture.resource_path == "res://Sunny Cozy Kitchen Interior.png")
	var language = menu.find_child("LanguageDropdown", true, false)
	assert(language.item_count == 3 and language.is_item_disabled(2))
	await _capture("02-language")
	menu.find_child("LanguageContinueButton", true, false).pressed.emit()
	await _frames()
	assert(menu.find_child("StartGame", true, false) != null)
	await _capture("03-home")
	menu.find_child("SelectLevel", true, false).pressed.emit()
	await _frames()
	assert(menu.get("_chosen_stage") == 3)
	for n in range(1,7):
		var card = menu.find_child("StageCard%02d" % n, true, false)
		assert(card != null and card.disabled == (n > 3))
	await _capture("04-stages")
	menu.call("_choose_stage", 1)
	await _frames()
	assert(current_scene == menu)
	Progress.launch_from_level_menu = true
	change_scene_to_file("res://main.tscn")
	await _frames()
	var game = current_scene
	assert(game.get("ok_button") != null)
	var canvas = game.get("canvas")
	assert(canvas.drawing_enabled)
	canvas.lines.append(PackedVector2Array([Vector2.ZERO, Vector2(1000,0)]))
	game.call("_undo")
	assert(canvas.lines.is_empty())
	game.call("_redo")
	assert(canvas.lines.size() == 1)
	canvas.clear_canvas()
	# Do not seed an answer into the player's board for previews.
	# Stage gameplay and visuals retain their original implementation.
	game.call("_open_game_menu")
	await _frames()
	assert(is_instance_valid(game.get("_pause_menu")))
	game.call("_resume_from_game_menu")
	await _frames()
	assert(canvas.lines.is_empty())
	print("REFERENCE_FLOW_OK: five screens, language, stage locks, drawing undo/redo, pause/resume")
	change_scene_to_file("res://stage_2.tscn")
	await _frames()
	change_scene_to_file("res://stage_3.tscn")
	await _frames()
	assert(current_scene.get("step") == 0)
	var last_scene = current_scene
	current_scene = null
	last_scene.queue_free()
	await _frames()
	quit()
