extends SceneTree
# Automated menu navigation smoke test; no persistent player progress mutated.

func _initialize() -> void:
	call_deferred("_run")

func _failure(reason: String) -> void:
	push_error("MENU_SMOKE_FAIL: " + reason)
	quit(1)

func _wait_frames() -> void:
	for i in range(5):
		await process_frame

func _run() -> void:
	if change_scene_to_file("res://GameMenu.tscn") != OK:
		_failure("could not load GameMenu")
		return
	await _wait_frames()
	var menu := current_scene
	if menu == null or not menu.has_method("_show_home"):
		_failure("missing game menu scene")
		return
	if menu.size.x < 800.0 or menu.size.y < 450.0:
		_failure("menu viewport is unexpectedly small: " + str(menu.size))
		return
	menu.call("_show_home")
	await _wait_frames()
	var body := menu.get("_body") as VBoxContainer
	if body == null or body.get_child_count() < 1 or body.size.x < 500.0:
		_failure("home scene collapsed")
		return
	var top := menu.get("_top_bar") as Control
	if top == null or top.size.y > 110.0 or top.size.y < 40.0:
		_failure("header size collapsed or stretched: " + str(top.size) + " viewport " + str(menu.size))
		return
	menu.call("_show_levels")
	await _wait_frames()
	var stages: Array[Button] = []
	for n in menu.find_children("*", "Button", true, false):
		var b := n as Button
		if b.has_meta("mission_stage"):
			stages.append(b)
	if stages.size() != 6:
		_failure("expected six stage cards, got " + str(stages.size()))
		return
	for b in stages:
		var stage: int = int(b.get_meta("mission_stage"))
		if b.disabled != (stage >= 4):
			_failure("stage access changed: " + str(stage))
			return
	if body.size.x < 500.0 or top.size.y > 110.0:
		_failure("level selection layout collapsed")
		return
	menu.call("_show_language_select")
	await _wait_frames()
	if body.get_child_count() == 0:
		_failure("language page failed to render")
		return
	print("MENU_SMOKE_OK: home, levels, stage access, language; viewport " + str(menu.size))
	quit(0)
