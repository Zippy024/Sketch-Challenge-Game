extends RefCounted
const UI=preload("res://KitchenUI.gd")
const INK=UI.INK
const CYAN=UI.TEAL

static func label(value: String,size: int=18,bold: bool=true) -> Label:
	var result=UI.label(value,size,bold,INK);result.text=value;result.set_meta("locale_ignore",true)
	return result

static func button(value: String,action: Callable=Callable(),primary: bool=false,width: int=0,height: int=38,font_size: int=14) -> Button:
	var result=UI.button(value,action,primary,width,font_size)
	result.name="StudioButton" if value.is_empty() else value.to_pascal_case()
	result.set_meta("locale_ignore",true)
	result.custom_minimum_size.y=height
	return result

static func icon(button: Button,kind: String) -> void:
	button.icon=UI.icon(kind)
	for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]:button.add_theme_color_override(state,INK)

static func card(button: Button,selected: bool=false) -> void:
	for state in ["normal","hover","pressed","disabled"]:
		var style=UI.box(Color.WHITE,CYAN if selected or state in ["hover","pressed"] else Color("bad9e6"),16,0)
		style.set_border_width_all(2 if selected else 1);style.shadow_size=2;style.shadow_offset=Vector2(0,1)
		button.add_theme_stylebox_override(state,style)
	var focus=UI.box(Color.TRANSPARENT,CYAN,16,0);focus.set_border_width_all(2);focus.shadow_size=0
	button.add_theme_stylebox_override("focus",focus)

static func ignore_children(node: Node) -> void:
	for child in node.get_children():
		if child is Control:child.mouse_filter=Control.MOUSE_FILTER_IGNORE
		ignore_children(child)
