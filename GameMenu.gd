extends Control

# Concept C — Modern Training Console. Native Godot controls, no screenshot-based buttons.
# Stage 1/2/3 game scripts and answer evaluation remain unchanged.
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
const C_DARK := Color("101d1c")
const C_PANEL := Color("152825")
const C_INK := Color("f4f1e9")
const C_MUTED := Color("b6c7c1")
const C_COPPER := Color("d7ab78")
const C_MINT := Color("87d3ae")
const LOCKED := Color("a3afb4")

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
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", WHITE if primary else C_INK)
	b.add_theme_color_override("font_hover_color", WHITE)
	b.add_theme_color_override("font_pressed_color", WHITE)
	b.add_theme_stylebox_override("normal", _console_style(Color("187457") if primary else Color("20322e"), C_MINT if primary else Color("527068"), 13, 10, 3 if primary else 0))
	b.add_theme_stylebox_override("hover", _console_style(Color("238e69") if primary else Color("2c5146"), Color("baf5d7") if primary else C_MINT, 13, 10, 5))
	b.add_theme_stylebox_override("pressed", _console_style(Color("125c46") if primary else Color("254338"), C_MINT, 13, 10, 0))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, C_COPPER, 13))
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
	line.color = Color("836e52")
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return line

func _build_frame() -> void:
	var base := PanelContainer.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_theme_stylebox_override("panel", _style(C_DARK, C_DARK, 0))
	add_child(base)
	# This is a separate kitchen photograph; all controls and text are live Godot UI.
	var photo := TextureRect.new()
	photo.texture = preload("res://MenuAssets/ConceptC_Home_Background.jpg")
	_menu_photo = photo
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.043, 0.040, 0.035)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	base.add_child(outer)
	_top_bar = PanelContainer.new()
	_top_bar.custom_minimum_size.y = 65
	_top_bar.add_theme_stylebox_override("panel", _style(Color(0.05, 0.10, 0.095, 0.94), Color("5c715f"), 0))
	outer.add_child(_top_bar)
	var head_pad := MarginContainer.new()
	head_pad.add_theme_constant_override("margin_left", 30)
	head_pad.add_theme_constant_override("margin_right", 30)
	head_pad.add_theme_constant_override("margin_top", 8)
	head_pad.add_theme_constant_override("margin_bottom", 8)
	_top_bar.add_child(head_pad)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	head_pad.add_child(header)
	var brand_icon := TextureRect.new()
	brand_icon.texture = preload("res://Branding/SketchChallengeLogo.png")
	brand_icon.custom_minimum_size = Vector2(43, 43)
	brand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(brand_icon)
	var brand := _label("KITCHEN DECORATION GAME", 18, C_INK)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var badge := _label("3D DESIGN TRAINING", 12, C_COPPER)
	badge.custom_minimum_size.x = 175
	header.add_child(badge)
	_jp_button = _button("日本語", false, 90, 41)
	_mm_button = _button("မြန်မာ", false, 90, 41)
	for lang_btn in [_jp_button, _mm_button]:
		lang_btn.add_theme_font_size_override("font_size", 13)
		header.add_child(lang_btn)
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
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 23)
	margin.add_theme_constant_override("margin_bottom", 18)
	_scroll.add_child(margin)
	var align := HBoxContainer.new()
	align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(align)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.add_child(_body)
	_bottom_bar = PanelContainer.new()
	_bottom_bar.custom_minimum_size.y = 23
	_bottom_bar.add_theme_stylebox_override("panel", _style(Color(0.045, 0.10, 0.10, 0.88), Color("4c564b"), 0))
	outer.add_child(_bottom_bar)
	_bottom_bar.add_child(_label("DESIGN  /  SKETCH  /  SELECT MATERIALS  /  LEARN", 10, C_COPPER, true))

func _set_concept_background(choose_levels: bool) -> void:
	if not is_instance_valid(_menu_photo):
		return
	_menu_photo.texture = preload("res://MenuAssets/ConceptC_Levels_Background.jpg") if choose_levels else preload("res://MenuAssets/ConceptC_Home_Background.jpg")


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
		b.add_theme_stylebox_override("normal", _console_style(Color("476452") if selected else Color("20332e"), C_MINT if selected else Color("4e615b"), 12, 7))
		b.add_theme_stylebox_override("hover", _console_style(Color("345749"), C_MINT, 12, 7))
		b.add_theme_color_override("font_color", WHITE)
		b.add_theme_color_override("font_hover_color", WHITE)

func _clear() -> void:
	_set_concept_background(false)
	_scroll.show()
	_top_bar.show()
	_bottom_bar.show()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_scroll.scroll_vertical = 0

func _show_home() -> void:
	_clear()
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var stage := HBoxContainer.new()
	stage.custom_minimum_size.y = 602
	stage.add_theme_constant_override("separation", 22)
	_body.add_child(stage)
	var menu := _c_panel(Color(0.052, 0.107, 0.105, 0.92), Color("a99070"), 19, 25)
	menu.custom_minimum_size.x = 585
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stage.add_child(menu)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	menu.add_child(column)
	column.add_child(_label("KITCHEN DESIGN TRAINING", 14, C_COPPER))
	var heading := _label("Kitchen\nDecoration Game", 42, C_INK)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	column.add_child(heading)
	# Slow loop; stops automatically when leaving the intro/home page.
	var logo_pulse := create_tween().bind_node(heading).set_loops()
	logo_pulse.tween_property(heading, "modulate:a", 0.82, 1.8).set_trans(Tween.TRANS_SINE)
	logo_pulse.tween_property(heading, "modulate:a", 1.0, 1.8).set_trans(Tween.TRANS_SINE)
	column.add_child(_thin_rule())
	column.add_child(_label("SKETCH    /    CHOOSE MATERIALS    /    LEARN", 13, C_COPPER))
	column.add_child(_label("A practical kitchen design challenge.\nListen to customer requests, sketch accurate layouts,\nand learn to select the right kitchen components.", 16, C_MUTED))
	var divider := Control.new()
	divider.custom_minimum_size.y = 12
	column.add_child(divider)
	var begin := _icon_button("Start Training", preload("res://MenuAssets/play_white.png"), true, 0, 53, _show_language_select)
	begin.add_theme_font_size_override("font_size", 20)
	column.add_child(begin)
	column.add_child(_icon_button("Select a Level", preload("res://MenuAssets/levels_white.png"), false, 0, 45, _show_levels))
	column.add_child(_icon_button("Training Guide", preload("res://MenuAssets/book_white.png"), false, 0, 45, _show_help))
	column.add_child(_icon_button("My Progress", preload("res://MenuAssets/levels_white.png"), false, 0, 45, _show_progress))
	var last := HBoxContainer.new()
	last.add_theme_constant_override("separation", 9)
	column.add_child(last)
	var achievements := _button("Achievements", false, 0, 43)
	achievements.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	achievements.pressed.connect(_show_achievements)
	last.add_child(achievements)
	var settings := _icon_button("Settings", preload("res://MenuAssets/settings_white.png"), false, 0, 43, _show_settings)
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	last.add_child(settings)
	if is_pause_overlay:
		var resume := _button("← Back to Game", true, 0, 42)
		resume.pressed.connect(_resume_paused)
		column.add_child(resume)
	var photo_space := Control.new()
	photo_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_child(photo_space)

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
	panel.add_theme_stylebox_override("panel", _style(Color("192e2b"), C_COPPER, 24, 30))
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
	panel.add_theme_stylebox_override("panel", _style(Color("192e2b"), C_COPPER, 22, 28))
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
	_set_concept_background(true)
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var ribbon := HBoxContainer.new()
	ribbon.add_theme_constant_override("separation", 13)
	_body.add_child(ribbon)
	var back := _button("← Back to Game" if is_pause_overlay else "← Main Menu", false, 175, 44)
	back.pressed.connect(_resume_paused if is_pause_overlay else _show_home)
	ribbon.add_child(back)
	var heading := _label("SELECT YOUR MISSION", 31, C_INK, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ribbon.add_child(heading)
	var unlocked_count: int = 0
	for stage_id in range(1, 4):
		if Progress.is_level_unlocked(stage_id):
			unlocked_count += 1
	var state := _label("●   %d / 3 UNLOCKED" % unlocked_count, 15, C_MINT)
	state.custom_minimum_size.x = 185
	ribbon.add_child(state)
	_body.add_child(_label("Choose any available stage to play.", 15, C_INK, true))
	var guide := _button("Training Guide", false, 185, 38)
	guide.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	guide.pressed.connect(_show_help)
	_body.add_child(guide)
	var panel := _c_panel(Color(0.057, 0.102, 0.103, 0.94), Color("907758"), 20, 14)
	_body.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	panel.add_child(stack)
	stack.add_child(_label("AVAILABLE MISSIONS", 15, C_COPPER))
	var cards := VBoxContainer.new()
	cards.add_theme_constant_override("separation", 9)
	stack.add_child(cards)
	for stage in range(1, 4):
		cards.add_child(_mission_card(stage))
	stack.add_child(_thin_rule())
	stack.add_child(_label("COMING SOON", 13, C_COPPER))
	var locked := VBoxContainer.new()
	locked.add_theme_constant_override("separation", 8)
	stack.add_child(locked)
	for stage in range(4, 7):
		locked.add_child(_locked_card(stage))

func _mission_card(stage: int) -> PanelContainer:
	# Compact horizontal list rows: the preview, description and live Play action
	# remain independent controls, not part of a flattened screenshot.
	var unlocked: bool = Progress.is_level_unlocked(stage)
	var card := _c_panel(Color("192e2b") if unlocked else Color("202c2b"), Color("63877a") if unlocked else Color("4b5b56"), 14, 12)
	card.custom_minimum_size.y = 106
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 17)
	card.add_child(line)
	var number := _label("%02d" % stage, 30, C_COPPER if unlocked else LOCKED, true)
	number.custom_minimum_size.x = 46
	line.add_child(number)
	var preview := TextureRect.new()
	preview.texture = preload("res://reference_sketch.png") if stage == 1 else (preload("res://MenuAssets/Level2.png") if stage == 2 else preload("res://MenuAssets/Level3.png"))
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(170, 76)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(preview)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	line.add_child(info)
	info.add_child(_label("STAGE %02d" % stage, 19, C_INK if unlocked else LOCKED))
	var detail := "LDK Boundary Drawing" if stage == 1 else ("Pipe Shaft Q&A" if stage == 2 else "S-Class Kitchen Selection")
	info.add_child(_label(detail, 15, C_MUTED if unlocked else LOCKED))
	info.add_child(_label("AVAILABLE TO PLAY" if unlocked else "COMPLETE THE PREVIOUS STAGE TO UNLOCK", 11, C_MINT if unlocked else LOCKED))
	var play := _button("▶   PLAY" if unlocked else "LOCKED", unlocked, 150, 46)
	play.disabled = not unlocked
	if unlocked:
		play.pressed.connect(_start_level.bind(stage))
	line.add_child(play)
	return card

func _locked_card(stage: int) -> PanelContainer:
	var card := _c_panel(Color(0.14, 0.18, 0.19, 0.91), Color("4d5954"), 13, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.y = 52
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	card.add_child(line)
	var number := _label("%02d" % stage, 22, Color("89958f"))
	number.custom_minimum_size.x = 43
	line.add_child(number)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 0)
	line.add_child(copy)
	copy.add_child(_label("COMING SOON", 13, Color("b0b6ad")))
	copy.add_child(_label("Locked", 12, Color("79877f")))
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
	panel.add_theme_stylebox_override("panel", _style(Color("192e2b"), C_COPPER, 18, 30))
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
	panel.add_theme_stylebox_override("panel", _style(Color("192e2b"), C_COPPER, 18, 30))
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
