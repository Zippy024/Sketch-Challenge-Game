extends Control
# Lightweight decorative cinematic sparkles, no controls, no gameplay state.
const GOLD := Color("ffd393")
const COPPER := Color("eaa06b")
var elapsed: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if size.x < 20.0 or size.y < 20.0:
		return
	var width_value: float = size.x
	var height_value: float = size.y
	for i in range(28):
		var u: float = fposmod(float(i) * 0.618033 + sin(elapsed * 0.14 + float(i)) * 0.016, 1.0)
		var v: float = fposmod(float(i) * 0.3773 - elapsed * (0.007 + float(i % 3) * 0.003), 1.0)
		var a: float = 0.22 + 0.30 * (0.5 + 0.5 * sin(elapsed * 1.7 + float(i) * 1.61))
		var pos := Vector2(u * width_value, v * height_value)
		var radius: float = 1.3 + float(i % 3) * 0.55
		draw_circle(pos, radius, Color(GOLD.r, GOLD.g, GOLD.b, a))
		if i % 8 == 0:
			draw_line(pos + Vector2(-7, 0), pos + Vector2(7, 0), Color(COPPER.r, COPPER.g, COPPER.b, a * 0.8), 1.4, true)
			draw_line(pos + Vector2(0, -7), pos + Vector2(0, 7), Color(COPPER.r, COPPER.g, COPPER.b, a * 0.8), 1.4, true)
	# Animated light ribbon along lower edge, like a mission-map horizon.
	var start_x: float = width_value * 0.07
	var end_x: float = width_value * 0.93
	var run: float = maxf(1.0, end_x - start_x)
	for k in range(22):
		var t: float = float(k) / 21.0
		var wave: float = sin(t * 7.5 + elapsed * 0.44) * 7.0
		var from_pos := Vector2(start_x + run * t, height_value - 38.0 + wave)
		var to_pos := Vector2(start_x + run * (t + 1.0 / 22.0), height_value - 38.0 + sin((t + 1.0 / 22.0) * 7.5 + elapsed * 0.44) * 7.0)
		draw_line(from_pos, to_pos, Color(COPPER.r, COPPER.g, COPPER.b, 0.21), 2.0, true)
