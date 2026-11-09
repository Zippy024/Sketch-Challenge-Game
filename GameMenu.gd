extends Control
<<<<<<< Updated upstream

# Concept C — Modern Training Console. Native Godot controls, no screenshot-based buttons.
# Stage 1/2/3 game scripts and answer evaluation remain unchanged.
=======
# Reference-matched blue/cyan desktop UI. Stage 1/2/3 logic remains in original files.
# All selectable cards and controls are native Godot UI, not screenshots.
>>>>>>> Stashed changes
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")
<<<<<<< Updated upstream
const ConsoleAnimations = preload("res://ConceptCAnimations.gd")
const SunsetSparkles = preload("res://MenuAssets/SunsetSparkles.gd")
const KitchenHologram = preload("res://MenuAssets/OptionCHologram.gd")
const EntryKitchenSketch = preload("res://MenuAssets/EntryKitchenSketch.gd")
const BlueprintMissionMap = preload("res://MenuAssets/BlueprintMissionMap.gd")
const KitchenDiorama3D = preload("res://MenuAssets/KitchenDiorama3D.gd")
const FlatBlueBackdrop = preload("res://MenuAssets/FlatBlueBackdrop.gd")
const ShowroomGlow = preload("res://MenuAssets/ShowroomGlow.gd")

const BG := Color("0b2e55")
const WHITE := Color("ffffff")
const INK := Color("eafaff")
const MUTED := Color("b6dcf2")
const GREEN := Color("00b8e2")
const GREEN_DARK := Color("0674bc")
const GREEN_PALE := Color("193e66")
const BORDER := Color("528ebd")
const GOLD := Color("5deaff")
const C_DARK := Color("0b294e")
const C_PANEL := Color("123d66")
const C_INK := Color("eaf9ff")
const C_MUTED := Color("b4daee")
const C_COPPER := Color("68eaff")
const C_MINT := Color("70defa")
const LOCKED := Color("849cb4")
=======
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
>>>>>>> Stashed changes

var is_pause_overlay: bool = false
var pause_level: int = 0
var _body: VBoxContainer
var _menu_photo: TextureRect
var _top_bar: Control
var _bottom_bar: Control
var _jp_button: Button
var _mm_button: Button
var _scroll: ScrollContainer
var _top: Control
var _bottom: Control
var _volume_value: float = 0.85
var _reset_armed: bool = false
<<<<<<< Updated upstream
var _selected_level: int = 3
=======
var _stats_reset_armed: bool = false
var _chosen_stage: int = 1
var _loading_tween: Tween
var _menu_backdrop: TextureRect
>>>>>>> Stashed changes


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
<<<<<<< Updated upstream
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
=======
		if OS.has_feature("web"):
			_show_language() # HTML shell already displayed the loading sequence.
		else:
			_show_loading()
>>>>>>> Stashed changes


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
<<<<<<< Updated upstream
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(min_w, min_h)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("ffffff"))
	button.add_theme_color_override("font_hover_color", Color("ffffff"))
	button.add_theme_color_override("font_pressed_color", Color("ffffff"))
	var body_color := Color("07b5db") if primary else Color("194b79")
	var border_color := Color("a3f4ff") if primary else Color("7ec4f0")
	button.add_theme_stylebox_override("normal", _console_style(body_color, border_color, 22, 8, 4))
	button.add_theme_stylebox_override("hover", _console_style(Color("04d3f4") if primary else Color("256ca0"), Color("e2fbff"), 22, 8, 10))
	button.add_theme_stylebox_override("pressed", _console_style(Color("0878b7"), Color("b3f0ff"), 22, 8, 2))
	button.add_theme_stylebox_override("disabled", _console_style(Color("697b91"), Color("9eb6c7"), 22, 8))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("d4faff"), 22))
	ConsoleAnimations.animate_button(button)
	return button
=======
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
>>>>>>> Stashed changes

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
	var button := _button(title, false, 122, 39)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color("143c69"))
	button.add_theme_color_override("font_hover_color", Color("085c94"))
	button.add_theme_color_override("font_pressed_color", Color("085c94"))
	button.add_theme_stylebox_override("normal", _console_style(Color("eaf8ff"), Color("aedff7"), 19, 5, 2))
	button.add_theme_stylebox_override("hover", _console_style(Color("c9f3ff"), Color("4dd6fb"), 19, 5, 7))
	button.add_theme_stylebox_override("pressed", _console_style(Color("b6e9fa"), Color("3cbfe9"), 19, 5, 1))
	if not callback.is_null():
		button.pressed.connect(callback)
	return button

func _build_frame() -> void:
<<<<<<< Updated upstream
	var base := Control.new()
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# NEW illustration (not reused old photo): one full-viewport background
	# for Loading, Language, Home and Level Select, no nested background.
	var backdrop := TextureRect.new()
	backdrop.name = "PhotoLikeBlueKitchenBackdrop"
	backdrop.set_meta("showroom_background", true)
	backdrop.set_meta("reference_style_background", true)
	backdrop.texture = preload("res://MenuAssets/BlueKitchenPhotoClean.jpeg")
=======
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := TextureRect.new()
	backdrop.texture = preload("res://MenuAssets/LoadingBackground.png")
>>>>>>> Stashed changes
	_menu_backdrop = backdrop
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
<<<<<<< Updated upstream
	backdrop.modulate = Color.WHITE
	base.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var light := ColorRect.new()
	light.color = Color(0.86, 0.96, 1.0, 0.015)
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(light)
	light.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	base.add_child(outer)
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_top_bar = _glass(Color("f0faff"), Color("b4e9ff"), 0, 3)
	_top_bar.custom_minimum_size.y = 67
	_top_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	outer.add_child(_top_bar)
	var head_pad := MarginContainer.new()
	head_pad.add_theme_constant_override("margin_left", 17)
	head_pad.add_theme_constant_override("margin_right", 17)
	head_pad.add_theme_constant_override("margin_top", 2)
	head_pad.add_theme_constant_override("margin_bottom", 2)
	_top_bar.add_child(head_pad)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	head_pad.add_child(header)
	var emblem := TextureRect.new()
	emblem.texture = preload("res://Branding/SketchPlanPencil.svg")
	emblem.custom_minimum_size = Vector2(53,53)
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(emblem)
	var brand := _label("KITCHEN DECORATION GAME", 18, Color("0e4677"))
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var home_btn := _nav_button("⌂  HOME", _show_home)
	home_btn.custom_minimum_size.x = 113
	header.add_child(home_btn)
	var level_btn := _nav_button("▦  ALL STAGES", _show_levels)
	level_btn.custom_minimum_size.x = 131
	header.add_child(level_btn)
	var guide_btn := _nav_button("▤  GUIDE", _show_help)
	guide_btn.custom_minimum_size.x = 119
	header.add_child(guide_btn)
	var prog_btn := _nav_button("▥  PROGRESS", _show_progress)
	prog_btn.custom_minimum_size.x = 130
	header.add_child(prog_btn)
	var trainee := _glass(Color("184d78"), Color("77d7fa"), 22, 8)
	trainee.custom_minimum_size.x = 104
	header.add_child(trainee)
	var trainee_text := _label("TRAINEE", 12, C_INK, true)
	trainee_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	trainee.add_child(trainee_text)
	_jp_button = _button("日本語", false, 73, 37)
	_mm_button = _button("မြန်မာ", false, 73, 37)
	for lang_btn in [_jp_button, _mm_button]:
		lang_btn.add_theme_font_size_override("font_size", 12)
		header.add_child(lang_btn)
=======
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
>>>>>>> Stashed changes
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
	_update_lang_buttons()

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
<<<<<<< Updated upstream
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
=======
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
>>>>>>> Stashed changes
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.clip_contents = true
	outer.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
<<<<<<< Updated upstream
	margin.add_theme_constant_override("margin_left", 17)
	margin.add_theme_constant_override("margin_right", 17)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 8)
	_scroll.add_child(margin)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 13)
	margin.add_child(_body)
	_bottom_bar = _glass(Color("0a3158"), Color("81ddfa"), 0, 1)
	_bottom_bar.custom_minimum_size.y = 23
	_bottom_bar.size_flags_vertical = Control.SIZE_SHRINK_END
	outer.add_child(_bottom_bar)
	var footer := _label("DESIGN  •  SKETCH  •  SELECT MATERIALS  •  LEARN", 11, C_INK, true)
	footer.autowrap_mode = TextServer.AUTOWRAP_OFF
	_bottom_bar.add_child(footer)
=======
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
>>>>>>> Stashed changes

func _set_concept_background(_choose_levels: bool) -> void:
	# Background is deliberately the same photo-free blue theme on every
	# menu screen. Stage 1–3 have their own unchanged scenes.
	pass

func _fit_content() -> void:
	if _body != null:
<<<<<<< Updated upstream
		_body.custom_minimum_size.x = 0.0
=======
		_body.custom_minimum_size.x = 1320.0

>>>>>>> Stashed changes

func _set_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()


func _update_lang_buttons() -> void:
	if _jp_button == null or _mm_button == null:
		return
	for b in [_jp_button, _mm_button]:
<<<<<<< Updated upstream
		if not is_instance_valid(b):
			continue
		var selected: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm")
		b.add_theme_stylebox_override("normal", _console_style(Color("047daf") if selected else Color("21527a"), Color("9defff") if selected else Color("adcfe1"), 12, 6))
		b.add_theme_stylebox_override("hover", _console_style(Color("159acb"), Color("d4faff"), 12, 6))
		b.add_theme_color_override("font_color", WHITE)

func _clear() -> void:
	_set_concept_background(false)
	_scroll.show()
	_top_bar.show()
	_bottom_bar.show()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
=======
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
>>>>>>> Stashed changes
	_scroll.scroll_vertical = 0
	_scroll.scroll_horizontal = 0

func _entry_background() -> void:
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Shared FlatBlueBackdrop stays visible behind all entry screens.

<<<<<<< Updated upstream
# User-selected artwork; fallback stays available until the images are uploaded.
var _menu_backdrop: TextureRect

func _set_entry_background(screen_name: String) -> void:
	if not is_instance_valid(_menu_backdrop):
		return
	var path := "res://MenuAssets/Sunny Cozy Kitchen Interior.png"
	if screen_name == "EntryLoadingScreen":
		path = "res://MenuAssets/Modern Blue-White Kitchen Interior.png"
	if ResourceLoader.exists(path):
		_menu_backdrop.texture = load(path)
	else:
		_menu_backdrop.texture = preload("res://MenuAssets/BlueKitchenPhotoClean.jpeg")

func _entry_canvas(name_value: String) -> Control:
	_set_entry_background(name_value)
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


func _showroom_photo(_parent: Control, _rect: Rect2, _vivid: bool = false) -> void:
	# All four screens already share the one fullscreen BlueKitchenFreshV1
	# layer in _build_frame. Do NOT add another image inside entry content.
	pass

func _showroom_title(parent: Control, left: float, top: float, width_value: float, _size_large: int = 50) -> void:
	# A single glossy rolled-blueprint & pencil logo from the selected
	# reference artwork. Text is baked into this logo, never shown twice.
	var logo := TextureRect.new()
	logo.name = "GlossyBlueprintPencilLogo"
	logo.set_meta("reference_game_logo", true)
	logo.texture = preload("res://MenuAssets/KitchenLogoGlossy.webp")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var on_home: bool = top >= 50.0
	var logo_width: float = minf(width_value, 515.0 if on_home else 560.0)
	var logo_height: float = logo_width * 0.41
	var logo_y: float = top - 24.0 if on_home else maxf(1.0, top - 12.0)
	_ui_put(parent, logo, Rect2(left + (width_value - logo_width)*0.5, logo_y, logo_width, logo_height))

func _show_splash() -> void:
	var canvas := _entry_canvas("EntryLoadingScreen")
	_showroom_photo(canvas,Rect2(0,0,1100,650))
	_showroom_title(canvas,220,27,665,60)
	var subtitle := _ui_text(canvas,"KITCHEN DESIGN ADVENTURE",15,Rect2(350,146,400,28),Color("154d7b"),true)
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var podium := ShowroomGlow.new()
	podium.name = "LoadingGlowingPlatform"
	_ui_put(canvas,podium,Rect2(131,325,838,236))
	var viewport_box := SubViewportContainer.new()
	viewport_box.name = "EntryIsometricKitchen"
	viewport_box.set_meta("entry_kitchen_art",true)
	viewport_box.stretch = true
	viewport_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,viewport_box,Rect2(180,163,740,369))
	var kitchen_view := KitchenDiorama3D.new()
	kitchen_view.mission = 1
	viewport_box.add_child(kitchen_view)
	var bar := ProgressBar.new()
	bar.name = "EntryLoadingProgress"
	bar.custom_minimum_size = Vector2(444,18)
	bar.show_percentage = false
	bar.max_value = 100
	bar.value = 0
	bar.add_theme_stylebox_override("background", _console_style(Color("c6e2f4"),Color("6caed7"),13,1))
	bar.add_theme_stylebox_override("fill", _console_style(Color("1bcbeb"),Color("d6fbff"),13,1))
	_ui_put(canvas,bar,Rect2(328,561,444,17))
	_ui_text(canvas,"Loading...",16,Rect2(400,587,300,30),Color("174b77"),true)
	canvas.modulate.a = 0.0
	create_tween().tween_property(canvas,"modulate:a",1.0,0.4)
	var loading := create_tween()
	loading.tween_property(bar,"value",100.0,1.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	loading.tween_callback(func() -> void:
		if is_inside_tree() and is_instance_valid(canvas):
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


func _blueprint_canvas(page_name: String) -> Control:
	_clear()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var root := Control.new()
	root.name = page_name + "Root"
	root.custom_minimum_size = Vector2(1320, 648)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(root)
	var stage := Control.new()
	stage.name = page_name
	root.add_child(stage)
	stage.anchor_left = 0.5
	stage.anchor_right = 0.5
	stage.anchor_top = 0.0
	stage.anchor_bottom = 0.0
	stage.offset_left = -660
	stage.offset_right = 660
	stage.offset_top = 0
	stage.offset_bottom = 648
	return stage


func _ui_put(parent: Control, child: Control, region: Rect2) -> void:
	parent.add_child(child)
	child.position = region.position
	child.size = region.size


func _ui_text(parent: Control, words: String, size_px: int, region: Rect2, color: Color, center: bool = false) -> Label:
	var label := _label(words, size_px, color, center)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ui_put(parent, label, region)
	return label


func _select_map_stage(stage: int) -> void:
	if stage > 3 or not Progress.is_level_unlocked(stage):
		return
	_selected_level = stage
	_show_levels()


func _map_stage_card(stage: int) -> Button:
	var available: bool = stage <= 3 and Progress.is_level_unlocked(stage)
	var selected: bool = available and stage == _selected_level
	var width_value := 194.0 if selected else 174.0
	var height_value := 335.0 if selected else 284.0
	var card := Button.new()
	card.name = "ShowroomStage%02d" % stage
	card.set_meta("mission_stage",stage)
	card.set_meta("showroom_stage_card",true)
	card.custom_minimum_size = Vector2(width_value,height_value)
	card.text = ""
	card.disabled = not available
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	card.add_theme_stylebox_override("normal",_console_style(Color("f0faff") if available else Color("cad3df"),Color("34deff") if selected else Color("9ecbdf"),20,0,15 if selected else 4))
	card.add_theme_stylebox_override("hover",_console_style(Color("f7fdff"),Color("66eaff"),20,0,14))
	card.add_theme_stylebox_override("pressed",_console_style(Color("ceeefa"),Color("5cd9f9"),20,0,3))
	card.add_theme_stylebox_override("disabled",_console_style(Color("b5c7d7"),Color("a4b3c3"),20,0,3))
	if available:
		card.pressed.connect(_select_map_stage.bind(stage))
		ConsoleAnimations.animate_button(card)

	var head := _glass(Color("08618c") if selected else (Color("135d81") if available else Color("41596f")),Color("70eaff") if selected else Color("92b9d2"),16,0)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(card,head,Rect2(1,1,width_value-2,44 if selected else 40))
	var t := _ui_text(card,("▶  STAGE %02d" if selected else "STAGE %02d") % stage,16 if selected else 14,Rect2(9,7,width_value-18,32),Color("ffffff"),true)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var photo := TextureRect.new()
	var textures: Array[Texture2D] = [
		preload("res://reference_sketch.png"),
		preload("res://MenuAssets/Level2.png"),
		preload("res://MenuAssets/Level3.png"),
		preload("res://MenuAssets/Level4.png"),
		preload("res://MenuAssets/Level5.png"),
		preload("res://MenuAssets/Level6.png")
	]
	photo.texture = textures[stage-1]
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo.modulate = Color.WHITE if available else Color("9ba6b2")
	_ui_put(card,photo,Rect2(7,47,width_value-14,160 if selected else 132))
	var photo_border := _glass(Color.TRANSPARENT,Color("b4d8eb"),7,0)
	photo_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(card,photo_border,Rect2(7,47,width_value-14,160 if selected else 132))
	var names: Array[String] = [
		"LDK Boundary", "Pipe Shaft", "S-Class Kitchen",
		"Island Layout", "Lighting &", "Final Kitchen"
	]
	var sub: Array[String] = [
		"Drawing", "Q&A", "Selection", "Planning", "Atmosphere", "Design"
	]
	var title_y := 216.0 if selected else 190.0
	var cap := _ui_text(card,names[stage-1],16 if selected else 14,Rect2(6,title_y,width_value-12,24),Color("0b3559") if available else Color("41556b"),true)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sec := _ui_text(card,sub[stage-1],15 if selected else 14,Rect2(6,title_y+24,width_value-12,23),Color("0b3559") if available else Color("41556b"),true)
	sec.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if selected:
		var play := _button("▶  PLAY   »",true,width_value-31,50)
		play.name = "SelectedMissionPlay"
		play.set_meta("mission_play",true)
		play.add_theme_font_size_override("font_size",18)
		play.pressed.connect(_start_level.bind(stage))
		_ui_put(card,play,Rect2(15,height_value-61,width_value-30,51))
	elif available:
		var ready := _ui_text(card,"●  AVAILABLE",12,Rect2(4,height_value-31,width_value-8,20),Color("0476a4"),true)
		ready.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		var lock_status := _glass(Color("37617c"),Color("8bafc1"),15,0)
		lock_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_put(card,lock_status,Rect2(18,height_value-38,width_value-36,29))
		var locked := _ui_text(card,"▣  LOCKED",12,Rect2(18,height_value-34,width_value-36,20),Color("f6fbff"),true)
		locked.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card

func _show_home() -> void:
	var canvas := _blueprint_canvas("OptionCHomeCanvas")
	_top_bar.hide()
	_bottom_bar.hide()
	_showroom_photo(canvas,Rect2(0,0,1320,638))
	# Reference image: bright left content zone and visible warm kitchen on right.
	# Keep the same brand-new fullscreen illustration visible on the right.
	# No inset/split duplicate background and no legacy kitchen images.
	var right_glow := ColorRect.new()
	right_glow.color = Color(0.89,0.97,1.0,0.035)
	right_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,right_glow,Rect2(713,0,607,638))
	var left_wash := ColorRect.new()
	left_wash.color = Color(0.88,0.97,1.0,0.35)
	left_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,left_wash,Rect2(0,0,723,638))
	var edge := ColorRect.new()
	edge.color = Color(0.31,0.73,0.95,0.22)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,edge,Rect2(710,0,3,638))
	var hero := _glass(Color(0.94,0.98,1,0.07),Color.TRANSPARENT,24,0)
	hero.name = "HomeHeroGlass"
	hero.set_meta("home_hero_panel",true)
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,hero,Rect2(22,24,675,573))
	_showroom_title(canvas,58,58,630,62)
	var headline := _ui_text(canvas,"DESIGN  •  SKETCH  •  SELECT",15,Rect2(145,214,442,26),Color("1a5c87"),true)
	headline.name = "HomeHeadline"
	headline.set_meta("home_headline",true)
	var start := _button("▶   START GAME",true,363,65)
	start.name = "HomeStartTraining"
	start.set_meta("home_start_button",true)
	start.add_theme_font_size_override("font_size",22)
	start.pressed.connect(_show_levels)
	_ui_put(canvas,start,Rect2(173,259,365,65))
	var select_level := _nav_button("▦   SELECT LEVEL",_show_levels)
	select_level.add_theme_font_size_override("font_size",19)
	_ui_put(canvas,select_level,Rect2(173,342,365,59))
	var guide := _nav_button("▤   GAME GUIDE",_show_help)
	guide.add_theme_font_size_override("font_size",19)
	_ui_put(canvas,guide,Rect2(173,418,365,59))
	var settings := _nav_button("⚙   SETTINGS",_show_settings)
	settings.add_theme_font_size_override("font_size",19)
	_ui_put(canvas,settings,Rect2(173,494,365,59))
	var trainee := _glass(Color("123b61"),Color("7ddaf3"),24,0)
	trainee.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,trainee,Rect2(1110,26,160,46))
	_ui_text(canvas,"◉  TRAINEE",15,Rect2(1119,34,142,30),Color("e1faff"),true)
	var features := _glass(Color(0.05,0.25,0.48,0.13),Color("a8f1ff"),24,0)
	features.name = "HomeFeaturesGlass"
	features.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,features,Rect2(760,138,510,386))
	if is_pause_overlay:
		var resume := _nav_button("←  BACK TO GAME",_resume_paused)
		_ui_put(canvas,resume,Rect2(193,572,320,43))
	canvas.modulate.a = 0
	create_tween().tween_property(canvas,"modulate:a",1.0,0.43)
=======
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
>>>>>>> Stashed changes

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
	panel.add_theme_stylebox_override("panel", _style(Color("0f3964"), C_COPPER, 24, 30))
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
	var canvas := _entry_canvas("EntryLanguageScreen")
	# Match the approved reference: large game logo, broad glass panel,
	# full-width dropdown and a visible Continue below the opened menu.
	var logo := TextureRect.new()
	logo.name = "ReferenceGlossyLanguageLogo"
	logo.texture = preload("res://MenuAssets/KitchenLogoGlossy.webp")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.set_meta("reference_game_logo",true)
	_ui_put(canvas,logo,Rect2(302,0,496,206))

	var panel := _glass(Color(0.94,0.98,1.0,0.95),Color("8ae9ff"),32,9)
	panel.name = "LanguageDropdownPanel"
	panel.set_meta("entry_language_panel",true)
	_ui_put(canvas,panel,Rect2(314,210,472,349))
	_ui_text(canvas,"Select Language",27,Rect2(335,226,430,43),Color("0a1c58"),true)

	var menu := OptionButton.new()
	menu.name = "EntryLanguageDropdown"
	menu.set_meta("entry_language_dropdown",true)
	menu.custom_minimum_size = Vector2(399,65)
	menu.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu.add_theme_font_size_override("font_size",27)
	for theme_color in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		menu.add_theme_color_override(theme_color,Color("071d56"))
	menu.add_theme_color_override("font_disabled_color",Color("9199a6"))
	menu.add_theme_stylebox_override("normal",_console_style(Color("ffffff"),Color("67d9ff"),31,17,7))
	menu.add_theme_stylebox_override("hover",_console_style(Color("ffffff"),Color("28caff"),31,17,8))
	menu.add_theme_stylebox_override("pressed",_console_style(Color("eaf8ff"),Color("28caff"),31,17,4))
	menu.add_theme_stylebox_override("focus",_console_style(Color.TRANSPARENT,Color("4fcff5"),31,0,0))
	var popup := menu.get_popup()
	popup.add_theme_stylebox_override("panel",_console_style(Color("ffffff"),Color("9cdbff"),22,9,8))
	popup.add_theme_stylebox_override("hover",_console_style(Color("2e9cf3"),Color("b4eaff"),5,12,0))
	popup.add_theme_color_override("font_color",Color("081e55"))
	popup.add_theme_color_override("font_hover_color",Color("ffffff"))
	popup.add_theme_color_override("font_disabled_color",Color("a0a4ad"))
	popup.add_theme_color_override("font_separator_color",Color("081e55"))
	popup.add_theme_font_size_override("font_size",25)
	popup.add_theme_constant_override("v_separation",12)
	popup.add_theme_constant_override("h_separation",15)
	menu.add_item("日本語",0)
	menu.add_item("မြန်မာ",1)
	menu.add_item("English (Coming Soon)",2)
	menu.set_item_disabled(2,true)
	menu.select(1 if Progress.get_language()=="mm" else 0)
	_ui_put(canvas,menu,Rect2(350,274,400,65))

	var continue_button := _button("Continue    »",true,322,69)
	continue_button.name = "LanguageContinue"
	continue_button.set_meta("entry_language_continue",true)
	continue_button.add_theme_font_size_override("font_size",29)
	continue_button.add_theme_stylebox_override("normal",_console_style(Color("0086ad"),Color("0de7f2"),37,12,9))
	continue_button.add_theme_stylebox_override("hover",_console_style(Color("00b5c9"),Color("9afaff"),37,12,12))
	continue_button.add_theme_stylebox_override("pressed",_console_style(Color("006b98"),Color("73edff"),37,12,3))
	continue_button.pressed.connect(func() -> void:
		_choose_language("mm" if menu.selected==1 else "jp")
	)
	# Below the panel, not covered by its expanded three-item dropdown.
	_ui_put(canvas,continue_button,Rect2(389,538,322,70))
	canvas.modulate.a = 0
	create_tween().tween_property(canvas,"modulate:a",1.0,0.30)

func _choose_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()
	_show_home()

func _show_achievements() -> void:
	_clear()
	_top_bar.visible = false
	_bottom_bar.visible = false
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("0f3964"), C_COPPER, 22, 28))
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

<<<<<<< Updated upstream
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
	var canvas := _blueprint_canvas("ShowroomLevelsCanvas")
	_top_bar.hide()
	_bottom_bar.hide()
	_showroom_photo(canvas,Rect2(0,0,1320,638))
	# One luminous showroom, not a dense dashboard or 3D room carousel.
	var overlay := ColorRect.new()
	overlay.color = Color(0.76,0.90,1.0,0.18)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,overlay,Rect2(0,0,1320,637))
	var brand_image := TextureRect.new()
	brand_image.texture = preload("res://Branding/SketchPlanPencil.svg")
	brand_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,brand_image,Rect2(25,13,74,74))
	var brand := _ui_text(canvas,"Kitchen Decoration Game",22,Rect2(105,29,328,40),Color("0a3f73"))
	brand.add_theme_constant_override("outline_size",1)
	brand.add_theme_color_override("font_outline_color",Color("eefbff"))
=======

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

>>>>>>> Stashed changes

	var home := _nav_button("⌂  HOME", _resume_paused if is_pause_overlay else _show_home)
	_ui_put(canvas,home,Rect2(448,17,141,43))
	var stages_btn := _button("▦  SELECT LEVEL",true,164,43)
	stages_btn.add_theme_font_size_override("font_size",14)
	stages_btn.pressed.connect(_show_levels)
	_ui_put(canvas,stages_btn,Rect2(596,17,165,43))
	var guide := _nav_button("▤  GUIDE",_show_help)
	_ui_put(canvas,guide,Rect2(768,17,136,43))
	var progress := _nav_button("▥  PROGRESS",_show_progress)
	_ui_put(canvas,progress,Rect2(911,17,144,43))
	var trainee := _glass(Color("0c3d69"),Color("8ee8fc"),23,0)
	trainee.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,trainee,Rect2(1098,17,181,43))
	_ui_text(canvas,"◉  TRAINEE",15,Rect2(1111,25,151,25),Color("e6faff"),true)

	var heading := _ui_text(canvas,"Select a Stage",34,Rect2(411,86,500,48),Color("0a315c"),true)
	heading.add_theme_constant_override("outline_size",2)
	heading.add_theme_color_override("font_outline_color",Color("e6f8ff"))
	_ui_text(canvas,"Progress through kitchen design missions step by step.",15,Rect2(393,135,535,29),Color("204c76"),true)
	var holo := KitchenHologram.new()
	holo.modulate.a = 0.20
	_ui_put(canvas,holo,Rect2(960,92,319,128))
	# Under the six stage cards: blue luminous oval stage and shadows.
	var pedestal := ShowroomGlow.new()
	pedestal.name = "StageShowroomPedestal"
	pedestal.set_meta("showroom_pedestal",true)
	_ui_put(canvas,pedestal,Rect2(26,379,1268,207))

	var x_positions: Array[float] = [72.0,269.0,466.0,677.0,874.0,1071.0]
	for stage in range(1,7):
		var chosen: bool = stage == _selected_level
		var top: float = 170.0 if chosen else 214.0
		var w: float = 194.0 if chosen else 174.0
		var h: float = 335.0 if chosen else 284.0
		var card := _map_stage_card(stage)
		_ui_put(canvas,card,Rect2(x_positions[stage-1],top,w,h))
		card.modulate.a = 0.0
		var appear := create_tween()
		appear.tween_interval(float(stage-1)*0.045)
		appear.tween_property(card,"modulate:a",1.0,0.34).set_trans(Tween.TRANS_SINE)
	var left_arrow := _nav_button("❮",func() -> void:
		_select_map_stage(maxi(1,_selected_level-1))
	)
	left_arrow.custom_minimum_size = Vector2(42,55)
	left_arrow.disabled = _selected_level <= 1
	_ui_put(canvas,left_arrow,Rect2(10,353,48,55))
	var right_arrow := _nav_button("❯",func() -> void:
		_select_map_stage(mini(3,_selected_level+1))
	)
	right_arrow.disabled = _selected_level >= 3
	_ui_put(canvas,right_arrow,Rect2(1265,353,45,55))

	# Bottom horizontal progress track. 3/6 means AVAILABLE, not fake results.
	var progress_box := _glass(Color("f1faff"),Color("b8e4f8"),34,0)
	progress_box.name = "SelectedMissionPanel"
	progress_box.set_meta("mission_detail",true)
	progress_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,progress_box,Rect2(126,540,1070,78))
	_ui_text(canvas,"▤  TRAINING MISSIONS",14,Rect2(146,550,215,24),Color("10496e"))
	_ui_text(canvas,"3 / 6  AVAILABLE",19,Rect2(145,577,216,29),Color("028bb4"))
	var line := ColorRect.new()
	line.color = Color("97d6e7")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_put(canvas,line,Rect2(373,553,2,49))
	for stage in range(1,7):
		var x: float = 411.0 + float(stage-1)*143.0
		if stage < 6:
			var link_line := ColorRect.new()
			link_line.color = Color("48d0e8") if stage < 3 else Color("b8c6d2")
			link_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_ui_put(canvas,link_line,Rect2(x+38,575,104,3))
		var select: bool = stage == _selected_level
		var unlocked: bool = stage <= 3
		var node := _glass(Color("04a4c6") if select else (Color("effaff") if unlocked else Color("dce4ec")),
			Color("54e2f5") if unlocked else Color("bdc7d2"),27,0)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ui_put(canvas,node,Rect2(x,554,48,48))
		_ui_text(canvas,"%02d" % stage,17,Rect2(x+2,566,44,24),
			Color("ffffff") if select else (Color("164868") if unlocked else Color("8192a2")),true)
	# Main Play action is owned by the selected mission card, not a fake static label.

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
	var card := _c_panel(Color("0f3964") if unlocked else Color("30283e"), C_MINT if unlocked else Color("61546b"), 12, 8)
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
	panel.add_theme_stylebox_override("panel", _style(Color("0f3964"), C_COPPER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 18)
	panel.add_child(contents)
<<<<<<< Updated upstream
	contents.add_child(_label("01  LISTEN TO THE CUSTOMER", 19, C_MINT))
	contents.add_child(_label("Choose Japanese or Myanmar, listen to the customer and review the layout request.", 16, C_MUTED))
	contents.add_child(_label("02  DRAW THE REQUESTED PLAN", 19, C_MINT))
	contents.add_child(_label("Use the grid tools to sketch the requested walls and press OK to check your layout.", 16, C_MUTED))
	contents.add_child(_label("03  ANSWER THE CUSTOMER", 19, C_MINT))
	contents.add_child(_label("Finish Level 1 to unlock the Pipe Shaft Q&A in Level 2.", 16, C_MUTED))
	contents.add_child(_label("Progress and language selection are saved on this device.", 14, C_MUTED))
=======
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
>>>>>>> Stashed changes
	var go := _button("BACK TO HOME", true, 190, 46)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_home)
	contents.add_child(go)


func _show_settings() -> void:
	_reset_armed = false
	_clear()
	_body.add_child(_label("SETTINGS", 31, C_INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("0f3964"), C_COPPER, 18, 30))
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
<<<<<<< Updated upstream
	contents.add_child(_label("SAVED GAME PROGRESS", 18, C_MINT))
	contents.add_child(_label("Resetting progress will lock Level 2 until you complete Level 1 again.", 14, C_MUTED))
=======
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
>>>>>>> Stashed changes
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
