extends Control
signal action_requested(action: String)
signal stage_requested(stage: int)
const Progress = preload("res://GameProgress.gd")
var levels: bool = false
var paused_game: bool = false
var selected_stage: int = 3
var _design: Control
var _logo: TextureRect
var _logo_origin: Vector2
var _time: float = 0.0
var _motion: bool = true

func _ready() -> void:
	name = "LevelSelectionScreen" if levels else "KitchenHomeScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if OS.has_feature("web"):
		_motion = not bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	_build()
	resized.connect(_fit)
	set_process(_motion)

func _box(fill: Color, edge: Color, radius: int = 24, glow: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=fill
	style.border_color=edge
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(8)
	style.shadow_color=Color(0.0,0.8,0.95,0.24) if glow>0 else Color(0,0.05,0.09,0.25)
	style.shadow_size=glow if glow>0 else 6
	style.shadow_offset=Vector2(0,3)
	return style

func _put(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.position=rect.position
	child.size=rect.size

func _label(parent: Control, message: String, rect: Rect2, font_size: int, color: Color = Color.WHITE, center: bool = true) -> Label:
	var label := Label.new()
	_put(parent,label,rect)
	label.text=LocaleManager.text(message)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label

func _button(message: String, primary: bool = false, font_size: int = 20) -> Button:
	var button := Button.new()
	button.text=LocaleManager.text(message)
	button.add_theme_font_size_override("font_size",font_size)
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,Color.WHITE)
	if primary:
		var capsule := StyleBoxTexture.new()
		capsule.texture=preload("res://LanguageAssets/Continue.svg")
		capsule.texture_margin_left=32
		capsule.texture_margin_right=32
		capsule.texture_margin_top=24
		capsule.texture_margin_bottom=24
		capsule.set_content_margin_all(6)
		button.add_theme_stylebox_override("normal",capsule)
	else:
		button.add_theme_stylebox_override("normal",_box(Color(0.015,0.20,0.29,0.94),Color("79d8ed"),28))
	button.add_theme_stylebox_override("hover",_box(Color("087e96"),Color("a0ffff"),28,9))
	button.add_theme_stylebox_override("pressed",_box(Color("03506b"),Color("a0ffff"),28))
	button.add_theme_stylebox_override("focus",_box(Color.TRANSPARENT,Color("d6ffff"),28))
	return button

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var background := TextureRect.new()
	background.texture=preload("res://MenuAssets/Modern Teal Kitchen with Warm Accents.png")
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color=Color(0.015,0.08,0.12,0.20)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_design=Control.new()
	_design.size=Vector2(1200,780)
	add_child(_design)
	if levels:_build_levels()
	else:_build_home()
	_fit()

func _add_logo(rect: Rect2) -> void:
	_logo=TextureRect.new()
	_logo.texture=preload("res://LoadingAssets/KitchenLogo.webp")
	_logo.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_put(_design,_logo,rect)
	_logo_origin=rect.position

func _build_home() -> void:
	_add_logo(Rect2(350,20,500,245))
	var captions: Array[String]=["Start Game","Select Level","Game Guide","Settings"]
	var actions: Array[String]=["levels","levels","guide","settings"]
	for i in range(captions.size()):
		var button := _button(captions[i],i==0,20)
		button.name=["StartGame","SelectLevel","GameGuide","Settings"][i]
		button.pressed.connect(func() -> void:action_requested.emit(actions[i]))
		_put(_design,button,Rect2(420,300+i*73,360,56))
	if paused_game:
		var resume := _button("Back to Game",false,16)
		resume.pressed.connect(func() -> void:action_requested.emit("back"))
		_put(_design,resume,Rect2(480,614,240,45))

func _build_levels() -> void:
	_add_logo(Rect2(35,10,235,120))
	_label(_design,"Select a Level",Rect2(295,22,620,49),34,Color.WHITE,false)
	_label(_design,"Progress through kitchen design missions step by step.",Rect2(295,76,665,46),15,Color("d4f2fa"),false)
	var trainee := _button("Trainee",false,15)
	trainee.pressed.connect(func() -> void:action_requested.emit("profile"))
	_put(_design,trainee,Rect2(1010,29,150,43))
	var panel := Panel.new()
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_box(Color(0.035,0.17,0.22,0.84),Color("75edff"),30,14))
	_put(_design,panel,Rect2(25,145,1150,565))
	for n in range(1,11):
		var column := (n-1)%5
		var row := (n-1)/5
		_card(n,Rect2(53+column*220,170+row*270,208,252))
	var back := _button("Back to Game" if paused_game else "Back to Home",false,15)
	back.pressed.connect(func() -> void:action_requested.emit("back"))
	_put(_design,back,Rect2(42,728,210,42))

func _thumbnail(stage: int) -> Texture2D:
	match stage:
		1:return preload("res://reference_sketch.png")
		2:return preload("res://MenuAssets/Level2.png")
		3:return preload("res://MenuAssets/Level3.png")
		4,7:return preload("res://MenuAssets/Level4.png")
		5,8:return preload("res://MenuAssets/Level5.png")
		_:return preload("res://MenuAssets/Level5.png")

func _card(stage: int, rect: Rect2) -> void:
	var available: bool=Progress.is_level_unlocked(stage)
	var selected: bool=available and stage==selected_stage
	var card := Button.new()
	card.name="StageCard%02d"%stage
	card.set_meta("stage",stage)
	card.disabled=not available
	card.text=""
	card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	card.add_theme_stylebox_override("normal",_box(Color("e8f7fc"),Color("64f1ff") if selected else Color("8fc2d1"),21,12 if selected else 0))
	card.add_theme_stylebox_override("disabled",_box(Color("c5d9df"),Color("82aebd"),21))
	card.add_theme_stylebox_override("hover",_box(Color("f4fdff"),Color("8af6ff"),21,10))
	card.add_theme_stylebox_override("focus",_box(Color.TRANSPARENT,Color("c5ffff"),21))
	card.pressed.connect(func() -> void:
		selected_stage=stage
		_build()
	)
	_put(_design,card,rect)
	var ribbon := Panel.new()
	ribbon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ribbon.add_theme_stylebox_override("panel",_box(Color("06445b"),Color("a7deed"),17))
	_put(card,ribbon,Rect2(4,4,200,33))
	_label(card,LocaleManager.text("Stage %02d")%stage,Rect2(8,6,192,29),16)
	var image := TextureRect.new()
	image.texture=_thumbnail(stage)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.modulate=Color.WHITE if available else Color(0.72,0.81,0.85,1)
	_put(card,image,Rect2(8,43,192,100))
	var caption: String="Coming soon"
	if stage==1:caption="LDK Boundary Drawing"
	elif stage==2:caption="Pipe Shaft Q&A"
	elif stage==3:caption="S-Class Kitchen Selection"
	_label(card,caption,Rect2(10,147,188,58),14,Color("11374a"))
	if selected:
		var play := _button("Play",false,13)
		play.name="SelectedPlayButton"
		for state in ["normal","hover","pressed","focus"]:
			var play_style := _box(Color("04768d") if state=="normal" else Color("0994a6"),Color("93eafb"),16)
			play_style.content_margin_top=2
			play_style.content_margin_bottom=2
			play.add_theme_stylebox_override(state,play_style)
		play.pressed.connect(func() -> void:stage_requested.emit(stage))
		_put(card,play,Rect2(48,214,112,34))
	else:
		_label(card,"Ready" if available else "Locked",Rect2(16,214,176,29),13,Color("22657c"))

func _fit() -> void:
	if not is_instance_valid(_design):return
	var factor := minf(minf(size.x/1260.0,size.y/820.0),1.2)
	_design.scale=Vector2.ONE*factor
	_design.position=(size-Vector2(1200,780)*factor)*0.5

func _process(delta: float) -> void:
	_time+=delta
	if is_instance_valid(_logo):_logo.position.y=_logo_origin.y+sin(_time*TAU/6.0)*3.0
