extends RefCounted
const Progress = preload("res://GameProgress.gd")
const INK := Color("082744")
const MUTED := Color("284f68")
const TEAL := Color("008f98")
const EDGE := Color("c3dce9")
const SUCCESS := Color("2da36b")
const FAILURE := Color("cd4c5e")
const FEEDBACK_TINT := 0.055
static var _fonts: Dictionary = {}
static var _font_files: Dictionary = {}
static var _pill_textures: Dictionary = {}
static var _backdrop_texture: Texture2D

static func text(value: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var manager := tree.root.get_node_or_null("LocaleManager") if tree else null
	return str(manager.call("text",value)) if manager else value

static func _font_file(path: String) -> FontFile:
	if not _font_files.has(path):
		var file := load(path).duplicate() as FontFile
		file.oversampling=2.0
		_font_files[path]=file
	return _font_files[path]

static func font(bold: bool = false) -> FontVariation:
	var lang := Progress.get_language()
	var key := lang + str(bold)
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = _font_file("res://Font/NotoSansMyanmar-VariableFont_wdth,wght.ttf") if lang == "mm" else _font_file("res://Font/NotoSansJP-VariableFont_wght.ttf")
		f.fallbacks = [_font_file("res://Font/NotoSansCJKjp-Regular.otf"),_font_file("res://Font/NotoSansMyanmar.ttf")]
		f.variation_opentype = {2003265652:700.0 if bold else 500.0}
		f.variation_embolden = 0.0
		_fonts[key] = f
	return _fonts[key]

static func make_theme() -> Theme:
	var result := preload("res://WebBilingualTheme.tres").duplicate() as Theme
	result.default_font = font()
	result.default_font_size = 15
	return result

static func box(fill: Color = Color(0.94,0.98,1.0,0.82), edge: Color = Color(1,1,1,0.9), radius: int = 20, pad: int = 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(pad)
	s.shadow_color = Color(0.06,0.24,0.32,0.10)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0,3)
	return s

static func label(value: String, size: int = 16, bold: bool = false, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text(value)
	l.add_theme_font_override("font",font(bold))
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func style_button(b: Button, primary: bool = false, size: int = 14, warning: bool = false) -> void:
	b.add_theme_font_override("font",font(primary))
	b.add_theme_font_size_override("font_size",size)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","disabled"]:
		var fill := TEAL if primary else (Color("fff0f1") if warning else Color("f3faff"))
		if state == "hover": fill = fill.darkened(0.05)
		if state == "pressed": fill = fill.darkened(0.11)
		if state == "disabled": fill = Color("dce8ed")
		var style := box(fill,Color("65c9d1") if primary else EDGE,1000,4)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.shadow_size = 2 if primary else 0
		b.add_theme_stylebox_override(state,style)
	b.set_meta("uses_primary_gloss",primary)
	if primary:
		_refresh_primary(b)
		if not b.has_meta("primary_resize_connected"):
			b.set_meta("primary_resize_connected",true)
			b.resized.connect(_refresh_primary.bind(b))
	var focus := box(Color.TRANSPARENT,TEAL,1000,0)
	focus.set_border_width_all(2)
	focus.shadow_size = 0
	b.add_theme_stylebox_override("focus",focus)
	var ink := Color.WHITE if primary else (Color("b32741") if warning else INK)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: b.add_theme_color_override(state,ink)
	b.add_theme_color_override("font_disabled_color",MUTED)
	b.add_theme_constant_override("icon_max_width",20)
	b.add_theme_constant_override("h_separation",8)

static func button(value: String, action: Callable, primary: bool = false, width: int = 110, size: int = 14) -> Button:
	var b := Button.new()
	b.text = text(value)
	b.custom_minimum_size = Vector2(width,38)
	style_button(b,primary,size)
	if action.is_valid(): b.pressed.connect(action)
	return b

static func _backdrop() -> Texture2D:
	if _backdrop_texture != null: return _backdrop_texture
	# The photograph is static. Blur it once, then reuse the rendered texture
	# across pages instead of running 25 texture samples per pixel every frame.
	var viewport := SubViewport.new()
	viewport.name = "CachedKitchenBackdrop"
	viewport.size = Vector2i(960,540)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var photo := TextureRect.new()
	photo.texture = preload("res://UIAssets/ConceptKitchen.webp")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.size = Vector2(960,540)
	var material := ShaderMaterial.new()
	material.shader = preload("res://UIAssets/kitchen-soft.gdshader")
	photo.material = material
	viewport.add_child(photo)
	var tree := Engine.get_main_loop() as SceneTree
	var manager := tree.root.get_node_or_null("LocaleManager")
	if manager: manager.add_child(viewport)
	else: tree.root.call_deferred("add_child",viewport)
	_backdrop_texture = viewport.get_texture()
	return _backdrop_texture

static func background(parent: Control) -> void:
	parent.theme = make_theme()
	var photo := TextureRect.new()
	photo.name = "KitchenBackdrop"
	photo.texture = _backdrop()
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash := ColorRect.new()
	wash.color = Color(0.90,0.98,1.0,0.06)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wash)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func logo(width: int = 150, height: int = 54) -> TextureRect:
	var mark := TextureRect.new()
	mark.texture = preload("res://LoadingAssets/KitchenLogo.webp")
	mark.custom_minimum_size = Vector2(width,height)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return mark

static func header(stage: int, _title: String, menu_action: Callable, language_action: Callable) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "Stage1Header" if stage == 1 else "GameHeader"
	panel.custom_minimum_size.y = 58
	var style := box(Color(0.95,0.99,1,0.14),Color(1,1,1,0.28),0,4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel",style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	panel.add_child(row)
	var mark := logo(144,44)
	mark.name = "Stage1Logo" if stage == 1 else "GameLogo"
	row.add_child(mark)
	var reach := level_reach(stage,true)
	reach.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	reach.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	row.add_child(reach)
	var picker := language_switcher(language_action)
	picker.name = "Stage1LanguagePicker" if stage==1 else "GameLanguagePicker"
	picker.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	row.add_child(picker)
	var home := button("",func(): go_home(menu_action.get_object()),false,38,14)
	home.name = "GameHomeButton"
	home.icon = icon("home")
	home.tooltip_text = text("Go to Main Menu")
	home.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state in ["icon_normal_color","icon_hover_color","icon_pressed_color"]:home.add_theme_color_override(state,TEAL)
	row.add_child(home)
	var menu := button("",menu_action,false,34,15)
	menu.icon = preload("res://Stage1Assets/menu-lines.svg")
	menu.add_theme_color_override("icon_normal_color",INK)
	menu.add_theme_color_override("icon_hover_color",TEAL)
	menu.add_theme_color_override("icon_pressed_color",INK)
	menu.tooltip_text = text("Menu")
	menu.name = "Stage1MenuButton" if stage == 1 else "GameMenuButton"
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(menu)
	return panel

static func bullet_text(value: String) -> String:
	var lines:=PackedStringArray()
	for source in value.split("\n"):
		var line:=source.strip_edges()
		if not line.is_empty():lines.append(line if line.begins_with("• ") else "• "+line)
	return "\n".join(lines)

static func level_reach(stage: int, in_header: bool=false) -> MarginContainer:
	var margin:=MarginContainer.new()
	margin.name="LevelReachBar"
	for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,0 if in_header else 18)
	margin.add_theme_constant_override("margin_top",0 if in_header else 4)
	margin.add_theme_constant_override("margin_bottom",0 if in_header else 4)
	var track=load("res://LevelReach.gd").new()
	track.current_stage=stage
	track.in_header=in_header
	margin.add_child(track)
	return margin

static func page(parent: Control, stage: int, title: String, menu_action: Callable, language_action: Callable) -> VBoxContainer:
	background(parent)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	parent.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(header(stage,title,menu_action,language_action))
	var margin := MarginContainer.new()
	for side in ["left","right","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	margin.add_child(content)
	return content

static func progress_strip(compact: bool = false) -> PanelContainer:
	var strip := PanelContainer.new()
	strip.name = "OverallProgressStrip"
	strip.add_theme_stylebox_override("panel",box(Color(0.96,0.99,1,0.85),Color.WHITE,18,8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",10)
	strip.add_child(row)
	row.add_child(ribbon("Your progress",13))
	for n in range(1,4):
		var segment := PanelContainer.new()
		segment.name = "MissionSegment%d" % n
		segment.custom_minimum_size = Vector2(65,12)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(segment)
	var caption := label("",13)
	caption.name = "OverallProgressCaption"
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(caption)
	caption.visible = not compact
	update_progress(strip)
	return strip

static func update_progress(strip: Control) -> void:
	for n in range(1,4):
		var segment := strip.find_child("MissionSegment%d" % n,true,false) as PanelContainer
		segment.add_theme_stylebox_override("panel",box(TEAL if Progress.is_completed(n) else Color("c1d3dc"),Color.TRANSPARENT,6,0))
	strip.find_child("OverallProgressCaption",true,false).text = text("%d of 3 missions complete") % Progress.completed_count()

static func portrait() -> TextureRect:
	var face := TextureRect.new()
	face.texture = preload("res://customer_portrait_ui.png")
	face.custom_minimum_size = Vector2(168,168)
	face.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://UIAssets/avatar.gdshader")
	face.material = mat
	return face

static func card_stack(parent: Control, expand: bool = false) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if expand: panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",box())
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	panel.add_child(stack)
	return stack

static func customer(parent: Control) -> Dictionary:
	var stack := card_stack(parent)
	stack.get_parent().name = "CustomerCard"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",12)
	stack.add_child(row)
	var identity := VBoxContainer.new()
	identity.custom_minimum_size.x = 178
	identity.add_theme_constant_override("separation",10)
	row.add_child(identity)
	identity.add_child(portrait())
	var plate := PanelContainer.new()
	plate.name="CustomerNamePlate"
	plate.add_theme_stylebox_override("panel",customer_plate())
	identity.add_child(plate)
	var customer_name := label("Ms. Hosokawa",15,true)
	customer_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(customer_name)
	var talk := VBoxContainer.new()
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk.add_theme_constant_override("separation",10)
	row.add_child(talk)
	var tag := PanelContainer.new()
	tag.name="CustomerRequestHeader"
	tag.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tag.add_theme_stylebox_override("panel",customer_plate())
	talk.add_child(tag)
	var header_row:=HBoxContainer.new()
	header_row.add_theme_constant_override("separation",7)
	tag.add_child(header_row)
	var request_title:=label("Customer Request",15,true)
	request_title.autowrap_mode=TextServer.AUTOWRAP_OFF
	header_row.add_child(request_title)
	var header_spacer:=Control.new()
	header_spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header_row.add_child(header_spacer)
	var bubble := PanelContainer.new()
	bubble.name="CustomerConversation"
	bubble.add_theme_stylebox_override("panel",conversation_style())
	bubble.custom_minimum_size.y = 200
	talk.add_child(bubble)
	var dialogue := VBoxContainer.new()
	dialogue.add_theme_constant_override("separation",9)
	bubble.add_child(dialogue)
	add_customer_feedback(bubble,header_row)
	var question := label("",14)
	question.set_meta("locale_ignore",true)
	dialogue.add_child(question)
	var voice := HBoxContainer.new()
	voice.add_theme_constant_override("separation",7)
	talk.add_child(voice)
	return {"name":customer_name,"bubble":bubble,"question":question,"dialogue":dialogue,"voice":voice}

static func customer_plate() -> StyleBoxTexture:
	var style:=StyleBoxTexture.new()
	style.texture=preload("res://UIAssets/customer-plate.svg")
	style.texture_margin_left=14
	style.texture_margin_right=14
	style.texture_margin_top=14
	style.texture_margin_bottom=14
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=9
	style.content_margin_bottom=11
	return style

static func conversation_style(state: String="neutral") -> StyleBoxFlat:
	var accent:=SUCCESS if state=="correct" else FAILURE
	var fill:=Color("f5faff")
	var edge:=EDGE
	if state!="neutral":
		fill=fill.lerp(accent,FEEDBACK_TINT)
		edge=edge.lerp(accent,0.22)
	var style:=box(fill,edge,18,12)
	style.shadow_size=4
	return style

static func add_customer_feedback(bubble: PanelContainer,header_row: HBoxContainer) -> void:
	# Keep the verdict alongside "Customer Request", never inside customer speech.
	var badge:=PanelContainer.new()
	badge.name="CustomerAnswerBadge"
	badge.size_flags_horizontal=Control.SIZE_SHRINK_END
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	header_row.add_child(badge)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",7)
	badge.add_child(row)
	var mark:=TextureRect.new()
	mark.name="AnswerVerdictIcon"
	mark.custom_minimum_size=Vector2(18,18)
	mark.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(mark)
	var caption:=inline_label("",14,true)
	caption.name="CustomerAnswerLabel"
	caption.add_theme_color_override("font_color",Color.WHITE)
	row.add_child(caption)
	badge.hide()
	bubble.set_meta("answer_state","neutral")
	bubble.set_meta("tint_strength",0.0)

static func set_customer_feedback(bubble: PanelContainer,state: String,animate: bool=true) -> void:
	if not is_instance_valid(bubble):return
	var badge:=bubble.find_child("CustomerAnswerBadge",true,false) as PanelContainer
	if badge==null:return
	var changed: bool=str(bubble.get_meta("answer_state","neutral"))!=state
	bubble.set_meta("answer_state",state)
	bubble.set_meta("tint_strength",0.0 if state=="neutral" else FEEDBACK_TINT)
	var previous:=bubble.get_theme_stylebox("panel") as StyleBoxFlat
	var surface:=conversation_style(state)
	var target:=surface.bg_color
	if changed and animate and previous:surface.bg_color=previous.bg_color
	bubble.add_theme_stylebox_override("panel",surface)
	var old: Variant=bubble.get_meta("feedback_tween") if bubble.has_meta("feedback_tween") else null
	if old is Tween and old.is_valid():old.kill()
	if changed and animate and bubble.is_inside_tree():
		var tween:=bubble.create_tween()
		bubble.set_meta("feedback_tween",tween)
		tween.tween_property(surface,"bg_color",target,0.24).set_trans(Tween.TRANS_SINE)
	badge.visible=state!="neutral"
	if not badge.visible:return
	var accent:=Color("237454") if state=="correct" else Color("a84655")
	var style:=box(Color("e7f6ee") if state=="correct" else Color("fff0f2"),Color("a5d9be") if state=="correct" else Color("e9b7c0"),1000,4)
	style.content_margin_left=9
	style.content_margin_right=9
	style.shadow_size=0
	badge.add_theme_stylebox_override("panel",style)
	var verdict_label:=badge.find_child("CustomerAnswerLabel",true,false) as Label
	verdict_label.text=text("Correct" if state=="correct" else "Incorrect")
	verdict_label.add_theme_color_override("font_color",accent)
	var verdict_icon:=badge.find_child("AnswerVerdictIcon",true,false) as TextureRect
	verdict_icon.texture=icon("check" if state=="correct" else "close")
	verdict_icon.modulate=accent
	if changed and animate:
		badge.scale=Vector2(0.94,0.94)
		badge.modulate.a=0.3
		var pop:=badge.create_tween().set_parallel()
		pop.tween_property(badge,"scale",Vector2.ONE,0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(badge,"modulate:a",1.0,0.18)

static func go_home(owner: Node) -> void:
	if not is_instance_valid(owner):return
	if owner.has_method("_save_session"):owner.call("_save_session")
	if owner.has_method("_stop_voice"):owner.call("_stop_voice")
	Progress.show_home_on_open=true
	Progress.show_levels_on_open=false
	owner.get_tree().paused=false
	owner.get_tree().change_scene_to_file("res://GameMenu.tscn")

static func inline_label(value: String, size: int = 14, bold: bool = false) -> Label:
	var result := label(value,size,bold)
	result.autowrap_mode = TextServer.AUTOWRAP_OFF
	return result

static func icon(kind: String) -> Texture2D:
	var shapes := {
		"chevron_down":'<path d="M6 9l6 6 6-6"/>',
		"globe":'<circle cx="12" cy="12" r="10"/><ellipse cx="12" cy="12" rx="4.5" ry="10"/><path d="M2 12h20M4 6h16M4 18h16"/>',
		"home":'<path d="M2 11L12 3l10 8M5 9v12h5v-7h4v7h5V9"/>',
		"close":'<path d="M6 6l12 12M18 6L6 18"/>',
		"planqa":'<path d="M3 3h14v12H3zM6 6h8v6H6zM8 8h3v2M12 11h9v8h-5l-4 3z"/>',
		"check":'<path d="M4 12l5 5L21 5"/>',
		"play":'<path d="M8 4l13 8L8 20z" fill="currentColor" stroke="none"/>',
		"layers":'<path d="M12 3l10 6-10 6L2 9zM2 13l10 6 10-6M2 17l10 6 10-6"/>',
		"help":'<circle cx="12" cy="12" r="10"/><path d="M9 8a3 3 0 1 1 4 3c-1 1-1 2-1 3M12 17v1"/>',
		"gear":'<path d="M9.5 2h5l.6 3 1.4.8 2.9-1 2.5 4.3-2.3 2v1.8l2.3 2-2.5 4.3-2.9-1-1.4.8-.6 3h-5l-.6-3-1.4-.8-2.9 1L1.6 15l2.3-2v-1.8l-2.3-2 2.5-4.3 2.9 1 1.4-.8z"/><circle cx="12" cy="12" r="3.4"/>',
		"plan":'<path d="M3 3h18v18H3zM7 3v7h6v11M13 10h8M3 15h4"/>',
		"chat":'<path d="M3 3h18v14H9l-6 5zM7 8h1m4 0h1m4 0h1"/>',
		"cube":'<path d="M12 2l10 6v10l-10 6-10-6V8zM2 8l10 6 10-6M12 14v10"/>',
		"undo":'<path d="M9 4L3 10l6 6M3 10h11a6 6 0 0 1 0 12"/>',
		"redo":'<path d="M15 4l6 6-6 6M21 10H10a6 6 0 0 0 0 12"/>',
		"trash":'<path d="M3 6h18M9 6V3h6v3M5 6l1 16h12l1-16M9 10v8M15 10v8"/>',
		"zoom":'<circle cx="10" cy="10" r="7"/><path d="M15 15l7 7M6 10h8M10 6v8"/>',
		"zoomout":'<circle cx="10" cy="10" r="7"/><path d="M15 15l7 7M6 10h8"/>',
		"clock":'<circle cx="12" cy="12" r="10"/><path d="M12 5v7l4 3"/>'
	}
	var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24"><g fill="none" stroke="#ffffff" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+str(shapes.get(kind,shapes["layers"])).replace("currentColor","#ffffff")+'</g></svg>'
	var img := Image.new()
	img.load_svg_from_buffer(svg.to_utf8_buffer())
	return ImageTexture.create_from_image(img)

static func _refresh_primary(button: Button) -> void:
	if not bool(button.get_meta("uses_primary_gloss",false)): return
	var height := maxi(38,roundi(button.size.y))
	if not _pill_textures.has(height):
		var radius := float(height)/2
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="%d"><defs><linearGradient id="a" x2="0" y2="1"><stop stop-color="#39bac0"/><stop offset=".45" stop-color="#00959c"/><stop offset="1" stop-color="#006c77"/></linearGradient></defs><rect x="1" y="1" width="318" height="%d" rx="%s" fill="url(#a)" stroke="#e6ffff" stroke-width="1.5"/></svg>'%[height,height-2,str(radius-1)]
		var img := Image.new()
		img.load_svg_from_buffer(svg.to_utf8_buffer())
		_pill_textures[height] = ImageTexture.create_from_image(img)
	for state in ["normal","hover","pressed"]:
		var box := StyleBoxTexture.new()
		box.texture = _pill_textures[height]
		box.texture_margin_left = float(height)/2+2
		box.texture_margin_right = float(height)/2+2
		box.content_margin_left = 14
		box.content_margin_right = 14
		box.content_margin_top = 4
		box.content_margin_bottom = 4
		box.modulate_color = Color("dfffff") if state=="hover" else (Color("acdce0") if state=="pressed" else Color.WHITE)
		button.add_theme_stylebox_override(state,box)
	var sheen:=button.get_node_or_null("ButtonSheen") as ColorRect
	if sheen==null:
		sheen=ColorRect.new()
		sheen.name="ButtonSheen"
		sheen.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var material:=ShaderMaterial.new()
		material.shader=preload("res://UIAssets/button-sheen.gdshader")
		sheen.material=material
		button.add_child(sheen)
		sheen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	(sheen.material as ShaderMaterial).set_shader_parameter("extent",Vector2(maxf(button.size.x,100),height))

static func ribbon(value: String, size: int = 15) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture=preload("res://UIAssets/ribbon.svg")
	style.texture_margin_left=30
	style.texture_margin_right=30
	style.content_margin_left=23
	style.content_margin_right=23
	style.content_margin_top=2 if size<=13 else 4
	style.content_margin_bottom=2 if size<=13 else 4
	panel.add_theme_stylebox_override("panel",style)
	var caption := label(value,size,true,Color.WHITE)
	caption.autowrap_mode=TextServer.AUTOWRAP_OFF
	caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(caption)
	return panel

static func _language_radio_icon(selected: bool) -> Texture2D:
	var fill:="#008f98" if selected else "#ffffff"
	var svg:='<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20"><circle cx="10" cy="10" r="7" fill="#ffffff" stroke="#72aeb5" stroke-width="1.8"/><circle cx="10" cy="10" r="3.5" fill="'+fill+'"/></svg>'
	var image:=Image.new()
	image.load_svg_from_buffer(svg.to_utf8_buffer())
	return ImageTexture.create_from_image(image)

static func style_language_popup(popup: PopupMenu) -> void:
	# PopupMenu is a Window: it does not inherit the surrounding Control's local theme.
	# Style the popup directly so it stays light in the game and in Settings.
	var panel:=box(Color("f7fcfd"),Color("9fcdd4"),13,8)
	panel.content_margin_left=10
	panel.content_margin_right=10
	panel.content_margin_top=8
	panel.content_margin_bottom=8
	panel.shadow_size=5
	panel.shadow_color=Color(0.02,0.22,0.27,0.16)
	popup.add_theme_stylebox_override("panel",panel)
	var hover:=box(Color("e6f5f6"),Color.TRANSPARENT,9,4)
	hover.set_border_width_all(0)
	hover.shadow_size=0
	popup.add_theme_stylebox_override("hover",hover)
	popup.add_theme_font_override("font",font())
	popup.add_theme_font_size_override("font_size",15)
	popup.add_theme_color_override("font_color",INK)
	popup.add_theme_color_override("font_hover_color",Color("006d76"))
	popup.add_theme_color_override("font_disabled_color",MUTED)
	popup.add_theme_color_override("font_outline_color",Color.TRANSPARENT)
	popup.add_theme_constant_override("v_separation",10)
	popup.add_theme_constant_override("h_separation",9)
	popup.add_theme_constant_override("item_start_padding",6)
	popup.add_theme_constant_override("item_end_padding",6)
	popup.add_theme_icon_override("radio_checked",_language_radio_icon(true))
	popup.add_theme_icon_override("radio_unchecked",_language_radio_icon(false))
	popup.min_size=Vector2i(220,0)

static func language_switcher(action: Callable, size: int = 12) -> HBoxContainer:
	var row := HBoxContainer.new()
	var picker:=MenuButton.new()
	picker.name="LanguageMenu"
	picker.flat=false
	picker.set_meta("locale_ignore",true)
	picker.custom_minimum_size=Vector2(138,36)
	picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	picker.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	picker.icon=icon("globe")
	style_button(picker,false,size)
	for state in ["icon_normal_color","icon_hover_color","icon_pressed_color"]:picker.add_theme_color_override(state,TEAL)
	row.add_child(picker)
	var chevron:=TextureRect.new()
	chevron.name="LanguageChevron"
	chevron.texture=icon("chevron_down")
	chevron.modulate=MUTED
	chevron.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	chevron.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chevron.mouse_filter=Control.MOUSE_FILTER_IGNORE
	picker.add_child(chevron)
	chevron.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	chevron.offset_left=-23
	chevron.offset_right=-11
	chevron.offset_top=-6
	chevron.offset_bottom=6
	var popup:=picker.get_popup()
	popup.set_meta("locale_ignore",true)
	style_language_popup(popup)
	popup.add_radio_check_item("日本語  ·  Japanese",0)
	popup.add_radio_check_item("မြန်မာ  ·  Myanmar",1)
	popup.add_radio_check_item("English",2)
	popup.id_pressed.connect(func(id: int):
		action.call(["jp","mm","en"][id])
		if is_instance_valid(row):update_language_switcher(row,Progress.get_language())
	)
	update_language_switcher(row,Progress.get_language())
	return row

static func update_language_switcher(row: Control, language: String) -> void:
	var picker:=row.find_child("LanguageMenu",true,false) as MenuButton
	if picker==null:return
	picker.text=str({"jp":"日本語","mm":"မြန်မာ","en":"English"}.get(language,"English"))
	picker.tooltip_text=text("Language")
	picker.add_theme_font_override("font",font(true))
	picker.get_popup().add_theme_font_override("font",font())
	for i in range(3):picker.get_popup().set_item_checked(i,["jp","mm","en"][i]==language)
