extends Control
signal action_requested(action: String)
signal stage_requested(stage: int)
const Progress = preload("res://GameProgress.gd")
const UI = preload("res://KitchenUI.gd")
const Rating = preload("res://StageRating.gd")
const Decor = preload("res://MenuAssets/MissionDecor.gd")
const Journey=preload("res://HomeJourney.gd")
static var _home_intro_played: bool=false
static var _last_home_completed: int=-1
var _intro_tween: Tween
var _intro_hero: Control
var _intro_skip: Button
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
	_finish_home_intro()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if levels:
		theme=UI.make_theme()
		UI.background(self)
	else:
		theme=UI.make_theme()
		var art:=TextureRect.new()
		art.name="RealKitchenIntroBackground"
		art.texture=preload("res://UIAssets/RealKitchenIntro.webp")
		art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_design=Control.new()
	_design.size=Vector2(1440,810)
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

func _top_controls() -> void:
	var language := UI.language_switcher(func(lang: String):
		Progress.set_language(lang)
		_build()
	,13)
	_put(_design,language,Rect2(1150,22,180,40))
	var settings := UI.button("",func():action_requested.emit("settings"),false,44,16)
	settings.name="Settings"
	settings.icon=UI.icon("gear")
	settings.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	settings.alignment=HORIZONTAL_ALIGNMENT_CENTER
	settings.add_theme_color_override("icon_normal_color",UI.INK)
	settings.add_theme_color_override("icon_hover_color",UI.TEAL)
	settings.add_theme_constant_override("icon_max_width",24)
	settings.tooltip_text=UI.text("Settings")
	_put(_design,settings,Rect2(1350,22,46,44))

func _build_home() -> void:
	_add_logo(Rect2(555,6,330,120))
	_top_controls()
	var back:=_back_button("Language","language")
	back.name="BackToLanguage"
	_put(self,back,Rect2(44,24,205,44))
	var hero:=Panel.new()
	hero.name="HomeHeroPanel"
	hero.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hero.add_theme_stylebox_override("panel",UI.box(Color("fffdf6"),Color("b3cfc2"),28,0))
	_put(_design,hero,Rect2(64,164,1312,590))
	var title:=_level_label(hero,"Create your dream kitchen",Rect2(38,26,540,112),32 if Progress.get_language()=="mm" else 36,UI.INK,false,true)
	title.name="HomeWelcomeTitle"
	_level_label(hero,"Your kitchen takes shape as you learn.",Rect2(40,141,536,58),16,UI.MUTED,false)
	var mission:=Panel.new()
	mission.name="HomeCurrentMission"
	mission.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var mission_surface:=UI.box(Color("ecf5e9"),Color("d7e6d6"),17,0)
	mission_surface.shadow_size=0
	mission.add_theme_stylebox_override("panel",mission_surface)
	_put(hero,mission,Rect2(38,214,540,101))
	_level_label(mission,"Your next mission",Rect2(18,9,504,28),13,UI.TEAL,false,true)
	var current: int=Journey.current_stage()
	var caption:=UI.text(["Draw the layout","Plan Q&A","Kitchen Selection"][current-1]) if current<=3 else UI.text("Coming soon")
	var next_label:=_level_label(mission,"",Rect2(18,40,504,47),17,UI.INK,false,true)
	next_label.name="HomeNextMission"
	next_label.set_meta("locale_ignore",true)
	next_label.text=(UI.text("Stage %d")%current)+" · "+caption
	_level_label(hero,"Your journey",Rect2(42,334,245,29),15,UI.INK,false,true)
	var count: int=Journey.completed_count()
	var summary:=_level_label(hero,"",Rect2(295,334,280,29),13,UI.INK,true,true)
	summary.name="HomeJourneySummary"
	summary.set_meta("locale_ignore",true)
	summary.text=UI.text("%d / %d stages complete")%[count,Journey.TOTAL_STAGES]
	var progress:=preload("res://HomeProgress.gd").new()
	_put(hero,progress,Rect2(38,374,540,58))
	var available:=_level_label(hero,"",Rect2(42,428,536,33),12,UI.MUTED,false)
	available.name="HomeAvailableStages"
	available.set_meta("locale_ignore",true)
	available.text=UI.text("%d stages · %d available now")%[Journey.TOTAL_STAGES,Journey.available_count()]
	var preview_surface:=Panel.new()
	preview_surface.name="HomeKitchenCard"
	preview_surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var preview_style:=UI.box(Color("fffdf6"),Color("dbe8dc"),20,0)
	preview_style.shadow_size=0
	preview_surface.add_theme_stylebox_override("panel",preview_style)
	_put(hero,preview_surface,Rect2(610,24,670,434))
	_level_label(preview_surface,"Your kitchen",Rect2(18,10,410,30),16,UI.INK,false,true)
	var preview:=preload("res://HomeKitchenPreview.gd").new()
	preview.name="HomeKitchenPreview"
	preview.completed_stages=count
	preview.set_meta("completed_stages",count)
	_put(preview_surface,preview,Rect2(8,49,654,332))
	if _last_home_completed>=0 and count>_last_home_completed and _motion_allowed() and not paused_game:
		preview.modulate.a=0.0
		preview.create_tween().tween_property(preview,"modulate:a",1.0,0.65).set_trans(Tween.TRANS_SINE)
	_last_home_completed=count
	var total_stars:=0
	for stage in range(1,Journey.TOTAL_STAGES+1):total_stars+=int(Rating.best(stage).get("stars",0))
	var gold:=Decor.new()
	gold.kind=Decor.Kind.TOTAL_STAR
	_put(preview_surface,gold,Rect2(566,12,25,25))
	var score:=_level_label(preview_surface,"",Rect2(596,8,54,32),16,UI.INK,true,true)
	score.name="HomeBestStars"
	score.set_meta("locale_ignore",true)
	score.text=str(total_stars)
	var phase: int=0 if count<3 else (1 if count<6 else 2)
	for i in range(3):
		var chip:=Panel.new()
		chip.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var chip_style:=UI.box(Color("e3f1e6") if i==phase else Color("f6f7ed"),Color("a6cdbc") if i==phase else Color("e4e9db"),10,0)
		chip_style.shadow_size=0
		chip.add_theme_stylebox_override("panel",chip_style)
		_put(preview_surface,chip,Rect2(12+i*218,390,210,32))
		var phase_label:=_level_label(chip,["Plan your space","Choose equipment","Finishing touches"][i],Rect2(4,0,202,32),11,UI.TEAL if i==phase else UI.MUTED,true,i==phase)
		phase_label.tooltip_text=["01–03","04–06","07–10"][i]
	var divider:=HSeparator.new()
	_put(hero,divider,Rect2(34,478,1244,4))
	var start:=_button("Start Game",true,18)
	start.name="StartGame"
	start.icon=UI.icon("play")
	start.pressed.connect(func():action_requested.emit("new_game"))
	_put(hero,start,Rect2(38,506,330,58))
	var continue_button:=_button("Continue Game",false,17)
	continue_button.name="ContinueGame"
	continue_button.icon=UI.icon("redo")
	continue_button.add_theme_color_override("icon_normal_color",UI.TEAL)
	continue_button.disabled=not paused_game and not Progress.has_session()
	continue_button.tooltip_text=UI.text("Resume your saved game") if not continue_button.disabled else UI.text("Start a game first")
	continue_button.pressed.connect(func():action_requested.emit("continue"))
	_put(hero,continue_button,Rect2(380,506,286,58))
	for i in range(2):
		var button:=_button("Select Level" if i==0 else "How to Play",false,16)
		button.name="SelectLevel" if i==0 else "HowToPlay"
		button.icon=UI.icon("layers" if i==0 else "help")
		button.add_theme_color_override("icon_normal_color",UI.INK)
		button.pressed.connect(func():action_requested.emit("levels" if i==0 else "guide"))
		_put(hero,button,Rect2(678+i*302,506,290,58))
	if paused_game:
		var resume:=_button("Back to Game",true,14)
		resume.pressed.connect(func():action_requested.emit("back"))
		_put(_design,resume,Rect2(1170,766,205,34))
	_play_home_intro(hero)

func _play_home_intro(hero: Control) -> void:
	if _home_intro_played or paused_game or not _motion_allowed():return
	_home_intro_played=true
	_intro_hero=hero
	hero.modulate.a=0.0
	_intro_skip=_button("Skip intro",false,12)
	_intro_skip.name="SkipHomeIntro"
	_intro_skip.pressed.connect(_finish_home_intro)
	_put(_design,_intro_skip,Rect2(1190,112,184,34))
	_intro_tween=create_tween()
	_intro_tween.tween_property(hero,"modulate:a",1.0,2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_intro_tween.finished.connect(_finish_home_intro)

func _finish_home_intro() -> void:
	if _intro_tween and _intro_tween.is_valid():_intro_tween.kill()
	if is_instance_valid(_intro_hero):_intro_hero.modulate.a=1.0
	if is_instance_valid(_intro_skip):_intro_skip.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(_intro_skip) and _intro_skip.visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		_finish_home_intro()
		get_viewport().set_input_as_handled()

func _build_levels() -> void:
	_add_logo(Rect2(62,3,250,106))
	_top_controls()
	var eyebrow:=_level_label(_design,"Your kitchen design journey",Rect2(367,10,750,26),12,Color("247c73"),false,true)
	eyebrow.name="LevelJourneyEyebrow"
	_level_label(_design,"Choose your mission",Rect2(365,34,755,52),35 if Progress.get_language()=="mm" else 38,UI.INK,false,true)
	_level_label(_design,"Complete kitchen design missions to build your skills.",Rect2(369,88,750,28),15,UI.INK,false)
	_build_level_journey()
	var board:=Panel.new()
	board.name="MissionBoard"
	board.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var board_style:=UI.box(Color(0.85,0.95,0.89,0.66),Color("e5fff5"),28,0)
	board_style.shadow_size=12
	board.add_theme_stylebox_override("panel",board_style)
	_put(_design,board,Rect2(46,182,1348,546))
	for n in range(1,11):
		var column: int=(n-1)%5
		var row:=floori(float(n-1)/5.0)
		if column<4:
			var dots:=Decor.new()
			dots.kind=Decor.Kind.LINK
			_put(_design,dots,Rect2(323+column*260,316+row*264,14,4))
		_card(n,Rect2(78+column*260,198+row*264,244,248))
	var back:=_back_button("Back to Game" if paused_game else "Go to Main Menu","back")
	back.name="BackFromLevels"
	_put(_design,back,Rect2(54,754,248,42))
	if paused_game:
		var home:=_button("Go to Main Menu",false,15)
		home.name="LevelsMainMenu"
		home.icon=UI.icon("home")
		home.add_theme_color_override("icon_normal_color",UI.INK)
		home.add_theme_color_override("icon_hover_color",UI.TEAL)
		home.pressed.connect(func():action_requested.emit("home"))
		_put(_design,home,Rect2(1148,754,238,42))

func _build_level_journey() -> void:
	var strip:=Panel.new()
	strip.name="LevelJourneyProgress"
	strip.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var surface:=UI.box(Color(0.95,0.99,0.94,0.92),Color("eafff4"),24,0)
	surface.shadow_size=5
	strip.add_theme_stylebox_override("panel",surface)
	_put(_design,strip,Rect2(220,120,1000,54))
	var ribbon:=Control.new()
	ribbon.name="LevelJourneyRibbon"
	ribbon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_put(strip,ribbon,Rect2(14,10,174,34))
	var ribbon_art:=TextureRect.new()
	ribbon_art.texture=preload("res://UIAssets/ribbon.svg")
	ribbon_art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ribbon_art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_put(ribbon,ribbon_art,Rect2(0,0,174,34))
	_level_label(ribbon,"Your journey",Rect2(22,-3,130,34),13,Color.WHITE,true,true)
	var track:=Decor.new()
	track.kind=Decor.Kind.JOURNEY
	track.current_stage=Progress.next_stage()
	for stage in range(1,4):track.completed.append(Progress.is_completed(stage))
	_put(strip,track,Rect2(210,10,470,34))
	var caption:=_level_label(strip,LocaleManager.text("%d / 3 complete")%Progress.completed_count(),Rect2(704,8,164,38),13,UI.INK,true,true)
	caption.name="LevelJourneyCompleted"
	caption.set_meta("completed",Progress.completed_count())
	var total: int=0
	for stage in range(1,4):total+=int(Rating.best(stage).get("stars",0))
	var gold:=Decor.new()
	gold.kind=Decor.Kind.TOTAL_STAR
	_put(strip,gold,Rect2(877,13,24,26))
	var score:=_level_label(strip,"",Rect2(903,8,82,38),15,UI.INK,true,true)
	score.name="LevelJourneyBestStars"
	score.set_meta("locale_ignore",true)
	score.set_meta("stars",total)
	score.text="%d / 9"%total

func _level_font(bold: bool = false) -> FontVariation:
	return UI.font(bold)


func _level_label(parent: Control, message: String, rect: Rect2, font_size: int, color: Color = Color.WHITE, center: bool = true, bold: bool = false) -> Label:
	var label := _label(parent,message,rect,font_size,color,center)
	label.add_theme_font_override("font",_level_font(bold))
	label.size = rect.size
	return label


func _thumbnail(stage: int) -> Texture2D:
	if stage==1:return preload("res://Refrence image.png")
	var atlas:=preload("res://MenuAssets/mission-thumbnails.webp")
	var index: int=clampi(stage-2,0,7) if stage<10 else 1
	var tile:=AtlasTexture.new()
	tile.atlas=atlas
	tile.region=Rect2(Vector2(index%4,floori(float(index)/4.0))*Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0),Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0))
	tile.filter_clip=true
	return tile

func _level_card_style(fill: Color, edge: Color, selected: bool=false) -> StyleBoxFlat:
	var surface:=UI.box(fill,edge,19,0)
	surface.set_border_width_all(2)
	surface.shadow_color=Color(0.14,0.34,0.27,0.2)
	surface.shadow_size=8 if selected else 5
	surface.shadow_offset=Vector2(0,4)
	return surface

func _motion_allowed() -> bool:
	return not (OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true)))

func _hover_card(card: Button, baseline: float, hovered: bool) -> void:
	if not is_instance_valid(card) or card.disabled:return
	var previous: Variant=card.get_meta("hover_tween") if card.has_meta("hover_tween") else null
	if previous is Tween and previous.is_valid():previous.kill()
	var target:=baseline-3.0 if hovered or card.has_focus() else baseline
	if _motion_allowed():
		var motion:=card.create_tween()
		card.set_meta("hover_tween",motion)
		motion.tween_property(card,"position:y",target,0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:card.position.y=target

func _card(stage: int, rect: Rect2) -> void:
	var available:=Progress.is_level_unlocked(stage)
	var selected:=available and stage==selected_stage
	var card:=Button.new()
	card.name="StageCard%02d"%stage
	card.set_meta("stage",stage)
	card.set_meta("selected",selected)
	card.disabled=not available
	card.text=""
	card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if available else Control.CURSOR_ARROW
	card.add_theme_stylebox_override("normal",_level_card_style(Color("f5faee"),Color("f1fff4"),selected))
	card.add_theme_stylebox_override("hover",_level_card_style(Color("f4fff3"),UI.TEAL,true))
	card.add_theme_stylebox_override("pressed",_level_card_style(Color("e0f3e7"),UI.TEAL,true))
	card.add_theme_stylebox_override("disabled",_level_card_style(Color(0.92,0.95,0.88,0.90),Color("edf8e9")))
	var focus:=UI.box(Color.TRANSPARENT,UI.TEAL,19,0)
	focus.set_border_width_all(2)
	focus.shadow_size=0
	card.add_theme_stylebox_override("focus",focus)
	card.pressed.connect(func():
		selected_stage=stage
		_build()
	)
	card.mouse_entered.connect(_hover_card.bind(card,rect.position.y,true))
	card.mouse_exited.connect(_hover_card.bind(card,rect.position.y,false))
	card.focus_entered.connect(_hover_card.bind(card,rect.position.y,true))
	card.focus_exited.connect(_hover_card.bind(card,rect.position.y,false))
	_put(_design,card,rect)
	var inner:=Panel.new()
	inner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var inner_style:=UI.box(Color.TRANSPARENT,Color("d8e7d9"),15,0)
	inner_style.shadow_size=0
	inner.add_theme_stylebox_override("panel",inner_style)
	_put(card,inner,Rect2(4,4,236,240))
	if selected:
		var glow:=Panel.new()
		glow.name="SelectedStageGlow"
		glow.show_behind_parent=true
		glow.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var outline:=UI.box(Color.TRANSPARENT,Color("69d8c8"),23,0)
		outline.set_border_width_all(3)
		outline.shadow_color=Color(0,0.65,0.59,0.26)
		outline.shadow_size=10
		outline.shadow_offset=Vector2.ZERO
		glow.add_theme_stylebox_override("panel",outline)
		_put(card,glow,Rect2(-5,-5,254,258))
		var ring:=Panel.new()
		ring.name="SelectedStageOutline"
		ring.z_index=2
		ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var ring_style:=UI.box(Color.TRANSPARENT,UI.TEAL,20,0)
		ring_style.set_border_width_all(2)
		ring_style.shadow_size=0
		ring.add_theme_stylebox_override("panel",ring_style)
		_put(card,ring,Rect2(-1,-1,246,250))
		var sparks:=Decor.new()
		sparks.kind=Decor.Kind.SPARKLES
		sparks.z_index=3
		_put(card,sparks,Rect2(-5,-5,254,258))
		if _motion_allowed():
			var pulse:=glow.create_tween().set_loops()
			pulse.tween_property(glow,"modulate:a",0.55,1.5).set_trans(Tween.TRANS_SINE)
			pulse.tween_property(glow,"modulate:a",1.0,1.5).set_trans(Tween.TRANS_SINE)
	var banner:=Panel.new()
	banner.name="StageCardHeader"
	banner.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var banner_style:=UI.box(Color(0.94,0.98,0.94,0.7),Color.TRANSPARENT,18,0)
	banner_style.corner_radius_bottom_left=0
	banner_style.corner_radius_bottom_right=0
	banner_style.shadow_size=0
	banner.add_theme_stylebox_override("panel",banner_style)
	_put(card,banner,Rect2(2,2,240,39))
	var number:=Decor.new()
	number.kind=Decor.Kind.NUMBER
	number.available=available
	_put(card,number,Rect2(1,1,57,42))
	var numeral:=_level_label(card,"",Rect2(2,2,43,33),20,Color.WHITE,true,true)
	numeral.set_meta("locale_ignore",true)
	numeral.text="%02d"%stage
	var icon:=TextureRect.new()
	icon.name="StageSymbol"
	var symbol:=AtlasTexture.new()
	symbol.atlas=preload("res://MenuAssets/stage-symbols.svg")
	symbol.region=Rect2((stage-1)*32,0,32,32)
	icon.texture=symbol
	icon.modulate=UI.TEAL if available else Color("63877b")
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_put(card,icon,Rect2(62,10,24,24))
	var title:=_level_label(card,LocaleManager.text("Stage %02d")%stage,Rect2(88,7,146,29),15,UI.INK,true,true)
	title.name="StageTitle"
	var image_frame:=Panel.new()
	image_frame.name="StageThumbnailFrame"
	image_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	image_frame.clip_children=CanvasItem.CLIP_CHILDREN_AND_DRAW
	var image_style:=UI.box(Color("fffdf6"),Color("d4dfd2"),10,0)
	image_style.shadow_size=0
	image_frame.add_theme_stylebox_override("panel",image_style)
	_put(card,image_frame,Rect2(10,44,224,102))
	var image:=TextureRect.new()
	image.name="StageThumbnail"
	image.texture=_thumbnail(stage)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED if stage==1 else TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_put(image_frame,image,Rect2(2,2,220,98))
	if not available:
		var wash:=ColorRect.new()
		wash.color=Color(0.91,0.95,0.88,0.54)
		wash.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_put(image_frame,wash,Rect2(2,2,220,98))
	var caption: String=["Draw the layout","Plan Q&A","Kitchen Selection"][stage-1] if stage<=3 else ""
	var caption_view:=_level_label(card,caption,Rect2(7,147,230,28),12 if Progress.get_language()=="mm" else 14,UI.INK,true,true)
	caption_view.name="StageCaption"
	if available:
		var stars:=Decor.new()
		stars.name="StageStars"
		stars.earned=int(Rating.best(stage).get("stars",0))
		stars.set_meta("stars",stars.earned)
		_put(card,stars,Rect2(54,175,136,20))
	else:
		var medallion:=Panel.new()
		medallion.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var medal_style:=UI.box(Color("fffdf0"),Color("c9d8c5"),20,0)
		medal_style.shadow_size=3
		medallion.add_theme_stylebox_override("panel",medal_style)
		_put(card,medallion,Rect2(104,132,36,36))
		var lock:=TextureRect.new()
		lock.name="StageLock"
		lock.texture=preload("res://MenuAssets/level-lock.svg")
		lock.modulate=Color.WHITE
		lock.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		lock.mouse_filter=Control.MOUSE_FILTER_IGNORE
		_put(medallion,lock,Rect2(9,8,18,20))
	if selected:
		var tab:=Panel.new()
		tab.name="SelectedStageTag"
		tab.z_index=5
		tab.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var tab_style:=UI.box(Color("fff7da"),Color("d8c98e"),7,0)
		tab_style.shadow_size=2
		tab.add_theme_stylebox_override("panel",tab_style)
		_put(card,tab,Rect2(144,-10,99,22))
		tab.rotation=0.05
		_level_label(tab,"Selected",Rect2(3,0,93,22),10,Color("38685e"),true,true)
		var play:=_button("Play",true,15)
		play.name="SelectedPlayButton"
		play.icon=preload("res://MenuAssets/level-play.svg")
		play.pressed.connect(func():stage_requested.emit(stage))
		_put(card,play,Rect2(28,194,188,42))
	else:
		var badge:=Panel.new()
		badge.name="StageStatusBadge"
		badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var badge_style:=UI.box(Color("f6faee") if available else Color("e8eee0"),Color("62aaa0") if available else Color("c0d1c2"),18,0)
		badge_style.shadow_size=2
		badge.add_theme_stylebox_override("panel",badge_style)
		_put(card,badge,Rect2(28,200,188,32))
		_level_label(badge,("Completed" if Progress.is_completed(stage) else "Ready") if available else "Coming soon",Rect2(4,0,180,32),12,Color("246b63"),true,true)

func _fit() -> void:
	if not is_instance_valid(_design):return
	var factor := minf(size.x/1440.0,size.y/810.0)
	_design.scale=Vector2.ONE*factor
	_design.position=(size-Vector2(1440,810)*factor)*0.5
	var language_back:=get_node_or_null("BackToLanguage") as Control
	if language_back!=null:
		language_back.scale=Vector2.ONE*factor
		language_back.position=Vector2(44,24)*factor
