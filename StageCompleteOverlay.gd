extends Control
signal next_requested
signal levels_requested
signal home_requested
const UI=preload("res://KitchenUI.gd")
var stage_index: int=1
var title_text: String="Stage complete!"
var next_text: String="Next Stage"
var levels_text: String="View Levels"
var _design: Control

func configure(title_value: String,_subtitle: String="",next_value: String="Next Stage",levels_value: String="View Levels") -> void:
	title_text=title_value
	next_text=next_value
	levels_text=levels_value

func _put(parent: Control,child: Control,rect: Rect2) -> void:
	parent.add_child(child)
	child.position=rect.position
	child.size=rect.size

func _caption(value: String,rect: Rect2,size: int,bold: bool=false,color: Color=UI.INK) -> Label:
	var label:=UI.label("",size,bold,color)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_put(_design,label,rect)
	label.text=value
	return label

func _ready() -> void:
	theme=UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var shade:=ColorRect.new()
	shade.color=Color(0.02,0.10,0.17,0.64)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var confetti:=preload("res://ConfettiRain.gd").new()
	confetti.name="CompletionConfetti"
	add_child(confetti)
	_design=Control.new()
	_design.size=Vector2(740,390)
	add_child(_design)
	var card:=Panel.new()
	card.name="MissionCompleteCard"
	card.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var frame:=StyleBoxTexture.new()
	frame.texture=preload("res://UIAssets/mission-ticket.svg")
	card.add_theme_stylebox_override("panel",frame)
	_put(_design,card,Rect2(0,0,740,390))
	var title:=_caption(UI.text("Stage %d complete!")%stage_index,Rect2(24,10,692,58),24,true,Color.WHITE)
	title.name="CompletionTitle"
	var graphic:=preload("res://CompletionBlueprint.gd").new()
	graphic.name="CompletionBlueprintGraphic"
	graphic.stage_index=stage_index
	_put(_design,graphic,Rect2(36,106,210,190))
	var mission:=_caption(UI.text(["LDK Boundary Drawing","Pipe Shaft Q&A","S-Class Kitchen Selection"][stage_index-1]),Rect2(295,100,402,62),16,true)
	mission.name="CompletionMission"
	var next:=UI.button(next_text,func():next_requested.emit(),true,0,19)
	next.name="CompletionNext"
	_put(_design,next,Rect2(311,175,370,50))
	next.call_deferred("grab_focus")
	var home:=UI.button("Go to Main Menu",func():home_requested.emit(),false,0,15)
	home.name="CompletionHome"
	_put(_design,home,Rect2(311,237,370,42))
	var levels:=UI.button(levels_text,func():levels_requested.emit(),false,0,13)
	levels.name="CompletionLevels"
	for state in ["normal","hover","pressed","disabled"]:levels.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	_put(_design,levels,Rect2(311,284,370,28))
	var reach=load("res://LevelReach.gd").new()
	reach.current_stage=mini(stage_index+1,3)
	reach.compact=true
	_put(_design,reach,Rect2(34,329,672,44))
	resized.connect(_fit)
	_fit()
	if not confetti.reduced_motion:
		_design.modulate.a=0
		create_tween().tween_property(_design,"modulate:a",1.0,0.22)

func _fit() -> void:
	var factor:=maxf(0.1,minf(1.0,minf((size.x-32)/740.0,(size.y-32)/390.0)))
	_design.scale=Vector2.ONE*factor
	_design.position=((size-Vector2(740,390)*factor)*0.5).round()
