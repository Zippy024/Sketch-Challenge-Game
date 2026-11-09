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
	# Neon path winds around the miniature kitchen stations instead of making
	# a flat progress list. Keep it behind the real clickable stage rooms.
	var route := PackedVector2Array([
		Vector2(w*0.17,h*0.40), Vector2(w*0.33,h*0.37),
		Vector2(w*0.49,h*0.40), Vector2(w*0.65,h*0.37),
		Vector2(w*0.82,h*0.41), Vector2(w*0.91,h*0.54),
		Vector2(w*0.82,h*0.76), Vector2(w*0.65,h*0.73),
		Vector2(w*0.49,h*0.76), Vector2(w*0.33,h*0.72),
		Vector2(w*0.17,h*0.76)
	])
	var active := PackedVector2Array()
	var future := PackedVector2Array()
	for i in range(route.size()):
		if i <= 4:
			active.append(route[i])
		if i >= 4:
			future.append(route[i])
	draw_polyline(active, Color(0.04,0.83,1.00,0.17), 21.0, true)
	draw_polyline(active, Color(0.48,0.96,1.00,0.84), 5.0, true)
	draw_polyline(future, Color(0.32,0.70,0.91,0.26), 10.0, true)
	draw_polyline(future, Color(0.67,0.86,0.99,0.43), 3.0, true)
	for i in range(6):
		var p: Vector2 = route[[0,2,4,10,8,6][i]]
		var is_open: bool = i < 3
		var glow: float = 0.70 + 0.15 * sin(_motion*2.0 + float(i))
		draw_circle(p, 18.0, Color(0.10,0.80,1.0,0.19) if is_open else Color(0.55,0.67,0.77,0.09))
		draw_circle(p, 8.0, Color(0.62,0.95,1.0,glow) if is_open else Color("68839e"))
		draw_arc(p, 12, 0, TAU, 40, CYAN if is_open else Color("839caf"), 2.0, true)

	# Drafting marks around the map perimeter.
	for p in [Vector2(23,22),Vector2(w-23,22),Vector2(23,h-22),Vector2(w-23,h-22)]:
		draw_line(p+Vector2(-12,0),p+Vector2(12,0),Color(0.61,0.88,1,0.52),1.5,true)
		draw_line(p+Vector2(0,-12),p+Vector2(0,12),Color(0.61,0.88,1,0.52),1.5,true)
