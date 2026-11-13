extends Control

# Stage 3: two image-choice questions, then five Japanese names on a real 3D model.
# Two layout questions and five components; completion is saved only after all seven checks.
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


var current_lang: String = "jp"
var step: int = 0 # 0 = S-Class type, 1 = wall layout, 2..6 = identify five components, 7 = completed
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
var _parts_answers: Array[String]=["","","","",""]
var _parts_solved: Array[bool]=[false,false,false,false,false]
var _parts_states: Array[String]=["","","","",""]
var _parts_fields: Array[LineEdit]=[]
var _parts_model: Control
var _parts_selected: int=0
var _model_pose: Dictionary={}
var _parts_message: String=""


func _process(delta: float) -> void:
	StageRating.advance(3,delta)


func _ready() -> void:
	theme = UI.make_theme()
	current_lang = Progress.get_language()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Progress.resume_stage()!=3: Progress.open_stage(3)
	step=Progress.kitchen_step()
	var saved:=Progress.kitchen_parts()
	_parts_answers.assign(saved.answers)
	_parts_solved.assign(saved.solved)
	for i in range(5):
		if _parts_solved[i]:_parts_states[i]="correct"
	if step<7:StageRating.begin(3)
	_completion_acknowledged=step>=7
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
	if is_instance_valid(_parts_model):_model_pose=_parts_model.view_state()
	_parts_model=null
	_parts_fields.clear()
	if _transition_tween and _transition_tween.is_valid():_transition_tween.kill()
	_transitioning=false
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _refresh() -> void:
	_clear()
	if step >= 7 and not _completion_acknowledged:
		UI.background(self,true)
		_show_completion()
		return
	if step >= 7:
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
	customer.voice.hide()
	UI.set_customer_feedback(_customer_bubble,_answer_state)
	var brief := UI.card_stack(left,true)
	if step>=2: brief.add_theme_constant_override("separation",5)
	brief.add_child(UI.label("Mission brief",18,true))
	brief.add_child(UI.label("Select the matching kitchen illustration." if step<2 else "Select a number on the 3D model and type its name in Japanese.",15))
	if step < 2:
		var plan := TextureRect.new()
		plan.name = "Stage3ReferencePlan"
		plan.texture = preload("res://Refrence image.png")
		plan.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plan.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plan.custom_minimum_size.y = 145
		plan.size_flags_vertical = Control.SIZE_EXPAND_FILL
		brief.add_child(plan)
	else:
		brief.add_child(UI.label("Parts checklist",16,true))
		for i in range(5):
			var caption:=str(i+1)+" · "+(_parts_answers[i] if _parts_solved[i] else UI.text("Not answered"))
			brief.add_child(UI.label(caption,15,_parts_solved[i],UI.TEAL if _parts_solved[i] else UI.MUTED))
		brief.add_child(UI.label("Drag to rotate. Scroll to zoom. The numbers stay attached to their parts.",13,false,UI.MUTED))
	var right := UI.card_stack(split,true)
	right.get_parent().name="Stage3AnswerCard"
	right.get_parent().size_flags_stretch_ratio = 13
	var heading:=HBoxContainer.new()
	heading.add_theme_constant_override("separation",12)
	right.add_child(heading)
	var title:=UI.label("Kitchen Selection" if step<2 else "Kitchen Parts",25,true)
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
	right.add_child(UI.label((_tr("Section %d of 3","အပိုင်း ၃ ပိုင်းမှ %d","全3項目中 %d項目")%(phase+1)) if step<2 else UI.text("%d / 5 names correct")%_parts_solved.count(true),14,false,UI.MUTED))
	_answer_area = VBoxContainer.new()
	_answer_area.add_theme_constant_override("separation",14)
	_answer_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_answer_area)
	if step<2: _draw_choices()
	else: _draw_parts()
	_feedback = UI.label(_parts_message if step>=2 else ("Please try another choice." if last_wrong else ""),14,false,Color("b32741") if last_wrong else UI.TEAL)
	_feedback.custom_minimum_size.y = 28
	right.add_child(_feedback)
	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation",12)
	right.add_child(progress)
	progress.add_child(UI.inline_label("Challenge progress",14,true))
	_progress_bar = ProgressBar.new()
	_progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_progress_bar.custom_minimum_size.y = 10
	_progress_bar.max_value = 7
	_progress_bar.value = maxi(0,step-1) if _answer_state=="correct" else step
	_progress_bar.show_percentage = false
	_progress_bar.add_theme_stylebox_override("background",UI.box(Color("d7e6ed"),Color.TRANSPARENT,5,0))
	_progress_bar.add_theme_stylebox_override("fill",UI.box(UI.TEAL,Color.TRANSPARENT,5,0))
	progress.add_child(_progress_bar)
	if _answer_state=="correct":create_tween().tween_property(_progress_bar,"value",step,0.42).set_trans(Tween.TRANS_SINE)
	progress.add_child(UI.inline_label("%d / 7"%step,14,true))
	if _last_phase>=0 and _last_phase!=phase:_enter_phase(right.get_parent())
	_last_phase=phase

func _tr(en: String, mm: String, jp: String) -> String:
	return {"en":en,"mm":mm,"jp":jp}.get(current_lang,en)

func _phase_name(index: int) -> String:
	return [
		_tr("Kitchen type","မီးဖိုချောင်ပုံစံ","キッチンタイプ"),
		_tr("Layout detail","ပုံစံအသေးစိတ်","レイアウト詳細"),
		_tr("Components","အစိတ်အပိုင်းများ","部材の選択")
	][index]

func _retry_stage() -> void:
	Progress.open_stage(3)
	step=0
	_completion_acknowledged=false
	last_wrong=false
	_answer_state="neutral"
	_last_phase=-1
	_parts_answers.assign(["","","","",""])
	_parts_solved.assign([false,false,false,false,false])
	_parts_states.assign(["","","","",""])
	_parts_message=""
	_parts_model=null
	_model_pose.clear()
	_refresh()

func _enter_phase(card: Control) -> void:
	var reduced_motion:=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	_transitioning=true
	# Block repeat clicks until the next section has visibly arrived.
	var shield:=Control.new()
	shield.name="Stage3TransitionShield"
	shield.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(shield)
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_transition_tween=create_tween()
	if reduced_motion:
		_transition_tween.tween_interval(0.12)
	else:
		card.modulate.a=0.15
		# Let the panel size a transparent holder, keeping the accent only 3 px tall.
		var accent:=Control.new()
		accent.mouse_filter=Control.MOUSE_FILTER_IGNORE
		card.add_child(accent)
		var sweep:=ColorRect.new()
		sweep.name="Stage3PhaseSweep"
		sweep.color=UI.TEAL
		sweep.mouse_filter=Control.MOUSE_FILTER_IGNORE
		accent.add_child(sweep)
		sweep.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		sweep.offset_left=2
		sweep.offset_right=-2
		sweep.offset_top=1
		sweep.offset_bottom=4
		sweep.scale.x=0.0
		_transition_tween.set_parallel(true)
		_transition_tween.tween_property(card,"modulate:a",1.0,0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_transition_tween.tween_property(sweep,"scale:x",1.0,0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_transition_tween.chain().tween_property(sweep,"modulate:a",0.0,0.1)
		_transition_tween.chain().tween_callback(accent.queue_free)
	_transition_tween.finished.connect(func():
		_transitioning=false
		if is_instance_valid(shield):shield.queue_free()
	)

func _question_text() -> String:
	if step == 0:
		return LocaleManager.text("現在のキッチンと同じ場所に設置するとすれば、S-classではどのタイプになりますか？" if current_lang == "jp" else "လက်ရှိမီးဖိုချောင်နေရာမှာ S-Class တပ်မယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။")
	if step == 1:
		return LocaleManager.text("現行のキッチンの後ろの壁も残すとすれば、どうなりますか？" if current_lang == "jp" else "မူလ Kitchen နောက်ဘက်နံရံကို ဆက်ထားမယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။")
	return LocaleManager.text("Please write the name of each numbered part in Japanese.")

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
		option.pressed.connect(_choose.bind(i))

	_answer_area.add_child(_label("Select an image. A correct choice automatically opens the next question." if current_lang == "jp" else "အဖြေမှန်ရွေးလိုက်တာနဲ့ နောက်မေးခွန်းကို အလိုအလျောက် သွားပါမယ်။", 13, SUBTEXT))

func _choose(index: int) -> void:
	if _transitioning or step>=2:return
	var correct_index: int = 2 if step == 0 else 1
	if index == correct_index:
		_answer_state="correct"
		step += 1
		Progress.save_kitchen_step(step)
		if step == 7:
			StageRating.finish(3)
			Progress.complete(3)
		last_wrong = false
		_refresh()
	else:
		StageRating.mistake(3)
		last_wrong = true
		_answer_state="incorrect"
		UI.set_customer_feedback(_customer_bubble,"incorrect")
		_feedback.text = "ちょっと違うようです。もう一度選んでください。" if current_lang == "jp" else "မမှန်သေးပါ။ ပြန်ရွေးပါ။"
		_feedback.add_theme_color_override("font_color", Color("c24144"))


func _draw_parts() -> void:
	_answer_area.add_theme_constant_override("separation",8)
	_answer_area.add_child(UI.label("Select a number on the 3D model and type its name in Japanese.",14))
	var content:=HBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	content.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_answer_area.add_child(content)
	var model_column:=VBoxContainer.new()
	model_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	model_column.size_flags_stretch_ratio=1.5
	model_column.add_theme_constant_override("separation",6)
	content.add_child(model_column)
	var toolbar:=HBoxContainer.new()
	toolbar.add_theme_constant_override("separation",4)
	model_column.add_child(toolbar)
	var model:=Model.new()
	model.name="KitchenPartsDiagram"
	model.custom_minimum_size=Vector2(360,260)
	model.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	model.size_flags_vertical=Control.SIZE_EXPAND_FILL
	for preset in ["perspective","front","rear"]:
		var button:=UI.button({"perspective":"3D","front":"Front view","rear":"Rear view"}[preset],func():model.set_view(preset),false,54,11)
		toolbar.add_child(button)
	for direction in [-1,1]:
		var button:=UI.button("+" if direction==-1 else "−",func():model.zoom_by(float(direction)*0.2),false,30,15)
		toolbar.add_child(button)
	model.part_selected.connect(_select_part)
	model.part_hovered.connect(func(index: int):
		if index>=0:model.tooltip_text=UI.text("Number %d")%(index+1)
		else:model.tooltip_text=""
	)
	model_column.add_child(model)
	_parts_model=model
	model.apply_view_state(_model_pose)
	model.set_solved(_parts_solved)
	model.set_selected(_parts_selected)
	model_column.add_child(UI.label("Drag to rotate · Scroll to zoom",11,false,UI.MUTED))
	var form:=UI.card_stack(content,true)
	form.get_parent().name="JapaneseAnswerForm"
	form.get_parent().custom_minimum_size.x=255
	form.get_parent().size_flags_stretch_ratio=1.0
	form.add_theme_constant_override("separation",8)
	form.add_child(UI.label("Write in Japanese",16,true))
	for i in range(5):
		var row:=HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		form.add_child(row)
		var number:=UI.button(str(i+1),_select_part.bind(i),false,30,13)
		number.name="PartNumber%d"%(i+1)
		row.add_child(number)
		var field:=LineEdit.new()
		field.name="PartAnswer%d"%(i+1)
		field.set_meta("locale_ignore",true)
		field.placeholder_text="日本語で入力"
		field.text=_parts_answers[i]
		field.editable=not _parts_solved[i]
		field.custom_minimum_size=Vector2(130,38)
		field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		field.add_theme_font_override("font",UI.font(false,"jp"))
		field.add_theme_font_size_override("font_size",15)
		field.add_theme_color_override("font_color",UI.INK)
		field.add_theme_color_override("font_placeholder_color",Color("80949b"))
		field.add_theme_color_override("font_uneditable_color",UI.INK)
		field.max_length=80
		var state:=_parts_states[i]
		var style:=UI.box(Color("e7f6ee") if state=="correct" else (Color("fff0f2") if state=="incorrect" else Color.WHITE),Color("91c6ac") if state=="correct" else (Color("dda5af") if state=="incorrect" else UI.EDGE),9,6)
		style.shadow_size=0
		field.add_theme_stylebox_override("normal",style)
		field.add_theme_stylebox_override("read_only",style)
		var focus:=UI.box(Color.TRANSPARENT,UI.TEAL,9,6)
		focus.shadow_size=0
		focus.set_border_width_all(2)
		field.add_theme_stylebox_override("focus",focus)
		field.text_changed.connect(_part_text_changed.bind(i))
		field.focus_entered.connect(func():
			_parts_selected=i
			if is_instance_valid(_parts_model):_parts_model.set_selected(i)
		)
		field.text_submitted.connect(func(_value: String):_submit_parts())
		row.add_child(field)
		_parts_fields.append(field)
		var verdict:=UI.label("✓" if _parts_solved[i] else ("×" if state=="incorrect" else ""),16,true,UI.TEAL if _parts_solved[i] else Color("b32741"))
		verdict.custom_minimum_size.x=17
		row.add_child(verdict)
	var spacer:=Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	spacer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	form.add_child(spacer)
	var submit:=UI.button("Check answers",_submit_parts,true,140,14)
	submit.name="CheckJapaneseParts"
	form.add_child(submit)

func _part_text_changed(value: String, index: int) -> void:
	_parts_answers[index]=value
	Progress.save_kitchen_parts(_parts_answers,_parts_solved)

func _select_part(which: int) -> void:
	if _transitioning or step<2 or step>=7 or which<0 or which>=5:return
	_parts_selected=which
	if is_instance_valid(_parts_model):_parts_model.set_selected(which)
	if which<_parts_fields.size():_parts_fields[which].grab_focus()

func _submit_parts() -> void:
	if _transitioning or step<2 or step>=7:return
	var errors: int=0
	var new_correct: int=0
	for i in range(5):
		if _parts_solved[i]:continue
		_parts_answers[i]=_parts_fields[i].text
		if Parts.normalize(_parts_answers[i]).is_empty():continue
		if Parts.is_correct(i,_parts_answers[i]):
			_parts_solved[i]=true
			_parts_states[i]="correct"
			new_correct+=1
		else:
			_parts_states[i]="incorrect"
			StageRating.mistake(3)
			errors+=1
	step=2+_parts_solved.count(true)
	Progress.save_kitchen_parts(_parts_answers,_parts_solved)
	if step==7:
		StageRating.finish(3)
		Progress.complete(3)
	last_wrong=errors>0
	_answer_state="incorrect" if errors>0 else ("correct" if new_correct>0 else "neutral")
	_parts_message="Please check the red answers. Use Japanese names." if errors>0 else ("Correct answers are saved. Complete the remaining numbers." if new_correct>0 else "Type the Japanese names beside the matching numbers.")
	_refresh()


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
	for i in range(_parts_fields.size()):
		if is_instance_valid(_parts_fields[i]):_parts_answers[i]=_parts_fields[i].text
	if step>=2:Progress.save_kitchen_parts(_parts_answers,_parts_solved)
	Progress.save_kitchen_step(step)

func _suspend_session_save() -> void:
	_session_save_suspended=true

func _exit_tree() -> void:
	StageRating.checkpoint(true)
	_save_session()
