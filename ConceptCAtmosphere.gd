extends Control
# Subtle animated cinematic-console HUD. Decorative only: never intercepts input.
var elapsed: float = 0.0
const COPPER := Color("d7ab78")
const EMERALD := Color("87d3ae")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 50.0 or h <= 50.0:
		return
	# Thin metallic frame and an animated warm highlight.
	draw_line(Vector2(26, 10), Vector2(w-26, 10), Color(0.72,0.54,0.35,0.25), 1.0)
	var scan_x: float = 35.0 + fposmod(elapsed * 88.0, maxf(1.0, w - 240.0))
	draw_line(Vector2(scan_x, 10), Vector2(minf(w-28.0, scan_x+150.0), 10), Color(COPPER.r,COPPER.g,COPPER.b,0.55), 2.0, true)
	for i in range(4):
		var px: float = w - 48.0 - float(i) * 18.0
		var alpha: float = 0.20 + 0.15 * (0.5 + 0.5 * sin(elapsed * 1.6 + float(i) * 0.8))
		draw_circle(Vector2(px, h-18.0), 2.4, Color(EMERALD.r,EMERALD.g,EMERALD.b,alpha))
	# Minimal architectural corner details in copper.
	for side in [0,1]:
		var x: float = 24.0 if side == 0 else w-24.0
		var direction: float = 1.0 if side == 0 else -1.0
		draw_line(Vector2(x,h-36.0), Vector2(x,h-18.0), Color(COPPER.r,COPPER.g,COPPER.b,0.35), 1.5)
		draw_line(Vector2(x,h-18.0), Vector2(x+direction*24.0,h-18.0), Color(COPPER.r,COPPER.g,COPPER.b,0.35), 1.5)
