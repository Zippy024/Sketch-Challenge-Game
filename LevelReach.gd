extends PanelContainer
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
var current_stage: int=1
var compact: bool=false
var _state: int=-1
var _elapsed: float=0.0

func _ready() -> void:
	name="LevelReachTrack"
	custom_minimum_size.y=42
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=UI.box(Color(0.94,0.99,1,0.94) if not compact else Color(0.86,0.96,0.99,0.7),Color("bbdee9") if not compact else Color.TRANSPARENT,14,5)
	style.content_margin_left=12
	style.content_margin_right=12
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
	route.add_theme_constant_override("separation",5)
	add_child(route)
	if not compact:
		var title:=UI.inline_label("Level reach",12,true)
		title.custom_minimum_size.x=110
		route.add_child(title)
	for n in range(1,4 if compact else 11):
		if n>1:
			var bridge:=Bridge.new()
			bridge.active=Progress.is_completed(n-1)
			bridge.custom_minimum_size.x=13
			route.add_child(bridge)
		var point:=Checkpoint.new()
		point.name="ReachNode%02d"%n
		point.done=Progress.is_completed(n)
		point.current=n==current_stage
		point.locked=n>3
		point.set_meta("stage",n)
		point.set_meta("completed",point.done)
		point.set_meta("current",point.current)
		point.set_meta("locked",point.locked)
		point.custom_minimum_size=Vector2(65 if n<=3 else 43,30)
		point.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		point.size_flags_vertical=Control.SIZE_SHRINK_CENTER
		point.size_flags_stretch_ratio=1.5 if n<=3 else 0.75
		point.tooltip_text=UI.text("Stage %d")%n+"\n"+UI.text("Coming soon" if n>3 else ("Completed" if point.done else "Ready"))
		route.add_child(point)
		var row:=HBoxContainer.new()
		row.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",6)
		point.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left=8
		row.offset_right=-8
		var icon:=TextureRect.new()
		icon.texture=preload("res://MenuAssets/level-lock.svg") if n>3 else UI.icon("check" if point.done else ["plan","chat","cube"][n-1])
		icon.modulate=Color.WHITE if point.current else (UI.TEAL if point.done else UI.MUTED)
		icon.custom_minimum_size=Vector2(15 if n>3 else 18,18)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var number:=UI.inline_label("%02d"%n,12,true)
		number.set_meta("locale_ignore",true)
		number.add_theme_color_override("font_color",Color.WHITE if point.current else (UI.MUTED if point.locked else UI.INK))
		row.add_child(number)

class Checkpoint extends Control:
	var current: bool=false
	var done: bool=false
	var locked: bool=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_PASS
		resized.connect(queue_redraw)
	func _draw() -> void:
		var cut:=7.0
		var shape:=PackedVector2Array([Vector2(cut,1),Vector2(size.x-cut,1),Vector2(size.x-1,size.y*0.5),Vector2(size.x-cut,size.y-1),Vector2(cut,size.y-1),Vector2(1,size.y*0.5)])
		var fill:=Color("008c9c") if current else (Color("d9f5f2") if done else (Color("e9eff4") if locked else Color("f8fdff")))
		var edge:=Color("34d8dc") if current else (Color("70c9c9") if done else Color("c4dbe6"))
		draw_colored_polygon(shape,fill)
		var outline:=shape.duplicate()
		outline.append(shape[0])
		draw_polyline(outline,edge,2.0 if current else 1.0,true)
		if current:draw_line(Vector2(11,4),Vector2(size.x-11,4),Color("8df4f2"),1.0,true)

class Bridge extends Control:
	var active: bool=false
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		var ink:=Color("24b9ba") if active else Color("b9d4df")
		for i in range(3):draw_circle(Vector2(2+i*4,size.y*0.5),1.3,ink)
