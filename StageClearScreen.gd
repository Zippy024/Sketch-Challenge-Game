extends Control
# Animated Stage 1 success overlay; gameplay evaluation is handled by Main.gd.
signal next_requested
signal levels_requested

const TEAL := Color("00b994")
const DEEP := Color("004e44")
const WHITE := Color("ffffff")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modulate.a = 0.0
	var dark := ColorRect.new()
	dark.color = Color(0.025, 0.15, 0.15, 0.72)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(570, 430)
	panel.add_theme_stylebox_override("panel", _style(Color(0.82, 1, 0.96, 0.96), Color(1, 1, 1, 0.96), 30, 30))
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 16)
	panel.add_child(stack)
	var check := Label.new()
	check.text = "✓"
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.add_theme_font_size_override("font_size", 79)
	check.add_theme_color_override("font_color", Color("00a87e"))
	stack.add_child(check)
	var headline := Label.new()
	headline.text = "Correct!"
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.add_theme_font_size_override("font_size", 48)
	headline.add_theme_color_override("font_color", DEEP)
	stack.add_child(headline)
	var body := Label.new()
	body.text = "The LDK area is drawn correctly."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 20)
	body.add_theme_color_override("font_color", DEEP)
	stack.add_child(body)
	var next := Button.new()
	next.text = "Continue to Stage 2  »"
	next.custom_minimum_size = Vector2(340, 55)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.add_theme_font_size_override("font_size", 20)
	next.add_theme_color_override("font_color", WHITE)
	next.add_theme_color_override("font_hover_color", WHITE)
	next.add_theme_stylebox_override("normal", _style(TEAL, Color("8bffdf"), 27, 15))
	next.add_theme_stylebox_override("hover", _style(DEEP, Color("8bffdf"), 27, 15))
	next.add_theme_stylebox_override("pressed", _style(DEEP, WHITE, 27, 15))
	next.pressed.connect(func() -> void: next_requested.emit())
	stack.add_child(next)
	var levels := Button.new()
	levels.text = "Levels"
	levels.custom_minimum_size = Vector2(140, 40)
	levels.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	levels.add_theme_stylebox_override("normal", _style(Color(0.94, 1, 0.97, 1), Color("a8e6d5"), 20, 8))
	levels.pressed.connect(func() -> void: levels_requested.emit())
	stack.add_child(levels)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	check.pivot_offset = check.size / 2.0
	var bump := create_tween()
	bump.tween_property(check, "scale", Vector2(1.12, 1.12), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bump.tween_property(check, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_SINE)

func _style(fill: Color, border: Color, radius: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	return s
