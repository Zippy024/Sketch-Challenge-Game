extends Control
signal language_chosen(language: String)
const Progress = preload("res://GameProgress.gd")
const BACKGROUND_PATH := "res://MenuAssets/Modern Teal Kitchen with Warm Accents.png"
var _layout: Control
var _dropdown: OptionButton
var _continue: Button
var _confirmed: bool = false

func _ready() -> void:
	name = "LanguageSelectionScreen"
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
	_layout.size = Vector2(640, 850)
	add_child(_layout)
	var logo := TextureRect.new()
	logo.texture = preload("res://LoadingAssets/KitchenLogo.webp")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(logo, Rect2(30, 0, 580, 265))
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _style(Color(0.93,0.98,1.0,0.95),Color("d6fbff"),42,2))
	_put(panel, Rect2(30, 270, 580, 470))
	var title := Label.new()
	title.text = "Select Language"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var title_font := FontVariation.new()
	title_font.base_font = get_theme_default_font()
	title_font.variation_embolden = 0.3
	title.add_theme_font_override("font",title_font)
	title.add_theme_font_size_override("font_size",36)
	title.add_theme_color_override("font_color",Color("09234c"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(title,Rect2(62,294,516,60))
	_dropdown = OptionButton.new()
	_dropdown.name = "LanguageDropdown"
	_dropdown.add_item("日本語",0)
	_dropdown.add_item("မြန်မာ",1)
	_dropdown.add_item("English (Coming Soon)",2)
	_dropdown.set_item_disabled(2,true)
	_dropdown.select(1 if Progress.get_language()=="mm" else 0)
	_dropdown.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_dropdown.add_theme_font_size_override("font_size",32)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		_dropdown.add_theme_color_override(state,Color("0b2853"))
	for state in ["normal","hover","pressed"]:
		var box := _style(Color("ffffff") if state=="normal" else Color("e2f7ff"),Color("89dcf3"),36,2)
		box.set_content_margin_all(16)
		_dropdown.add_theme_stylebox_override(state,box)
	_dropdown.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("00a9d2"),36,3))
	var popup := _dropdown.get_popup()
	popup.add_theme_stylebox_override("panel",_style(Color("ffffff"),Color("c2e8f5"),25,1))
	var hover_row := _style(Color("269deb"),Color("269deb"),12,0)
	hover_row.shadow_size = 0
	popup.add_theme_stylebox_override("hover",hover_row)
	popup.add_theme_font_size_override("font_size",30)
	popup.add_theme_color_override("font_color",Color("09234c"))
	popup.add_theme_color_override("font_hover_color",Color.WHITE)
	popup.add_theme_color_override("font_disabled_color",Color("9ba6b1"))
	popup.add_theme_constant_override("v_separation",18)
	popup.add_theme_constant_override("h_separation",16)
	_put(_dropdown,Rect2(66,380,508,76))
	_continue = Button.new()
	_continue.name = "LanguageContinue"
	_continue.text = "Continue"
	_continue.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_continue.add_theme_font_size_override("font_size",32)
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		_continue.add_theme_color_override(state,Color.WHITE)
	var capsule := StyleBoxTexture.new()
	capsule.texture = preload("res://LanguageAssets/Continue.svg")
	capsule.texture_margin_left = 32
	capsule.texture_margin_right = 32
	capsule.texture_margin_top = 24
	capsule.texture_margin_bottom = 24
	capsule.set_content_margin_all(14)
	_continue.add_theme_stylebox_override("normal",capsule)
	_continue.add_theme_stylebox_override("hover",_style(Color("00a9be"),Color("b8ffff"),38,2))
	_continue.add_theme_stylebox_override("pressed",_style(Color("005b79"),Color("73e6f7"),38,2))
	_continue.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,Color("c5fcff"),38,3))
	_continue.pressed.connect(_confirm)
	_put(_continue,Rect2(140,716,360,76))
	_dropdown.item_selected.connect(func(_index: int) -> void: _continue.grab_focus())
	resized.connect(_fit)
	_fit()

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
	var factor := minf(minf(size.x/680.0,size.y/880.0),1.3)
	_layout.scale = Vector2.ONE * factor
	_layout.position = (size - Vector2(640,850)*factor)*0.5

func _confirm() -> void:
	if _confirmed or _dropdown.selected not in [0,1]: return
	_confirmed = true
	_continue.disabled = true
	language_chosen.emit("mm" if _dropdown.selected==1 else "jp")
	queue_free()
