extends Control
# Original procedural pastel-blue background. No bitmap or kitchen photograph.
# This Control is decorative and cannot capture mouse input.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 1.0 or h < 1.0:
		return

	# Light-blue to ice-white vertical gradient (no photo assets).
	for i in range(92):
		var t := float(i) / 91.0
		var sky := Color("a7d3f0").lerp(Color("ecf9ff"), t)
		draw_rect(Rect2(0.0, t * h, w, h / 91.0 + 2.0), sky, true)

	# Subtle cyan light from the right for depth, without a photographic scene.
	for i in range(18, 0, -1):
		var radius := w * 0.09 + float(i) * w * 0.029
		var opacity := 0.008 + (18.0 - float(i)) * 0.001
		draw_circle(Vector2(w * 0.79, h * 0.33), radius, Color(0.97, 1.0, 1.0, opacity))

	# Clean architectural drafting guides and a faint horizon.
	draw_line(Vector2(0.0, h * 0.87), Vector2(w, h * 0.87), Color(0.47, 0.78, 0.96, 0.25), 2.0, true)
	for i in range(1, 18):
		var x := float(i) * w / 18.0
		draw_line(Vector2(x, h * 0.87), Vector2(w * 0.5 + (x - w * 0.5) * 1.75, h),
			Color(0.35, 0.73, 0.95, 0.09), 1.0, true)
	for i in range(1, 5):
		var y := h * 0.87 + pow(float(i) / 4.0, 1.5) * h * 0.13
		draw_line(Vector2(0.0, y), Vector2(w, y), Color(0.30, 0.69, 0.89, 0.07), 1.0, true)
