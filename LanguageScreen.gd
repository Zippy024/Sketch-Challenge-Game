extends Control
signal language_chosen(language: String)
const Progress = preload("res://GameProgress.gd")
const UI = preload("res://KitchenUI.gd")
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
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 500
	column.add_theme_constant_override("separation",18)
	center.add_child(column)
	column.add_child(UI.logo(430,160))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",UI.box())
	column.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",14)
	panel.add_child(stack)
	var heading := UI.label("Choose your language",26,true)
	heading.text = "Choose your language"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(heading)
	var subtitle := UI.label("",14,false,UI.MUTED)
	subtitle.text = "You can change it any time during the game."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	for entry in [["jp","日本語","Japanese"],["mm","မြန်မာ","Myanmar"],["en","English","English"]]:
		var choice := UI.button("",_choose.bind(entry[0]),false,460,19)
		choice.name = "LanguageOption"+entry[0]
		choice.custom_minimum_size.y = 58
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.set_meta("language",entry[0])
		choice.set_meta("caption",entry[1]+"   ·   "+entry[2])
		stack.add_child(choice)
		_choices.append(choice)
	_continue = UI.button("",_confirm,true,460,18)
	_continue.text = "Continue   →"
	_continue.name = "LanguageContinue"
	_continue.custom_minimum_size.y = 46
	stack.add_child(_continue)
	_choose(_selected)
func _choose(language: String) -> void:
	_selected = language
	for choice in _choices:
		var selected: bool = choice.get_meta("language") == language
		choice.text = ("●   " if selected else "○   ")+str(choice.get_meta("caption"))
		UI.style_button(choice,selected,19)
func _confirm() -> void:
	if _confirmed: return
	_confirmed = true
	_continue.disabled = true
	language_chosen.emit(_selected)
	queue_free()
