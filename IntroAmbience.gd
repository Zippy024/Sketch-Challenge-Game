extends Control
var _phase: float=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true)):
		set_process(false)
func _process(delta: float) -> void:
	_phase=fmod(_phase+delta,TAU)
	queue_redraw()
func _draw() -> void:
	var points=[Vector2(679,209),Vector2(1354,442),Vector2(1140,708)]
	for i in range(points.size()):
		var wave: float=(sin(_phase*1.3+float(i)*2.0)+1.0)*0.5
		var r: float=3.0+wave*4.0
		var center: Vector2=points[i]+Vector2(0,sin(_phase+float(i))*3)
		var shape:=PackedVector2Array([center+Vector2(0,-r),center+Vector2(r*0.25,-r*0.25),center+Vector2(r,0),center+Vector2(r*0.25,r*0.25),center+Vector2(0,r),center+Vector2(-r*0.25,r*0.25),center+Vector2(-r,0),center+Vector2(-r*0.25,-r*0.25)])
		draw_colored_polygon(shape,Color(1.0,0.87,0.51,0.18+wave*0.46))
