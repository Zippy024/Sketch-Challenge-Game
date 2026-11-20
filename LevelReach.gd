extends PanelContainer
const UI=preload("res://KitchenUI.gd")
const Aqua=preload("res://AquaStyle.gd")
const Progress=preload("res://GameProgress.gd")
var current_stage: int=1
var compact: bool=false
var in_header: bool=false
var _state: int=-1
var _elapsed: float=0.0

func _ready() -> void:
	name="LevelReachTrack"
	custom_minimum_size.y=68
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=UI.box(Color(0.91,0.99,1,0.65),Color("b8e5ec"),22,2)
	style.content_margin_left=5
	style.content_margin_right=5
	style.shadow_size=0
	add_theme_stylebox_override("panel",style)
	_rebuild()

func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<0.2:return
	_elapsed=0
	var state:=int(Progress.is_completed(1))+2*int(Progress.is_completed(2))+4*int(Progress.is_completed(3))
	if state!=_state:_rebuild()

func _rebuild() -> void:
	_state=int(Progress.is_completed(1))+2*int(Progress.is_completed(2))+4*int(Progress.is_completed(3))
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var route:=HBoxContainer.new()
	route.add_theme_constant_override("separation",0)
	add_child(route)
	for n in range(1,4 if compact else 11):
		if n>1:
			var bridge:=Bridge.new()
			bridge.active=Progress.is_completed(n-1)
			bridge.custom_minimum_size.x=5 if in_header else 9
			route.add_child(bridge)
		var point:=Checkpoint.new()
		point.name="ReachNode%02d"%n
		point.done=Progress.is_completed(n)
		point.current=n==current_stage
		point.locked=not Progress.is_level_unlocked(n)
		point.set_meta("stage",n)
		point.set_meta("completed",point.done)
		point.set_meta("current",point.current)
		point.set_meta("locked",point.locked)
		point.custom_minimum_size=Vector2(104,68) if point.current else Vector2(44,50)
		point.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		point.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		point.size_flags_stretch_ratio=1.7 if point.current else 1.0
		point.tooltip_text=UI.text("Stage %d")%n+"\n"+UI.text("Coming soon" if point.locked else ("Completed" if point.done else "Ready"))
		route.add_child(point)
		var number:=UI.inline_label(UI.text("Stage %d")%n if point.current else "%02d"%n,12 if point.current else 17,true)
		number.name="CurrentStageLabel" if point.current else "ReachStageLabel"
		number.set_meta("locale_ignore",not point.current)
		number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_color_override("font_color",Color.WHITE if point.current or point.done else UI.INK)
		point.add_child(number)
		number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		number.offset_left=3
		number.offset_right=-3
		number.offset_top=25 if point.current else -6
		number.offset_bottom=-16 if point.current else -9
		var icon:=TextureRect.new()
		icon.texture=UI.icon(["plan","chat","cabinet"][n-1]) if point.current else (UI.icon("check") if point.done else preload("res://MenuAssets/level-lock.svg"))
		icon.modulate=Color.WHITE if point.current or point.done else UI.TEAL
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		point.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP if point.current else Control.PRESET_CENTER_BOTTOM)
		icon.position=Vector2(point.size.x/2-10,6 if point.current else point.size.y-21)
		icon.size=Vector2(20,20) if point.current else Vector2(13,13)
		# Icons follow container allocation without changing any stage state.
		point.resized.connect(func():
			icon.position=Vector2(point.size.x/2-icon.size.x/2,6 if point.current else point.size.y-21)
		)
		if point.current:
			var index:=UI.inline_label("%02d"%n,12,true)
			index.add_theme_color_override("font_color",Color.WHITE)
			index.set_meta("locale_ignore",true)
			index.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			point.add_child(index)
			index.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
			index.offset_top=-25
			index.offset_bottom=-7

class Checkpoint extends Control:
	var current: bool=false
	var done: bool=false
	var locked: bool=false
	var _pulse: float=0.0
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)
		set_process(current)
	func _process(delta: float) -> void:
		_pulse+=delta
		queue_redraw()
	func _draw() -> void:
		var width:=minf(size.x-2,size.y*(1.1 if current else 1.0))
		var rect:=Rect2((size.x-width)/2,0,width,size.y)
		if current:
			draw_circle(size/2,25+sin(_pulse*1.8),Color(0.19,0.89,0.89,0.08))
			# A broad shield holds translated stage names without clipping.
			rect=Rect2((size.x-width)/2,0,width,size.y)
		draw_texture_rect(Aqua.badge(current,done,locked),rect,false)
		if done and not current:
			var center:=Vector2(size.x/2+width*.26,size.y*.79)
			draw_circle(center,9,Color("35b86a"))
			draw_arc(center,9,0,TAU,28,Color.WHITE,1,true)
			draw_polyline(PackedVector2Array([center+Vector2(-4,0),center+Vector2(-1,3),center+Vector2(5,-4)]),Color.WHITE,1.8,true)

class Bridge extends Control:
	var active: bool=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var y:=size.y*.5
		draw_line(Vector2(-3,y+2),Vector2(size.x+3,y+2),Color("9cced8"),6,true)
		draw_line(Vector2(-3,y),Vector2(size.x+3,y),Color("44d4d7") if active else Color("b3e4eb"),4,true)
		draw_line(Vector2(-3,y-1),Vector2(size.x+3,y-1),Color("e9ffff"),1,true)
