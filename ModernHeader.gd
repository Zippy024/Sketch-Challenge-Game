extends Control
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
var stage: int=1
var menu_action: Callable
var language_action: Callable
var design: Control
var frame: TextureRect
var _signature: String=""
var _stage_nodes: Array[Control]=[]
var _controls_ready: bool=false
var _fitting: bool=false

static func svg(source: String) -> Texture2D:
	# Retain SVG data so Godot rasterizes at the actual canvas/display scale.
	# A fixed 1070px/36px ImageTexture becomes soft when this header is enlarged.
	var texture:=DPITexture.create_from_string(source,1.0)
	# Cover the header's own scaled design as well as the viewport's DPI scale.
	texture.set_size_override(Vector2i(texture.get_size()))
	return texture

static func pill(active: bool,done: bool=false,round_button: bool=false,state: String="normal",locked: bool=false) -> StyleBoxTexture:
	var width=36 if round_button else 120
	var style=StyleBoxTexture.new()
	style.texture=UI.Gloss.surface("primary" if active else ("locked" if locked else ("round" if round_button else "button")),width,36)
	style.texture_margin_left=10 if not round_button else 12;style.texture_margin_right=style.texture_margin_left
	style.texture_margin_top=10;style.texture_margin_bottom=10
	style.set_content_margin_all(3);style.content_margin_top=1;style.content_margin_bottom=4
	if state=="hover":style.modulate_color=Color("f1fbff")
	elif state=="pressed":style.modulate_color=Color("cceaf9")
	return style

func _ready() -> void:
	name="Stage1Header" if stage==1 else "GameHeader"
	custom_minimum_size.y=84
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	design=Control.new()
	design.name="LevelReachBar"
	design.size=Vector2(1070,52)
	design.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(design)
	frame=TextureRect.new()
	frame.texture=UI.Gloss.surface("header",1070,52)
	frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	frame.size=Vector2(1070,52)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	design.add_child(frame)
	resized.connect(_fit)
	_refresh()
	_build_controls()
	_controls_ready=true
	_fit()

func _fit() -> void:
	if design==null or not _controls_ready or _fitting:return
	_fitting=true
	var factor=maxf(1.0,size.x-24.0)/1070.0
	design.scale=Vector2.ONE
	design.position=Vector2(12,8)
	design.size=Vector2(roundf(1070*factor),roundf(52*factor))
	frame.size=design.size
	frame.texture=UI.Gloss.surface("header",roundi(design.size.x),roundi(design.size.y))
	for child in design.get_children():
		if child==frame or not child is Control:continue
		if not child.has_meta("header_base_rect"):child.set_meta("header_base_rect",Rect2(child.position,child.size))
		var base_rect: Rect2=child.get_meta("header_base_rect")
		child.position=(base_rect.position*factor).round()
		child.size=(base_rect.size*factor).round()
		if child is PanelContainer and child.has_meta("stage"):
			var kind="primary" if child.get_meta("current") else ("locked" if child.get_meta("locked") else "button")
			var style=StyleBoxTexture.new();style.texture=UI.Gloss.surface(kind,roundi(child.size.x),roundi(child.size.y))
			style.set_content_margin_all(3);style.content_margin_top=1;style.content_margin_bottom=4
			child.add_theme_stylebox_override("panel",style)
			for caption in child.find_children("*","Label",true,false):caption.add_theme_font_size_override("font_size",maxi(13,roundi(13*factor)))
			for icon in child.find_children("*","TextureRect",true,false):icon.custom_minimum_size=Vector2.ONE*roundf(12*factor)
			for row in child.find_children("*","HBoxContainer",true,false):row.add_theme_constant_override("separation",roundi(4*factor))
		elif child.name in ["GameHomeButton","GameMenuButton","Stage1MenuButton"]:
			child.add_theme_constant_override("icon_max_width",roundi(19*factor))
			for state in ["normal","hover","pressed","disabled"]:
				var style=StyleBoxTexture.new();style.texture=UI.Gloss.surface("round",roundi(child.size.x),roundi(child.size.y));style.set_content_margin_all(3)
				child.add_theme_stylebox_override(state,style)
		else:
			var picker=child.find_child("LanguageMenu",true,false) as MenuButton
			if picker:
				picker.custom_minimum_size=(Vector2(98,30)*factor).round()
				picker.add_theme_font_size_override("font_size",maxi(12,roundi(12*factor)))
				picker.add_theme_constant_override("icon_max_width",roundi(15*factor))
				for state in ["normal","hover","pressed","disabled"]:
					var style=StyleBoxTexture.new();style.texture=UI.Gloss.surface("button",roundi(98*factor),roundi(30*factor));style.set_content_margin_all(3);style.content_margin_right=roundf(14*factor)
					picker.add_theme_stylebox_override(state,style)
	var height=roundf(52*factor)+13
	if not is_equal_approx(custom_minimum_size.y,height):custom_minimum_size.y=height
	_fitting=false

func _process(_delta: float) -> void:
	var key: String=P.get_language()+str(P.is_completed(1))+str(P.is_completed(2))+str(P.is_completed(3))
	if key!=_signature:_refresh()

func _refresh() -> void:
	if design==null:return
	_signature=P.get_language()+str(P.is_completed(1))+str(P.is_completed(2))+str(P.is_completed(3))
	for n in _stage_nodes:
		design.remove_child(n)
		n.queue_free()
	_stage_nodes.clear()
	var x:=164.0
	for i in range(1,11):
		var active:=i==stage
		var done:=P.is_completed(i)
		var point:=PanelContainer.new()
		point.name="ReachNode%02d"%i
		point.set_meta("stage",i)
		point.set_meta("current",active)
		point.set_meta("completed",done)
		point.set_meta("locked",not P.is_level_unlocked(i))
		point.tooltip_text=UI.text("Stage %d")%i+"\n"+UI.text("Coming soon" if not P.is_level_unlocked(i) else ("Completed" if done else "Ready"))
		var width:=52.0
		point.position=Vector2(x,8 if active else 9)
		point.size=Vector2(width,34)
		point.add_theme_stylebox_override("panel",pill(active,done,false,"normal",not P.is_level_unlocked(i)))
		if stage==4 and P.is_level_unlocked(i) and not active:
			point.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
			point.gui_input.connect(_stage_pressed.bind(i))
		design.add_child(point)
		_stage_nodes.append(point)
		if active:
			var pointer=TextureRect.new();pointer.texture=svg('<svg xmlns="http://www.w3.org/2000/svg" width="14" height="8"><path d="M1 1H13L7 7Z" fill="#087fff" stroke="#087fff" stroke-linejoin="round"/></svg>');pointer.mouse_filter=Control.MOUSE_FILTER_IGNORE
			pointer.position=Vector2(x+(width-14)*.5,0);pointer.size=Vector2(14,8);design.add_child(pointer);_stage_nodes.append(pointer)
		var row:=HBoxContainer.new()
		row.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",4)
		point.add_child(row)
		if done or not P.is_level_unlocked(i):
			var icon:=TextureRect.new()
			icon.texture=UI.icon("play" if active else ("check" if done else "lock"))
			icon.modulate=Color.WHITE if active else (Color("21a55b") if done else Color("63849a"))
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size=Vector2(12,12)
			icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
		var caption:=UI.inline_label("%02d"%i,11,true)
		caption.name="CurrentStageLabel" if active else "ReachStageLabel"
		caption.set_meta("locale_ignore",not active)
		caption.add_theme_color_override("font_color",Color.WHITE if active else Color("163e61"))
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(caption)
		x+=width+16.0
	_fit.call_deferred()

func _build_controls() -> void:
	var mark=UI.logo(0,0)
	mark.name="Stage1Logo" if stage==1 else "GameLogo"
	design.add_child(mark)
	mark.position=Vector2(12,2)
	mark.size=Vector2(122,44)
	var language=UI.language_switcher(language_action,10)
	language.name="Stage1LanguagePicker" if stage==1 else "GameLanguagePicker"
	design.add_child(language)
	language.position=Vector2(850,8)
	var picker=language.find_child("LanguageMenu",true,false)
	# Header is uniformly scaled from the accepted native reference geometry.
	# Remove only the classic alignment callback; native popup/action signals stay.
	for connection in picker.resized.get_connections():picker.resized.disconnect(connection.callable)
	UI.Gloss.disable_button(picker)
	picker.custom_minimum_size=Vector2(98,30)
	picker.add_theme_constant_override("icon_max_width",15)
	picker.add_theme_constant_override("h_separation",4)
	for state in ["normal","hover","pressed","disabled"]:
		var style=pill(false,true,false,state)
		style.content_margin_left=5
		style.content_margin_right=14
		picker.add_theme_stylebox_override(state,style)
	var chevron=picker.find_child("LanguageChevron",true,false)
	chevron.offset_left=-13
	chevron.offset_right=-6
	chevron.offset_top=-3
	chevron.offset_bottom=3
	language.size=Vector2(98,32)
	for home in [true,false]:
		var action: Callable=func():UI.go_home(menu_action.get_object())
		if not home:action=menu_action
		var button=UI.button("",action,false,36,11)
		UI.Gloss.disable_button(button)
		button.name="GameHomeButton" if home else ("Stage1MenuButton" if stage==1 else "GameMenuButton")
		button.icon=UI.icon("home" if home else "menu")
		button.tooltip_text=UI.text("Go to Main Menu" if home else "Menu")
		design.add_child(button)
		button.custom_minimum_size=Vector2(36,31)
		button.position=Vector2(960 if home else 1012,8)
		button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width",19)
		button.add_theme_constant_override("h_separation",4)
		for state in ["normal","hover","pressed","disabled"]:
			button.add_theme_stylebox_override(state,pill(false,true,true,state))
		for state in ["icon_normal_color","icon_hover_color","icon_pressed_color"]:button.add_theme_color_override(state,Color("087fff"))
		button.size=Vector2(36,31)

func _stage_pressed(event: InputEvent,number: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var owner=menu_action.get_object()
		if is_instance_valid(owner) and owner.has_method("_go_stage"):owner.call("_go_stage",number)
