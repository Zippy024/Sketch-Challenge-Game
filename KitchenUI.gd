extends RefCounted
const Progress = preload("res://GameProgress.gd")
const INK := Color("082744")
const MUTED := Color("355c72")
const TEAL := Color("008f98")
const EDGE := Color("c3dce9")
static var _fonts: Dictionary = {}
static var _pill_textures: Dictionary = {}
static var _backdrop_texture: Texture2D

static func text(value: String) -> String:
	var tree := Engine.get_main_loop() as SceneTree
	var manager := tree.root.get_node_or_null("LocaleManager") if tree else null
	return str(manager.call("text",value)) if manager else value

static func font(bold: bool = false) -> FontVariation:
	var lang := Progress.get_language()
	var key := lang + str(bold)
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = preload("res://Font/NotoSansMyanmar-VariableFont_wdth,wght.ttf") if lang == "mm" else preload("res://Font/NotoSansJP-VariableFont_wght.ttf")
		f.fallbacks = [preload("res://Font/NotoSansCJKjp-Regular.otf"),preload("res://Font/NotoSansMyanmar.ttf")]
		f.variation_opentype = {2003265652:700.0 if bold else 450.0}
		f.variation_embolden = 0.1 if bold else 0.0
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

static func header(stage: int, title: String, menu_action: Callable, language_action: Callable) -> PanelContainer:
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
	var badge := PanelContainer.new()
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.add_theme_stylebox_override("panel",box(TEAL,TEAL,15,5))
	row.add_child(badge)
	var stage_label := label("Stage %d" % stage,15,true,Color.WHITE)
	stage_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.add_child(stage_label)
	var heading := label(title,22,true)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.clip_text = true
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	var count := label(text("Stage %d of 3") % stage,12,false,MUTED)
	count.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(count)
	var picker := OptionButton.new()
	picker.name = "Stage1LanguagePicker" if stage == 1 else "GameLanguagePicker"
	for language in ["日本語","မြန်မာ","English"]: picker.add_item(language)
	picker.select({"jp":0,"mm":1,"en":2}[Progress.get_language()])
	picker.fit_to_longest_item = false
	picker.custom_minimum_size = Vector2(105,34)
	picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_button(picker,false,12)
	picker.item_selected.connect(func(index: int): language_action.call(["jp","mm","en"][index]))
	row.add_child(picker)
	var pause := button("Ⅱ",menu_action,false,34,15)
	pause.name = "Stage1PauseButton" if stage == 1 else "GamePauseButton"
	pause.tooltip_text = text("Pause / Level Menu")
	pause.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pause)
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
	row.add_child(inline_label("Your progress",14,true))
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
	plate.add_theme_stylebox_override("panel",box(Color("e8f4ff"),EDGE,8,6))
	identity.add_child(plate)
	var customer_name := label("Ms. Hosokawa",16,true)
	customer_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.add_child(customer_name)
	var talk := VBoxContainer.new()
	talk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk.add_theme_constant_override("separation",10)
	row.add_child(talk)
	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel",box(Color("e5f2fc"),EDGE,8,6))
	talk.add_child(tag)
	tag.add_child(label("Customer Request",16,true))
	var bubble := PanelContainer.new()
	bubble.add_theme_stylebox_override("panel",box(Color("f5faff"),EDGE,14,12))
	bubble.custom_minimum_size.y = 200
	talk.add_child(bubble)
	var dialogue := VBoxContainer.new()
	dialogue.add_theme_constant_override("separation",9)
	bubble.add_child(dialogue)
	var question := label("",15)
	dialogue.add_child(question)
	var voice := HBoxContainer.new()
	voice.add_theme_constant_override("separation",7)
	talk.add_child(voice)
	return {"name":customer_name,"bubble":bubble,"question":question,"dialogue":dialogue,"voice":voice}

static func inline_label(value: String, size: int = 14, bold: bool = false) -> Label:
	var result := label(value,size,bold)
	result.autowrap_mode = TextServer.AUTOWRAP_OFF
	return result

static func icon(kind: String) -> Texture2D:
	var shapes := {
		"play":'<path d="M8 4l13 8L8 20z" fill="currentColor" stroke="none"/>',
		"layers":'<path d="M12 3l10 6-10 6L2 9zM2 13l10 6 10-6M2 17l10 6 10-6"/>',
		"help":'<circle cx="12" cy="12" r="10"/><path d="M9 8a3 3 0 1 1 4 3c-1 1-1 2-1 3M12 17v1"/>',
		"gear":'<path d="M9 2h6l1 3 3 1 3 4-2 3 1 3-4 4-3-1-3 3-4-2v-3l-3-2v-5l3-1 1-3z"/><circle cx="12" cy="12" r="4"/>',
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
