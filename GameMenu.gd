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

func _build_frame() -> void:
	var base := PanelContainer.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_theme_stylebox_override("panel", _style(C_DARK, C_DARK, 0))
	add_child(base)
	var photo := TextureRect.new()
	photo.texture = preload("res://MenuAssets/ConceptC_Home_Background.jpg")
	_menu_photo = photo
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Sunset-magenta photographic grade removes green casts from the old kitchen art.
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb;
	float green_weight = clamp(col.g - max(col.r, col.b) * 0.72, 0.0, 1.0);
	col = mix(col, vec3(col.r * 0.96 + 0.12, col.r * 0.34 + 0.04, col.r * 0.76 + 0.11), green_weight * 0.88);
	vec3 blue_night = vec3(0.13, 0.085, 0.25);
	col = mix(col, blue_night, 0.32);
	col.r += (UV.y * 0.07);
	col.b += (1.0 - UV.y) * 0.09;
	COLOR = vec4(col, tex.a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	photo.material = mat
	base.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.09,0.06,0.16,0.20)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sparkles := SunsetSparkles.new()
	base.add_child(sparkles)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	base.add_child(outer)
	_top_bar = PanelContainer.new()
	_top_bar.custom_minimum_size.y = 60
	_top_bar.add_theme_stylebox_override("panel", _style(Color(0.10,0.075,0.16,0.86), Color("aa785c"), 0))
	outer.add_child(_top_bar)
	var head_pad := MarginContainer.new()
	for side in ["margin_left","margin_right"]:
		head_pad.add_theme_constant_override(side, 28)
	for side in ["margin_top","margin_bottom"]:
		head_pad.add_theme_constant_override(side, 5)
	_top_bar.add_child(head_pad)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	head_pad.add_child(header)
	var brand_icon := TextureRect.new()
	brand_icon.texture = preload("res://Branding/SketchPlanPencil.svg")
	brand_icon.custom_minimum_size = Vector2(49,49)
	brand_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brand_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	brand_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(brand_icon)
	var brand := _label("KITCHEN SKETCH CHALLENGE", 19, C_INK)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	header.add_child(_label("DESIGN  /  SKETCH  /  CHOOSE MATERIALS", 12, C_COPPER))
	_jp_button = _button("日本語", false, 82, 38)
	_mm_button = _button("မြန်မာ", false, 82, 38)
	for lang_btn in [_jp_button,_mm_button]:
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
	outer.add_child(_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	_scroll.add_child(margin)
	var align := HBoxContainer.new()
	align.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(align)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	align.add_child(_body)
	_bottom_bar = PanelContainer.new()
	_bottom_bar.custom_minimum_size.y = 26
	_bottom_bar.add_theme_stylebox_override("panel", _style(Color(0.12, 0.09, 0.18, 0.85), Color("b37763"), 0))
	outer.add_child(_bottom_bar)
	_bottom_bar.add_child(_label("KITCHEN SKETCH CHALLENGE  •  PLAN  /  SELECT  /  LEARN", 11, C_COPPER, true))

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
	alignment.custom_minimum_size.y = maxf(560.0, size.y - 105.0)
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
	var stage := HBoxContainer.new()
	stage.custom_minimum_size.y = maxf(530.0, size.y - 160.0)
	stage.add_theme_constant_override("separation", 25)
	_body.add_child(stage)

	var hero := VBoxContainer.new()
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	hero.custom_minimum_size.x = 660
	hero.add_theme_constant_override("separation", 9)
	stage.add_child(hero)

	var title_panel := _c_panel(Color(0.10,0.07,0.19,0.72), Color("ffbc78"), 25, 18)
	hero.add_child(title_panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	title_panel.add_child(stack)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	stack.add_child(heading)
	var mark := TextureRect.new()
	mark.texture = preload("res://Branding/SketchPlanPencil.svg")
	mark.custom_minimum_size = Vector2(104,104)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading.add_child(mark)
	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_child(titles)
	titles.add_child(_label("KITCHEN", 36, C_INK))
	titles.add_child(_label("SKETCH CHALLENGE", 36, C_COPPER))
	var mid := _label("DECORATION GAME", 22, C_INK, true)
	stack.add_child(mid)
	stack.add_child(_thin_rule())
	stack.add_child(_label("SKETCH  •  CHOOSE MATERIALS  •  COMPLETE", 15, Color("ffe0af"), true))
	stack.add_child(_label("Listen to the customer, create an accurate kitchen layout and solve real design missions.", 15, C_MUTED, true))

	var play := _button("▶   START TRAINING", true, 500, 70)
	play.add_theme_font_size_override("font_size", 25)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.pressed.connect(_show_language_select)
	hero.add_child(play)

	var secondary := HBoxContainer.new()
	secondary.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary.add_theme_constant_override("separation", 12)
	hero.add_child(secondary)
	var level_btn := _button("◇   SELECT LEVEL", false, 212, 50)
	level_btn.pressed.connect(_show_levels)
	secondary.add_child(level_btn)
	var guide_btn := _button("▤   GAME GUIDE", false, 190, 50)
	guide_btn.pressed.connect(_show_help)
	secondary.add_child(guide_btn)
	var settings_btn := _button("⚙", false, 64, 50)
	settings_btn.pressed.connect(_show_settings)
	secondary.add_child(settings_btn)
	if is_pause_overlay:
		var resume := _button("← BACK TO GAME", false, 240, 43)
		resume.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		resume.pressed.connect(_resume_paused)
		hero.add_child(resume)

	var right := Control.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_child(right)
	# The kitchen remains visible on the right instead of a heavy app-style panel.
	var tag := _c_panel(Color(0.16,0.11,0.24,0.75), Color("db9874"), 17, 14)
	right.add_child(tag)
	tag.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	tag.offset_left = -300
	tag.offset_right = -20
	tag.offset_top = -112
	tag.offset_bottom = -18
	var tag_col := VBoxContainer.new()
	tag_col.add_theme_constant_override("separation", 5)
	tag.add_child(tag_col)
	tag_col.add_child(_label("NEW MISSION", 13, C_COPPER))
	tag_col.add_child(_label("Design • Sketch • Create", 18, C_INK))
	tag_col.add_child(_label("3 playable stages  /  3 coming soon", 12, C_MUTED))
	hero.modulate.a = 0.0
	var entrance := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	entrance.tween_property(hero, "modulate:a", 1.0, 0.55)
	var pulse := create_tween().bind_node(play).set_loops()
	pulse.tween_property(play, "modulate", Color(1.0,0.96,0.87,1.0), 1.3)
	pulse.tween_property(play, "modulate", Color.WHITE, 1.3)

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

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	_body.add_child(top)
	var back := _button("←  BACK", false, 130, 43)
	back.pressed.connect(_resume_paused if is_pause_overlay else _show_home)
	top.add_child(back)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	top.add_child(_label("✦  SELECT LEVEL  ✦", 33, C_COPPER, true))
	gap = Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var progress := _button("PROGRESS", false, 145, 43)
	progress.pressed.connect(_show_progress)
	top.add_child(progress)
	_body.add_child(_label("Complete the design missions and unlock the next adventures.", 15, C_INK, true))
	var space := Control.new()
	space.custom_minimum_size.y = 10
	_body.add_child(space)

	var board := _c_panel(Color(0.11,0.08,0.19,0.81), Color("ffbb7b"), 29, 17)
	board.custom_minimum_size.y = 395
	_body.add_child(board)
	var holder := VBoxContainer.new()
	holder.add_theme_constant_override("separation", 20)
	board.add_child(holder)
	holder.add_child(_label("✦   KITCHEN DESIGN MISSIONS   ✦", 16, Color("ffe2b1"), true))

	var mission_row := HBoxContainer.new()
	mission_row.alignment = BoxContainer.ALIGNMENT_CENTER
	mission_row.add_theme_constant_override("separation", 18)
	holder.add_child(mission_row)
	var guide_column := VBoxContainer.new()
	guide_column.custom_minimum_size.x = 150
	guide_column.alignment = BoxContainer.ALIGNMENT_CENTER
	guide_column.add_theme_constant_override("separation", 10)
	mission_row.add_child(guide_column)
	var face := TextureRect.new()
	face.texture = preload("res://customer_portrait_ui.png")
	face.custom_minimum_size = Vector2(148, 148)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face_shader := Shader.new()
	face_shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float blue = clamp(tex.b - tex.r * 1.16, 0.0, 1.0);
	tex.rgb = mix(tex.rgb, vec3(0.95, 0.57, 0.34), blue * 0.92);
	COLOR = tex;
}
"""
	var face_material := ShaderMaterial.new()
	face_material.shader = face_shader
	face.material = face_material
	guide_column.add_child(face)
	guide_column.add_child(_label("DESIGN GUIDE", 13, C_COPPER, true))
	guide_column.add_child(_label("Choose your next\nchallenge!", 12, C_MUTED, true))
	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override("separation", 12)
	mission_row.add_child(cards)
	for stage in range(1, 7):
		var card := _stage_card(stage)
		cards.add_child(card)
		card.modulate.a = 0.0
		var card_entrance := create_tween()
		card_entrance.tween_interval(float(stage - 1) * 0.10)
		card_entrance.tween_property(card, "modulate:a", 1.0, 0.36).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var path := HBoxContainer.new()
	path.alignment = BoxContainer.ALIGNMENT_CENTER
	path.add_theme_constant_override("separation", 0)
	holder.add_child(path)
	var portrait_gap := Control.new()
	portrait_gap.custom_minimum_size.x = 168
	path.add_child(portrait_gap)
	for stage in range(1, 7):
		var node := _label("◆" if stage <= 3 else "◇", 18, Color("ffd285") if stage <= 3 else Color("867890"), true)
		node.custom_minimum_size.x = 166
		path.add_child(node)
		if stage < 6:
			var connector := ColorRect.new()
			connector.color = Color("b77b72") if stage <= 3 else Color("5d536b")
			connector.custom_minimum_size = Vector2(12,2)
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			path.add_child(connector)

	var status := _label("03 PLAYABLE STAGES      •      04 — 06 COMING SOON", 14, C_MUTED, true)
	_body.add_child(status)
	board.modulate.a = 0.0
	var slide := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	slide.tween_property(board, "modulate:a", 1.0, 0.62)

func _stage_card(stage: int) -> Button:
	var unlocked: bool = stage <= 3 and Progress.is_level_unlocked(stage)
	var card := Button.new()
	card.text = ""
	card.custom_minimum_size = Vector2(166, 275)
	card.disabled = not unlocked
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	var fill := Color(0.19,0.12,0.25,0.96) if unlocked else Color(0.22,0.20,0.28,0.92)
	var edge := Color("ffc077") if unlocked else Color("6f6878")
	card.add_theme_stylebox_override("normal", _console_style(fill, edge, 20, 5, 6))
	card.add_theme_stylebox_override("disabled", _console_style(fill, edge, 20, 5))
	card.add_theme_stylebox_override("hover", _console_style(Color("683850"), Color("ffe7a1"), 20, 5, 12))
	card.add_theme_stylebox_override("pressed", _console_style(Color("49243d"), Color("fff0c2"), 20, 5, 4))
	if unlocked:
		card.pressed.connect(_start_level.bind(stage))
		ConsoleAnimations.animate_button(card)

	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left","margin_right"]:
		pad.add_theme_constant_override(side, 10)
	for side in ["margin_top","margin_bottom"]:
		pad.add_theme_constant_override(side, 12)
	card.add_child(pad)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 7)
	pad.add_child(content)
	content.add_child(_label("STAGE %02d" % stage, 18, Color("ffd49c") if unlocked else Color("a69da9"), true))
	var preview := TextureRect.new()
	var images: Array[Texture2D] = [
		preload("res://reference_sketch.png"),
		preload("res://MenuAssets/Level2.png"),
		preload("res://MenuAssets/Level3.png"),
		preload("res://MenuAssets/Level4.png"),
		preload("res://MenuAssets/Level5.png"),
		preload("res://MenuAssets/Level6.png")
	]
	preview.texture = images[stage-1]
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(140, 89)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color.WHITE if unlocked else Color("756d7b")
	content.add_child(preview)
	var descriptions: Array[String] = ["Sketch Layout","Pipe Shaft Q&A","Select Materials","Design Challenge","Kitchen Planning","Final Challenge"]
	var name_label := _label(descriptions[stage-1], 16, C_INK if unlocked else Color("b6a6b3"), true)
	name_label.custom_minimum_size.y = 40
	content.add_child(name_label)
	var badge := _label("✦  READY TO PLAY" if unlocked else "◆  LOCKED", 12, Color("ffd68d") if unlocked else Color("aaa0ad"), true)
	content.add_child(badge)
	content.add_child(_label("★ ★ ★" if unlocked else "☆ ☆ ☆", 16, Color("ffc56b") if unlocked else Color("817885"), true))
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
