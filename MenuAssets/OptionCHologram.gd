extends Control
# Decorative holographic kitchen / floor-plan preview; all click controls live in Godot UI.
const MINT := Color("5ae9c4")
const LIGHT := Color("d6fff4")
var motion := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(254, 166)
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	motion += delta
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 30.0 or h < 30.0:
		return
	var c := Vector2(w * 0.50, h * 0.52)
	var scale_value := minf(w / 260.0, h / 170.0)
	var pulse := 0.55 + 0.22 * sin(motion * 1.7)
	var line := Color(MINT.r, MINT.g, MINT.b, pulse)
	var p := PackedVector2Array([
		Vector2(-101,-10), Vector2(-32,-49), Vector2(93,-11), Vector2(29,35), Vector2(-101,-10),
		Vector2(-101,45), Vector2(-32,79), Vector2(93,42), Vector2(93,-11),
	])
	var iso := PackedVector2Array()
	for v in p:
		iso.append(c + v * scale_value)
	draw_polyline(iso, line, 2.0, true)
	for pair in [
		[Vector2(-101,-10),Vector2(-101,45)],
		[Vector2(-32,-49),Vector2(-32,9)],
		[Vector2(29,35),Vector2(29,83)],
		[Vector2(-32,9),Vector2(93,-11)],
		[Vector2(-101,45),Vector2(29,83)],
		[Vector2(-32,9),Vector2(29,35)]
	]:
		draw_line(c + pair[0] * scale_value, c + pair[1] * scale_value, line, 1.6, true)
	var counter := PackedVector2Array([
		Vector2(-49,21),Vector2(14,4),Vector2(56,25),Vector2(-8,44),Vector2(-49,21)
	])
	var counter_draw := PackedVector2Array()
	for v in counter:
		counter_draw.append(c + v * scale_value)
	draw_colored_polygon(counter_draw, Color(0.27,0.90,0.75,0.11))
	draw_polyline(counter_draw, LIGHT, 1.5, true)
	for t in range(12):
		var x := float(t) * w / 11.0
		draw_line(Vector2(x,0), Vector2(x,h), Color(0.50,1,0.85,0.055), 1)
	for t in range(8):
		var y := float(t) * h / 7.0
		draw_line(Vector2(0,y), Vector2(w,y), Color(0.50,1,0.85,0.055), 1)
