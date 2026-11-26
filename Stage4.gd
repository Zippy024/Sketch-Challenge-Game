extends Control
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
const S=preload("res://Stage4Assets/StudioTheme.gd")
const Catalog=preload("res://Stage4Assets/ProductCatalog.gd")
const Kitchen=preload("res://Stage4Assets/SelectionKitchen.gd")
const Plan=preload("res://Stage3Assets/ReferencePlanOverlay.gd")
var choices: Array[int]=[0,0,0,0]
var confirmed: Array[bool]=[false,false,false,false]
var active: int=-1
var pending: int=0
var model: Control
var _main: VBoxContainer
var _picker: VBoxContainer
var _option_grid: GridContainer
var _picker_heading: Label
var _breadcrumb: Label
var _cards: Array[Button]=[]
var _options: Array[Button]=[]
var _count: Label
var _pause_menu: Control
var _session_save_suspended: bool=false
var _language: String

func _ready() -> void:
	name="Stage4";theme=UI.make_theme();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_language=P.get_language()
	var saved=P.stage4_selection();choices.assign(saved.choices);confirmed.assign(saved.confirmed)
	_build()
	model.apply_view_state(saved.view)
	_update_cards()

func _text(key: String) -> String:return Catalog.text(key)

func _build() -> void:
	var background=TextureRect.new();background.name="Stage4StudioBackground";background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	background.texture=S.vector('<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="810"><defs><radialGradient id="g"><stop stop-color="#e9fbff"/><stop offset="1" stop-color="#70d3f4"/></radialGradient></defs><rect width="1440" height="810" fill="url(#g)"/></svg>')
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;add_child(background);background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
	var root=VBoxContainer.new();root.add_theme_constant_override("separation",12);margin.add_child(root)
	_header(root)
	var columns=HBoxContainer.new();columns.name="Stage4Columns";columns.add_theme_constant_override("separation",10);columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;root.add_child(columns)
	var left=VBoxContainer.new();left.name="Stage4CustomerColumn";left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=24;left.add_theme_constant_override("separation",10);columns.add_child(left)
	_customer(left);_reference(left)
	var center=S.panel(columns,"Stage4CatalogPanel","panel",10);center.get_parent().size_flags_stretch_ratio=25
	_build_catalog(center)
	var right=S.panel(columns,"Stage4PreviewPanel","panel",10);right.get_parent().size_flags_stretch_ratio=51
	_build_preview(right)

func _header(parent: Control) -> void:
	var card=PanelContainer.new();card.name="GameHeader";card.custom_minimum_size.y=70
	var style=S.face("header");style.set_content_margin_all(10);style.content_margin_bottom=13;card.add_theme_stylebox_override("panel",style);parent.add_child(card)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);card.add_child(row)
	var logo=UI.logo(140,44);logo.name="Stage4OriginalLogo";row.add_child(logo)
	var stages=HBoxContainer.new();stages.name="LevelReachBar";stages.size_flags_horizontal=Control.SIZE_EXPAND_FILL;stages.add_theme_constant_override("separation",5);row.add_child(stages)
	for stage in range(1,11):
		var caption=_text("Stage 4") if stage==4 else "%02d"%stage
		var button=S.button(caption,_go_stage.bind(stage),stage==4,82 if stage==4 else 42,36,12)
		button.name="ReachNode%02d"%stage;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.size_flags_stretch_ratio=1.6 if stage==4 else 1.0
		button.disabled=not P.is_level_unlocked(stage)
		button.set_meta("stage",stage);button.set_meta("locked",button.disabled);button.set_meta("completed",P.is_completed(stage));button.set_meta("current",stage==4)
		if stage==4 or button.disabled or P.is_completed(stage):
			button.icon=UI.icon("play" if stage==4 else ("lock" if button.disabled else "check"))
			button.add_theme_color_override("icon_normal_color",Color.WHITE if stage==4 else Color("27bc5c"));button.add_theme_color_override("icon_disabled_color",Color("527997"))
		stages.add_child(button)
	var language=MenuButton.new();language.name="HeaderLanguage";language.text={"jp":"日本語","mm":"မြန်မာ","en":"English"}[_language]
	language.set_meta("locale_ignore",true);language.flat=false;language.custom_minimum_size=Vector2(112,36);language.add_theme_font_override("font",UI.font(true));language.add_theme_font_size_override("font_size",12)
	language.add_theme_constant_override("icon_max_width",18);language.add_theme_constant_override("h_separation",6)
	for state in ["normal","hover","pressed"]:language.add_theme_stylebox_override(state,S.face("button",state))
	language.add_theme_color_override("font_color",S.INK);S.icon(language,"globe");row.add_child(language)
	language.resized.connect(S.fit_button.bind(language))
	var chevron=TextureRect.new();chevron.texture=UI.icon("chevron_down");chevron.modulate=S.INK;chevron.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;chevron.mouse_filter=Control.MOUSE_FILTER_IGNORE;language.add_child(chevron)
	chevron.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT);chevron.offset_left=-17;chevron.offset_right=-7;chevron.offset_top=-7;chevron.offset_bottom=3
	for label_text in ["日本語","မြန်မာ","English"]:language.get_popup().add_item(label_text)
	UI.style_language_popup(language.get_popup())
	language.get_popup().id_pressed.connect(func(index: int):_change_language(["jp","mm","en"][index]))
	var home=S.button(_text("Home"),_home,false,78,36,12);home.name="GameHomeButton";S.icon(home,"home");row.add_child(home)
	var menu=S.button(_text("Menu"),_open_game_menu,false,78,36,12);menu.name="GameMenuButton";S.icon(menu,"menu");row.add_child(menu)

func _customer(parent: Control) -> void:
	var stack=S.panel(parent,"Stage4CustomerCard","panel",10)
	var row=HBoxContainer.new();row.add_theme_constant_override("separation",10);stack.add_child(row)
	var identity=VBoxContainer.new();identity.custom_minimum_size.x=104;identity.add_theme_constant_override("separation",5);row.add_child(identity)
	var portrait=UI.portrait();portrait.custom_minimum_size=Vector2(104,104);identity.add_child(portrait)
	var plate=PanelContainer.new();plate.name="CustomerNamePlate";plate.add_theme_stylebox_override("panel",UI.customer_plate());identity.add_child(plate)
	var customer=S.label(_text("Ms. Hosokawa"),11);customer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;plate.add_child(customer)
	var speech=VBoxContainer.new();speech.size_flags_horizontal=Control.SIZE_EXPAND_FILL;speech.add_theme_constant_override("separation",7);row.add_child(speech)
	var request=S.panel(speech,"Stage4RequestHeading","speech",8);request.add_child(S.label(_text("Customer Request"),12))
	var bubble=S.panel(speech,"Stage4Conversation","speech",10);bubble.get_parent().size_flags_vertical=Control.SIZE_EXPAND_FILL
	var placeholder=S.label("…",24);placeholder.name="Stage4Dialogue";placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;placeholder.size_flags_vertical=Control.SIZE_EXPAND_FILL;bubble.add_child(placeholder)

func _reference(parent: Control) -> void:
	var stack=S.panel(parent,"Stage4ReferenceCard","button",10);stack.get_parent().size_flags_vertical=Control.SIZE_EXPAND_FILL
	var heading=HBoxContainer.new();stack.add_child(heading)
	var title=S.label(_text("Reference Plan"),17);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	var enlarge=S.button("↗",_open_plan,false,32,30,20);enlarge.name="EnlargeStage4Plan";heading.add_child(enlarge)
	var view=Plan.PlanView.new();view.name="Stage4ReferencePlan";view.custom_minimum_size=Vector2(0,180);view.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(view)

func _build_catalog(parent: Control) -> void:
	_main=VBoxContainer.new();_main.name="Stage4CategoryCatalog";_main.size_flags_vertical=Control.SIZE_EXPAND_FILL;_main.add_theme_constant_override("separation",10);parent.add_child(_main)
	_main.add_child(S.label(_text("Kitchen parts"),20))
	var grid=GridContainer.new();grid.columns=2;grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);_main.add_child(grid)
	for category in range(4):
		var button=_product_card(grid,category,choices[category],true);button.name="Stage4Category%d"%category;button.pressed.connect(open_picker.bind(category));_cards.append(button)
	var footer=HBoxContainer.new();footer.add_theme_constant_override("separation",10);_main.add_child(footer)
	_count=S.label("0 / 4",20);_count.custom_minimum_size.x=64;_count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;footer.add_child(_count)
	var check=S.button(_text("Check Answer"),Callable(),true,0,42,14);check.name="Stage4CheckAnswer";check.size_flags_horizontal=Control.SIZE_EXPAND_FILL;check.disabled=true;footer.add_child(check)
	_picker=VBoxContainer.new();_picker.name="Stage4ProductPicker";_picker.size_flags_vertical=Control.SIZE_EXPAND_FILL;_picker.add_theme_constant_override("separation",9);_picker.hide();parent.add_child(_picker)
	var trail=HBoxContainer.new();trail.add_theme_constant_override("separation",8);_picker.add_child(trail)
	var back=S.button("←",cancel_selection,false,32,32,18);back.name="Stage4BackFromPicker";trail.add_child(back)
	_breadcrumb=S.label("",13);_breadcrumb.size_flags_horizontal=Control.SIZE_EXPAND_FILL;trail.add_child(_breadcrumb)
	_picker_heading=S.label("",19);_picker.add_child(_picker_heading)
	_option_grid=GridContainer.new();_option_grid.name="Stage4FiveChoices";_option_grid.columns=2;_option_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;_option_grid.add_theme_constant_override("h_separation",9);_option_grid.add_theme_constant_override("v_separation",9);_picker.add_child(_option_grid)
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",8);_picker.add_child(actions)
	var cancel=S.button(_text("Cancel"),cancel_selection,false,0,42,13);cancel.name="Stage4CancelSelection";cancel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(cancel)
	var apply=S.button(_text("Use Selection"),use_selection,true,0,42,13);apply.name="Stage4UseSelection";apply.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(apply)

func _product_card(parent: Control,category: int,index: int,summary: bool) -> Button:
	var button=Button.new();button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.size_flags_vertical=Control.SIZE_EXPAND_FILL;button.custom_minimum_size=Vector2(0,130 if summary else 118);button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	S.card(button);parent.add_child(button)
	var margin=MarginContainer.new();button.add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,4)
	var content=VBoxContainer.new();content.add_theme_constant_override("separation",3);margin.add_child(content)
	if summary:
		var heading=PanelContainer.new();var style=UI.box(Color("1c3c63"),Color.TRANSPARENT,7,3);style.set_border_width_all(0);style.shadow_size=0;heading.add_theme_stylebox_override("panel",style);content.add_child(heading)
		var title=S.label(_text(Catalog.TITLES[category]),14);title.add_theme_color_override("font_color",Color.WHITE);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_child(title)
	var image=TextureRect.new();image.name="ProductImage";image.texture=Catalog.image(category,index);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.custom_minimum_size.y=55;content.add_child(image)
	var caption=S.label(Catalog.caption(category,index) if summary else String.chr(65+index),12 if summary else 16);caption.name="ProductCaption";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.custom_minimum_size.y=38 if summary else 24;content.add_child(caption)
	button.tooltip_text=Catalog.caption(category,index);S.ignore_children(button)
	return button

func _build_preview(parent: Control) -> void:
	var heading=HBoxContainer.new();heading.add_theme_constant_override("separation",5);parent.add_child(heading)
	var title=S.label(_text("3D Kitchen Preview"),19);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(title)
	for action in ["3D","Front","Rotate","Zoom −","Zoom +"]:
		var button=S.button(_text(action),_view_action.bind(action),action=="3D",40 if action=="3D" else 53,32,11);button.name={"3D":"Stage4View3D","Front":"Stage4ViewFront","Rotate":"Stage4Rotate","Zoom −":"Stage4ZoomOut","Zoom +":"Stage4ZoomIn"}[action]
		if action in ["Rotate","Zoom −","Zoom +"]:S.icon(button,{"Rotate":"undo","Zoom −":"zoomout","Zoom +":"zoom"}[action])
		if action=="Rotate":button.toggle_mode=true
		heading.add_child(button)
	model=Kitchen.new();model.name="Stage4Kitchen3D";model.choices=choices.duplicate();model.custom_minimum_size=Vector2(0,260);model.size_flags_vertical=Control.SIZE_EXPAND_FILL;parent.add_child(model)
	var hint=S.label(_text("Drag to rotate · Scroll to zoom"),11,false);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;parent.add_child(hint)

func open_picker(category: int) -> void:
	if active>=0:cancel_selection()
	active=category;pending=choices[category]
	for child in _option_grid.get_children():_option_grid.remove_child(child);child.queue_free()
	_options.clear();_breadcrumb.text=_text(Catalog.TITLES[category]);_picker_heading.text=_text(["Choose a sink","Choose a faucet","Choose a hood","Choose a cooktop"][category])
	for index in range(5):
		var button=_product_card(_option_grid,category,index,false);button.name="Stage4Option%d"%index;button.pressed.connect(preview_selection.bind(index));S.card(button,index==pending);_options.append(button)
	_main.hide();_picker.show();_options[pending].grab_focus()

func preview_selection(index: int) -> void:
	if active<0 or index<0 or index>=5:return
	pending=index;model.set_product(active,index)
	for i in range(5):S.card(_options[i],i==pending)

func cancel_selection() -> void:
	if active<0:return
	model.set_product(active,choices[active]);active=-1;_picker.hide();_main.show()

func use_selection() -> void:
	if active<0:return
	choices[active]=pending;confirmed[active]=true;active=-1;_picker.hide();_main.show();_update_cards();_save_session()

func _update_cards() -> void:
	for category in range(_cards.size()):
		_cards[category].find_child("ProductImage",true,false).texture=Catalog.image(category,choices[category])
		_cards[category].find_child("ProductCaption",true,false).text=Catalog.caption(category,choices[category])
		S.card(_cards[category],confirmed[category])
	_count.text="%d / 4"%confirmed.count(true)

func _view_action(action: String) -> void:
	if action=="Rotate":model.rotating=not model.rotating
	elif action in ["3D","Front"]:model.set_view("perspective" if action=="3D" else "front")
	elif action=="Zoom −":model.zoom_by(.2)
	else:model.zoom_by(-.2)
	if action in ["3D","Front"]:
		for entry in [["Stage4View3D","3D"],["Stage4ViewFront","Front"]]:
			var button=find_child(entry[0],true,false) as Button;var selected=entry[1]==action
			button.set_meta("studio_primary",selected)
			for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:button.add_theme_color_override(state,Color.WHITE if selected else S.INK)
			S.fit_button(button)

func _open_plan() -> void:add_child(Plan.new())

func _change_language(language: String) -> void:
	_save_session();P.set_language(language);get_tree().reload_current_scene()

func _go_stage(stage: int) -> void:
	if stage==4 or not P.is_level_unlocked(stage):return
	_save_session();_session_save_suspended=true;P.open_stage(stage);P.launch_from_level_menu=stage==1;get_tree().change_scene_to_file(P.scene_for_stage(stage))

func _home() -> void:
	_save_session();P.show_home_on_open=true;get_tree().change_scene_to_file("res://GameMenu.tscn")

func _open_game_menu() -> void:
	if is_instance_valid(_pause_menu):return
	_save_session()
	var overlay=preload("res://GameMenu.tscn").instantiate();overlay.is_pause_overlay=true;overlay.pause_level=4;overlay.process_mode=Node.PROCESS_MODE_ALWAYS;overlay.resume_requested.connect(_resume_from_game_menu)
	_pause_menu=overlay;add_child(overlay);overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);get_tree().paused=true

func _resume_from_game_menu() -> void:
	get_tree().paused=false
	if is_instance_valid(_pause_menu):_pause_menu.queue_free()
	_pause_menu=null
	if _language!=P.get_language():get_tree().reload_current_scene()

func _save_session() -> void:
	if _session_save_suspended or not is_instance_valid(model):return
	P.save_stage4_selection(choices,confirmed,model.view_state())

func _suspend_session_save() -> void:_session_save_suspended=true

func _exit_tree() -> void:_save_session()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if active>=0:cancel_selection()
		elif not is_instance_valid(_pause_menu):_open_game_menu()
		get_viewport().set_input_as_handled()
