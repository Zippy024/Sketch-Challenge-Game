extends TextureRect
class PortraitArcs extends Control:
	func _draw() -> void:
		var center:=size*0.5
		var radius:=minf(size.x,size.y)*0.491
		for start in [102.0,282.0]:
			draw_arc(center,radius,deg_to_rad(start),deg_to_rad(start+73.0),40,Color("9ec6cb"),1.5,true)
	func _ready() -> void:resized.connect(queue_redraw)

# One quiet portrait frame shared by all three stages.
func _init() -> void:
	texture=preload("res://customer_portrait.png")
	custom_minimum_size=Vector2(168,168)
	size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode=TextureRect.STRETCH_SCALE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var frame:=ShaderMaterial.new()
	frame.shader=preload("res://UIAssets/portrait-frame.gdshader")
	material=frame
	var arcs:=PortraitArcs.new()
	arcs.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(arcs)
	arcs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
