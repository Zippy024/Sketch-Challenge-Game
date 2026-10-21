extends Control

const Progress = preload("res://GameProgress.gd")

const QUESTIONS := {
	"jp": {
		"name": "細川さん（女性）",
		"question": "ところで、図面にあるPSって何でしょうか？",
		"answer_hint": "ここに回答を入力してください...",
		"answer_title": "あなたの回答",
		"check": "Check Answer",
		"empty": "まず回答を入力してください。",
		"demo": "DEMO（AI未接続）：",
		"good": "よくわかりました！",
		"needs": "ちょっとよくわからないわね、、、",
		"back": "Back to Stage 1",
		"reset": "Clear",
		"lang_note": "Stage 2 | Customer question",
		"offline": "DEMO CHECK — AI will be connected later"
	},
	"mm": {
		"name": "ဟိုဆိုကာဝါစံ (Customer)",
		"question": "စကားမစပ်၊ ပုံစံစာရွက်ထဲက PS ဆိုတာ ဘာကိုဆိုလိုတာလဲရှင်။",
		"answer_hint": "ဒီနေရာမှာ အဖြေရေးပါ...",
		"answer_title": "သင့်အဖြေ",
		"check": "အဖြေစစ်မည်",
		"empty": "အရင်ဆုံး အဖြေတစ်ခု ရေးပေးပါ။",
		"demo": "စမ်းသပ်စစ်ဆေးမှု (AI မချိတ်ရသေး): ",
		"good": "သေချာနားလည်သွားပါပြီ!",
		"needs": "နည်းနည်းနားမလည်ဘူးနော်။",
		"back": "Stage 1 ပြန်သွားမယ်",
		"reset": "ဖျက်မည်",
		"lang_note": "Stage 2 | Customer question",
		"offline": "DEMO CHECK — AI ကို နောက်မှချိတ်မည်"
	}
}

class PlanViewer extends Control:
	signal open_requested()
	var plan_texture: Texture2D
	var zoom: float = 1.0
	var offset: Vector2 = Vector2.ZERO
	var drag_active := false
	var drag_distance := 0.0
	var last_pos: Vector2
	var allow_open := true

	func _init(tex: Texture2D, open_on_click: bool = true) -> void:
		plan_texture = tex
		allow_open = open_on_click
		clip_contents = true
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(300, 200)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, true)
		if plan_texture == null:
			return
		var img_size := plan_texture.get_size()
		if img_size.x < 1.0 or img_size.y < 1.0:
			return
		var scale_factor: float = minf(size.x / img_size.x, size.y / img_size.y) * zoom
		var drawn_size := img_size * scale_factor
		var pos := (size - drawn_size) * 0.5 + offset
		draw_texture_rect(plan_texture, Rect2(pos, drawn_size), false)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = clampf(zoom * 1.18, 1.0, 8.0)
				queue_redraw()
				accept_event()
			elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = clampf(zoom / 1.18, 1.0, 8.0)
				if is_equal_approx(zoom, 1.0):
					offset = Vector2.ZERO
				queue_redraw()
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					drag_active = true
					drag_distance = 0.0
					last_pos = mb.position
				else:
					drag_active = false
					if drag_distance < 5.0 and allow_open:
						open_requested.emit()
				accept_event()
		elif event is InputEventMouseMotion and drag_active:
			var motion := event as InputEventMouseMotion
			var delta_pos := motion.position - last_pos
			offset += delta_pos
			drag_distance += delta_pos.length()
			last_pos = motion.position
			queue_redraw()
			accept_event()

var current_lang := "jp"
var last_eval_state := "none" # "none", "good", "needs"
var name_label: Label
var bubble: PanelContainer
var question_label: Label
var feedback_divider: ColorRect
var feedback_label: Label
var answer_title: Label
var answer_input: TextEdit
var result_label: Label
var submit_button: Button
var reset_button: Button
var jp_button: Button
var mm_button: Button
var status_label: Label
var popup_window: Window
var popup_viewer: PlanViewer
var _pause_menu: Control
var _voice_paused_for_menu: bool = false

# အသံနှင့် စာသား တစ်ပြိုင်တည်းပြသရန် Variables
var voice_player: AudioStreamPlayer
var voice_stop_button: Button
var voice_replay_button: Button
var voice_kind: String = ""
var voice_caption: Label
var voice_segment_times: Array[float] = []
var voice_segment_texts: Array[String] = []
var fallback_typing_active: bool = false
var fallback_elapsed: float = 0.0
var fallback_duration: float = 1.8

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_multilang_font()

	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finished)

	_build_ui()
	_apply_web_readability(self)
	_change_language(Progress.get_language())
	_play_entrance_fade()

# Shared font policy: keep Stage 2 desktop appearance; bundle fonts for browsers.
# Reference-project method: one bundled bilingual Theme for both desktop and Web.
# This avoids SystemFont dependency and provides Myanmar glyph fallback.
const BILINGUAL_THEME: Theme = preload("res://WebBilingualTheme.tres")

func _setup_multilang_font() -> void:
	theme = BILINGUAL_THEME

func _apply_web_readability(_node: Node) -> void:
	# Preserve the successful bundled-font rendering on desktop and Web.
	pass

func _style(bg: String, edge: String = "cad7e8", radius: int = 10) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(bg)
	st.border_color = Color(edge)
	st.set_border_width_all(1)
	st.set_corner_radius_all(radius)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st

func _label(t: String, sz: int = 16, c: String = "17233b") -> Label:
	var l := Label.new()
	l.text = t
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Color(c))
	l.add_theme_font_size_override("font_size", sz)
	return l

func _modern_button_style(button: Button, kind: String = "secondary") -> void:
	var backgrounds := {"primary": "2563eb", "secondary": "ffffff", "back": "dbeafe", "warning": "fff0d9"}
	var borders := {"primary": "1d4ed8", "secondary": "93c5fd", "back": "93c5fd", "warning": "fdba74"}
	var hovers := {"primary": "1d4ed8", "secondary": "eff6ff", "back": "bfdbfe", "warning": "ffedd5"}
	var ink := "ffffff" if kind == "primary" else ("9a3412" if kind == "warning" else "1e40af")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(hovers.get(kind, "eff6ff")) if state in ["hover", "pressed"] else Color(backgrounds.get(kind, "ffffff"))
		style.border_color = Color(borders.get(kind, "93c5fd"))
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, Color(ink))
	button.add_theme_font_size_override("font_size", 14)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _btn(t: String, min_width: float = 85.0) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(min_width, 37)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 15)
	_modern_button_style(b, "primary" if t == "Check Answer" else ("back" if t == "Back to Stage 1" else "secondary"))
	return b

func _build_ui() -> void:
	var background := PanelContainer.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_theme_stylebox_override("panel", _style("e9eef5"))
	add_child(background)

	var outside := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		outside.add_theme_constant_override("margin_" + s, 15)
	background.add_child(outside)

	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.split_offset = 490
	outside.add_child(split)

	var left_card := PanelContainer.new()
	left_card.custom_minimum_size.x = 450
	left_card.add_theme_stylebox_override("panel", _style("f1f5f9"))
	split.add_child(left_card)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left_card.add_child(left)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	left.add_child(header)
	var title := _label("STAGE 2", 19, "1f3c56")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	jp_button = Button.new()
	jp_button.text = "日本語"
	jp_button.custom_minimum_size = Vector2(53, 29)
	jp_button.add_theme_font_size_override("font_size", 12)
	jp_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	jp_button.pressed.connect(func(): _change_language("jp"))
	header.add_child(jp_button)

	mm_button = Button.new()
	mm_button.text = "မြန်မာ"
	mm_button.custom_minimum_size = Vector2(53, 29)
	mm_button.add_theme_font_size_override("font_size", 12)
	mm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mm_button.pressed.connect(func(): _change_language("mm"))
	header.add_child(mm_button)

	var menu_button := _make_levels_menu_button()
	menu_button.pressed.connect(_open_game_menu)
	header.add_child(menu_button)

	var customer_panel := PanelContainer.new()
	customer_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	customer_panel.size_flags_stretch_ratio = 0.9
	customer_panel.custom_minimum_size.y = 230
	customer_panel.add_theme_stylebox_override("panel", _style("e2e8f0"))
	left.add_child(customer_panel)
	var customer_row := HBoxContainer.new()
	customer_row.add_theme_constant_override("separation", 12)
	customer_panel.add_child(customer_row)

	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(110, 110)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	avatar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var avatar_path := "res://customer_portrait_ui.png"
	if ResourceLoader.exists(avatar_path):
		avatar.texture = load(avatar_path) as Texture2D
	var avatar_shader := Shader.new()
	avatar_shader.code = """
shader_type canvas_item;
uniform vec4 ring_color : source_color = vec4(0.47, 0.70, 1.0, 1.0);
uniform float ring_width = 0.035;
void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered);
	float aa = max(fwidth(dist), 0.001);
	float circle_alpha = 1.0 - smoothstep(0.5 - aa, 0.5 + aa, dist);
	vec4 tex = texture(TEXTURE, UV);
	float ring = smoothstep(0.5 - ring_width - aa, 0.5 - ring_width + aa, dist);
	vec3 rgb = mix(tex.rgb, ring_color.rgb, ring);
	COLOR = vec4(rgb, tex.a * circle_alpha);
}
"""
	var avatar_mat := ShaderMaterial.new()
	avatar_mat.shader = avatar_shader
	avatar.material = avatar_mat
	customer_row.add_child(avatar)

	bubble = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble.add_theme_stylebox_override("panel", _style("ffffff", "d6e2ef"))
	customer_row.add_child(bubble)

	var bubble_box := VBoxContainer.new()
	bubble_box.add_theme_constant_override("separation", 8)
	bubble.add_child(bubble_box)

	var name_voice_row := HBoxContainer.new()
	name_voice_row.add_theme_constant_override("separation", 4)
	bubble_box.add_child(name_voice_row)

	name_label = _label("", 15, "1d4ed8")
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_voice_row.add_child(name_label)

	var voice_controls := HBoxContainer.new()
	voice_controls.add_theme_constant_override("separation", 3)
	voice_controls.size_flags_horizontal = Control.SIZE_SHRINK_END
	name_voice_row.add_child(voice_controls)

	var customer_question_subtitle := _label("CUSTOMER QUESTION", 11, "64748b")
	bubble_box.add_child(customer_question_subtitle)

	voice_replay_button = Button.new()
	voice_replay_button.text = ""
	voice_replay_button.pressed.connect(_replay_voice)

	voice_stop_button = Button.new()
	voice_stop_button.text = ""
	voice_stop_button.pressed.connect(_toggle_voice_pause)

	for btn in [voice_replay_button, voice_stop_button]:
		btn.custom_minimum_size = Vector2(32, 32)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color", Color("1d4ed8"))
		btn.add_theme_color_override("font_hover_color", Color("1e40af"))
		btn.add_theme_color_override("font_pressed_color", Color("1e40af"))
		btn.add_theme_color_override("font_focus_color", Color("1d4ed8"))
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("eaf2ff") if state == "normal" else Color("cfe2ff")
			style.border_color = Color("93c5fd")
			style.set_border_width_all(1)
			style.set_corner_radius_all(5)
			style.set_content_margin_all(4)
			btn.add_theme_stylebox_override(state, style)
	_set_voice_icon(voice_replay_button, "replay")
	_set_voice_icon(voice_stop_button, "pause")
	voice_replay_button.tooltip_text = "Replay from beginning"
	voice_stop_button.tooltip_text = "Pause / Resume"
	# Voice buttons hidden; audio and subtitles still run.

	question_label = _label("", 14, "17233b")
	bubble_box.add_child(question_label)

	feedback_divider = ColorRect.new()
	feedback_divider.custom_minimum_size.y = 1
	feedback_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_divider.color = Color("93c5fd")
	feedback_divider.visible = false
	bubble_box.add_child(feedback_divider)

	feedback_label = _label("", 14, "991b1b")
	feedback_label.visible = false
	bubble_box.add_child(feedback_label)

	var ref_title := _btn("Reference Plan  ↗", 200)
	ref_title.flat = true
	ref_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ref_title.pressed.connect(_open_reference_popup)
	left.add_child(ref_title)

	var image_frame := PanelContainer.new()
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_frame.size_flags_stretch_ratio = 1.45
	image_frame.custom_minimum_size.y = 220
	image_frame.add_theme_stylebox_override("panel", _style("ffffff"))
	left.add_child(image_frame)

	var texture_path := "res://reference_sketch.png"
	var loaded_tex: Texture2D = null
	if ResourceLoader.exists(texture_path):
		loaded_tex = load(texture_path) as Texture2D
	else:
		push_warning("Reference image not found: " + texture_path)
	var embedded_viewer := PlanViewer.new(loaded_tex)
	embedded_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	embedded_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	embedded_viewer.open_requested.connect(_open_reference_popup)
	image_frame.add_child(embedded_viewer)
	_create_reference_popup(loaded_tex)

	var right_card := PanelContainer.new()
	right_card.custom_minimum_size.x = 570
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", _style("f1f5f9"))
	split.add_child(right_card)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right_card.add_child(right)
	right.add_child(_label("Answer Area", 23))
	status_label = _label("DEMO CHECK — AI will be connected later", 13, "64748b")
	right.add_child(status_label)
	answer_title = _label("", 18)
	right.add_child(answer_title)
	answer_input = TextEdit.new()
	answer_input.custom_minimum_size.y = 220
	answer_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	answer_input.add_theme_font_size_override("font_size", 18)
	answer_input.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	# Modern light answer editor, including focus/readonly states.
	answer_input.add_theme_color_override("background_color", Color("ffffff"))
	answer_input.add_theme_color_override("font_color", Color("17233b"))
	answer_input.add_theme_color_override("font_placeholder_color", Color("94a3b8"))
	answer_input.add_theme_color_override("caret_color", Color("2563eb"))
	answer_input.add_theme_color_override("selection_color", Color("bfdbfe"))
	answer_input.add_theme_color_override("current_line_color", Color("f8fafc"))
	for state in ["normal", "focus", "read_only"]:
		var editor_style := StyleBoxFlat.new()
		editor_style.bg_color = Color("ffffff")
		editor_style.border_color = Color("2563eb") if state == "focus" else Color("cbd5e1")
		editor_style.set_border_width_all(2 if state == "focus" else 1)
		editor_style.set_corner_radius_all(14)
		editor_style.content_margin_left = 18
		editor_style.content_margin_right = 18
		editor_style.content_margin_top = 16
		editor_style.content_margin_bottom = 16
		answer_input.add_theme_stylebox_override(state, editor_style)
	right.add_child(answer_input)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	right.add_child(actions)
	submit_button = _btn("Check Answer", 150)
	_modern_button_style(submit_button, "primary")
	actions.add_child(submit_button)
	reset_button = _btn("Clear", 90)
	actions.add_child(reset_button)
	submit_button.pressed.connect(_check_demo_answer)
	reset_button.pressed.connect(_reset_answer)

	var result_panel := PanelContainer.new()
	result_panel.custom_minimum_size.y = 110
	result_panel.add_theme_stylebox_override("panel", _style("ffffff"))
	right.add_child(result_panel)
	result_label = _label("", 17)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_panel.add_child(result_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)

func _update_lang_buttons_style() -> void:
	var active_s: StyleBoxFlat = _style("2563eb", "1d4ed8")
	var inactive_s: StyleBoxFlat = _style("ffffff", "cbd5e1")
	if current_lang == "jp":
		jp_button.add_theme_stylebox_override("normal", active_s)
		jp_button.add_theme_stylebox_override("hover", active_s)
		jp_button.add_theme_color_override("font_color", Color("ffffff"))
		mm_button.add_theme_stylebox_override("normal", inactive_s)
		mm_button.add_theme_stylebox_override("hover", inactive_s)
		mm_button.add_theme_color_override("font_color", Color("1e293b"))
	else:
		mm_button.add_theme_stylebox_override("normal", active_s)
		mm_button.add_theme_stylebox_override("hover", active_s)
		mm_button.add_theme_color_override("font_color", Color("ffffff"))
		jp_button.add_theme_stylebox_override("normal", inactive_s)
		jp_button.add_theme_stylebox_override("hover", inactive_s)
		jp_button.add_theme_color_override("font_color", Color("1e293b"))

func _change_language(lang: String) -> void:
	Progress.set_language(lang)
	_stop_voice()
	current_lang = lang
	_update_lang_buttons_style()
	var d: Dictionary = QUESTIONS[lang]
	name_label.text = str(d["name"])
	answer_title.text = str(d["answer_title"])
	answer_input.placeholder_text = str(d["answer_hint"])
	submit_button.text = str(d["check"])
	reset_button.text = str(d["reset"])
	status_label.text = str(d["offline"])

	if last_eval_state == "good":
		question_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		result_label.text = str(d["demo"]) + str(d["good"])
		_play_voice("good")
	elif last_eval_state == "needs":
		question_label.visible = true
		question_label.text = str(d["question"])
		feedback_divider.visible = true
		feedback_label.visible = true
		result_label.text = str(d["demo"]) + str(d["needs"])
		_play_voice("needs")
	else:
		question_label.visible = true
		feedback_divider.visible = false
		feedback_label.visible = false
		result_label.text = ""
		_play_voice("question")

func _reset_answer() -> void:
	_stop_voice()
	last_eval_state = "none"
	answer_input.clear()
	result_label.text = ""
	question_label.visible = true
	question_label.text = str(QUESTIONS[current_lang]["question"])
	feedback_divider.visible = false
	feedback_label.visible = false
	bubble.add_theme_stylebox_override("panel", _style("ffffff", "d6e2ef"))
	answer_input.grab_focus()

func _check_demo_answer() -> void:
	var answer := answer_input.text.strip_edges()
	var d: Dictionary = QUESTIONS[current_lang]
	if answer.is_empty():
		result_label.text = str(d["empty"])
		return
	var normalized := answer.to_lower()
	var names := ["pipe shaft", "pipe-shaft", "パイプシャフト", "配管スペース", "ပိုက်လိုင်း", "ပိုက်တွေ", "ပိုက်များ", "ပိုက်"]
	var pipes := ["pipe", "plumb", "給排水", "配管", "給水", "排水", "ရေပိုက်", "ရေဆိုးပိုက်", "ပိုက်"]
	var matched_name := false
	var matched_pipe := false
	for item in names:
		if normalized.contains(item):
			matched_name = true
			break
	for item in pipes:
		if normalized.contains(item):
			matched_pipe = true
			break
	var has_placement := normalized.contains("space") or normalized.contains("shaft") or normalized.contains("スペース") or normalized.contains("通す") or normalized.contains("場所") or normalized.contains("နေရာ") or normalized.contains("ဖြတ်သန်း") or normalized.contains("ထား")
	var looks_relevant := matched_name and matched_pipe and has_placement

	if looks_relevant:
		last_eval_state = "good"
		question_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		bubble.add_theme_stylebox_override("panel", _style("dcfce7", "4ade80"))
		feedback_label.add_theme_color_override("font_color", Color("14532d"))
		result_label.text = str(d["demo"]) + str(d["good"])
		_play_voice("good")
	else:
		last_eval_state = "needs"
		question_label.visible = true
		question_label.text = str(d["question"])
		feedback_divider.visible = true
		feedback_label.visible = true
		bubble.add_theme_stylebox_override("panel", _style("dbeafe", "f87171"))
		feedback_divider.color = Color("f87171")
		feedback_label.add_theme_color_override("font_color", Color("b91c1c"))
		result_label.text = str(d["demo"]) + str(d["needs"])
		_play_voice("needs")

# ---------------- Stage 2 Voice & Subtitle Animation ----------------
func _voice_path(kind: String) -> String:
	var candidates: Array[String] = []
	if current_lang == "jp":
		match kind:
			"question": candidates = ["res://Ps Question.mp3"]
			"needs": candidates = ["res://Dontunderstand.mp3"]
			"good": candidates = ["res://Understand.mp3"]
	else:
		match kind:
			"question": candidates = ["res://Ps Questionmm.mp3", "res://Talkmm.mp3"]
			"needs": candidates = ["res://Dontunderstandmm.mp3", "res://Wrongmm.mp3"]
			"good": candidates = ["res://Understandmm.mp3", "res://Thanksmm.mp3"]

	for path in candidates:
		if ResourceLoader.exists(path):
			return path
	return ""

func _play_voice(kind: String) -> void:
	_stop_voice()
	voice_kind = kind
	var voice_path: String = _voice_path(kind)
	var target: Label = question_label if kind == "question" else feedback_label
	voice_caption = target
	voice_segment_texts.clear()
	voice_segment_times.clear()

	var full_text: String = str(QUESTIONS[current_lang][kind])
	target.text = ""

	# ၁။ MP3 ဖိုင်ရှိပါက MP3 ဖြင့် ဖွင့်မည်
	if voice_path != "":
		var stream: AudioStream = load(voice_path) as AudioStream
		if stream != null:
			voice_player.stream = stream
			voice_segment_texts = [full_text]
			voice_segment_times = [0.0, maxf(stream.get_length(), 0.1)]
			voice_player.play()
			voice_stop_button.text = ""
			return

	# ၂။ MP3 ဖိုင်မရှိပါက စာသားတစ်လုံးချင်း အလိုအလျောက် ပေါ်လာစေရန် Animation (Typing Effect)
	voice_segment_texts = [full_text]
	fallback_duration = clampf(float(full_text.length()) * 0.05, 1.2, 3.0)
	voice_segment_times = [0.0, fallback_duration]
	fallback_elapsed = 0.0
	fallback_typing_active = true
	voice_stop_button.text = ""

func _process(delta: float) -> void:
	if voice_caption == null or voice_segment_texts.is_empty():
		return

	var elapsed: float = 0.0
	if voice_player != null and voice_player.playing:
		if voice_player.stream_paused:
			return
		elapsed = voice_player.get_playback_position()
	elif fallback_typing_active:
		fallback_elapsed += delta
		elapsed = fallback_elapsed
		if elapsed >= fallback_duration:
			fallback_typing_active = false
			voice_caption.text = voice_segment_texts[0]
			if voice_stop_button != null:
				_set_voice_icon(voice_stop_button, "play")
			return
	else:
		return

	var displayed: String = ""
	for i in range(voice_segment_texts.size()):
		var t0: float = voice_segment_times[i]
		var t1: float = voice_segment_times[i + 1]
		var segment: String = voice_segment_texts[i]
		if elapsed >= t1:
			displayed += segment
		elif elapsed > t0:
			var fraction: float = clampf((elapsed - t0) / maxf(t1 - t0, 0.01), 0.0, 1.0)
			displayed += segment.substr(0, int(floor(float(segment.length()) * fraction)))
			break
		else:
			break
	voice_caption.text = displayed

func _set_voice_icon(button: Button, icon_name: String) -> void:
	if button == null:
		return
	# Generate crisp vector artwork at runtime; no UI_Icons PNG files needed.
	var symbol: String = ""
	match icon_name:
		"replay":
			symbol = '<path d="M20 11a8 8 0 1 1-2.4-5.7"/><path d="M20 3v6h-6"/>'
		"play":
			symbol = '<path d="M9 5l11 7-11 7z" fill="#2563eb" stroke-linejoin="round"/>'
		"pause":
			symbol = '<path d="M9 5v14M15 5v14"/>'
		_:
			return
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 24 24"><g fill="none" stroke="#2563eb" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">' + symbol + '</g></svg>'
	var img := Image.new()
	var err: Error = img.load_svg_from_buffer(svg.to_utf8_buffer(), 1.0)
	if err != OK:
		push_warning("Unable to render voice icon: " + icon_name)
		return
	var tex := ImageTexture.create_from_image(img)
	button.text = ""
	button.icon = tex
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _stop_voice() -> void:
	fallback_typing_active = false
	if voice_player != null:
		voice_player.stop()
		voice_player.stream_paused = false
	if voice_stop_button != null:
		_set_voice_icon(voice_stop_button, "play")

func _toggle_voice_pause() -> void:
	if voice_player != null and voice_player.playing:
		if not voice_player.stream_paused:
			voice_player.stream_paused = true
			_set_voice_icon(voice_stop_button, "play")
		else:
			voice_player.stream_paused = false
			voice_stop_button.text = ""
	elif fallback_typing_active:
		fallback_typing_active = false
		_set_voice_icon(voice_stop_button, "play")
	else:
		_replay_voice()

func _replay_voice() -> void:
	var kind: String = voice_kind if voice_kind != "" else "question"
	_play_voice(kind)

func _on_voice_finished() -> void:
	if voice_stop_button != null:
		_set_voice_icon(voice_stop_button, "play")
	if voice_caption != null and voice_kind != "":
		voice_caption.text = str(QUESTIONS[current_lang][voice_kind])

func _create_reference_popup(tex: Texture2D) -> void:
	popup_window = Window.new()
	popup_window.title = "Reference Plan"
	popup_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	popup_window.size = Vector2i(1050, 700)
	popup_window.visible = false
	add_child(popup_window)
	popup_window.close_requested.connect(func(): popup_window.hide())

	var popup_root := VBoxContainer.new()
	popup_window.add_child(popup_root)
	popup_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var actions := HBoxContainer.new()
	popup_root.add_child(actions)
	var reset := _btn("Reset Zoom", 120)
	reset.pressed.connect(func():
		popup_viewer.zoom = 1.0
		popup_viewer.offset = Vector2.ZERO
		popup_viewer.queue_redraw()
	)
	actions.add_child(reset)
	var close_btn := _btn("Close", 80)
	close_btn.pressed.connect(func(): popup_window.hide())
	actions.add_child(close_btn)
	popup_viewer = PlanViewer.new(tex, false)
	popup_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	popup_root.add_child(popup_viewer)

func _open_reference_popup() -> void:
	if popup_window != null:
		popup_window.popup_centered(Vector2i(1050, 700))

func _play_entrance_fade() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color("e9eef5")
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(overlay.queue_free)

func _make_levels_menu_button() -> Button:
	var btn := Button.new()
	btn.text = "LEVELS"
	btn.custom_minimum_size = Vector2(65, 30)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color("216a58"))
	btn.add_theme_color_override("font_hover_color", Color("124b3d"))
	btn.add_theme_color_override("font_pressed_color", Color("124b3d"))
	btn.add_theme_color_override("font_focus_color", Color("216a58"))
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("f5fbf8") if state == "normal" else Color("def1e9")
		style.border_color = Color("a7cbbb")
		style.set_border_width_all(1)
		style.set_corner_radius_all(9)
		style.set_content_margin_all(5)
		btn.add_theme_stylebox_override(state, style)
	btn.tooltip_text = "Pause and view levels"
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return btn


func _open_game_menu() -> void:
	if is_instance_valid(_pause_menu):
		return
	_voice_paused_for_menu = voice_player != null and voice_player.playing and not voice_player.stream_paused
	if _voice_paused_for_menu:
		voice_player.stream_paused = true
	var overlay := preload("res://GameMenu.tscn").instantiate() as Control
	overlay.set("is_pause_overlay", true)
	overlay.set("pause_level", 2)
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.connect("resume_requested", Callable(self, "_resume_from_game_menu"))
	_pause_menu = overlay
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = true


func _resume_from_game_menu() -> void:
	get_tree().paused = false
	if is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
	_pause_menu = null
	var chosen_lang: String = Progress.get_language()
	if chosen_lang != current_lang:
		_change_language(chosen_lang)
	elif _voice_paused_for_menu and voice_player != null:
		voice_player.stream_paused = false
	_voice_paused_for_menu = false
