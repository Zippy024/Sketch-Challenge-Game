extends Control

# Concept C — Modern Training Console. Native Godot controls, no screenshot-based buttons.
# Stage 1/2/3 game scripts and answer evaluation remain unchanged.
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")
const ConsoleAnimations = preload("res://ConceptCAnimations.gd")
const SunsetSparkles = preload("res://MenuAssets/SunsetSparkles.gd")
const KitchenHologram = preload("res://MenuAssets/OptionCHologram.gd")
const EntryKitchenSketch = preload("res://MenuAssets/EntryKitchenSketch.gd")

const BG := Color("211c34")
const WHITE := Color("ffffff")
const INK := Color("fff3db")
const MUTED := Color("c9b8c7")
const GREEN := Color("e77d4a")
const GREEN_DARK := Color("bc5539")
const GREEN_PALE := Color("453044")
const BORDER := Color("61465a")
const GOLD := Color("f9bc73")
const C_DARK := Color("19172a")
const C_PANEL := Color("292037")
const C_INK := Color("fff4e6")
const C_MUTED := Color("dcc2c5")
const C_COPPER := Color("ffbb76")
const C_MINT := Color("ffce80")
const LOCKED := Color("8d8395")

var is_pause_overlay: bool = false
var pause_level: int = 0
var _body: VBoxContainer
var _menu_photo: TextureRect
var _top_bar: Control
var _bottom_bar: Control
var _jp_button: Button
var _mm_button: Button
var _scroll: ScrollContainer
var _volume_value: float = 0.85
var _reset_armed: bool = false


func _ready() -> void:
	theme = BilingualTheme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame()
	resized.connect(_fit_content)
	_fit_content()
	if is_pause_overlay or Progress.show_levels_on_open:
		Progress.show_levels_on_open = false
		_show_levels()
	else:
		# Web users already saw the branded progress intro in the HTML shell.
		# Switch directly to the language screen to avoid two loading screens.
		if OS.has_feature("web"):
			_show_language_select()
		else:
			_show_splash()
	# The HTML Web shell must not dismiss its loading artwork until this
	# actual menu scene has entered the tree and completed its UI setup.
	if OS.has_feature("web"):
		call_deferred("_notify_web_menu_ready")


func _notify_web_menu_ready() -> void:
	if OS.has_feature("web") and is_inside_tree() and is_instance_valid(_body):
		JavaScriptBridge.eval("window.__sketchSceneReady = true;", true)


func _style(bg: Color, edge: Color = BORDER, radius: int = 15, padding: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(padding)
	return s


func _label(value: String, font_size: int = 16, color: Color = INK, centered: bool = false) -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(title: String, primary: bool = false, min_w: float = 165.0, min_h: float = 46.0) -> Button:
	var b := Button.new()
	b.text = title
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", Color("ffffff"))
	b.add_theme_color_override("font_hover_color", Color("ffffff"))
	b.add_theme_color_override("font_pressed_color", Color("ffffff"))
	b.add_theme_stylebox_override("normal", _console_style(Color("12ae8c") if primary else Color(0.15,0.18,0.21,0.85), Color("9bffe1") if primary else Color("a4c7bf"), 25, 9, 8 if primary else 2))
	b.add_theme_stylebox_override("hover", _console_style(Color("1ad8ac") if primary else Color("415257"), Color("e1fff1"), 25, 9, 12))
	b.add_theme_stylebox_override("pressed", _console_style(Color("0d967a") if primary else Color("26373b"), Color("b8ffe8"), 25, 9, 3))
	b.add_theme_stylebox_override("disabled", _console_style(Color("66686d"), Color("a4a7a8"), 25, 9))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("a2ffe3"), 25))
	ConsoleAnimations.animate_button(b)
	return b

func _console_style(fill: Color, line: Color, radius: int = 15, inset: int = 10, shadow: int = 0) -> StyleBoxFlat:
	var style := _style(fill, line, radius, inset)
	if shadow > 0:
		style.shadow_size = shadow
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.31)
		style.shadow_offset = Vector2(0, 3)
	return style


func _icon_button(title: String, image: Texture2D, primary: bool, w: float, h: float, callback: Callable) -> Button:
	var btn := _button(title, primary, w, h)
	btn.icon = image
	btn.expand_icon = false
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_constant_override("icon_max_width", 22)
	btn.pressed.connect(callback)
	return btn


func _c_panel(fill: Color = C_PANEL, edge: Color = C_COPPER, rounding: int = 22, padding: int = 18) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _console_style(fill, edge, rounding, padding, 8))
	return p


func _section_heading(value: String, font_size: int = 22) -> Label:
	return _label(value, font_size, C_INK)


func _thin_rule() -> ColorRect:
	var line := ColorRect.new()
	line.color = Color("b9786f")
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _glass(fill: Color, edge: Color = Color("f6e1d3"), radius: int = 22, padding: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = fill
	st.border_color = edge
	st.set_border_width_all(2)
	st.set_corner_radius_all(radius)
	st.set_content_margin_all(padding)
	st.shadow_size = 10
	st.shadow_color = Color(0.16, 0.09, 0.17, 0.20)
	st.shadow_offset = Vector2(0, 4)
	p.add_theme_stylebox_override("panel", st)
	return p


func _nav_button(title: String, callback: Callable) -> Button:
	var b := _button(title, false, 125, 38)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal", _console_style(Color(0.98,0.98,0.98,0.80), Color("ffffff"), 23, 7, 3))
	b.add_theme_stylebox_override("hover", _console_style(Color("d3fff1"), Color("6bdec3"), 23, 7, 8))
	b.add_theme_stylebox_override("pressed", _console_style(Color("b6f4e5"), Color("4aba9f"), 23, 7, 1))
	b.add_theme_color_override("font_color", Color("263434"))
	b.add_theme_color_override("font_hover_color", Color("172d2a"))
	b.add_theme_color_override("font_pressed_color", Color("172d2a"))
	if not callback.is_null():
		b.pressed.connect(callback)
	return b

func _build_frame() -> void:
	# Full-viewport controls: no PanelContainer sizing feedback into the header.
	var base := Control.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var photo := TextureRect.new()
	photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_photo = photo
	base.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var light := ColorRect.new()
	light.color = Color(0.93, 1.0, 0.95, 0.06)
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(light)
	light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sparkles := SunsetSparkles.new()
	base.add_child(sparkles)
	sparkles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	base.add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_top_bar = _glass(Color(1, 1, 1, 0.88), Color("f6ffff"), 0, 4)
	_top_bar.custom_minimum_size.y = 66
	_top_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	outer.add_child(_top_bar)
	var head_pad := MarginContainer.new()
	head_pad.add_theme_constant_override("margin_left", 21)
	head_pad.add_theme_constant_override("margin_right", 21)
	head_pad.add_theme_constant_override("margin_top", 3)
	head_pad.add_theme_constant_override("margin_bottom", 3)
	_top_bar.add_child(head_pad)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 9)
	head_pad.add_child(header)
	var emblem := TextureRect.new()
	emblem.texture = preload("res://Branding/SketchPlanPencil.svg")
	emblem.custom_minimum_size = Vector2(46, 46)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(emblem)
	var brand := _label("KITCHEN SKETCH CHALLENGE", 17, Color("203b37"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(brand)
	header.add_child(_nav_button("HOME", _show_home))
	header.add_child(_nav_button("ALL STAGES", _show_levels))
	var trainee := _glass(Color(0.11,0.22,0.23,0.87), Color("aefce9"), 20, 7)
	header.add_child(trainee)
	var trainee_text := _label("TRAINEE", 12, C_INK, true)
	trainee_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	trainee.custom_minimum_size.x = 105
	trainee.add_child(trainee_text)
	_jp_button = _button("日本語", false, 74, 36)
	_mm_button = _button("မြန်မာ", false, 74, 36)
	for lang_btn in [_jp_button, _mm_button]:
		lang_btn.add_theme_font_size_override("font_size", 12)
		header.add_child(lang_btn)
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
	_update_lang_buttons()

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.clip_contents = true
	outer.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_scroll.add_child(margin)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 13)
	margin.add_child(_body)
	_bottom_bar = _glass(Color(0.11,0.23,0.22,0.77), Color("d4ffed"), 0, 1)
	_bottom_bar.custom_minimum_size.y = 25
	_bottom_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	outer.add_child(_bottom_bar)
	_bottom_bar.add_child(_label("DESIGN  •  SKETCH  •  SELECT MATERIALS  •  LEARN", 11, C_INK, true))

func _set_concept_background(choose_levels: bool) -> void:
	if not is_instance_valid(_menu_photo):
		return
	# Warm, daylight kitchen remains legible behind glass panels.
	_menu_photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg") if not choose_levels else preload("res://MenuAssets/KitchenHero.jpg")
	_menu_photo.modulate = Color.WHITE

func _fit_content() -> void:
	if _body != null:
		_body.custom_minimum_size.x = 0.0

func _set_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()


func _update_lang_buttons() -> void:
	for b in [_jp_button, _mm_button]:
		if not is_instance_valid(b):
			continue
		var selected: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm")
		b.add_theme_stylebox_override("normal", _console_style(Color("117d6a") if selected else Color("314749"), Color("b7ffe9") if selected else Color("aac8be"), 12, 6))
		b.add_theme_stylebox_override("hover", _console_style(Color("1da58c"), Color("d4fff3"), 12, 6))
		b.add_theme_color_override("font_color", WHITE)

func _clear() -> void:
	_set_concept_background(false)
	_scroll.show()
	_top_bar.show()
	_bottom_bar.show()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_scroll.scroll_vertical = 0

func _entry_background() -> void:
	# Blue daylight kitchen background used only during Intro + Language.
	if is_instance_valid(_menu_photo):
		_menu_photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg")
		_menu_photo.modulate = Color("c7e8ff")
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


func _entry_canvas(name_value: String) -> Control:
	_clear()
	_top_bar.hide()
	_bottom_bar.hide()
	_entry_background()
	var root := Control.new()
	root.name = name_value
	root.custom_minimum_size = Vector2(1100, 650)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(root)
	# Center the fixed 1100×650 stage inside the desktop window.
	var center := Control.new()
	center.name = name_value + "Content"
	root.add_child(center)
	center.anchor_left = 0.5
	center.anchor_right = 0.5
	center.anchor_top = 0.0
	center.anchor_bottom = 0.0
	center.offset_left = -550.0
	center.offset_right = 550.0
	center.offset_top = 0.0
	center.offset_bottom = 650.0
	return center


func _entry_add(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.position = rect.position
	child.size = rect.size


func _entry_centered_label(value: String, font_size: int, rect: Rect2, color: Color, parent: Control) -> Label:
	var lbl := _label(value, font_size, color, true)
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_entry_add(parent, lbl, rect)
	return lbl


func _show_splash() -> void:
	var scene := _entry_canvas("EntryLoadingScreen")
	var tint := ColorRect.new()
	tint.color = Color(0.83, 0.93, 1.0, 0.35)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_add(scene, tint, Rect2(0, 0, 1100, 650))
	var heading := _entry_centered_label("Kitchen", 62, Rect2(215, 10, 670, 83), Color("267dbb"), scene)
	heading.add_theme_constant_override("outline_size", 6)
	heading.add_theme_color_override("font_outline_color", Color("113e71"))
	var subtitle := _entry_centered_label("Decoration Game", 43, Rect2(185, 88, 730, 64), Color("ffffff"), scene)
	subtitle.add_theme_constant_override("outline_size", 7)
	subtitle.add_theme_color_override("font_outline_color", Color("123c73"))
	var mark := TextureRect.new()
	mark.texture = preload("res://Branding/SketchPlanPencil.svg")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_add(scene, mark, Rect2(335, 151, 72, 72))
	var scene_art := EntryKitchenSketch.new()
	scene_art.name = "EntryIsometricKitchen"
	scene_art.set_meta("entry_kitchen_art", true)
	_entry_add(scene, scene_art, Rect2(168, 165, 790, 375))
	var bar := ProgressBar.new()
	bar.name = "EntryLoadingProgress"
	bar.custom_minimum_size = Vector2(400, 17)
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 0
	bar.add_theme_stylebox_override("background", _console_style(Color("c8dbea"), Color("fff9ff"), 12, 1))
	bar.add_theme_stylebox_override("fill", _console_style(Color("358ed1"), Color("b5edff"), 12, 1))
	_entry_add(scene, bar, Rect2(350, 559, 400, 18))
	_entry_centered_label("Loading...", 17, Rect2(395, 584, 320, 30), Color("254e77"), scene)
	scene.modulate.a = 0
	var appear := create_tween()
	appear.tween_property(scene, "modulate:a", 1.0, 0.35)
	var loading := create_tween()
	loading.tween_property(bar, "value", 100.0, 1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	loading.tween_callback(func() -> void:
		if is_inside_tree() and is_instance_valid(scene):
			_show_language_select()
	)

func _home_place(parent: Control, child: Control, bounds: Rect2) -> void:
	# Absolute screen composition for the opening hero; the surrounding
	# layout is handled by the scroll view. No intrinsic Label min-size can
	# collapse the panel, expand the scene, or stack letters vertically.
	parent.add_child(child)
	child.position = bounds.position
	child.size = bounds.size


func _home_right_place(parent: Control, child: Control, left: float, top: float, width_value: float, height_value: float) -> void:
	parent.add_child(child)
	child.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	child.offset_left = left
	child.offset_right = left + width_value
	child.offset_top = top
	child.offset_bottom = top + height_value


func _show_home() -> void:
	_clear()
	_set_concept_background(false)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	# Control root prevents VBox/HBox minimum sizing feedback from turning
	# the hero into a blank area and the right features into vertical text.
	var canvas := Control.new()
	canvas.name = "OptionCHomeCanvas"
	canvas.custom_minimum_size = Vector2(960, 588)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(canvas)

	var glass := _glass(Color(1.0, 1.0, 0.99, 0.88), Color("ffffff"), 32, 0)
	glass.name = "HomeHeroGlass"
	glass.set_meta("home_hero_panel", true)
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_place(canvas, glass, Rect2(10, 18, 560, 520))

	var emblem := TextureRect.new()
	emblem.texture = preload("res://Branding/SketchPlanPencil.svg")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_place(canvas, emblem, Rect2(36, 60, 105, 105))

	var tagline := _label("KITCHEN DESIGN TRAINING", 13, Color("4d5b5c"))
	tagline.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_place(canvas, tagline, Rect2(156, 61, 385, 28))
	var kitchen := _label("Kitchen", 47, Color("193e37"))
	kitchen.autowrap_mode = TextServer.AUTOWRAP_OFF
	kitchen.set_meta("home_headline", true)
	_home_place(canvas, kitchen, Rect2(156, 91, 388, 65))
	var sketch := _label("Sketch Challenge", 33, Color("078b73"))
	sketch.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_place(canvas, sketch, Rect2(156, 148, 390, 56))

	var subtitle := _label("DECORATION GAME", 19, Color("3b514d"), true)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_place(canvas, subtitle, Rect2(38, 211, 495, 29))
	var rule := ColorRect.new()
	rule.color = Color("63cdb1")
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_place(canvas, rule, Rect2(72, 257, 440, 2))
	var mission := _label("DESIGN  •  SKETCH  •  SELECT  •  LEARN", 15, Color("315c50"), true)
	mission.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_place(canvas, mission, Rect2(43, 274, 488, 27))
	var description := _label("Plan kitchen layouts, choose materials and solve real design challenges through practical missions.", 16, Color("344b47"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_home_place(canvas, description, Rect2(58, 309, 467, 66))

	var start := _button("▶   START TRAINING   »", true, 430, 59)
	start.name = "HomeStartTraining"
	start.set_meta("home_start_button", true)
	start.add_theme_font_size_override("font_size", 22)
	start.pressed.connect(_show_language_select)
	_home_place(canvas, start, Rect2(74, 388, 431, 59))
	var level := _nav_button("▦  SELECT LEVEL", _show_levels)
	_home_place(canvas, level, Rect2(36, 467, 158, 44))
	var guide := _nav_button("▤  TRAINING GUIDE", _show_help)
	_home_place(canvas, guide, Rect2(207, 467, 159, 44))
	var progress := _nav_button("▥  MY PROGRESS", _show_progress)
	_home_place(canvas, progress, Rect2(379, 467, 160, 44))

	# Right-hand decorative cards are independently right-anchored, never
	# packed in a VBox that can collapse to a 30px-wide strip.
	var hologram_panel := _glass(Color(0.08, 0.30, 0.30, 0.66), Color("8bfadf"), 25, 0)
	hologram_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_right_place(canvas, hologram_panel, -346, 105, 326, 195)
	var hologram := KitchenHologram.new()
	_home_right_place(canvas, hologram, -330, 116, 294, 164)

	var features := _glass(Color(0.06, 0.22, 0.24, 0.78), Color("c0ffe9"), 23, 0)
	features.name = "HomeFeaturesGlass"
	features.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_right_place(canvas, features, -318, 323, 296, 179)
	var features_title := _label("DESIGN SKILLS", 15, Color("bcffeb"), true)
	features_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_right_place(canvas, features_title, -302, 338, 266, 26)
	var f1 := _label("✎   Sketch Layouts", 17, Color("ffffff"))
	f1.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_right_place(canvas, f1, -290, 374, 250, 30)
	var f2 := _label("▱   Choose Materials", 17, Color("ffffff"))
	f2.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_right_place(canvas, f2, -290, 415, 250, 30)
	var f3 := _label("⬡   Build Design Skills", 17, Color("ffffff"))
	f3.autowrap_mode = TextServer.AUTOWRAP_OFF
	_home_right_place(canvas, f3, -290, 456, 250, 30)

	if is_pause_overlay:
		var resume := _nav_button("← BACK TO GAME", _resume_paused)
		_home_place(canvas, resume, Rect2(36, 523, 210, 40))
	glass.modulate.a = 0.0
	var intro := create_tween()
	intro.tween_property(glass, "modulate:a", 1.0, 0.46).set_trans(Tween.TRANS_SINE)

func _add_home_button(parent: HBoxContainer, label_text: String, action: Callable) -> void:
	var b := _button(label_text, false, 195, 60)
	b.add_theme_stylebox_override("normal", _style(Color(0.70, 0.98, 0.93, 0.74), Color(1, 1, 1, 0.97), 20, 12))
	b.add_theme_stylebox_override("hover", _style(Color("ffe7dc"), Color("faad79"), 20, 12))
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(action)
	parent.add_child(b)


func _show_profile() -> void:
	_show_information("PLAYER PROFILE", "You are playing as a guest. Stage progress is stored on this device.")


func _show_progress() -> void:
	_show_information("MY PROGRESS", "Stages 1, 2, and 3 are available to play. More challenges are coming soon.")


func _show_information(title_text: String, details: String) -> void:
	_clear()
	_top_bar.show()
	_bottom_bar.show()
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 380
	panel.add_theme_stylebox_override("panel", _style(Color("282038"), C_COPPER, 24, 30))
	_body.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	panel.add_child(stack)
	stack.add_child(_label(title_text, 30, C_INK, true))
	stack.add_child(_label(details, 17, C_MUTED, true))
	var back := _button("← Back to Home", true, 190, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_home)
	stack.add_child(back)

func _show_language_select() -> void:
	var scene := _entry_canvas("EntryLanguageScreen")
	var tint := ColorRect.new()
	tint.color = Color(0.91, 0.96, 1.0, 0.29)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_entry_add(scene, tint, Rect2(0, 0, 1100, 650))
	var title := _entry_centered_label("Kitchen", 59, Rect2(255, 65, 590, 76), Color("2679b1"), scene)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color("133e73"))
	var subtitle := _entry_centered_label("Decoration Game", 42, Rect2(222, 134, 652, 60), Color("ffffff"), scene)
	subtitle.add_theme_constant_override("outline_size", 7)
	subtitle.add_theme_color_override("font_outline_color", Color("154373"))
	# Simple architectural sketch placed below the title, not a chef's hat.
	var blueprint := EntryKitchenSketch.new()
	blueprint.name = "LanguageKitchenDiagram"
	blueprint.set_meta("entry_kitchen_art", true)
	_entry_add(scene, blueprint, Rect2(361, 196, 390, 191))

	var panel := _glass(Color("eaf5ff"), Color("8bbce2"), 23, 0)
	panel.name = "LanguageDropdownPanel"
	panel.set_meta("entry_language_panel", true)
	_entry_add(scene, panel, Rect2(391, 386, 320, 192))
	var choose_title := _entry_centered_label("Select language", 21, Rect2(418, 397, 266, 30), Color("245f91"), scene)
	choose_title.set_meta("language_heading", true)
	var menu := OptionButton.new()
	menu.name = "EntryLanguageDropdown"
	menu.set_meta("entry_language_dropdown", true)
	menu.custom_minimum_size = Vector2(267, 47)
	menu.add_theme_font_size_override("font_size", 20)
	menu.add_theme_color_override("font_color", Color("234a79"))
	menu.add_theme_color_override("font_hover_color", Color("234a79"))
	menu.add_theme_stylebox_override("normal", _console_style(Color("f7fcff"), Color("82bce8"), 16, 7))
	menu.add_theme_stylebox_override("hover", _console_style(Color("ffffff"), Color("438fc8"), 16, 7))
	menu.add_theme_stylebox_override("pressed", _console_style(Color("dcefff"), Color("438fc8"), 16, 7))
	menu.add_item("日本語", 0)
	menu.add_item("မြန်မာ", 1)
	menu.add_item("English (Coming Soon)", 2)
	menu.set_item_disabled(2, true)
	menu.select(1 if Progress.get_language() == "mm" else 0)
	_entry_add(scene, menu, Rect2(418, 433, 266, 47))
	var go := Button.new()
	go.name = "LanguageContinue"
	go.set_meta("entry_language_continue", true)
	go.text = "Continue  ›"
	go.add_theme_font_size_override("font_size", 18)
	go.add_theme_color_override("font_color", Color("ffffff"))
	go.add_theme_stylebox_override("normal", _console_style(Color("348bd0"), Color("b2e7ff"), 17, 7))
	go.add_theme_stylebox_override("hover", _console_style(Color("1d6fae"), Color("e5f6ff"), 17, 7))
	go.pressed.connect(func() -> void:
		_choose_language("mm" if menu.selected == 1 else "jp")
	)
	_entry_add(scene, go, Rect2(418, 494, 266, 48))
	scene.modulate.a = 0.0
	var enter := create_tween()
	enter.tween_property(scene, "modulate:a", 1.0, 0.40)

func _choose_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()
	_show_levels()

func _show_achievements() -> void:
	_clear()
	_top_bar.visible = false
	_bottom_bar.visible = false
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("282038"), C_COPPER, 22, 28))
	_body.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	stack.add_child(_label("ACHIEVEMENTS", 30, C_INK, true))
	stack.add_child(_label("Stage progress is earned by completing in-game challenges.", 17, C_MUTED, true))
	stack.add_child(_label("Stage 1: " + ("Cleared ✓" if Progress.is_level_unlocked(2) else "Not yet cleared"), 19, C_MINT, true))
	stack.add_child(_label("More achievements will appear as new stages are released.", 15, C_MUTED, true))
	var back := _button("Back to Home", true, 200, 44)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_home)
	stack.add_child(back)

func _home_tile(caption_text: String, graphic: Texture2D, primary: bool, action: Callable) -> Button:
	var tile := Button.new()
	tile.text = ""
	tile.custom_minimum_size = Vector2(158, 98)
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.add_theme_stylebox_override("normal", _tile_style(primary, false))
	tile.add_theme_stylebox_override("hover", _tile_style(primary, true))
	tile.add_theme_stylebox_override("pressed", _tile_style(primary, true))
	tile.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD, 14, 0))
	tile.pressed.connect(action)
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 4)
	tile.add_child(contents)
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_top = 8
	contents.offset_bottom = -8
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	var img := TextureRect.new()
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.texture = graphic
	img.custom_minimum_size = Vector2(31, 31)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contents.add_child(img)
	var txt := _label(caption_text, 14, WHITE if primary else INK, true)
	txt.autowrap_mode = TextServer.AUTOWRAP_OFF
	contents.add_child(txt)
	return tile


func _tile_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style := _style((GREEN_DARK if hovered else GREEN) if primary else (Color("f5fbf7") if hovered else WHITE), GREEN if primary else Color("ede9e1"), 14, 9)
	# Small shadow and one-pixel border keep the button edge crisp in Web export.
	style.shadow_color = Color(0.25, 0.20, 0.12, 0.10)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	return style

func _level_row(n: int) -> Button:
	var active: bool = n <= 3 and Progress.is_level_unlocked(n)
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(0, 75)
	button.disabled = not active
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if active else Control.CURSOR_ARROW
	button.add_theme_stylebox_override("normal", _style(Color(0.83, 0.99, 0.95, 0.83) if active else Color(0.76, 0.86, 0.84, 0.61), Color(0.93, 1, 0.98, 0.94), 18))
	button.add_theme_stylebox_override("hover", _style(Color("ffe0c2"), Color("ffbc76"), 18))
	button.add_theme_stylebox_override("pressed", _style(Color("f4c5af"), Color("d98a5d"), 18))
	button.add_theme_stylebox_override("disabled", _style(Color(0.74, 0.84, 0.83, 0.53), Color(0.88, 0.97, 0.94, 0.50), 18))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("ffc074"), 18))
	if active:
		button.pressed.connect(_start_level.bind(n))
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 22)
	pad.add_theme_constant_override("margin_right", 22)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(pad)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 18)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(line)
	var number := _label("%02d" % n, 26, Color("9a577d") if active else Color("92819d"), true)
	number.custom_minimum_size.x = 70
	line.add_child(number)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 1)
	line.add_child(info)
	info.add_child(_label("STAGE %d" % n if active else "COMING SOON", 20, Color("75516d") if active else Color("8a7793")))
	if active:
		info.add_child(_label("Draw the LDK boundary" if n == 1 else ("Pipe Shaft Q&A  •  Explain PS to the customer" if n == 2 else "S-Class Kitchen  •  Layout and parts"), 14, Color("a78694")))
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(148, 43)
	pill.add_theme_stylebox_override("panel", _style(Color("ba6d58") if active else Color(0.7, 0.8, 0.77, 0.42), Color("ffcc91") if active else Color(0.65, 0.75, 0.72, 0.45), 22))
	line.add_child(pill)
	pill.add_child(_label("▶  PLAY" if active else "LOCKED", 17, WHITE if active else Color("9f8a9a"), true))
	return button

func _show_levels() -> void:
	_clear()
	_set_concept_background(true)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var page_header := HBoxContainer.new()
	page_header.add_theme_constant_override("separation", 14)
	_body.add_child(page_header)
	var home := _nav_button("⌂  HOME", _resume_paused if is_pause_overlay else _show_home)
	page_header.add_child(home)
	var title := _label("TRAINING MISSIONS   /   SELECT A STAGE", 24, Color("203b37"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_header.add_child(title)
	var prog := _nav_button("▥  PROGRESS", _show_progress)
	page_header.add_child(prog)

	var board := _glass(Color(1,1,1,0.83), Color("ffffff"), 29, 20)
	board.custom_minimum_size.y = 570
	_body.add_child(board)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 17)
	board.add_child(layout)
	var stage_row := HBoxContainer.new()
	stage_row.custom_minimum_size.y = 424
	stage_row.add_theme_constant_override("separation", 16)
	layout.add_child(stage_row)
	var intro := VBoxContainer.new()
	intro.custom_minimum_size.x = 228
	intro.add_theme_constant_override("separation", 12)
	stage_row.add_child(intro)
	intro.add_child(_label("T R A I N I N G   M I S S I O N S", 12, Color("3e6e66")))
	intro.add_child(_label("Select a Stage", 30, Color("1c3633")))
	intro.add_child(_label("Progress through hands-on kitchen design missions and build your skills step by step.", 15, Color("4c5755")))
	var pad := Control.new()
	pad.custom_minimum_size.y = 16
	intro.add_child(pad)
	var summary := _glass(Color(1,1,1,0.95), Color("d9e2df"), 22, 14)
	intro.add_child(summary)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	summary.add_child(stats)
	stats.add_child(_label("TRAINING PROGRESS", 14, Color("234e48")))
	stats.add_child(_label("3 / 6  STAGES AVAILABLE", 19, Color("127e68")))
	stats.add_child(_label("Stage 04–06 coming soon", 12, Color("62726f")))
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 6
	bar.value = 3
	bar.add_theme_stylebox_override("background", _console_style(Color("cfd6d5"), Color.TRANSPARENT, 10, 0))
	bar.add_theme_stylebox_override("fill", _console_style(Color("0dbd97"), Color.TRANSPARENT, 10, 0))
	stats.add_child(bar)

	var mission_area := VBoxContainer.new()
	mission_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_area.add_theme_constant_override("separation", 12)
	stage_row.add_child(mission_area)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	mission_area.add_child(actions)
	var mission_title := _label("DESIGN CHALLENGES", 16, Color("255247"))
	mission_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(mission_title)
	var left := _nav_button("‹", Callable())
	left.custom_minimum_size.x = 42
	actions.add_child(left)
	var right := _nav_button("›", Callable())
	right.custom_minimum_size.x = 42
	actions.add_child(right)

	var strip := ScrollContainer.new()
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.custom_minimum_size.y = 325
	strip.clip_contents = true
	mission_area.add_child(strip)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 13)
	strip.add_child(cards)
	for stage in range(1, 7):
		var card := _stage_card(stage)
		cards.add_child(card)
		card.modulate.a = 0.0
		var opening := create_tween()
		opening.tween_interval(float(stage-1) * 0.08)
		opening.tween_property(card, "modulate:a", 1.0, 0.40).set_trans(Tween.TRANS_SINE)
	left.pressed.connect(func() -> void: strip.scroll_horizontal = maxi(0, strip.scroll_horizontal - 250))
	right.pressed.connect(func() -> void: strip.scroll_horizontal += 250)
	mission_area.add_child(_label("‹  SCROLL TO DISCOVER ALL SIX MISSIONS  ›", 12, Color("4a7770"), true))

	var line := ColorRect.new()
	line.custom_minimum_size.y = 2
	line.color = Color("8de4cd")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(line)
	var progression := HBoxContainer.new()
	progression.alignment = BoxContainer.ALIGNMENT_CENTER
	progression.add_theme_constant_override("separation", 12)
	layout.add_child(progression)
	for stage in range(1, 7):
		var dot := _glass(Color("d9fff1") if stage <= 3 else Color("e0e4e5"), Color("70dabb") if stage <= 3 else Color("b8bdc1"), 28, 7)
		dot.custom_minimum_size = Vector2(52, 38)
		progression.add_child(dot)
		var number := _label("%02d" % stage, 13, Color("117b64") if stage <= 3 else Color("7a8386"), true)
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.set_meta("stage_node", stage)
		dot.add_child(number)
		if stage < 6:
			var connector := _label("━━━━", 12, Color("79d4bc") if stage < 3 else Color("bec4c4"), true)
			connector.autowrap_mode = TextServer.AUTOWRAP_OFF
			progression.add_child(connector)
	layout.add_child(_label("STAGE 01–03  AVAILABLE      •      STAGE 04–06  COMING SOON", 12, Color("62736f"), true))
	board.modulate.a = 0.0
	var appear := create_tween()
	appear.tween_property(board, "modulate:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE)

func _stage_card(stage: int) -> Button:
	var unlocked: bool = stage <= 3 and Progress.is_level_unlocked(stage)
	var card := Button.new()
	card.set_meta("mission_stage", stage)
	card.text = ""
	card.custom_minimum_size = Vector2(218, 313)
	card.disabled = not unlocked
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	var active_background := Color(0.08,0.20,0.21,0.93)
	var locked_background := Color(0.35,0.37,0.40,0.90)
	card.add_theme_stylebox_override("normal", _console_style(active_background if unlocked else locked_background, Color("8bffe0") if unlocked else Color("aeb5b8"), 21, 5, 9))
	card.add_theme_stylebox_override("disabled", _console_style(locked_background, Color("adb0b2"), 21, 5, 1))
	card.add_theme_stylebox_override("hover", _console_style(Color("165a50"), Color("c5ffea"), 21, 5, 16))
	card.add_theme_stylebox_override("pressed", _console_style(Color("10735e"), Color("e4fff1"), 21, 5, 4))
	if unlocked:
		card.pressed.connect(_start_level.bind(stage))
		ConsoleAnimations.animate_button(card)

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 9)
	pad.add_theme_constant_override("margin_right", 9)
	pad.add_theme_constant_override("margin_top", 8)
	pad.add_theme_constant_override("margin_bottom", 8)
	card.add_child(pad)
	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 5)
	pad.add_child(body)
	var state := _label("▶  AVAILABLE" if unlocked else "▣  LOCKED", 12, Color("afffe7") if unlocked else Color("eeeeee"), true)
	body.add_child(state)
	var preview := TextureRect.new()
	var thumbnails: Array[Texture2D] = [
		preload("res://reference_sketch.png"),
		preload("res://MenuAssets/Level2.png"),
		preload("res://MenuAssets/Level3.png"),
		preload("res://MenuAssets/Level4.png"),
		preload("res://MenuAssets/Level5.png"),
		preload("res://MenuAssets/Level6.png")
	]
	preview.texture = thumbnails[stage - 1]
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(193, 138)
	preview.modulate = Color.WHITE if unlocked else Color("b4b6bb")
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(preview)
	body.add_child(_label("STAGE %02d" % stage, 13, Color("d5ffef") if unlocked else Color("e9e9ec")))
	var names: Array[String] = [
		"LDK Boundary Drawing", "Pipe Shaft Q&A", "S-Class Kitchen Selection",
		"Island Layout Planning", "Lighting & Atmosphere", "Final Kitchen Design"
	]
	var name := _label(names[stage-1], 16, Color("ffffff") if unlocked else Color("e7e5e7"), true)
	name.custom_minimum_size.y = 40
	body.add_child(name)
	var action_line := _label("✦  START MISSION" if unlocked else "COMING SOON", 12, Color("9dffe0") if unlocked else Color("d7d7db"), true)
	action_line.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.add_child(action_line)
	return card

func _mission_card(stage: int) -> PanelContainer:
	var unlocked: bool = Progress.is_level_unlocked(stage)
	var card := _c_panel(Color("282038") if unlocked else Color("30283e"), C_MINT if unlocked else Color("61546b"), 12, 8)
	card.custom_minimum_size.y = 87
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var number := _label("%02d" % stage, 27, C_COPPER if unlocked else LOCKED, true)
	number.custom_minimum_size.x = 40
	row.add_child(number)
	var image_preview := TextureRect.new()
	image_preview.texture = preload("res://reference_sketch.png") if stage == 1 else (preload("res://MenuAssets/Level2.png") if stage == 2 else preload("res://MenuAssets/Level3.png"))
	image_preview.custom_minimum_size = Vector2(124, 62)
	image_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(image_preview)
	var description := VBoxContainer.new()
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.alignment = BoxContainer.ALIGNMENT_CENTER
	description.add_theme_constant_override("separation", 4)
	row.add_child(description)
	description.add_child(_label("STAGE %02d" % stage, 17, C_INK if unlocked else LOCKED))
	description.add_child(_label("Draw the LDK boundary" if stage == 1 else ("PS Q&A  ·  Customer conversation" if stage == 2 else "S-Class kitchen selection"), 13, C_MUTED))
	var action := _button("▶  PLAY" if unlocked else "LOCKED", unlocked, 116, 39)
	action.disabled = not unlocked
	if unlocked:
		action.pressed.connect(_start_level.bind(stage))
	row.add_child(action)
	return card

func _locked_card(stage: int) -> PanelContainer:
	var card := _c_panel(Color(0.14, 0.18, 0.19, 0.91), Color("62576b"), 12, 8)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 43
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	card.add_child(line)
	line.add_child(_label("%02d" % stage, 20, Color("958b9b")))
	var txt := _label("LOCKED  •  COMING SOON", 12, Color("a8a0ad"))
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(txt)
	return card

func _resume_paused() -> void:
	if is_pause_overlay:
		resume_requested.emit()
	else:
		_show_home()


func _show_help() -> void:
	_clear()
	_top_bar.visible = true
	_bottom_bar.visible = true
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_body.add_child(_label("HOW TO PLAY", 31, C_INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("282038"), C_COPPER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 18)
	panel.add_child(contents)
	contents.add_child(_label("01  LISTEN TO THE CUSTOMER", 19, C_MINT))
	contents.add_child(_label("Choose Japanese or Myanmar, listen to the customer and review the layout request.", 16, C_MUTED))
	contents.add_child(_label("02  DRAW THE REQUESTED PLAN", 19, C_MINT))
	contents.add_child(_label("Use the grid tools to sketch the requested walls and press OK to check your layout.", 16, C_MUTED))
	contents.add_child(_label("03  ANSWER THE CUSTOMER", 19, C_MINT))
	contents.add_child(_label("Finish Level 1 to unlock the Pipe Shaft Q&A in Level 2.", 16, C_MUTED))
	contents.add_child(_label("Progress and language selection are saved on this device.", 14, C_MUTED))
	var go := _button("BACK TO HOME", true, 190, 46)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_home)
	contents.add_child(go)


func _show_settings() -> void:
	_reset_armed = false
	_clear()
	_body.add_child(_label("SETTINGS", 31, C_INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("282038"), C_COPPER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 20)
	panel.add_child(contents)
	contents.add_child(_label("LANGUAGE", 18, C_MINT))
	var languages := HBoxContainer.new()
	contents.add_child(languages)
	var japanese := _button("日本語", false, 140, 48)
	japanese.pressed.connect(func() -> void: _set_language("jp"))
	languages.add_child(japanese)
	var myanmar := _button("မြန်မာ", false, 140, 48)
	myanmar.pressed.connect(func() -> void: _set_language("mm"))
	languages.add_child(myanmar)
	contents.add_child(_label("GAME VOLUME", 18, C_MINT))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = _volume_value
	volume.custom_minimum_size = Vector2(300, 36)
	volume.value_changed.connect(_on_volume_changed)
	contents.add_child(volume)
	contents.add_child(_label("SAVED GAME PROGRESS", 18, C_MINT))
	contents.add_child(_label("Resetting progress will lock Level 2 until you complete Level 1 again.", 14, C_MUTED))
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
	var db: float = -80.0 if value <= 0.001 else linear_to_db(value)
	AudioServer.set_bus_volume_db(0, db)


func _start_level(level: int) -> void:
	if level > 3 or not Progress.is_level_unlocked(level):
		return
	Progress.launch_from_level_menu = (level == 1)
	if is_pause_overlay:
		get_tree().paused = false
	var target: String = "res://main.tscn" if level == 1 else ("res://stage_2.tscn" if level == 2 else "res://stage_3.tscn")
	var result: Error = get_tree().change_scene_to_file(target)
	if result != OK:
		Progress.launch_from_level_menu = false
		if is_pause_overlay:
			get_tree().paused = true
		push_error("Failed to open level: " + target)
