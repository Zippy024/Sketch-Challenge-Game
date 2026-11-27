extends Control
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
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
		body='<rect width="30" height="20" fill="#183c83"/><path d="M0 0L30 20M30 0L0 20" stroke="white" stroke-width="5"/><path d="M0 0L30 20M30 0L0 20" stroke="#d73349" stroke-width="2"/><path d="M15 0V20M0 10H30" stroke="white" stroke-width="7"/><path d="M15 0V20M0 10H30" stroke="#d73349" stroke-width="4"/>'
	return svg('<svg xmlns="http://www.w3.org/2000/svg" width="30" height="20">'+body+'<rect x=".5" y=".5" width="29" height="19" fill="none" stroke="#6d9bbd" stroke-width=".7"/></svg>')

static func skin(kind: String,w: int,h: int) -> StyleBoxTexture:
	var result=StyleBoxTexture.new()
	result.texture=UI.Gloss.surface(kind,w,h)
	result.set_content_margin_all(3)
	return result

func _ready() -> void:
	name="Stage1Header" if stage==1 else "GameHeader"
	custom_minimum_size.y=76
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	design=Control.new();design.name="LevelReachBar";design.size=Vector2(1070,48);design.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(design)
	frame=TextureRect.new();frame.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;frame.size=design.size;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;design.add_child(frame)
	resized.connect(_fit)
	_refresh();_build_controls();_controls_ready=true;_fit()

func _fit() -> void:
	if design==null or not _controls_ready or _fitting:return
	_fitting=true
	var factor=maxf(1.0,size.x-24.0)/1070.0
	design.position=Vector2(12,8);design.size=Vector2(roundf(1070*factor),roundf(48*factor))
	frame.size=design.size;frame.texture=UI.Gloss.surface("header",roundi(design.size.x),roundi(design.size.y))
	for child in design.get_children():
		if child==frame or not child is Control:continue
		if not child.has_meta("header_base_rect"):child.set_meta("header_base_rect",Rect2(child.position,child.size))
		var rect: Rect2=child.get_meta("header_base_rect")
		child.position=(rect.position*factor).round();child.size=(rect.size*factor).round()
		if child.has_meta("stage"):
			child.add_theme_stylebox_override("panel",skin("primary" if child.get_meta("current") else ("locked" if child.get_meta("locked") else "button"),roundi(child.size.x),roundi(child.size.y)))
			for caption in child.find_children("*","Label",true,false):caption.add_theme_font_size_override("font_size",maxi(12,roundi(11*factor)))
			for icon in child.find_children("*","TextureRect",true,false):icon.custom_minimum_size=Vector2.ONE*roundf(9*factor)
			for row in child.find_children("*","HBoxContainer",true,false):row.add_theme_constant_override("separation",roundi(3*factor))
		elif child.has_meta("header_command"):
			var button=child if child is Button else child.get_child(0)
			button.add_theme_font_size_override("font_size",maxi(12,roundi(11*factor)))
			button.add_theme_constant_override("icon_max_width",roundi(13*factor))
			for state in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(state,skin("button",roundi(child.size.x),roundi(child.size.y)))
		elif child.name=="GameLanguageStatus":
			child.add_theme_stylebox_override("panel",skin("name",roundi(child.size.x),roundi(child.size.y)))
			var label=child.find_child("LanguageCaption",true,false)
			label.add_theme_font_size_override("font_size",maxi(12,roundi(12*factor)))
			child.find_child("LanguageFlag",true,false).custom_minimum_size=Vector2(22,15)*factor
			child.get_child(0).add_theme_constant_override("separation",roundi(6*factor))
	var height=roundf(48*factor)+13
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
		var point=PanelContainer.new();point.name="ReachNode%02d"%i
		point.set_meta("stage",i);point.set_meta("current",active);point.set_meta("completed",done);point.set_meta("locked",locked)
		point.tooltip_text=UI.text("Stage %d")%i;point.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;point.focus_mode=Control.FOCUS_ALL
		point.position=Vector2(174+(i-1)*50,11);point.size=Vector2(38,26);point.set_meta("header_base_rect",Rect2(point.position,point.size));point.add_theme_stylebox_override("panel",skin("button",38,26))
		point.gui_input.connect(_stage_pressed.bind(i));design.add_child(point);_stage_nodes.append(point)
		var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.mouse_filter=Control.MOUSE_FILTER_IGNORE;point.add_child(row)
		if done or locked:
			var icon=TextureRect.new();icon.texture=UI.icon("play" if active else ("check" if done else "lock"));icon.modulate=Color.WHITE if active else (Color("21a55b") if done else Color("63849a"));icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(9,9);icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(icon)
		var caption=UI.inline_label("%02d"%i,11,true);caption.name="CurrentStageLabel" if active else "ReachStageLabel";caption.set_meta("locale_ignore",true);caption.add_theme_color_override("font_color",Color.WHITE if active else Color("163e61"));row.add_child(caption)
		if active:
			var pointer=TextureRect.new();pointer.texture=svg('<svg xmlns="http://www.w3.org/2000/svg" width="12" height="7"><path d="M1 1H11L6 6Z" fill="#087fff"/></svg>');pointer.mouse_filter=Control.MOUSE_FILTER_IGNORE;pointer.position=Vector2(point.position.x+13,2);pointer.size=Vector2(12,7);design.add_child(pointer);_stage_nodes.append(pointer)
	var status=design.get_node_or_null("GameLanguageStatus")
	if status:
		status.set_meta("language",P.get_language());status.find_child("LanguageFlag",true,false).texture=flag(P.get_language());status.find_child("LanguageCaption",true,false).text={"jp":"Japan","mm":"Myanmar","en":"English"}[P.get_language()]
	_fit.call_deferred()

func _build_controls() -> void:
	var mark=UI.logo(0,0);mark.name="Stage1Logo" if stage==1 else "GameLogo";mark.position=Vector2(12,4);mark.size=Vector2(122,40);design.add_child(mark)
	var group=HBoxContainer.new();group.name="HeaderRetryGroup";group.set_meta("header_command",true);group.position=Vector2(740,9);group.size=Vector2(86,30);group.set_meta("header_base_rect",Rect2(740,9,86,30));design.add_child(group)
	var retry=UI.button("Retry",retry_action,false,0,11);retry.name="Stage%dRetry"%stage;retry.icon=UI.icon("undo",14);retry.expand_icon=true;retry.clip_text=true;retry.custom_minimum_size=Vector2.ZERO;retry.size_flags_horizontal=Control.SIZE_EXPAND_FILL;UI.Gloss.disable_button(retry);group.add_child(retry)
	var stages=UI.button("Stage",menu_action,false,0,11);stages.name="Stage1MenuButton" if stage==1 else "GameMenuButton";stages.icon=UI.icon("menu",14);stages.expand_icon=true;stages.clip_text=true;stages.custom_minimum_size=Vector2.ZERO;stages.tooltip_text=UI.text("Select Level");stages.set_meta("header_command",true);UI.Gloss.disable_button(stages);stages.position=Vector2(836,9);stages.size=Vector2(86,30);stages.set_meta("header_base_rect",Rect2(836,9,86,30));design.add_child(stages)
	var status=PanelContainer.new();status.name="GameLanguageStatus";status.set_meta("locale_ignore",true);status.set_meta("language",P.get_language());status.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.position=Vector2(932,9);status.size=Vector2(126,30);design.add_child(status)
	var row=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.mouse_filter=Control.MOUSE_FILTER_IGNORE;status.add_child(row)
	var emblem=TextureRect.new();emblem.name="LanguageFlag";emblem.texture=flag(P.get_language());emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;emblem.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(emblem)
	var caption=UI.inline_label("",12,true);caption.name="LanguageCaption";caption.text={"jp":"Japan","mm":"Myanmar","en":"English"}[P.get_language()];caption.add_theme_font_override("font",UI.font(true,"en"));caption.set_meta("locale_ignore",true);row.add_child(caption)

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
