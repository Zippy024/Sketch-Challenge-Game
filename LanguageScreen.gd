extends Control
signal language_chosen(language: String)
const Progress = preload("res://GameProgress.gd")
const BACKGROUND_PATH := "res://MenuAssets/Modern Teal Kitchen with Warm Accents.png"
var _layout: Control
var _dropdown: OptionButton
var _continue: Button
var _confirmed: bool = false
var _logo: TextureRect

func _ready() -> void:
	name = "LanguageSelectionScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var base := ColorRect.new()
	base.color = Color("10455c")
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := TextureRect.new()
	background.name = "LanguageBackground"
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout = Control.new()
	_layout.name = "LanguageLayout"
	_layout.size = Vector2(640, 690)
	add_child(_layout)
	var logo := TextureRect.new()
	logo.texture = preload("res://LoadingAssets/KitchenLogo.webp")
	_logo = logo
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(logo, Rect2(55, 10, 530, 245))
	logo.pivot_offset = logo.size * 0.5
	_start_logo_motion()
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := _style(Color("e8f4ff"),Color("8db9e2"),24,2)
	panel_style.shadow_size = 6
	panel_style.shadow_offset = Vector2(0,3)
	panel.add_theme_stylebox_override("panel", panel_style)
	_put(panel, Rect2(185, 330, 270, 142))
	var title := Label.new()
	title.text = "Select Language"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var title_font := FontVariation.new()
	title_font.base_font = get_theme_default_font()
	title_font.variation_embolden = 0.3
	title.add_theme_font_override("font",title_font)
	title.add_theme_font_size_override("font_size",17)
	title.add_theme_color_override("font_color",Color("09234c"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(title,Rect2(205,338,230,24))
	_dropdown = OptionButton.new()
	_dropdown.name = "LanguageDropdown"
	_dropdown.add_item("日本語",0)
	_dropdown.add_item("မြန်မာ",1)
	_dropdown.add_item("English",2)
	# Keep all three endonyms within the compact 230px dropdown.
	_dropdown.fit_to_longest_item = false
	_dropdown.select({"jp":0,"mm":1,"en":2}[Progress.get_language()])
	_dropdown.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_dropdown.add_theme_font_size_override("font_size",17)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		_dropdown.add_theme_color_override(state,Color("0b2853"))
	for state in ["normal","hover","pressed"]:
		var box := _style(Color("f4faff") if state=="normal" else Color("e4f4ff"),Color("81b8e7"),13,1)
		box.set_content_margin(SIDE_LEFT, 12)
		box.set_content_margin(SIDE_RIGHT, 10)
		box.set_content_margin(SIDE_TOP, 2)
		box.set_content_margin(SIDE_BOTTOM, 2)
		box.shadow_size = 4
		box.shadow_offset = Vector2(0,2)
		_dropdown.add_theme_stylebox_override(state,box)
	_dropdown.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("579fe2"),13,2))
	var popup := _dropdown.get_popup()
	popup.add_theme_stylebox_override("panel",_style(Color("ffffff"),Color("c2e8f5"),25,1))
	var hover_row := _style(Color("269deb"),Color("269deb"),12,0)
	hover_row.shadow_size = 0
	popup.add_theme_stylebox_override("hover",hover_row)
	popup.add_theme_font_size_override("font_size",19)
	popup.add_theme_color_override("font_color",Color("09234c"))
	popup.add_theme_color_override("font_hover_color",Color.WHITE)
	popup.add_theme_color_override("font_disabled_color",Color("9ba6b1"))
	popup.add_theme_constant_override("v_separation",18)
	popup.add_theme_constant_override("h_separation",16)
	_put(_dropdown,Rect2(205,368,230,40))
	_continue = Button.new()
	_continue.name = "LanguageContinue"
	_continue.text = "Continue"
	_continue.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_continue.add_theme_font_size_override("font_size",18)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		_continue.add_theme_color_override(state,Color.WHITE)
	# Match the compact blue pill-style button in the supplied reference.
	var normal_button := _style(Color("1976be"),Color("83b9e8"),22,2)
	normal_button.shadow_size = 5
	normal_button.shadow_offset = Vector2(0,3)
	_continue.add_theme_stylebox_override("normal",normal_button)
	_continue.add_theme_stylebox_override("hover",_style(Color("278bd2"),Color("9fd0f7"),24,2))
	_continue.add_theme_stylebox_override("pressed",_style(Color("105b9f"),Color("83b9e8"),24,2))
	_continue.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("b3dfff"),24,2))
	_continue.pressed.connect(_confirm)
	_put(_continue,Rect2(205,426,230,40))
	# Godot's Myanmar font can make OptionButton taller than its requested
	# rectangle. Measure the real minimum height, then place Continue below it.
	# Keep a visible gap even after the button shadows are drawn.
	var dropdown_height := maxf(40.0, _dropdown.get_combined_minimum_size().y)
	_dropdown.size.y = dropdown_height
	var continue_height := maxf(40.0, _continue.get_combined_minimum_size().y)
	_continue.position.y = _dropdown.position.y + dropdown_height + 13.0
	_continue.size.y = continue_height
	panel.size.y = _continue.position.y + continue_height + 12.0 - panel.position.y
	_dropdown.item_selected.connect(func(_index: int) -> void: _continue.grab_focus())
	resized.connect(_fit)
	_fit()

func _start_logo_motion() -> void:
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true)):
		return
	var motion := ShaderMaterial.new()
	motion.shader = preload("res://MenuAssets/LogoFloat.gdshader")
	_logo.material = motion
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _style(fill: Color, edge: Color, radius: int, border: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(border)
	box.set_corner_radius_all(radius)
	box.shadow_color = Color(0.01,0.20,0.35,0.22)
	box.shadow_size = 12
	box.shadow_offset = Vector2(0,7)
	return box

func _put(control: Control, rect: Rect2) -> void:
	_layout.add_child(control)
	control.position = rect.position
	control.size = rect.size

func _fit() -> void:
	if not is_instance_valid(_layout): return
	var factor := minf(minf(size.x/680.0,size.y/730.0),1.3)
	_layout.scale = Vector2.ONE * factor
	_layout.position = (size - Vector2(640,690)*factor)*0.5

func _confirm() -> void:
	if _confirmed or _dropdown.selected not in [0,1,2]: return
	_confirmed = true
	_continue.disabled = true
	language_chosen.emit(["jp","mm","en"][_dropdown.selected])
	queue_free()
