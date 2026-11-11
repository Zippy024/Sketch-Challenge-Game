extends Control
# One short celebration; no textures, input interception or endless loop.
var reduced_motion: bool = false
var elapsed: float = 0.0
var duration: float = 4.5
var particles: Array[Dictionary] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	reduced_motion=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	if reduced_motion:
		set_process(false)
		return
	var random := RandomNumberGenerator.new()
	random.randomize()
	var colors := [Color("18c8c6"),Color("9fe9ff"),Color("ffd77a"),Color("ffffff")]
	for i in range(76):
		particles.append({"x":random.randf(),"start":random.randf_range(-120,0),"delay":random.randf_range(0,1.0),"speed":random.randf_range(170,290),"drift":random.randf_range(-35,35),"spin":random.randf_range(-4,4),"phase":random.randf_range(0,TAU),"width":random.randf_range(4,7),"color":colors[i%colors.size()]})

func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed>=duration:
		particles.clear()
		set_process(false)
	queue_redraw()

func _draw() -> void:
	for piece in particles:
		var age: float=elapsed-float(piece.delay)
		if age<0: continue
		var point := Vector2(float(piece.x)*size.x+float(piece.drift)*age+sin(age*3+float(piece.phase))*16,float(piece.start)+float(piece.speed)*age)
		var ink: Color=piece.color
		ink.a=clampf((duration-elapsed)/0.8,0,0.9)
		draw_set_transform(point,float(piece.phase)+age*float(piece.spin),Vector2(1,maxf(0.18,absf(cos(age*4+float(piece.phase))))))
		draw_rect(Rect2(-float(piece.width)*0.5,-3,float(piece.width),9),ink)
	draw_set_transform(Vector2.ZERO)
