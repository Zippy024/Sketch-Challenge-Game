extends PanelContainer
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
var current_stage: int=1
var compact: bool=false
var in_header: bool=false
var _state: int=-1
var _elapsed: float=0.0

func _ready() -> void:
	name="LevelReachTrack"
	custom_minimum_size.y=40
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxEmpty.new()
	style.set_content_margin_all(2)
	add_theme_stylebox_override("panel",style)
	_rebuild()

func _process(delta: float) -> void:
	_elapsed+=delta
	if _elapsed<0.2:return
	_elapsed=0
	var state:=int(Progress.is_completed(1))+2*int(Progress.is_completed(2))+4*int(Progress.is_completed(3))
	if state!=_state:_rebuild()

func _rebuild() -> void:
	_state=int(Progress.is_completed(1))+2*int(Progress.is_completed(2))+4*int(Progress.is_completed(3))
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",5)
	add_child(row)
	for n in range(1,4 if compact else 11):
		var point:=PanelContainer.new()
		point.name="ReachNode%02d"%n
		var done:=Progress.is_completed(n)
		var active:=n==current_stage
		var locked:=not Progress.is_level_unlocked(n)
		point.set_meta("stage",n)
		point.set_meta("completed",done)
		point.set_meta("current",active)
		point.set_meta("locked",locked)
		point.custom_minimum_size=Vector2(106 if active else 48,36)
		point.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		point.size_flags_stretch_ratio=1.35 if active else 1.0
		point.mouse_filter=Control.MOUSE_FILTER_PASS
		point.tooltip_text=UI.text("Stage %d")%n+"\n"+UI.text("Coming soon" if locked else ("Completed" if done else "Ready"))
		var style:=UI.box(Color("078a9c") if active else (Color("badce5") if locked else Color("d0e9ee")),Color("56b9c8") if active else Color("8fb7c6"),9,4)
		style.shadow_size=0
		point.add_theme_stylebox_override("panel",style)
		row.add_child(point)
		var content:=HBoxContainer.new()
		content.alignment=BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation",5)
		point.add_child(content)
		if locked or done:
			var icon:=TextureRect.new()
			icon.texture=UI.icon("lock" if locked else "check")
			icon.modulate=Color.WHITE if active else (Color("53748a") if locked else Color("087e7f"))
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size=Vector2(13,13)
			icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
			content.add_child(icon)
		var caption:=UI.inline_label(UI.text("Stage %d")%n if active else "%02d"%n,13,true)
		caption.name="CurrentStageLabel" if active else "ReachStageLabel"
		caption.set_meta("locale_ignore",not active)
		caption.add_theme_color_override("font_color",Color.WHITE if active else UI.INK)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(caption)
