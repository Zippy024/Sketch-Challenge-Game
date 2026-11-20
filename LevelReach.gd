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
	var style:=StyleBoxEmpty.new()
	style.content_margin_left=4
	style.content_margin_right=4
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
	var route:=Route.new()
	route.add_theme_constant_override("separation",0)
	add_child(route)
	for n in range(1,4 if compact else 11):
		var point:=Checkpoint.new()
		point.name="ReachNode%02d"%n
		point.done=Progress.is_completed(n)
		point.current=n==current_stage
		point.locked=not Progress.is_level_unlocked(n)
		point.set_meta("stage",n)
		point.set_meta("completed",point.done)
		point.set_meta("current",point.current)
		point.set_meta("locked",point.locked)
		point.custom_minimum_size=Vector2(116,68) if point.current else Vector2(54,56)
		point.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		point.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		point.size_flags_stretch_ratio=1.15 if point.current else 1.0
		point.tooltip_text=UI.text("Stage %d")%n+"\n"+UI.text("Coming soon" if point.locked else ("Completed" if point.done else "Ready"))
		route.add_child(point)
		point.resized.connect(route.queue_redraw)
		point.item_rect_changed.connect(route.queue_redraw)
		var number:=UI.inline_label("%02d"%n,22 if point.current else 20,true)
		number.name="ReachStageLabel"
		number.set_meta("locale_ignore",true)
		number.add_theme_font_override("font",UI.font(true,"en"))
		number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		point.add_child(number)
		number.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		number.offset_top=23 if point.current else 3
		number.offset_bottom=57 if point.current else 39
		if point.current:
			var flag:=UI.inline_label(UI.text("Stage %d")%n,12,true)
			flag.name="CurrentStageLabel"
			flag.add_theme_color_override("font_color",Color.WHITE)
			flag.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			point.add_child(flag)
			flag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
			flag.offset_left=-13
			flag.offset_right=57
			flag.offset_top=0
			flag.offset_bottom=24
		elif point.locked:
			var lock:=TextureRect.new()
			lock.name="CheckpointLock"
			lock.texture=UI.icon("lock")
			lock.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			lock.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock.mouse_filter=Control.MOUSE_FILTER_IGNORE
			point.add_child(lock)
			lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			lock.offset_left=-6
			lock.offset_right=6
			lock.offset_top=-17
			lock.offset_bottom=-5

class Checkpoint extends Control:
	var current: bool=false
	var done: bool=false
	var locked: bool=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)
	func centre() -> Vector2:
		return Vector2(size.x/2,42 if current else size.y/2-2)
	func _draw() -> void:
		var center:=centre()
		var diameter:=54.0 if current else 50.0
		if current:
			var base:=Rect2(center+Vector2(-29,17),Vector2(58,11))
			draw_style_box(UI.box(Color("eebd36"),Color("ffe9a2"),8,0),base)
			draw_line(center+Vector2(-22,20),center+Vector2(22,20),Color("fff3a3"),2,true)
		draw_texture_rect(Aqua.badge(current,done,locked),Rect2(center-Vector2.ONE*diameter/2,Vector2.ONE*diameter),false)
		if current:
			var pole:=Vector2(center.x-20,1)
			draw_line(pole,Vector2(pole.x+7,58),Color("d49a21"),3,true)
			var flag:=PackedVector2Array([pole+Vector2(2,1),pole+Vector2(80,3),pole+Vector2(72,12),pole+Vector2(80,22),pole+Vector2(5,20)])
			draw_colored_polygon(flag,Color("009d9f"))
			flag.append(flag[0])
			draw_polyline(flag,Color("b8ffff"),1,true)
			for d in [Vector2(-10,-4),Vector2(-15,3),Vector2(-9,11)]:
				draw_line(pole+d,pole+d+Vector2(-3,-3),Color("f0bd32"),3,true)
		elif done:
			var tick:=center+Vector2(13,17)
			draw_circle(tick,10,Color("36b86b"))
			draw_arc(tick,10,0,TAU,28,Color.WHITE,1.5,true)
			draw_polyline(PackedVector2Array([tick+Vector2(-4,0),tick+Vector2(-1,3),tick+Vector2(5,-4)]),Color.WHITE,2,true)
		elif locked:
			var lock:=Vector2(center.x,size.y-11)
			draw_circle(lock,10,Color("42aabe"))
			draw_arc(lock,10,0,TAU,28,Color.WHITE,1.5,true)

class Route extends HBoxContainer:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var points:=get_children()
		for i in range(points.size()-1):
			var left=points[i]
			var right=points[i+1]
			var a: Vector2=left.position+left.centre()
			var b: Vector2=right.position+right.centre()
			var curve:=PackedVector2Array()
			for n in range(33):
				var t:=float(n)/32
				curve.append(a.lerp(b,t)+Vector2(0,sin(t*TAU)*5.0))
			# Draw the entire link behind medals, including unused slot space.
			draw_polyline(curve,Color("b4e9ed"),8,true)
			draw_polyline(curve,Color("26b5bd"),5,true)
			for n in range(0,30,4):
				draw_polyline(PackedVector2Array([curve[n],curve[n+1],curve[n+2]]),Color("edffff"),2,true)
