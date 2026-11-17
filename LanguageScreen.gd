extends Control
signal language_chosen(language: String)
const Progress = preload("res://GameProgress.gd")
const UI = preload("res://KitchenUI.gd")
const LANGUAGES: Array[String]=["jp","mm","en"]
const CAPTIONS: Array[String]=["日本語","မြန်မာ","English"]
var _layout: Control
var _selected: String
var _dropdown: MenuButton
var _continue: Button
var _confirmed: bool=false
func _ready() -> void:
 name="LanguageSelectionScreen"
 set_meta("locale_ignore",true)
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 UI.background(self)
 _selected=Progress.get_language()
 _layout=Control.new()
 _layout.size=Vector2(1440,810)
 add_child(_layout)
 var mark:=UI.logo(390,150)
 _layout.add_child(mark)
 mark.position=Vector2(525,22)
 var panel:=PanelContainer.new()
 panel.name="LanguageSelectionCard"
 panel.add_theme_stylebox_override("panel",UI.box(Color("fffdf6"),Color("b3d6cb"),25,32))
 _layout.add_child(panel)
 panel.position=Vector2(420,214)
 panel.size=Vector2(600,410)
 var stack:=VBoxContainer.new()
 stack.alignment=BoxContainer.ALIGNMENT_CENTER
 stack.add_theme_constant_override("separation",18)
 panel.add_child(stack)
 var globe:=TextureRect.new()
 globe.texture=UI.icon("globe")
 globe.modulate=UI.TEAL
 globe.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 globe.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 globe.custom_minimum_size=Vector2(38,38)
 globe.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
 stack.add_child(globe)
 var heading:=UI.label("",30,true)
 heading.text="Choose your language"
 heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 stack.add_child(heading)
 var subtitle:=UI.label("",15,false,UI.MUTED)
 subtitle.text="You can change this later in Settings."
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 stack.add_child(subtitle)
 _dropdown=MenuButton.new()
 _dropdown.name="LanguageDropdown"
 _dropdown.flat=false
 _dropdown.custom_minimum_size=Vector2(500,58)
 _dropdown.alignment=HORIZONTAL_ALIGNMENT_LEFT
 _dropdown.add_theme_constant_override("h_separation",12)
 _dropdown.icon=UI.icon("globe")
 UI.style_button(_dropdown,false,21)
 for state in ["normal","hover","pressed","focus"]:
  var surface:=UI.box(Color("f6fcfb"),Color("69bcb3"),14,12)
  surface.shadow_size=0
  _dropdown.add_theme_stylebox_override(state,surface)
 for state in ["icon_normal_color","icon_hover_color","icon_pressed_color"]:_dropdown.add_theme_color_override(state,UI.TEAL)
 stack.add_child(_dropdown)
 var chevron:=TextureRect.new()
 chevron.texture=UI.icon("chevron_down")
 chevron.modulate=UI.INK
 chevron.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 chevron.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 chevron.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _dropdown.add_child(chevron)
 chevron.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
 chevron.offset_left=-34
 chevron.offset_right=-14
 chevron.offset_top=-10
 chevron.offset_bottom=10
 var popup:=_dropdown.get_popup()
 for i in range(LANGUAGES.size()):popup.add_radio_check_item(CAPTIONS[i],i)
 UI.style_language_popup(popup)
 popup.add_theme_font_size_override("font_size",20)
 popup.about_to_popup.connect(func():_fit_popup.call_deferred())
 popup.id_pressed.connect(func(id: int):_choose(LANGUAGES[id]))
 _continue=UI.button("",_confirm,true,500,21)
 _continue.text="Continue   →"
 _continue.name="LanguageContinue"
 _continue.custom_minimum_size.y=58
 stack.add_child(_continue)
 _choose(_selected)
 resized.connect(_fit)
 _fit()
func _fit_popup() -> void:
 var popup:=_dropdown.get_popup()
 var width:=roundi(_dropdown.get_global_rect().size.x)
 popup.min_size=Vector2i(width,0)
 popup.size=Vector2i(width,popup.size.y)
func _fit() -> void:
 var factor:=minf(size.x/1440.0,size.y/810.0)
 _layout.scale=Vector2.ONE*factor
 _layout.position=(size-Vector2(1440,810)*factor)/2
func _choose(language: String) -> void:
 if language not in LANGUAGES:return
 _selected=language
 _dropdown.text=CAPTIONS[LANGUAGES.find(language)]
 for i in range(LANGUAGES.size()):_dropdown.get_popup().set_item_checked(i,LANGUAGES[i]==language)
func _confirm() -> void:
 if _confirmed:return
 _confirmed=true
 _continue.disabled=true
 language_chosen.emit(_selected)
 queue_free()
