extends Control
signal finished
const UI = preload("res://KitchenUI.gd")
const Aqua = preload("res://AquaStyle.gd")
var _caption: Label
var _logo: TextureRect
var _footer: Panel
var _line: LoadingLine
var _elapsed: float = 0.0
func _ready() -> void:
	name = "KitchenLoadingScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UI.make_theme()
	var photo := TextureRect.new()
	photo.name = "OriginalLoadingKitchen"
	photo.texture = Aqua.artwork("res://LoadingAssets/AquaBuilder.png",preload("res://LoadingAssets/TealKitchen.webp"))
	var blue_grade:=ShaderMaterial.new()
	blue_grade.shader=preload("res://UIAssets/loading-blue.gdshader")
	photo.material=blue_grade
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var glaze:=ColorRect.new()
	glaze.name="DeepSkyArtworkWash"
	glaze.color=Color(0,0.749,1,.16)
	glaze.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(glaze)
	glaze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_logo = UI.logo(0,0)
	add_child(_logo)
	_footer=Panel.new()
	_footer.add_theme_stylebox_override("panel",Aqua.surface(true,false,66))
	add_child(_footer)
	_caption = UI.label("",24,true,UI.INK)
	_caption.name = "LoadingCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	_footer.add_child(_caption)
	_caption.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_caption.offset_top=0
	_caption.offset_bottom=-15
	_caption.text="Loading....."
	_line=LoadingLine.new()
	_line.name="LoadingMovingLine"
	_footer.add_child(_line)
	_line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_fit)
	_fit()
func _fit() -> void:
	_logo.size = Vector2(minf(size.x*0.39,480),size.y*0.28)
	_logo.position = Vector2((size.x-_logo.size.x)/2,size.y*0.018)
	_footer.size=Vector2(minf(size.x*.5,310),66)
	_footer.position=Vector2((size.x-_footer.size.x)/2,size.y-maxf(12,size.y*.053)-_footer.size.y)

func _process(delta: float) -> void:
	_elapsed += delta
	_logo.position.y=size.y*0.018+sin(_elapsed*1.3)*3.0
	var fraction := minf(_elapsed/2.1,1.0)
	_line.phase=_elapsed
	_line.queue_redraw()
	if fraction>=1:
		set_process(false)
		finished.emit()
		queue_free()

class LoadingLine extends Control:
	var phase: float=0.0
	func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var start:=24.0
		var width:=maxf(1,size.x-48)
		var y:=size.y-17
		var length:=width*.25
		var x:=start+(width-length)*(.5+.5*sin(phase*3.2-PI/2))
		draw_line(Vector2(start,y),Vector2(start+width,y),Color(0.82,0.96,1,.5),2,true)
		draw_line(Vector2(x,y),Vector2(x+length,y),Color(0.78,0.95,1,.3),6,true)
		draw_line(Vector2(x,y),Vector2(x+length,y),Color.WHITE,3,true)
