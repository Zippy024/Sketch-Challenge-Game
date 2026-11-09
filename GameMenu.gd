extends Control
# Reference-matched blue/cyan desktop UI. Stage 1/2/3 logic remains in original files.
# All selectable cards and controls are native Godot UI, not screenshots.
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")
const Extras = preload("res://MenuExtras.gd")

const BG := Color("d4edff")
const WHITE := Color("ffffff")
const INK := Color("103960")
const MUTED := Color("537a9a")
const GREEN := Color("06a9d0") # original constant name, cyan UI only
const GREEN_DARK := Color("07699b")
const GREEN_PALE := Color("d9f4ff")
const BORDER := Color("9cd8f5")
const GOLD := Color("ffd171")
const LOCKED := Color("8399ae")

var is_pause_overlay: bool = false
var pause_level: int = 0
var _body: VBoxContainer
var _jp_button: Button
var _mm_button: Button
var _scroll: ScrollContainer
var _top: Control
var _bottom: Control
var _volume_value: float = 0.85
var _reset_armed: bool = false
var _stats_reset_armed: bool = false
var _chosen_stage: int = 1
var _loading_tween: Tween
var _menu_backdrop: TextureRect


func _ready() -> void:
	theme = BilingualTheme
	_volume_value = Extras.volume()
	Extras.apply_audio()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame()
	resized.connect(_fit_content)
	_fit_content()
	if is_pause_overlay or Progress.show_levels_on_open:
		Progress.show_levels_on_open = false
		_show_levels()
	else:
		if OS.has_feature("web"):
			_show_language() # HTML shell already displayed the loading sequence.
		else:
			_show_loading()


func _style(bg: Color, edge: Color = BORDER, radius: int = 16, padding: int = 0) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = edge
	st.set_border_width_all(2)
	st.set_corner_radius_all(radius)
	st.set_content_margin_all(padding)
	return st


func _raised(bg: Color, edge: Color = BORDER, radius: int = 18) -> StyleBoxFlat:
	var st := _style(bg, edge, radius)
	st.shadow_color = Color(0.04, 0.19, 0.37, 0.19)
	st.shadow_size = 10
	st.shadow_offset = Vector2(0, 6)
	return st


func _label(value: String, font_size: int = 16, color: Color = INK, centered: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = value
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _button(title: String, primary: bool = false, min_w: float = 165.0, min_h: float = 46.0) -> Button:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(min_w, min_h)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", WHITE if primary else INK)
	btn.add_theme_color_override("font_hover_color", WHITE if primary else GREEN_DARK)
	btn.add_theme_color_override("font_pressed_color", WHITE if primary else GREEN_DARK)
	btn.add_theme_color_override("font_disabled_color", Color("e8edf3"))
	btn.add_theme_stylebox_override("normal", _raised(Color("079fc4") if primary else Color("eefaff"), Color("76edfc") if primary else Color("b9d9ef"), 24))
	btn.add_theme_stylebox_override("hover", _raised(Color("05c3e0") if primary else Color("d2f5ff"), Color("c7fcff"), 24))
	btn.add_theme_stylebox_override("pressed", _style(Color("0878a6") if primary else Color("c4eaff"), Color("62c5e6"), 24))
	btn.add_theme_stylebox_override("disabled", _style(Color("7e91a4"), Color("a5bbcc"), 24))
	btn.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("4cdaff"), 24))
	return btn


func _place(parent: Control, child: Control, area: Rect2) -> void:
	parent.add_child(child)
	child.position = area.position
	child.size = area.size


func _panel(parent: Control, area: Rect2, fill: Color, outline: Color = BORDER, radius: int = 20) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _raised(fill, outline, radius))
	_place(parent, panel, area)
	return panel


func _text(parent: Control, words: String, size_px: int, area: Rect2, color: Color = INK, centered: bool = false) -> Label:
	var lbl := _label(words, size_px, color, centered)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place(parent, lbl, area)
	return lbl


func _image(parent: Control, image: Texture2D, area: Rect2, cover: bool = false) -> TextureRect:
	var pic := TextureRect.new()
	pic.texture = image
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_place(parent, pic, area)
	return pic


func _build_frame() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://MenuAssets/LoadingBackground.png")
	_menu_backdrop = backdrop
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash := ColorRect.new()
	wash.color = Color(0.88, 0.96, 1.0, 0.14)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wash)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	root.add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top = PanelContainer.new()
	_top.custom_minimum_size.y = 59
	_top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_top.add_theme_stylebox_override("panel", _style(Color("e9f8ff"), Color("8edcf7"), 0, 0))
	outer.add_child(_top)
	var head_margin := MarginContainer.new()
	head_margin.add_theme_constant_override("margin_left", 20)
	head_margin.add_theme_constant_override("margin_right", 20)
	head_margin.add_theme_constant_override("margin_top", 5)
	head_margin.add_theme_constant_override("margin_bottom", 5)
	_top.add_child(head_margin)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 9)
	head_margin.add_child(head)
	var brand_pic := TextureRect.new()
	brand_pic.texture = preload("res://Branding/BlueprintPencilGameLogo.png")
	brand_pic.custom_minimum_size = Vector2(185, 48)
	brand_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(brand_pic)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spacer)
	for info in [["⌂  HOME", "_show_home"], ["▤  SELECT LEVEL", "_show_levels"], ["▦  GUIDE", "_show_help"], ["▥  PROGRESS", "_show_progress"]]:
		var nav := _button(str(info[0]), false, 122, 39)
		nav.add_theme_font_size_override("font_size", 13)
		nav.pressed.connect(Callable(self, str(info[1])))
		head.add_child(nav)
	var user_pill := PanelContainer.new()
	user_pill.custom_minimum_size = Vector2(115, 37)
	user_pill.add_theme_stylebox_override("panel", _style(Color("153e6d"), Color("73ddf6"), 22, 4))
	head.add_child(user_pill)
	user_pill.add_child(_label("◉   TRAINEE", 13, Color("eefbff"), true))
	_jp_button = _button("日本語", false, 71, 38)
	_mm_button = _button("မြန်မာ", false, 71, 38)
	for b in [_jp_button, _mm_button]:
		b.add_theme_font_size_override("font_size", 12)
		head.add_child(b)
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
	_update_lang_buttons()

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.clip_contents = true
	outer.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	_scroll.add_child(margin)
	var align := HBoxContainer.new()
	align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(align)
	var left := Control.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.add_child(left)
	_body = VBoxContainer.new()
	_body.custom_minimum_size.x = 1320
	_body.add_theme_constant_override("separation", 0)
	align.add_child(_body)
	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.add_child(right)

	_bottom = PanelContainer.new()
	_bottom.custom_minimum_size.y = 22
	_bottom.size_flags_vertical = Control.SIZE_SHRINK_END
	_bottom.add_theme_stylebox_override("panel", _style(Color("113c69"), Color("3caed5"), 0, 0))
	outer.add_child(_bottom)
	_bottom.add_child(_label("DESIGN   •   SKETCH   •   SELECT MATERIALS   •   LEARN", 11, Color("d8f7ff"), true))


func _fit_content() -> void:
	if _body != null:
		_body.custom_minimum_size.x = 1320.0


func _set_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()


func _update_lang_buttons() -> void:
	if _jp_button == null or _mm_button == null:
		return
	for b in [_jp_button, _mm_button]:
		var active: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm")
		b.add_theme_stylebox_override("normal", _style(Color("0b89b8") if active else Color("ebfaff"), Color("84dffa"), 17, 5))
		b.add_theme_color_override("font_color", WHITE if active else INK)


func _clear() -> void:
	if _loading_tween != null and _loading_tween.is_running():
		_loading_tween.kill()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_top.show()
	_bottom.show()
	_scroll.scroll_vertical = 0
	_scroll.scroll_horizontal = 0


func _page(page_id: String, height_value: float = 645.0) -> Control:
	_clear()
	var p := Control.new()
	p.name = page_id
	p.custom_minimum_size = Vector2(1320, height_value)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(p)
	return p


func _entry_page(name_value: String) -> Control:
	var p := _page(name_value, 695)
	_top.hide()
	_bottom.hide()
	return p


func _show_loading() -> void:
	_menu_backdrop.texture = preload("res://MenuAssets/LoadingBackground.png")
	var page := _entry_page("IntroLoadingScreen")
	_panel(page, Rect2(130, 0, 1060, 680), Color(0.87, 0.96, 1.0, 0.52), Color("d8f7ff"), 24)
	_image(page, preload("res://Branding/BlueprintPencilGameLogo.png"), Rect2(320, 6, 684, 182))
	_image(page, preload("res://MenuAssets/Intro3DKitchenArt.png"), Rect2(190, 168, 940, 400))
	var progress := ProgressBar.new()
	progress.name = "LoadingBar"
	progress.max_value = 100.0
	progress.value = 0.0
	progress.show_percentage = false
	progress.custom_minimum_size = Vector2(480, 16)
	progress.add_theme_stylebox_override("background", _style(Color("b1dff5"), Color("2b8fbd"), 11))
	progress.add_theme_stylebox_override("fill", _style(Color("27d6f4"), Color("a9fcff"), 11))
	_place(page, progress, Rect2(421, 572, 478, 17))
	_text(page, "Preparing your kitchen adventure...", 18, Rect2(410, 598, 500, 34), Color("1b5984"), true)
	_loading_tween = create_tween()
	_loading_tween.tween_property(progress, "value", 100.0, 2.15).set_trans(Tween.TRANS_SINE)
	_loading_tween.tween_callback(func() -> void:
		if is_inside_tree() and is_instance_valid(page):
			_show_language()
	)


func _show_language() -> void:
	_menu_backdrop.texture = preload("res://MenuAssets/LanguageBackground.png")
	var page := _entry_page("ChooseLanguageScreen")
	_image(page, preload("res://Branding/BlueprintPencilGameLogo.png"), Rect2(338, 31, 644, 196))
	_panel(page, Rect2(440, 222, 440, 325), Color("ecf9ff"), Color("87d6f8"), 28)
	_text(page, "SELECT LANGUAGE", 23, Rect2(488, 253, 345, 40), Color("153d66"), true)
	var options := OptionButton.new()
	options.name = "LanguageDropdown"
	options.custom_minimum_size = Vector2(350, 52)
	options.add_theme_font_size_override("font_size", 20)
	options.add_theme_color_override("font_color", Color("173e64"))
	options.add_theme_color_override("font_hover_color", Color("173e64"))
	options.add_theme_color_override("font_pressed_color", Color("173e64"))
	options.add_theme_stylebox_override("normal", _style(Color("fcfeff"), Color("83d2f5"), 15, 9))
	options.add_theme_stylebox_override("hover", _style(Color("ddf4ff"), Color("27b8e8"), 15, 9))
	options.add_theme_stylebox_override("pressed", _style(Color("d3f2ff"), Color("27b8e8"), 15, 9))
	options.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("50ceff"), 15))
	var popup := options.get_popup()
	popup.add_theme_stylebox_override("panel", _raised(Color("f7fcff"), Color("9adbf9"), 15))
	popup.add_theme_stylebox_override("hover", _style(Color("c8ecff"), Color("55c6ef"), 13, 6))
	popup.add_theme_color_override("font_color", Color("19466e"))
	popup.add_theme_color_override("font_hover_color", Color("144977"))
	popup.add_theme_color_override("font_disabled_color", Color("8daab9"))
	popup.add_theme_font_size_override("font_size", 19)
	options.add_item("日本語", 0)
	options.add_item("မြန်မာ", 1)
	options.add_item("English (Coming Soon)", 2)
	options.set_item_disabled(2, true)
	options.select(1 if Progress.get_language() == "mm" else 0)
	_place(page, options, Rect2(478, 329, 364, 54))
	var continue_button := _button("CONTINUE   »", true, 300, 57)
	continue_button.name = "LanguageContinueButton"
	continue_button.add_theme_font_size_override("font_size", 19)
	continue_button.pressed.connect(func() -> void:
		_set_language("mm" if options.selected == 1 else "jp")
		_show_home()
	)
	_place(page, continue_button, Rect2(505, 425, 310, 58))
	_text(page, "Japanese  •  Myanmar", 15, Rect2(470, 498, 380, 32), Color("5e84a4"), true)


func _show_home() -> void:
	_menu_backdrop.texture = preload("res://MenuAssets/LanguageBackground.png")
	var page := _entry_page("MainMenuScreen")
	_panel(page, Rect2(104, 3, 1112, 666), Color(0.93, 0.98, 1.0, 0.66), Color("d8f9ff"), 28)
	_image(page, preload("res://Branding/BlueprintPencilGameLogo.png"), Rect2(302, 12, 705, 210))
	# Menu buttons are live and deliberately stacked, as in the reference.
	var menu_back := _panel(page, Rect2(150, 246, 440, 368), Color(0.96, 0.99, 1.0, 0.87), Color("bbecfa"), 26)
	var start := _button("▶   START GAME", true, 347, 60)
	start.add_theme_font_size_override("font_size", 22)
	start.pressed.connect(_show_levels)
	_place(page, start, Rect2(192, 271, 352, 60))
	var sel := _button("▤   SELECT LEVEL", false, 347, 55)
	sel.pressed.connect(_show_levels)
	_place(page, sel, Rect2(192, 349, 352, 55))
	var guide := _button("▦   GAME GUIDE", false, 347, 55)
	guide.pressed.connect(_show_help)
	_place(page, guide, Rect2(192, 424, 352, 55))
	var settings := _button("⚙   SETTINGS", false, 347, 55)
	settings.pressed.connect(_show_settings)
	_place(page, settings, Rect2(192, 499, 352, 55))
	# A framed kitchenette only; never an image used as a non-clickable menu overlay.
	_panel(page, Rect2(625, 242, 527, 344), Color(0.84, 0.94, 0.99, 0.82), Color("b1ecfe"), 22)
	_image(page, preload("res://MenuAssets/Intro3DKitchenArt.png"), Rect2(622, 231, 542, 365))
	_panel(page, Rect2(866, 598, 270, 38), Color("114d7e"), Color("77e2fc"), 21)
	_text(page, "SKETCH  •  Q&A  •  MATERIALS", 13, Rect2(872, 602, 254, 27), Color("e9fbff"), true)
	if is_pause_overlay:
		var resume := _button("←  BACK TO GAME", false, 194, 38)
		resume.pressed.connect(_resume_paused)
		_place(page, resume, Rect2(171, 565, 193, 38))


func _selected_name(n: int) -> String:
	match n:
		1: return "LDK Boundary Drawing"
		2: return "Pipe Shaft Q&A"
		3: return "S-Class Kitchen Selection"
		4: return "Island Layout Planning"
		5: return "Lighting & Atmosphere"
		_: return "Final Kitchen Design"


func _stage_image(n: int) -> Texture2D:
	match n:
		1: return preload("res://reference_sketch.png")
		2: return preload("res://MenuAssets/Level2.png")
		3: return preload("res://MenuAssets/KitchenHero.jpg")
		4: return preload("res://MenuAssets/Level4.png")
		5: return preload("res://MenuAssets/Level5.png")
		_: return preload("res://MenuAssets/Level6.png")


func _choose_stage(n: int) -> void:
	if n <= 3 and Progress.is_level_unlocked(n):
		_chosen_stage = n
		_show_levels()


func _step_stage(delta: int) -> void:
	_chosen_stage = clampi(_chosen_stage + delta, 1, 3)
	_show_levels()


func _stage_card(page: Control, n: int, x: float, y: float, w: float, h: float) -> void:
	var available: bool = n <= 3 and Progress.is_level_unlocked(n)
	var selected: bool = n == _chosen_stage and available
	var btn := Button.new()
	btn.name = "StageCard%02d" % n
	btn.set_meta("stage", n)
	btn.set_meta("level_unlocked", available)
	btn.text = ""
	btn.disabled = not available
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	btn.clip_contents = true
	btn.add_theme_stylebox_override("normal", _raised(Color("effaff") if available else Color("9daebd"), Color("28deef") if selected else Color("c1ddea"), 20))
	btn.add_theme_stylebox_override("hover", _raised(Color("dcf8ff"), Color("52eaff"), 20))
	btn.add_theme_stylebox_override("pressed", _style(Color("c9f0ff"), Color("34bfdf"), 20))
	btn.add_theme_stylebox_override("disabled", _style(Color("aabac8"), Color("bacad6"), 20))
	if available:
		btn.pressed.connect(_choose_stage.bind(n))
	_place(page, btn, Rect2(x, y, w, h))
	# Curved dark blueprint ribbon, image, description and genuine play button.
	_panel(btn, Rect2(4, 4, w - 8, 33), Color("064b75") if available else Color("4b6175"), Color("63e4f5") if selected else Color("b1cedd"), 13)
	_text(btn, ("▶   " if selected else "") + "STAGE %02d" % n, 15, Rect2(7, 8, w-14, 27), Color("ffffff"), true)
	var photo := _image(btn, _stage_image(n), Rect2(8, 43, w - 16, 122 if selected else 110), true)
	photo.modulate = WHITE if available else Color("bac5d0")
	_text(btn, _selected_name(n), 15 if selected else 13, Rect2(6, 171 if selected else 159, w-12, 38), INK if available else Color("e7f1f7"), true)
	if selected:
		var play := _button("▶  Play  »", true, w-37, 40)
		play.name = "SelectedPlayButton"
		play.add_theme_font_size_override("font_size", 17)
		play.pressed.connect(_start_level.bind(n))
		_place(btn, play, Rect2(18, h-54, w-36, 40))
	else:
		var hint := "SELECT" if available else "🔒  Locked"
		_text(btn, hint, 12, Rect2(7, h-41, w-14, 30), Color("0b7eac") if available else Color("ecf2f7"), true)
	if selected:
		btn.move_to_front()


func _show_levels() -> void:
	var page := _page("StageSelectionScreen", 659)
	# A restrained showroom with floating light blue cards and a cyan stage rail.
	_panel(page, Rect2(14, 6, 1292, 642), Color(0.94, 0.99, 1.0, 0.62), Color("a9def6"), 25)
	_text(page, "Select a Stage", 35, Rect2(345, 22, 628, 55), Color("103c67"), true)
	_text(page, "Progress through kitchen design missions step by step.", 16, Rect2(333, 79, 654, 28), Color("4f7998"), true)
	# Architectural blueprint ornament, not decorative UI screenshot.
	_image(page, preload("res://Branding/BlueprintPencilIcon.png"), Rect2(1059, 22, 126, 124))
	_image(page, preload("res://MenuAssets/BlueShowroomPlatform.png"), Rect2(0, 332, 1320, 243))
	# Cards intentionally stay in one row. The current card rises and glows.
	for n in range(1,7):
		var x: float = 69.0 + float(n-1) * 199.0
		var selected: bool = n == _chosen_stage and n <= 3
		_stage_card(page, n, x - (8.0 if selected else 0.0), 160.0 if selected else 191.0, 205.0 if selected else 188.0, 327.0 if selected else 286.0)
	var back := _button("‹", false, 49, 49)
	back.add_theme_font_size_override("font_size", 29)
	back.disabled = _chosen_stage <= 1
	back.pressed.connect(_step_stage.bind(-1))
	_place(page, back, Rect2(14, 281, 48, 48))
	var forward := _button("›", false, 49, 49)
	forward.add_theme_font_size_override("font_size", 29)
	forward.disabled = _chosen_stage >= 3
	forward.pressed.connect(_step_stage.bind(1))
	_place(page, forward, Rect2(1258, 281, 48, 48))
	# Progress shown as availability, NOT fabricated completion stars/coins.
	_panel(page, Rect2(109, 537, 1101, 100), Color(0.98,0.99,1.0,0.92), Color("b4e5f6"), 29)
	_text(page, "TRAINING MISSIONS", 13, Rect2(130, 548, 193, 25), Color("234f70"))
	_text(page, "3 / 6", 28, Rect2(140, 576, 115, 47), Color("079fc8"), true)
	_text(page, "AVAILABLE", 11, Rect2(230, 593, 110, 27), Color("477e9c"), true)
	# Timeline centered beneath the cards.
	var dots := [460.0, 596.0, 732.0, 868.0, 1004.0, 1140.0]
	for n in range(1,7):
		if n < 6:
			var line := ColorRect.new()
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.color = Color("0c9bbb") if n < 3 else Color("bbcbd6")
			_place(page, line, Rect2(float(dots[n-1]) + 48, 588, 88, 3))
		var active: bool = n <= 3
		var circle := _panel(page, Rect2(float(dots[n-1]), 567, 49, 49), Color("0aaacb") if n == _chosen_stage else (Color("e5faff") if active else Color("f2f4f7")), Color("27ddec") if active else Color("c4d3dc"), 25)
		_text(page, "%02d" % n, 16, Rect2(float(dots[n-1]), 574, 49, 34), WHITE if n == _chosen_stage else (INK if active else LOCKED), true)
	# Back-to-menu path retains pause behavior.
	if is_pause_overlay:
		var resume := _button("← BACK TO GAME", false, 171, 38)
		resume.pressed.connect(_resume_paused)
		_place(page, resume, Rect2(28, 24, 171, 38))



func _resume_paused() -> void:
	if is_pause_overlay:
		resume_requested.emit()
	else:
		_show_home()


func _show_help() -> void:
	_clear()
	_body.add_child(_label("HOW TO PLAY", 31, INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 18)
	panel.add_child(contents)
	contents.add_child(_label("01  LISTEN TO THE CUSTOMER", 19, GREEN))
	contents.add_child(_label("Choose Japanese or Myanmar, listen to the customer and review the layout request.", 16, MUTED))
	contents.add_child(_label("02  DRAW THE REQUESTED PLAN", 19, GREEN))
	contents.add_child(_label("Use the grid tools to sketch the requested walls and press OK to check your layout.", 16, MUTED))
	contents.add_child(_label("03  ANSWER THE CUSTOMER", 19, GREEN))
	contents.add_child(_label("Stages 1, 2, and 3 are available to play.", 16, MUTED))
	contents.add_child(_label("Progress and language selection are saved on this device.", 14, MUTED))
	var guide := _button("VIEW MISSION GUIDE", false, 206, 42)
	guide.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	guide.pressed.connect(_show_missions)
	contents.add_child(guide)
	var go := _button("BACK TO HOME", true, 190, 46)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_home)
	contents.add_child(go)


func _show_settings() -> void:
	_reset_armed = false
	_clear()
	_body.add_child(_label("SETTINGS", 31, INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 20)
	panel.add_child(contents)
	contents.add_child(_label("LANGUAGE", 18, GREEN))
	var languages := HBoxContainer.new()
	contents.add_child(languages)
	var japanese := _button("日本語", false, 140, 48)
	japanese.pressed.connect(func() -> void: _set_language("jp"))
	languages.add_child(japanese)
	var myanmar := _button("မြန်မာ", false, 140, 48)
	myanmar.pressed.connect(func() -> void: _set_language("mm"))
	languages.add_child(myanmar)
	contents.add_child(_label("GAME VOLUME", 18, GREEN))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = _volume_value
	volume.custom_minimum_size = Vector2(300, 36)
	volume.value_changed.connect(_on_volume_changed)
	contents.add_child(volume)
	var sound_row := HBoxContainer.new()
	sound_row.add_theme_constant_override("separation", 12)
	contents.add_child(sound_row)
	var sound_lbl := _label("MUTE ALL GAME AUDIO", 15, MUTED)
	sound_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_row.add_child(sound_lbl)
	var mute_toggle := CheckButton.new()
	mute_toggle.text = "OFF" if not Extras.muted() else "ON"
	mute_toggle.button_pressed = Extras.muted()
	mute_toggle.toggled.connect(func(value: bool) -> void:
		Extras.set_muted(value)
		Extras.apply_audio()
		mute_toggle.text = "ON" if value else "OFF"
	)
	sound_row.add_child(mute_toggle)
	contents.add_child(_label("DISPLAY", 18, GREEN))
	var full_row := HBoxContainer.new()
	full_row.add_theme_constant_override("separation", 12)
	contents.add_child(full_row)
	var fullscreen_btn := _button("TOGGLE FULLSCREEN", false, 220, 39)
	fullscreen_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fullscreen_btn.pressed.connect(_toggle_fullscreen)
	full_row.add_child(fullscreen_btn)
	full_row.add_child(_label("Browser fullscreen may require user permission.", 12, MUTED))
	contents.add_child(_label("Volume and mute settings are saved locally.", 12, MUTED))
	contents.add_child(_label("SAVED GAME PROGRESS", 18, GREEN))
	contents.add_child(_label("Reset saved stage progress; all available stages remain playable.", 14, MUTED))
	var reset := _button("RESET LEVEL PROGRESS", false, 255, 45)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_on_reset_progress_pressed.bind(reset))
	contents.add_child(reset)
	var go := _button("BACK TO HOME", true, 190, 48)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_home)
	contents.add_child(go)


func _on_reset_progress_pressed(b: Button) -> void:
	if not _reset_armed:
		_reset_armed = true
		b.text = "CONFIRM RESET"
		return
	_reset_armed = false
	Progress.reset_progress()
	_show_levels()


func _on_volume_changed(value: float) -> void:
	_volume_value = value
	Extras.set_volume(value)
	Extras.apply_audio()


func _start_level(level: int) -> void:
	if level > 3 or not Progress.is_level_unlocked(level):
		return
	Progress.launch_from_level_menu = (level == 1)
	if is_pause_overlay:
		get_tree().paused = false
	var target: String = "res://main.tscn" if level == 1 else ("res://stage_2.tscn" if level == 2 else "res://stage_3.tscn")
	var result: Error = get_tree().change_scene_to_file(target)
	if result == OK:
		Extras.record_launch(level)
	if result != OK:
		Progress.launch_from_level_menu = false
		if is_pause_overlay:
			get_tree().paused = true
		push_error("Failed to open level: " + target)

# -----------------------------------------------------------------------------
# V16 MENU HUB. Separate from Stage 1 / Stage 2 / Stage 3 gameplay.
# -----------------------------------------------------------------------------

func _menu_page(page_title: String, subtitle: String) -> VBoxContainer:
	_clear()
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 14)
	_body.add_child(heading_row)
	var back := _button("BACK TO LEVELS" if is_pause_overlay else "BACK TO HOME", false, 150, 35)
	back.add_theme_font_size_override("font_size", 12)
	if is_pause_overlay:
		back.pressed.connect(_show_levels)
	else:
		back.pressed.connect(_show_home)
	heading_row.add_child(back)
	var title := _label(page_title, 26, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(title)
	_body.add_child(_label(subtitle, 13, MUTED))
	return _body


func _info_panel(title_text: String, description: String, marker: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 15, 18))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	card.add_child(content)
	if not marker.is_empty():
		content.add_child(_label(marker, 12, GREEN))
	content.add_child(_label(title_text, 18, INK))
	if not description.is_empty():
		content.add_child(_label(description, 14, MUTED))
	return card


func _show_profile() -> void:
	_menu_page("PLAYER PROFILE", "Optional local display name. No account or password required.")
	var card := _info_panel("Welcome, " + Extras.get_name(), "Your display name and game menu statistics are saved locally on this device.", "PLAYER CARD")
	_body.add_child(card)
	var content := card.get_child(0) as VBoxContainer
	content.add_child(_label("DISPLAY NAME", 13, GREEN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var field := LineEdit.new()
	field.text = Extras.get_name()
	field.placeholder_text = "Guest"
	field.max_length = 24
	field.custom_minimum_size = Vector2(290, 42)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	var save_btn := _button("SAVE NAME", true, 144, 42)
	save_btn.pressed.connect(func() -> void:
		Extras.set_name(field.text)
		_show_profile()
	)
	field.text_submitted.connect(func(_value: String) -> void:
		Extras.set_name(field.text)
		_show_profile()
	)
	row.add_child(save_btn)
	_body.add_child(_info_panel("Privacy", "This is a local guest profile, not online sign-in. Clearing the browser's site data or Godot user data can erase it."))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	_body.add_child(actions)
	var progress_btn := _button("MY PROGRESS", false, 170, 39)
	progress_btn.pressed.connect(_show_progress)
	actions.add_child(progress_btn)
	var achieve_btn := _button("ACHIEVEMENTS", false, 180, 39)
	achieve_btn.pressed.connect(_show_achievements)
	actions.add_child(achieve_btn)


func _show_progress() -> void:
	_stats_reset_armed = false
	_menu_page("MY PROGRESS", "Verified progress and launch history; available stages remain unlocked.")
	var summary := _info_panel("" + Extras.get_name() + "'s Learning Journey", "Stages launched from Level Select: %d" % Extras.total_count(), "PLAYER OVERVIEW")
	_body.add_child(summary)
	var v := summary.get_child(0) as VBoxContainer
	var last_label := "Not yet played"
	if Extras.last_stage() > 0:
		last_label = "Stage %d" % Extras.last_stage()
		if not Extras.last_date().is_empty():
			last_label += "  •  " + Extras.last_date()
	v.add_child(_label("Last selected: " + last_label, 13, MUTED))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 11)
	_body.add_child(grid)
	for n in range(1, 4):
		var text_status := "COMPLETED (VERIFIED)" if n == 1 and Extras.stage1_completed() else ("NOT YET VERIFIED" if n == 1 else "COMPLETION NOT TRACKED")
		var panel := _info_panel("STAGE %d" % n, "Level Menu launches: %d\n%s" % [Extras.count(n), text_status], "AVAILABLE TO PLAY")
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
	_body.add_child(_info_panel("About progress", "Stage 1 completion is read from the existing verified save file. Stage 2/3 completion is not stored there, so this screen does not claim they were completed. Launch counts only include starts from Level Select."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_body.add_child(row)
	var go := _button("SELECT LEVEL", true, 155, 41)
	go.pressed.connect(_show_levels)
	row.add_child(go)
	var reset := _button("CLEAR MENU HISTORY", false, 225, 41)
	reset.pressed.connect(func() -> void:
		if not _stats_reset_armed:
			_stats_reset_armed = true
			reset.text = "CONFIRM CLEAR HISTORY"
		else:
			Extras.reset_stats()
			_show_progress()
	)
	row.add_child(reset)


func _achievement_card(title_text: String, requirement: String, earned: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("f0faf4") if earned else WHITE, GREEN if earned else BORDER, 14, 16))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(_label("UNLOCKED" if earned else "LOCKED", 12, GREEN if earned else LOCKED))
	v.add_child(_label(title_text, 18, INK))
	v.add_child(_label(requirement, 13, MUTED))
	return panel


func _show_achievements() -> void:
	_menu_page("ACHIEVEMENTS", "Rewards reflect actual menu activity or verified Stage 1 completion.")
	var total := Extras.total_count()
	var all_visited := Extras.count(1) > 0 and Extras.count(2) > 0 and Extras.count(3) > 0
	var completed_count: int = 0
	if total >= 1:
		completed_count += 1
	if all_visited:
		completed_count += 1
	if total >= 5:
		completed_count += 1
	if Extras.stage1_completed():
		completed_count += 1
	_body.add_child(_info_panel("%d / 4 BADGES EARNED" % completed_count, "Keep exploring the available stages to earn menu badges.", "ACHIEVEMENT COLLECTION"))
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	_body.add_child(row1)
	row1.add_child(_achievement_card("First Steps", "Launch any stage from Level Select.", total >= 1))
	row1.add_child(_achievement_card("Stage Explorer", "Launch Stage 1, 2 and 3 at least once each.", all_visited))
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	_body.add_child(row2)
	row2.add_child(_achievement_card("Dedicated Learner", "Launch stages 5 times in total from Level Select.", total >= 5))
	row2.add_child(_achievement_card("Drawing Challenge Clear", "Complete and verify Stage 1 drawing.", Extras.stage1_completed()))
	_body.add_child(_label("Stage 2/3 badges will need completion events in those scenes. They are not invented here.", 13, MUTED))
	var go := _button("VIEW MY PROGRESS", true, 190, 42)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_progress)
	_body.add_child(go)


func _show_missions() -> void:
	_menu_page("MISSION GUIDE", "Preview each stage without changing gameplay, answers or customer dialogue.")
	var titles := ["FLOOR PLAN DRAWING", "PIPE SHAFT Q&A", "S-CLASS KITCHEN SELECTION"]
	var details := [
		"Listen to the customer, draw the requested LDK boundary and check the measured layout.",
		"Explain what PS means and why it matters during renovation. Gemini is used when available, with a local fallback.",
		"Choose the kitchen layout and configuration, then identify the kitchen parts. Follow the existing in-stage progress flow."
	]
	for n in range(1, 4):
		var card := _info_panel("STAGE %d  •  %s" % [n, titles[n - 1]], details[n - 1], "MISSION %02d  •  AVAILABLE" % n)
		_body.add_child(card)
		var v := card.get_child(0) as VBoxContainer
		var start := _button("PLAY STAGE %d" % n, false, 154, 37)
		start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		start.pressed.connect(_start_level.bind(n))
		v.add_child(start)
	_body.add_child(_label("STAGES 4–6  •  COMING SOON", 14, LOCKED))


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
