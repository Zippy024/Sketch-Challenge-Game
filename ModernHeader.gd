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
	var im:=Image.new()
	im.load_svg_from_buffer(source.to_utf8_buffer())
	return ImageTexture.create_from_image(im)

static func pill(active: bool,done: bool=false) -> StyleBoxTexture:
	var source: String
	if active:
		source='<svg xmlns="http://www.w3.org/2000/svg" width="120" height="36"><defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="#00bfff"/><stop offset=".45" stop-color="#009fd6"/><stop offset="1" stop-color="#006fa8"/></linearGradient></defs><rect x="1" y="4" width="118" height="31" rx="15" fill="#07598c" opacity=".25"/><rect x="1" y="1" width="118" height="31" rx="15" fill="url(#g)" stroke="#b7faff" stroke-width="1.2"/></svg>'
	else:
		var fill: String="#ffffff" if done else "#86c9ed"
		source='<svg xmlns="http://www.w3.org/2000/svg" width="120" height="36"><rect x="1" y="4" width="118" height="29" rx="14" fill="#366b91" opacity=".17"/><rect x="1" y="1" width="118" height="29" rx="14" fill="'+fill+'" fill-opacity="'+('1' if done else '.63')+'" stroke="#caeffb" stroke-width="1.2"/></svg>'
	var s:=StyleBoxTexture.new()
	s.texture=svg(source)
	s.texture_margin_left=18
	s.texture_margin_right=18
	s.set_content_margin_all(2)
	s.content_margin_top=0
	s.content_margin_bottom=4
	return s

func _ready() -> void:
	name="Stage1Header" if stage==1 else "GameHeader"
	custom_minimum_size.y=76
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	design=Control.new()
	design.name="LevelReachBar"
	design.size=Vector2(1070,56)
	design.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(design)
	frame=TextureRect.new()
	frame.texture=svg('<svg xmlns="http://www.w3.org/2000/svg" width="1070" height="56"><defs><linearGradient id="g"><stop stop-color="#00bfff"/><stop offset=".52" stop-color="#59cfff"/><stop offset="1" stop-color="#368fdf"/></linearGradient><linearGradient id="v" x2="0" y2="1"><stop stop-color="#ffffff" stop-opacity=".26"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></linearGradient></defs><rect x=".5" y=".5" width="1069" height="55" rx="18" fill="url(#g)" stroke="#c9f7ff"/><rect x="1" y="1" width="1068" height="54" rx="18" fill="url(#v)"/><path d="M155 1L132 55M159 1L136 55M879 1L857 55" stroke="#e9fcff" opacity=".48" fill="none"/><path d="M156 29Q330 19 511 29T859 29" stroke="#edffff" stroke-width="2" opacity=".8" fill="none"/><rect x="173" y="48" width="255" height="5" rx="3" fill="#00bfff" opacity=".7"/><path d="M161 44Q374 32 582 45T1050 43" stroke="#c9f2ff" stroke-width="1" opacity=".25" fill="none"/></svg>')
	frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	frame.size=Vector2(1070,56)
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	design.add_child(frame)
	resized.connect(_fit)
	_refresh()
	_build_controls()
	_fit()

func _fit() -> void:
	if design==null:return
	var factor:=size.x/1070.0
	design.scale=Vector2.ONE*factor
	var height:=56*factor
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
		point.position=Vector2(x,11 if active else 12)
		point.size=Vector2(width,34)
		point.add_theme_stylebox_override("panel",pill(active,done))
		design.add_child(point)
		_stage_nodes.append(point)
		var row:=HBoxContainer.new()
		row.alignment=BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation",4)
		point.add_child(row)
		if active or done or i>3:
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
	mark.size=Vector2(122,52)
	var language=UI.language_switcher(language_action,10)
	language.name="Stage1LanguagePicker" if stage==1 else "GameLanguagePicker"
	design.add_child(language)
	language.position=Vector2(881,12)
	var picker=language.find_child("LanguageMenu",true,false)
	# Header is uniformly scaled from the accepted native reference geometry.
	# Remove only the classic alignment callback; native popup/action signals stay.
	for connection in picker.resized.get_connections():picker.resized.disconnect(connection.callable)
	picker.custom_minimum_size=Vector2(88,30)
	picker.add_theme_constant_override("icon_max_width",15)
	picker.add_theme_constant_override("h_separation",4)
	for state in ["normal","hover","pressed","disabled"]:
		var style=UI.box(Color("edf9ff"),Color("b9eaff"),18,2)
		style.shadow_size=2
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
		button.icon=UI.icon("home") if home else preload("res://Stage1Assets/menu-lines.svg")
		button.tooltip_text=UI.text("Go to Main Menu" if home else "Menu")
		design.add_child(button)
		button.custom_minimum_size=Vector2(31,31)
		button.position=Vector2(979 if home else 1020,12)
		button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.alignment=HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width",19)
		for state in ["normal","hover","pressed","disabled"]:
			var style=UI.box(Color("edf9ff").darkened(.06 if state=="pressed" else (.03 if state=="hover" else 0)),Color("d2f2ff"),16,3)
			style.shadow_size=1
			button.add_theme_stylebox_override(state,style)
		for state in ["icon_normal_color","icon_hover_color","icon_pressed_color"]:button.add_theme_color_override(state,Color("007db3"))
		button.size=Vector2(31,31)
