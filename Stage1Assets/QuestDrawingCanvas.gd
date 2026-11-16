extends "res://DrawingCanvas.gd"
# Stage 1 presentation only; input, snapping, dimensions and grading are inherited.
func _draw_dynamic_grid() -> void:
	var step: float = 100.0 / BASE_MM_PER_PX * zoom_level
	if step < 8.0:
		step *= 10.0
	var x: float = fposmod(pan.x, step)
	while x < size.x:
		draw_line(Vector2(x,0),Vector2(x,size.y),Color("dfecf8"),1.0)
		x += step
	var y: float = fposmod(pan.y, step)
	while y < size.y:
		draw_line(Vector2(0,y),Vector2(size.x,y),Color("dfecf8"),1.0)
		y += step

func _draw_solid_wall(a_mm: Vector2, b_mm: Vector2, highlight: bool, v_state: int = 0, is_selected: bool = false) -> void:
	super._draw_solid_wall(a_mm,b_mm,highlight,v_state,is_selected)
	var ink := Color("ff960b") if is_selected else Color("087cf0")
	if v_state == -1: ink = Color("dc2626")
	elif v_state == 1: ink = Color("16a34a")
	var a := _to_screen(a_mm)
	var b := _to_screen(b_mm)
	draw_line(a,b,ink,4.5,true)
	for point in [a,b]:
		draw_circle(point,6.0,ink,true,-1,true)
		draw_circle(point,3.8,Color.WHITE,true,-1,true)
