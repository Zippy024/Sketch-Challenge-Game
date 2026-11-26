extends RefCounted
const UI=preload("res://KitchenUI.gd")
const INK=Color("09244d")
const CYAN=Color("00c9f2")
static var _surfaces: Dictionary={}

static func vector(source: String) -> Texture2D:
	var texture=DPITexture.create_from_string(source,2.0)
	texture.set_size_override(Vector2i(texture.get_size()/2.0))
	return texture

static func face(kind: String="panel",state: String="normal") -> StyleBoxTexture:
	var key=kind+state
	if not _surfaces.has(key):
		var top="#ffffff";var bottom="#def4ff";var edge="#91d5ee";var radius=18
		if kind=="primary":top="#00def2";bottom="#0087ff";edge="#bdffff";radius=22
		elif kind=="header":top="#6be8ff";bottom="#00afe7";edge="#edffff";radius=22
		elif kind=="panel":top="#f0fcff";bottom="#bdefff";edge="#f6ffff"
		elif kind=="speech":top="#f7fdff";bottom="#d9f5ff";edge="#78d9f4";radius=16
		elif kind=="navy":top="#36567e";bottom="#102f58";edge="#718eaf";radius=10
		var source='<svg xmlns="http://www.w3.org/2000/svg" width="320" height="160"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><rect x="2" y="7" width="316" height="151" rx="%d" fill="#166894" opacity=".26"/><rect x="1" y="2" width="318" height="151" rx="%d" fill="url(#g)" stroke="%s" stroke-width="1.4"/><rect x="3.5" y="4.5" width="313" height="145" rx="%d" fill="none" stroke="#ffffff" stroke-opacity=".82" stroke-width="1.2"/></svg>'%[top,bottom,radius,radius,edge,maxi(2,radius-2)]
		_surfaces[key]=vector(source)
		if kind in ["button","primary"]:
			var pill='<svg xmlns="http://www.w3.org/2000/svg" width="320" height="48"><defs><linearGradient id="p" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><rect x="1" y="6" width="318" height="41" rx="20" fill="#237da8" opacity=".24"/><rect x="1" y="1" width="318" height="40" rx="20" fill="url(#p)" stroke="%s" stroke-width="1.2"/><rect x="3" y="3" width="314" height="35" rx="17" fill="none" stroke="#ffffff" stroke-opacity=".8" stroke-width="1"/></svg>'%[top,bottom,edge]
			_surfaces[key]=vector(pill)
	var style=StyleBoxTexture.new();style.texture=_surfaces[key]
	style.texture_margin_left=24;style.texture_margin_right=24;style.texture_margin_top=24;style.texture_margin_bottom=26
	style.set_content_margin_all(12 if kind=="panel" else 7)
	style.content_margin_bottom+=3
	if kind in ["button","primary"]:
		style.texture_margin_left=16;style.texture_margin_right=16;style.texture_margin_top=12;style.texture_margin_bottom=14
		style.content_margin_left=9;style.content_margin_right=9;style.content_margin_top=2;style.content_margin_bottom=7
	if state=="hover":style.modulate_color=Color("e8faff")
	elif state=="pressed":style.modulate_color=Color("c6e9fa")
	elif state=="disabled":style.modulate_color=Color("dce8ef")
	return style

static func panel(parent: Node,node_name: String,kind: String="panel",padding: int=12) -> VBoxContainer:
	var card=PanelContainer.new();card.name=node_name;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var style=face(kind);style.set_content_margin_all(padding);style.content_margin_bottom+=3
	card.add_theme_stylebox_override("panel",style);parent.add_child(card)
	var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",10);card.add_child(stack)
	return stack

static func label(value: String,size: int=18,bold: bool=true) -> Label:
	var result=UI.label(value,size,bold,INK);result.text=value;result.set_meta("locale_ignore",true)
	return result

static func button(value: String,action: Callable=Callable(),primary: bool=false,width: int=0,height: int=38,font_size: int=14) -> Button:
	var result=Button.new();result.text=value;result.name=value.to_pascal_case();result.set_meta("locale_ignore",true)
	result.custom_minimum_size=Vector2(width,height);result.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font",UI.font(true));result.add_theme_font_size_override("font_size",font_size)
	for state in ["normal","hover","pressed","disabled"]:
		result.add_theme_stylebox_override(state,face("primary" if primary else "button",state))
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		result.add_theme_color_override(state,Color.WHITE if primary else INK)
	result.add_theme_color_override("font_disabled_color",Color("7897b0"))
	result.add_theme_constant_override("h_separation",6);result.add_theme_constant_override("icon_max_width",18)
	var focus=UI.box(Color.TRANSPARENT,CYAN,18,0);focus.set_border_width_all(2);focus.shadow_size=0
	result.add_theme_stylebox_override("focus",focus)
	result.set_meta("studio_primary",primary)
	result.resized.connect(fit_button.bind(result))
	if action.is_valid():result.pressed.connect(action)
	return result

static func fit_button(button: Button) -> void:
	var width=maxi(24,roundi(button.size.x));var height=maxi(24,roundi(button.size.y));var primary=bool(button.get_meta("studio_primary",false))
	var radius=(height-7)*.5
	var top="#00def2" if primary else "#ffffff";var bottom="#0087ff" if primary else "#def4ff"
	var svg='<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><rect x="1" y="5" width="%d" height="%d" rx="%s" fill="#297ca5" opacity=".24"/><rect x="1" y="1" width="%d" height="%d" rx="%s" fill="url(#g)" stroke="#91d5ee" stroke-width="1"/><rect x="3" y="3" width="%d" height="%d" rx="%s" fill="none" stroke="#ffffff" stroke-opacity=".8" stroke-width="1"/></svg>'%[width,height,top,bottom,width-2,height-7,str(radius),width-2,height-7,str(radius),width-6,height-11,str(maxf(1,radius-2))]
	var texture=vector(svg)
	for state in ["normal","hover","pressed","disabled"]:
		var style=StyleBoxTexture.new();style.texture=texture
		style.content_margin_left=9;style.content_margin_right=9;style.content_margin_top=2;style.content_margin_bottom=7
		if state=="hover":style.modulate_color=Color("e8faff")
		elif state=="pressed":style.modulate_color=Color("c6e9fa")
		elif state=="disabled":style.modulate_color=Color("dce8ef")
		button.add_theme_stylebox_override(state,style)

static func icon(button: Button,kind: String) -> void:
	button.icon=UI.icon(kind)
	for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]:button.add_theme_color_override(state,INK)

static func card(button: Button,selected: bool=false) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		var style=UI.box(Color.WHITE,CYAN if selected or state in ["hover","pressed"] else Color("bad9e6"),12,0)
		style.set_border_width_all(3 if selected else 1);style.shadow_size=3;style.shadow_offset=Vector2(0,2)
		button.add_theme_stylebox_override(state,style)
	var focus=UI.box(Color.TRANSPARENT,CYAN,12,0);focus.set_border_width_all(3);focus.shadow_size=0
	button.add_theme_stylebox_override("focus",focus)

static func ignore_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:child.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ignore_children(child)
