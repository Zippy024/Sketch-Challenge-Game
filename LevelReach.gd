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
		point.custom_minimum_size=Vector2(92,68) if point.current else Vector2(54,60)
		point.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		point.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		point.size_flags_stretch_ratio=1.12 if point.current else 1.0
		point.tooltip_text=UI.text("Stage %d")%n+"\n"+UI.text("Coming soon" if point.locked else ("Completed" if point.done else "Ready"))
		route.add_child(point)
		point.resized.connect(route.queue_redraw)
		point.item_rect_changed.connect(route.queue_redraw)
		var number:=UI.inline_label("%02d"%n,22 if point.current else 18,true)
		number.name="CurrentStageLabel" if point.current else "ReachStageLabel"
		number.set_meta("locale_ignore",true)
		number.add_theme_font_override("font",UI.font(true,"en"))
		number.add_theme_color_override("font_color",Color.WHITE if point.current else UI.INK)
		number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		point.add_child(number)
		number.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		number.offset_top=6 if point.current else 5
		number.offset_bottom=49 if point.current else 39
		if point.locked:
			var lock:=TextureRect.new()
			lock.name="CheckpointLock"
			lock.texture=UI.icon("lock")
			lock.modulate=Color("4e7c99")
			lock.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			lock.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			lock.mouse_filter=Control.MOUSE_FILTER_IGNORE
			point.add_child(lock)
			lock.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			lock.offset_left=-6
			lock.offset_right=6
			lock.offset_top=-26
			lock.offset_bottom=-14

class Checkpoint extends Control:
	var current: bool=false
	var done: bool=false
	var locked: bool=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)
	func centre() -> Vector2:
		return Vector2(size.x/2,34 if current else size.y/2)
	func _draw() -> void:
		var center:=centre()
		var diameter:=54.0 if current else 46.0
		if current:
			draw_circle(center,32,Color(0.15,0.87,0.91,0.13))
			draw_arc(center,30,0,TAU,64,Color("91f2f4"),1.5,true)
		draw_texture_rect(Aqua.badge(current,done,locked),Rect2(center-Vector2.ONE*diameter/2,Vector2.ONE*diameter),false)
		if current:
			var marker:=PackedVector2Array([center+Vector2(-6,-33),center+Vector2(6,-33),center+Vector2(0,-26)])
			draw_colored_polygon(marker,Color("009fac"))
			marker.append(marker[0])
			draw_polyline(marker,Color.WHITE,1,true)
		elif done:
			var tick:=center+Vector2(0,10)
			draw_polyline(PackedVector2Array([tick+Vector2(-6,0),tick+Vector2(-1,5),tick+Vector2(8,-5)]),Color("00a68d"),2.5,true)
			var star:=PackedVector2Array()
			var top:=center+Vector2(0,-24)
			for n in range(10):
				var a: float=-PI/2+float(n)*PI/5
				star.append(top+Vector2(cos(a),sin(a))*(4.5 if n%2==0 else 2.1))
			draw_colored_polygon(star,Color("e6b548"))

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
			# One continuous aqua ribbon runs behind the glass bubbles.
			draw_polyline(curve,Color("b1eaf0"),9,true)
			draw_polyline(curve,Color("66cddc"),5,true)
			draw_polyline(curve,Color("dcffff"),1.5,true)
		for side in [0,1]:
			var x:=5.0 if side==0 else size.x-5.0
			for y in [15.0,43.0]:
				draw_circle(Vector2(x,y),3,Color(0.8,0.97,1,0.65))
				draw_arc(Vector2(x,y),3,0,TAU,20,Color("a1d9e7"),0.8,true)
