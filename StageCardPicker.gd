extends Control
signal resume_requested
signal stage_requested(stage: int)
signal main_menu_requested
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
const Decor=preload("res://MenuAssets/MissionDecor.gd")
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

func _ready() -> void:
	name="StageCardPicker";theme=UI.make_theme();mouse_filter=Control.MOUSE_FILTER_STOP
	set_meta("locale_ignore",true)
	var shade=ColorRect.new();shade.color=Color(0.03,.13,.26,.48);add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel=PanelContainer.new();_panel.name="StagePickerPanel";var style=UI.box(Color("d8efff"),Color("80bce8"),24,14);style.set_border_width_all(2);style.shadow_size=10;style.shadow_color=Color(0,.12,.25,.25);_panel.add_theme_stylebox_override("panel",style);UI.Gloss.bind_panel(_panel,"panel",style);add_child(_panel);_panel.resized.connect(_center)
	var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",10);_panel.add_child(stack)
	var heading=PanelContainer.new();var heading_style=UI.box(UI.TEAL,Color.WHITE,22,6);heading.add_theme_stylebox_override("panel",heading_style);UI.Gloss.bind_panel(heading,"primary",heading_style);stack.add_child(heading)
	var title=UI.label("Select a Level",21,true,Color.WHITE);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_child(title)
	var align=HBoxContainer.new();stack.add_child(align)
	var before=Control.new();before.size_flags_horizontal=Control.SIZE_EXPAND_FILL;align.add_child(before)
	var card=PanelContainer.new();card.name="StagePreviewCard";card.custom_minimum_size=Vector2(310,0);card.add_theme_stylebox_override("panel",UI.box(Color("f3fcff"),Color("87cbed"),16,10));align.add_child(card)
	var content=VBoxContainer.new();content.add_theme_constant_override("separation",4);card.add_child(content)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);content.add_child(row)
	var badge=PanelContainer.new();badge.custom_minimum_size=Vector2(44,30);var badge_style=UI.box(UI.TEAL,Color.WHITE,8,2);badge.add_theme_stylebox_override("panel",badge_style);UI.Gloss.bind_panel(badge,"primary",badge_style);row.add_child(badge)
	_number=UI.label("",19,true,Color.WHITE);_number.name="StageCardNumber";_number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;badge.add_child(_number)
	_title=UI.inline_label("",17,true);_title.name="StageCardTitle";_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;row.add_child(_title)
	var frame=PanelContainer.new();frame.add_theme_stylebox_override("panel",UI.box(Color.WHITE,Color("c2e0f0"),10,4));content.add_child(frame)
	_image=TextureRect.new();_image.name="StageCardImage";_image.custom_minimum_size.y=120;_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;frame.add_child(_image)
	_caption=UI.label("",15,true);_caption.name="StageCardCaption";_caption.custom_minimum_size.y=48;_caption.max_lines_visible=2;_caption.clip_text=true;_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(_caption)
	var star_slot=Control.new();star_slot.name="StageCardStarsSlot";star_slot.custom_minimum_size.y=25;content.add_child(star_slot)
	_stars=Decor.new();_stars.name="StageCardStars";star_slot.add_child(_stars);_stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_status=UI.inline_label("",13,true);_status.add_theme_color_override("font_color",UI.MUTED);_status.name="StageCardStatus";_status.custom_minimum_size.y=18;_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;content.add_child(_status)
	_start=UI.button("Start",_start_selected,true,0,17);_start.name="StageCardStart";_start.custom_minimum_size.y=34;_start.icon=UI.icon("play",16);UI.Gloss.disable_button(_start);_start.resized.connect(_start_skin);content.add_child(_start)
	var after=Control.new();after.size_flags_horizontal=Control.SIZE_EXPAND_FILL;align.add_child(after)
	var choices=HBoxContainer.new();choices.name="StageCardChoices";choices.add_theme_constant_override("separation",4);stack.add_child(choices)
	for i in range(1,11):
		var button=UI.button("%02d"%i,_select.bind(i),false,0,13);button.name="StagePopupChoice%02d"%i;button.set_meta("stage",i);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.custom_minimum_size.y=32;UI.Gloss.disable_button(button);choices.add_child(button);_choices.append(button)
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);stack.add_child(actions)
	var back=UI.button("Return to Game",func():resume_requested.emit(),false,0,14);back.name="StagePickerReturn";back.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(back)
	var home=UI.button("Main Menu",func():main_menu_requested.emit(),false,0,14);home.name="StagePickerMainMenu";home.icon=UI.icon("home",16);home.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(home)
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
	for button in _choices:
		var n=int(button.get_meta("stage"));var locked=not P.is_level_unlocked(n)
		button.text="" if locked else "%02d"%n;button.icon=UI.icon("lock",12) if locked else null;button.add_theme_constant_override("icon_max_width",12)
		for state in ["normal","hover","pressed","disabled"]:
			var style=StyleBoxTexture.new();style.texture=UI.Gloss.surface("primary" if n==stage else ("locked" if locked else "button"),44,32);style.set_content_margin_all(2);button.add_theme_stylebox_override(state,style)
		for state in ["font_color","font_hover_color","font_pressed_color"]:button.add_theme_color_override(state,Color.WHITE if n==stage else UI.INK)
	var focus_target=_start if available else find_child("StagePickerReturn",true,false)
	focus_target.grab_focus.call_deferred()
	_fit.call_deferred()

func _start_skin() -> void:
	if not is_instance_valid(_start):return
	for state in ["normal","hover","pressed","disabled"]:
		var style=StyleBoxTexture.new();style.texture=UI.Gloss.surface("button" if _start.disabled else "start",maxi(100,roundi(_start.size.x)),34);style.set_content_margin_all(3);_start.add_theme_stylebox_override(state,style)

func _start_selected() -> void:
	if P.is_level_unlocked(selected_stage):stage_requested.emit(selected_stage)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):resume_requested.emit();get_viewport().set_input_as_handled()
