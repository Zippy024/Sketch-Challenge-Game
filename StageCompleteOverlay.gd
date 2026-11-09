extends Control
<<<<<<< Updated upstream
# Shared, fully interactive achievement overlay. No stage gameplay or grading changes.
# Confetti and success emblem are drawn by Godot each frame, NOT a static PNG.
=======
>>>>>>> Stashed changes

signal next_requested
signal levels_requested
signal replay_requested

<<<<<<< Updated upstream
const BG := Color(0.05, 0.11, 0.14, 0.42)
const WHITE := Color("ffffff")
const TEXT := Color("193d43")
const SUBTEXT := Color("48666b")
const GREEN := Color("119661")
const GREEN_DARK := Color("087c50")
const GREEN_PALE := Color("eefaf4")
const OUTLINE := Color("d5e5df")


class SuccessMark extends Control:
    func _ready() -> void:
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        custom_minimum_size = Vector2(88, 88)
    func _draw() -> void:
        var midpoint: Vector2 = size * 0.5
        draw_circle(midpoint, 40, Color("119661"))
        draw_arc(midpoint, 38, 0.0, TAU, 64, Color("54dca4"), 3.0, true)
        draw_line(midpoint + Vector2(-19, 0), midpoint + Vector2(-5, 14), Color.WHITE, 8.0, true)
        draw_line(midpoint + Vector2(-5, 14), midpoint + Vector2(22, -17), Color.WHITE, 8.0, true)

class FallingConfetti extends Control:
    const PALETTE := [Color("22c55e"), Color("f59e0b"), Color("38bdf8"), Color("ec4899"), Color("a78bfa")]
    var pieces: Array[Dictionary] = []
    var time_elapsed: float = 0.0

    func _ready() -> void:
        set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        mouse_filter = Control.MOUSE_FILTER_IGNORE
        var rng := RandomNumberGenerator.new()
        rng.randomize()
        for i in range(92):
            pieces.append({
                "x": rng.randf_range(0.02, 0.98),
                "y": rng.randf_range(-0.85, 0.03),
                "speed": rng.randf_range(0.16, 0.32),
                "swing": rng.randf_range(0.008, 0.04),
                "phase": rng.randf_range(0.0, TAU),
                "length": rng.randf_range(6.0, 13.0),
                "color": PALETTE[i % PALETTE.size()]
            })

    func _process(delta: float) -> void:
        time_elapsed += delta
        if time_elapsed > 6.2:
            set_process(false)
            visible = false
            return
        for i in range(pieces.size()):
            var piece: Dictionary = pieces[i]
            piece["y"] = float(piece["y"]) + float(piece["speed"]) * delta
            if float(piece["y"]) > 1.06:
                piece["y"] = -0.05
            pieces[i] = piece
        queue_redraw()

    func _draw() -> void:
        for item in pieces:
            var x: float = float(item["x"]) + sin(time_elapsed * 2.4 + float(item["phase"])) * float(item["swing"])
            var y: float = float(item["y"])
            var point := Vector2(x * size.x, y * size.y)
            var length: float = float(item["length"])
            var c: Color = item["color"]
            c.a = 0.88
            draw_rect(Rect2(point, Vector2(length * 0.55, length)), c, true)
=======
const BG := Color(0.06, 0.12, 0.18, 0.35)
const WHITE := Color("ffffff")
const TEXT := Color("1f3c56")
const SUBTEXT := Color("6b7f98")
const GREEN := Color("16a34a")
const GREEN_DARK := Color("15803d")
const GREEN_PALE := Color("f0fdf4")
const OUTLINE := Color("d6e2ef")
>>>>>>> Stashed changes

var title_text: String = "Stage Complete!"
var subtitle_text: String = "Great job. You cleared this stage."
var next_text: String = "Next Stage"
var levels_text: String = "Levels"
var replay_text: String = "Replay"
var show_next_button: bool = true
var show_replay_button: bool = false

func configure(title_value: String, subtitle_value: String, next_value: String = "Next Stage", levels_value: String = "Levels", replay_value: String = "Replay", allow_next: bool = true, allow_replay: bool = false) -> void:
<<<<<<< Updated upstream
    title_text = title_value
    subtitle_text = subtitle_value
    next_text = next_value
    levels_text = levels_value
    replay_text = replay_value
    show_next_button = allow_next
    show_replay_button = allow_replay
    if is_inside_tree():
        _build()

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build()

func _style(bg: Color, edge: Color = OUTLINE, radius: int = 18, padding: int = 0) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = bg
    s.border_color = edge
    s.set_border_width_all(1)
    s.set_corner_radius_all(radius)
    s.set_content_margin_all(padding)
    return s

func _label(text_value: String, font_size: int, color: Color = TEXT, centered: bool = true) -> Label:
    var l := Label.new()
    l.text = text_value
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button(caption: String, primary: bool = false) -> Button:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(145, 46)
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", WHITE if primary else TEXT)
    button.add_theme_color_override("font_hover_color", WHITE if primary else GREEN_DARK)
    button.add_theme_color_override("font_pressed_color", WHITE if primary else GREEN_DARK)
    button.add_theme_stylebox_override("normal", _style(GREEN if primary else WHITE, GREEN if primary else OUTLINE, 12, 10))
    button.add_theme_stylebox_override("hover", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 10))
    button.add_theme_stylebox_override("pressed", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 10))
    button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GREEN, 12, 0))
    return button

func _build() -> void:
    for child in get_children():
        remove_child(child)
        child.queue_free()

    var shade := ColorRect.new()
    shade.color = BG
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(shade)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var center := CenterContainer.new()
    add_child(center)
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(510, 340)
    card.add_theme_stylebox_override("panel", _style(WHITE, OUTLINE, 22, 30))
    center.add_child(card)
    var stack := VBoxContainer.new()
    stack.alignment = BoxContainer.ALIGNMENT_CENTER
    stack.add_theme_constant_override("separation", 12)
    card.add_child(stack)

    var check := SuccessMark.new()
    check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    stack.add_child(check)
    stack.add_child(_label(title_text, 30, TEXT, true))
    stack.add_child(_label(subtitle_text, 16, SUBTEXT, true))
    var result := _label("100% COMPLETED", 14, GREEN, true)
    stack.add_child(result)

    var buttons := HBoxContainer.new()
    buttons.alignment = BoxContainer.ALIGNMENT_CENTER
    buttons.add_theme_constant_override("separation", 10)
    stack.add_child(buttons)
    if show_replay_button:
        var replay := _button(replay_text, false)
        replay.pressed.connect(func() -> void: replay_requested.emit())
        buttons.add_child(replay)
    if show_next_button:
        var next := _button(next_text, true)
        next.pressed.connect(func() -> void: next_requested.emit())
        buttons.add_child(next)
    var levels := _button(levels_text, false)
    levels.pressed.connect(func() -> void: levels_requested.emit())
    buttons.add_child(levels)

    # Draw particles above the backdrop, below the interactive success card.
    var confetti := FallingConfetti.new()
    add_child(confetti)
    confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    move_child(confetti, 1)

    # The check is animated, so this is an actual cheer screen, not an image.
    card.modulate.a = 0.0
    check.scale = Vector2(0.38, 0.38)
    check.pivot_offset = Vector2(44, 44)
    var tween := create_tween()
    tween.tween_property(card, "modulate:a", 1.0, 0.36).set_trans(Tween.TRANS_SINE)
    tween.parallel().tween_property(check, "scale", Vector2.ONE, 0.54).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
=======
	title_text = title_value
	subtitle_text = subtitle_value
	next_text = next_value
	levels_text = levels_value
	replay_text = replay_value
	show_next_button = allow_next
	show_replay_button = allow_replay
	if is_inside_tree():
		_build()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()

func _style(bg: Color, edge: Color = OUTLINE, radius: int = 18, padding: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(padding)
	return s

func _label(text_value: String, size_value: int, color_value: Color = TEXT, centered: bool = true) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size_value)
	l.add_theme_color_override("font_color", color_value)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text_value: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(150, 44)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", WHITE if primary else TEXT)
	b.add_theme_color_override("font_hover_color", WHITE if primary else GREEN_DARK)
	b.add_theme_color_override("font_pressed_color", WHITE if primary else GREEN_DARK)
	b.add_theme_stylebox_override("normal", _style(GREEN if primary else WHITE, GREEN if primary else OUTLINE, 12, 10))
	b.add_theme_stylebox_override("hover", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 10))
	b.add_theme_stylebox_override("pressed", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 10))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GREEN, 12, 0))
	return b

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var shade := ColorRect.new()
	shade.color = BG
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 300)
	card.add_theme_stylebox_override("panel", _style(WHITE, OUTLINE, 24, 24))
	center.add_child(card)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 12)
	card.add_child(stack)

	var icon_circle := PanelContainer.new()
	icon_circle.custom_minimum_size = Vector2(86, 86)
	icon_circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_circle.add_theme_stylebox_override("panel", _style(GREEN, GREEN, 43, 0))
	stack.add_child(icon_circle)
	var check := _label("✓", 46, WHITE, true)
	check.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_circle.add_child(check)

	stack.add_child(_label(title_text, 28, TEXT, true))
	stack.add_child(_label(subtitle_text, 15, SUBTEXT, true))

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	stack.add_child(row)

	if show_replay_button:
		var replay_btn := _button(replay_text, false)
		replay_btn.pressed.connect(func() -> void: replay_requested.emit())
		row.add_child(replay_btn)

	if show_next_button:
		var next_btn := _button(next_text, true)
		next_btn.pressed.connect(func() -> void: next_requested.emit())
		row.add_child(next_btn)

	var levels_btn := _button(levels_text, false)
	levels_btn.pressed.connect(func() -> void: levels_requested.emit())
	row.add_child(levels_btn)
>>>>>>> Stashed changes
