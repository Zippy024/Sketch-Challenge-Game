extends Control

# Stage 3: two image choices, then eight directly selected Japanese component names.
# Completion requires both layout questions and all eight component answers.
const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")
const StageRating = preload("res://StageRating.gd")
const UI_THEME: Theme = preload("res://WebBilingualTheme.tres")
const PORTRAIT: Texture2D = preload("res://customer_portrait_ui.png")
const IMAGES_Q1: Array[Texture2D] = [preload("res://Stage3Assets/Original/type_0.jpeg"), preload("res://Stage3Assets/Original/type_1.jpeg"), preload("res://Stage3Assets/Original/type_2.jpeg"), preload("res://Stage3Assets/Original/type_3.jpeg"), preload("res://Stage3Assets/Original/type_4.jpeg")]
const IMAGES_Q2: Array[Texture2D] = [preload("res://Stage3Assets/Original/detail_0.jpeg"), preload("res://Stage3Assets/Original/detail_1.jpeg"), preload("res://Stage3Assets/Clear/float.webp"), preload("res://Stage3Assets/Original/detail_3.jpeg")]
const BG := Color("e9eef5")
const PANEL := Color("f1f5f9")
const TEXT := Color("1f3c56")
const SUBTEXT := Color("6b7f98")
const BLUE := Color("008f98")
const GREEN := Color("008f98")
const OUTLINE := Color("d6e2ef")
const Parts = preload("res://Stage3Assets/Model/JapaneseParts.gd")
const Model = preload("res://Stage3Assets/Model/KitchenModel.gd")
const AnswerPopover = preload("res://Stage3Assets/Model/PartAnswerPopover.gd")
const Speech = preload("res://CustomerSpeech.gd")
const QUESTIONS := {
	"jp":["現在のキッチンと同じ場所に設置するとすれば、S-classではどのタイプになりますか？","現行のキッチンの後ろの壁も残すとすれば、どうなりますか？","それぞれのパーツの名前を教えてもらえますか？"],
	"mm":["ကျွန်တော့်ရဲ့ လက်ရှိမီးဖိုချောင်နဲ့ တစ်နေရာတည်းမှာ တပ်ဆင်မယ်ဆိုရင် ဘယ် S-class မော်ဒယ်က သင့်တော်မလဲ။","လက်ရှိမီးဖိုချောင်ရဲ့နောက်မှာ နံရံကိုဆက်ထားရင် ဘာဖြစ်မလဲ။","အစိတ်အပိုင်းတစ်ခုချင်းစီရဲ့ နာမည်တွေကို ပြောပြပေးနိုင်မလား။"],
	"en":["If I were to install it in the same location as my current kitchen, which model in the S-class series would be the right choice?","What would happen if we were to keep the wall behind the existing kitchen?","Could you tell me the names of the individual parts?"]
}


var current_lang: String = "jp"
var step: int = 0 # 0 = S-Class type, 1 = wall layout, 2..9 = identify eight components, 10 = completed
var last_wrong: bool = false
var _completion_acknowledged: bool = false
var _session_save_suspended: bool = false
var _left_dialogue: VBoxContainer
var _answer_area: VBoxContainer
var _pause_menu: Control
var _progress_bar: ProgressBar
var _feedback: Label
var _customer_bubble: PanelContainer
var _answer_state: String="neutral"
var _card_texture_cache: Dictionary = {}
var _last_phase: int=-1
var _transitioning: bool=false
var _transition_tween: Tween
var _parts_answers: Array[String]=["","","","","","","",""]
var _parts_solved: Array[bool]=[false,false,false,false,false,false,false,false]
var _parts_states: Array[String]=["","","","","","","",""]
var _answer_popover: Control
var _feedback_revision: int=0
var _popup_revision: int=0
var _hover_block_until: int=0
var _parts_count_label: Label
var _part_checklist: Array[Label]=[]
var _challenge_count: Label
var _parts_model: Control
var _parts_selected: int=0
var _model_pose: Dictionary={}
var _parts_message: String=""
var _speech_ready: bool=false
var _stage_choice_buttons: Array[Button]=[]
var _speech: Control


func _process(delta: float) -> void:
	if _speech_ready and not _transitioning:StageRating.advance(3,delta)


func _ready() -> void:
	theme = UI.make_theme()
	current_lang = Progress.get_language()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Progress.resume_stage()!=3: Progress.open_stage(3)
	step=Progress.kitchen_step()
	var saved:=Progress.kitchen_parts()
	_parts_answers.assign(saved.answers)
	_parts_solved.assign(saved.solved)
	for i in range(Parts.COUNT):
		if _parts_solved[i]:_parts_states[i]="correct"
	if step<Parts.CHALLENGE_STEPS:StageRating.begin(3)
	_completion_acknowledged=step>=Parts.CHALLENGE_STEPS
	_refresh()


func _style(background: Color, border: Color = OUTLINE, radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = background
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(11)
	return s


func _label(t: String, font_size: int = 17, color: Color = TEXT, wrap_text: bool = true) -> Label:
	var l := Label.new()
	l.text = LocaleManager.text(t)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	return l


func _btn(t: String, main: bool = false, w: float = 92.0) -> Button:
	return UI.button(t,Callable(),main,int(w),14)

func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _style(PANEL))
	return p


func _clear() -> void:
	if is_instance_valid(_speech):_speech.stop()
	_speech=null
	_speech_ready=false
	_stage_choice_buttons.clear()
	if is_instance_valid(_parts_model):_model_pose=_parts_model.view_state()
	_parts_model=null
	_answer_popover=null
	_part_checklist.clear()
	_feedback_revision+=1
	_popup_revision+=1
	_answer_state="neutral"
	last_wrong=false
	if _transition_tween and _transition_tween.is_valid():_transition_tween.kill()
	_transitioning=false
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _refresh() -> void:
	_clear()
	if step >= Parts.CHALLENGE_STEPS and not _completion_acknowledged:
		UI.background(self,true)
		_show_completion()
		return
	if step >= Parts.CHALLENGE_STEPS:
		var results := preload("res://ResultsScreen.gd").new()
		results.levels_requested.connect(_go_levels)
		results.replay_requested.connect(_retry_stage)
		results.home_requested.connect(func(): get_tree().change_scene_to_file("res://GameMenu.tscn"))
		add_child(results)
		return
	var page := UI.page(self,3,"S-Class Kitchen Selection",_open_game_menu,_change_lang)
	var split := HBoxContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_theme_constant_override("separation",18)
	page.add_child(split)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 7
	left.add_theme_constant_override("separation",12)
	split.add_child(left)
	var customer := UI.customer(left)
	_customer_bubble=customer.bubble
	customer.question.text = UI.bullet_text(_question_text())
	customer.bubble.custom_minimum_size.y = 110
	_speech=Speech.new()
	customer.voice.add_child(_speech)
	_speech.dialogue_started.connect(func():_set_speech_ready(false))
	_speech.dialogue_finished.connect(func():_set_speech_ready(true))
	customer.question.visible_characters=mini(12,customer.question.get_total_character_count())
	_begin_question_speech.call_deferred(_speech,customer.question,Speech.voice_path(current_lang,mini(step,2)))
	UI.set_customer_feedback(_customer_bubble,_answer_state)
	var brief := UI.card_stack(left,true)
	if step>=2: brief.add_theme_constant_override("separation",5)
	brief.add_child(UI.label("Mission brief",18,true))
	brief.add_child(UI.label("Select the matching kitchen illustration." if step<2 else "Click a kitchen part and type its name in Japanese.",15))
	_reference_tile(brief)
	if step>=2:
		brief.add_child(UI.label("Parts checklist",14,true))
		var checklist:=GridContainer.new()
		checklist.columns=2
		checklist.add_theme_constant_override("h_separation",12)
		checklist.add_theme_constant_override("v_separation",2)
		brief.add_child(checklist)
		for i in range(Parts.COUNT):
			var caption:=str(i+1)+" · "+(_parts_answers[i] if _parts_solved[i] else UI.text("Not answered"))
			var item:=UI.label(caption,12,_parts_solved[i],UI.TEAL if _parts_solved[i] else UI.MUTED)
			item.name="Stage3PartProgress%d"%(i+1)
			item.set_meta("locale_ignore",true)
			item.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			checklist.add_child(item)
			_part_checklist.append(item)
	var right := UI.card_stack(split,true)
	right.get_parent().name="Stage3AnswerCard"
	right.get_parent().size_flags_stretch_ratio = 13
	var heading:=HBoxContainer.new()
	heading.add_theme_constant_override("separation",12)
	right.add_child(heading)
	var title:=UI.label("Kitchen Selection" if step<2 else "Kitchen Parts",25 if step<2 else 21,true)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var retry:=UI.button(_tr("Retry","ပြန်ကစားမည်","もう一度"),_retry_stage,false,110,14)
	retry.name="Stage3Retry"
	retry.icon=preload("res://Stage1Assets/reset.svg")
	retry.tooltip_text=_tr("Restart Stage 3","အဆင့် ၃ ကို အစမှပြန်ကစားမည်","ステージ3を最初からやり直す")
	heading.add_child(retry)
	var phase:=mini(step,2)
	var phases:=HBoxContainer.new()
	phases.name="Stage3Sections"
	phases.add_theme_constant_override("separation",8)
	right.add_child(phases)
	for i in range(3):
		var chip:=PanelContainer.new()
		chip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		chip.add_theme_stylebox_override("panel",UI.box(Color("e5f3ed") if i==phase else Color("f7fbf8"),Color("8bbeb2") if i==phase else Color("d7e8e0"),12,6))
		phases.add_child(chip)
		var caption:=UI.label(str(i+1)+" · "+_phase_name(i),12,i==phase)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(caption)
	if step<2:right.add_child(UI.label(_tr("Section %d of 3","အပိုင်း ၃ ပိုင်းမှ %d","全3項目中 %d項目")%(phase+1),14,false,UI.MUTED))
	_answer_area = VBoxContainer.new()
	_answer_area.add_theme_constant_override("separation",14)
	_answer_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_answer_area)
	if step<2: _draw_choices()
	else: _draw_parts()
	_feedback = UI.label(_parts_message if step>=2 else ("Please try another choice." if last_wrong else ""),14,false,Color("b32741") if last_wrong else UI.TEAL)
	_feedback.custom_minimum_size.y = 28
	if step<2:right.add_child(_feedback)
	else:
		add_child(_feedback)
		_feedback.hide()
	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation",12)
	right.add_child(progress)
	progress.add_child(UI.inline_label("Challenge progress",14,true))
	_progress_bar = ProgressBar.new()
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_bar.custom_minimum_size.y = 10
	_progress_bar.max_value = Parts.CHALLENGE_STEPS
	_progress_bar.value = maxi(0,step-1) if _answer_state=="correct" else step
	_progress_bar.show_percentage = false
	_progress_bar.add_theme_stylebox_override("background",UI.box(Color("d7e6ed"),Color.TRANSPARENT,5,0))
	_progress_bar.add_theme_stylebox_override("fill",UI.box(UI.TEAL,Color.TRANSPARENT,5,0))
	progress.add_child(_progress_bar)
	if _answer_state=="correct":create_tween().tween_property(_progress_bar,"value",step,0.42).set_trans(Tween.TRANS_SINE)
	_challenge_count=UI.inline_label("%d / %d"%[step,Parts.CHALLENGE_STEPS],14,true)
	progress.add_child(_challenge_count)
	if _last_phase>=0 and _last_phase!=phase:_enter_phase(right.get_parent())
	_last_phase=phase

func _set_speech_ready(ready: bool) -> void:
	_speech_ready=ready
	for button in _stage_choice_buttons:
		if is_instance_valid(button):button.disabled=not ready

func _begin_question_speech(speech: Control, caption: Label, path: String) -> void:
	await get_tree().process_frame
	while is_instance_valid(speech) and speech==_speech and _transitioning:
		await get_tree().process_frame
	if not is_instance_valid(speech) or speech!=_speech or not speech.is_inside_tree():return
	speech.start(caption,path)

func _reference_tile(parent: VBoxContainer) -> void:
	var card:=PanelContainer.new()
	card.name="Stage3ReferenceTile"
	card.size_flags_vertical=Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel",UI.box(Color("f2fafb"),Color("c8e0e8"),12,6))
	parent.add_child(card)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	var title:=UI.label("Reference Plan",13,true,UI.TEAL)
	content.add_child(title)
	var plan:=TextureRect.new()
	plan.name="Stage3ReferencePlan"
	plan.texture=preload("res://Refrence image.png")
	plan.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	plan.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plan.size_flags_vertical=Control.SIZE_EXPAND_FILL
	plan.custom_minimum_size=Vector2(160,100)
	plan.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(plan)

func _tr(en: String, mm: String, jp: String) -> String:
	return {"en":en,"mm":mm,"jp":jp}.get(current_lang,en)

func _phase_name(index: int) -> String:
	return [
		_tr("Kitchen type","မီးဖိုချောင်ပုံစံ","キッチンタイプ"),
		_tr("Layout detail","ပုံစံအသေးစိတ်","レイアウト詳細"),
		_tr("Components","အစိတ်အပိုင်းများ","部材の選択")
	][index]

func _retry_stage() -> void:
	StageRating.begin(3,true)
	Progress.open_stage(3)
	step=0
	_completion_acknowledged=false
	last_wrong=false
	_answer_state="neutral"
	_last_phase=-1
	_parts_answers.assign(["","","","","","","",""])
	_parts_solved.assign([false,false,false,false,false,false,false,false])
	_parts_states.assign(["","","","","","","",""])
	_parts_message=""
	_parts_model=null
	_model_pose.clear()
	_refresh()

func _enter_phase(card: Control) -> void:
	# A visible centered section announcement, rather than a near-invisible 3px line.
	var reduced:=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	_transitioning=true
	var veil:=ColorRect.new()
	veil.name="Stage3TransitionShield"
	veil.color=Color(0.04,0.16,0.19,0.36)
	veil.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center:=CenterContainer.new()
	center.name="Stage3PhaseAnnouncement"
	center.mouse_filter=Control.MOUSE_FILTER_STOP
	veil.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var toast:=PanelContainer.new()
	toast.custom_minimum_size=Vector2(455,148)
	var frame:=UI.box(Color("f2fbfc"),Color("6ec9c7"),22,14)
	frame.set_border_width_all(2)
	frame.shadow_color=Color(0.0,0.16,0.19,0.25)
	frame.shadow_size=10
	toast.add_theme_stylebox_override("panel",frame)
	center.add_child(toast)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	toast.add_child(content)
	var chapter:=UI.label(_tr("SECTION %d OF 3","အပိုင်း %d / ၃","セクション %d / 3")%(_last_phase+2),17,true,UI.TEAL)
	chapter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(chapter)
	var headline:=UI.label(_phase_name(mini(step,2)),25,true,UI.INK)
	headline.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(headline)
	var hint:=UI.label(_tr("Next challenge ready","နောက်ထပ်မစ်ရှင်သို့ ရောက်ပါပြီ","次の課題です"),13,false,UI.MUTED)
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	_transition_tween=create_tween()
	if reduced:
		_transition_tween.tween_interval(0.12)
	else:
		toast.pivot_offset=toast.custom_minimum_size*0.5
		toast.modulate.a=0.0
		toast.scale=Vector2(0.92,0.92)
		_transition_tween.tween_property(toast,"modulate:a",1.0,0.18)
		_transition_tween.parallel().tween_property(toast,"scale",Vector2.ONE,0.21).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_interval(0.22)
		_transition_tween.tween_property(toast,"modulate:a",0.0,0.15)
	_transition_tween.finished.connect(func():
		_transitioning=false
		if is_instance_valid(veil):veil.queue_free()
	)


func _question_text() -> String:
	return QUESTIONS[current_lang][mini(step,2)]

# Card artwork is deliberately prepared at modest native resolution rather than
# shrinking 1448px line art to ~210px with only one bilinear sample. Generate
# mipmaps at runtime so small diagonal lines stay continuous on Godot desktop/Web.
# Cached across question transitions; does not affect selection or answer logic.
func _card_texture_for_screen(source: Texture2D) -> Texture2D:
	var id: int = source.get_instance_id()
	if _card_texture_cache.has(id):
		return _card_texture_cache[id] as Texture2D
	var img: Image = source.get_image()
	if img != null and not img.is_empty():
		if not img.has_mipmaps():
			var result: Error = img.generate_mipmaps()
			if result != OK:
				_card_texture_cache[id] = source
				return source
		var mipped: ImageTexture = ImageTexture.create_from_image(img)
		_card_texture_cache[id] = mipped
		return mipped
	_card_texture_cache[id] = source
	return source


func _draw_choices() -> void:
	_answer_area.add_child(_label("S-classのキッチンタイプを選んでください。" if step == 0 else "プランレイアウト詳細を選択してください。", 18, TEXT))
	# Use the original source illustrations in the supplied reference order.
	var labels: Array[String] = []
	var textures: Array[Texture2D] = []
	if step == 0:
		labels = ["I型", "L型", "対面", "II型", "アイランド"]
		textures = IMAGES_Q1
	else:
		labels = ["フルフラット", "耐力壁", "フロート", "ラウンドアクセス"]
		textures = IMAGES_Q2

	var surface := PanelContainer.new()
	surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	surface.add_theme_stylebox_override("panel", _style(Color.WHITE, OUTLINE, 12))
	_answer_area.add_child(surface)

	var cards := GridContainer.new()
	# Desktop: all the choices on one row. Small windows wrap rather than scroll sideways.
	var viewport_width: float = get_viewport_rect().size.x
	cards.columns = labels.size() if viewport_width >= 1100.0 else mini(3, labels.size())
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 11)
	cards.add_theme_constant_override("v_separation", 12)
	surface.add_child(cards)

	for i in range(labels.size()):
		var option := Button.new()
		option.text = ""
		option.custom_minimum_size = Vector2(128, 260 if step==1 else 240)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_theme_stylebox_override("normal", _style(Color.WHITE, OUTLINE, 9))
		var hover_style:=_style(Color("eef9f5"),UI.TEAL,9)
		hover_style.set_border_width_all(2)
		option.add_theme_stylebox_override("hover",hover_style)
		option.add_theme_stylebox_override("pressed", _style(Color("f7faff"), Color("b5c6d9"), 9))
		option.add_theme_stylebox_override("focus",UI.box(Color.TRANSPARENT,UI.TEAL,12,0))
		option.focus_mode = Control.FOCUS_ALL
		option.name = "KitchenChoice%d" % i
		option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cards.add_child(option)

		var option_col := VBoxContainer.new()
		option_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option_col.add_theme_constant_override("separation", 6)
		option.add_child(option_col)
		option_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		option_col.offset_left = 5
		option_col.offset_top = 5
		option_col.offset_right = -5
		option_col.offset_bottom = -6

		var pic := TextureRect.new()
		pic.texture = _card_texture_for_screen(textures[i])
		pic.custom_minimum_size.y = 188
		pic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Show the whole image; DO NOT stretch-cover or cut away the hood/cabinets.
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if step==1:
			# Keep low-resolution originals at a readable, bounded display size.
			var slot:=Control.new()
			slot.mouse_filter=Control.MOUSE_FILTER_IGNORE
			slot.custom_minimum_size.y=188
			slot.size_flags_vertical=Control.SIZE_EXPAND_FILL
			option_col.add_child(slot)
			pic.custom_minimum_size=Vector2.ZERO
			slot.add_child(pic)
			var fit:=func():
				if not is_instance_valid(pic) or not is_instance_valid(slot):return
				var aspect:=float(pic.texture.get_width())/float(pic.texture.get_height())
				var width:=minf(minf(slot.size.x,220.0),minf(slot.size.y,147.0)*aspect)
				pic.size=Vector2(width,width/aspect)
				pic.position=(slot.size-pic.size)*0.5
			slot.resized.connect(fit)
			fit.call_deferred()
			var clarity:=ShaderMaterial.new()
			clarity.shader=preload("res://UIAssets/diagram-clarity.gdshader")
			if i==2:
				clarity.set_shader_parameter("strength",0.45)
				clarity.set_shader_parameter("ink_boost",0.06)
			pic.material=clarity
			var frame:=Panel.new()
			frame.name="DiagramFrame"
			frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var frame_style:=UI.box(Color.TRANSPARENT,Color("d7dbd9"),0,0)
			frame_style.shadow_size=0
			frame.add_theme_stylebox_override("panel",frame_style)
			pic.add_child(frame)
			frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		else:
			option_col.add_child(pic)

		var caption := _label(labels[i], 14, TEXT, step==1)
		if step==1:caption.custom_minimum_size.y=44
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option_col.add_child(caption)
		option.disabled=not _speech_ready
		_stage_choice_buttons.append(option)
		option.pressed.connect(_choose.bind(i))

	_answer_area.add_child(_label("Select an image. A correct choice automatically opens the next question." if current_lang == "jp" else "အဖြေမှန်ရွေးလိုက်တာနဲ့ နောက်မေးခွန်းကို အလိုအလျောက် သွားပါမယ်။", 13, SUBTEXT))

func _choose(index: int) -> void:
	if not _speech_ready or _transitioning or step>=2:return
	var correct_index: int=2 if step==0 else 1
	if index==correct_index:
		step+=1
		Progress.save_kitchen_step(step)
		_show_verdict("correct")
		_transitioning=true
		var revision:=_feedback_revision
		get_tree().create_timer(0.40,false).timeout.connect(_advance_choice.bind(step,revision))
	else:
		StageRating.mistake(3)
		_show_verdict("incorrect")

func _advance_choice(expected_step: int, revision: int) -> void:
	if step==expected_step and revision==_feedback_revision:_refresh()

func _show_verdict(state: String) -> void:
	_feedback_revision+=1
	_answer_state=state
	last_wrong=state=="incorrect"
	UI.set_customer_feedback(_customer_bubble,state)
	if is_instance_valid(_feedback):
		_feedback.text=UI.text("Correct" if state=="correct" else "Incorrect")
		_feedback.add_theme_color_override("font_color",UI.TEAL if state=="correct" else Color("b32741"))
	get_tree().create_timer(1.0,false).timeout.connect(_expire_verdict.bind(_feedback_revision))

func _expire_verdict(revision: int) -> void:
	if revision!=_feedback_revision:return
	_answer_state="neutral"
	last_wrong=false
	if is_instance_valid(_customer_bubble):UI.set_customer_feedback(_customer_bubble,"neutral")
	if is_instance_valid(_feedback):_feedback.text=""

func _draw_parts() -> void:
	_answer_area.add_theme_constant_override("separation",6)
	var toolbar:=HBoxContainer.new()
	toolbar.add_theme_constant_override("separation",5)
	_answer_area.add_child(toolbar)
	var model:=Model.new()
	model.name="KitchenPartsDiagram"
	model.custom_minimum_size=Vector2(300,220)
	model.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	model.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for preset in ["perspective","front","rear"]:
		toolbar.add_child(UI.button({"perspective":"3D","front":"Front view","rear":"Rear view"}[preset],model.set_view.bind(preset),false,54,11))
	for direction in [-1,1]:
		var orbit:=UI.button("↶" if direction==-1 else "↷",model.rotate_by.bind(float(direction)*PI/4),false,34,18)
		orbit.name="OrbitLeft" if direction==-1 else "OrbitRight"
		orbit.tooltip_text=UI.text("Rotate left" if direction==-1 else "Rotate right")
		toolbar.add_child(orbit)
	for direction in [-1,1]:toolbar.add_child(UI.button("+" if direction==-1 else "−",model.zoom_by.bind(float(direction)*0.2),false,30,15))
	_parts_count_label=UI.label(UI.text("%d / %d names correct")%[_parts_solved.count(true),Parts.COUNT],12,true,UI.TEAL)
	_parts_count_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_parts_count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	toolbar.add_child(_parts_count_label)
	model.part_selected.connect(_select_part)
	model.interaction_started.connect(_close_answer)
	_answer_area.add_child(model)
	_parts_model=model
	model.apply_view_state(_model_pose)
	model.set_solved(_parts_solved)
	model.set_selected(-1)
	_answer_area.add_child(UI.label("Click a part to answer · Drag to rotate 360° · Scroll to zoom",12,false,UI.MUTED))
	var editor:=AnswerPopover.new()
	model.add_child(editor)
	_answer_popover=editor
	editor.draft_changed.connect(_popover_draft_changed)
	editor.answer_submitted.connect(_submit_part_answer)
	editor.close_requested.connect(_close_answer)
	editor.resized.connect(_position_answer)
	model.view_changed.connect(_position_answer)

func _select_part(which: int) -> void:
	_open_answer(which,true)

func _open_answer(which: int, focus_input: bool=true) -> void:
	if not _speech_ready or _transitioning or step<2 or step>=Parts.CHALLENGE_STEPS or which<0 or which>=Parts.COUNT:return
	if not is_instance_valid(_answer_popover):return
	_parts_selected=which
	_popup_revision+=1
	_feedback_revision+=1
	_expire_verdict(_feedback_revision)
	_parts_model.set_selected(which)
	if _answer_popover.part_index!=which or not _answer_popover.visible:
		_answer_popover.configure(which,_parts_answers[which],_parts_solved[which])
	_answer_popover.show()
	_position_answer.call_deferred()
	if focus_input:_answer_popover.input.grab_focus()

func _position_answer() -> void:
	if not is_instance_valid(_answer_popover) or not is_instance_valid(_parts_model) or not _answer_popover.visible or not _parts_model.is_inside_tree():return
	var anchor: Vector2=_parts_model.part_center(_parts_selected)
	var desired:=anchor+Vector2(24,-110)
	var limit: Vector2=_parts_model.size-_answer_popover.size-Vector2(10,10)
	_answer_popover.position=desired.clamp(Vector2(10,10),limit.max(Vector2(10,10)))

func _close_answer() -> void:
	_popup_revision+=1
	_hover_block_until=Time.get_ticks_msec()+250
	if is_instance_valid(_answer_popover):
		_answer_popover.hide()
		_answer_popover.input.release_focus()
	if is_instance_valid(_parts_model):_parts_model.set_selected(-1)

func _popover_draft_changed(value: String) -> void:
	if _parts_selected<0 or _parts_selected>=Parts.COUNT:return
	_parts_answers[_parts_selected]=value
	Progress.save_kitchen_parts(_parts_answers,_parts_solved)

func _submit_part_answer(value: String) -> void:
	if not _speech_ready or _transitioning or step<2 or step>=Parts.CHALLENGE_STEPS:return
	var index: int=_parts_selected
	if index<0 or index>=Parts.COUNT or _parts_solved[index]:return
	_parts_answers[index]=value
	Progress.save_kitchen_parts(_parts_answers,_parts_solved)
	if Parts.normalize(value).is_empty():return
	if Parts.needs_conversion(value):
		_answer_popover.request_conversion()
		return
	if Parts.is_correct(index,value):
		_parts_solved[index]=true
		_parts_states[index]="correct"
		step=2+_parts_solved.count(true)
		Progress.save_kitchen_parts(_parts_answers,_parts_solved)
		_parts_model.set_solved(_parts_solved)
		_part_checklist[index].text=str(index+1)+" · "+value
		_part_checklist[index].add_theme_color_override("font_color",UI.TEAL)
		_answer_popover.show_result("correct")
		_show_verdict("correct")
		_parts_count_label.text=UI.text("%d / %d names correct")%[_parts_solved.count(true),Parts.COUNT]
		_progress_bar.value=step
		_challenge_count.text="%d / %d"%[step,Parts.CHALLENGE_STEPS]
		if step==Parts.CHALLENGE_STEPS:
			StageRating.finish(3)
			Progress.complete(3)
		if step==Parts.CHALLENGE_STEPS:get_tree().create_timer(0.70,false).timeout.connect(_finish_written_parts)
		else:get_tree().create_timer(0.70,false).timeout.connect(_after_part_correct.bind(_popup_revision))
	else:
		_parts_states[index]="incorrect"
		StageRating.mistake(3)
		_answer_popover.show_result("incorrect")
		_show_verdict("incorrect")

func _after_part_correct(revision: int) -> void:
	if revision==_popup_revision:_close_answer()

func _finish_written_parts() -> void:
	if step==Parts.CHALLENGE_STEPS:_refresh()


func _draw_completed() -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_answer_area.add_child(center)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 17)
	center.add_child(stack)
	var t := _label("STAGE 3 COMPLETE!", 27, GREEN, false)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(t)
	var thanks := _label("ありがとうございました！" if current_lang == "jp" else "ကျေးဇူးတင်ပါတယ်။", 22, TEXT)
	thanks.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(thanks)
	var levels := _btn("View Levels", true, 180)
	levels.pressed.connect(_go_levels)
	stack.add_child(levels)


func _change_lang(lang: String) -> void:
	current_lang = lang
	Progress.set_language(lang)
	_refresh()


func _go_levels() -> void:
	Progress.show_levels_on_open = true
	get_tree().change_scene_to_file("res://GameMenu.tscn")


func _open_game_menu() -> void:
	StageRating.checkpoint(true)
	_save_session()
	if is_instance_valid(_pause_menu):
		return
	if is_instance_valid(_speech):_speech.pause_for_menu()
	var overlay := preload("res://GameMenu.tscn").instantiate() as Control
	overlay.set("is_pause_overlay", true)
	overlay.set("pause_level", 3)
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
	if current_lang != Progress.get_language():
		current_lang = Progress.get_language()
		_refresh()
	elif is_instance_valid(_speech):_speech.resume_from_menu()


func _show_completion() -> void:
	var popup := preload("res://StageCompleteOverlay.gd").new()
	popup.name="Stage3CompleteOverlay"
	popup.stage_index=3
	popup.configure("","","View Results","View Levels")
	popup.next_requested.connect(func():
		_completion_acknowledged=true
		_refresh()
	)
	popup.home_requested.connect(func():
		Progress.show_home_on_open=true
		Progress.show_levels_on_open=false
		get_tree().change_scene_to_file("res://GameMenu.tscn")
	)
	popup.levels_requested.connect(_go_levels)
	popup.retry_requested.connect(_retry_stage)
	add_child(popup)

func _save_session() -> void:
	if _session_save_suspended or Progress.resume_stage()!=3:return
	if is_instance_valid(_answer_popover) and _answer_popover.visible and _answer_popover.part_index>=0:
		_parts_answers[_answer_popover.part_index]=_answer_popover.input.text
	if step>=2:Progress.save_kitchen_parts(_parts_answers,_parts_solved)
	Progress.save_kitchen_step(step)

func _suspend_session_save() -> void:
	_session_save_suspended=true

func _exit_tree() -> void:
	StageRating.checkpoint(true)
	_save_session()
