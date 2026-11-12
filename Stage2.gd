extends Control

const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")
const AIConfig = preload("res://AIConfig.gd")
const StageRating = preload("res://StageRating.gd")

const QUESTIONS := {
	"en": {
		"name": "Ms. Hosokawa",
		"question": "By the way, what does PS on the floor plan mean?",
		"answer_hint": "Type your answer here...",
		"answer_title": "Your answer",
		"check": "Check Answer",
		"empty": "Please enter an answer first.",
		"demo": "Demo (AI not connected): ",
		"good": "I understand very well!",
		"needs": "I am not quite sure I understand.",
		"back": "Back to Stage 1",
		"reset": "Clear",
		"lang_note": "Stage 2 | Customer question",
		"offline": "DEMO CHECK — AI will be connected later"
	},
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

	# Stage 2: PS points from the 1695 × 928 reference image.
	# Normalized coordinates keep highlights aligned during zoom and pan.
	const PS_POINTS: Array[Vector2] = [
		Vector2(862.5 / 1695.0, 431.5 / 928.0),
		Vector2(838.5 / 1695.0, 720.0 / 928.0),
		Vector2(1174.0 / 1695.0, 678.5 / 928.0)
	]
	const PS_PULSE_TIME: float = 2.5
	const PS_STAGGER: float = 0.32
	var _ps_hint_elapsed: float = 0.0
	var _ps_hint_active: bool = false

	func _ready() -> void:
		play_ps_hint()

	# The PS rings remain printed on the image after the short overlay motion.
	func play_ps_hint() -> void:
		_ps_hint_elapsed = 0.0
		_ps_hint_active = true
		set_process(true)
		queue_redraw()

	func _process(delta: float) -> void:
		if not _ps_hint_active:
			return
		_ps_hint_elapsed += delta
		if _ps_hint_elapsed >= PS_PULSE_TIME + PS_STAGGER * float(PS_POINTS.size() - 1):
			_ps_hint_active = false
			set_process(false)
		queue_redraw()

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
		# Animated rings are drawn in the same coordinate space as the texture.
		# The background already contains the stationary red PS circles.
		if _ps_hint_active:
			for i in range(PS_POINTS.size()):
				var pulse_time: float = _ps_hint_elapsed - float(i) * PS_STAGGER
				if pulse_time < 0.0 or pulse_time >= PS_PULSE_TIME:
					continue
				var cycle: float = fposmod(pulse_time, 0.82) / 0.82
				var fade: float = 1.0 - pulse_time / PS_PULSE_TIME
				var alpha: float = maxf(0.0, sin(cycle * PI)) * fade
				var uv: Vector2 = PS_POINTS[i]
				var center: Vector2 = pos + Vector2(uv.x * drawn_size.x, uv.y * drawn_size.y)
				var base_radius: float = maxf(8.0, 27.0 * scale_factor)
				var pulse_radius: float = base_radius * (1.08 + cycle * 0.82)
				var red: Color = Color(0.96, 0.10, 0.08, 0.85 * alpha)
				draw_circle(center, pulse_radius * 0.68, Color(1.0, 0.14, 0.10, 0.09 * alpha))
				draw_arc(center, pulse_radius, 0.0, TAU, 48, red, 2.5, true)

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
var last_evaluation_source: String = "offline"
var _ai_http: HTTPRequest
var _ai_busy: bool = false
var _completion_shown: bool = false
var _completion_voice_finished: bool = false
var _dialogue_generation: int = 0
var _session_save_suspended: bool = false
var name_label: Label
var bubble: PanelContainer
var question_label: Label
var feedback_divider: ColorRect
var feedback_label: Label
var answer_title: Label
var answer_input: TextEdit
# Plan Q&A status stays in the answer footer; customer speech stays on the left.
var progress_card: PanelContainer
var progress_description: Label
var progress_actions: HBoxContainer
var submit_button: Button
var jp_button: Button
var mm_button: Button
var en_button: Button
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
	_ai_http = HTTPRequest.new()
	_ai_http.timeout = 40.0 # Three backend models can take about 30 seconds total.
	add_child(_ai_http)
	_ai_http.request_completed.connect(_on_ai_request_completed)
	_setup_multilang_font()

	voice_player = AudioStreamPlayer.new()
	add_child(voice_player)
	voice_player.finished.connect(_on_voice_finished)

	if Progress.resume_stage()!=2: Progress.open_stage(2)
	StageRating.begin(2)
	_build_ui()
	answer_input.text=Progress.answer()
	answer_input.text_changed.connect(_save_session)
	_apply_web_readability(self)
	_change_language(Progress.get_language())
	_play_entrance_fade()

# Shared font policy: keep Stage 2 desktop appearance; bundle fonts for browsers.
# Reference-project method: one bundled bilingual Theme for both desktop and Web.
# This avoids SystemFont dependency and provides Myanmar glyph fallback.
const BILINGUAL_THEME: Theme = preload("res://WebBilingualTheme.tres")

func _setup_multilang_font() -> void:
	theme = UI.make_theme()

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
	l.text = LocaleManager.text(t)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Color(c))
	l.add_theme_font_size_override("font_size", sz)
	return l

func _modern_button_style(button: Button, kind: String = "secondary") -> void:
	UI.style_button(button,kind=="primary",14,kind=="warning")

func _btn(t: String, min_width: float = 85.0) -> Button:
	var b := Button.new()
	b.text = LocaleManager.text(t)
	b.custom_minimum_size = Vector2(min_width, 37)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 15)
	_modern_button_style(b, "primary" if t == "Check Answer" else ("back" if t == "Back to Stage 1" else "secondary"))
	return b

func _build_ui() -> void:
	var page := UI.page(self,2,"Pipe Shaft Q&A",_open_game_menu,_change_language)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation",18)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(split)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 7
	left.add_theme_constant_override("separation",12)
	split.add_child(left)
	var customer := UI.customer(left)
	name_label = customer.name
	bubble = customer.bubble
	question_label = customer.question
	var dialogue: VBoxContainer = customer.dialogue
	feedback_divider = ColorRect.new()
	feedback_divider.custom_minimum_size.y = 1
	feedback_divider.color = UI.EDGE
	dialogue.add_child(feedback_divider)
	feedback_label = UI.label("",14)
	dialogue.add_child(feedback_label)
	voice_replay_button = UI.button("",_replay_voice,false,30,12)
	voice_stop_button = UI.button("",_toggle_voice_pause,false,30,12)
	_set_voice_icon(voice_replay_button,"replay")
	_set_voice_icon(voice_stop_button,"pause")
	customer.voice.name="CustomerVoiceControls"
	customer.voice.hide()
	customer.voice.add_child(voice_replay_button)
	customer.voice.add_child(UI.inline_label("Replay",12))
	customer.voice.add_child(voice_stop_button)
	customer.voice.add_child(UI.inline_label("Pause",12))
	var reference := UI.card_stack(left,true)
	var ref_title := UI.button("Reference Plan  ↗",_open_reference_popup,false,160,16)
	ref_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	reference.add_child(ref_title)
	var texture := preload("res://reference_ps_stage2.png")
	var embedded := PlanViewer.new(texture)
	embedded.custom_minimum_size.y = 170
	embedded.size_flags_vertical = Control.SIZE_EXPAND_FILL
	embedded.open_requested.connect(_open_reference_popup)
	reference.add_child(embedded)
	_create_reference_popup(texture)
	var right_panel := PanelContainer.new()
	right_panel.name="Stage2AnswerCard"
	right_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio=13
	right_panel.add_theme_stylebox_override("panel",UI.box(Color(0.94,0.98,1.0,0.82),Color.WHITE,24,18))
	split.add_child(right_panel)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation",14)
	right_panel.add_child(right)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",10)
	right.add_child(header)
	var mark := TextureRect.new()
	mark.texture=UI.icon("planqa")
	mark.modulate=UI.TEAL
	mark.custom_minimum_size=Vector2(30,32)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(mark)
	answer_title=UI.label("Plan Q&A",24,true)
	answer_title.name="Stage2QATitle"
	answer_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(answer_title)
	var instructions:=UI.label("Type your answer, then press OK.",14,false,UI.MUTED)
	instructions.name="Stage2AnswerInstructions"
	right.add_child(instructions)
	status_label=UI.label("",12)
	status_label.hide()
	right.add_child(status_label)
	var input_frame:=PanelContainer.new()
	input_frame.name="Stage2AnswerFrame"
	input_frame.size_flags_vertical=Control.SIZE_EXPAND_FILL
	input_frame.add_theme_stylebox_override("panel",UI.box(Color("f3faff"),UI.EDGE,12,10))
	right.add_child(input_frame)
	answer_input=TextEdit.new()
	answer_input.name="Stage2AnswerInput"
	answer_input.custom_minimum_size.y=260
	answer_input.size_flags_vertical=Control.SIZE_EXPAND_FILL
	answer_input.add_theme_font_size_override("font_size",18)
	answer_input.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	answer_input.add_theme_color_override("font_color",UI.INK)
	answer_input.add_theme_color_override("font_placeholder_color",Color("99a6ba"))
	answer_input.add_theme_color_override("caret_color",UI.TEAL)
	for state in ["normal","focus","read_only"]:
		var border:=UI.box(Color.WHITE,UI.TEAL if state=="focus" else UI.EDGE,14,16)
		border.set_border_width_all(2 if state=="focus" else 1)
		border.shadow_size=0
		answer_input.add_theme_stylebox_override(state,border)
	input_frame.add_child(answer_input)
	_build_progress_panel(right)

func _qa_button(value: String,action: Callable,primary: bool,width: int=104,font_size: int=16) -> Button:
	var button:=UI.button(value,action,primary,width,font_size)
	button.custom_minimum_size.y=48
	return button

func _build_progress_panel(parent: VBoxContainer) -> void:
	var footer:=HBoxContainer.new()
	footer.name="Stage2AnswerFooter"
	footer.add_theme_constant_override("separation",12)
	parent.add_child(footer)
	progress_card=PanelContainer.new()
	progress_card.name="Stage2AnswerStatus"
	progress_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	progress_card.custom_minimum_size.y=50
	footer.add_child(progress_card)
	progress_description=UI.label("",14,false,UI.MUTED)
	progress_description.name="Stage2AnswerStatusText"
	progress_card.add_child(progress_description)
	submit_button=_qa_button("OK",_check_ai_or_demo_answer,true,104,16)
	submit_button.name="Stage2SubmitAnswer"
	submit_button.set_meta("locale_ignore",true)
	submit_button.text="OK"
	footer.add_child(submit_button)
	progress_actions=HBoxContainer.new()
	footer.add_child(progress_actions)
	var next:=_qa_button("Next Stage",func():
		_stop_voice()
		get_tree().change_scene_to_file("res://stage_3.tscn")
	,true,120,15)
	next.name="ContinueStage3"
	progress_actions.add_child(next)
	progress_actions.hide()
	_set_progress_state("pending")

func _replay_stage_two() -> void:
	_reset_answer()
	_play_voice("question")

func _set_progress_state(state: String,message: String="") -> void:
	if progress_card==null:return
	var text: String="Type your answer, then press OK."
	var fill:=Color("f0fafc")
	var edge:=UI.EDGE
	var ink:=UI.MUTED
	match state:
		"completed":
			text="Stage 2 complete!" if _completion_voice_finished else "Please wait for the customer to finish speaking."
			fill=Color("edf9f4")
			edge=Color("7acbb5")
			ink=Color("246c58")
		"incorrect":
			text="Revise your explanation and try again."
			fill=Color("fff3f2")
			edge=Color("edafa9")
			ink=Color("ad3743")
		"checking":text="Checking your answer..."
		"error":
			text="Please try again. This is not a wrong answer."
			fill=Color("fff7e8")
			edge=Color("e8c17d")
			ink=Color("98632c")
		"invalid":
			text=message if not message.is_empty() else "Answer needed"
			edge=Color("edafa9")
			ink=Color("ad3743")
	var style:=UI.box(fill,edge,10,12)
	style.shadow_size=0
	progress_card.add_theme_stylebox_override("panel",style)
	progress_description.text=UI.text(text)
	progress_description.add_theme_color_override("font_color",ink)
	var ready_for_next: bool=state=="completed" and _completion_voice_finished
	progress_actions.visible=ready_for_next
	submit_button.visible=not ready_for_next
	submit_button.disabled=_ai_busy or state in ["checking","completed"]

func _update_lang_buttons_style() -> void:
	var active_s := _style("2563eb", "1d4ed8")
	var inactive_s := _style("ffffff", "cbd5e1")
	for pair in [[jp_button,"jp"],[mm_button,"mm"],[en_button,"en"]]:
		var button: Button = pair[0]
		if not is_instance_valid(button):continue
		var active: bool = current_lang == pair[1]
		button.add_theme_stylebox_override("normal",active_s if active else inactive_s)
		button.add_theme_stylebox_override("hover",active_s if active else inactive_s)
		button.add_theme_color_override("font_color",Color.WHITE if active else Color("1e293b"))

func _change_language(lang: String) -> void:
	_cancel_ai_request()
	Progress.set_language(lang)
	_stop_voice()
	current_lang = lang
	theme = UI.make_theme()
	var picker := find_child("GameLanguagePicker",true,false) as Control
	if picker: UI.update_language_switcher(picker,lang)
	_update_lang_buttons_style()
	var d: Dictionary = QUESTIONS[lang]
	name_label.text = str(d["name"])
	answer_title.text = UI.text("Plan Q&A")
	answer_input.placeholder_text = str(d["answer_hint"])
	submit_button.text = "OK"
	status_label.text = "AI CHECK · 3 MODELS" if _is_ai_configured() else "LOCAL CHECK · OFFLINE"

	if last_eval_state == "good":
		question_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		_set_progress_state("completed")
		progress_actions.hide()
		_play_voice("good")
		if last_evaluation_source == "local":
			status_label.text = "LOCAL CHECK · APPROXIMATE"
	elif last_eval_state == "needs":
		question_label.visible = true
		question_label.text = UI.bullet_text(str(d["question"]))
		feedback_divider.visible = true
		feedback_label.visible = true
		_set_progress_state("incorrect")
		_play_voice("needs")
		if last_evaluation_source == "local":
			status_label.text = "LOCAL CHECK · APPROXIMATE"
	else:
		question_label.visible = true
		feedback_divider.visible = false
		feedback_label.visible = false
		_set_progress_state("pending")
		_play_voice("question")
	UI.set_customer_feedback(bubble,{"good":"correct","needs":"incorrect"}.get(last_eval_state,"neutral"),false)

func _reset_answer() -> void:
	_completion_shown=false
	_cancel_ai_request()
	_stop_voice()
	last_eval_state = "none"
	last_evaluation_source = "none"
	status_label.text = "AI CHECK · 3 MODELS" if _is_ai_configured() else "LOCAL CHECK · OFFLINE"
	answer_input.clear()
	_set_progress_state("pending")
	question_label.visible = true
	question_label.text = UI.bullet_text(str(QUESTIONS[current_lang]["question"]))
	feedback_divider.visible = false
	feedback_label.visible = false
	UI.set_customer_feedback(bubble,"neutral")
	answer_input.grab_focus()

# Stage 2 Gemini AI: HTTP requests go only to our Cloudflare Worker; no API key in game.
func _is_ai_configured() -> bool:
	return AIConfig.API_URL.begins_with("https://") and not AIConfig.API_URL.contains("REPLACE")

func _cancel_ai_request() -> void:
	if _ai_busy:
		_ai_busy = false
		if is_instance_valid(_ai_http):
			_ai_http.cancel_request()
	if is_instance_valid(submit_button):
		submit_button.disabled = false

func _check_ai_or_demo_answer() -> void:
	if _ai_busy or last_eval_state=="good":
		return
	var answer: String = answer_input.text.strip_edges()
	var d: Dictionary = QUESTIONS[current_lang]
	if answer.is_empty():
		_set_progress_state("invalid", str(d["empty"]))
		return
	if answer.length() > 1200:
		_set_progress_state("invalid", "回答が長すぎます。" if current_lang == "jp" else "အဖြေစာသား အရမ်းရှည်နေပါတယ်။")
		return
	if not _is_ai_configured():
		_check_demo_answer()
		return

	_ai_busy = true
	submit_button.disabled = true
	_set_progress_state("checking")
	status_label.text = "AI CHECK · TRYING MODELS"
	# The deployed grading endpoint accepts jp/mm; its verdict supports answers in any language.
	# Keep that wire contract while the English interface uses the same unchanged grading rules.
	var payload: String = JSON.stringify({"language": "jp" if current_lang == "en" else current_lang, "answer": answer})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err: Error = _ai_http.request(AIConfig.API_URL, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		_ai_busy = false
		submit_button.disabled = false
		_check_demo_answer() # Network or request setup failed: local fallback.

func _on_ai_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not _ai_busy:
		return
	_ai_busy = false
	submit_button.disabled = false
	var response_data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200 and response_data is Dictionary:
		var verdict: Variant = response_data.get("correct", null)
		if typeof(verdict) == TYPE_BOOL:
			var model: String = str(response_data.get("model", "Gemini"))
			last_evaluation_source = model
			_show_check_result(bool(verdict))
			status_label.text = "AI CHECK · " + model
			return
	# HTTP 429, 503, timeout, invalid JSON, etc.: The Worker already tried all
	# available AI models. NEVER mislabel an AI outage as a wrong AI answer.
	_check_demo_answer()

func _show_ai_error() -> void:
	# Kept as an optional manual error UI; routine outages use local fallback.
	status_label.text = "AI CHECK · CONNECTION ERROR"
	_set_progress_state("error")

func _show_check_result(correct: bool) -> void:
	var d: Dictionary = QUESTIONS[current_lang]
	if correct:
		Progress.complete(2)
		last_eval_state = "good"
		question_label.visible = false
		feedback_divider.visible = false
		feedback_label.visible = true
		UI.set_customer_feedback(bubble,"correct")
		feedback_label.add_theme_color_override("font_color", Color("14532d"))
		_set_progress_state("completed")
		progress_actions.hide()
		_play_voice("good")
	else:
		StageRating.mistake(2)
		last_eval_state = "needs"
		question_label.visible = true
		question_label.text = UI.bullet_text(str(d["question"]))
		feedback_divider.visible = true
		feedback_label.visible = true
		UI.set_customer_feedback(bubble,"incorrect")
		feedback_divider.color = Color("f87171")
		feedback_label.add_theme_color_override("font_color", Color("b91c1c"))
		_set_progress_state("incorrect")
		_play_voice("needs")

func _has_any_keyword(text: String, options: Array[String]) -> bool:
	for word in options:
		if text.contains(word):
			return true
	return false

func _check_demo_answer() -> void:
	# V15 Local Fallback: CONSERVATIVE keyword approximation, not semantic AI.
	# THREE PS concepts must ALL be present (same standard as the Gemini grader).
	# It is safer to request another attempt than to mark a vague answer correct.
	var answer: String = answer_input.text.strip_edges()
	if answer.is_empty():
		_set_progress_state("invalid", str(QUESTIONS[current_lang]["empty"]))
		return
	last_evaluation_source = "local"
	var s: String = answer.to_lower().replace("　", " ").replace("\n", " ")

	# 1) Dedicated pipe shaft / service SPACE in a building.
	var space_words: Array[String] = [
		"shaft", "space", "duct", "service void", "service chase", "riser", "cavity",
		"シャフト", "スペース", "空間", "縦穴", "竪穴", "場所", "配管室",
		"နေရာ", "အခန်း", "ပိုက်ခန်း", "ပိုက်ရှပ်", "ပိုက်လမ်းကြောင်း"
	]
	var identity_ok: bool = _has_any_keyword(s, space_words)

	# 2) Pipe services running through a VERTICAL space.
	var pipe_words: Array[String] = [
		"pipe", "plumb", "water supply", "drain", "water line", "wastewater",
		"配管", "給水", "排水", "パイプ", "水道管", "水管",
		"ရေပိုက်", "ရေပေး", "ရေဆင်း", "ရေထုတ်", "ရေဆိုး", "ပိုက်လိုင်း", "ပိုက်များ", "ပိုက်တွေ", "ပိုက်"
	]
	var vertical_words: Array[String] = [
		"vertical", "vertically", "shaft", "riser", "up and down", "upright",
		"縦", "竪", "垂直", "上下", "シャフト",
		"ဒေါင်လိုက်", "အပေါ်အောက်", "အထက်အောက်"
	]
	var purpose_ok: bool = _has_any_keyword(s, pipe_words) and _has_any_keyword(s, vertical_words)

	# 3) The PS cannot easily be moved/relocated during renovation.
	var movement_words: Array[String] = [
		"mov", "relocat", "reposition", "shift the shaft", "shift the ps", "change its position", "fixed",
		"移動", "移設", "動か", "移す", "変更", "固定",
		"ရွှေ့", "ပြောင်း", "နေရာပြောင်း", "တည်နေရာ"
	]
	var restriction_words: Array[String] = [
		"cannot", "can't", "can not", "not easy", "not easily", "difficult", "hard to", "impossible", "fixed", "not movable", "non-movable", "not permitted",
		"できません", "できない", "難しい", "困難", "不可", "簡単ではない", "簡単に動かせない", "固定", "容易ではない", "不可能",
		"မရ", "မနိုင်", "မလွယ်", "ခက်", "အလွယ်တကူ မ", "အလွယ်တကူမ", "အလွယ်တကူ ရွှေ့၍မရ", "မဖြစ်နိုင်"
	]
	var relocation_ok: bool = _has_any_keyword(s, movement_words) and _has_any_keyword(s, restriction_words)

	# Explicitly incorrect definitions must not be accepted.
	var wrong_definition: Array[String] = ["pipe shift", "pipe-shift", "pipe size", "パイプシフト"]
	var wrong: bool = _has_any_keyword(s, wrong_definition)
	# Reject obviously easy-to-move claims unless a genuine negation is also stated.
	var easy_move: Array[String] = ["easy to move", "easy to relocate", "can easily move", "can easily be moved", "can be easily moved", "簡単に動かせます", "容易に移動できます", "ရွှေ့လို့ရပါတယ်", "ရွှေ့လို့ရတယ်"]
	if _has_any_keyword(s, easy_move) and not _has_any_keyword(s, restriction_words):
		wrong = true

	var correct: bool = identity_ok and purpose_ok and relocation_ok and not wrong
	_show_check_result(correct)
	status_label.text = "LOCAL CHECK · APPROXIMATE"

# ---------------- Stage 2 Voice & Subtitle Animation ----------------
func _voice_path(kind: String) -> String:
	if current_lang == "en":
		var english_path := "res://Voice/en/stage2_%s.mp3" % kind
		return english_path if ResourceLoader.exists(english_path) else ""
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
	if kind=="question":full_text=UI.bullet_text(full_text)
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
			_on_voice_finished()
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
	button.custom_minimum_size = Vector2(30,30)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_constant_override("icon_max_width",18)
	for state in ["normal","hover","pressed"]:
		var compact := UI.box(Color("eff8ff"),UI.EDGE,15,4)
		compact.shadow_size = 0
		button.add_theme_stylebox_override(state,compact)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _stop_voice() -> void:
	_dialogue_generation += 1
	_completion_voice_finished=false
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
		voice_caption.text = UI.bullet_text(str(QUESTIONS[current_lang][voice_kind])) if voice_kind=="question" else str(QUESTIONS[current_lang][voice_kind])
		if voice_kind=="good" and last_eval_state=="good":
			_completion_voice_finished=true
			_set_progress_state("completed")
			_show_completion()

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
		# Re-play a short hint whenever the plan is opened enlarged.
		if is_instance_valid(popup_viewer):
			popup_viewer.play_ps_hint()

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


func _open_game_menu() -> void:
	_save_session()
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

func _show_completion() -> void:
	if _completion_shown or not _completion_voice_finished or last_eval_state!="good": return
	_completion_shown=true
	var generation := _dialogue_generation
	await get_tree().create_timer(0.35,false).timeout
	if generation!=_dialogue_generation or not _completion_voice_finished or last_eval_state!="good" or not is_inside_tree():
		_completion_shown=false
		return
	var popup := preload("res://StageCompleteOverlay.gd").new()
	popup.name="Stage2CompleteOverlay"
	popup.stage_index=2
	popup.configure("","","Next Stage","View Levels")
	popup.next_requested.connect(func():
		_stop_voice()
		get_tree().change_scene_to_file("res://stage_3.tscn")
	)
	popup.levels_requested.connect(func():
		_stop_voice()
		Progress.show_levels_on_open=true
		get_tree().change_scene_to_file("res://GameMenu.tscn")
	)
	popup.home_requested.connect(func():
		_stop_voice()
		Progress.show_home_on_open=true
		Progress.show_levels_on_open=false
		get_tree().change_scene_to_file("res://GameMenu.tscn")
	)
	popup.retry_requested.connect(func():
		_stop_voice()
		_suspend_session_save()
		Progress.open_stage(2)
		get_tree().change_scene_to_file("res://stage_2.tscn")
	)
	add_child(popup)

func _save_session() -> void:
	if _session_save_suspended or Progress.resume_stage()!=2 or not is_instance_valid(answer_input) or last_eval_state=="good": return
	Progress.save_answer(answer_input.text)

func _suspend_session_save() -> void:
	_session_save_suspended=true

func _exit_tree() -> void:
	_save_session()
