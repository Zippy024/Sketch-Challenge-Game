extends Control
var stage_index: int=1
var reveal: float=1.0:
	set(value):
		reveal=value
		queue_redraw()

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var reduced:=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	if not reduced:
		reveal=0
		create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).tween_property(self,"reveal",1.0,0.85)

func _stroke(points: Array, ink: Color, width: float=3.0) -> void:
	var total:=0.0
	for i in range(points.size()-1):total+=(Vector2(points[i+1])-Vector2(points[i])).length()
	var left:=total*clampf(reveal*1.4,0,1)
	for i in range(points.size()-1):
		var a: Vector2=points[i]
		var b: Vector2=points[i+1]
		var length: float=a.distance_to(b)
		if left<=0:break
		draw_line(a,a.lerp(b,minf(1,left/maxf(length,0.001))),ink,width,true)
		left-=length

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,size/Vector2(210,190))
	var grid:=Color("c2e3ec")
	for x in range(10,211,16):draw_line(Vector2(x,8),Vector2(x,182),grid,0.7)
	for y in range(8,191,16):draw_line(Vector2(8,y),Vector2(202,y),grid,0.7)
	var ink:=Color("006f87")
	if stage_index==1:
		_stroke([Vector2(25,27),Vector2(145,27),Vector2(145,91),Vector2(180,91),Vector2(180,156),Vector2(25,156),Vector2(25,27)],ink,4)
		_stroke([Vector2(47,113),Vector2(105,113),Vector2(105,135),Vector2(47,135),Vector2(47,113)],Color("72b8c8"),2)
		_stroke([Vector2(98,48),Vector2(124,48),Vector2(124,88)],Color("72b8c8"),3)
	elif stage_index==2:
		_stroke([Vector2(33,23),Vector2(162,23),Vector2(162,164),Vector2(33,164),Vector2(33,23)],Color("72b8c8"),2)
		for x in [65,96,127]:
			_stroke([Vector2(x,36),Vector2(x,130),Vector2(x+12,142)],ink,5)
			draw_circle(Vector2(x,38),5,Color("6dd5d3"))
	else:
		_stroke([Vector2(22,96),Vector2(180,96),Vector2(180,157),Vector2(22,157),Vector2(22,96)],ink,4)
		_stroke([Vector2(22,116),Vector2(180,116)],Color("72b8c8"),2)
		for x in [61,102,143]:_stroke([Vector2(x,116),Vector2(x,155)],Color("72b8c8"),2)
		_stroke([Vector2(39,41),Vector2(145,41),Vector2(145,78),Vector2(39,78),Vector2(39,41)],ink,3)
		_stroke([Vector2(92,42),Vector2(92,78)],Color("72b8c8"),2)
	var alpha:=clampf((reveal-0.45)/0.55,0,1)
	draw_circle(Vector2(171,146),26,Color(0.0,0.62,0.61,alpha))
	draw_arc(Vector2(171,146),27,-PI/2,TAU*alpha-PI/2,40,Color(0.57,0.95,0.91,alpha),2,true)
	if alpha>0.2:draw_polyline(PackedVector2Array([Vector2(158,146),Vector2(167,155),Vector2(185,135)]),Color(1,1,1,alpha),4,true)
	draw_set_transform(Vector2.ZERO)
