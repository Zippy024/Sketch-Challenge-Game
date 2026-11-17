extends Control
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
const Journey=preload("res://HomeJourney.gd")
var _current: int=0
func _center(stage: int) -> Vector2:
 return Vector2(22+(size.x-44)*float(stage-1)/float(Journey.TOTAL_STAGES-1),24)
func _ready() -> void:
 name="HomeStageProgress"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 _current=Journey.current_stage()
 for stage in range(1,Journey.TOTAL_STAGES+1):
  var marker:=Control.new()
  marker.name="HomeProgressStage%d"%stage
  marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
  marker.set_meta("completed",Progress.is_completed(stage))
  marker.set_meta("current",stage==_current)
  marker.set_meta("available",Progress.is_level_unlocked(stage))
  marker.set_meta("stars",int(Rating.best(stage).get("stars",0)))
  add_child(marker)
  var number:=UI.label("",12,true)
  number.set_meta("locale_ignore",true)
  number.add_theme_font_override("font",UI.font(true,"en"))
  number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  number.autowrap_mode=TextServer.AUTOWRAP_OFF
  marker.add_child(number)
  number.text="" if Progress.is_completed(stage) else str(stage)
  number.add_theme_color_override("font_color",UI.TEAL if stage==_current else UI.MUTED)
 resized.connect(_fit)
 _fit()
func _fit() -> void:
 for stage in range(1,Journey.TOTAL_STAGES+1):
  var marker:=get_node_or_null("HomeProgressStage%d"%stage) as Control
  if marker==null:continue
  marker.position=_center(stage)-Vector2(18,18)
  marker.size=Vector2(36,36)
  marker.get_child(0).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 queue_redraw()
func _draw() -> void:
 for stage in range(1,Journey.TOTAL_STAGES):
  draw_line(_center(stage)+Vector2(17,0),_center(stage+1)-Vector2(17,0),UI.TEAL if Progress.is_completed(stage) else Color("d2ddd5"),2,true)
 for stage in range(1,Journey.TOTAL_STAGES+1):
  var center:=_center(stage)
  var done:=Progress.is_completed(stage)
  draw_circle(center,15,UI.TEAL if done else Color("fafcf5"))
  draw_arc(center,15,0,TAU,40,UI.TEAL if done or stage==_current else Color("c0d2c8"),1.5,true)
  if stage==_current:draw_arc(center,19,0,TAU,40,Color("9cd5c5"),1.0,true)
  if done:draw_polyline(PackedVector2Array([center+Vector2(-5,0),center+Vector2(-1,4),center+Vector2(6,-4)]),Color.WHITE,2.0,true)
