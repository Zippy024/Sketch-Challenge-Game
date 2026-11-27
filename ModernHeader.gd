extends Control
# The same compact, interactive stage ribbon is used in Stages 1–4.
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
var stage: int=1
var menu_action: Callable
var language_action: Callable # The chosen language is display-only in the game.
var retry_action: Callable
var design: Control
var frame: TextureRect
var _signature: String=""
var _stage_nodes: Array[Control]=[]
var _controls_ready: bool=false
var _fitting: bool=false
var _language_name: Label

static func svg(source: String) -> Texture2D:
	var texture:=DPITexture.create_from_string(source,1.0)
	texture.set_size_override(Vector2i(texture.get_size()))
	return texture

static func _surface(fill: Color,border: Color,radius: int=14) -> StyleBoxFlat:
	var style:=UI.box(fill,border,radius,3)
	style.set_border_width_all(1)
	style.shadow_color=Color(0.02,0.22,0.42,0.14)
	style.shadow_size=3
	style.shadow_offset=Vector2(0,2)
	return style

func _ready() -> void:
	name="Stage1Header" if stage==1 else "GameHeader"
	custom_minimum_size.y=72
	mouse_filter=Control.MOUSE_FILTER_PASS
	design=Control.new()
	design.name="LevelReachBar"
	design.size=Vector2(1070,52)
	design.mouse_filter=Control.MOUSE_FILTER_PASS
	add_child(design)
	frame=TextureRect.new()
	frame.name="StageHeaderFrame"
	frame.texture=UI.Gloss.surface("header",1070,52)
	frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	frame.size=Vector2(1070,52)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	design.add_child(frame)
	resized.connect(_fit)
	_refresh()
	_build_controls()
	_controls_ready=true
	_fit.call_deferred()

func _fit() -> void:
	if design==null or not _controls_ready or _fitting or size.x<280:return
	_fitting=true
	var factor: float=maxf(0.5,(size.x-24.0)/1070.0)
	design.position=Vector2(12,6)
	design.size=Vector2(roundf(1070.0*factor),roundf(52.0*factor))
	frame.size=design.size
	frame.texture=UI.Gloss.surface("header",roundi(frame.size.x),roundi(frame.size.y))
	for child in design.get_children():
		if child==frame or not child is Control:continue
		if not child.has_meta("header_base_rect"):
			child.set_meta("header_base_rect",Rect2(child.position,child.size))
		var rect: Rect2=child.get_meta("header_base_rect")
		child.position=(rect.position*factor).round()
		child.size=(rect.size*factor).round()
		if child.has_meta("stage"):
			var active: bool=bool(child.get_meta("current"))
			var done: bool=bool(child.get_meta("completed"))
			var locked: bool=bool(child.get_meta("locked"))
			child.add_theme_stylebox_override("panel",_node_style(active,done,locked))
			for caption in child.find_children("*","Label",true,false):
				caption.add_theme_font_size_override("font_size",maxi(12,roundi(11*factor)))
			for icon in child.find_children("*","TextureRect",true,false):
				icon.custom_minimum_size=Vector2.ONE*roundf(10*factor)
		elif child is Button:
			child.add_theme_font_size_override("font_size",maxi(12,roundi(12*factor)))
			child.add_theme_constant_override("icon_max_width",roundi(14*factor))
		elif child==_language_name.get_parent():
			_language_name.add_theme_font_size_override("font_size",maxi(12,roundi(12*factor)))
			for icon in child.find_children("*","TextureRect",true,false):
				icon.custom_minimum_size=Vector2(24*factor,17*factor)
	var height=roundf(52.0*factor)+10
	if not is_equal_approx(custom_minimum_size.y,height):custom_minimum_size.y=height
	_fitting=false

func _node_style(active: bool,done: bool,locked: bool) -> StyleBoxFlat:
	var fill:=Color("078df1") if active else (Color("ecfbf6") if done else (Color("d8e7f0") if locked else Color("f4fbff")))
	var edge:=Color("5deafa") if active else (Color("a8ddcb") if done else Color("b9d7e6"))
	var style:=_surface(fill,edge,13)
	if active:
		style.set_border_width_all(2)
		style.shadow_color=Color("0084e6",0.28)
	return style

func _process(_delta: float) -> void:
	var key: String=P.get_language()+str(P.is_completed(1))+str(P.is_completed(2))+str(P.is_completed(3))
	if key!=_signature:
		_refresh()
		_update_language_badge()

func _refresh() -> void:
	if design==null:return
	_signature=P.get_language()+str(P.is_completed(1))+str(P.is_completed(2))+str(P.is_completed(3))
	for control in _stage_nodes:
		if is_instance_valid(control):
			design.remove_child(control)
			control.queue_free()
	_stage_nodes.clear()
	var x:=171.0
	for i in range(1,11):
		var active:=i==stage
		var done:=P.is_completed(i)
		var locked:=not P.is_level_unlocked(i)
		var node:=PanelContainer.new()
		node.name="ReachNode%02d"%i
		node.set_meta("stage",i)
		node.set_meta("completed",done)
		node.set_meta("current",active)
		node.set_meta("locked",locked)
		node.tooltip_text=UI.text("Stage %d")%i+" · "+UI.text("Coming soon" if locked else ("Completed" if done else "Ready"))
		node.position=Vector2(x,12)
		node.size=Vector2(36,28)
		node.mouse_filter=Control.MOUSE_FILTER_STOP
		node.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
		node.add_theme_stylebox_override("panel",_node_style(active,done,locked))
		node.gui_input.connect(_stage_pressed.bind(i))
		design.add_child(node)
		_stage_nodes.append(node)
		var row:=HBoxContainer.new()
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",3)
		node.add_child(row)
		if done or locked or active:
			var icon:=TextureRect.new()
			icon.texture=UI.icon("play" if active else ("check" if done else "lock"))
			icon.modulate=Color.WHITE if active else (Color("21996a") if done else Color("5d7e91"))
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size=Vector2(10,10)
			icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
		var caption:=UI.inline_label("%02d"%i,11,true)
		caption.name="CurrentStageLabel" if active else "ReachStageLabel"
		caption.set_meta("locale_ignore",true)
		caption.add_theme_color_override("font_color",Color.WHITE if active else Color("183e61"))
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(caption)
		if active:
			var pointer:=TextureRect.new()
			pointer.name="ActiveStagePointer"
			pointer.texture=svg('<svg xmlns="http://www.w3.org/2000/svg" width="12" height="7"><path d="M0 0h12L6 7z" fill="#058ee9"/></svg>')
			pointer.position=Vector2(x+12,4)
			pointer.size=Vector2(12,7)
			pointer.mouse_filter=Control.MOUSE_FILTER_IGNORE
			design.add_child(pointer)
			_stage_nodes.append(pointer)
		x+=44
	if _controls_ready:_fit.call_deferred()

func _header_button(name: String,caption: String,kind: String,rect: Rect2,action: Callable) -> Button:
	var button:=Button.new()
	button.name=name
	button.text=UI.text(caption)
	button.icon=UI.icon(kind)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.alignment=HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_override("font",UI.font(true))
	button.add_theme_font_size_override("font_size",12)
	button.add_theme_constant_override("icon_max_width",14)
	button.add_theme_constant_override("h_separation",5)
	for state in ["normal","hover","pressed","disabled"]:
		var fill:=Color("eef9ff") if state=="normal" else (Color("d3f4ff") if state=="hover" else Color("c5e9ff"))
		button.add_theme_stylebox_override(state,_surface(fill,Color("74b4de"),15))
	for state in ["font_color","font_hover_color","font_pressed_color","icon_normal_color","icon_hover_color","icon_pressed_color"]:
		button.add_theme_color_override(state,Color("07518c"))
	button.pressed.connect(action)
	design.add_child(button)
	button.position=rect.position
	button.size=rect.size
	return button

func _flag_texture() -> Texture2D:
	match P.get_language():
		"jp":
			return svg('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="22"><rect width="32" height="22" rx="3" fill="#fff"/><circle cx="16" cy="11" r="7" fill="#bc002d"/></svg>')
		"mm":
			return svg('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="22"><rect width="32" height="7.4" fill="#f9cf30"/><rect y="7.3" width="32" height="7.4" fill="#35a564"/><rect y="14.6" width="32" height="7.4" fill="#e94b49"/><path d="M16 5l1.7 4 4.3.2-3.4 2.7 1 4.1-3.6-2.4-3.6 2.4 1-4.1-3.4-2.7 4.3-.2z" fill="white"/></svg>')
	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="22"><rect width="32" height="22" fill="#16468b"/><path d="M0 0l32 22m0-22L0 22" stroke="white" stroke-width="6"/><path d="M0 0l32 22m0-22L0 22" stroke="#cc223c" stroke-width="2.5"/><path d="M16 0v22M0 11h32" stroke="white" stroke-width="9"/><path d="M16 0v22M0 11h32" stroke="#c92035" stroke-width="5"/></svg>')

func _update_language_badge() -> void:
	if not is_instance_valid(_language_name):return
	_language_name.text={"jp":"Japan","mm":"Myanmar","en":"English"}.get(P.get_language(),"English")
	var icon=_language_name.get_parent().find_child("HeaderLanguageFlag",true,false) as TextureRect
	if icon:icon.texture=_flag_texture()

func _build_controls() -> void:
	var mark=UI.logo(0,0)
	mark.name="Stage1Logo" if stage==1 else "GameLogo"
	design.add_child(mark)
	mark.position=Vector2(11,2)
	mark.size=Vector2(126,45)
	_header_button("HeaderRetryButton","Retry","undo",Rect2(644,10,96,32),func():
		if retry_action.is_valid():retry_action.call()
	)
	_header_button("HeaderStageButton","Stages","layers",Rect2(751,10,102,32),_open_stage_hub)
	var badge:=PanelContainer.new()
	badge.name="HeaderLanguageBadge"
	badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
	badge.position=Vector2(868,10)
	badge.size=Vector2(181,32)
	badge.add_theme_stylebox_override("panel",_surface(Color("f3faff"),Color("8fc9ee"),16))
	design.add_child(badge)
	var row:=HBoxContainer.new()
	row.alignment=BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation",8)
	badge.add_child(row)
	var icon:=TextureRect.new()
	icon.name="HeaderLanguageFlag"
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size=Vector2(26,18)
	icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	_language_name=UI.inline_label("",13,true)
	_language_name.name="HeaderLanguageLabel"
	_language_name.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_language_name.add_theme_color_override("font_color",Color("143b71"))
	row.add_child(_language_name)
	_update_language_badge()

func _stage_pressed(event: InputEvent,number: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		_show_preview(number)
		get_viewport().set_input_as_handled()

func _show_preview(number: int) -> void:
	var scene:=get_tree().current_scene
	if not is_instance_valid(scene) or scene.find_child("StageMiniPreview",true,false)!=null:return
	var popup:=preload("res://StageMiniPreview.gd").new()
	popup.selected_stage=number
	popup.current_stage=stage
	popup.play_requested.connect(_play_preview_stage)
	scene.add_child(popup)
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _play_preview_stage(number: int) -> void:
	if number==stage or not P.is_level_unlocked(number):
		var popup=get_tree().current_scene.find_child("StageMiniPreview",true,false)
		if popup:popup.queue_free()
		return
	var owner=menu_action.get_object()
	if is_instance_valid(owner):
		if owner.has_method("_save_session"):owner.call("_save_session")
		if owner.has_method("_suspend_session_save"):owner.call("_suspend_session_save")
	P.open_stage(number)
	P.launch_from_level_menu=number==1
	get_tree().change_scene_to_file(P.scene_for_stage(number))

func _open_stage_hub() -> void:
	if not menu_action.is_valid():return
	menu_action.call()
	var owner=menu_action.get_object()
	if is_instance_valid(owner):
		var overlay=owner.get("_pause_menu")
		if is_instance_valid(overlay):overlay.call("_show_levels")
