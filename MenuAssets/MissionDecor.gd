extends Control
# Resolution-independent accents; all decoration lets clicks reach the card.
enum Kind { NUMBER, STARS, JOURNEY, SPARKLES, LINK, TOTAL_STAR }
var kind: Kind=Kind.STARS
var earned: int=0
var available: bool=true
var completed: Array[bool]=[]
var current_stage: int=0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _star(center: Vector2, radius: float, filled: bool) -> void:
	var points:=PackedVector2Array()
	for i in range(10):
		var angle: float=-PI/2+float(i)*PI/5
		points.append(center+Vector2(cos(angle),sin(angle))*(radius if i%2==0 else radius*0.45))
	draw_colored_polygon(points,Color("f2c55e") if filled else Color("fffdf0"))
	points.append(points[0])
	draw_polyline(points,Color("bd9040") if filled else Color("9d9b7c"),1.2,true)

func _draw() -> void:
	match kind:
		Kind.NUMBER:
			var points:=PackedVector2Array([Vector2(16,0),Vector2(57,0),Vector2(45,38),Vector2(0,42),Vector2(0,16)])
			for i in range(1,8):
				var angle: float=PI+float(i)*PI/16
				points.append(Vector2(16,16)+Vector2(cos(angle),sin(angle))*16)
			var light:=Color("34b8b4") if available else Color("a1bbb0")
			var dark:=Color("007c80") if available else Color("668b80")
			var colors:=PackedColorArray()
			for point in points:colors.append(light.lerp(dark,point.y/42.0))
			draw_polygon(points,colors)
			draw_polyline(PackedVector2Array([Vector2(2,36),Vector2(2,2),Vector2(51,2)]),Color(1,1,0.91,0.8),1.5,true)
		Kind.STARS:
			for i in range(3):_star(Vector2(size.x*0.5+(i-1)*26,size.y*0.5),8.5,i<earned)
		Kind.TOTAL_STAR:
			_star(size*0.5,10,true)
		Kind.JOURNEY:
			var points: Array[Vector2]=[]
			for i in range(3):points.append(Vector2(size.x*(0.15+i*0.35),size.y*0.5))
			draw_line(Vector2(0,size.y*0.5),Vector2(size.x,size.y*0.5),Color("b7ccc3"),6,true)
			for i in range(2):
				if completed[i]:draw_line(points[i],points[i+1],Color("369f95"),6,true)
			for i in range(3):
				var point: Vector2=points[i]
				draw_circle(point+Vector2(0,2),15,Color(0.19,0.32,0.26,0.12))
				draw_circle(point,14,Color("fffdf0"))
				draw_arc(point,14,0,TAU,48,Color("9abaad") if i+1==current_stage else Color("d2d9c2"),1.2,true)
				_star(point,8.5,completed[i])
		Kind.SPARKLES:
			for point in [Vector2(3,4),Vector2(size.x-3,7),Vector2(3,size.y-4),Vector2(size.x-3,size.y-5)]:
				var sparkle:=PackedVector2Array()
				for i in range(8):
					var angle: float=float(i)*PI/4
					sparkle.append(point+Vector2(cos(angle),sin(angle))*(8 if i%2==0 else 2))
				draw_colored_polygon(sparkle,Color("fff7cd"))
				draw_circle(point,1.8,Color("fffefa"))
		Kind.LINK:
			for i in range(3):draw_circle(Vector2(2+i*5,size.y*0.5),1.5,Color(1,1,0.96,0.75))
