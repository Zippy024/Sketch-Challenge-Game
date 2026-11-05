extends Control

# V8: native interactive menu over a clean kitchen-background photo. Level list is text-only.
# Compatible with the existing Stage 1/2 scenes, saved progression and pause/resume.
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")

const BG := Color("dcece7")
const WHITE := Color("ffffff")
const INK := Color("152f32")
const MUTED := Color("647780")
const GREEN := Color("008c76")
const GREEN_DARK := Color("006858")
const GREEN_PALE := Color("c9f7ea")
const BORDER := Color("d6e0e0")
const GOLD := Color("d5ac72")
const LOCKED := Color("a3afb4")

var is_pause_overlay: bool = false
var pause_level: int = 0
var _body: VBoxContainer
var _top_bar: Control
var _bottom_bar: Control
var _jp_button: Button
var _mm_button: Button
var _scroll: ScrollContainer
var _volume_value: float = 0.85
var _reset_armed: bool = false
var _reference_layer: Control
var _reference_canvas: Control
const REF_SIZE := Vector2(1672.0, 941.0)
const REF_HOME := preload("res://MenuAssets/MenuReferenceHome.webp")
const REF_LEVELS := preload("res://MenuAssets/MenuReferenceLevels.webp")


func _ready() -> void:
	theme = BilingualTheme
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame()
	resized.connect(_fit_content)
	resized.connect(_sync_reference_layout)
	_fit_content()
	if is_pause_overlay or Progress.show_levels_on_open:
		Progress.show_levels_on_open = false
		_show_levels()
	else:
		_show_home()


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
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", WHITE if primary else INK)
	b.add_theme_color_override("font_hover_color", WHITE if primary else GREEN)
	b.add_theme_color_override("font_pressed_color", WHITE if primary else GREEN)
	b.add_theme_stylebox_override("normal", _style(GREEN if primary else WHITE, GREEN if primary else BORDER, 12, 9))
	b.add_theme_stylebox_override("hover", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 9))
	b.add_theme_stylebox_override("pressed", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 9))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD, 12, 0))
	return b


func _build_frame() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _style(Color("d0e7e0"), Color("d0e7e0"), 0))
	add_child(bg)
	var photo := TextureRect.new()
	photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var colorwash := ColorRect.new()
	colorwash.color = Color(0.04, 0.20, 0.18, 0.30)
	colorwash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(colorwash)
	colorwash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	bg.add_child(outer)
	var top := PanelContainer.new()
	top.custom_minimum_size.y = 76
	_top_bar = top
	top.add_theme_stylebox_override("panel", _style(Color(0.02, 0.26, 0.24, 0.83), Color(0.63, 1, 0.90, 0.35), 0, 0))
	outer.add_child(top)
	var header_pad := MarginContainer.new()
	header_pad.add_theme_constant_override("margin_left", 28)
	header_pad.add_theme_constant_override("margin_right", 28)
	header_pad.add_theme_constant_override("margin_top", 10)
	header_pad.add_theme_constant_override("margin_bottom", 10)
	top.add_child(header_pad)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header_pad.add_child(header)
	var logo := TextureRect.new()
	logo.texture = preload("res://Branding/SketchChallengeLogo.png")
	logo.custom_minimum_size = Vector2(52, 52)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(logo)
	var brand := _label("Kitchen Layout Game", 23, WHITE)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	_jp_button = _button("日本語", false, 100, 42)
	_mm_button = _button("မြန်မာ", false, 105, 42)
	for language_button in [_jp_button, _mm_button]:
		language_button.add_theme_font_size_override("font_size", 15)
		header.add_child(language_button)
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
	_update_lang_buttons()
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	outer.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 25)
	_scroll.add_child(margin)
	var aligner := HBoxContainer.new()
	aligner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(aligner)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 15)
	aligner.add_child(_body)
	var footer := PanelContainer.new()
	_bottom_bar = footer
	footer.custom_minimum_size.y = 22
	footer.add_theme_stylebox_override("panel", _style(Color(0.02, 0.24, 0.22, 0.65), Color(0.36, 0.86, 0.75, 0.25), 0, 0))
	outer.add_child(footer)
	footer.add_child(_label("SKETCH CHALLENGE    •    DRAW / DESIGN / LEARN", 10, Color("d6fff2"), true))

func _fit_content() -> void:
	if _body != null:
		_body.custom_minimum_size.x = minf(1350.0, maxf(320.0, size.x - 60.0))

func _set_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()


func _update_lang_buttons() -> void:
	for b in [_jp_button, _mm_button]:
		if not is_instance_valid(b):
			continue
		var selected: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm")
		b.add_theme_stylebox_override("normal", _style(Color("008f78") if selected else Color(0.72, 1, 0.94, 0.19), Color("70ffdf") if selected else Color(0.78, 1, 0.95, 0.75), 24, 7))
		b.add_theme_stylebox_override("hover", _style(Color("00b593"), Color("aaffec"), 24, 7))
		b.add_theme_color_override("font_color", WHITE)
		b.add_theme_color_override("font_hover_color", WHITE)

func _clear() -> void:
	if is_instance_valid(_reference_layer):
		_reference_layer.queue_free()
	_reference_layer = null
	_reference_canvas = null
	_scroll.show()
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_scroll.scroll_vertical = 0


# V8: The background is only a photograph. All headings, card graphics,
# language buttons and actions are genuine Godot Controls (not screenshot text).
func _show_home() -> void:
	_clear()
	_top_bar.show()
	_bottom_bar.show()
	_scroll.show()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var layout := HBoxContainer.new()
	layout.custom_minimum_size.y = 680
	layout.add_theme_constant_override("separation", 25)
	_body.add_child(layout)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 810
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color(0.73, 0.95, 0.91, 0.79), Color(0.92, 1.0, 0.98, 0.97), 32, 27))
	layout.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 13)
	panel.add_child(content)
	var heading_logo := TextureRect.new()
	heading_logo.texture = preload("res://Branding/SketchChallengeLogo.png")
	heading_logo.custom_minimum_size = Vector2(106, 106)
	heading_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heading_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading_logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(heading_logo)
	var heading := _label("Kitchen Layout Game", 43, Color("064e46"), true)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	content.add_child(_label("DRAW   •   DESIGN   •   LEARN", 21, Color("007c6e"), true))
	var text := _label("Learn kitchen planning through real customer requests.\nDraw floor plans, design layouts, and build your skills step by step.", 17, Color("2d5053"), true)
	content.add_child(text)
	var expanding := Control.new()
	expanding.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(expanding)
	var start := _button("▶   Start Game", true, 335, 72)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 26)
	start.add_theme_stylebox_override("normal", _style(Color("00a68c"), Color("75ffe4"), 28, 12))
	start.add_theme_stylebox_override("hover", _style(Color("007d6a"), Color("b2fff2"), 28, 12))
	start.pressed.connect(_show_language_select)
	content.add_child(start)
	var row_one := HBoxContainer.new()
	row_one.alignment = BoxContainer.ALIGNMENT_CENTER
	row_one.add_theme_constant_override("separation", 10)
	content.add_child(row_one)
	_add_home_button(row_one, "How to Play", _show_help)
	_add_home_button(row_one, "Settings", _show_settings)
	_add_home_button(row_one, "Player Profile", _show_profile)
	var row_two := HBoxContainer.new()
	row_two.alignment = BoxContainer.ALIGNMENT_CENTER
	row_two.add_theme_constant_override("separation", 10)
	content.add_child(row_two)
	_add_home_button(row_two, "My Progress", _show_progress)
	_add_home_button(row_two, "Achievements", _show_achievements)
	if is_pause_overlay:
		var back := _button("← Back to Game", true, 190, 45)
		back.pressed.connect(_resume_paused)
		content.add_child(back)
	var right_space := Control.new()
	right_space.custom_minimum_size.x = 80
	right_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(right_space)


func _add_home_button(parent: HBoxContainer, label_text: String, action: Callable) -> void:
	var b := _button(label_text, false, 195, 60)
	b.add_theme_stylebox_override("normal", _style(Color(0.70, 0.98, 0.93, 0.74), Color(1, 1, 1, 0.97), 20, 12))
	b.add_theme_stylebox_override("hover", _style(Color("befff0"), Color("19c7a7"), 20, 12))
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
	panel.add_theme_stylebox_override("panel", _style(Color(0.80, 1, 0.95, 0.88), WHITE, 24, 30))
	_body.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 24)
	panel.add_child(stack)
	stack.add_child(_label(title_text, 30, INK, true))
	stack.add_child(_label(details, 17, MUTED, true))
	var back := _button("← Back to Home", true, 190, 48)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_home)
	stack.add_child(back)

func _show_language_select() -> void:
	_clear()
	_top_bar.visible = false
	_bottom_bar.visible = false
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var area := CenterContainer.new()
	area.custom_minimum_size.y = 665
	_body.add_child(area)
	var glass := PanelContainer.new()
	glass.custom_minimum_size = Vector2(860, 480)
	glass.add_theme_stylebox_override("panel", _style(Color(0.83, 1.0, 0.96, 0.78), Color(1, 1, 1, 0.91), 28, 30))
	area.add_child(glass)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 16)
	glass.add_child(stack)
	stack.add_child(_label("◉", 39, GREEN_DARK, true))
	stack.add_child(_label("Select Language", 37, INK, true))
	stack.add_child(_label("Please choose your language.", 18, MUTED, true))
	var space := Control.new()
	space.custom_minimum_size.y = 18
	stack.add_child(space)
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 22)
	stack.add_child(choices)
	var jp := _button("JP   日本語   ›", false, 300, 95)
	jp.add_theme_font_size_override("font_size", 25)
	jp.pressed.connect(func() -> void: _choose_language("jp"))
	choices.add_child(jp)
	var mm := _button("MM   မြန်မာ   ›", true, 300, 95)
	mm.add_theme_font_size_override("font_size", 25)
	mm.pressed.connect(func() -> void: _choose_language("mm"))
	choices.add_child(mm)
	var back := _button("← Back", false, 130, 38)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_home)
	stack.add_child(back)

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
	panel.add_theme_stylebox_override("panel", _style(Color(0.82, 1, 0.95, 0.89), WHITE, 22, 28))
	_body.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	stack.add_child(_label("ACHIEVEMENTS", 30, INK, true))
	stack.add_child(_label("Stage progress is earned by completing in-game challenges.", 17, MUTED, true))
	stack.add_child(_label("Stage 1: " + ("Cleared ✓" if Progress.is_level_unlocked(2) else "Not yet cleared"), 19, GREEN_DARK, true))
	stack.add_child(_label("More achievements will appear as new stages are released.", 15, MUTED, true))
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
	button.add_theme_stylebox_override("hover", _style(Color("b6fff0"), Color("4bffdd"), 18))
	button.add_theme_stylebox_override("pressed", _style(Color("a8ffe6"), Color("00bc9a"), 18))
	button.add_theme_stylebox_override("disabled", _style(Color(0.74, 0.84, 0.83, 0.53), Color(0.88, 0.97, 0.94, 0.50), 18))
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("3af2ca"), 18))
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
	var number := _label("%02d" % n, 26, Color("006c5e") if active else Color("64827f"), true)
	number.custom_minimum_size.x = 70
	line.add_child(number)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 1)
	line.add_child(info)
	info.add_child(_label("STAGE %d" % n if active else "COMING SOON", 20, Color("064e46") if active else Color("607a77")))
	if active:
		info.add_child(_label("Draw the LDK boundary" if n == 1 else ("Pipe Shaft Q&A  •  Explain PS to the customer" if n == 2 else "S-Class Kitchen  •  Layout and parts"), 14, Color("436866")))
	var pill := PanelContainer.new()
	pill.custom_minimum_size = Vector2(148, 43)
	pill.add_theme_stylebox_override("panel", _style(Color("008e77") if active else Color(0.7, 0.8, 0.77, 0.42), Color("6ff5d3") if active else Color(0.65, 0.75, 0.72, 0.45), 22))
	line.add_child(pill)
	pill.add_child(_label("▶  PLAY" if active else "LOCKED", 17, WHITE if active else Color("567570"), true))
	return button

func _show_levels() -> void:
	_clear()
	_top_bar.show()
	_bottom_bar.show()
	_scroll.show()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var heading_bar := HBoxContainer.new()
	heading_bar.add_theme_constant_override("separation", 14)
	_body.add_child(heading_bar)
	var back := _button("← Back to Game" if is_pause_overlay else "← Back to Home", false, 195, 48)
	back.add_theme_stylebox_override("normal", _style(Color(0.67, 0.96, 0.89, 0.88), Color("adfff0"), 24, 9))
	back.pressed.connect(_resume_paused if is_pause_overlay else _show_home)
	heading_bar.add_child(back)
	var heading := _label("SELECT A LEVEL", 34, WHITE, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_bar.add_child(heading)
	var status := _button("●   3 / 3 AVAILABLE", true, 190, 46)
	status.disabled = true
	status.add_theme_stylebox_override("disabled", _style(Color("007c68"), Color("83ffe0"), 24, 10))
	status.add_theme_color_override("font_disabled_color", WHITE)
	heading_bar.add_child(status)
	_body.add_child(_label("Choose any available stage to play.", 17, Color("e9fff8"), true))
	var guide := _button("Mission Guide", true, 235, 52)
	guide.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	guide.pressed.connect(_show_help)
	_body.add_child(guide)
	var list_panel := PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", _style(Color(0.70, 0.94, 0.89, 0.77), Color(0.90, 1, 0.97, 0.93), 28, 23))
	_body.add_child(list_panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 11)
	list_panel.add_child(list)
	for n in range(1, 7):
		list.add_child(_level_row(n))

func _sync_reference_layout() -> void:
	if not is_instance_valid(_reference_canvas):
		return
	var factor: float = minf(size.x / REF_SIZE.x, size.y / REF_SIZE.y)
	_reference_canvas.size = REF_SIZE
	_reference_canvas.scale = Vector2(factor, factor)
	_reference_canvas.position = (size - REF_SIZE * factor) * 0.5


func _reference_button(hit_area: Rect2, action: Callable) -> void:
	if not is_instance_valid(_reference_canvas):
		return
	var hit := Button.new()
	hit.text = ""
	hit.position = hit_area.position
	hit.size = hit_area.size
	hit.mouse_filter = Control.MOUSE_FILTER_STOP
	hit.focus_mode = Control.FOCUS_NONE
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var clear := _style(Color.TRANSPARENT, Color.TRANSPARENT, 16)
	var hover := _style(Color(0.0, 0.93, 0.73, 0.12), Color(0.72, 1, 0.91, 0.38), 16)
	hit.add_theme_stylebox_override("normal", clear)
	hit.add_theme_stylebox_override("hover", hover)
	hit.add_theme_stylebox_override("pressed", hover)
	hit.add_theme_stylebox_override("focus", clear)
	hit.pressed.connect(action)
	_reference_canvas.add_child(hit)


func _show_reference_screen(levels: bool) -> void:
	_top_bar.hide()
	_bottom_bar.hide()
	_scroll.hide()
	_reference_layer = Control.new()
	_reference_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_reference_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_reference_layer)
	var letterbox := ColorRect.new()
	letterbox.color = Color("dceee9")
	letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reference_layer.add_child(letterbox)
	_reference_canvas = Control.new()
	_reference_canvas.custom_minimum_size = REF_SIZE
	_reference_canvas.size = REF_SIZE
	_reference_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	_reference_layer.add_child(_reference_canvas)
	var picture := TextureRect.new()
	picture.texture = REF_LEVELS if levels else REF_HOME
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.size = REF_SIZE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reference_canvas.add_child(picture)
	_sync_reference_layout()
	call_deferred("_sync_reference_layout")
	if levels:
		_reference_button(Rect2(103, 142, 222, 63), _resume_paused if is_pause_overlay else _show_home)
		_reference_button(Rect2(338, 145, 66, 65), _show_home)
		_reference_button(Rect2(688, 246, 282, 65), _show_help)
		_reference_button(Rect2(1285, 30, 145, 61), _set_language.bind("jp"))
		_reference_button(Rect2(1433, 30, 150, 61), _set_language.bind("mm"))
		# Entire stage row is clickable, not only its PLAY region.
		_reference_button(Rect2(134, 350, 1388, 92), _start_level.bind(1))
		_reference_button(Rect2(134, 441, 1388, 82), _start_level.bind(2))
		_reference_button(Rect2(134, 526, 1388, 79), _start_level.bind(3))
	else:
		_reference_button(Rect2(1352, 32, 277, 71), _resume_paused if is_pause_overlay else _show_levels)
		_reference_button(Rect2(133, 505, 286, 151), _show_language_select)
		_reference_button(Rect2(431, 504, 245, 151), _show_help)
		_reference_button(Rect2(681, 504, 239, 151), _show_settings)
		_reference_button(Rect2(131, 671, 255, 96), _show_achievements)
		_reference_button(Rect2(390, 671, 263, 96), _show_levels)
		_reference_button(Rect2(660, 671, 259, 96), _show_achievements)


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
	contents.add_child(_label("Finish Level 1 to unlock the Pipe Shaft Q&A in Level 2.", 16, MUTED))
	contents.add_child(_label("Progress and language selection are saved on this device.", 14, MUTED))
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
	contents.add_child(_label("SAVED GAME PROGRESS", 18, GREEN))
	contents.add_child(_label("Resetting progress will lock Level 2 until you complete Level 1 again.", 14, MUTED))
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
