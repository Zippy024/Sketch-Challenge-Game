extends Control

# Concept C — Modern Training Console. Native Godot controls, no screenshot-based buttons.
# Stage 1/2/3 game scripts and answer evaluation remain unchanged.
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")
const ConsoleAnimations = preload("res://ConceptCAnimations.gd")
const SunsetSparkles = preload("res://MenuAssets/SunsetSparkles.gd")

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
	b.add_theme_color_override("font_color", Color("fff7ed"))
	b.add_theme_color_override("font_hover_color", Color("ffffff"))
	b.add_theme_color_override("font_pressed_color", Color("ffffff"))
	b.add_theme_stylebox_override("normal", _console_style(Color("e77844") if primary else Color(0.17,0.15,0.25,0.94), Color("ffcc83") if primary else Color("81627d"), 16, 10, 5 if primary else 2))
	b.add_theme_stylebox_override("hover", _console_style(Color("fa995b") if primary else Color("4a3258"), Color("ffe4a9"), 16, 10, 7))
	b.add_theme_stylebox_override("pressed", _console_style(Color("b8513b") if primary else Color("352239"), Color("ffbf72"), 16, 10, 1))
	b.add_theme_stylebox_override("disabled", _console_style(Color("45404e"), Color("82768b"), 16, 10))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("ffe4a9"), 16))
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
	var b := _button(title, false, 125, 37)
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_stylebox_override("normal", _console_style(Color(0.94,0.91,0.93,0.70), Color("d6a68f"), 18, 5))
	b.add_theme_stylebox_override("hover", _console_style(Color(1,0.96,0.92,0.98), Color("ec9860"), 18, 5))
	b.add_theme_color_override("font_color", Color("2d253e"))
	b.add_theme_color_override("font_hover_color", Color("251b36"))
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
	light.color = Color(0.98, 0.88, 0.91, 0.10)
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
	_top_bar = _glass(Color(1, 0.975, 0.97, 0.88), Color("fff6e4"), 0, 4)
	_top_bar.custom_minimum_size.y = 70
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
	var brand := _label("KITCHEN SKETCH CHALLENGE", 19, Color("302538"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.add_child(brand)
	header.add_child(_nav_button("HOME", _show_home))
	header.add_child(_nav_button("ALL STAGES", _show_levels))
	header.add_child(_nav_button("GAME GUIDE", _show_help))
	header.add_child(_nav_button("PROGRESS", _show_progress))
	var trainee := _glass(Color(0.18,0.13,0.24,0.82), Color("dbaf89"), 20, 7)
	header.add_child(trainee)
	var trainee_text := _label("TRAINEE  •  LEVEL 1–3", 12, C_INK, true)
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
	_bottom_bar = _glass(Color(0.19,0.14,0.24,0.85), Color("d3ad90"), 0, 1)
	_bottom_bar.custom_minimum_size.y = 25
	outer.add_child(_bottom_bar)
	_bottom_bar.add_child(_label("DESIGN  •  SKETCH  •  SELECT MATERIALS  •  LEARN", 11, C_INK, true))

func _set_concept_background(choose_levels: bool) -> void:
	if not is_instance_valid(_menu_photo):
		return
	# Warm, daylight kitchen remains legible behind glass panels.
	_menu_photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg") if not choose_levels else preload("res://MenuAssets/KitchenHero.jpg")

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
		b.add_theme_stylebox_override("normal", _console_style(Color("6e3e59") if selected else Color("2a2239"), Color("ffc98a") if selected else Color("886477"), 12, 6))
		b.add_theme_stylebox_override("hover", _console_style(Color("86516c"), Color("ffe2ad"), 12, 6))
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

func _show_splash() -> void:
	_clear()
	_top_bar.hide()
	_bottom_bar.hide()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var alignment := CenterContainer.new()
	alignment.custom_minimum_size.y = 560.0
	_body.add_child(alignment)
	var panel := _c_panel(Color(0.08, 0.055, 0.16, 0.85), Color("ffc889"), 30, 30)
	panel.custom_minimum_size = Vector2(560, 360)
	alignment.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 15)
	panel.add_child(content)
	var mark := TextureRect.new()
	mark.texture = preload("res://Branding/SketchPlanPencil.svg")
	mark.custom_minimum_size = Vector2(110, 110)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(mark)
	content.add_child(_label("KITCHEN SKETCH CHALLENGE", 30, C_COPPER, true))
	content.add_child(_label("D E C O R A T I O N   G A M E", 15, C_INK, true))
	var caption := _label("LOADING YOUR DESIGN ADVENTURE...", 13, C_MUTED, true)
	content.add_child(caption)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(440, 20)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _console_style(Color("302741"), Color("7b5063"), 12, 2))
	bar.add_theme_stylebox_override("fill", _console_style(Color("ffa44d"), Color("ffd88c"), 12, 2))
	content.add_child(bar)
	var progress := _label("0%", 13, C_COPPER, true)
	content.add_child(progress)
	panel.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(panel, "modulate:a", 1.0, 0.36)
	var load_anim := create_tween()
	load_anim.tween_property(bar, "value", 100.0, 1.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	load_anim.tween_callback(func() -> void:
		if is_inside_tree():
			_show_home()
	)
	bar.value_changed.connect(func(v: float) -> void:
		if is_instance_valid(progress):
			progress.text = "%d%%" % roundi(v)
	)


func _show_home() -> void:
	_clear()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var scene_row := HBoxContainer.new()
	scene_row.custom_minimum_size.y = 585
	scene_row.add_theme_constant_override("separation", 26)
	_body.add_child(scene_row)

	# Reference layout: bright frosted hero left, unobstructed kitchen right.
	var panel := _glass(Color(1, 0.98, 0.97, 0.86), Color("fff8ee"), 29, 29)
	panel.custom_minimum_size.x = 560
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	scene_row.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 11)
	panel.add_child(stack)
	var header_line := HBoxContainer.new()
	header_line.add_theme_constant_override("separation", 16)
	stack.add_child(header_line)
	var logo := TextureRect.new()
	logo.texture = preload("res://Branding/SketchPlanPencil.svg")
	logo.custom_minimum_size = Vector2(100,100)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_line.add_child(logo)
	var headline := VBoxContainer.new()
	headline.alignment = BoxContainer.ALIGNMENT_CENTER
	header_line.add_child(headline)
	headline.add_child(_label("KITCHEN DESIGN TRAINING", 12, Color("72516c")))
	headline.add_child(_label("Kitchen", 43, Color("292235")))
	headline.add_child(_label("Sketch Challenge", 33, Color("b85c44")))
	stack.add_child(_label("DECORATION GAME", 18, Color("674763"), true))
	var info := _label("DESIGN  •  SKETCH  •  SELECT  •  LEARN", 13, Color("634e62"), true)
	stack.add_child(info)
	stack.add_child(_label("A practical kitchen design training game. Plan layouts, answer customer questions and choose kitchen materials.", 16, Color("3f3748")))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 12
	stack.add_child(spacer)
	var start := _button("▶   START TRAINING   ››", true, 420, 60)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 22)
	start.pressed.connect(_show_language_select)
	stack.add_child(start)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 8)
	stack.add_child(actions)
	var levels := _nav_button("SELECT LEVEL", _show_levels)
	levels.custom_minimum_size.x = 142
	actions.add_child(levels)
	var help := _nav_button("TRAINING GUIDE", _show_help)
	help.custom_minimum_size.x = 150
	actions.add_child(help)
	var progress := _nav_button("MY PROGRESS", _show_progress)
	progress.custom_minimum_size.x = 132
	actions.add_child(progress)
	if is_pause_overlay:
		var resume := _button("← BACK TO GAME", false, 240, 42)
		resume.pressed.connect(_resume_paused)
		stack.add_child(resume)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 16)
	scene_row.add_child(right)
	var feature := _glass(Color(0.20,0.15,0.25,0.70), Color("f8d4a1"), 23, 22)
	feature.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(feature)
	var feature_text := VBoxContainer.new()
	feature_text.add_theme_constant_override("separation", 14)
	feature.add_child(feature_text)
	feature_text.add_child(_label("YOUR DESIGN ADVENTURE", 14, Color("ffe7b7"), true))
	feature_text.add_child(_label("✎  Sketch Layouts", 18, C_INK))
	feature_text.add_child(_label("▱  Choose Materials", 18, C_INK))
	feature_text.add_child(_label("✧  Build Design Skills", 18, C_INK))
	var sub := _glass(Color(0.98,0.94,0.96,0.84), Color("fff0dd"), 20, 14)
	sub.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(sub)
	sub.add_child(_label("3 PLAYABLE STAGES   •   MORE COMING SOON", 14, Color("58445c"), true))
	panel.modulate.a = 0.0
	var entrance := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entrance.tween_property(panel, "modulate:a", 1.0, 0.60)
	feature.modulate.a = 0.0
	var drift := create_tween()
	drift.tween_interval(0.16)
	drift.tween_property(feature, "modulate:a", 1.0, 0.60)

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
	_clear()
	var alignment := CenterContainer.new()
	alignment.custom_minimum_size.y = 610
	_body.add_child(alignment)
	var panel := _c_panel(Color(0.065, 0.15, 0.14, 0.96), C_COPPER, 24, 30)
	panel.custom_minimum_size = Vector2(680, 430)
	alignment.add_child(panel)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 17)
	panel.add_child(content)
	content.add_child(_label("01  /  SELECT LANGUAGE", 16, C_COPPER, true))
	content.add_child(_label("Choose your language", 34, C_INK, true))
	content.add_child(_label("Customer dialogue and questions are available in Japanese and Myanmar.", 16, C_MUTED, true))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	content.add_child(spacer)
	var options := HBoxContainer.new()
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	options.add_theme_constant_override("separation", 17)
	content.add_child(options)
	var jp := _button("JP   日本語", false, 260, 78)
	jp.add_theme_font_size_override("font_size", 23)
	jp.pressed.connect(func() -> void: _choose_language("jp"))
	options.add_child(jp)
	var mm := _button("MM   မြန်မာ", false, 260, 78)
	mm.add_theme_font_size_override("font_size", 23)
	mm.pressed.connect(func() -> void: _choose_language("mm"))
	options.add_child(mm)
	var go_back := _button("← Back to Menu", false, 180, 41)
	go_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	go_back.pressed.connect(_show_home)
	content.add_child(go_back)

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

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 15)
	_body.add_child(header)
	var back := _nav_button("←  HOME", _resume_paused if is_pause_overlay else _show_home)
	header.add_child(back)
	var headline := _label("TRAINING MISSIONS  /  SELECT A STAGE", 26, Color("342a3a"), true)
	headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(headline)
	var prog_btn := _nav_button("MY PROGRESS", _show_progress)
	header.add_child(prog_btn)

	var board := _glass(Color(1.0, 0.975, 0.965, 0.85), Color("fff8eb"), 28, 18)
	board.custom_minimum_size.y = 545
	_body.add_child(board)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	board.add_child(layout)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.custom_minimum_size.y = 390
	layout.add_child(row)

	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 234
	left.add_theme_constant_override("separation", 13)
	row.add_child(left)
	left.add_child(_label("KITCHEN DESIGN", 13, Color("aa6a4c")))
	left.add_child(_label("Select a Stage", 30, Color("2b2738")))
	left.add_child(_label("Progress through real kitchen design missions and build your skills step by step.", 15, Color("584a57")))
	var space := Control.new()
	space.custom_minimum_size.y = 10
	left.add_child(space)
	var summary := _glass(Color(0.99,0.93,0.91,0.94), Color("ebc7a3"), 19, 13)
	left.add_child(summary)
	var progress_col := VBoxContainer.new()
	progress_col.add_theme_constant_override("separation", 7)
	summary.add_child(progress_col)
	progress_col.add_child(_label("TRAINING PROGRESS", 14, Color("4a3346")))
	progress_col.add_child(_label("3 / 6  PLAYABLE", 21, Color("bd6b47")))
	progress_col.add_child(_label("Stages 1–3 available", 13, Color("6c5a66")))
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 12
	progress.min_value = 0
	progress.max_value = 6
	progress.value = 3
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background", _console_style(Color("d4c8cf"), Color.TRANSPARENT, 9, 0))
	progress.add_theme_stylebox_override("fill", _console_style(Color("d98655"), Color.TRANSPARENT, 9, 0))
	progress_col.add_child(progress)
	var level_guide := _glass(Color(0.19,0.14,0.25,0.92), Color("f4cc9a"), 19, 12)
	left.add_child(level_guide)
	var guide_text := VBoxContainer.new()
	guide_text.add_theme_constant_override("separation", 5)
	level_guide.add_child(guide_text)
	guide_text.add_child(_label("GAME GUIDE", 12, Color("ffcf91")))
	guide_text.add_child(_label("01  Sketch Layout", 13, C_INK))
	guide_text.add_child(_label("02  Pipe Shaft Q&A", 13, C_INK))
	guide_text.add_child(_label("03  Select Materials", 13, C_INK))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	var row_heading := HBoxContainer.new()
	right.add_child(row_heading)
	var all_label := _label("DESIGN CHALLENGES", 17, Color("433341"))
	all_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_heading.add_child(all_label)
	var left_arrow := _nav_button("‹", func() -> void: pass)
	left_arrow.custom_minimum_size.x = 40
	row_heading.add_child(left_arrow)
	var right_arrow := _nav_button("›", func() -> void: pass)
	right_arrow.custom_minimum_size.x = 40
	row_heading.add_child(right_arrow)
	var strip := ScrollContainer.new()
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.custom_minimum_size.y = 327
	strip.clip_contents = true
	right.add_child(strip)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 13)
	strip.add_child(cards)
	for stage in range(1, 7):
		var card := _stage_card(stage)
		cards.add_child(card)
		card.modulate.a = 0.0
		var intro := create_tween()
		intro.tween_interval(float(stage - 1) * 0.08)
		intro.tween_property(card, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	left_arrow.pressed.connect(func() -> void: strip.scroll_horizontal = maxi(0, strip.scroll_horizontal - 270))
	right_arrow.pressed.connect(func() -> void: strip.scroll_horizontal += 270)
	right.add_child(_label("‹  Scroll to discover more levels  ›", 12, Color("786473"), true))

	var separator := ColorRect.new()
	separator.custom_minimum_size.y = 2
	separator.color = Color("d7a777")
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(separator)
	var path := HBoxContainer.new()
	path.alignment = BoxContainer.ALIGNMENT_CENTER
	path.add_theme_constant_override("separation", 20)
	layout.add_child(path)
	for stage in range(1, 7):
		var token := _glass(Color("ffead1") if stage <= 3 else Color("d8d0d7"), Color("e09a60") if stage <= 3 else Color("aca2aa"), 30, 9)
		path.add_child(token)
		token.add_child(_label("%02d" % stage, 14, Color("a85c3e") if stage <= 3 else Color("736c77"), true))
		if stage < 6:
			path.add_child(_label("━━━━", 14, Color("cd977d") if stage < 3 else Color("b6a9b2"), true))
	layout.add_child(_label("STAGE 04—06  •  COMING SOON", 13, Color("7b6574"), true))
	board.modulate.a = 0.0
	var fade := create_tween()
	fade.tween_property(board, "modulate:a", 1.0, 0.52).set_trans(Tween.TRANS_SINE)

func _stage_card(stage: int) -> Button:
	var available: bool = stage <= 3 and Progress.is_level_unlocked(stage)
	var card := Button.new()
	card.set_meta("mission_stage", stage)
	card.text = ""
	card.custom_minimum_size = Vector2(203, 296)
	card.disabled = not available
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	var background := Color(1,0.985,0.97,0.96) if available else Color(0.69,0.66,0.69,0.91)
	card.add_theme_stylebox_override("normal", _console_style(background, Color("eeb47e") if available else Color("a49ba4"), 20, 5, 8))
	card.add_theme_stylebox_override("disabled", _console_style(background, Color("9d96a1"), 20, 5, 2))
	card.add_theme_stylebox_override("hover", _console_style(Color("fff3e6"), Color("f0a15e"), 20, 5, 13))
	card.add_theme_stylebox_override("pressed", _console_style(Color("f6dec8"), Color("df8b54"), 20, 5, 4))
	if available:
		card.pressed.connect(_start_level.bind(stage))
		ConsoleAnimations.animate_button(card)

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for margin in ["margin_left","margin_right"]:
		pad.add_theme_constant_override(margin, 10)
	for margin in ["margin_top","margin_bottom"]:
		pad.add_theme_constant_override(margin, 8)
	card.add_child(pad)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 5)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(body)
	var status := "● AVAILABLE" if available else "◆ LOCKED"
	var pill := _label(status, 12, Color("9a543c") if available else Color("665b65"), true)
	body.add_child(pill)
	var thumb := TextureRect.new()
	var textures: Array[Texture2D] = [
		preload("res://reference_sketch.png"),
		preload("res://MenuAssets/Level2.png"),
		preload("res://MenuAssets/Level3.png"),
		preload("res://MenuAssets/Level4.png"),
		preload("res://MenuAssets/Level5.png"),
		preload("res://MenuAssets/Level6.png")
	]
	thumb.texture = textures[stage - 1]
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.custom_minimum_size = Vector2(174, 153)
	thumb.modulate = Color.WHITE if available else Color("bcb2b8")
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(thumb)
	body.add_child(_label("STAGE %02d" % stage, 12, Color("8c6349") if available else Color("736872")))
	var names: Array[String] = ["LDK Boundary Drawing","Pipe Shaft Q&A","S-Class Kitchen Selection","Island Layout Planning","Lighting & Atmosphere","Final Kitchen Design"]
	var title := _label(names[stage - 1], 16, Color("2f2a36") if available else Color("635c68"), true)
	title.custom_minimum_size.y = 38
	body.add_child(title)
	body.add_child(_label("✦  PLAY MISSION" if available else "🔒  COMING SOON", 13, Color("c7794d") if available else Color("766c76"), true))
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
