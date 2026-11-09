extends Control
# Noninteractive blue luminous showroom platform, used under the stage cards.
const ICE := Color("e5f9ff")
const CYAN := Color("53dcff")
var glow_clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	glow_clock += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 200.0 or h < 70.0:
		return
	var center := Vector2(w*0.5,h*0.60)
	var rx := w*0.47
	var ry := h*0.27
	# Soft base / marble platform elliptical layers.
	for layer in range(16,0,-1):
		var r := float(layer)
		_ellipse(center + Vector2(0.0, 6.0),rx+r*3.0,ry+r*1.2,
			Color(0.17,0.78,1.0,0.006+float(16-layer)*0.0025),3.0)
	_ellipse(center+Vector2(0,13),rx,ry,Color("9bbbd0"),8.0)
	_ellipse(center,rx,ry,Color(0.95,0.99,1.0,0.86),28.0)
	var opacity := 0.76 + 0.18*sin(glow_clock*1.8)
	_ellipse(center+Vector2(0,-2),rx,ry,Color(0.30,0.84,1.0,opacity),5.0)
	_ellipse(center+Vector2(0,-5),rx*0.96,ry*0.91,Color(0.98,1.0,1.0,0.91),2.0)
	_ellipse(center+Vector2(0,19),rx,ry,Color(0.16,0.70,1.0,0.73),3.0)
	for j in range(12):
		var xpos := w*(0.10 + float(j)*0.073)
		draw_line(Vector2(xpos,center.y-ry*0.52),
			Vector2(w*0.5+(xpos-w*0.5)*0.62,center.y+ry*0.52),
			Color(0.38,0.65,0.86,0.06),1.0,true)

func _ellipse(center: Vector2,rx: float,ry: float,col: Color,line_width: float) -> void:
	var points := PackedVector2Array()
	for i in range(97):
		var angle := TAU*float(i)/96.0
		points.append(center+Vector2(cos(angle)*rx,sin(angle)*ry))
	draw_polyline(points,col,line_width,true)
