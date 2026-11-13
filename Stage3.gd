extends Control

# Stage 3 only: two image-choice questions followed by five kitchen-part selections.
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
const NAMES: Array[String] = ["カウンター", "キッチンボード", "フード", "腰壁", "その他"]
const EN_PARTS: Array[String] = ["Countertop", "Kitchen board", "Range hood", "Half wall", "Other fixtures"]

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


func _process(delta: float) -> void:
	StageRating.advance(3,delta)


func _ready() -> void:
	theme = UI.make_theme()
	current_lang = Progress.get_language()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Progress.resume_stage()!=3: Progress.open_stage(3)
	step=Progress.kitchen_step()
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
	brief.add_child(UI.label("Select the matching kitchen illustration." if step<2 else "Identify the kitchen components from the diagram.",15))
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
			brief.add_child(UI.label(("✓  " if i<step-2 else "○  ")+UI.text(EN_PARTS[i]),15,i==step-2,UI.TEAL if i<=step-2 else UI.MUTED))
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
	right.add_child(UI.label((_tr("Section %d of 3","အပိုင်း ၃ ပိုင်းမှ %d","全3項目中 %d項目")%(phase+1)) if step<2 else UI.text("Part %d of 5")%(step-1),14,false,UI.MUTED))
	_answer_area = VBoxContainer.new()
	_answer_area.add_theme_constant_override("separation",14)
	_answer_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_answer_area)
	if step<2: _draw_choices()
	else: _draw_parts()
	_feedback = UI.label("Please try another choice." if last_wrong else "",15,false,Color("b32741") if last_wrong else UI.TEAL)
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
	return LocaleManager.text("それぞれのパーツの名前を教えてもらえますか？" if current_lang == "jp" else "မီးဖိုချောင်အစိတ်အပိုင်းတွေကို ရွေးပြနိုင်မလား။")

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
	var needed: int = step - 2
	_answer_area.add_child(_label(LocaleManager.text("Select: %s") % LocaleManager.text(NAMES[needed]), 18, BLUE))
	var instruction:=_tr("Point to a part, or choose its button below.","ပစ္စည်းပေါ် ထောက်ကြည့်ပါ၊ သို့မဟုတ် အောက်ကခလုတ်ဖြင့် ရွေးပါ။","部材にカーソルを合わせるか、下のボタンで選択してください。")
	var hover_label:=_label(instruction,13,SUBTEXT)
	hover_label.name="PartHoverLabel"
	_answer_area.add_child(hover_label)
	var diagram := KitchenDiagram.new()
	diagram.custom_minimum_size = Vector2(450, 220)
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.name = "KitchenPartsDiagram"
	diagram.item_selected.connect(_select_part)
	diagram.item_hovered.connect(func(index: int):
		hover_label.text=(str(index+1)+" · "+LocaleManager.text(NAMES[index])) if index>=0 else instruction
		hover_label.add_theme_color_override("font_color",UI.TEAL if index>=0 else SUBTEXT)
	)
	_answer_area.add_child(diagram)
	var choices:=GridContainer.new()
	choices.columns=3 if get_viewport_rect().size.x>=1100 else 2
	choices.add_theme_constant_override("h_separation",8)
	choices.add_theme_constant_override("v_separation",8)
	_answer_area.add_child(choices)
	for i in range(NAMES.size()):
		var button:=UI.button(str(i+1)+" · "+LocaleManager.text(NAMES[i]),_select_part.bind(i),false,110,13)
		button.name="KitchenPartButton%d"%i
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y=40
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var hover_style:=UI.box(Color("e7f5ef"),UI.TEAL,12,8)
		hover_style.set_border_width_all(2)
		hover_style.shadow_size=0
		button.add_theme_stylebox_override("hover",hover_style)
		button.mouse_entered.connect(diagram.set_hovered.bind(i))
		button.focus_entered.connect(diagram.set_hovered.bind(i))
		button.mouse_exited.connect(diagram.clear_hover.bind(i))
		button.focus_exited.connect(diagram.clear_hover.bind(i))
		choices.add_child(button)


func _select_part(which: int) -> void:
	if _transitioning or step<2 or step>=7:return
	if which == step - 2:
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
	if not _session_save_suspended and Progress.resume_stage()==3: Progress.save_kitchen_step(step)

func _suspend_session_save() -> void:
	_session_save_suspended=true

func _exit_tree() -> void:
	StageRating.checkpoint(true)
	_save_session()


class KitchenDiagram extends Control:
	signal item_selected(which: int)
	signal item_hovered(which: int)
	var hovered: int=-1
	var zones: Array[Rect2] = [Rect2(89,181,445,44),Rect2(205,77,323,94),Rect2(100,70,99,68),Rect2(88,260,488,58),Rect2(531,161,58,150)]
	var tip_colors: Array[Color] = [Color("72bbdf"), Color("c2d7e7"), Color("8ba6c5"), Color("d4c4b1"), Color("f3d8ab")]

	func _ready() -> void:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)
		mouse_exited.connect(set_hovered.bind(-1))

	func _draw() -> void:
		# A deliberately simple schematic, not a substituted 3D model asset.
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, true)
		var sx: float = w / 650.0
		var sy: float = h / 390.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx,sy))
		draw_rect(Rect2(0,0,650,390),Color("f7fafc"))
		draw_rect(Rect2(0,307,650,83),Color("e9d8c3"))
		# rear wall section
		draw_rect(Rect2(83,62,480,246),Color("f5f5f4"))
		draw_rect(Rect2(83,62,480,246),Color("c8cfd8"),false,2)
		# upper kitchen board
		draw_rect(Rect2(205,83,316,78),Color("cbdce8"))
		for x in [280,357,435]:
			draw_line(Vector2(x,83),Vector2(x,161),Color("8198ac"),2)
		# hood above hob
		draw_rect(Rect2(105,76,85,43),Color("8fa6bb"))
		draw_rect(Rect2(127,119,41,9),Color("758ea8"))
		# tall side fixture
		draw_rect(Rect2(532,171,45,134),Color("f0d6a8"))
		# half wall in front
		draw_rect(Rect2(90,270,480,42),Color("dbc7b2"))
		# lower base cabinet
		draw_rect(Rect2(104,205,432,95),Color("e6f1f8"))
		for x in [204,303,403]:
			draw_line(Vector2(x,205),Vector2(x,300),Color("a2b5c9"),2)
		# countertop slab
		draw_colored_polygon(PackedVector2Array([Vector2(93,194),Vector2(508,194),Vector2(536,215),Vector2(104,215)]),Color("90d4f0"))
		draw_line(Vector2(93,194),Vector2(508,194),Color("3a8ba9"),3)
		# sink and faucet
		draw_rect(Rect2(325,196,80,17),Color("a0b7c5"))
		draw_arc(Vector2(362,190),18,PI,TAU,20,Color("627f92"),3)
		# cooktop
		for center in [Vector2(156,208),Vector2(186,208)]:
			draw_arc(center,9,0,TAU,20,Color("64798e"),2)
		# clickable outlines identify the five conceptual elements.
		for r in zones:
			draw_rect(r,Color(0.58, 0.66, 0.75, 0.25),false,1)
		if hovered>=0:
			draw_rect(zones[hovered],Color(0.0,0.56,0.60,0.14),true)
			draw_rect(zones[hovered],Color("008f98"),false,3)
		draw_set_transform(Vector2.ZERO)
		for i in range(zones.size()):
			var point := (zones[i].position+Vector2(15,15))*Vector2(sx,sy)
			draw_circle(point,15 if i==hovered else 12,Color("006d75") if i==hovered else Color("008f98"))
			draw_string(ThemeDB.fallback_font,point+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)

	func set_hovered(index: int) -> void:
		if hovered==index:return
		hovered=index
		mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if index>=0 else Control.CURSOR_ARROW
		item_hovered.emit(index)
		queue_redraw()

	func clear_hover(index: int) -> void:
		if hovered==index:set_hovered(-1)

	func _hit_test(position: Vector2) -> int:
		var point:=position*Vector2(650.0/maxf(size.x,1.0),390.0/maxf(size.y,1.0))
		# Match the hover and click target, with small objects taking priority.
		for i in [2,1,4,3,0]:
			if zones[i].has_point(point):return i
		# A few pixels of tolerance help at the edge of thin items.
		for i in [2,1,4,3,0]:
			if zones[i].grow(5).has_point(point):return i
		return -1

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			set_hovered(_hit_test(event.position))
		elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			var index:=_hit_test(event.position)
			if index>=0:
				accept_event()
				item_selected.emit(index)
