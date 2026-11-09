extends Control
# Decorative blueprint mission map. Never owns controls, progress or game logic.
const NAVY := Color("0a315c")
const GRID := Color(0.42, 0.77, 1.00, 0.13)
const CYAN := Color("4de3ff")
const ICE := Color("d9f8ff")
var _motion: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	_motion += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 150 or h < 150:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("0d3c6c"))
	for step in range(int(w / 32.0) + 2):
		var x: float = float(step) * 32.0
		draw_line(Vector2(x, 0), Vector2(x, h), GRID, 1.0, true)
	for step in range(int(h / 32.0) + 2):
		var y: float = float(step) * 32.0
		draw_line(Vector2(0, y), Vector2(w, y), GRID, 1.0, true)
	# Faint architectural plan, behind the real stage cards.
	var outline := PackedVector2Array([
		Vector2(w*0.21,h*0.29), Vector2(w*0.47,h*0.29),
		Vector2(w*0.47,h*0.44), Vector2(w*0.65,h*0.44),
		Vector2(w*0.65,h*0.79), Vector2(w*0.21,h*0.79),
		Vector2(w*0.21,h*0.29)
	])
	draw_polyline(outline, Color(0.72,0.90,1.0,0.19), 3.0, true)
	draw_line(Vector2(w*0.21,h*0.49),Vector2(w*0.47,h*0.49),Color(0.72,0.9,1.0,0.13),2.0,true)
	draw_line(Vector2(w*0.37,h*0.49),Vector2(w*0.37,h*0.79),Color(0.72,0.9,1.0,0.13),2.0,true)
	draw_rect(Rect2(Vector2(w*0.29,h*0.57),Vector2(w*0.19,h*0.095)),Color(0.77,0.91,1.0,0.075),true)
	# S-shaped training route. Neon for available stages and dim blue for future.
	var route := PackedVector2Array([
		Vector2(w*0.17,h*0.70), Vector2(w*0.25,h*0.63),
		Vector2(w*0.33,h*0.63), Vector2(w*0.42,h*0.70),
		Vector2(w*0.51,h*0.70), Vector2(w*0.58,h*0.64),
		Vector2(w*0.65,h*0.64),Vector2(w*0.72,h*0.71),
		Vector2(w*0.80,h*0.71),Vector2(w*0.89,h*0.64)
	])
	var active := PackedVector2Array()
	var future := PackedVector2Array()
	for i in range(route.size()):
		if i <= 5: active.append(route[i])
		if i >= 5: future.append(route[i])
	draw_polyline(active,Color(0.02,0.79,1.0,0.13),16.0,true)
	draw_polyline(active,Color(0.20,0.84,1.0,0.69),4.5,true)
	draw_polyline(future,Color(0.65,0.81,0.92,0.29),3.0,true)
	var dot_positions := [route[0],route[2],route[5],route[6],route[8],route[9]]
	for i in range(dot_positions.size()):
		var p: Vector2 = dot_positions[i]
		var is_open: bool = i < 3
		var glow: float = 0.70 + 0.15 * sin(_motion*2.0 + float(i))
		draw_circle(p,15.0,Color(0.10,0.80,1.0,0.10) if is_open else Color(0.55,0.67,0.77,0.10))
		draw_circle(p,7.0,Color(0.60,0.95,1.0,glow) if is_open else Color("678198"))
		draw_arc(p,11,0.0,TAU,36,CYAN if is_open else Color("829bb0"),2.0,true)
	# Drafting marks around the map perimeter.
	for p in [Vector2(23,22),Vector2(w-23,22),Vector2(23,h-22),Vector2(w-23,h-22)]:
		draw_line(p+Vector2(-12,0),p+Vector2(12,0),Color(0.61,0.88,1,0.52),1.5,true)
		draw_line(p+Vector2(0,-12),p+Vector2(0,12),Color(0.61,0.88,1,0.52),1.5,true)
