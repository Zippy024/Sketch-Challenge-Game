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
var _selected_level: int = 3


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
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _set_concept_background(_choose_levels: bool) -> void:
	# Background is deliberately the same photo-free blue theme on every
	# menu screen. Stage 1–3 have their own unchanged scenes.
	pass

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
	_scroll.scroll_vertical = 0

func _entry_background() -> void:
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Shared FlatBlueBackdrop stays visible behind all entry screens.

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
	_showroom_title(canvas,215,9,670,59)
	# The glass panel occupies nearly half the desktop width, exactly one
	# live Godot interface above the full-screen photo-like kitchen.
	var panel := _glass(Color(0.96,0.99,1.0,0.95),Color("84d9f8"),27,6)
	panel.name = "LanguageDropdownPanel"
	panel.set_meta("entry_language_panel",true)
	_ui_put(canvas,panel,Rect2(317,215,466,357))
	_ui_text(canvas,"Select Language",22,Rect2(340,241,417,36),Color("102e56"),true)

	var menu := OptionButton.new()
	menu.name = "EntryLanguageDropdown"
	menu.set_meta("entry_language_dropdown",true)
	menu.custom_minimum_size = Vector2(397,58)
	menu.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	menu.add_theme_font_size_override("font_size",21)
	for theme_color in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		menu.add_theme_color_override(theme_color, Color("143d69"))
	menu.add_theme_color_override("font_disabled_color", Color("88a0bb"))
	menu.add_theme_stylebox_override("normal",_console_style(Color("ffffff"),Color("7dcdf4"),20,11,5))
	menu.add_theme_stylebox_override("hover",_console_style(Color("e6f7ff"),Color("38c9f3"),20,11,8))
	menu.add_theme_stylebox_override("pressed",_console_style(Color("d9f3ff"),Color("48c7f0"),20,11,3))
	menu.add_theme_stylebox_override("focus",_console_style(Color.TRANSPARENT,Color("4fcff5"),20,0,0))
	var popup := menu.get_popup()
	popup.add_theme_stylebox_override("panel",_console_style(Color("f8fcff"),Color("a6dff5"),16,13,8))
	popup.add_theme_stylebox_override("hover",_console_style(Color("41a1f3"),Color("b4eaff"),13,9,3))
	popup.add_theme_color_override("font_color",Color("10385b"))
	popup.add_theme_color_override("font_hover_color",Color("ffffff"))
	popup.add_theme_color_override("font_disabled_color",Color("8da1b4"))
	popup.add_theme_font_size_override("font_size",20)
	menu.add_item("🌐   日本語",0)
	menu.add_item("မြန်မာ",1)
	menu.add_item("English (Coming Soon)",2)
	menu.set_item_disabled(2,true)
	menu.select(1 if Progress.get_language()=="mm" else 0)
	_ui_put(canvas,menu,Rect2(352,316,398,59))

	var continue_button := _button("Continue    »",true,362,62)
	continue_button.name = "LanguageContinue"
	continue_button.set_meta("entry_language_continue",true)
	continue_button.add_theme_font_size_override("font_size",23)
	continue_button.pressed.connect(func() -> void:
		_choose_language("mm" if menu.selected==1 else "jp")
	)
	_ui_put(canvas,continue_button,Rect2(369,467,362,64))
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
