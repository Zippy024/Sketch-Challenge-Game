extends Control

const CanvasScript = preload("res://DrawingCanvas.gd")
const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")

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
		custom_minimum_size = Vector2(330, 230) if not popup_mode else Vector2(800, 520)
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
		custom_minimum_size = Vector2(168, 168)
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

		var avatar_path := "res://customer_portrait_ui.png"
		if ResourceLoader.exists(avatar_path):
			texture = load(avatar_path) as Texture2D

		var circle_shader := Shader.new()
		circle_shader.code = """
shader_type canvas_item;
render_mode blend_mix;

uniform vec4 ring_color : source_color = vec4(0.29, 0.60, 0.96, 1.0);
uniform float ring_width = 0.025;

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
var _reviewing_completed: bool = false
var _session_save_suspended: bool = false
var intro_overlay: ColorRect
var game_has_started: bool = false
var status_label: Label
var status_panel: PanelContainer
var _stage1_status_icon: PanelContainer
var _stage1_status_mark: Label
var ok_button: Button
var jp_lang_btn: Button
var mm_lang_btn: Button
var en_lang_btn: Button
var _stage1_language_picker: Control

# Recorded voice files. Place the three MP3 files in res:// (the project root).
var voice_player: AudioStreamPlayer
var voice_stop_button: Button
var voice_replay_button: Button
var voice_kind: String = ""
var voice_caption: Control
var voice_segment_times: Array[float] = []
var voice_segment_texts: Array[String] = []
var voice_last_visible: int = -1
var _pause_menu: Control
var _voice_paused_for_menu: bool = false

var current_lang: String = "jp" # "jp" သို့မဟုတ် "mm"
var last_eval_state: String = "none" # "none", "correct", "wrong"
var conversation_finished: bool = false
var is_drawing_started: bool = false
var is_typing_message: bool = false
var typing_token: int = 0

const DIALOGUE_TEXTS: Dictionary = {
	"en": {
		"speaker": "Ms. Hosokawa",
		"request": "I am thinking about renovating my kitchen.\nI have a floor plan, but I do not understand it clearly.\nCould you neatly draw the area that I need?\nI would like to know the exact living, dining and kitchen layout.",
		"correct": "I understand now.\nThank you very much.",
		"wrong": "Something seems a little different.",
		"try_again": "Try Again",
		"start": "Start drawing"
	},
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
	# GLES3/Web does not support 2D MSAA. Keep it disabled for crisp, compatible UI.
	if OS.has_feature("web"):
		get_viewport().msaa_2d = Viewport.MSAA_DISABLED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_setup_multilang_font()
	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finished)
	current_lang = Progress.get_language()
	if Progress.resume_stage()!=1: Progress.open_stage(1)
	_build_ui()
	var saved := Progress.drawing()
	if not saved.is_empty():
		canvas.lines=saved
		var view := Progress.drawing_view()
		canvas.zoom_level=view.zoom
		canvas.pan=view.pan
		canvas.queue_redraw()
	var autosave := Timer.new()
	autosave.wait_time=1.0
	autosave.timeout.connect(_save_session)
	add_child(autosave)
	autosave.start()
	speaker_name_label.text = DIALOGUE_TEXTS[current_lang]["speaker"]
	_apply_web_readability(self)
	_update_lang_buttons_style()
	if Progress.launch_from_level_menu:
		Progress.launch_from_level_menu = false
		game_has_started = true
		_run_conversation()
	else:
		_show_intro_screen()

# Use bundled fonts on Web; retain the preferred desktop font appearance.
# These paths must exactly match the files under res://Font/.
# Reference-project method: one bundled bilingual Theme for both desktop and Web.
# This avoids SystemFont dependency and provides Myanmar glyph fallback.
const BILINGUAL_THEME: Theme = preload("res://WebBilingualTheme.tres")

func _setup_multilang_font() -> void:
	theme = UI.make_theme()

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
	heading.text = "LEVEL 01  /  CUSTOMER REQUEST"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 31)
	heading.add_theme_color_override("font_color", Color.WHITE)
	stack.add_child(heading)

	var subtitle := Label.new()
	subtitle.text = "Kitchen Layout Design Game"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 19)
	subtitle.add_theme_color_override("font_color", Color("cbd5e1"))
	stack.add_child(subtitle)

	var languages := Label.new()
	languages.text = "日本語  /  မြန်မာ  /  English"
	languages.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	languages.add_theme_font_size_override("font_size", 17)
	languages.add_theme_color_override("font_color", Color("bfdbfe"))
	stack.add_child(languages)

	var start := Button.new()
	start.text = "START LEVEL 1"
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
	hint.text = "Press START LEVEL 1 to hear your customer."
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

# Browser-only readability adjustment. Desktop UI is intentionally unchanged.
func _apply_web_readability(_node: Node) -> void:
	# Preserve the successful bundled-font rendering on desktop and Web.
	pass

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
	l.text = LocaleManager.text(value)
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
	UI.style_button(button,kind=="primary",14,kind=="warning")

func _compact_button_style(button: Button, warning: bool = false, primary: bool = false) -> void:
	var fill := "e8f1f8" if not warning else "ffe6e8"
	var edge := "cbdce9" if not warning else "ffbfc8"
	var ink := "254563" if not warning else "b2213d"
	if primary:
		fill = "087f9b"
		edge = "55cddd"
		ink = "ffffff"
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := _stage1_surface(Color(fill), Color(edge), 17, 4)
		if state in ["hover", "pressed"]: box.bg_color = box.bg_color.darkened(0.06 if state == "hover" else 0.12)
		box.shadow_size = 0
		box.content_margin_left = 8
		box.content_margin_right = 8
		button.add_theme_stylebox_override(state, box)
	var focus := _stage1_surface(Color.TRANSPARENT, Color("258fc4"), 17, 0)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Color(ink))
	button.add_theme_font_size_override("font_size", 12)
	button.remove_theme_font_override("font")
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _button(value: String, action: Callable, min_w: float = 80.0) -> Button:
	var b: Button = Button.new()
	b.text = LocaleManager.text(value)
	b.custom_minimum_size = Vector2(min_w, 36)
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

# Stage 1 surfaces only. The drawing engine and answer rules are unchanged.
func _stage1_surface(fill: Color, edge: Color, radius: int = 18, pad: int = 9) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(pad)
	box.shadow_color = Color(0.04, 0.15, 0.20, 0.035)
	box.shadow_size = 2
	box.shadow_offset = Vector2(0, 1)
	return box


func _stage1_glass(variant: String = "panel", pad: int = 12) -> StyleBoxFlat:
	var fill := Color("fff1f2") if variant == "danger" else (Color("eef9fc") if variant == "speech" else Color(0.94,0.98,1,0.82))
	return UI.box(fill,Color("edb8c2") if variant == "danger" else (UI.EDGE if variant == "speech" else Color.WHITE),18,pad)

func _stage1_bold(control: Control) -> void:
	control.add_theme_font_override("font",UI.font(true))


func _stage1_header_button(glyph: String) -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(34, 34)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 17)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := _stage1_surface(Color(0.02, 0.31, 0.43, 0.8), Color("4c9fb8"), 8, 3)
	var hover := _stage1_surface(Color("0b5c74"), Color("9ae5f0"), 8, 3)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", hover)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Color.WHITE)
	return b


func _stage1_language_label(lang: String) -> String:
	match lang:
		"jp": return "日本語"
		"mm": return "မြန်မာ"
		"en": return "English"
	return "日本語"


func _stage1_icon_texture(index: int) -> AtlasTexture:
	var texture_part := AtlasTexture.new()
	texture_part.atlas = preload("res://Stage1Assets/stage1_icons.svg")
	texture_part.region = Rect2(48 * index, 0, 48, 48)
	return texture_part


func _stage1_toolbar_button(index: int, caption: String, action: Callable, active: bool = false, available: bool = true) -> Button:
	var b := Button.new()
	b.name = "Stage1Tool" + caption.replace(" ", "")
	b.text = ""
	b.custom_minimum_size = Vector2(68, 70)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	var normal := _stage1_surface(Color("128b9e") if active else Color("edf7fb"), Color("55b7c6") if active else Color("c5dfe9"), 13, 3)
	var hover := _stage1_surface(Color("0b788b") if active else Color("d9eef7"), Color("64c7d2"), 13, 3)
	for state in ["normal","hover","pressed","focus","disabled"]:
		b.add_theme_stylebox_override(state, hover if state in ["hover","pressed"] else normal)
	if available:
		b.pressed.connect(action)
	else:
		b.disabled = true
		b.tooltip_text = "Not available in the current Stage 1 drawing engine"
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	b.add_child(stack)
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_top = 4
	stack.offset_bottom = -4
	var picture := TextureRect.new()
	picture.texture = _stage1_icon_texture(index)
	picture.custom_minimum_size = Vector2(29, 29)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.modulate = Color.WHITE if active else (Color("7391a2") if not available else Color("1b426c"))
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(picture)
	var caption_view := _label(caption, 12, "ffffff" if active else ("648396" if not available else "1c3d62"))
	caption_view.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_view.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_view.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(caption_view)
	return b


func _build_ui() -> void:
	UI.background(self)
	var screen_layout := VBoxContainer.new()
	add_child(screen_layout)
	screen_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_layout.add_theme_constant_override("separation",0)
	var hud := UI.header(1,"LDK Boundary Drawing",_open_game_menu,_switch_language)
	screen_layout.add_child(hud)
	_stage1_language_picker = hud.find_child("Stage1LanguagePicker",true,false)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	screen_layout.add_child(margin)

	var split := HBoxContainer.new()
	split.name = "Stage1WorkspaceSplit"
	split.add_theme_constant_override("separation", 18)
	split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(split)

	# --- ဘယ်ဘက်ခြမ်း ---
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.custom_minimum_size.x = 0
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The reference has a 28% sidebar; widen it to 35% for the customer text.
	left_panel.size_flags_stretch_ratio = 7.0
	left_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	split.add_child(left_panel)

	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override("separation", 18)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(left)

	# Conversation Box
	var chat_panel: PanelContainer = PanelContainer.new()
	chat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_panel.name = "Stage1CustomerCard"
	chat_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chat_panel.size_flags_stretch_ratio = 0.92
	chat_panel.custom_minimum_size.y = 330
	chat_panel.add_theme_stylebox_override("panel", _stage1_glass("customer", 14))
	left.add_child(chat_panel)

	var customer_stack := VBoxContainer.new()
	customer_stack.add_theme_constant_override("separation", 0)
	chat_panel.add_child(customer_stack)
	# Portrait and speech sit beside each other, as in the reference.
	var customer_row := HBoxContainer.new()
	customer_row.add_theme_constant_override("separation", 12)
	customer_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	customer_stack.add_child(customer_row)


	var avatar_column := VBoxContainer.new()
	avatar_column.name = "Stage1CustomerPortrait"
	avatar_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	avatar_column.custom_minimum_size.x = 178
	avatar_column.add_theme_constant_override("separation", 10)
	customer_row.add_child(avatar_column)

	var avatar_holder := CenterContainer.new()
	# Match the 110 x 110 customer portrait used in Stage 2.
	avatar_holder.custom_minimum_size = Vector2(168, 168)
	avatar_column.add_child(avatar_holder)
	var avatar: StaticCustomerAvatar = StaticCustomerAvatar.new()
	avatar.name = "Stage1CustomerAvatar"
	avatar.custom_minimum_size = Vector2(168, 168)
	avatar_holder.add_child(avatar)

	var name_plate := PanelContainer.new()
	name_plate.name = "Stage1CustomerIdentity"
	name_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var identity_box := _stage1_surface(Color("edf7ff"), Color("89b6d9"), 8, 6)
	identity_box.content_margin_left = 8
	identity_box.content_margin_right = 8
	identity_box.shadow_size = 1
	identity_box.shadow_offset = Vector2(0,1)
	name_plate.add_theme_stylebox_override("panel", identity_box)
	avatar_column.add_child(name_plate)
	speaker_name_label = _label(DIALOGUE_TEXTS[current_lang]["speaker"], 15, "173b61")
	_stage1_bold(speaker_name_label)
	speaker_name_label.name = "Stage1CustomerName"
	speaker_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speaker_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_plate.add_child(speaker_name_label)

	var speech_stack := VBoxContainer.new()
	speech_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	speech_stack.add_theme_constant_override("separation", 10)
	customer_row.add_child(speech_stack)
	var request_header := PanelContainer.new()
	request_header.name = "CustomerRequestHeader"
	request_header.custom_minimum_size.x = 220
	request_header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var heading_box := _stage1_surface(Color("e7f3ff"), Color("94bddb"), 8, 6)
	heading_box.content_margin_left = 10
	heading_box.content_margin_right = 10
	heading_box.shadow_size = 1
	heading_box.shadow_offset = Vector2(0,1)
	request_header.add_theme_stylebox_override("panel", heading_box)
	speech_stack.add_child(request_header)
	var request_heading := _label("Customer Request", 18, "173b61")
	_stage1_bold(request_heading)
	request_heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	request_header.add_child(request_heading)

	# A separate request heading and clear text box match the supplied conversation.
	dialog_bubble = PanelContainer.new()
	dialog_bubble.name = "Stage1ConversationText"
	dialog_bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_bubble.add_theme_stylebox_override("panel", _stage1_glass("speech", 10))
	speech_stack.add_child(dialog_bubble)

	var bubble_vbox := VBoxContainer.new()
	bubble_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_vbox.add_theme_constant_override("separation", 8)
	dialog_bubble.add_child(bubble_vbox)

	# Preserve recorded voice and UI feedback behavior.
	voice_replay_button = _button("", _replay_voice, 26)
	voice_stop_button = _button("", _toggle_voice_pause, 26)
	_set_voice_icon(voice_replay_button, "replay")
	_set_voice_icon(voice_stop_button, "pause")
	voice_replay_button.tooltip_text = "Replay from beginning"
	voice_stop_button.tooltip_text = "Pause / Resume"
	var voice_controls := HBoxContainer.new()
	voice_controls.name="CustomerVoiceControls"
	voice_controls.hide()
	voice_controls.add_theme_constant_override("separation",7)
	speech_stack.add_child(voice_controls)
	voice_controls.add_child(voice_replay_button)
	voice_controls.add_child(UI.inline_label("Replay",12))
	voice_controls.add_child(voice_stop_button)
	voice_controls.add_child(UI.inline_label("Pause",12))

	dialog_scroll = ScrollContainer.new()
	dialog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialog_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bubble_vbox.add_child(dialog_scroll)

	var text_container: VBoxContainer = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_container.add_theme_constant_override("separation", 8)
	dialog_scroll.add_child(text_container)

	request_label = _rich_label(16, "102c51")
	var request_font := UI.font(false)
	request_label.add_theme_font_override("normal_font", request_font)
	request_label.add_theme_constant_override("line_separation", 2)
	text_container.add_child(request_label)

	feedback_divider = ColorRect.new()
	feedback_divider.custom_minimum_size.y = 1
	feedback_divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	feedback_divider.color = Color("8cbfca")
	feedback_divider.visible = false
	text_container.add_child(feedback_divider)

	feedback_label = _label("", 14, "99534c")
	feedback_label.visible = false
	text_container.add_child(feedback_label)

	again_button_row = HBoxContainer.new()
	again_button_row.alignment = BoxContainer.ALIGNMENT_END
	again_button_row.visible = false
	# Retry will be placed in the answer footer after Reset.

	again_button = Button.new()
	again_button.text = "Try Again"
	# V9: compact, legible retry action instead of the oversized solid-red button.
	again_button.custom_minimum_size = Vector2(101, 30)
	again_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var again_style := StyleBoxFlat.new()
	again_style.bg_color = Color("fff7f5")
	again_style.border_color = Color("e9a29a")
	again_style.set_border_width_all(1)
	again_style.set_corner_radius_all(22)
	again_style.set_content_margin_all(4)
	var again_hover: StyleBoxFlat = again_style.duplicate() as StyleBoxFlat
	again_hover.bg_color = Color("ffe9e6")
	again_hover.border_color = Color("ce5b50")
	var again_pressed: StyleBoxFlat = again_style.duplicate() as StyleBoxFlat
	again_pressed.bg_color = Color("fbd5d0")
	again_button.add_theme_stylebox_override("normal", again_style)
	again_button.add_theme_stylebox_override("hover", again_hover)
	again_button.add_theme_stylebox_override("pressed", again_pressed)
	again_button.add_theme_stylebox_override("focus", again_hover)
	again_button.add_theme_color_override("font_color", Color("ad3832"))
	again_button.add_theme_color_override("font_hover_color", Color("952a25"))
	again_button.add_theme_color_override("font_pressed_color", Color("952a25"))
	again_button.add_theme_font_size_override("font_size", 14)
	_modern_button_style(again_button, "warning")
	again_button.pressed.connect(_on_again_pressed)
	again_button_row.add_child(again_button)

	# Reference Plan
	var ref_title_btn: Button = Button.new()
	ref_title_btn.text = "Reference Plan"
	ref_title_btn.flat = true
	ref_title_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ref_title_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ref_title_btn.add_theme_font_size_override("font_size", 19)
	_stage1_bold(ref_title_btn)
	ref_title_btn.icon = preload("res://Stage1Assets/plan.svg")
	ref_title_btn.add_theme_color_override("font_color", Color("0c315b"))
	ref_title_btn.add_theme_color_override("font_hover_color", Color("117489"))
	ref_title_btn.pressed.connect(_open_reference_popup)
	ref_title_btn.custom_minimum_size.y = 33

	# Reference Plan ဧရိယာကို ကြီးမားကျယ်ဝန်းစွာ ချဲ့ထွင်ထားခြင်း (stretch_ratio = 1.45)
	var image_frame: PanelContainer = PanelContainer.new()
	image_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_frame.size_flags_stretch_ratio = 1.0
	image_frame.custom_minimum_size.y = 200

	image_frame.add_theme_stylebox_override("panel", _stage1_surface(Color("f4fcff"), Color("b3ecff"), 18, 7))
	var reference_card := PanelContainer.new()
	reference_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reference_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reference_card.name = "Stage1ReferenceCard"
	reference_card.add_theme_stylebox_override("panel", _stage1_glass("panel", 14))
	left.add_child(reference_card)
	var ref_contents := VBoxContainer.new()
	ref_contents.add_theme_constant_override("separation", 10)
	reference_card.add_child(ref_contents)
	ref_contents.add_child(ref_title_btn)
	ref_contents.add_child(image_frame)

	var loaded_tex: Texture2D = _load_reference_texture()
	ref_viewer = ReferencePlanViewer.new(loaded_tex, false)
	ref_viewer.custom_minimum_size.y = 190
	ref_viewer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ref_viewer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ref_viewer.clicked_to_open_popup.connect(_open_reference_popup)
	image_frame.add_child(ref_viewer)
	ref_viewer.modulate.a = 0.0

	# --- ညာဘက်ခြမ်း (Drawing Area) ---
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.custom_minimum_size.x = 0
	right_panel.size_flags_stretch_ratio = 13.0
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.name = "Stage1DrawingCard"
	right_panel.add_theme_stylebox_override("panel", _stage1_glass("panel", 10))
	split.add_child(right_panel)

	var right: VBoxContainer = VBoxContainer.new()
	right.add_theme_constant_override("separation", 7)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right)

	var drawing_heading := _label("Layout Drawing Area", 21, "163657")
	drawing_heading.name = "Stage1DrawingHeading"
	right.add_child(drawing_heading)
	var drawing_hint := _label("1 Small Grid = 100 mm (e.g., 1,000 mm = 10 grids) | Click points to draw (straight or angled) | Drag = Move", 12, "45617b")
	drawing_hint.name = "Stage1DrawingHint"
	right.add_child(drawing_hint)
	# Compact tools grouped together; each callback retains its original function.
	var toolbar := HBoxContainer.new()
	toolbar.name = "Stage1DrawingToolbar"
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_theme_constant_override("separation", 10)
	right.add_child(toolbar)

	var tools_frame := PanelContainer.new()
	tools_frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tools_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	toolbar.add_child(tools_frame)
	var tools_row := HBoxContainer.new()
	tools_row.name = "Stage1SixToolGroup"
	tools_row.add_theme_constant_override("separation", 6)
	tools_frame.add_child(tools_row)

	var add_tool := func(label_text: String, action: Callable, min_width: float, warning: bool = false) -> void:
		var button := _button(label_text, action, min_width)
		button.name = "Stage1Tool" + label_text.replace(" ", "")
		button.custom_minimum_size.y = 34
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.clip_text = false
		button.add_theme_font_size_override("font_size", 14)
		_compact_button_style(button, false)
		var kind: String = {"Undo":"undo","Redo":"redo","Delete Last":"layers","Delete":"trash","Zoom In":"zoom","Zoom Out":"zoomout"}[label_text]
		button.icon = UI.icon(kind)
		button.add_theme_color_override("icon_normal_color",UI.TEAL)
		button.add_theme_color_override("icon_hover_color",UI.INK)
		button.add_theme_constant_override("icon_max_width",16)
		tools_row.add_child(button)
	add_tool.call("Undo", _undo, 80)
	add_tool.call("Redo", _redo, 80)
	add_tool.call("Delete Last", _delete, 124, true)
	add_tool.call("Delete", func() -> void: canvas.delete_selected_line(), 92, true)
	add_tool.call("Zoom In", _zoom_in, 106)
	add_tool.call("Zoom Out", _zoom_out, 116)

	# Separate Reset control keeps its original reset-view (zoom/pan) behavior.
	var reset_view_button := _button("Reset", _reset_view, 98)
	reset_view_button.name = "Stage1ResetView"
	reset_view_button.tooltip_text = "Reset drawing view (zoom and pan)"
	reset_view_button.custom_minimum_size = Vector2(72, 34)
	reset_view_button.add_theme_font_size_override("font_size", 14)
	_compact_button_style(reset_view_button)
	# All seven tools share the same glass toolbar, preserving both Reset actions.
	tools_row.add_child(reset_view_button)

	var drawing_frame := PanelContainer.new()
	drawing_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	drawing_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	drawing_frame.add_theme_stylebox_override("panel", _stage1_surface(Color("f2fbff"), Color("b4efff"), 17, 6))
	right.add_child(drawing_frame)
	canvas = CanvasScript.new()
	canvas.custom_minimum_size = Vector2(450, 350)
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.drawing_status_changed.connect(_on_drawing_status)
	drawing_frame.add_child(canvas)
	canvas.set_drawing_enabled(true)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	right.add_child(footer)

	status_panel = PanelContainer.new()
	status_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_panel.add_theme_stylebox_override("panel", _stage1_glass("button", 8))
	footer.add_child(status_panel)

	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 8)
	status_panel.add_child(status_row)
	_stage1_status_icon = PanelContainer.new()
	_stage1_status_icon.custom_minimum_size = Vector2(32, 32)
	_stage1_status_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stage1_status_icon.add_theme_stylebox_override("panel", _stage1_surface(Color("cd5551"), Color("d77f79"), 18, 3))
	_stage1_status_icon.visible = false
	status_row.add_child(_stage1_status_icon)
	_stage1_status_mark = _label("!", 18, "ffffff")
	_stage1_status_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stage1_status_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stage1_status_icon.add_child(_stage1_status_mark)
	status_label = _label("Draw the requested layout, then click Check Answer.", 12, "183f56")
	status_label.custom_minimum_size.y = 30
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_row.add_child(status_label)

	var clear_button := _button("Reset", _clear)
	clear_button.name = "Stage1ResetDrawing"
	clear_button.icon = preload("res://Stage1Assets/reset.svg")
	clear_button.add_theme_constant_override("icon_max_width", 18)
	clear_button.custom_minimum_size = Vector2(78, 34)
	_compact_button_style(clear_button)
	var hint := UI.button("Hint",func(): _set_status("Trace only the connected LDK area. Check each wall length and close the outline.",false),false,55,12)
	hint.name = "Stage1Hint"
	footer.add_child(hint)
	footer.add_child(clear_button)
	again_button_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	footer.add_child(again_button_row)
	again_button.custom_minimum_size = Vector2(98, 34)
	_compact_button_style(again_button, true)
	ok_button = _button("Check Answer", _confirm)
	ok_button.name = "Stage1CheckAnswer"
	ok_button.icon = preload("res://Stage1Assets/check.svg")
	ok_button.add_theme_constant_override("icon_max_width", 18)
	ok_button.custom_minimum_size = Vector2(132, 34)
	_compact_button_style(ok_button, false, true)
	footer.add_child(ok_button)

	_build_reference_popup(loaded_tex)

func _update_lang_buttons_style() -> void:
	if is_instance_valid(_stage1_language_picker):
		UI.update_language_switcher(_stage1_language_picker,current_lang)
	var active_s := _stage1_surface(Color("187f95"), Color("77bdc9"), 11, 5)
	var inactive_s := _stage1_surface(Color("f1f8fa"), Color("adced9"), 11, 5)
	for pair in [[jp_lang_btn,"jp"],[mm_lang_btn,"mm"],[en_lang_btn,"en"]]:
		var button: Button = pair[0]
		if not is_instance_valid(button):continue
		var active: bool = current_lang == pair[1]
		button.add_theme_stylebox_override("normal",active_s if active else inactive_s)
		button.add_theme_stylebox_override("hover",active_s if active else inactive_s)
		button.add_theme_color_override("font_color",Color.WHITE if active else Color("245366"))

func _switch_language(lang: String) -> void:
	Progress.set_language(lang)
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
		if ref_viewer != null:
			ref_viewer.modulate.a = 0.0
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
	header.add_child(_button("Close", func(): popup_overlay.visible = false, 90))

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
	if ref_viewer != null and ref_viewer.modulate.a < 0.99:
		return
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
		await get_tree().create_timer(delay, false).timeout
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
		await get_tree().create_timer(delay, false).timeout
	await _scroll_dialog_to_bottom()

func _reveal_reference_after_talk() -> void:
	if ref_viewer == null or not is_instance_valid(ref_viewer):
		return
	var fade := create_tween()
	fade.tween_property(ref_viewer, "modulate:a", 1.0, 0.65)

func _run_conversation() -> void:
	if ref_viewer != null:
		ref_viewer.modulate.a = 0.0
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
	status_label.text = LocaleManager.text(value)
	if is_instance_valid(_stage1_status_icon):
		_stage1_status_icon.visible = error or success
		_stage1_status_icon.add_theme_stylebox_override("panel", _stage1_surface(Color("c95654") if error else Color("4a9a78"), Color("e5a59e") if error else Color("92c8aa"), 18, 3))
		_stage1_status_mark.text = "!" if error else "✓"
	if error:
		status_panel.add_theme_stylebox_override("panel", _stage1_glass("danger", 8))
		status_label.add_theme_color_override("font_color", Color("991b1b"))
	elif success:
		status_panel.add_theme_stylebox_override("panel", _stage1_glass("speech", 8))
		status_label.add_theme_color_override("font_color", Color("14532d"))
	else:
		status_panel.add_theme_stylebox_override("panel", _stage1_glass("button", 8))
		status_label.add_theme_color_override("font_color", Color("143b63"))

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
	_reviewing_completed = false
	stage_transition_running = false
	ok_button.text = UI.text("Check Answer")
	last_eval_state = "none"
	request_label.visible = true
	request_label.text = DIALOGUE_TEXTS[current_lang]["request"]
	request_label.visible_characters = -1
	feedback_divider.visible = false
	feedback_label.visible = false
	feedback_label.text = ""
	again_button_row.visible = false
	dialog_bubble.add_theme_stylebox_override("panel", _stage1_glass("speech", 12))

func _on_again_pressed() -> void:
	typing_token += 1
	_reset_feedback_ui()
	canvas.clear_canvas()
	canvas.set_drawing_enabled(true)
	is_drawing_started = true
	_set_status("Canvas cleared. Please draw the layout again.", false)

func _confirm() -> void:
	if _reviewing_completed:
		_stop_voice()
		get_tree().change_scene_to_file("res://stage_2.tscn")
		return
	if not conversation_finished or not is_drawing_started:
		return
	ok_button.disabled = true
	again_button_row.visible = false

	var is_correct: bool = canvas.analyze_reference()

	if is_correct:
		Progress.unlock_level(2)
		last_eval_state = "correct"
		request_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		dialog_bubble.add_theme_stylebox_override("panel", _stage1_glass("speech", 12))
		feedback_label.add_theme_color_override("font_color", Color("14532d"))
		_set_status("Please wait for the customer to finish speaking.", false, true)
		feedback_label.text = DIALOGUE_TEXTS[current_lang]["correct"]
		_play_voice("correct")
		_start_auto_stage_transition()
	else:
		last_eval_state = "wrong"
		canvas.set_drawing_enabled(false)
		request_label.visible = true
		feedback_divider.visible = true
		feedback_label.visible = true
		dialog_bubble.add_theme_stylebox_override("panel", _stage1_glass("speech", 12))
		feedback_divider.color = Color("d6a49a")
		feedback_label.add_theme_color_override("font_color", Color("b91c1c"))
		_set_status("Red highlighted parts on the drawing are incorrect. Click 'Try Again'.", true)
		feedback_label.text = DIALOGUE_TEXTS[current_lang]["wrong"]
		_play_voice("wrong")
		again_button_row.visible = true
		await _scroll_dialog_to_bottom()
	ok_button.disabled = false

# ---------------- Recorded Japanese voice and synchronized subtitles ----------------
func _voice_path(kind: String) -> String:
	if current_lang == "en":
		return "res://Voice/en/stage1_%s.mp3" % kind
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
		if kind == "talk":
			_reveal_reference_after_talk()
		# No matching MP3: show the full text, then allow the user to continue.
		if target is RichTextLabel:
			request_label.visible_characters = -1
		if kind == "correct" and last_eval_state == "correct":
			_start_auto_stage_transition()
		return
	var stream: AudioStream = load(voice_path) as AudioStream
	if stream == null:
		if kind == "talk":
			_reveal_reference_after_talk()
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
	_set_voice_icon(voice_stop_button, "pause")

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
	button.custom_minimum_size = Vector2(30,30)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_constant_override("icon_max_width",18)
	for state in ["normal","hover","pressed"]:
		var compact := UI.box(Color("eff8ff"),UI.EDGE,15,4)
		compact.shadow_size = 0
		button.add_theme_stylebox_override(state,compact)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _stop_voice() -> void:
	if voice_player != null:
		voice_player.stop()
		voice_player.stream_paused = false
	if voice_stop_button != null:
		_set_voice_icon(voice_stop_button, "play")

func _toggle_voice_pause() -> void:
	if voice_player == null:
		return
	if voice_player.playing and not voice_player.stream_paused:
		voice_player.stream_paused = true
		_set_voice_icon(voice_stop_button, "play")
	elif voice_player.stream_paused:
		voice_player.stream_paused = false
		_set_voice_icon(voice_stop_button, "pause")
	else:
		_replay_voice()

func _replay_voice() -> void:
	var kind: String = voice_kind
	if kind == "":
		kind = "talk"
	_play_voice(kind)

func _on_voice_finished() -> void:
	if voice_stop_button != null:
		_set_voice_icon(voice_stop_button, "play")
	if voice_caption == request_label:
		request_label.visible_characters = -1
		_reveal_reference_after_talk()
	elif voice_caption == feedback_label and voice_kind != "":
		feedback_label.text = DIALOGUE_TEXTS[current_lang][voice_kind]
		if voice_kind == "correct" and last_eval_state == "correct":
			_start_auto_stage_transition()


func _start_auto_stage_transition() -> void:
	if stage_transition_running or last_eval_state != "correct" or not is_inside_tree():
		return
	stage_transition_running = true
	_set_status("Stage 1 complete. Continue when you are ready.", false, true)
	_run_stage_transition()

func _run_stage_transition() -> void:
	var overlay := preload("res://StageCompleteOverlay.gd").new()
	overlay.name = "Stage1CompleteOverlay"
	overlay.configure("Stage 1 complete!","The LDK boundary matches the reference plan.","Next Stage","View Levels","Review drawing",true,true)
	overlay.next_requested.connect(func():
		_stop_voice()
		get_tree().change_scene_to_file("res://stage_2.tscn")
	)
	overlay.levels_requested.connect(func():
		Progress.show_levels_on_open = true
		get_tree().change_scene_to_file("res://GameMenu.tscn")
	)
	overlay.home_requested.connect(func():
		_stop_voice()
		Progress.show_home_on_open=true
		Progress.show_levels_on_open=false
		get_tree().change_scene_to_file("res://GameMenu.tscn")
	)
	overlay.replay_requested.connect(func():
		overlay.queue_free()
		stage_transition_running = false
		_reviewing_completed = true
		ok_button.text = UI.text("Continue to Stage 2")
	)
	add_child(overlay)

func _make_levels_menu_button() -> Button:
	var btn := Button.new()
	btn.text = "LEVELS"
	btn.icon=preload("res://MenuAssets/BackArrow.svg")
	btn.add_theme_color_override("icon_normal_color",Color("216a58"))
	btn.add_theme_color_override("icon_hover_color",Color("124b3d"))
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


# Show the menu ON TOP of the running scene. Do not lose the drawing or timer.
func _open_game_menu() -> void:
	_save_session()
	if is_instance_valid(_pause_menu):
		return
	_voice_paused_for_menu = voice_player != null and voice_player.playing and not voice_player.stream_paused
	if _voice_paused_for_menu:
		voice_player.stream_paused = true
	var overlay := preload("res://GameMenu.tscn").instantiate() as Control
	overlay.set("is_pause_overlay", true)
	overlay.set("pause_level", 1)
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
		_switch_language(chosen_lang)
	elif _voice_paused_for_menu and voice_player != null:
		voice_player.stream_paused = false
	_voice_paused_for_menu = false

func _save_session() -> void:
	if _session_save_suspended or Progress.resume_stage()!=1 or not is_instance_valid(canvas) or last_eval_state=="correct": return
	Progress.save_drawing(canvas.lines,canvas.zoom_level,canvas.pan)

func _suspend_session_save() -> void:
	_session_save_suspended=true

func _exit_tree() -> void:
	_save_session()
