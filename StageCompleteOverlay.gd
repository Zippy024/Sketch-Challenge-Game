extends Control

signal next_requested
signal levels_requested
signal replay_requested

const BG := Color(0.06, 0.12, 0.18, 0.35)
const WHITE := Color("ffffff")
const TEXT := Color("1f3c56")
const SUBTEXT := Color("6b7f98")
const GREEN := Color("16a34a")
const GREEN_DARK := Color("15803d")
const GREEN_PALE := Color("f0fdf4")
const OUTLINE := Color("d6e2ef")

var title_text: String = "Stage Complete!"
var subtitle_text: String = "Great job. You cleared this stage."
var next_text: String = "Next Stage"
var levels_text: String = "Levels"
var replay_text: String = "Replay"
var show_next_button: bool = true
var show_replay_button: bool = false

func configure(title_value: String, subtitle_value: String, next_value: String = "Next Stage", levels_value: String = "Levels", replay_value: String = "Replay", allow_next: bool = true, allow_replay: bool = false) -> void:
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
	l.text = LocaleManager.text(text_value)
	l.add_theme_font_size_override("font_size", size_value)
	l.add_theme_color_override("font_color", color_value)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text_value: String, primary: bool = false) -> Button:
	var b := Button.new()
	b.text = LocaleManager.text(text_value)
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
