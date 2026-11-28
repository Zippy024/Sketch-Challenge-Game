extends RefCounted
# Scoped aqua navigation surfaces. All text remains native and accessible.
const UI=preload("res://KitchenUI.gd")
static var _cache: Dictionary={}
static func texture(kind: String,w: int,h: int) -> Texture2D:
	w=maxi(w,24);h=maxi(h,24)
	var key="%s/%d/%d"%[kind,w,h]
	if _cache.has(key):return _cache[key]
	var top="#f3fcff";var bottom="#c1e8fb";var edge="#69c9ed"
	if kind=="blue":top="#14b3ff";bottom="#006ad3";edge="#00baff"
	elif kind=="heading":top="#1dccfa";bottom="#0074da";edge="#00baff"
	elif kind=="green":top="#42f382";bottom="#00b94f";edge="#19c76a"
	elif kind=="done":top="#e5ffd4";bottom="#88dc60";edge="#64ca38"
	elif kind=="locked":top="#c8e2f1";bottom="#84adca";edge="#95bfd9"
	elif kind=="card":top="#f4fcff";bottom="#def4ff"
	elif kind=="photo":top="#fafcff";bottom="#edf7ff";edge="#badcf0"
	elif kind=="title":top="#e4f5ff";bottom="#acd9fa";edge="#d8f2ff"
	var round=kind in ["blue","green","done","locked","button","heading","title","bar"]
	var radius=(h-8)*.5 if round else minf(26,(h-8)*.5)
	var middle="#008ced" if kind=="blue" else ("#09d05b" if kind=="green" else top)
	var defs='<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset=".48" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient><linearGradient id="s" x2="0" y2="1"><stop stop-color="#fff" stop-opacity=".6"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>'%[top,middle,bottom]
	var body='<rect x="3" y="6" width="%d" height="%d" rx="%s" fill="#1c7eb6" opacity=".23"/><rect x="2" y="2" width="%d" height="%d" rx="%s" fill="url(#g)" stroke="%s" stroke-width="1.4"/><rect x="4" y="4" width="%d" height="%d" rx="%s" fill="none" stroke="#fff" stroke-width="1.3" opacity=".95"/>'%[w-6,h-9,str(radius),w-4,h-7,str(radius),edge,w-8,h-11,str(maxf(3,radius-2))]
	if round:
		body+='<rect x="6" y="4" width="%d" height="%s" rx="%s" fill="url(#s)" opacity=".45"/>'%[w-12,str(maxf(6,h*.43)),str(maxf(3,radius-4))]
	if kind in ["outer","bar"]:
		body+='<path d="M5 65Q38 50 58 5H106Q76 47 5 93Z" fill="#79ddf4" opacity=".45"/><path d="M%d %dQ%d %d %d %dH%dZ" fill="#59d3ee" opacity=".24"/>'%[w-5,h-74,w-47,h-55,w-73,h-6,w-123]
	if _cache.size()>120:_cache.clear()
	var result=UI.Gloss.vector('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">'%[w,h]+defs+body+'</svg>')
	_cache[key]=result;return result
static func skin(kind: String,w: int,h: int) -> StyleBoxTexture:
	var s=StyleBoxTexture.new();s.texture=texture(kind,w,h);s.set_content_margin_all(6 if kind=="photo" else 0);return s
static func symbol(kind: String) -> Texture2D:
	var body=''
	if kind=="crown":body='<path d="M3 9L9 14L16 3L23 14L29 9L25 25H7Z" fill="#ffdb38" stroke="#ed9a00" stroke-width="1.5" stroke-linejoin="round"/><path d="M9 23H23" stroke="#fff6a4" stroke-width="2"/>'
	elif kind=="check":body='<circle cx="16" cy="16" r="14" fill="#51cc23" stroke="#eaffc8" stroke-width="2"/><path d="M9 16L14 21L23 11" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>'
	elif kind=="play":body='<circle cx="16" cy="16" r="14" fill="#008de6" stroke="#b5faff" stroke-width="2"/><path d="M12 8L24 16L12 24Z" fill="white"/>'
	elif kind=="layers":body='<path d="M3 10L16 3L29 10L16 17Z M3 17L16 24L29 17 M3 23L16 30L29 23" fill="none" stroke="white" stroke-width="3" stroke-linejoin="round"/>'
	else:body='<path d="M6 5L10 12M18 2L16 11M28 8L22 15" stroke="#ffcf20" stroke-width="3" stroke-linecap="round"/>'
	return UI.Gloss.vector('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">'+body+'</svg>')
static func style_button(b: Button,kind: String) -> void:
	UI.Gloss.disable_button(b)
	for state in ["normal","hover","pressed","disabled"]:
		var s=skin("locked" if state=="disabled" else kind,roundi(b.size.x),roundi(b.size.y))
		if state=="hover":s.modulate_color=Color(1.04,1.04,1.04)
		elif state=="pressed":s.modulate_color=Color(.88,.94,.99)
		b.add_theme_stylebox_override(state,s)
	var focus=UI.box(Color.TRANSPARENT,Color("0076d8"),30,0);focus.set_border_width_all(2);focus.shadow_size=0;b.add_theme_stylebox_override("focus",focus)

static func center_content(b: Button,icon: Texture2D,color: Color) -> void:
	# Keep the native button text for accessibility; draw its icon/text as one group.
	var row=b.get_node_or_null("CenteredButtonContent") as HBoxContainer
	if row==null:
		row=HBoxContainer.new();row.name="CenteredButtonContent";row.alignment=BoxContainer.ALIGNMENT_CENTER;row.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_theme_constant_override("separation",8);b.add_child(row);row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var image=TextureRect.new();image.name="ActionIcon";image.custom_minimum_size=Vector2(18,18);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.size_flags_vertical=Control.SIZE_SHRINK_CENTER;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(image)
		var new_label=UI.inline_label("",b.get_theme_font_size("font_size"),true);new_label.name="ActionCaption";new_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(new_label)
	row.get_node("ActionIcon").texture=icon;row.get_node("ActionIcon").modulate=color
	var label=row.get_node("ActionCaption");label.text=b.text;label.add_theme_color_override("font_color",color)
	b.icon=null
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color","font_outline_color","font_shadow_color"]:b.add_theme_color_override(state,Color.TRANSPARENT)
