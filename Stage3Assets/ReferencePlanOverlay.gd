extends Control
const UI=preload("res://KitchenUI.gd")
class PlanView extends Control:
 var texture: Texture2D=preload("res://Refrence image.png")
 var zoom: float=1.0
 var pan: Vector2=Vector2.ZERO
 var dragging: bool=false
 func _ready() -> void:
  mouse_filter=Control.MOUSE_FILTER_STOP
  mouse_default_cursor_shape=Control.CURSOR_DRAG
  clip_contents=true
  resized.connect(queue_redraw)
 func reset_view() -> void:
  zoom=1.0
  pan=Vector2.ZERO
  queue_redraw()
 func zoom_by(factor: float, point: Vector2=Vector2(-1,-1)) -> void:
  if point.x<0:point=size*0.5
  var previous: float=zoom
  zoom=clampf(zoom*factor,1.0,6.0)
  pan=point-size*0.5-(point-size*0.5-pan)*zoom/previous
  if is_equal_approx(zoom,1.0):pan=Vector2.ZERO
  queue_redraw()
 func _gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton:
   if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:zoom_by(1.2,event.position)
   elif event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:zoom_by(1.0/1.2,event.position)
   elif event.button_index==MOUSE_BUTTON_LEFT:
    dragging=event.pressed
    if event.double_click:reset_view()
   accept_event()
  elif event is InputEventMouseMotion and dragging:
   pan+=event.relative
   queue_redraw()
   accept_event()
  elif event is InputEventScreenDrag:
   pan+=event.relative
   queue_redraw()
   accept_event()
  elif event is InputEventMagnifyGesture:
   zoom_by(event.factor,event.position)
   accept_event()
 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)
  var fit: float=minf(size.x/texture.get_width(),size.y/texture.get_height())
  var drawn: Vector2=texture.get_size()*fit*zoom
  draw_texture_rect(texture,Rect2((size-drawn)*0.5+pan,drawn),false)
var viewer: PlanView
func _ready() -> void:
 name="Stage3ReferenceOverlay"
 z_index=100
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var shade:=ColorRect.new()
 shade.color=Color(0.04,0.12,0.16,0.62)
 add_child(shade)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin:=MarginContainer.new()
 add_child(margin)
 margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right"]:margin.add_theme_constant_override("margin_"+side,40)
 for side in ["top","bottom"]:margin.add_theme_constant_override("margin_"+side,35)
 var card:=PanelContainer.new()
 card.add_theme_stylebox_override("panel",UI.box(Color("f7fcfa"),UI.EDGE,18,14))
 margin.add_child(card)
 var stack:=VBoxContainer.new()
 stack.add_theme_constant_override("separation",10)
 card.add_child(stack)
 var heading:=HBoxContainer.new()
 stack.add_child(heading)
 var title:=UI.label("Reference Plan",20,true)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 heading.add_child(title)
 viewer=PlanView.new()
 viewer.name="EnlargedReferencePlan"
 viewer.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var zoom_in:=UI.button("+",viewer.zoom_by.bind(1.25),false,42,20)
 zoom_in.name="ReferenceZoomIn"
 heading.add_child(zoom_in)
 var zoom_out:=UI.button("−",viewer.zoom_by.bind(0.8),false,42,20)
 zoom_out.name="ReferenceZoomOut"
 heading.add_child(zoom_out)
 var reset:=UI.button("Reset",viewer.reset_view,false,75,14)
 reset.name="ReferenceReset"
 heading.add_child(reset)
 var close:=UI.button("Close",queue_free,false,80,14)
 close.name="CloseReferencePlan"
 heading.add_child(close)
 stack.add_child(viewer)
 close.grab_focus()
func _unhandled_key_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  queue_free()
  get_viewport().set_input_as_handled()
