extends Control
signal finished
const UI = preload("res://KitchenUI.gd")
const Aqua = preload("res://AquaStyle.gd")
var _caption: Label
var _logo: TextureRect
var _footer: Panel
var _accents: LoadingAccents
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
	_accents=LoadingAccents.new()
	add_child(_accents)
	_accents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_footer=Panel.new()
	_footer.add_theme_stylebox_override("panel",Aqua.surface(false,false,58))
	add_child(_footer)
	_caption = UI.label("",24,true,UI.INK)
	_caption.name = "LoadingCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	_footer.add_child(_caption)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption.offset_top=-3
	_caption.offset_bottom=-5
	_caption.text="Loading... 0%"
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	_logo.size = Vector2(minf(size.x*0.39,480),size.y*0.28)
	_logo.position = Vector2((size.x-_logo.size.x)/2,size.y*0.018)
	_footer.size=Vector2(minf(size.x*.5,310),58)
	_footer.position=Vector2((size.x-_footer.size.x)/2,size.y*.865)
	_accents.frame=Rect2(_footer.position,_footer.size)
	_accents.queue_redraw()
func _process(delta: float) -> void:
	_elapsed += delta
	_logo.position.y=size.y*0.018+sin(_elapsed*1.3)*3.0
	var fraction := minf(_elapsed/2.1,1.0)
	_caption.text = "Loading... %d%%"%roundi(fraction*100)
	if fraction>=1:
		set_process(false)
		finished.emit()
		queue_free()

class LoadingAccents extends Control:
	var frame: Rect2
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var y:=frame.get_center().y-3
		var length:=minf(120,size.x*.1)
		for side in [-1,1]:
			var edge:=frame.position.x-14 if side==-1 else frame.end.x+14
			draw_line(Vector2(edge,y),Vector2(edge+side*length,y),Color("fff2b0"),6,true)
			draw_line(Vector2(edge,y),Vector2(edge+side*length,y),Color("f2c43b"),3,true)
