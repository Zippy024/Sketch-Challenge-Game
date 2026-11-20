extends Control
signal finished
const UI = preload("res://KitchenUI.gd")
const Aqua = preload("res://AquaStyle.gd")
var _bar: ProgressBar
var _caption: Label
var _logo: TextureRect
var _footer: Panel
var _elapsed: float = 0.0
func _ready() -> void:
	name = "KitchenLoadingScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.make_theme()
	var photo := TextureRect.new()
	photo.name = "OriginalLoadingKitchen"
	photo.texture = Aqua.artwork("res://LoadingAssets/AquaBuilder.png",preload("res://LoadingAssets/TealKitchen.webp"))
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_logo = UI.logo(0,0)
	add_child(_logo)
	_footer=Panel.new()
	_footer.add_theme_stylebox_override("panel",Aqua.surface(false,true))
	add_child(_footer)
	_bar = SegmentedBar.new()
	_bar.show_percentage = false
	for style in ["background","fill"]:
		_bar.add_theme_stylebox_override(style,StyleBoxEmpty.new())
	_footer.add_child(_bar)
	_caption = UI.label("Loading...",22,true,UI.INK)
	_caption.name = "LoadingCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	_footer.add_child(_caption)
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	_logo.size = Vector2(minf(size.x*0.39,480),size.y*0.28)
	_logo.position = Vector2((size.x-_logo.size.x)/2,size.y*0.018)
	_footer.size=Vector2(minf(size.x*.62,820),66)
	_footer.position=Vector2((size.x-_footer.size.x)/2,size.y*.865)
	var caption_width:=minf(220,_footer.size.x*.36)
	_bar.position=Vector2(18,18)
	_bar.size=Vector2(_footer.size.x-caption_width-36,28)
	_caption.position=Vector2(_footer.size.x-caption_width-10,6)
	_caption.size=Vector2(caption_width,50)
func _process(delta: float) -> void:
	_elapsed += delta
	_logo.position.y=size.y*0.018+sin(_elapsed*1.3)*3.0
	var fraction := minf(_elapsed/2.1,1.0)
	_bar.value = fraction*100
	_caption.text = "Loading... %d%%"%roundi(fraction*100)
	if fraction>=1:
		set_process(false)
		finished.emit()
		queue_free()

class SegmentedBar extends ProgressBar:
	func _ready() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
		value_changed.connect(func(_value: float):queue_redraw())
	func _draw() -> void:
		var gap:=3.0
		var width: float=(size.x-gap*11)/12
		for i in range(12):
			var rect:=Rect2(i*(width+gap),0,width,size.y)
			UI.box(Color("d8edf4"),Color("a4d4e2"),6,0).draw(get_canvas_item(),rect)
			var fraction:=clampf(value/100.0*12-float(i),0,1)
			if fraction>0:
				rect.size.x*=fraction
				UI.box(Color("00bdc9"),Color("dcffff"),6,0).draw(get_canvas_item(),rect)
				draw_line(rect.position+Vector2(6,3),rect.position+Vector2(maxf(6,rect.size.x-6),3),Color("93ffff"),2,true)
