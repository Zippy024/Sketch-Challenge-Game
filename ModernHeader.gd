extends Control
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
const REFERENCE_SIZE=Vector2(1912,110)
var stage: int=1
var menu_action: Callable
var language_action: Callable # Kept for callers; the in-game language is display-only.
var retry_action: Callable
var design: Control
var frame: TextureRect
var _signature: String=""
var _stage_nodes: Array[Control]=[]
var _controls_ready: bool=false
var _fitting: bool=false
var _popup: Control
var _paused_audio: Array[AudioStreamPlayer]=[]

static func svg(source: String) -> Texture2D:
	return UI.Gloss.vector(source)

static func flag(language: String) -> Texture2D:
	var body='<rect width="30" height="20" fill="white"/><circle cx="15" cy="10" r="5.5" fill="#d92840"/>'
	if language=="mm":
		body='<path fill="#ffd432" d="M0 0H30V7H0Z"/><path fill="#34a753" d="M0 7H30V14H0Z"/><path fill="#e84742" d="M0 14H30V20H0Z"/><path fill="white" d="M15 3L17 8H23L18 12L20 18L15 14L10 18L12 12L7 8H13Z"/>'
	elif language=="en":
		body='<rect width="30" height="20" fill="white"/>'
		for stripe in range(0,13,2):body+='<rect y="%s" width="30" height="%s" fill="#b22234"/>'%[str(stripe*20.0/13),str(20.0/13)]
		body+='<rect width="12.5" height="10.8" fill="#3c3b6e"/>'
		for row in range(9):
			for column in range(6 if row%2==0 else 5):body+='<circle cx="%s" cy="%s" r=".28" fill="white"/>'%[str(1.1+column*2.0+(1.0 if row%2 else 0.0)),str(.7+row*1.15)]

	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="30" height="20">'+body+'<rect x=".5" y=".5" width="29" height="19" fill="none" stroke="#6d9bbd" stroke-width=".7"/></svg>')

static func skin(kind: String,w: int,h: int) -> StyleBoxTexture:
	var result=StyleBoxTexture.new()
	result.texture=UI.Gloss.surface(kind,w,h)
	result.set_content_margin_all(3)
	return result

static func award_icon() -> Texture2D:
	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"><circle cx="12" cy="12" r="10.4" fill="#ffd34c" stroke="#b77911" stroke-width="1.2"/><path d="M12 3L14.7 8.4L20.7 9.3L16.35 13.55L17.38 19.6L12 16.8L6.62 19.6L7.65 13.55L3.3 9.3L9.3 8.4Z" fill="#fff8df" stroke="#d79420" stroke-width=".8"/></svg>')

static func clear_lock_icon() -> Texture2D:
	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 12 12"><path d="M4 5V3.2a2 2 0 0 1 4 0V5" fill="none" stroke="white" stroke-width="1.5"/><rect x="2.8" y="5" width="6.4" height="5.8" rx="1.1" fill="white"/><circle cx="6" cy="7.5" r=".65" fill="#164d72"/><path d="M5.6 7.6h.8v1.7h-.8z" fill="#164d72"/></svg>')

static func command_icon(kind: String) -> Texture2D:
	var shape='<path d="M18.3 6.4A8 8 0 1 0 20 14" fill="none" stroke="white" stroke-width="2.7" stroke-linecap="round"/><path d="M14 3L22 5L19 12Z" fill="white"/>' if kind=="retry" else '<g fill="white"><circle cx="5" cy="6" r="1.8"/><circle cx="5" cy="12" r="1.8"/><circle cx="5" cy="18" r="1.8"/><path d="M9 4.5H21V7.5H9ZM9 10.5H21V13.5H9ZM9 16.5H21V19.5H9Z"/></g>'
	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24">'+shape+'</svg>')

static func ribbon_texture(kind: String,w: int,h: int) -> Texture2D:
	w=maxi(24,w);h=maxi(18,h)
	var dimensions={"header":Vector2(1912,110),"command":Vector2(47,47),"locale":Vector2(154,47),"track":Vector2(733,37),"label":Vector2(113,44),"active":Vector2(48,48),"done":Vector2(48,48),"available":Vector2(48,48),"locked":Vector2(48,48)}
	var palettes={"header":["#2dc7f4","#075b98","#063c68"],"command":["#45d9fb","#117fb6","#064a78"],"locale":["#f0fbff","#cceaff","#064f7e"],"track":["#0c4b76","#07375b","#418cb0"],"label":["#0e5d94","#073f72","#54dcff"],"active":["#4de1ff","#0ca5df","#84efff"],"done":["#4ee5b4","#1aa483","#8cebc9"],"available":["#427fa7","#245f8b","#4e9ec6"],"locked":["#2c5d83","#20496d","#3b7499"]}
	var reference: Vector2=dimensions[kind];var colors: Array=palettes[kind]
	var stops='<stop stop-color="%s"/><stop offset="1" stop-color="%s"/>'%[colors[0],colors[1]]
	if kind=="header":stops='<stop stop-color="#2dc7f4"/><stop offset=".26" stop-color="#159bdb"/><stop offset=".65" stop-color="#0a7bbd"/><stop offset="1" stop-color="#075b98"/>'
	var defs='<defs><linearGradient id="g" x2="0" y2="1">'+stops+'</linearGradient><radialGradient id="soft" cx=".48" cy="0" r=".8"><stop stop-color="#dffaff" stop-opacity=".14"/><stop offset="1" stop-color="#dffaff" stop-opacity="0"/></radialGradient></defs>'
	var body: String
	if kind=="header":
		body='<rect x="8" y="12" width="1898" height="94" rx="26" fill="#064570" opacity=".5"/><rect x="6" y="6" width="1900" height="94" rx="25" fill="url(#g)" stroke="#063c68" stroke-width="2.2"/><rect x="9" y="9" width="1894" height="88" rx="23" fill="none" stroke="#6bddff" stroke-width="1" opacity=".5"/><path d="M331 32V78M1608 32V78" stroke="#8ce5fb" stroke-width="1.2" opacity=".35"/>'
	elif kind=="command":
		body='<circle cx="23.5" cy="25" r="22" fill="#06476a" opacity=".4"/><circle cx="23.5" cy="23.5" r="22" fill="url(#g)" stroke="#064a78" stroke-width="1.6"/>'
	elif kind=="locale":
		body='<rect x="1" y="4" width="152" height="42" rx="12" fill="#064f77" opacity=".4"/><rect x="1" y="1" width="152" height="44" rx="12" fill="url(#g)" stroke="#064f7e" stroke-width="1.6"/>'
	elif kind=="label":
		body='<rect x="1" y="2" width="111" height="41" rx="12" fill="#06446a" opacity=".5"/><rect x="1" y="1" width="111" height="42" rx="12" fill="url(#g)" stroke="#54dcff" stroke-width="1.4"/><path d="M29 41H85" stroke="#4edbff" stroke-width="2"/>'
	elif kind=="track":
		body='<path d="M39 18.5H696" fill="none" stroke="#0a3a60" stroke-width="8" stroke-linecap="round"/><path d="M39 18.5H696" fill="none" stroke="#6ac2e4" stroke-width="3" stroke-linecap="round" opacity=".7"/>'
	else:
		body='<circle cx="24" cy="25.5" r="22" fill="#082b49" opacity=".4"/><circle cx="24" cy="24" r="22" fill="url(#g)" stroke="%s" stroke-width="1.4"/>'%colors[2]
		if kind=="active":body+='<circle cx="24" cy="24" r="23" fill="none" stroke="#8df4ff" stroke-width="2"/>'

	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %s %s" preserveAspectRatio="none">'%[w,h,str(reference.x),str(reference.y)]+defs+body+'</svg>')

static func ribbon_skin(kind: String,w: int,h: int) -> StyleBoxTexture:
	var result=StyleBoxTexture.new();result.texture=ribbon_texture(kind,w,h)
	result.set_content_margin_all(6*float(h)/47.0 if kind=="locale" else 0)
	return result

func _ready() -> void:
	name="Stage1Header" if stage==1 else "GameHeader"
	custom_minimum_size.y=83
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	design=Control.new();design.name="LevelReachBar";design.size=REFERENCE_SIZE;design.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(design)
	frame=TextureRect.new();frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;frame.size=design.size;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;design.add_child(frame)
	resized.connect(_fit)
	_refresh();_build_controls();_controls_ready=true;_fit()

func _fit() -> void:
	if design==null or not _controls_ready or _fitting or size.x<1:return
	_fitting=true
	var factor=size.x/REFERENCE_SIZE.x
	design.position=Vector2.ZERO;design.size=(REFERENCE_SIZE*factor).round()
	frame.size=design.size;frame.texture=ribbon_texture("header",roundi(design.size.x),roundi(design.size.y))
	for child in design.get_children():
		if child==frame or not child is Control:continue
		if not child.has_meta("header_base_rect"):child.set_meta("header_base_rect",Rect2(child.position,child.size))
		var rect: Rect2=child.get_meta("header_base_rect")
		child.position=(rect.position*factor).round();child.size=(rect.size*factor).round()
		if child.has_meta("stage"):
			var kind="active" if child.get_meta("current") else ("locked" if child.get_meta("locked") else ("done" if child.get_meta("completed") else "available"))
			child.add_theme_stylebox_override("panel",ribbon_skin(kind,roundi(child.size.x),roundi(child.size.y)))
			var caption=child.get_child(0)
			var number_size=maxi(11,roundi(22*factor))
			var number_font=UI.font(false,"en").duplicate()
			number_font.variation_opentype={2003265652:750.0 if child.get_meta("current") else 700.0}
			number_font.spacing_top=-roundi(number_size*.45);number_font.spacing_bottom=-roundi(number_size*.45)
			caption.add_theme_font_override("font",number_font);caption.add_theme_font_size_override("font_size",number_size)
			caption.size=Vector2(child.size.x,caption.get_minimum_size().y);caption.position=Vector2(0,roundf((child.size.y-caption.size.y)*.5))
			var marker=child.get_node_or_null("ActiveStageMark")
			if marker:marker.visible=false
			for icon in child.find_children("*","TextureRect",true,false):
				var stars=icon.name=="EarnedStageStar"
				icon.size=Vector2.ONE*roundf((22 if stars else 12)*factor)
				icon.position=Vector2(roundf((child.size.x-icon.size.x)*.5),roundf(-12*factor)) if stars else Vector2(child.size.x-icon.size.x,roundf(36*factor))
		elif child.has_meta("ribbon_surface"):
			child.texture=ribbon_texture(str(child.get_meta("ribbon_surface")),roundi(child.size.x),roundi(child.size.y))
			if child.name=="RibbonLevelBadge":
				var text=child.get_node("RibbonLevelLabel");text.add_theme_font_size_override("font_size",maxi(10,roundi(20*factor)))
				text.size=Vector2(child.size.x-48*factor,text.get_minimum_size().y);text.position=Vector2(44*factor,roundf((child.size.y-text.size.y)*.5))
				var star=child.get_node("RibbonLevelStar");star.size=Vector2.ONE*22*factor;star.position=Vector2(8*factor,11*factor)
		elif child.has_meta("header_command"):
			var button=child if child is Button else child.get_child(0)
			button.add_theme_font_size_override("font_size",1 if child.has_meta("circle_command") else maxi(10,roundi(20*factor)))
			button.add_theme_constant_override("icon_max_width",roundi(32*factor))
			for state in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(state,ribbon_skin("command",roundi(child.size.x),roundi(child.size.y)) if child.has_meta("circle_command") else skin("button",roundi(child.size.x),roundi(child.size.y)))
			if child.has_meta("circle_command"):
				button.get_theme_stylebox("hover").modulate_color=Color(1.1,1.1,1.1,1)
				button.get_theme_stylebox("pressed").modulate_color=Color(.84,.9,.98,1)
				button.get_theme_stylebox("disabled").modulate_color=Color(.65,.75,.82,1)
				for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]:button.add_theme_color_override(state,Color.WHITE)

		elif child.name=="GameLanguageStatus":
			child.add_theme_stylebox_override("panel",ribbon_skin("locale",roundi(child.size.x),roundi(child.size.y)))
			var label=child.find_child("LanguageCaption",true,false)
			label.add_theme_font_size_override("font_size",maxi(10,roundi(20*factor)))
			var slot=label.get_parent();slot.custom_minimum_size=Vector2(label.get_minimum_size().x,0)
			label.size=Vector2(slot.custom_minimum_size.x,label.get_minimum_size().y);label.position=Vector2(0,roundf((child.size.y-12*factor-label.size.y)*.5))
			child.find_child("LanguageFlag",true,false).custom_minimum_size=Vector2(32,22)*factor
			child.get_child(0).add_theme_constant_override("separation",roundi(10*factor))
	var height=roundf(REFERENCE_SIZE.y*factor)
	if not is_equal_approx(custom_minimum_size.y,height):custom_minimum_size.y=height
	_fitting=false

func _process(_delta: float) -> void:
	var key=P.get_language()+str(P.is_completed(1))+str(P.is_completed(2))+str(P.is_completed(3))
	if key!=_signature:_refresh()

func _refresh() -> void:
	if design==null:return
	_signature=P.get_language()+str(P.is_completed(1))+str(P.is_completed(2))+str(P.is_completed(3))
	for n in _stage_nodes:design.remove_child(n);n.queue_free()
	_stage_nodes.clear()
	for i in range(1,11):
		var active=i==stage;var done=P.is_completed(i);var locked=not P.is_level_unlocked(i)
		var point=Panel.new();point.name="ReachNode%02d"%i
		point.set_meta("stage",i);point.set_meta("current",active);point.set_meta("completed",done);point.set_meta("locked",locked)
		point.tooltip_text=UI.text("Stage %d")%i;point.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;point.focus_mode=Control.FOCUS_ALL
		point.position=Vector2(680+(i-1)*73,30);point.size=Vector2(48,48);point.set_meta("header_base_rect",Rect2(point.position,point.size))
		point.gui_input.connect(_stage_pressed.bind(i));design.add_child(point);_stage_nodes.append(point)
		var caption=UI.inline_label("%02d"%i,11,true);caption.name="CurrentStageLabel" if active else "ReachStageLabel";caption.set_meta("locale_ignore",true);caption.clip_text=true;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_color_override("font_color",Color("c6e2f4") if locked else (Color("063e63") if active or done else Color("f4fbff")));point.add_child(caption)
		point.mouse_entered.connect(func():point.self_modulate=Color(1.12,1.12,1.12,1))
		point.mouse_exited.connect(func():point.self_modulate=Color.WHITE)
		if active:
			var marker=ColorRect.new();marker.name="ActiveStageMark";marker.color=Color("8df4ff");marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;point.add_child(marker)
		if done or locked:
			var icon=TextureRect.new();icon.name="EarnedStageStar" if done else "LockedStageCorner";icon.texture=award_icon() if done else clear_lock_icon();icon.modulate=Color.WHITE if done else Color("d7effe");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;point.add_child(icon)
	var status=design.get_node_or_null("GameLanguageStatus")
	if status:
		status.set_meta("language",P.get_language());status.find_child("LanguageFlag",true,false).texture=flag(P.get_language());status.find_child("LanguageCaption",true,false).text={"jp":"Japan","mm":"Myanmar","en":"English"}[P.get_language()]
	_fit.call_deferred()

func _build_controls() -> void:
	var rail=TextureRect.new();rail.name="StageRibbonTrack";rail.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rail.set_meta("ribbon_surface","track");rail.position=Vector2(665,36);rail.size=Vector2(733,37);rail.mouse_filter=Control.MOUSE_FILTER_IGNORE;design.add_child(rail);design.move_child(rail,1)
	var badge=TextureRect.new();badge.name="RibbonLevelBadge";badge.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;badge.set_meta("ribbon_surface","label");badge.position=Vector2(541,31);badge.size=Vector2(113,44);badge.mouse_filter=Control.MOUSE_FILTER_IGNORE;design.add_child(badge)
	var star=TextureRect.new();star.name="RibbonLevelStar";star.texture=award_icon();star.modulate=Color.WHITE;star.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;star.mouse_filter=Control.MOUSE_FILTER_IGNORE;badge.add_child(star)
	var level=UI.inline_label("LEVEL",20,true);level.name="RibbonLevelLabel";level.set_meta("locale_ignore",true);level.clip_text=true;level.add_theme_color_override("font_color",Color.WHITE);badge.add_child(level)
	var mark=UI.logo(0,0);mark.name="Stage1Logo" if stage==1 else "GameLogo";mark.position=Vector2(28,8);mark.size=Vector2(278,82);mark.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT;design.add_child(mark)
	var group=HBoxContainer.new();group.name="HeaderRetryGroup";group.set_meta("header_command",true);group.set_meta("circle_command",true);group.position=Vector2(1624,29);group.size=Vector2(47,47);group.set_meta("header_base_rect",Rect2(1624,29,47,47));design.add_child(group)
	var retry=UI.button("",retry_action,false,0,11);retry.name="Stage%dRetry"%stage;retry.icon=command_icon("retry");retry.set_meta("icon_only",true);retry.tooltip_text=UI.text("Retry");retry.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;retry.expand_icon=true;retry.clip_text=true;retry.custom_minimum_size=Vector2.ZERO;retry.size_flags_horizontal=Control.SIZE_EXPAND_FILL;UI.Gloss.disable_button(retry);group.add_child(retry)
	var stages=UI.button("",menu_action,false,0,11);stages.name="Stage1MenuButton" if stage==1 else "GameMenuButton";stages.icon=command_icon("stage");stages.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;stages.expand_icon=true;stages.clip_text=true;stages.custom_minimum_size=Vector2.ZERO;stages.tooltip_text=UI.text("Select Level");stages.set_meta("header_command",true);stages.set_meta("circle_command",true);UI.Gloss.disable_button(stages);stages.position=Vector2(1682,29);stages.size=Vector2(47,47);stages.set_meta("header_base_rect",Rect2(1682,29,47,47));design.add_child(stages)
	var status=PanelContainer.new();status.name="GameLanguageStatus";status.set_meta("locale_ignore",true);status.set_meta("language",P.get_language());status.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.position=Vector2(1742,30);status.size=Vector2(154,47);design.add_child(status)
	var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.add_child(row)
	var emblem=TextureRect.new();emblem.name="LanguageFlag";emblem.texture=flag(P.get_language());emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(emblem)
	var caption=UI.inline_label("",12,true);caption.name="LanguageCaption";caption.text={"jp":"Japan","mm":"Myanmar","en":"English"}[P.get_language()];caption.add_theme_font_override("font",UI.font(true,"en"));caption.set_meta("locale_ignore",true);var slot=Control.new();slot.name="LanguageTextSlot";slot.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(slot);slot.add_child(caption)

func _stage_pressed(event: InputEvent,number: int) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT) or event.is_action_pressed("ui_accept"):_open_stage_card(number)

func _open_stage_card(number: int) -> void:
	if is_instance_valid(_popup):return
	var owner=menu_action.get_object()
	if not is_instance_valid(owner):return
	Rating.checkpoint(true)
	if owner.has_method("_save_session"):owner.call("_save_session")
	_paused_audio.clear()
	for player in owner.find_children("*","AudioStreamPlayer",true,false):
		if player.playing and not player.stream_paused:player.stream_paused=true;_paused_audio.append(player)
	_popup=load("res://StageCardPicker.gd").new();_popup.selected_stage=number;_popup.process_mode=Node.PROCESS_MODE_ALWAYS
	_popup.resume_requested.connect(_return_to_game);_popup.stage_requested.connect(_start_stage);_popup.main_menu_requested.connect(_main_menu)
	owner.add_child(_popup);_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);get_tree().paused=true

func _return_to_game() -> void:
	get_tree().paused=false
	for player in _paused_audio:
		if is_instance_valid(player):player.stream_paused=false
	_paused_audio.clear()
	if is_instance_valid(_popup):_popup.queue_free()
	_popup=null

func _start_stage(number: int) -> void:
	if not P.is_level_unlocked(number):return
	var owner=menu_action.get_object()
	if owner.has_method("_suspend_session_save"):owner.call("_suspend_session_save")
	P.open_stage(number);P.launch_from_level_menu=number==1;get_tree().paused=false
	var result=get_tree().change_scene_to_file(P.scene_for_stage(number))
	if result==OK:preload("res://MenuExtras.gd").record_launch(number)
	else:
		if owner.get("_session_save_suspended")!=null:owner.set("_session_save_suspended",false)
		get_tree().paused=true

func _main_menu() -> void:
	UI.go_home(menu_action.get_object())
