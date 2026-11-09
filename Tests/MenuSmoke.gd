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
	var fresh_backgrounds := 0
	var old_backgrounds := 0
	for node in menu.find_children("*", "TextureRect", true, false):
		var image := node as TextureRect
		if image.texture == null:
			continue
		var path := image.texture.resource_path
		if "BlueKitchenFreshV1.svg" in path:
			fresh_backgrounds += 1
		if "KitchenIntroV8.jpg" in path or "KitchenHero.jpg" in path or "ConceptC_Home_Background.jpg" in path:
			old_backgrounds += 1
	if fresh_backgrounds != 1 or old_backgrounds != 0:
		_failure("Expected exactly ONE fresh blue kitchen background, not reused/stacked photos: fresh=%d old=%d" % [fresh_backgrounds, old_backgrounds])
		return
	var home_canvas: Control
	var hero: Control
	var main_headline: Control
	var start_button: Control
	var features_panel: Control
	for node in menu.find_children("*", "Control", true, false):
		if node.name == "OptionCHomeCanvas":
			home_canvas = node
		if node.has_meta("home_hero_panel"):
			hero = node
		if node.has_meta("home_headline"):
			main_headline = node
		if node.has_meta("home_start_button"):
			start_button = node
		if node.name == "HomeFeaturesGlass":
			features_panel = node
	if home_canvas == null or hero == null or main_headline == null or start_button == null or features_panel == null:
		_failure("Option C hero, headline, button or feature panel missing")
		return
	if hero.size.x < 500.0 or hero.size.y < 480.0:
		_failure("Home glass panel collapsed: " + str(hero.size))
		return
	if main_headline.size.x < 300 or start_button.size.x < 350:
		_failure("Home text/button width collapsed")
		return
	if features_panel.size.x < 250 or features_panel.size.y < 140:
		_failure("Feature cards collapsed to vertical letters: " + str(features_panel.size))
		return
	if hero.global_position.y < 0 or hero.global_position.y > 150:
		_failure("Home hero is outside viewport " + str(hero.global_position))
		return
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
	var showroom_cards := 0
	var selected_play: Button
	var selected_card: Button
	for node in menu.find_children("*", "Button", true, false):
		if node.has_meta("showroom_stage_card"):
			showroom_cards += 1
			if int(node.get_meta("mission_stage")) == 3:
				selected_card = node
		if node.has_meta("mission_play"):
			selected_play = node
	if showroom_cards != 6 or selected_card == null or selected_play == null:
		_failure("Missing six picture-card stages or selected Stage Play button")
		return
	if selected_card.size.x < 185 or selected_card.size.y < 320:
		_failure("Highlighted Stage 03 card must be larger than other cards")
		return
	if selected_play.size.x < 150.0 or selected_play.size.y < 40.0:
		_failure("Play button too narrow / missing")
		return
	var pedestal: Control
	var detail: Control
	for node in menu.find_children("*","Control",true,false):
		if node.has_meta("showroom_pedestal"):
			pedestal = node
		if node.has_meta("mission_detail"):
			detail = node
	if pedestal == null or detail == null or pedestal.size.x < 1000.0 or detail.size.x < 950.0:
		_failure("Neon showroom floor or bottom mission track missing")
		return
	if body.size.x < 500.0:
		_failure("showroom level selection collapsed")
		return
	menu.call("_select_map_stage", 2)
	await _wait_frames()
	if menu.get("_selected_level") != 2:
		_failure("Stage 02 cannot be chosen")
		return
	menu.call("_select_map_stage", 3)
	await _wait_frames()
	if menu.get("_selected_level") != 3:
		_failure("Stage 03 cannot be chosen")
		return
	# Selecting cards must never enter gameplay until pressing PLAY.
	if current_scene != menu:
		_failure("Selecting a stage accidentally launched gameplay")
		return
	# All entry screens use the outermost background: no inset second photo.
	for node in menu.find_children("*", "TextureRect", true, false):
		if node.texture != null and "KitchenIntroV8.jpg" in node.texture.resource_path:
			_failure("Old photo reappeared inside stage selection")
			return
	menu.call("_show_splash")
	await _wait_frames()
	var intro_art: Control
	var intro_bar: ProgressBar
	for node in menu.find_children("*", "Control", true, false):
		if node.has_meta("entry_kitchen_art"):
			intro_art = node
		if node.name == "EntryLoadingProgress":
			intro_bar = node
	if intro_art == null or intro_bar == null or intro_art.size.x < 700 or intro_bar.size.x < 350:
		_failure("Intro drawing or loading bar missing/collapsed")
		return
	if top.visible:
		_failure("intro unexpectedly shows game navigation header")
		return
	menu.call("_show_language_select")
	await _wait_frames()
	var dropdown: OptionButton
	var dropdown_panel: Control
	var continue_btn: Button
	for node in menu.find_children("*", "Control", true, false):
		if node.has_meta("entry_language_dropdown"):
			dropdown = node
		if node.has_meta("entry_language_panel"):
			dropdown_panel = node
		if node.has_meta("entry_language_continue"):
			continue_btn = node
	if dropdown == null or dropdown_panel == null or continue_btn == null:
		_failure("language dropdown, panel or continue control missing")
		return
	if dropdown.item_count != 3 or not dropdown.is_item_disabled(2):
		_failure("expected Japanese, Myanmar and honest English-coming-soon option")
		return
	var entry_photo_count := 0
	for node in menu.find_children("*", "TextureRect", true, false):
		var img := node as TextureRect
		if img.texture != null and "BlueKitchenFreshV1.svg" in img.texture.resource_path:
			entry_photo_count += 1
	if entry_photo_count != 1:
		_failure("Language page reintroduced duplicate/inset background")
		return
	if dropdown_panel.size.x < 290 or continue_btn.size.x < 245:
		_failure("language layout collapsed")
		return
	if body.get_child_count() == 0:
		_failure("language page failed to render")
		return
	menu.call("_choose_language", "jp")
	await _wait_frames()
	if top.visible:
		_failure("reference main menu should show its own minimal layout, not the game HUD")
		return
	var found_home := false
	for node in menu.find_children("*", "Control", true, false):
		if node.name == "OptionCHomeCanvas":
			found_home = true
	if not found_home:
		_failure("language confirmation skipped the required Main Menu")
		return
	print("MENU_SMOKE_OK: single new blue kitchen background across screens; no old photos, six stage cards, language, locked stages")
	quit(0)
