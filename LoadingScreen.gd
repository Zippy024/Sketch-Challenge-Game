extends Control
signal finished
const UI = preload("res://KitchenUI.gd")
var _bar: ProgressBar
var _caption: Label
var _logo: TextureRect
var _caption_panel: PanelContainer
var _elapsed: float = 0.0
func _ready() -> void:
	name = "KitchenLoadingScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.make_theme()
	var photo := TextureRect.new()
	photo.name = "OriginalLoadingKitchen"
	photo.texture = preload("res://LoadingAssets/BlueKitchen.png")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tint := ColorRect.new()
	tint.color = Color(0.01,0.12,0.23,0.12)
	add_child(tint)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ring := FloorArc.new()
	add_child(ring)
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.resized.connect(ring.queue_redraw)
	_logo = UI.logo(0,0)
	add_child(_logo)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.add_theme_stylebox_override("background",UI.box(Color("153f62"),Color("b5efff"),8,0))
	_bar.add_theme_stylebox_override("fill",UI.box(Color("50e4f0"),Color("baffff"),8,0))
	add_child(_bar)
	_caption = UI.label("Loading...",16,true,Color.WHITE)
	_caption.name = "LoadingCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	_caption_panel = PanelContainer.new()
	_caption_panel.add_theme_stylebox_override("panel",UI.box(Color(0.02,0.13,0.25,0.65),Color.TRANSPARENT,18,4))
	add_child(_caption_panel)
	_caption_panel.add_child(_caption)
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	_logo.size = Vector2(minf(size.x*0.47,530),size.y*0.31)
	_logo.position = Vector2((size.x-_logo.size.x)/2,size.y*0.018)
	_bar.size = Vector2(minf(size.x*0.48,560),12)
	_bar.position = Vector2((size.x-_bar.size.x)/2,size.y*0.89)
	_caption_panel.size = Vector2(240,44)
	_caption_panel.position = Vector2((size.x-240)/2,_bar.position.y+17)
func _process(delta: float) -> void:
	_elapsed += delta
	var fraction := minf(_elapsed/2.1,1.0)
	_bar.value = fraction*100
	_caption.text = "Loading... %d%%"%roundi(fraction*100)
	if fraction>=1:
		set_process(false)
		finished.emit()
		queue_free()
class FloorArc extends Control:
	func _draw() -> void:
		var points := PackedVector2Array()
		for i in range(97):
			var a := PI*float(i)/96
			points.append(Vector2(size.x*0.5+cos(a)*size.x*0.36,size.y*0.78+sin(a)*size.y*0.09))
		draw_polyline(points,Color(0.1,0.8,1,0.12),18,true)
		draw_polyline(points,Color(0.2,0.9,1,0.3),7,true)
		draw_polyline(points,Color(0.7,1,1,0.9),2,true)
