extends Control
# Click a small stage chip to preview its mission without leaving the game.
signal play_requested(stage_number: int)
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
const PHOTOS=[
	preload("res://reference_sketch.png"),
	preload("res://reference_ps_stage2.png"),
	preload("res://MenuAssets/Level3.png"),
	preload("res://MenuAssets/Level4.png"),
	preload("res://MenuAssets/Level5.png"),
	preload("res://MenuAssets/Level6.png")
]
var selected_stage: int=1
var current_stage: int=1
var _title: Label
var _image: TextureRect
var _description: Label
var _stars: Label
var _status: Label
var _play: Button
var _buttons: Array[Button]=[]

func _ready() -> void:
	name="StageMiniPreview"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	process_mode=Node.PROCESS_MODE_ALWAYS
	z_index=100
	var shade:=ColorRect.new()
	shade.name="StagePreviewBackdrop"
	shade.color=Color(0.02,0.12,0.25,0.61)
	shade.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:queue_free()
	)
	var center:=CenterContainer.new()
	center.mouse_filter=Control.MOUSE_FILTER_PASS
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board:=PanelContainer.new()
	board.name="StagePreviewCard"
	board.custom_minimum_size=Vector2(690,462)
	board.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	var style:=UI.box(Color("edf9ff"),Color("8edbfa"),27,18)
	style.set_border_width_all(3)
	style.shadow_color=Color(0.0,0.13,0.38,0.35)
	style.shadow_size=15
	board.add_theme_stylebox_override("panel",style)
	center.add_child(board)
	var body:=VBoxContainer.new()
	body.add_theme_constant_override("separation",13)
	board.add_child(body)
	var header:=HBoxContainer.new()
	body.add_child(header)
	var heading:=UI.label("STAGE PREVIEW",16,true,Color("197cb8"))
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var close:=_button("✕",false,_close)
	close.name="CloseStageMiniPreview"
	close.custom_minimum_size=Vector2(40,38)
	header.add_child(close)
	var center_row:=HBoxContainer.new()
	center_row.add_theme_constant_override("separation",16)
	center_row.custom_minimum_size.y=258
	body.add_child(center_row)
	var art:=PanelContainer.new()
	art.custom_minimum_size.x=290
	art.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	art.add_theme_stylebox_override("panel",UI.box(Color.WHITE,Color("b9def3"),18,7))
	center_row.add_child(art)
	_image=TextureRect.new()
	_image.name="StagePreviewArtwork"
	_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.add_child(_image)
	var info:=VBoxContainer.new()
	info.custom_minimum_size.x=300
	info.add_theme_constant_override("separation",9)
	info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center_row.add_child(info)
	_title=UI.label("",38,true,Color("067fe0"))
	info.add_child(_title)
	_description=UI.label("",18,true,Color("123c66"))
	info.add_child(_description)
	_stars=UI.label("",28,true,Color("e9ad27"))
	info.add_child(_stars)
	_status=UI.label("",16,true,Color("347d95"))
	info.add_child(_status)
	info.add_spacer(false)
	_play=_button("Play Stage",true,func():play_requested.emit(selected_stage))
	_play.name="StagePreviewPlay"
	_play.custom_minimum_size.y=44
	info.add_child(_play)
	var bottom:=HBoxContainer.new()
	bottom.name="StagePreviewNumberStrip"
	bottom.add_theme_constant_override("separation",4)
	bottom.alignment=BoxContainer.ALIGNMENT_CENTER
	body.add_child(bottom)
	for n in range(1,11):
		var button:=_button("%02d"%n,false,_choose.bind(n))
		button.name="StagePreviewSelect%02d"%n
		button.custom_minimum_size=Vector2(50,38)
		bottom.add_child(button)
		_buttons.append(button)
	var foot:=HBoxContainer.new()
	foot.alignment=BoxContainer.ALIGNMENT_END
	body.add_child(foot)
	var back:=_button("Return to Game",false,_close)
	back.name="StagePreviewReturn"
	back.custom_minimum_size=Vector2(170,38)
	foot.add_child(back)
	_refresh()

func _button(value: String,primary: bool,action: Callable) -> Button:
	var button:=Button.new()
	button.text=value
	button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font",UI.font(true))
	button.add_theme_font_size_override("font_size",16)
	for state in ["normal","hover","pressed","disabled"]:
		var fill:=Color("008ee9") if primary else Color("f8fcff")
		if state=="hover":fill=Color("14b9fa") if primary else Color("dbf5ff")
		if state=="pressed":fill=Color("007ed6") if primary else Color("d6edfa")
		if state=="disabled":fill=Color("dceaf3")
		var style:=UI.box(fill,Color("61c7ed") if primary else Color("9bc8ea"),20,6)
		style.set_border_width_all(2)
		style.shadow_size=4
		button.add_theme_stylebox_override(state,style)
	for key in ["font_color","font_hover_color","font_pressed_color"]:
		button.add_theme_color_override(key,Color.WHITE if primary else Color("153c72"))
	button.add_theme_color_override("font_disabled_color",Color("688aa1"))
	button.pressed.connect(action)
	return button

func _choose(number: int) -> void:
	selected_stage=number
	_refresh()

func _refresh() -> void:
	var captions=["Draw the layout","Answer the customer","Kitchen type and 3D parts","Choose kitchen components"]
	_title.text="STAGE %02d"%selected_stage
	_description.text=UI.text(captions[selected_stage-1]) if selected_stage<=4 else UI.text("Coming soon")
	_image.texture=PHOTOS[mini(selected_stage-1,PHOTOS.size()-1)]
	var best: int=int(Rating.best(selected_stage).get("stars",0)) if selected_stage<=3 else 0
	_stars.text="★".repeat(best)+"☆".repeat(3-best)
	_status.text=UI.text("Completed") if Progress.is_completed(selected_stage) else (UI.text("Locked / Coming soon") if not Progress.is_level_unlocked(selected_stage) else UI.text("Ready to play"))
	_play.disabled=not Progress.is_level_unlocked(selected_stage)
	_play.text=UI.text("Return to this stage") if selected_stage==current_stage else (UI.text("Play Stage %d")%selected_stage)
	for i in range(_buttons.size()):
		var button:=_buttons[i]
		var chosen:=i+1==selected_stage
		for state in ["normal","hover"]:
			var base:=button.get_theme_stylebox(state) as StyleBoxFlat
			if base:
				var surface:=base.duplicate() as StyleBoxFlat
				surface.bg_color=Color("c5f4ff") if chosen else Color("f7fcff")
				surface.border_color=Color("05a5e7") if chosen else Color("b1d7e8")
				button.add_theme_stylebox_override(state,surface)

func _close() -> void:
	queue_free()

func _unhandled_key_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
