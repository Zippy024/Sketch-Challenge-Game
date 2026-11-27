extends Control
const UI=preload("res://KitchenUI.gd")
const P=preload("res://GameProgress.gd")
const S=preload("res://Stage4Assets/StudioTheme.gd")
const Catalog=preload("res://Stage4Assets/ProductCatalog.gd")
const Plan=preload("res://Stage3Assets/ReferencePlanOverlay.gd")
var choices: Array[int]=[0,0,0,0]
var confirmed: Array[bool]=[false,false,false,false]
var active: int=-1
var pending: int=0
var _saved_view: Dictionary={}
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
	_saved_view=saved.view.duplicate(true)
	_update_cards()

func _text(key: String) -> String:return Catalog.text(key)

func _build() -> void:
	var page=UI.page(self,4,"Kitchen parts",_open_game_menu,_change_language)
	var columns=HBoxContainer.new();columns.name="Stage4Columns";columns.add_theme_constant_override("separation",18);columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;page.add_child(columns)
	var left=VBoxContainer.new();left.name="Stage4CustomerColumn";left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.size_flags_stretch_ratio=7;left.add_theme_constant_override("separation",12);columns.add_child(left)
	_customer(left);_reference(left)
	var catalog=UI.card_stack(columns,true);catalog.get_parent().name="Stage4CatalogPanel";catalog.get_parent().size_flags_stretch_ratio=13
	_build_catalog(catalog)

func _customer(parent: Control) -> void:
	var customer=UI.customer(parent)
	parent.get_child(parent.get_child_count()-1).name="Stage4CustomerCard"
	customer.question.text="…";customer.question.name="Stage4Dialogue"
	customer.question.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	customer.question.add_theme_font_size_override("font_size",24)

func _reference(parent: Control) -> void:
	var stack=UI.card_stack(parent,true);stack.get_parent().name="Stage4ReferenceCard"
	var title=UI.button("Reference Plan",_open_plan,false,160,18);UI.reference_heading(title);title.name="EnlargeStage4Plan";stack.add_child(title)
	var view=Plan.PlanView.new();view.name="Stage4ReferencePlan";view.custom_minimum_size=Vector2(0,180);view.size_flags_vertical=Control.SIZE_EXPAND_FILL;stack.add_child(view)

func _build_catalog(parent: Control) -> void:
	_main=VBoxContainer.new();_main.name="Stage4CategoryCatalog";_main.size_flags_vertical=Control.SIZE_EXPAND_FILL;_main.add_theme_constant_override("separation",10);parent.add_child(_main)
	var title=S.label(_text("Kitchen parts"),20);UI.decorate_heading(title);_main.add_child(title)
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
	_picker_heading=S.label("",19);UI.decorate_heading(_picker_heading);_picker.add_child(_picker_heading)
	_option_grid=GridContainer.new();_option_grid.name="Stage4FiveChoices";_option_grid.columns=3;_option_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;_option_grid.add_theme_constant_override("h_separation",9);_option_grid.add_theme_constant_override("v_separation",9);_picker.add_child(_option_grid)
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
		var heading=PanelContainer.new();var style=UI.box(Color("1c3c63"),Color.TRANSPARENT,7,3);style.set_border_width_all(0);style.shadow_size=0;heading.add_theme_stylebox_override("panel",style);UI.Gloss.bind_panel(heading,"navy",style);content.add_child(heading)
		var title=S.label(_text(Catalog.TITLES[category]),14);title.add_theme_color_override("font_color",Color.WHITE);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_child(title)
	var image=TextureRect.new();image.name="ProductImage";image.texture=Catalog.image(category,index);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.size_flags_vertical=Control.SIZE_EXPAND_FILL;image.custom_minimum_size.y=55;content.add_child(image)
	var caption=S.label(Catalog.caption(category,index) if summary else String.chr(65+index),14 if summary else 16);caption.name="ProductCaption";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.custom_minimum_size.y=38 if summary else 24;content.add_child(caption)
	button.tooltip_text=Catalog.caption(category,index);S.ignore_children(button)
	return button

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
	pending=index
	for i in range(5):S.card(_options[i],i==pending)

func cancel_selection() -> void:
	if active<0:return
	active=-1;_picker.hide();_main.show()

func use_selection() -> void:
	if active<0:return
	choices[active]=pending;confirmed[active]=true;active=-1;_picker.hide();_main.show();_update_cards();_save_session()

func _update_cards() -> void:
	for category in range(_cards.size()):
		_cards[category].find_child("ProductImage",true,false).texture=Catalog.image(category,choices[category])
		_cards[category].find_child("ProductCaption",true,false).text=Catalog.caption(category,choices[category])
		S.card(_cards[category],confirmed[category])
	_count.text="%d / 4"%confirmed.count(true)

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
	if _session_save_suspended:return
	P.save_stage4_selection(choices,confirmed,_saved_view)

func _suspend_session_save() -> void:_session_save_suspended=true

func _exit_tree() -> void:_save_session()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if active>=0:cancel_selection()
		elif not is_instance_valid(_pause_menu):_open_game_menu()
		get_viewport().set_input_as_handled()
