extends Control

# Stage 3 only: two image-choice questions followed by five kitchen-part selections.
# Two layout questions and five components; completion is saved only after all seven checks.
const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")
const UI_THEME: Theme = preload("res://WebBilingualTheme.tres")
const PORTRAIT: Texture2D = preload("res://customer_portrait_ui.png")
const IMAGES_Q1: Array[Texture2D] = [preload("res://Stage3Assets/q1_1.png"), preload("res://Stage3Assets/q1_2.png"), preload("res://Stage3Assets/q1_3.png"), preload("res://Stage3Assets/q1_4.png"), preload("res://Stage3Assets/q1_5.png")]
const IMAGES_Q2: Array[Texture2D] = [preload("res://Stage3Assets/q2_1.png"), preload("res://Stage3Assets/q2_2.png"), preload("res://Stage3Assets/q2_3.png"), preload("res://Stage3Assets/q2_4.png")]
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
var _card_texture_cache: Dictionary = {}


func _ready() -> void:
	theme = UI.make_theme()
	current_lang = Progress.get_language()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Progress.resume_stage()!=3: Progress.open_stage(3)
	step=Progress.kitchen_step()
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
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _refresh() -> void:
	_clear()
	if step >= 7 and not _completion_acknowledged:
		UI.background(self)
		_show_completion()
		return
	if step >= 7:
		var results := preload("res://ResultsScreen.gd").new()
		results.levels_requested.connect(_go_levels)
		results.replay_requested.connect(func():
			Progress.open_stage(3)
			step = 0
			_completion_acknowledged=false
			last_wrong = false
			_refresh()
		)
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
	customer.question.text = _question_text()
	customer.bubble.custom_minimum_size.y = 110
	customer.voice.hide()
	var brief := UI.card_stack(left,true)
	if step>=2: brief.add_theme_constant_override("separation",5)
	brief.add_child(UI.label("Mission brief",18,true))
	brief.add_child(UI.label("Select the matching kitchen illustration." if step<2 else "Identify the kitchen components from the diagram.",15))
	if step < 2:
		var plan := TextureRect.new()
		plan.texture = preload("res://reference_sketch.png")
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
	right.get_parent().size_flags_stretch_ratio = 13
	right.add_child(UI.label("Kitchen Selection" if step<2 else "Kitchen Parts",25,true))
	right.add_child(UI.label(UI.text("Question %d of 2")%(step+1) if step<2 else UI.text("Part %d of 5")%(step-1),14,false,UI.MUTED))
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
	_progress_bar.value = step
	_progress_bar.show_percentage = false
	_progress_bar.add_theme_stylebox_override("background",UI.box(Color("d7e6ed"),Color.TRANSPARENT,5,0))
	_progress_bar.add_theme_stylebox_override("fill",UI.box(UI.TEAL,Color.TRANSPARENT,5,0))
	progress.add_child(_progress_bar)
	progress.add_child(UI.inline_label("%d / 7"%step,14,true))
	page.add_child(UI.progress_strip())

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
	# Stage 3 image cards use original high-resolution standalone artwork.
	# NO screenshot crops, NO embedded blue selection lines, NO horizontal scrollbar.
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
		option.custom_minimum_size = Vector2(128, 240)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_theme_stylebox_override("normal", _style(Color.WHITE, OUTLINE, 9))
		option.add_theme_stylebox_override("hover", _style(Color("f9fbfd"), Color("b5c6d9"), 9))
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
		option_col.add_child(pic)

		var caption := _label(labels[i], 14, TEXT, false)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		option_col.add_child(caption)
		option.pressed.connect(_choose.bind(i))

	_answer_area.add_child(_label("Select an image. A correct choice automatically opens the next question." if current_lang == "jp" else "အဖြေမှန်ရွေးလိုက်တာနဲ့ နောက်မေးခွန်းကို အလိုအလျောက် သွားပါမယ်။", 13, SUBTEXT))

func _choose(index: int) -> void:
	var correct_index: int = 2 if step == 0 else 1
	if index == correct_index:
		step += 1
		Progress.save_kitchen_step(step)
		if step == 7: Progress.complete(3)
		last_wrong = false
		_refresh()
	else:
		last_wrong = true
		_feedback.text = "ちょっと違うようです。もう一度選んでください。" if current_lang == "jp" else "မမှန်သေးပါ။ ပြန်ရွေးပါ။"
		_feedback.add_theme_color_override("font_color", Color("c24144"))


func _draw_parts() -> void:
	var needed: int = step - 2
	_answer_area.add_child(_label(LocaleManager.text("Select: %s") % LocaleManager.text(NAMES[needed]), 18, BLUE))
	_answer_area.add_child(_label("Click the corresponding area in the kitchen illustration.", 13, SUBTEXT))
	var diagram := KitchenDiagram.new()
	diagram.custom_minimum_size = Vector2(450, 260)
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.name = "KitchenPartsDiagram"
	diagram.item_selected.connect(_select_part)
	_answer_area.add_child(diagram)


func _select_part(which: int) -> void:
	if which == step - 2:
		step += 1
		Progress.save_kitchen_step(step)
		if step == 7: Progress.complete(3)
		last_wrong = false
		_refresh()
	else:
		last_wrong = true
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
	add_child(popup)

func _save_session() -> void:
	if not _session_save_suspended and Progress.resume_stage()==3: Progress.save_kitchen_step(step)

func _suspend_session_save() -> void:
	_session_save_suspended=true

func _exit_tree() -> void:
	_save_session()


class KitchenDiagram extends Control:
	signal item_selected(which: int)
	var zones: Array[Rect2] = [Rect2(89,181,445,44),Rect2(205,77,323,94),Rect2(100,70,99,68),Rect2(88,260,488,58),Rect2(531,161,58,150)]
	var tip_colors: Array[Color] = [Color("72bbdf"), Color("c2d7e7"), Color("8ba6c5"), Color("d4c4b1"), Color("f3d8ab")]

	func _ready() -> void:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_filter = Control.MOUSE_FILTER_STOP
		resized.connect(queue_redraw)

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
		draw_set_transform(Vector2.ZERO)
		for i in range(zones.size()):
			var point := (zones[i].position+Vector2(15,15))*Vector2(sx,sy)
			draw_circle(point,12,Color("008f98"))
			draw_string(ThemeDB.fallback_font,point+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var point: Vector2 = Vector2(event.position.x * 650.0 / maxf(size.x,1.0), event.position.y * 390.0 / maxf(size.y,1.0))
			# smaller elements first to avoid overlap
			for i in [2, 1, 4, 3, 0]:
				if i < zones.size() and zones[i].has_point(point):
					accept_event()
					item_selected.emit(i)
					return
