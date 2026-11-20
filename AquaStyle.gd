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
	var top := "#00bfff" if primary else "#ffffff"
	var middle := "#009fd6" if primary else "#e1f4ff"
	var bottom := "#006fa8" if primary else "#b1e3fa"
	var height := 160 if card else maxi(38,button_height)
	var edge := "#efbd43" if gold else "#60c7ee"
	var radius := 30 if card else (height-8)/2
	var source := '<svg xmlns="http://www.w3.org/2000/svg" width="320" height="%d"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset=".48" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><rect x="3" y="7" width="314" height="%d" rx="%d" fill="#126e9c" opacity=".22"/><rect x="2" y="2" width="316" height="%d" rx="%d" fill="url(#g)" stroke="%s" stroke-width="2"/><rect x="6" y="5" width="308" height="%d" rx="%d" fill="none" stroke="#ffffff" stroke-width="2" opacity=".92"/></svg>' % [height,top,middle,bottom,height-10,radius,height-10,radius,edge,height-16,radius-3]
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
	# Restore the game's original pre-Aqua button renderer.
	var ui=load("res://KitchenUI.gd")
	var icon_limit:=button.get_theme_constant("icon_max_width")
	ui.style_button(button,primary,button.get_theme_font_size("font_size"))
	button.add_theme_constant_override("icon_max_width",icon_limit)
	if not button.has_meta("classic_alignment"):
		button.set_meta("classic_alignment",true)
		button.resized.connect(_align_classic.bind(button))
	_align_classic(button)

static func _align_classic(button: Button) -> void:
	button.alignment=HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER if button.text.is_empty() else HORIZONTAL_ALIGNMENT_LEFT
	var reserved: float=0.0
	if button.icon!=null and not button.text.is_empty():
		var limit:=button.get_theme_constant("icon_max_width")
		reserved=minf(button.icon.get_width(),limit) if limit>0 else button.icon.get_width()
		reserved+=button.get_theme_constant("h_separation")
	for state in ["normal","hover","pressed","disabled"]:
		var style:=button.get_theme_stylebox(state).duplicate() as StyleBox
		style.content_margin_left=14
		style.content_margin_right=14+reserved
		button.add_theme_stylebox_override(state,style)

static func badge(current: bool, done: bool, locked: bool) -> Texture2D:
	var key := "glass_%s_%s_%s" % [current,done,locked]
	var top := "#cbffff" if current else "#ffffff"
	var middle := "#53dce8" if current else "#f1faff"
	var bottom := "#12b7cd" if current else ("#c7dfeb" if locked else "#d5f2f7")
	var edge := "#55d6e4" if current else "#b6d9e9"
	var source := '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset=".46" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><circle cx="40" cy="43" r="35" fill="#366e95" opacity=".17"/><circle cx="40" cy="38" r="35" fill="url(#g)" stroke="%s" stroke-width="2"/><circle cx="40" cy="38" r="31.5" fill="none" stroke="#ffffff" stroke-width="2"/><ellipse cx="34" cy="19" rx="23" ry="11" fill="#ffffff" opacity=".25"/></svg>' % [top,middle,bottom,edge]
	return _svg(key,source)
