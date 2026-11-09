extends Control
# Purely decorative original isometric kitchen/plan transition art.
# Transparent, no input, no gameplay state; designed for a blue daylight intro.
const OUTLINE := Color("308ed0")
const GLOW := Color("aee8ff")
const WHITE := Color("f8fdff")
const CABINET := Color("cbefff")
const SIDE := Color("91d3f0")
const DARK := Color("4d9fc8")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _polygon(points: Array[Vector2], color: Color, line_color: Color = OUTLINE) -> void:
	var p := PackedVector2Array(points)
	draw_colored_polygon(p, color)
	draw_polyline(PackedVector2Array(points + [points[0]]), line_color, 2.3, true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

var _time: float = 0.0

func _draw() -> void:
	if size.x < 300.0 or size.y < 180.0:
		return
	var scale_value: float = minf(size.x / 840.0, size.y / 420.0)
	var c := Vector2(size.x / 2.0, size.y / 2.0 + 22.0)
	draw_set_transform(c, 0.0, Vector2.ONE * scale_value)
	# Marble turntable with pale-blue luminous rim.
	var upper := PackedVector2Array()
	var lower := PackedVector2Array()
	for i in range(81):
		var a := TAU * float(i) / 80.0
		upper.append(Vector2(cos(a) * 380.0, 120.0 + sin(a) * 98.0))
		lower.append(Vector2(cos(a) * 380.0, 165.0 + sin(a) * 98.0))
	draw_colored_polygon(lower, Color("b7d5e3"))
	draw_colored_polygon(upper, Color("f5fcff"))
	draw_polyline(upper, Color(GLOW.r,GLOW.g,GLOW.b,0.75 + 0.23 * sin(_time*2.8)), 7.0, true)
	draw_polyline(lower, Color("5cc3f7"), 4.0, true)
	# Isometric white kitchen: back wall, sink run, right cooktop run.
	_polygon([Vector2(-260,-60), Vector2(-22,-171), Vector2(249,-70), Vector2(8,43)], Color("f7fdff"))
	_polygon([Vector2(-260,-60), Vector2(-22,-171), Vector2(-22,-40), Vector2(-260,70)], Color("a6ddf6"))
	_polygon([Vector2(-22,-171), Vector2(249,-70), Vector2(249,55), Vector2(-22,-40)], Color("d5f3ff"))
	# Under-counter cabinet faces and end panels.
	_polygon([Vector2(-248,-16), Vector2(-32,-112), Vector2(-32,27), Vector2(-248,119)], Color("bbecff"))
	_polygon([Vector2(-32,-112), Vector2(236,-17), Vector2(236,118), Vector2(-32,27)], Color("a6daf5"))
	# Quartz countertop outlines.
	_polygon([Vector2(-263,-39), Vector2(-29,-148), Vector2(250,-47), Vector2(22,58)], Color("ffffff"), Color("4c9fce"))
	# Kitchen L-cutout work area.
	_polygon([Vector2(-193,-35), Vector2(-29,-114), Vector2(204,-28), Vector2(137,1), Vector2(-28,-61), Vector2(-141,-5)], Color("d7effe"))
	draw_line(Vector2(-141,-5), Vector2(-28,-61), DARK, 2.0, true)
	draw_line(Vector2(-28,-61), Vector2(137,1), DARK, 2.0, true)
	# Cabinet joinery
	for i in range(1,4):
		var x := -247.0 + float(i) * 54.0
		draw_line(Vector2(x, -16 + float(i)*-21.0), Vector2(x, 111 + float(i)*-23.0), Color("5baed6"), 1.7, true)
	for i in range(1,4):
		draw_line(Vector2(-31.0 + i*60.0, -110 + i*21.0), Vector2(-31.0+i*60.0,24 + i*21.0), Color("5baed6"), 1.7, true)
	# Sink basin and faucet.
	_polygon([Vector2(-145,-34),Vector2(-82,-66),Vector2(-42,-51),Vector2(-107,-20)], Color("84b6d7"))
	_polygon([Vector2(-132,-34),Vector2(-85,-57),Vector2(-56,-47),Vector2(-106,-24)], Color("e4f5ff"))
	draw_arc(Vector2(-111,-46), 27, PI*1.07, TAU*0.05, 24, Color("4b869f"), 3.0, true)
	draw_line(Vector2(-84,-48), Vector2(-84,-13), Color("4b869f"), 3.0, true)
	# Black cooktop isometric island of four burners.
	_polygon([Vector2(65,-60),Vector2(141,-32),Vector2(197,-8),Vector2(119,-37)], Color("293e57"))
	for p in [Vector2(102,-46),Vector2(146,-30),Vector2(121,-23),Vector2(164,-10)]:
		draw_arc(p, 9.0, 0, TAU, 28, Color("c4e4fb"), 1.6, true)
	# Blueprint transition lines in front of left run.
	for start in [Vector2(-268,-70),Vector2(-248,-26),Vector2(-32,-113)]:
		draw_dashed_line(start, start + Vector2(0,170), Color(0.23,0.68,0.98,0.46), 1.8, 9.0, true)
	# The visual is a drawing game, represented by a drafting pencil.
	draw_line(Vector2(-290,-146), Vector2(-195,-69), Color("e5ac56"), 12, true)
	draw_line(Vector2(-195,-69), Vector2(-184,-57), Color("276ca9"), 5, true)
	draw_line(Vector2(-184,-57), Vector2(-176,-49), Color("eaf9ff"), 2, true)
	draw_set_transform(Vector2.ZERO)
