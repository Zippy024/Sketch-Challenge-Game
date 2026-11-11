extends Control
signal next_requested
signal levels_requested
signal replay_requested
signal home_requested
const UI = preload("res://KitchenUI.gd")
var stage_index: int = 1
var title_text: String = "Stage complete!"
var next_text: String = "Next Stage"
var levels_text: String = "View Levels"
var replay_text: String = "Review drawing"
var show_next_button: bool = true
var show_replay_button: bool = false
var _design: Control

func configure(title_value: String, _subtitle: String = "", next_value: String = "Next Stage", levels_value: String = "View Levels", replay_value: String = "Replay", allow_next: bool = true, allow_replay: bool = false) -> void:
	title_text=title_value
	next_text=next_value
	levels_text=levels_value
	replay_text=replay_value
	show_next_button=allow_next
	show_replay_button=allow_replay

func _put(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.position=rect.position
	child.size=rect.size

func _ready() -> void:
	theme=UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color=Color(0.02,0.12,0.20,0.55)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var confetti := preload("res://ConfettiRain.gd").new()
	confetti.name="CompletionConfetti"
	add_child(confetti)
	_design=Control.new()
	_design.size=Vector2(730,310)
	add_child(_design)
	var card := Panel.new()
	card.name="MissionCompleteCard"
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel",UI.box(Color("e9f9ff"),Color("dbffff"),28,0))
	_put(_design,card,Rect2(0,0,730,310))
	var art := TextureRect.new()
	art.name="CelebrationArtwork"
	art.texture=preload("res://UIAssets/HosokawaThumbsUp.webp")
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_put(_design,art,Rect2(8,-8,252,318))
	var heading := UI.label(UI.text("Stage %d complete!")%stage_index,27,true)
	heading.autowrap_mode=TextServer.AUTOWRAP_OFF
	heading.name="CompletionTitle"
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_put(_design,heading,Rect2(270,28,430,76))
	if show_next_button:
		var next := UI.button(next_text,func():next_requested.emit(),true,0,22)
		next.name="CompletionNext"
		_put(_design,next,Rect2(300,118,370,52))
		next.call_deferred("grab_focus")
	var home := UI.button("Go to Main Menu",func():home_requested.emit(),false,0,16)
	home.name="CompletionHome"
	_put(_design,home,Rect2(300,183,370,44))
	var actions := HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",18)
	_put(_design,actions,Rect2(270,244,430,36))
	if show_replay_button:
		var review := _link(replay_text,func():replay_requested.emit())
		review.name="CompletionReview"
		actions.add_child(review)
	var levels := _link(levels_text,func():levels_requested.emit())
	levels.name="CompletionLevels"
	actions.add_child(levels)
	resized.connect(_fit)
	_fit()
	if not confetti.reduced_motion:
		art.modulate.a=0
		create_tween().tween_property(art,"modulate:a",1.0,0.22)

func _link(value: String, action: Callable) -> Button:
	var button := UI.button(value,action,false,0,13)
	for state in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",UI.MUTED)
	return button

func _fit() -> void:
	var factor := minf(1.0,minf((size.x-32)/730.0,(size.y-32)/326.0))
	_design.scale=Vector2.ONE*maxf(0.1,factor)
	_design.position=(size-Vector2(730,310)*_design.scale)*0.5
