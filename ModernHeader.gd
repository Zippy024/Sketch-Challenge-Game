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

static func svg(source: String) -> Texture2D:
	# Retain SVG data so Godot rasterizes at the actual canvas/display scale.
	# A fixed 1070px/36px ImageTexture becomes soft when this header is enlarged.
	var texture:=DPITexture.create_from_string(source,2.0)
	# Cover the header's own scaled design as well as the viewport's DPI scale.
	texture.set_size_override(Vector2i(texture.get_size()/2.0))
	return texture

static func pill(active: bool,done: bool=false,round_button: bool=false,state: String="normal") -> StyleBoxTexture:
	# Match the nameplate: a raised base, a pale top rim and a shaded lower lip.
	var w:=36 if round_button else 120
	var top:="#71dfff" if active else ("#ffffff" if done else "#d8f2ff")
	var middle:="#00bfff" if active else ("#e3f5ff" if done else "#a9dcf3")
	var bottom:="#007fb4" if active else ("#a9dcf3" if done else "#74b7da")
	var source:='<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="36"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset=".48" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient></defs><rect x="1" y="6" width="%d" height="29" rx="15" fill="#14688e" opacity=".28"/><rect x="1" y="3" width="%d" height="29" rx="15" fill="#4ca5ce"/><rect x="1" y="1" width="%d" height="29" rx="15" fill="url(#g)" stroke="#8fdcff" stroke-width="1.3"/><rect x="3" y="2.8" width="%d" height="24" rx="12" fill="none" stroke="#ffffff" stroke-width="1.4" opacity=".88"/><path d="M10 28H%d" stroke="#267ea6" stroke-opacity=".35" stroke-width="1.5" stroke-linecap="round"/></svg>'%[w,top,middle,bottom,w-2,w-2,w-2,w-6,w-10]
	var style:=StyleBoxTexture.new()
	style.texture=svg(source)
	style.texture_margin_left=10 if round_button else 18
	style.texture_margin_right=10 if round_button else 18
	style.set_content_margin_all(3 if round_button else 2)
	style.content_margin_top=0 if not round_button else 2
	style.content_margin_bottom=5
	style.modulate_color=Color("b7def0") if state=="pressed" else (Color("eefbff") if state=="hover" else Color.WHITE)
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
	frame.texture=svg('<svg xmlns="http://www.w3.org/2000/svg" width="1070" height="52"><defs><linearGradient id="g"><stop stop-color="#00bfff"/><stop offset=".52" stop-color="#57cfff"/><stop offset="1" stop-color="#219fdf"/></linearGradient><linearGradient id="v" x2="0" y2="1"><stop stop-color="#ffffff" stop-opacity=".46"/><stop offset=".46" stop-color="#ffffff" stop-opacity=".10"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></linearGradient></defs><rect x="1" y="6" width="1068" height="45" rx="17" fill="#14688e" opacity=".28"/><rect x="1" y="3" width="1068" height="45" rx="17" fill="#2195c4"/><rect x=".7" y=".7" width="1068.6" height="44" rx="17" fill="url(#g)" stroke="#89dcfb" stroke-width="1.4"/><rect x="3.5" y="2.5" width="1063" height="39" rx="14" fill="url(#v)" stroke="#f1fdff" stroke-width="1.4"/><path d="M22 4H1048" stroke="#fff" stroke-width="1.5" opacity=".85"/><path d="M21 43H1049" stroke="#007da8" stroke-width="2" opacity=".35"/><path d="M155 2L136 43M159 2L140 43M879 2L861 43" stroke="#e9fcff" opacity=".48" fill="none"/><path d="M156 25Q330 15 511 25T859 25" stroke="#edffff" stroke-width="2" opacity=".8" fill="none"/></svg>')
	frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	frame.size=Vector2(1070,52)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	design.add_child(frame)
	resized.connect(_fit)
	_refresh()
	_build_controls()
	_fit()

func _fit() -> void:
	if design==null:return
	var factor:=maxf(1.0,size.x-24.0)/1070.0
	design.scale=Vector2.ONE*factor
	design.position=Vector2(12,8)
	var height:=52*factor+13
	if not is_equal_approx(custom_minimum_size.y,height):custom_minimum_size.y=height

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
	var x:=173.0
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
		var width:=92.0 if active else (54.0 if i<=3 else 52.0)
		point.position=Vector2(x,8 if active else 9)
		point.size=Vector2(width,34)
		point.add_theme_stylebox_override("panel",pill(active,done))
		design.add_child(point)
		_stage_nodes.append(point)
		var row:=HBoxContainer.new()
		row.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",4)
		point.add_child(row)
		if active or done or not P.is_level_unlocked(i):
			var icon:=TextureRect.new()
			icon.texture=UI.icon("play" if active else ("check" if done else "lock"))
			icon.modulate=Color.WHITE if active else (Color("2ec75b") if done else Color("386282"))
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size=Vector2(12,12)
			icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			row.add_child(icon)
		var caption:=UI.inline_label(UI.text("Stage %d")%i if active else "%02d"%i,11,true)
		caption.name="CurrentStageLabel" if active else "ReachStageLabel"
		caption.set_meta("locale_ignore",not active)
		caption.add_theme_color_override("font_color",Color.WHITE if active else Color("163e61"))
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(caption)
		x+=width+(9.0 if i==1 else (13.0 if i==2 else (18.0 if i==3 else 12.0)))

func _build_controls() -> void:
	var mark=UI.logo(0,0)
	mark.name="Stage1Logo" if stage==1 else "GameLogo"
	design.add_child(mark)
	mark.position=Vector2(12,2)
	mark.size=Vector2(122,44)
	var language=UI.language_switcher(language_action,10)
	language.name="Stage1LanguagePicker" if stage==1 else "GameLanguagePicker"
	design.add_child(language)
	language.position=Vector2(881,8)
	var picker=language.find_child("LanguageMenu",true,false)
	# Header is uniformly scaled from the accepted native reference geometry.
	# Remove only the classic alignment callback; native popup/action signals stay.
	for connection in picker.resized.get_connections():picker.resized.disconnect(connection.callable)
	picker.custom_minimum_size=Vector2(88,30)
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
	language.size=Vector2(88,32)
	for home in [true,false]:
		var action: Callable=func():UI.go_home(menu_action.get_object())
		if not home:action=menu_action
		var button=UI.button("",action,false,31,14)
		button.name="GameHomeButton" if home else ("Stage1MenuButton" if stage==1 else "GameMenuButton")
		button.icon=UI.icon("home" if home else "menu")
		button.tooltip_text=UI.text("Go to Main Menu" if home else "Menu")
		design.add_child(button)
		button.custom_minimum_size=Vector2(31,31)
		button.position=Vector2(979 if home else 1020,8)
		button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width",19)
		for state in ["normal","hover","pressed","disabled"]:
			button.add_theme_stylebox_override(state,pill(false,true,true,state))
		for state in ["icon_normal_color","icon_hover_color","icon_pressed_color"]:button.add_theme_color_override(state,Color("007db3"))
		button.size=Vector2(31,31)
