extends Control
signal resume_requested
signal stage_requested(stage: int)
signal main_menu_requested
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
const Decor=preload("res://MenuAssets/MissionDecor.gd")
const Look=preload("res://StagePickerStyle.gd")
const PANEL_SIZE=Vector2(520,560)
var selected_stage: int=1
var _panel: PanelContainer
var _number: Label
var _title: Label
var _image: TextureRect
var _caption: Label
var _stars: Control
var _status: Label
var _start: Button
var _choices: Array[Button]=[]
var _crown: TextureRect
var _checks: Array[TextureRect]=[]
func put(parent: Node,node: Control,rect: Rect2) -> void:
	parent.add_child(node);node.position=rect.position;node.size=rect.size
func art(parent: Node,image: Texture2D,rect: Rect2) -> TextureRect:
	var n=TextureRect.new();n.texture=image;n.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;n.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;n.mouse_filter=Control.MOUSE_FILTER_IGNORE;put(parent,n,rect);return n
func face(parent: Node,kind: String,rect: Rect2) -> PanelContainer:
	var n=PanelContainer.new();n.add_theme_stylebox_override("panel",Look.skin(kind,roundi(rect.size.x),roundi(rect.size.y)));put(parent,n,rect);return n
func caption(parent: Node,value: String,rect: Rect2,font_size: int=16,white: bool=false) -> Label:
	var n=UI.inline_label(value,font_size,true);n.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;n.add_theme_color_override("font_color",Color.WHITE if white else UI.INK);put(parent,n,rect);return n
func action(parent: Node,value: String,rect: Rect2,callback: Callable,kind: String="button",font_size: int=15) -> Button:
	var n=UI.button(value,callback,false,0,font_size);n.custom_minimum_size=Vector2.ZERO;put(parent,n,rect);n.alignment=HORIZONTAL_ALIGNMENT_CENTER;n.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;Look.style_button(n,kind);return n
func _ready() -> void:
	name="StageCardPicker";theme=UI.make_theme();mouse_filter=Control.MOUSE_FILTER_STOP;set_meta("locale_ignore",true)
	var shade=ColorRect.new();shade.color=Color(.025,.13,.26,.43);add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel=face(self,"outer",Rect2(Vector2.ZERO,PANEL_SIZE));_panel.name="StagePickerPanel";_panel.resized.connect(_center)
	var design=Control.new();design.mouse_filter=Control.MOUSE_FILTER_IGNORE;_panel.add_child(design)
	var heading=face(design,"heading",Rect2(108,-5,304,48));caption(heading,"Select a Level",Rect2(0,1,304,40),22,true)
	art(design,Look.symbol("spark"),Rect2(128,8,20,20));art(design,Look.symbol("spark"),Rect2(376,8,20,20))
	var card=face(design,"card",Rect2(91,54,338,354));card.name="StagePreviewCard"
	var content=Control.new();content.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(content)
	face(content,"title",Rect2(19,16,302,38));face(content,"blue",Rect2(8,3,61,61))
	_number=caption(content,"",Rect2(8,8,61,49),25,true);_number.name="StageCardNumber"
	_title=caption(content,"",Rect2(72,16,238,33),19);_title.name="StageCardTitle"
	var frame=face(content,"photo",Rect2(14,68,310,132))
	_image=TextureRect.new();_image.name="StageCardImage";_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(_image)
	_caption=caption(content,"",Rect2(15,201,308,35),17 if P.get_language()=="mm" else 19);_caption.name="StageCardCaption";_caption.clip_text=true
	_stars=Decor.new();_stars.name="StageCardStars";put(content,_stars,Rect2(108,237,90,24));_stars.scale=Vector2(1.35,1.35)
	face(content,"title",Rect2(94,269,150,25));_status=caption(content,"",Rect2(87,269,164,23),13);_status.name="StageCardStatus";_status.add_theme_color_override("font_color",Color("3c7da3"))
	_start=action(content,"Start",Rect2(18,302,302,44),_start_selected,"green",21);_start.name="StageCardStart";_start.icon=UI.icon("play",19);_start.add_theme_color_override("font_color",Color.WHITE);_start.add_theme_color_override("font_hover_color",Color.WHITE);_start.add_theme_color_override("font_pressed_color",Color.WHITE);_start.add_theme_color_override("icon_normal_color",Color.WHITE)
	face(design,"card",Rect2(16,426,488,65))
	var rail=ColorRect.new();rail.color=Color("6acdf0");rail.mouse_filter=Control.MOUSE_FILTER_IGNORE;put(design,rail,Rect2(40,455,440,5))
	for i in range(1,11):
		var b=action(design,"%02d"%i,Rect2(26+(i-1)*48,441,34,34),_select.bind(i));b.name="StagePopupChoice%02d"%i;b.set_meta("stage",i);_choices.append(b)
		_checks.append(art(design,Look.symbol("check"),Rect2(0,0,15,15)))
	_crown=art(design,Look.symbol("crown"),Rect2(0,0,27,27));_crown.name="SelectedStageCrown"
	var back=action(design,"Return to Game",Rect2(27,506,223,40),func():resume_requested.emit(),"button",14);back.name="StagePickerReturn";back.icon=UI.icon("undo",18)
	var home=action(design,"Main Menu",Rect2(270,506,223,40),func():main_menu_requested.emit(),"button",14);home.name="StagePickerMainMenu";home.icon=UI.icon("home",18)
	resized.connect(_fit);_select(selected_stage);_fit.call_deferred()

func _process(_delta: float) -> void:
	if not get_tree().paused:return
	var focus=get_viewport().gui_get_focus_owner()
	if focus==null or not is_ancestor_of(focus):
		var target=_start if not _start.disabled else find_child("StagePickerReturn",true,false)
		target.grab_focus()

func _center() -> void:
	_panel.position=((size-_panel.size)*.5).round()

func _fit() -> void:
	if not is_instance_valid(_panel):return
	_panel.custom_minimum_size.y=PANEL_SIZE.y
	_panel.size=Vector2(minf(PANEL_SIZE.x,size.x-32),PANEL_SIZE.y)
	_center()

func _thumbnail(stage: int) -> Texture2D:
	if stage==1:return preload("res://Refrence image.png")
	if stage==4:return preload("res://Stage4Assets/Products/Cooktops/JUASDS17WS.png")
	if not P.is_level_unlocked(stage):return UI.icon("lock")
	var atlas=preload("res://MenuAssets/mission-thumbnails.webp");var tile=AtlasTexture.new();var index=stage-2
	tile.atlas=atlas;tile.region=Rect2(Vector2(index%4,floori(float(index)/4))*Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0),Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0));tile.filter_clip=true;return tile

func _select(stage: int) -> void:
	selected_stage=stage;set_meta("selected_stage",stage)
	var available=P.is_level_unlocked(stage)
	_number.text="%02d"%stage;_title.text=UI.text("Stage %02d")%stage;_image.texture=_thumbnail(stage)
	_caption.text=UI.text(["Draw the layout","Plan Q&A","Kitchen Selection"][stage-1]) if stage<=3 else (preload("res://Stage4Assets/ProductCatalog.gd").text("Kitchen parts") if stage==4 else UI.text("Coming soon"))
	_stars.visible=stage<=3;_stars.earned=int(Rating.best(stage).get("stars",0));_stars.set_meta("stars",_stars.earned);_stars.queue_redraw()
	_status.text=UI.text("Completed") if P.is_completed(stage) else (UI.text("Ready") if available else UI.text("Coming soon"))
	_start.disabled=not available;_start.text=UI.text("Start") if available else UI.text("Coming soon");_start_skin()
	for b in _choices:
		var n=int(b.get_meta("stage"));var locked=not P.is_level_unlocked(n);var active=n==stage;var done=P.is_completed(n)
		var side=48 if active else 34
		b.position=Vector2(43+(n-1)*48-side*.5,458-side*.5);b.size=Vector2.ONE*side
		b.add_theme_font_size_override("font_size",18 if active else 13)
		b.text="" if locked else "%02d"%n;b.icon=UI.icon("lock",15) if locked else null;b.add_theme_constant_override("icon_max_width",15)
		Look.style_button(b,"blue" if active else ("locked" if locked else ("done" if done else "button")))
		for state in ["font_color","font_hover_color","font_pressed_color"]:b.add_theme_color_override(state,Color.WHITE if active else UI.INK)
		var check=_checks[n-1];check.visible=done and not active;check.position=b.position+Vector2(23,24)
	_crown.visible=available;_crown.position=Vector2(43+(stage-1)*48-13.5,411)
	var target=_start if available else find_child("StagePickerReturn",true,false);target.grab_focus.call_deferred();_fit.call_deferred()
func _start_skin() -> void:
	Look.style_button(_start,"green")
func _start_selected() -> void:
	if P.is_level_unlocked(selected_stage):stage_requested.emit(selected_stage)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):resume_requested.emit();get_viewport().set_input_as_handled()
