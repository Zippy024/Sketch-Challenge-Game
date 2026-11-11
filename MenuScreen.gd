extends Control
signal action_requested(action: String)
signal stage_requested(stage: int)
const Progress = preload("res://GameProgress.gd")
const UI = preload("res://KitchenUI.gd")
var levels: bool = false
var paused_game: bool = false
var selected_stage: int = 1
var _design: Control
var _logo: TextureRect
var _level_fonts: Dictionary = {}

func _ready() -> void:
	name = "LevelSelectionScreen" if levels else "KitchenHomeScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	selected_stage = Progress.next_stage()
	_build()
	resized.connect(_fit)

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
	return UI.button(message,Callable(),primary,110,font_size)

func _back_button(message: String, action: String) -> Button:
	var button := _button(message,false,15)
	button.icon=preload("res://MenuAssets/BackArrow.svg")
	button.add_theme_color_override("icon_normal_color",UI.INK)
	button.add_theme_color_override("icon_hover_color",UI.TEAL)
	button.add_theme_constant_override("h_separation",8)
	button.pressed.connect(func() -> void:action_requested.emit(action))
	return button

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	UI.background(self)
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
	_logo.name="MenuLogo"
	if OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true)):
		return
	var motion := ShaderMaterial.new()
	motion.shader = preload("res://MenuAssets/LogoFloat.gdshader")
	_logo.material = motion
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _build_home() -> void:
	_add_logo(Rect2(365,0,470,210))
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",UI.box())
	_put(_design,panel,Rect2(350,215,500,435))
	_label(_design,"Your kitchen design journey",Rect2(375,235,450,45),27,UI.INK)
	_label(_design,"Three missions. One thoughtful kitchen.",Rect2(380,283,440,35),15,UI.MUTED)
	var captions := [("Play Again" if Progress.completed_count()==3 else "Continue Game") if Progress.completed_count()>0 else "Start Game","Select Level","How to Play"]
	for i in range(3):
		var button := _button(captions[i],i==0,18)
		button.name = ["StartGame","SelectLevel","HowToPlay"][i]
		if i == 0 and Progress.completed_count() in [1,2]:
			button.pressed.connect(func(): stage_requested.emit(Progress.next_stage()))
		else:
			button.pressed.connect(func(): action_requested.emit("guide" if i==2 else "levels"))
		_put(_design,button,Rect2(420,340+i*65,360,48))
	var progress := UI.progress_strip(true)
	_put(_design,progress,Rect2(380,560,440,55))
	# Keep the compact home progress readable inside its narrower card.
	progress.find_child("OverallProgressCaption",true,false).hide()
	var settings := _button("Settings",false,15)
	settings.name = "Settings"
	settings.pressed.connect(func(): action_requested.emit("settings"))
	_put(_design,settings,Rect2(1020,24,150,40))
	var back := _back_button("Language", "language")
	back.name = "BackToLanguage"
	_put(_design,back,Rect2(42,728,170,42))
	if paused_game:
		var resume := _button("Back to Game",true,16)
		resume.pressed.connect(func():action_requested.emit("back"))
		_put(_design,resume,Rect2(480,680,240,42))

func _build_levels() -> void:
	_add_logo(Rect2(25,5,285,125))
	var divider := ColorRect.new()
	divider.color = Color("9bf8ff")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(_design,divider,Rect2(322,27,1,78))
	var heading := _level_label(_design,"Select a Level",Rect2(346,16,810,66),38,UI.INK,false,true)
	var title_font := _level_font(true).duplicate() as FontVariation
	title_font.variation_transform = Transform2D(Vector2(1,0),Vector2(-0.1,1),Vector2.ZERO)
	heading.add_theme_font_override("font",title_font)
	_level_label(_design,"Progress through kitchen design missions step by step.",Rect2(346,79,810,38),15,UI.MUTED,false)
	var panel := Panel.new()
	panel.name = "LevelGlassFrame"
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_level_surface("frame"))
	_put(_design,panel,Rect2(25,135,1150,535))
	for n in range(1,11):
		var column := (n-1)%5
		var row := floori(float(n-1)/5.0)
		_card(n,Rect2(53+column*220,151+row*258,208,252))
	var brief := PanelContainer.new()
	brief.name = "MissionBrief"
	brief.add_theme_stylebox_override("panel",UI.box(Color(0.96,0.99,1,0.92),Color.WHITE,16,8))
	_put(_design,brief,Rect2(280,680,895,100))
	var brief_col := VBoxContainer.new()
	brief_col.add_theme_constant_override("separation",6)
	brief.add_child(brief_col)
	brief_col.add_child(UI.label(["Draw the connected living, dining and kitchen area.","Explain the pipe shaft and the limits on moving it.","Choose a kitchen layout and identify five components."][selected_stage-1],14,true))
	brief_col.add_child(UI.progress_strip())
	var back := _back_button("Back to Game" if paused_game else "Back to Home", "back")
	back.name="BackFromLevels"
	_style_level_action(back,16)
	_put(_design,back,Rect2(42,728,210,42))


func _level_font(bold: bool = false) -> FontVariation:
	var language := Progress.get_language()
	var key := language + ("/bold" if bold else "/regular")
	if not _level_fonts.has(key):
		var font := FontVariation.new()
		font.base_font = preload("res://Font/NotoSansMyanmar.ttf") if language == "mm" else preload("res://Font/NotoSansCJKjp-Regular.otf")
		font.variation_embolden = 0.5 if bold else 0.0
		_level_fonts[key] = font
	return _level_fonts[key] as FontVariation


func _level_label(parent: Control, message: String, rect: Rect2, font_size: int, color: Color = Color.WHITE, center: bool = true, bold: bool = false) -> Label:
	var label := _label(parent,message,rect,font_size,color,center)
	label.add_theme_font_override("font",_level_font(bold))
	label.size = rect.size
	return label


func _level_surface(kind: String) -> StyleBoxFlat:
	return UI.box(Color(0.94,0.98,1,0.92) if kind=="card" else Color(0.93,0.98,1,0.58),Color.WHITE,20,0)

func _style_level_action(button: Button, font_size: int) -> void:
	UI.style_button(button,false,font_size)

func _style_level_play(button: Button) -> void:
	UI.style_button(button,true,15)

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
	card.add_theme_stylebox_override("normal",_level_surface("card"))
	var disabled_style := _level_surface("card")
	disabled_style.bg_color = Color("d8e5ea")
	card.add_theme_stylebox_override("disabled",disabled_style)
	var hover := _level_surface("card")
	hover.border_color = UI.TEAL
	card.add_theme_stylebox_override("hover",hover)
	var focus := _box(Color.TRANSPARENT,Color("c5ffff"),21)
	focus.shadow_size = 0
	card.add_theme_stylebox_override("focus",focus)
	card.pressed.connect(func() -> void:
		selected_stage=stage
		_build()
	)
	_put(_design,card,rect)
	if selected:
		var glow := Panel.new()
		glow.name = "SelectedStageGlow"
		glow.show_behind_parent = true
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var outline := UI.box(Color.TRANSPARENT,Color("36c0c7"),22,0)
		outline.set_border_width_all(3)
		outline.shadow_color = Color(0.0,0.6,0.7,0.18)
		outline.shadow_offset = Vector2.ZERO
		glow.add_theme_stylebox_override("panel",outline)
		_put(card,glow,Rect2(-3,-3,214,258))
		var ring := Panel.new()
		ring.name = "SelectedStageOutline"
		ring.z_index = 2
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ring_style := _box(Color.TRANSPARENT,Color("36c0c7"),22)
		ring_style.set_border_width_all(3)
		ring_style.shadow_size = 0
		ring_style.draw_center = false
		ring.add_theme_stylebox_override("panel",ring_style)
		_put(card,ring,Rect2(-3,-3,214,258))
	var icon := TextureRect.new()
	icon.name = "StageSymbol"
	var symbol := AtlasTexture.new()
	symbol.atlas = preload("res://MenuAssets/stage-symbols.svg")
	symbol.region = Rect2((stage-1)*32,0,32,32)
	icon.texture = symbol
	icon.modulate = UI.TEAL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(card,icon,Rect2(14,9,26,26))
	var title := _level_label(card,LocaleManager.text("Stage %02d")%stage,Rect2(45,0,153,42),15,UI.INK,true,true)
	title.name="StageTitle"
	var image_frame := Panel.new()
	image_frame.name = "StageThumbnailFrame"
	image_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_frame.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var image_style := _box(Color("f4fcff"),Color("d4f7ff"),12)
	image_style.shadow_size = 0
	image_frame.add_theme_stylebox_override("panel",image_style)
	_put(card,image_frame,Rect2(7,44,194,100))
	var image := TextureRect.new()
	image.name = "StageThumbnail"
	image.texture=_thumbnail(stage)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if stage == 1 else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image.modulate=Color.WHITE if available else Color(0.86,0.93,0.96)
	_put(image_frame,image,Rect2(4,4,186,92))
	var caption: String="Coming soon"
	if stage==1:caption="LDK Boundary Drawing"
	elif stage==2:caption="Pipe Shaft Q&A"
	elif stage==3:caption="S-Class Kitchen Selection"
	var caption_font_size := 12 if Progress.get_language() == "mm" else 14
	var caption_view := _level_label(card,caption,Rect2(9,147,190,49),caption_font_size,Color("11374a"),true,true)
	caption_view.name = "StageCaption"
	if selected:
		var play := _button("Play",false,16)
		play.name="SelectedPlayButton"
		_style_level_play(play)
		play.icon = preload("res://MenuAssets/level-play.svg")
		play.pressed.connect(func() -> void:stage_requested.emit(stage))
		_put(card,play,Rect2(26,198,156,40))
	else:
		var badge := Panel.new()
		badge.name = "StageStatusBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_style := _box(Color("91e2e9") if available else Color("9ebecb"),Color(0.9,1.0,1.0,0.5),14)
		badge_style.shadow_size = 0
		badge_style.set_border_width_all(1)
		badge.add_theme_stylebox_override("panel",badge_style)
		_put(card,badge,Rect2(44,210,120,28))
		if not available:
			var lock := TextureRect.new()
			lock.name = "StageLock"
			lock.texture = preload("res://MenuAssets/level-lock.svg")
			lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_put(badge,lock,Rect2(14,6,16,16))
		_level_label(badge,("Completed" if Progress.is_completed(stage) else "Ready") if available else "Locked",Rect2(4 if available else 31,0,112 if available else 85,28),12,Color("245b70"),true,true)

func _fit() -> void:
	if not is_instance_valid(_design):return
	var factor := minf(minf(size.x/1260.0,size.y/820.0),1.2)
	_design.scale=Vector2.ONE*factor
	_design.position=(size-Vector2(1200,780)*factor)*0.5
