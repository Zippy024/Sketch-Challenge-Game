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
	bg.add_theme_stylebox_override("panel", _style(BG, BG, 0))
	add_child(bg)
	var back_photo := TextureRect.new()
	back_photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg")
	back_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back_photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	back_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(back_photo)
	back_photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var veil := ColorRect.new()
	veil.color = Color(0.45, 0.90, 0.82, 0.05)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bg.add_child(outer)
	var top := PanelContainer.new()
	top.custom_minimum_size.y = 62
	_top_bar = top
	top.add_theme_stylebox_override("panel", _style(Color(0.87, 1.0, 0.97, 0.85), Color(1, 1, 1, 0.85), 14, 0))
	outer.add_child(top)
	var header_margin := MarginContainer.new()
	for side in ["left", "right"]:
		header_margin.add_theme_constant_override("margin_" + side, 24)
	header_margin.add_theme_constant_override("margin_top", 7)
	header_margin.add_theme_constant_override("margin_bottom", 7)
	top.add_child(header_margin)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header_margin.add_child(header)
	var mark := TextureRect.new()
	mark.custom_minimum_size = Vector2(42, 42)
	mark.texture = preload("res://Branding/SketchChallengeLogo.png")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(mark)
	var brand := _label("Kitchen Layout Game", 20, INK)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	_jp_button = _button("日本語", false, 83, 38)
	_mm_button = _button("မြန်မာ", false, 83, 38)
	for b in [_jp_button, _mm_button]:
		b.add_theme_font_size_override("font_size", 13)
		header.add_child(b)
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
	_update_lang_buttons()
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_bottom", 11)
	_scroll.add_child(margin)
	var aligner := HBoxContainer.new()
	aligner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(aligner)
	var left_gutter := Control.new()
	left_gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aligner.add_child(left_gutter)
	_body = VBoxContainer.new()
	_body.custom_minimum_size.x = 1040
	_body.add_theme_constant_override("separation", 10)
	aligner.add_child(_body)
	var right_gutter := Control.new()
	right_gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aligner.add_child(right_gutter)
	var footer := PanelContainer.new()
	footer.custom_minimum_size.y = 25
	_bottom_bar = footer
	footer.add_theme_stylebox_override("panel", _style(Color(0.86, 1.0, 0.97, 0.75), BORDER, 0))
	outer.add_child(footer)
	footer.add_child(_label("SKETCH CHALLENGE  •  DRAW  /  DESIGN  /  LEARN", 10, MUTED, true))

func _fit_content() -> void:
	if _body != null:
		_body.custom_minimum_size.x = minf(1300.0, maxf(320.0, size.x - 52.0))

func _set_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()


func _update_lang_buttons() -> void:
	for b in [_jp_button, _mm_button]:
		var selected: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm")
		b.add_theme_stylebox_override("normal", _style(GREEN if selected else WHITE, GREEN if selected else BORDER, 10, 7))
		b.add_theme_color_override("font_color", WHITE if selected else INK)
		b.add_theme_color_override("font_hover_color", WHITE if selected else GREEN)


func _clear() -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_scroll.scroll_vertical = 0


# V8: The background is only a photograph. All headings, card graphics,
# language buttons and actions are genuine Godot Controls (not screenshot text).
func _show_home() -> void:
	_clear()
	_top_bar.visible = false
	_bottom_bar.visible = false
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var hero := PanelContainer.new()
	hero.custom_minimum_size.y = 665
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", _style(Color(0.03, 0.29, 0.27, 0.035), Color(1, 1, 1, 0.15), 22))
	_body.add_child(hero)
	var stage := Control.new()
	stage.custom_minimum_size.y = 665
	hero.add_child(stage)
	var glass := PanelContainer.new()
	glass.anchor_left = 0.035
	glass.anchor_top = 0.04
	glass.anchor_right = 0.73
	glass.anchor_bottom = 0.96
	glass.add_theme_stylebox_override("panel", _style(Color(0.025, 0.31, 0.29, 0.80), Color(0.72, 1, 0.94, 0.65), 26, 18))
	stage.add_child(glass)
	var padding := MarginContainer.new()
	for side in ["left", "right"]:
		padding.add_theme_constant_override("margin_" + side, 18)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	glass.add_child(padding)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	padding.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 20)
	stack.add_child(heading)
	var logo := TextureRect.new()
	logo.texture = preload("res://MenuAssets/v8_house_white.png")
	logo.custom_minimum_size = Vector2(112, 112)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(logo)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	heading.add_child(titles)
	var title1 := _label("Kitchen", 49, WHITE)
	title1.autowrap_mode = TextServer.AUTOWRAP_OFF
	titles.add_child(title1)
	var title2 := _label("Layout Game", 49, Color("79ffe2"))
	title2.autowrap_mode = TextServer.AUTOWRAP_OFF
	titles.add_child(title2)
	stack.add_child(_label("DRAW  •  DESIGN  •  LEARN", 19, Color("eafff9"), true))
	var description := _label("Learn kitchen planning through real customer requests.\nDraw floor plans, design layouts, and build your skills step by step.", 15, Color("ebfff9"), true)
	stack.add_child(description)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(gap)
	var start := _button("▶  Start Game", true, 330, 62)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 22)
	start.add_theme_stylebox_override("normal", _style(Color("00a890"), Color("85ffdf"), 28, 10))
	start.add_theme_stylebox_override("hover", _style(Color("008775"), Color("b6fff3"), 28, 10))
	start.pressed.connect(_show_language_select)
	stack.add_child(start)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	stack.add_child(actions)
	for label in ["How to Play", "Settings", "Achievements"]:
		var b := _button(label, false, 150, 48)
		b.add_theme_stylebox_override("normal", _style(Color(0.65, 0.94, 0.88, 0.38), Color(0.90, 1, 1, 0.72), 20, 9))
		b.add_theme_color_override("font_color", WHITE)
		b.add_theme_color_override("font_hover_color", GREEN_DARK)
		if label == "How to Play":
			b.pressed.connect(_show_help)
		elif label == "Settings":
			b.pressed.connect(_show_settings)
		else:
			b.pressed.connect(_show_achievements)
		actions.add_child(b)
	if is_pause_overlay:
		var resume := _button("← BACK TO GAME", false, 168, 41)
		resume.position = Vector2(0, 0)
		resume.anchor_left = 1.0
		resume.anchor_right = 1.0
		resume.offset_left = -195
		resume.offset_right = -22
		resume.offset_top = 20
		resume.offset_bottom = 61
		resume.pressed.connect(_resume_paused)
		stage.add_child(resume)

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
	var available: bool = n <= 2 and Progress.is_level_unlocked(n)
	var future: bool = n >= 3
	var row := Button.new()
	row.text = ""
	row.custom_minimum_size = Vector2(0, 61)
	row.disabled = not available
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	var fill := Color(0.86, 1.0, 0.97, 0.88) if available else Color(0.92, 0.96, 0.95, 0.73)
	row.add_theme_stylebox_override("normal", _style(fill, Color(1, 1, 1, 0.81), 16))
	row.add_theme_stylebox_override("hover", _style(Color("d1fff1"), Color("34d3b0"), 16))
	row.add_theme_stylebox_override("pressed", _style(Color("c1fce8"), GREEN, 16))
	row.add_theme_stylebox_override("disabled", _style(fill, Color(1, 1, 1, 0.55), 16))
	row.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GREEN, 16))
	if available:
		row.pressed.connect(_start_level.bind(n))
	var inner := MarginContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("margin_left", 14)
	inner.add_theme_constant_override("margin_right", 14)
	inner.add_theme_constant_override("margin_top", 4)
	inner.add_theme_constant_override("margin_bottom", 4)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(inner)
	var line := HBoxContainer.new()
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_theme_constant_override("separation", 18)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(line)
	var number := _label("%02d" % n, 23, GREEN_DARK if available else LOCKED, true)
	number.custom_minimum_size.x = 65
	line.add_child(number)
	var text_col := VBoxContainer.new()
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.add_theme_constant_override("separation", 1)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(text_col)
	text_col.add_child(_label(("Stage %d" % n) if not future else "Coming Soon", 19 if not future else 17, INK if available else MUTED))
	if not future:
		text_col.add_child(_label("Draw the LDK boundary" if n == 1 else "PS Q&A · Explain PS to the customer", 12, MUTED))
	var action := _label("▶ PLAY" if available else "🔒", 16, GREEN_DARK if available else MUTED, true)
	action.custom_minimum_size.x = 102
	line.add_child(action)
	return row

func _show_levels() -> void:
	_clear()
	_top_bar.visible = false
	_bottom_bar.visible = false
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var glass := PanelContainer.new()
	glass.custom_minimum_size.y = 603
	glass.add_theme_stylebox_override("panel", _style(Color(0.70, 0.95, 0.91, 0.75), Color(1, 1, 1, 0.84), 26, 20))
	_body.add_child(glass)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	glass.add_child(stack)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 15)
	stack.add_child(row)
	var back := _button("← Back to Game" if is_pause_overlay else "← Back", false, 154, 44)
	back.pressed.connect(_resume_paused if is_pause_overlay else _show_home)
	row.add_child(back)
	var title := _label("⌂  Select a Level", 30, INK, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var available_count := 2 if Progress.is_level_unlocked(2) else 1
	row.add_child(_label("%d / 6 Available" % available_count, 14, GREEN_DARK, true))
	stack.add_child(_label("Choose any available stage to play.", 16, MUTED, true))
	var gap := Control.new()
	gap.custom_minimum_size.y = 7
	stack.add_child(gap)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color(0.88, 1, 0.97, 0.49), Color(1, 1, 1, 0.93), 21, 17))
	stack.add_child(card)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 9)
	card.add_child(list)
	for n in range(1, 7):
		list.add_child(_level_row(n))
	if is_pause_overlay:
		var home := _button("Home", false, 130, 37)
		home.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		home.pressed.connect(_show_home)
		stack.add_child(home)

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
	if level > 2 or not Progress.is_level_unlocked(level):
		return
	Progress.launch_from_level_menu = (level == 1)
	if is_pause_overlay:
		get_tree().paused = false
	var target: String = "res://main.tscn" if level == 1 else "res://stage_2.tscn"
	var result: Error = get_tree().change_scene_to_file(target)
	if result != OK:
		Progress.launch_from_level_menu = false
		if is_pause_overlay:
			get_tree().paused = true
		push_error("Failed to open level: " + target)
