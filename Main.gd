extends Control

const CanvasScript = preload("res://DrawingCanvas.gd")

# Reference ပုံအမှန်ကို မူရင်းအတိုင်း ပြသပေးပြီး နှိပ်လိုက်ပါက ပုံအကြီး ချဲ့ကြည့်နိုင်သည့် Viewer
class ReferencePlanViewer extends Control:
	signal clicked_to_open_popup()

	var plan_texture: Texture2D
	var ref_zoom: float = 1.0
	var ref_pan: Vector2 = Vector2.ZERO
	var dragging: bool = false
	var drag_moved: bool = false
	var press_pos: Vector2 = Vector2.ZERO
	var last_mouse_pos: Vector2 = Vector2.ZERO
	var is_popup_view: bool = false

	func _init(tex: Texture2D, popup_mode: bool = false) -> void:
		plan_texture = tex
		is_popup_view = popup_mode
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(360, 260) if not popup_mode else Vector2(800, 520)
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		resized.connect(_on_resized)

	func reset_zoom() -> void:
		ref_zoom = 1.0
		ref_pan = Vector2.ZERO
		queue_redraw()

	func zoom_by(factor: float) -> void:
		_zoom_at_point(size * 0.5, factor)

	func _on_resized() -> void:
		if is_equal_approx(ref_zoom, 1.0):
			ref_pan = Vector2.ZERO
		queue_redraw()

	func _zoom_at_point(focus: Vector2, factor: float) -> void:
		var prev_zoom: float = ref_zoom
		ref_zoom = clampf(ref_zoom * factor, 0.6, 7.0)
		if is_equal_approx(ref_zoom, 1.0):
			ref_pan = Vector2.ZERO
		else:
			ref_pan = focus - (focus - ref_pan) * (ref_zoom / prev_zoom)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
				_zoom_at_point(mb.position, 1.22)
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
				_zoom_at_point(mb.position, 1.0 / 1.22)
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_LEFT:
				if mb.pressed:
					if mb.double_click and is_popup_view:
						reset_zoom()
						accept_event()
						return
					dragging = true
					drag_moved = false
					press_pos = mb.position
					last_mouse_pos = mb.position
				else:
					dragging = false
					if not drag_moved:
						if not is_popup_view:
							clicked_to_open_popup.emit()
						else:
							if ref_zoom < 3.5:
								_zoom_at_point(mb.position, 1.45)
							else:
								reset_zoom()
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				if ref_zoom > 1.05:
					_zoom_at_point(mb.position, 0.72)
				else:
					reset_zoom()
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_MIDDLE:
				dragging = mb.pressed
				last_mouse_pos = mb.position
				accept_event()

		elif event is InputEventMouseMotion and dragging:
			var mm: InputEventMouseMotion = event
			if mm.position.distance_to(press_pos) > 4.0:
				drag_moved = true
			ref_pan += mm.position - last_mouse_pos
			last_mouse_pos = mm.position
			queue_redraw()
			accept_event()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("ffffff"), true)
		if not plan_texture:
			return
		var tex_size: Vector2 = plan_texture.get_size()
		if tex_size.x <= 0 or tex_size.y <= 0:
			return

		var base_scale: float = minf(size.x / tex_size.x, size.y / tex_size.y)
		var base_size: Vector2 = tex_size * base_scale
		var base_offset: Vector2 = (size - base_size) * 0.5

		var final_size: Vector2 = base_size * ref_zoom
		var final_pos: Vector2 = base_offset * ref_zoom + ref_pan
		draw_texture_rect(plan_texture, Rect2(final_pos, final_size), false)




class StaticCustomerAvatar extends TextureRect:

	func _init() -> void:
		custom_minimum_size = Vector2(110, 110)
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

		var avatar_path := "res://customer_portrait.png"
		if ResourceLoader.exists(avatar_path):
			texture = load(avatar_path) as Texture2D

		var circle_shader := Shader.new()
		circle_shader.code = """
shader_type canvas_item;
render_mode blend_mix;

uniform vec4 ring_color : source_color = vec4(0.47, 0.70, 1.0, 1.0);
uniform float ring_width = 0.035;

void fragment() {
    vec2 p = UV - vec2(0.5);
    float dist = length(p);

    
vec4 tex = texture(TEXTURE, UV);


    float edge = fwidth(dist);
    float circle_alpha = 1.0 - smoothstep(0.5 - edge, 0.5 + edge, dist);

    float ring = smoothstep(
        0.5 - ring_width - edge,
        0.5 - ring_width + edge,
        dist
    );

    vec3 final_color = mix(tex.rgb, ring_color.rgb, ring);
    COLOR = vec4(final_color, tex.a * circle_alpha);
}
"""

		var shader_material := ShaderMaterial.new()
		shader_material.shader = circle_shader
		material = shader_material


var canvas: Control
var ref_viewer: ReferencePlanViewer
var popup_overlay: ColorRect
var popup_viewer: ReferencePlanViewer
var speaker_name_label: Label
var dialog_bubble: PanelContainer
var dialog_scroll: ScrollContainer
var request_label: RichTextLabel
var feedback_divider: ColorRect
var feedback_label: Label
var start_button_row: HBoxContainer
var start_button: Button
var again_button_row: HBoxContainer
var again_button: Button
var stage_transition_running: bool = false
var intro_overlay: ColorRect
var game_has_started: bool = false
var status_label: Label
var status_panel: PanelContainer
var ok_button: Button
var jp_lang_btn: Button
var mm_lang_btn: Button

# Recorded voice files. Place the three MP3 files in res:// (the project root).
var voice_player: AudioStreamPlayer
var voice_stop_button: Button
var voice_replay_button: Button
var voice_kind: String = ""
var voice_caption: Control
var voice_segment_times: Array[float] = []
var voice_segment_texts: Array[String] = []
var voice_last_visible: int = -1

var current_lang: String = "jp" # "jp" သို့မဟုတ် "mm"
var last_eval_state: String = "none" # "none", "correct", "wrong"
var conversation_finished: bool = false
var is_drawing_started: bool = false
var is_typing_message: bool = false
var typing_token: int = 0

const DIALOGUE_TEXTS: Dictionary = {
	"jp": {
		"speaker": "細川さん（女性）",
		"request": "キッチンのリフォームを考えています。\n図面はあったけど、よくわかりません。\n必要なエリアをきれいに描いてもらえますか？\nリビングダイニングとキッチンの間取りを正確に知りたいです。",
		"correct": "よくわかりました。\nありがとうございます。",
		"wrong": "ちょっと違うような気がしますけど。",
		"try_again": "Try Again",
		"start": "Start (描き始める)"
	},
	"mm": {
		"speaker": "ဟိုဆိုကာဝါစံ",
		"request": "မီးဖိုချောင်ကို ပြန်လည်ပြင်ဆင်ဖို့ စဉ်းစားနေပါတယ်။\nပုံစံစာရွက် ရှိပေမယ့် သေချာနားမလည်လို့ပါ။\nလိုအပ်တဲ့ ဧရိယာလေးကို သပ်သပ်ရပ်ရပ် ဆွဲပေးနိုင်မလားရှင်။\nထမင်းစားခန်းနဲ့ မီးဖိုချောင်ရဲ့ အခန်းဖွဲ့စည်းပုံကို အတိအကျ သိချင်ပါတယ်။",
		"correct": "သေချာနားလည်သွားပါပြီ။\nကျေးဇူးအများကြီးတင်ပါတယ်။",
		"wrong": "နည်းနည်းလေး လွဲနေသလိုပဲနော်、、、",
		"try_again": "Try Again",
		"start": "Start (စတင်ဆွဲမည်)"
	}
}

func _ready() -> void:
	get_viewport().msaa_2d = Viewport.MSAA_4X
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_multilang_font()
	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finished)
	_build_ui()
	_update_lang_buttons_style()
	_show_intro_screen()

# No external TTF/OTF files are required. This matches Stage 2 desktop fonts.
# Note: Web browser font availability is platform-dependent.
func _setup_multilang_font() -> void:
	var sys_font := SystemFont.new()
	sys_font.font_names = PackedStringArray(["Yu Gothic UI", "Meiryo", "Noto Sans JP", "Myanmar Text", "Pyidaungsu", "Padauk", "Segoe UI"])
	var custom_theme := Theme.new()
	custom_theme.default_font = sys_font
	theme = custom_theme

func _show_intro_screen() -> void:
	# Keep the game UI constructed underneath the intro screen.
	canvas.set_drawing_enabled(false)
	request_label.visible = true
	request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
	request_label.visible_characters = -1
	intro_overlay = ColorRect.new()
	intro_overlay.name = "GameIntroOverlay"
	intro_overlay.color = Color("101d35")
	intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(intro_overlay)
	intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_overlay.add_child(center)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size = Vector2(420, 280)
	stack.add_theme_constant_override("separation", 18)
	center.add_child(stack)

	var heading := Label.new()
	heading.text = "SKETCH CHALLENGE"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 36)
	heading.add_theme_color_override("font_color", Color.WHITE)
	stack.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Kitchen Layout Design Game"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color("cbd5e1"))
	stack.add_child(subtitle)

	var languages := Label.new()
	languages.text = "日本語  /  မြန်မာ"
	languages.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	languages.add_theme_font_size_override("font_size", 17)
	languages.add_theme_color_override("font_color", Color("bfdbfe"))
	stack.add_child(languages)

	var start := Button.new()
	start.text = "▶  START GAME"
	start.custom_minimum_size = Vector2(260, 62)
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.add_theme_font_size_override("font_size", 22)
	start.add_theme_color_override("font_color", Color.WHITE)
	start.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("2563eb")
	normal.set_corner_radius_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("1d4ed8")
	start.add_theme_stylebox_override("normal", normal)
	start.add_theme_stylebox_override("hover", hover)
	start.add_theme_stylebox_override("pressed", hover)
	start.pressed.connect(_on_intro_start_pressed)
	stack.add_child(start)

	var hint := Label.new()
	hint.text = "Press START GAME to enable customer audio."
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("94a3b8"))
	stack.add_child(hint)

func _on_intro_start_pressed() -> void:
	if game_has_started:
		return
	game_has_started = true
	# Direct button interaction gives the browser a chance to unlock audio.
	if intro_overlay != null:
		intro_overlay.hide()
	_run_conversation()
	if intro_overlay != null:
		intro_overlay.queue_free()
		intro_overlay = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if popup_overlay and popup_overlay.visible:
			popup_overlay.visible = false
			get_viewport().set_input_as_handled()

func _style(bg: String, border: String = "cbd5e1") -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = Color(bg)
	s.border_color = Color(border)
	s.set_border_width_all(1)
	s.set_corner_radius_all(9)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _label(value: String, font_size: int, color: String = "17233b") -> Label:
	var l: Label = Label.new()
	l.text = value
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(color))
	return l

func _rich_label(font_size: int, color: String = "17233b") -> RichTextLabel:
	var r: RichTextLabel = RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.add_theme_font_size_override("normal_font_size", font_size)
	r.add_theme_color_override("default_color", Color(color))
	return r

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

func _button(value: String, action: Callable, min_w: float = 80.0) -> Button:
	var b: Button = Button.new()
	b.text = value
	b.custom_minimum_size = Vector2(min_w, 40)
	b.pressed.connect(action)
	_modern_button_style(b, "primary" if value in ["OK", "Start (描き始める)", "Start (စတင်ဆွဲမည်)"] else ("warning" if value == "Try Again" else "secondary"))
	return b


func _load_reference_texture() -> Texture2D:
	var image_path: String = "res://reference_sketch.png"

	if ResourceLoader.exists(image_path):
		return load(image_path) as Texture2D

	push_error("Reference image not found: " + image_path)
	return null


func _try_load_image_file(path: String) -> Texture2D:
	if not FileAccess.file_exists(path):
		return null
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 12:
		return null
	var img: Image = Image.new()
	var err: Error = FAILED
	if bytes[0] == 0x89 and bytes[1] == 0x50 and bytes[2] == 0x4E and bytes[3] == 0x47:
		err = img.load_png_from_buffer(bytes)
	elif bytes[0] == 0xFF and bytes[1] == 0xD8:
		err = img.load_jpg_from_buffer(bytes)
	elif bytes[0] == 0x52 and bytes[1] == 0x49 and bytes[2] == 0x46 and bytes[3] == 0x46:
		err = img.load_webp_from_buffer(bytes)
	if err == OK and not img.is_empty():
		img.generate_mipmaps()
		return ImageTexture.create_from_image(img)
	return null

func _build_ui() -> void:
	var base: PanelContainer = PanelContainer.new()
	add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.add_theme_stylebox_override("panel", _style("e9eef5"))

	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	base.add_child(margin)

	var split: HSplitContainer = HSplitContainer.new()
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 490
	margin.add_child(split)

	# --- ဘယ်ဘက်ခြမ်း ---
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.custom_minimum_size.x = 450
	left_panel.add_theme_stylebox_override("panel", _style("f1f5f9"))
	split.add_child(left_panel)

	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left)

	var left_top_bar: HBoxContainer = HBoxContainer.new()
	left_top_bar.add_theme_constant_override("separation", 6)
	left.add_child(left_top_bar)

	var stage_title: Label = _label("STAGE 1  |  CUSTOMER REQUEST", 18)
	stage_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_top_bar.add_child(stage_title)

	jp_lang_btn = Button.new()
	jp_lang_btn.text = "日本語"
	jp_lang_btn.custom_minimum_size = Vector2(76, 34)
	jp_lang_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	jp_lang_btn.pressed.connect(func(): _switch_language("jp"))
	left_top_bar.add_child(jp_lang_btn)

	mm_lang_btn = Button.new()
	mm_lang_btn.text = "မြန်မာ"
	mm_lang_btn.custom_minimum_size = Vector2(76, 34)
	mm_lang_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mm_lang_btn.pressed.connect(func(): _switch_language("mm"))
	left_top_bar.add_child(mm_lang_btn)

	# Conversation Box
	var chat_panel: PanelContainer = PanelContainer.new()
	chat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_panel.size_flags_stretch_ratio = 1.0
	chat_panel.custom_minimum_size.y = 285
	chat_panel.add_theme_stylebox_override("panel", _style("e2e8f0"))
	left.add_child(chat_panel)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chat_panel.add_child(row)

	var avatar_holder := CenterContainer.new()
	avatar_holder.custom_minimum_size = Vector2(110, 110)
	avatar_holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(avatar_holder)

	var avatar: StaticCustomerAvatar = StaticCustomerAvatar.new()
	avatar_holder.add_child(avatar)

	dialog_bubble = PanelContainer.new()
	dialog_bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_bubble.add_theme_stylebox_override("panel", _style("dbeafe", "93c5fd"))
	row.add_child(dialog_bubble)

	var bubble_vbox: VBoxContainer = VBoxContainer.new()
	bubble_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_vbox.add_theme_constant_override("separation", 6)
	dialog_bubble.add_child(bubble_vbox)

	# Name and voice controls share one line; they do not take text space below.
	var name_voice_row: HBoxContainer = HBoxContainer.new()
	name_voice_row.add_theme_constant_override("separation", 4)
	bubble_vbox.add_child(name_voice_row)

	speaker_name_label = _label(DIALOGUE_TEXTS["jp"]["speaker"], 15, "1d4ed8")
	speaker_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_voice_row.add_child(speaker_name_label)

	var voice_controls: HBoxContainer = HBoxContainer.new()
	voice_controls.add_theme_constant_override("separation", 3)
	voice_controls.size_flags_horizontal = Control.SIZE_SHRINK_END
	name_voice_row.add_child(voice_controls)

	voice_replay_button = _button("↻", _replay_voice, 22)
	voice_stop_button = _button("Ⅱ", _toggle_voice_pause, 22)
	for btn in [voice_replay_button, voice_stop_button]:
		btn.custom_minimum_size = Vector2(22, 22)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color", Color("1d4ed8"))
		btn.add_theme_color_override("font_hover_color", Color("1e40af"))
		btn.add_theme_color_override("font_pressed_color", Color("1e40af"))
		btn.add_theme_color_override("font_focus_color", Color("1d4ed8"))
		for state in ["normal", "hover", "pressed", "focus"]:
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = Color("eaf2ff") if state == "normal" else Color("cfe2ff")
			style.border_color = Color("93c5fd")
			style.set_border_width_all(1)
			style.set_corner_radius_all(5)
			style.set_content_margin_all(0)
			btn.add_theme_stylebox_override(state, style)
	voice_replay_button.tooltip_text = "Replay from beginning"
	voice_stop_button.tooltip_text = "Pause / Resume"
	voice_controls.add_child(voice_replay_button)
	voice_controls.add_child(voice_stop_button)

	dialog_scroll = ScrollContainer.new()
	dialog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	bubble_vbox.add_child(dialog_scroll)

	var text_container: VBoxContainer = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 8)
	dialog_scroll.add_child(text_container)

	request_label = _rich_label(14, "17233b")
	text_container.add_child(request_label)

	feedback_divider = ColorRect.new()
	feedback_divider.custom_minimum_size.y = 1
	feedback_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_divider.color = Color("93c5fd")
	feedback_divider.visible = false
	text_container.add_child(feedback_divider)

	feedback_label = _label("", 13, "991b1b")
	feedback_label.visible = false
	text_container.add_child(feedback_label)

	again_button_row = HBoxContainer.new()
	again_button_row.alignment = BoxContainer.ALIGNMENT_END
	again_button_row.visible = false
	text_container.add_child(again_button_row)

	again_button = Button.new()
	again_button.text = "Try Again"
	again_button.custom_minimum_size = Vector2(125, 36)
	again_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var again_style: StyleBoxFlat = _style("dc2626", "b91c1c")
	var again_hover: StyleBoxFlat = _style("b91c1c", "991b1b")
	again_button.add_theme_stylebox_override("normal", again_style)
	again_button.add_theme_stylebox_override("hover", again_hover)
	again_button.add_theme_stylebox_override("pressed", again_hover)
	again_button.add_theme_color_override("font_color", Color("ffffff"))
	again_button.add_theme_color_override("font_hover_color", Color("ffffff"))
	again_button.add_theme_font_size_override("font_size", 13)
	again_button.pressed.connect(_on_again_pressed)
	again_button_row.add_child(again_button)

	# Reference Plan
	var ref_title_btn: Button = Button.new()
	ref_title_btn.text = "Reference Plan"
	ref_title_btn.flat = true
	ref_title_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ref_title_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ref_title_btn.add_theme_font_size_override("font_size", 17)
	ref_title_btn.add_theme_color_override("font_color", Color("17233b"))
	ref_title_btn.add_theme_color_override("font_hover_color", Color("2563eb"))
	ref_title_btn.pressed.connect(_open_reference_popup)
	left.add_child(ref_title_btn)

	# Reference Plan ဧရိယာကို ကြီးမားကျယ်ဝန်းစွာ ချဲ့ထွင်ထားခြင်း (stretch_ratio = 1.45)
	var image_frame: PanelContainer = PanelContainer.new()
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_frame.size_flags_stretch_ratio = 1.45
	image_frame.custom_minimum_size.y = 240
	image_frame.add_theme_stylebox_override("panel", _style("ffffff"))
	left.add_child(image_frame)

	var loaded_tex: Texture2D = _load_reference_texture()
	ref_viewer = ReferencePlanViewer.new(loaded_tex, false)
	ref_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ref_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ref_viewer.clicked_to_open_popup.connect(_open_reference_popup)
	image_frame.add_child(ref_viewer)

	# --- ညာဘက်ခြမ်း (Drawing Area) ---
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size.x = 580
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_stylebox_override("panel", _style("f1f5f9"))
	split.add_child(right_panel)

	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override("separation", 9)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right)

	right.add_child(_label("Layout Drawing Area", 22))
	right.add_child(_label("1 Small Grid = 100 mm (e.g., 1,000 mm = 10 grids) | Click points to draw (straight or angled) | Drag = Move", 13, "475569"))

	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 6)
	right.add_child(toolbar)

	var _create_styled_btn = func(txt: String, cb: Callable, bg_hex: String, fg_hex: String, hover_hex: String, w: float = 85.0) -> Button:
		var b: Button = _button(txt, cb, w)
		var s: StyleBoxFlat = _style(bg_hex, hover_hex)
		var h: StyleBoxFlat = _style(hover_hex, bg_hex)
		b.add_theme_stylebox_override("normal", s)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_stylebox_override("pressed", h)
		b.add_theme_color_override("font_color", Color(fg_hex))
		b.add_theme_color_override("font_hover_color", Color("ffffff"))
		b.add_theme_font_size_override("font_size", 12)
		return b

	toolbar.add_child(_create_styled_btn.call("Undo", _undo, "f1f5f9", "334155", "e2e8f0", 75))
	toolbar.add_child(_create_styled_btn.call("Redo", _redo, "f1f5f9", "334155", "e2e8f0", 75))
	toolbar.add_child(_create_styled_btn.call("Delete Last", _delete, "fee2e2", "991b1b", "fecaca", 95))
	
	# Delete ခလုတ် (Select လုပ်ထားသောမျဉ်းကို ဖျက်ရန်)
	toolbar.add_child(_create_styled_btn.call("Delete", func():
		if canvas.has_method("delete_selected_line"):
			canvas.delete_selected_line()
	, "fee2e2", "991b1b", "fecaca", 80))

	toolbar.add_child(_create_styled_btn.call("Zoom +", _zoom_in, "f1f5f9", "334155", "e2e8f0", 75))
	toolbar.add_child(_create_styled_btn.call("Zoom -", _zoom_out, "f1f5f9", "334155", "e2e8f0", 75))
	toolbar.add_child(_create_styled_btn.call("Reset", _reset_view, "f1f5f9", "334155", "e2e8f0", 75))

	canvas = CanvasScript.new()
	canvas.custom_minimum_size = Vector2(450, 350)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.drawing_status_changed.connect(_on_drawing_status)
	right.add_child(canvas)
	canvas.set_drawing_enabled(true)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 9)
	right.add_child(footer)

	status_panel = PanelContainer.new()
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_panel.add_theme_stylebox_override("panel", _style("ffffff"))
	footer.add_child(status_panel)

	status_label = _label("Draw the requested layout, then click OK.", 14)
	status_label.custom_minimum_size.y = 45
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_panel.add_child(status_label)

	footer.add_child(_button("Clear", _clear))
	ok_button = _button("OK", _confirm)
	footer.add_child(ok_button)

	_build_reference_popup(loaded_tex)

func _update_lang_buttons_style() -> void:
	var active_s: StyleBoxFlat = _style("2563eb", "1d4ed8")
	var inactive_s: StyleBoxFlat = _style("ffffff", "cbd5e1")

	if current_lang == "jp":
		jp_lang_btn.add_theme_stylebox_override("normal", active_s)
		jp_lang_btn.add_theme_stylebox_override("hover", active_s)
		jp_lang_btn.add_theme_color_override("font_color", Color("ffffff"))
		mm_lang_btn.add_theme_stylebox_override("normal", inactive_s)
		mm_lang_btn.add_theme_stylebox_override("hover", inactive_s)
		mm_lang_btn.add_theme_color_override("font_color", Color("1e293b"))
	else:
		mm_lang_btn.add_theme_stylebox_override("normal", active_s)
		mm_lang_btn.add_theme_stylebox_override("hover", active_s)
		mm_lang_btn.add_theme_color_override("font_color", Color("ffffff"))
		jp_lang_btn.add_theme_stylebox_override("normal", inactive_s)
		jp_lang_btn.add_theme_stylebox_override("hover", inactive_s)
		jp_lang_btn.add_theme_color_override("font_color", Color("1e293b"))

func _switch_language(lang: String) -> void:
	if current_lang == lang:
		return
	_stop_voice()
	current_lang = lang
	_update_lang_buttons_style()
	speaker_name_label.text = DIALOGUE_TEXTS[current_lang]["speaker"]
	again_button.text = DIALOGUE_TEXTS[current_lang]["try_again"]
	if last_eval_state == "correct":
		request_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		feedback_label.text = DIALOGUE_TEXTS[current_lang]["correct"]
		# Hide the button while the current-language thank-you voice is playing.
		_play_voice("correct")
	elif last_eval_state == "wrong":
		request_label.visible = true
		request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
		request_label.visible_characters = -1
		feedback_divider.visible = true
		feedback_label.visible = true
		feedback_label.text = DIALOGUE_TEXTS[current_lang]["wrong"]
		again_button_row.visible = true
		_play_voice("wrong")
	else:
		request_label.visible = true
		request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
		request_label.visible_characters = -1
		feedback_label.visible = false
		_play_voice("talk")

func _build_reference_popup(tex: Texture2D) -> void:
	popup_overlay = ColorRect.new()
	popup_overlay.color = Color(0.06, 0.09, 0.16, 0.78)
	popup_overlay.visible = false
	popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(popup_overlay)
	popup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	popup_overlay.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			popup_overlay.visible = false
	)

	var center_margin: MarginContainer = MarginContainer.new()
	center_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		center_margin.add_theme_constant_override("margin_" + side, 36)
	popup_overlay.add_child(center_margin)

	var modal_card: PanelContainer = PanelContainer.new()
	modal_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_card.add_theme_stylebox_override("panel", _style("ffffff", "94a3b8"))
	center_margin.add_child(modal_card)

	var modal_vbox: VBoxContainer = VBoxContainer.new()
	modal_vbox.add_theme_constant_override("separation", 10)
	modal_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_card.add_child(modal_vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	modal_vbox.add_child(header)

	var title: Label = _label("Reference Plan", 18, "0f172a")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	header.add_child(_button("Zoom +", func(): popup_viewer.zoom_by(1.28), 85))
	header.add_child(_button("Zoom -", func(): popup_viewer.zoom_by(0.78), 85))
	header.add_child(_button("100%", func(): popup_viewer.reset_zoom(), 75))
	header.add_child(_button("✕ Close", func(): popup_overlay.visible = false, 90))

	var viewer_frame: PanelContainer = PanelContainer.new()
	viewer_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewer_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewer_frame.add_theme_stylebox_override("panel", _style("f8fafc", "cbd5e1"))
	modal_vbox.add_child(viewer_frame)

	popup_viewer = ReferencePlanViewer.new(tex, true)
	popup_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	popup_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewer_frame.add_child(popup_viewer)

func _open_reference_popup() -> void:
	if popup_overlay:
		popup_overlay.visible = true

# Keep the conversation at the beginning instead of jumping down while typing.
func _scroll_dialog_to_bottom() -> void:
	await get_tree().process_frame
	if is_instance_valid(dialog_scroll):
		dialog_scroll.scroll_vertical = 0

func _type_rich_text(target_rich: RichTextLabel, bbcode_msg: String, duration: float = 1.6) -> void:
	typing_token += 1
	var my_token: int = typing_token
	target_rich.text = bbcode_msg
	target_rich.visible_characters = 0
	var total_chars: int = maxi(1, target_rich.get_total_character_count())
	var delay: float = duration / float(total_chars)
	for i in range(1, total_chars + 1):
		if not is_inside_tree() or my_token != typing_token:
			return
		target_rich.visible_characters = i
		if i % 10 == 0:
			_scroll_dialog_to_bottom()
		await get_tree().create_timer(delay).timeout
	target_rich.visible_characters = -1
	await _scroll_dialog_to_bottom()

func _type_text(target_label: Label, message: String, duration: float = 1.6) -> void:
	typing_token += 1
	var my_token: int = typing_token
	target_label.text = ""
	var delay: float = duration / float(maxi(1, message.length()))
	for i in range(message.length()):
		if not is_inside_tree() or my_token != typing_token:
			return
		target_label.text += message.substr(i, 1)
		if i % 10 == 0:
			_scroll_dialog_to_bottom()
		await get_tree().create_timer(delay).timeout
	await _scroll_dialog_to_bottom()

func _run_conversation() -> void:
	speaker_name_label.text = DIALOGUE_TEXTS[current_lang]["speaker"]
	is_drawing_started = true
	conversation_finished = true
	canvas.set_drawing_enabled(true)
	request_label.visible = true
	request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
	request_label.visible_characters = -1
	_set_status("Draw the requested layout, then click OK.", false)
	_play_voice("talk")

func _set_status(value: String, error: bool, success: bool = false) -> void:
	status_label.text = value
	if error:
		status_panel.add_theme_stylebox_override("panel", _style("fee2e2", "dc2626"))
		status_label.add_theme_color_override("font_color", Color("991b1b"))
	elif success:
		status_panel.add_theme_stylebox_override("panel", _style("dcfce7", "16a34a"))
		status_label.add_theme_color_override("font_color", Color("14532d"))
	else:
		status_panel.add_theme_stylebox_override("panel", _style("ffffff"))
		status_label.add_theme_color_override("font_color", Color("17233b"))

func _on_drawing_status(message: String) -> void:
	if is_drawing_started:
		_set_status(message, false)

func _undo() -> void:
	if is_drawing_started: canvas.undo_line()
func _redo() -> void:
	if is_drawing_started: canvas.redo_line()
func _delete() -> void:
	if is_drawing_started: canvas.delete_last_line()
func _zoom_in() -> void: canvas.zoom_in()
func _zoom_out() -> void: canvas.zoom_out()
func _reset_view() -> void: canvas.reset_view()

func _clear() -> void:
	if is_drawing_started:
		_reset_feedback_ui()
		canvas.clear_canvas()
		canvas.set_drawing_enabled(true)

func _on_start_pressed() -> void:
	if is_typing_message:
		return
	is_drawing_started = true
	canvas.set_drawing_enabled(true)
	_set_status("Drawing started! Click points on the grid to draw the layout.", false)

func _reset_feedback_ui() -> void:
	last_eval_state = "none"
	request_label.visible = true
	request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
	request_label.visible_characters = -1
	feedback_divider.visible = false
	feedback_label.visible = false
	feedback_label.text = ""
	again_button_row.visible = false
	dialog_bubble.add_theme_stylebox_override("panel", _style("dbeafe", "93c5fd"))

func _on_again_pressed() -> void:
	typing_token += 1
	_reset_feedback_ui()
	canvas.clear_canvas()
	canvas.set_drawing_enabled(true)
	is_drawing_started = true
	_set_status("Canvas cleared. Please draw the layout again.", false)

func _confirm() -> void:
	if not conversation_finished or not is_drawing_started:
		return
	ok_button.disabled = true
	again_button_row.visible = false

	var is_correct: bool = canvas.analyze_reference()

	if is_correct:
		last_eval_state = "correct"
		request_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		dialog_bubble.add_theme_stylebox_override("panel", _style("dcfce7", "4ade80"))
		feedback_label.add_theme_color_override("font_color", Color("14532d"))
		_set_status("Please wait for the customer to finish speaking.", false, true)
		feedback_label.text = DIALOGUE_TEXTS[current_lang]["correct"]
		_play_voice("correct")
	else:
		last_eval_state = "wrong"
		canvas.set_drawing_enabled(false)
		request_label.visible = true
		feedback_divider.visible = true
		feedback_label.visible = true
		dialog_bubble.add_theme_stylebox_override("panel", _style("dbeafe", "f87171"))
		feedback_divider.color = Color("f87171")
		feedback_label.add_theme_color_override("font_color", Color("b91c1c"))
		_set_status("Red highlighted parts on the drawing are incorrect. Click 'Try Again'.", true)
		feedback_label.text = DIALOGUE_TEXTS[current_lang]["wrong"]
		_play_voice("wrong")
		again_button_row.visible = true
		await _scroll_dialog_to_bottom()
	ok_button.disabled = false

# ---------------- Recorded Japanese voice and synchronized subtitles ----------------
func _voice_path(kind: String) -> String:
	if current_lang == "jp":
		match kind:
			"talk": return "res://Talk.mp3"
			"wrong": return "res://Wrong.mp3"
			"correct": return "res://Arigatou.mp3"
	# Myanmar voice uses the user's supplied MP3 filenames.
	else:
		match kind:
			"talk": return "res://Talkmm.mp3"
			"wrong": return "res://Wrongmm.mp3"
			"correct": return "res://Thanksmm.mp3"
	return ""

func _play_voice(kind: String) -> void:
	_stop_voice()
	voice_kind = kind
	var voice_path: String = _voice_path(kind)
	var target: Control = request_label if kind == "talk" else feedback_label
	voice_caption = target
	voice_segment_texts.clear()
	voice_segment_times.clear()
	voice_last_visible = -1
	if kind == "talk":
		request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
	else:
		feedback_label.text = DIALOGUE_TEXTS[current_lang][kind]
	if not ResourceLoader.exists(voice_path):
		# No matching MP3: show the full text, then allow the user to continue.
		if target is RichTextLabel:
			request_label.visible_characters = -1
		if kind == "correct" and last_eval_state == "correct":
			_start_auto_stage_transition()
		return
	var stream: AudioStream = load(voice_path) as AudioStream
	if stream == null:
		if kind == "correct" and last_eval_state == "correct":
			_start_auto_stage_transition()
		return
	voice_player.stream = stream
	# Timestamp groups match spoken sentences, including pauses.
	# Small edits to the MP3 may require adjustments to these times.
	if current_lang == "jp" and kind == "talk":
		voice_segment_texts = [
			"キッチンのリフォームを考えています。\n",
			"図面はあったけど、よくわかりません。\n",
			"必要なエリアをきれいに描いてもらえますか？\n",
			"リビングダイニングとキッチンの間取りを正確に知りたいです。"
		]
		voice_segment_times = [0.0, 3.29, 6.79, 10.50, stream.get_length()]
	elif current_lang == "jp" and kind == "correct":
		voice_segment_texts = ["よくわかりました。\n", "ありがとうございます。"]
		voice_segment_times = [0.0, 2.21, stream.get_length()]
	elif current_lang == "mm" and kind == "talk":
		voice_segment_texts = [
			"မီးဖိုချောင်ကို ပြန်လည်ပြင်ဆင်ဖို့ စဉ်းစားနေပါတယ်။\n",
			"ပုံစံစာရွက် ရှိပေမယ့် သေချာနားမလည်လို့ပါ။\n",
			"လိုအပ်တဲ့ ဧရိယာလေးကို သပ်သပ်ရပ်ရပ် ဆွဲပေးနိုင်မလားရှင်။\n",
			"ထမင်းစားခန်းနဲ့ မီးဖိုချောင်ရဲ့ အခန်းဖွဲ့စည်းပုံကို အတိအကျ သိချင်ပါတယ်။"
		]
		voice_segment_times = [0.0, 4.3, 8.1, 12.8, stream.get_length()]
	elif current_lang == "mm" and kind == "correct":
		voice_segment_texts = ["သေချာနားလည်သွားပါပြီ။\n", "ကျေးဇူးအများကြီးတင်ပါတယ်။"]
		voice_segment_times = [0.0, 2.7, stream.get_length()]
	else:
		voice_segment_texts = [str(DIALOGUE_TEXTS[current_lang]["request" if kind == "talk" else kind])]
		voice_segment_times = [0.0, stream.get_length()]
	if target is RichTextLabel:
		# Reveal characters in sync with the voice on Desktop and Web.
		request_label.visible_characters = 0
	else:
		feedback_label.text = ""
	voice_player.play()
	voice_stop_button.text = "Ⅱ"

func _process(_delta: float) -> void:
	if voice_player == null or not voice_player.playing or voice_player.stream_paused or voice_caption == null:
		return
	var elapsed: float = voice_player.get_playback_position()
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
	if voice_caption == request_label:
		# RichTextLabel text has no markup for the Japanese spoken version.
		var visible: int = mini(displayed.length(), request_label.get_total_character_count())
		if visible != voice_last_visible:
			request_label.visible_characters = visible
			voice_last_visible = visible
	else:
		feedback_label.text = displayed

func _stop_voice() -> void:
	if voice_player != null:
		voice_player.stop()
		voice_player.stream_paused = false
	if voice_stop_button != null:
		voice_stop_button.text = "▶"

func _toggle_voice_pause() -> void:
	if voice_player == null:
		return
	if voice_player.playing and not voice_player.stream_paused:
		voice_player.stream_paused = true
		voice_stop_button.text = "▶"
	elif voice_player.stream_paused:
		voice_player.stream_paused = false
		voice_stop_button.text = "Ⅱ"
	else:
		_replay_voice()

func _replay_voice() -> void:
	var kind: String = voice_kind
	if kind == "":
		kind = "talk"
	_play_voice(kind)

func _on_voice_finished() -> void:
	if voice_stop_button != null:
		voice_stop_button.text = "▶"
	if voice_caption == request_label:
		request_label.visible_characters = -1
	elif voice_caption == feedback_label and voice_kind != "":
		feedback_label.text = DIALOGUE_TEXTS[current_lang][voice_kind]
		if voice_kind == "correct" and last_eval_state == "correct":
			_start_auto_stage_transition()


func _start_auto_stage_transition() -> void:
	if stage_transition_running or last_eval_state != "correct" or not is_inside_tree():
		return
	stage_transition_running = true
	_set_status("Stage 2 is starting automatically...", false, true)
	_run_stage_transition()

func _run_stage_transition() -> void:
	# Keep the customer response visible briefly, then fade to Stage 2.
	await get_tree().create_timer(0.75).timeout
	if not is_inside_tree() or last_eval_state != "correct":
		stage_transition_running = false
		return
	var fade := ColorRect.new()
	fade.color = Color(0.91, 0.95, 1.0, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	if not is_inside_tree():
		return
	_stop_voice()
	var result: Error = get_tree().change_scene_to_file("res://stage_2.tscn")
	if result != OK:
		push_error("Cannot open res://stage_2.tscn")
		stage_transition_running = false
		fade.queue_free()
