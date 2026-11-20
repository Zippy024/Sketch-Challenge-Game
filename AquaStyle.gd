extends RefCounted
# Shared visual resources only. Progress, navigation and grading stay with their owners.
static var _textures: Dictionary = {}

static func artwork(path: String, fallback: Texture2D) -> Texture2D:
	# The two background paintings can be uploaded separately without breaking a build.
	return load(path) as Texture2D if ResourceLoader.exists(path) else fallback

static func _svg(key: String, source: String) -> Texture2D:
	if not _textures.has(key):
		var image := Image.new()
		image.load_svg_from_buffer(source.to_utf8_buffer())
		_textures[key] = ImageTexture.create_from_image(image)
	return _textures[key]

static func surface(primary: bool = false, card: bool = false, button_height: int = 80, gold: bool = false) -> StyleBoxTexture:
	var key := ("primary" if primary else ("card" if card else "pearl"))+str(button_height)+str(gold)
	var top := "#42f1ef" if primary else "#ffffff"
	var middle := "#00b6c5" if primary else "#edfafd"
	var bottom := "#007f96" if primary else "#bcecf1"
	var height := 160 if card else maxi(38,button_height)
	var edge := "#efbd43" if gold else "#5bc8d4"
	var radius := 30 if card else (height-8)/2
	var source := '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="%d"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset=".48" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><rect x="3" y="7" width="314" height="%d" rx="%d" fill="#157d8c" opacity=".22"/><rect x="2" y="2" width="316" height="%d" rx="%d" fill="url(#g)" stroke="%s" stroke-width="2"/><rect x="6" y="5" width="308" height="%d" rx="%d" fill="none" stroke="#ffffff" stroke-width="2" opacity=".92"/></svg>' % [height,top,middle,bottom,height-10,radius,height-10,radius,edge,height-16,radius-3]
	var style := StyleBoxTexture.new()
	style.texture = _svg(key,source)
	style.texture_margin_left = radius+2
	style.texture_margin_right = radius+2
	style.texture_margin_top = 30 if card else mini(20,height/2-1)
	style.texture_margin_bottom = 30 if card else mini(20,height/2-1)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 7
	return style

static func button(button: Button, primary: bool = false) -> void:
	button.set_meta("uses_primary_gloss",false)
	if not button.has_meta("aqua_resize"):
		button.set_meta("aqua_resize",true)
		button.resized.connect(func():_refresh_button(button,primary))
	_refresh_button(button,primary)

static func _refresh_button(button: Button, primary: bool) -> void:
	button.alignment=HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER if button.text.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	var icon_space: float=0.0
	if button.icon!=null and not button.text.is_empty():
		var limit:=button.get_theme_constant("icon_max_width")
		icon_space=minf(button.icon.get_width(),limit) if limit>0 else button.icon.get_width()
		icon_space+=button.get_theme_constant("h_separation")
	var gold:=button.name in ["GameHomeButton","GameMenuButton","Stage1MenuButton"]
	for state in ["normal","hover","pressed","disabled"]:
		var style := surface(primary,false,roundi(button.size.y),gold)
		style.modulate_color = Color("e6ffff") if state=="hover" else (Color("b5e2e9") if state=="pressed" else (Color("d9e6ec") if state=="disabled" else Color.WHITE))
		# Native Button reserves icon_space on the left of its text layout.
		# Matching space on the right keeps the text at the button's true centre.
		style.content_margin_left=14
		style.content_margin_right=14+icon_space
		style.content_margin_top=0
		style.content_margin_bottom=10
		button.add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color.WHITE if primary else Color("092c56"))

static func badge(current: bool, done: bool, locked: bool) -> Texture2D:
	var key := "medal_%s_%s_%s" % [current,done,locked]
	var top := "#fff9d5" if current else "#ffffff"
	var bottom := "#ffdc63" if current else ("#d6eff4" if locked else "#e5fbfc")
	var edge := "#ebb62d" if current or done else "#62b6cc"
	var source := '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><circle cx="40" cy="43" r="35" fill="#21697d" opacity=".15"/><circle cx="40" cy="39" r="35" fill="url(#g)" stroke="%s" stroke-width="2.5"/><circle cx="40" cy="39" r="31.5" fill="none" stroke="#ffffff" stroke-width="2"/></svg>' % [top,bottom,edge]
	return _svg(key,source)
