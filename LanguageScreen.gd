extends Control
signal language_chosen(language: String)
const Progress = preload("res://GameProgress.gd")
const UI = preload("res://KitchenUI.gd")
var _layout: Control
var _selected: String
var _choices: Array[Button] = []
var _continue: Button
var _confirmed: bool = false
func _ready() -> void:
	name = "LanguageSelectionScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.background(self)
	_selected = Progress.get_language()
	_layout = Control.new()
	_layout.size = Vector2(1440,810)
	add_child(_layout)
	var mark := UI.logo(470,180)
	_layout.add_child(mark)
	mark.position = Vector2(485,5)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",UI.box(Color(0.94,0.98,1,0.74),Color.WHITE,28,30))
	_layout.add_child(panel)
	panel.position = Vector2(280,196)
	panel.size = Vector2(880,580)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation",14)
	panel.add_child(stack)
	var heading := UI.label("",36,true)
	heading.text = "Choose your language"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(heading)
	var subtitle := UI.label("",18,false,UI.MUTED)
	subtitle.text = "You can change this later in Settings."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	for entry in [["jp","日本語"],["mm","မြန်မာ"],["en","English"]]:
		var choice := UI.button("",_choose.bind(entry[0]),false,800,24)
		choice.name = "LanguageOption"+entry[0]
		choice.custom_minimum_size.y = 66
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.set_meta("language",entry[0])
		choice.set_meta("caption",entry[1])
		stack.add_child(choice)
		_choices.append(choice)
	_continue = UI.button("",_confirm,true,430,24)
	_continue.text = "Continue   →"
	_continue.name = "LanguageContinue"
	_continue.custom_minimum_size.y = 64
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(_continue)
	_choose(_selected)
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	var factor := minf(size.x/1440.0,size.y/810.0)
	_layout.scale = Vector2.ONE*factor
	_layout.position = (size-Vector2(1440,810)*factor)/2
func _choose(language: String) -> void:
	_selected = language
	for choice in _choices:
		var selected: bool = choice.get_meta("language") == language
		choice.text = ("✓   " if selected else "○   ")+str(choice.get_meta("caption"))
		UI.style_button(choice,false,24)
		choice.add_theme_font_override("font",UI.font(selected))
		var style := UI.box(Color("c1f2f4") if selected else Color(0.97,0.99,1,0.75),Color.WHITE,20,8)
		style.content_margin_left = 30
		choice.add_theme_stylebox_override("normal",style)
func _confirm() -> void:
	if _confirmed: return
	_confirmed = true
	_continue.disabled = true
	language_chosen.emit(_selected)
	queue_free()
