extends Control

# Stage 3 only: two image-choice questions followed by five kitchen-part selections.
# The previous stages, AI code, audio assets, and the existing menu visuals are unchanged.
const Progress = preload("res://GameProgress.gd")
const StageCompleteOverlay = preload("res://StageCompleteOverlay.gd")
const UI_THEME: Theme = preload("res://WebBilingualTheme.tres")
const PORTRAIT: Texture2D = preload("res://customer_portrait_ui.png")
const ConsoleAnimations = preload("res://ConceptCAnimations.gd")
const ConsoleAtmosphere = preload("res://ConceptCAtmosphere.gd")
var IMAGES_Q1: Array[Texture2D] = []
var IMAGES_Q2: Array[Texture2D] = []
const BG := Color("101d1c")
const PANEL := Color("192c29")
const TEXT := Color("f4f1e9")
const SUBTEXT := Color("b6c7c1")
const BLUE := Color("87d3ae")
const GREEN := Color("54c894")
const OUTLINE := Color("597469")
const NAMES: Array[String] = ["カウンター", "キッチンボード", "フード", "腰壁", "その他"]
const EN_PARTS: Array[String] = ["Countertop", "Kitchen board", "Range hood", "Half wall", "Other fixtures"]

var current_lang: String = "jp"
var step: int = 0 # 0 = S-Class type, 1 = wall layout, 2..6 = identify five components, 7 = completed
var last_wrong: bool = false
var _left_dialogue: VBoxContainer
var _answer_area: VBoxContainer
var _completion_overlay: Control
var _pause_menu: Control
var _progress_bar: ProgressBar
var _feedback: Label
var _card_texture_cache: Dictionary = {}


func _ready() -> void:
	theme = UI_THEME
	current_lang = Progress.get_language()
	_load_stage3_atlas()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_refresh()
	ConsoleAnimations.animate_screen(self)


func _load_stage3_atlas() -> void:
    # Contains the nine original V22 Panasonic S-Class choice images, without their card borders.
    # Image order: q1_1..q1_5 then q2_1..q2_4.
    var atlas_resource: Texture2D = load("res://Stage3Assets/choices_atlas.webp") as Texture2D
    if atlas_resource == null:
        push_error("Stage 3 kitchen asset atlas is missing")
        return
    var atlas: Image = atlas_resource.get_image()
    if atlas == null:
        push_error("Stage 3 kitchen atlas image could not be decoded")
        return
    for n in range(9):
        var rect := Rect2i((n % 5) * 400, floori(float(n) / 5.0) * 285, 400, 285)
        var picture: Image = atlas.get_region(rect)
        if picture == null:
            continue
        var texture: Texture2D = ImageTexture.create_from_image(picture)
        if n < 5:
            IMAGES_Q1.append(texture)
        else:
            IMAGES_Q2.append(texture)


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
	l.text = t
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_text else TextServer.AUTOWRAP_OFF
	return l


func _btn(t: String, main: bool = false, w: float = 92.0) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(w, 36)
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", Color.WHITE if main else TEXT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _style(Color("187457") if main else Color("263e37"), BLUE if main else OUTLINE))
	b.add_theme_stylebox_override("hover", _style(Color("238e69") if main else Color("31554a"), BLUE))
	b.add_theme_stylebox_override("pressed", _style(Color("125c46") if main else Color("31554a"), BLUE))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	ConsoleAnimations.animate_button(b)
	return b


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
	var background := PanelContainer.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_theme_stylebox_override("panel", _style(BG, BG, 0))
	add_child(background)
	var kitchen_photo := TextureRect.new()
	kitchen_photo.texture = preload("res://MenuAssets/ConceptC_Home_Background.jpg")
	kitchen_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kitchen_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	kitchen_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(kitchen_photo)
	kitchen_photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var photo_dim := ColorRect.new()
	photo_dim.color = Color(0.04, 0.09, 0.08, 0.69)
	photo_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(photo_dim)
	photo_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var atmosphere := ConsoleAtmosphere.new()
	background.add_child(atmosphere)
	var frame := HBoxContainer.new()
	frame.add_theme_constant_override("separation", 14)
	background.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 15
	frame.offset_right = -15
	frame.offset_top = 15
	frame.offset_bottom = -15
	var left := _panel()
	left.custom_minimum_size.x = 450
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 0.38
	frame.add_child(left)
	var left_pad := MarginContainer.new()
	left_pad.add_theme_constant_override("margin_left", 13)
	left_pad.add_theme_constant_override("margin_right", 13)
	left_pad.add_theme_constant_override("margin_top", 12)
	left_pad.add_theme_constant_override("margin_bottom", 12)
	left.add_child(left_pad)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 12)
	left_pad.add_child(contents)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	contents.add_child(header)
	var heading := _label("STAGE 3  /  KITCHEN MATERIALS", 19, TEXT, false)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var jp := _btn("日本語", false, 62)
	var mm := _btn("မြန်မာ", false, 64)
	var levels := _btn("LEVELS", false, 72)
	levels.add_theme_stylebox_override("normal", _style(Color("263e37"), Color("64877b"), 10))
	levels.add_theme_stylebox_override("hover", _style(Color("31554a"), BLUE, 10))
	levels.add_theme_color_override("font_color", TEXT)
	levels.add_theme_color_override("font_hover_color", TEXT)
	for button in [jp, mm, levels]:
		button.custom_minimum_size.y = 36
		header.add_child(button)
	jp.pressed.connect(_change_lang.bind("jp"))
	mm.pressed.connect(_change_lang.bind("mm"))
	levels.pressed.connect(_open_game_menu)
	for pair in [[jp, "jp"], [mm, "mm"]]:
		var button: Button = pair[0]
		if current_lang == pair[1]:
			button.add_theme_stylebox_override("normal", _style(Color("187457"), BLUE))
			button.add_theme_color_override("font_color", Color.WHITE)
	var customer := _panel()
	customer.custom_minimum_size.y = 230
	customer.add_theme_stylebox_override("panel", _style(Color("203934")))
	contents.add_child(customer)
	var customer_row := HBoxContainer.new()
	customer_row.add_theme_constant_override("separation", 12)
	customer.add_child(customer_row)
	var face := TextureRect.new()
	face.texture = PORTRAIT
	face.custom_minimum_size = Vector2(110, 110)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var avatar_shader := Shader.new()
	avatar_shader.code = """
shader_type canvas_item;
uniform vec4 ring_color : source_color = vec4(0.47, 0.70, 1.0, 1.0);
uniform float ring_width = 0.035;
void fragment() {
 vec2 p = UV - vec2(0.5);
 float d = length(p);
 float aa = max(fwidth(d), 0.001);
 float a = 1.0 - smoothstep(0.5-aa,0.5+aa,d);
 vec4 t = texture(TEXTURE,UV);
 float ring = smoothstep(0.5-ring_width-aa,0.5-ring_width+aa,d);
 COLOR = vec4(mix(t.rgb,ring_color.rgb,ring), t.a*a);
}
"""
	var avatar_mat := ShaderMaterial.new()
	avatar_mat.shader = avatar_shader
	face.material = avatar_mat
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	customer_row.add_child(face)
	var talk_card := _panel()
	talk_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk_card.add_theme_stylebox_override("panel", _style(Color("203934")))
	customer_row.add_child(talk_card)
	var talk_pad := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		talk_pad.add_theme_constant_override(side, 12)
	talk_card.add_child(talk_pad)
	_left_dialogue = VBoxContainer.new()
	_left_dialogue.add_theme_constant_override("separation", 9)
	talk_pad.add_child(_left_dialogue)
	_left_dialogue.add_child(_label("細川さん（女性）" if current_lang == "jp" else "ဟိုဆိုကာဝါစံ (Customer)", 16, BLUE))
	_left_dialogue.add_child(_label("CUSTOMER QUESTION", 12, SUBTEXT, false))
	_left_dialogue.add_child(_label(_question_text(), 16))
	var info := _panel()
	info.add_theme_stylebox_override("panel", _style(Color("203934")))
	contents.add_child(info)
	var info_pad := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		info_pad.add_theme_constant_override(side, 13)
	info.add_child(info_pad)
	var info_col := VBoxContainer.new()
	info_col.add_theme_constant_override("separation", 9)
	info_pad.add_child(info_col)
	info_col.add_child(_label("STAGE 3 / PART %s" % ("1" if step < 2 else "2"), 17, BLUE, false))
	info_col.add_child(_label("S-CLASS KITCHEN TRAINING", 14, TEXT, false))
	info_col.add_child(_label("Select the matching kitchen illustration." if step < 2 else "Identify the kitchen components from the diagram.", 13, SUBTEXT))
	var right := _panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 0.62
	frame.add_child(right)
	var right_margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		right_margin.add_theme_constant_override(side, 16)
	right.add_child(right_margin)
	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 11)
	right_margin.add_child(right_col)
	right_col.add_child(_label("Kitchen Selection" if step < 2 else "Kitchen Parts", 23, TEXT, false))
	right_col.add_child(_label(("QUESTION %d / 2" % (step + 1)) if step < 2 else ("PARTS  %d / 5" % (step - 1) if step < 7 else "STAGE 3 COMPLETED"), 12, SUBTEXT, false))
	_answer_area = VBoxContainer.new()
	_answer_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_answer_area.add_theme_constant_override("separation", 12)
	right_col.add_child(_answer_area)
	if step < 2:
		_draw_choices()
	elif step < 7:
		_draw_parts()
	else:
		_draw_completed()
	_feedback = _label("", 15, GREEN, false)
	_feedback.custom_minimum_size.y = 30
	right_col.add_child(_feedback)
	if last_wrong:
		_feedback.text = "ちょっと違うようです。もう一度選んでください。" if current_lang == "jp" else "မမှန်သေးပါ။ ပြန်ရွေးပါ။"
		_feedback.add_theme_color_override("font_color", Color("c24144"))
	var progress_panel := PanelContainer.new()
	progress_panel.add_theme_stylebox_override("panel", _style(Color("203934"), OUTLINE, 13))
	right_col.add_child(progress_panel)
	var progress_box := VBoxContainer.new()
	progress_box.add_theme_constant_override("separation", 8)
	progress_panel.add_child(progress_box)
	var progress_title := HBoxContainer.new()
	progress_box.add_child(progress_title)
	progress_title.add_child(_label("CHALLENGE PROGRESS", 13, SUBTEXT, false))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_title.add_child(spacer)
	progress_title.add_child(_label("%d / 7" % mini(step, 7), 13, GREEN, false))
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size.y = 9
	_progress_bar.min_value = 0
	_progress_bar.max_value = 7
	_progress_bar.value = step
	_progress_bar.show_percentage = false
	_progress_bar.add_theme_stylebox_override("background", _style(Color("101d1c"), Color("101d1c"), 5))
	_progress_bar.add_theme_stylebox_override("fill", _style(GREEN, GREEN, 5))
	progress_box.add_child(_progress_bar)


func _question_text() -> String:
	if step == 0:
		return "現在のキッチンと同じ場所に設置するとすれば、S-classではどのタイプになりますか？" if current_lang == "jp" else "လက်ရှိမီးဖိုချောင်နေရာမှာ S-Class တပ်မယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။"
	if step == 1:
		return "現行のキッチンの後ろの壁も残すとすれば、どうなりますか？" if current_lang == "jp" else "မူလ Kitchen နောက်ဘက်နံရံကို ဆက်ထားမယ်ဆို ဘယ်ပုံစံဖြစ်မလဲ။"
	return "それぞれのパーツの名前を教えてもらえますか？" if current_lang == "jp" else "မီးဖိုချောင်အစိတ်အပိုင်းတွေကို ရွေးပြနိုင်မလား။"


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
	surface.add_theme_stylebox_override("panel", _style(Color("142622"), OUTLINE, 12))
	_answer_area.add_child(surface)

	var cards := GridContainer.new()
	# Desktop: all the choices on one row. Small windows wrap rather than scroll sideways.
	var viewport_width: float = get_viewport_rect().size.x
	cards.columns = labels.size() if viewport_width >= 1320.0 else mini(3, labels.size())
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 11)
	cards.add_theme_constant_override("v_separation", 12)
	surface.add_child(cards)

	for i in range(labels.size()):
		var option := Button.new()
		option.text = ""
		option.custom_minimum_size = Vector2(128, 240)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.add_theme_stylebox_override("normal", _style(Color("263e37"), OUTLINE, 9))
		option.add_theme_stylebox_override("hover", _style(Color("31554a"), BLUE, 9))
		option.add_theme_stylebox_override("pressed", _style(Color("21483b"), BLUE, 9))
		option.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		option.focus_mode = Control.FOCUS_NONE
		option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		cards.add_child(option)
		ConsoleAnimations.animate_button(option)

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
		last_wrong = false
		_refresh()
	else:
		last_wrong = true
		_feedback.text = "ちょっと違うようです。もう一度選んでください。" if current_lang == "jp" else "မမှန်သေးပါ။ ပြန်ရွေးပါ။"
		_feedback.add_theme_color_override("font_color", Color("c24144"))


func _draw_parts() -> void:
	var needed: int = step - 2
	_answer_area.add_child(_label("Select: %s  (%s)" % [NAMES[needed], EN_PARTS[needed]], 18, BLUE))
	_answer_area.add_child(_label("Click the corresponding area in the kitchen illustration.", 13, SUBTEXT))
	var diagram := KitchenDiagram.new()
	diagram.custom_minimum_size = Vector2(560, 355)
	diagram.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diagram.item_selected.connect(_select_part)
	_answer_area.add_child(diagram)
	_answer_area.add_child(_label("Countertop · Kitchen board · Range hood · Half wall · Other fixtures", 13, SUBTEXT))


func _select_part(which: int) -> void:
	if which == step - 2:
		step += 1
		last_wrong = false
		_refresh()
	else:
		last_wrong = true
		_feedback.text = "ちょっと違うようです。もう一度選んでください。" if current_lang == "jp" else "မမှန်သေးပါ။ ပြန်ရွေးပါ။"
		_feedback.add_theme_color_override("font_color", Color("c24144"))


func _draw_completed() -> void:
	# All seven existing selection steps have passed; use a shared celebration
	# without changing their answers, cards or scoring.
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_answer_area.add_child(center)
	var ready := _label("Stage 3 Complete!", 26, GREEN, false)
	ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(ready)
	if not is_instance_valid(_completion_overlay):
		call_deferred("_stage3_show_complete")


func _stage3_show_complete() -> void:
	if not is_inside_tree() or step < 7 or is_instance_valid(_completion_overlay):
		return
	var jp: bool = current_lang == "jp"
	_completion_overlay = StageCompleteOverlay.new()
	_completion_overlay.configure(
		"ステージ3 クリア！" if jp else "Stage 3 Complete!",
		"S-Class の学習が完了しました！" if jp else "S-Class Training ကို အောင်မြင်စွာ ပြီးပါပြီ။",
		"", "レベル一覧" if jp else "Levels", "もう一度" if jp else "Replay", false, true
	)
	add_child(_completion_overlay)
	_completion_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_completion_overlay.levels_requested.connect(_go_levels)
	_completion_overlay.replay_requested.connect(_stage3_complete_replay)


func _stage3_complete_replay() -> void:
	if is_instance_valid(_completion_overlay):
		_completion_overlay.queue_free()
		_completion_overlay = null
	step = 0
	last_wrong = false
	_refresh()


func _change_lang(lang: String) -> void:
	current_lang = lang
	Progress.set_language(lang)
	_refresh()


func _go_levels() -> void:
	Progress.show_levels_on_open = true
	get_tree().change_scene_to_file("res://GameMenu.tscn")


func _open_game_menu() -> void:
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


class KitchenDiagram extends Control:
	signal item_selected(which: int)
	var zones: Array[Rect2] = []
	var tip_colors: Array[Color] = [Color("87d3ae"), Color("d7ab78"), Color("91a6a0"), Color("ccb49c"), Color("e5c79c")]

	func _ready() -> void:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		# A deliberately simple schematic, not a substituted 3D model asset.
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color("10211e"), true)
		var sx: float = w / 650.0
		var sy: float = h / 390.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sx,sy))
		draw_rect(Rect2(0,0,650,390),Color("172b27"))
		draw_rect(Rect2(0,307,650,83),Color("514b42"))
		# rear wall section
		draw_rect(Rect2(83,62,480,246),Color("3a4a43"))
		draw_rect(Rect2(83,62,480,246),Color("718b80"),false,2)
		# upper kitchen board
		draw_rect(Rect2(205,83,316,78),Color("5b786c"))
		for x in [280,357,435]:
			draw_line(Vector2(x,83),Vector2(x,161),Color("324a41"),2)
		# hood above hob
		draw_rect(Rect2(105,76,85,43),Color("ab8263"))
		draw_rect(Rect2(127,119,41,9),Color("705740"))
		# tall side fixture
		draw_rect(Rect2(532,171,45,134),Color("8a7e67"))
		# half wall in front
		draw_rect(Rect2(90,270,480,42),Color("7b705f"))
		# lower base cabinet
		draw_rect(Rect2(104,205,432,95),Color("587366"))
		for x in [204,303,403]:
			draw_line(Vector2(x,205),Vector2(x,300),Color("344e44"),2)
		# countertop slab
		draw_colored_polygon(PackedVector2Array([Vector2(93,194),Vector2(508,194),Vector2(536,215),Vector2(104,215)]),Color("c9c6b7"))
		draw_line(Vector2(93,194),Vector2(508,194),Color("87d3ae"),3)
		# sink and faucet
		draw_rect(Rect2(325,196,80,17),Color("a2a9a1"))
		draw_arc(Vector2(362,190),18,PI,TAU,20,Color("d7ab78"),3)
		# cooktop
		for center in [Vector2(156,208),Vector2(186,208)]:
			draw_arc(center,9,0,TAU,20,Color("a2b7aa"),2)
		# clickable outlines identify the five conceptual elements.
		zones = [Rect2(89,181,445,44),Rect2(205,77,323,94),Rect2(100,70,99,68),Rect2(88,260,488,58),Rect2(531,161,58,150)]
		for r in zones:
			draw_rect(r,Color(0.58, 0.66, 0.75, 0.25),false,1)
		draw_set_transform(Vector2.ZERO)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var point: Vector2 = Vector2(event.position.x * 650.0 / maxf(size.x,1.0), event.position.y * 390.0 / maxf(size.y,1.0))
			# smaller elements first to avoid overlap
			for i in [2, 1, 4, 3, 0]:
				if zones[i].has_point(point):
					item_selected.emit(i)
					accept_event()
					return