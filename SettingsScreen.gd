extends Control
signal home_requested
signal levels_requested
signal language_requested(language: String)
signal fullscreen_requested
signal volume_changed(value: float)
const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")
const Extras = preload("res://MenuExtras.gd")
var _design: Control
var _reset_armed: bool = false

func _ready() -> void:
	name="KitchenSettingsScreen"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	_build()
	resized.connect(_fit)

func _put(parent: Control, child: Control, rect: Rect2) -> void:
	parent.add_child(child)
	child.position=rect.position
	child.size=rect.size

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	UI.background(self)
	_design=Control.new()
	_design.size=Vector2(1440,810)
	add_child(_design)
	_put(_design,UI.logo(),Rect2(44,10,240,100))
	var title := UI.label("Settings",34,true)
	title.autowrap_mode=TextServer.AUTOWRAP_OFF
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_put(_design,title,Rect2(320,82,800,62))
	var panel := PanelContainer.new()
	panel.name="SettingsCard"
	panel.add_theme_stylebox_override("panel",UI.box(Color(0.96,0.99,1,0.95),Color.WHITE,26,26))
	_put(_design,panel,Rect2(300,158,840,548))
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",12)
	panel.add_child(stack)
	stack.add_child(UI.label("Language",18,true))
	var languages := UI.language_switcher(func(lang: String):
		language_requested.emit(lang)
		_reset_armed=false
		_build()
	,17)
	languages.name="SettingsLanguages"
	languages.custom_minimum_size.y=46
	for button in languages.get_children():
		button.custom_minimum_size.x=0
		button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stack.add_child(languages)
	_divider(stack)
	var volume_heading := HBoxContainer.new()
	stack.add_child(volume_heading)
	var volume_label := UI.label("Game Volume",18,true)
	volume_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	volume_heading.add_child(volume_label)
	var percentage := UI.inline_label("%d%%"%roundi(Extras.volume()*100),16,true)
	percentage.set_meta("locale_ignore",true)
	percentage.custom_minimum_size.x=48
	volume_heading.add_child(percentage)
	var volume := HSlider.new()
	volume.name="SettingsVolume"
	volume.min_value=0
	volume.max_value=1
	volume.step=0.05
	volume.value=Extras.volume()
	volume.custom_minimum_size.y=28
	volume.value_changed.connect(func(value: float):
		percentage.text="%d%%"%roundi(value*100)
		volume_changed.emit(value)
	)
	var track := UI.box(Color("c6dce5"),Color.TRANSPARENT,4,0)
	track.content_margin_top=3
	track.content_margin_bottom=3
	track.shadow_size=0
	volume.add_theme_stylebox_override("slider",track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color=UI.TEAL
	volume.add_theme_stylebox_override("grabber_area",fill)
	volume.add_theme_stylebox_override("grabber_area_highlight",fill)
	stack.add_child(volume)
	var mute_row := HBoxContainer.new()
	mute_row.add_theme_constant_override("separation",16)
	stack.add_child(mute_row)
	var mute_label := UI.label("Mute all game audio",16)
	mute_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	mute_row.add_child(mute_label)
	var mute := UI.button("On" if Extras.muted() else "Off",Callable(),Extras.muted(),100,15)
	mute.name="SettingsMute"
	mute.toggle_mode=true
	mute.button_pressed=Extras.muted()
	mute.toggled.connect(func(value: bool):
		Extras.set_muted(value)
		Extras.apply_audio()
		mute.text=UI.text("On" if value else "Off")
		UI.style_button(mute,value,15)
	)
	mute_row.add_child(mute)
	_divider(stack)
	var display_row := HBoxContainer.new()
	display_row.add_theme_constant_override("separation",20)
	stack.add_child(display_row)
	var display_label := UI.label("Display",18,true)
	display_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	display_row.add_child(display_label)
	var fullscreen := UI.button("Toggle Fullscreen",func():fullscreen_requested.emit(),false,260,15)
	fullscreen.name="SettingsFullscreen"
	fullscreen.custom_minimum_size.y=44
	display_row.add_child(fullscreen)
	_divider(stack)
	stack.add_child(UI.label("Saved Game Progress",18,true))
	var saved_row := HBoxContainer.new()
	saved_row.add_theme_constant_override("separation",24)
	stack.add_child(saved_row)
	var saved_hint := UI.label("Reset saved stage progress; all available stages remain playable.",14,false,UI.MUTED)
	saved_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	saved_row.add_child(saved_hint)
	var reset := UI.button("Reset Level Progress",Callable(),false,260,14)
	reset.name="SettingsReset"
	reset.custom_minimum_size.y=50
	reset.pressed.connect(func():
		if not _reset_armed:
			_reset_armed=true
			reset.text=UI.text("Confirm Reset")
			return
		Progress.reset_progress()
		levels_requested.emit()
	)
	saved_row.add_child(reset)
	var back := UI.button("Go to Main Menu",func():home_requested.emit(),true,0,18)
	back.name="SettingsHome"
	_put(_design,back,Rect2(540,734,360,48))
	_fit()

func _divider(parent: Control) -> void:
	var line := ColorRect.new()
	line.color=Color("d6e6ee")
	line.custom_minimum_size.y=1
	line.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _fit() -> void:
	if not is_instance_valid(_design):return
	var factor := minf(size.x/1440.0,size.y/810.0)
	_design.scale=Vector2.ONE*factor
	_design.position=(size-Vector2(1440,810)*factor)*0.5
