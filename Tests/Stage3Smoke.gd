extends SceneTree
# Stage 3 functional regression; uses actual Godot scene and user's answer keys.
# Does not change game saved progress.

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	push_error("STAGE3_SMOKE_FAIL: " + reason)
	quit(1)

func _frames() -> void:
	for n in range(7):
		await process_frame

func _run() -> void:
	if change_scene_to_file("res://stage_3.tscn") != OK:
		_fail("unable to load stage_3.tscn")
		return
	await _frames()
	var scene := current_scene
	if scene == null or not scene.has_method("_choose") or not scene.has_method("_select_part"):
		_fail("Stage 3 essential answer functions not found")
		return
	if scene.get("step") != 0:
		_fail("Stage3 did not start at Q1")
		return
	var left: Control
	var right: Control
	for item in scene.find_children("*", "PanelContainer", true, false):
		if item.has_meta("stage3_panel"):
			if item.get_meta("stage3_panel") == "customer":
				left = item
			elif item.get_meta("stage3_panel") == "choices":
				right = item
	if left == null or right == null:
		_fail("missing customer and choice panes")
		return
	if left.size.x < 375 or right.size.x < 500 or left.size.y < 400:
		_fail("Stage3 glass layout collapsed " + str(left.size) + " / " + str(right.size))
		return
	if scene.get("IMAGES_Q1").size() != 5 or scene.get("IMAGES_Q2").size() != 4:
		_fail("Stage3 image assets missing; expected Q1=5 Q2=4")
		return
	scene.call("_choose", 0)
	if scene.get("step") != 0 or scene.get("last_wrong") != true:
		_fail("wrong answer no longer retries at Q1")
		return
	scene.call("_choose", 2)
	await _frames()
	if scene.get("step") != 1:
		_fail("correct Q1 did not advance to Q2")
		return
	scene.call("_choose", 0)
	if scene.get("step") != 1:
		_fail("wrong Q2 did not stay on Q2")
		return
	scene.call("_choose", 1)
	await _frames()
	if scene.get("step") != 2:
		_fail("correct Q2 did not advance to kitchen part selection")
		return
	for index in range(4):
		scene.call("_select_part", index)
		await _frames()
		if scene.get("step") != index + 3:
			_fail("Kitchen part " + str(index) + " did not advance")
			return
	# Do not invoke last part: completion overlay can delay process in smoke tests.
	var names: Array = scene.get_script().get_script_constant_map().get("NAMES", [])
	var expected: Array = ["カウンター", "キッチンボード", "フード", "腰壁", "その他"]
	if names != expected:
		_fail("kitchen component names changed")
		return
	scene.call("_change_lang", "mm")
	await _frames()
	if scene.get("current_lang") != "mm" or scene.get("step") != 6:
		_fail("Myanmar language switch reset gameplay step")
		return
	print("STAGE3_SMOKE_OK: glass layout, 5+4 choice assets, Q1/Q2 retry/advance, 5 part names, JP/MM switching")
	quit(0)
