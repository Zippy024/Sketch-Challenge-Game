extends Control
signal finished
const UI = preload("res://KitchenUI.gd")
var _bar: ProgressBar
var _caption: Label
var _elapsed: float = 0.0
func _ready() -> void:
	name = "KitchenLoadingScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UI.background(self)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = 560
	stack.add_theme_constant_override("separation",22)
	center.add_child(stack)
	stack.add_child(UI.logo(560,245))
	var tagline := UI.label("Design a kitchen. Build your confidence.",22,true)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(tagline)
	var space := Control.new()
	space.custom_minimum_size.y = 48
	stack.add_child(space)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size.y = 12
	_bar.add_theme_stylebox_override("background",UI.box(Color("d6e7ec"),Color.WHITE,6,0))
	_bar.add_theme_stylebox_override("fill",UI.box(UI.TEAL,UI.TEAL,6,0))
	stack.add_child(_bar)
	_caption = UI.label("Loading...",16)
	_caption.name = "LoadingCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(_caption)
	var tip := UI.label("Read the plan. Understand the space. Make it yours.",14,false,UI.MUTED)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(tip)
func _process(delta: float) -> void:
	_elapsed += delta
	var fraction := minf(_elapsed / 2.1,1.0)
	_bar.value = fraction * 100
	_caption.text = "Loading... %d%%" % roundi(fraction*100)
	if fraction >= 1.0:
		set_process(false)
		finished.emit()
		queue_free()
