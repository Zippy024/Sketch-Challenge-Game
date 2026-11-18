extends Control
# Shared conversation indicator; it owns no playback controls.
var audio_player: AudioStreamPlayer
var speaking: bool=false
var elapsed: float=0.0
func _ready() -> void:
 name="SpeakingMeter"
 custom_minimum_size=Vector2(30,20)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 if is_instance_valid(audio_player):
  var active:=audio_player.playing and not audio_player.stream_paused
  if active!=speaking:
   speaking=active
   queue_redraw()
 if speaking:
  elapsed+=delta
  queue_redraw()
func _draw() -> void:
 var style:=StyleBoxFlat.new()
 style.bg_color=Color("2a9897") if speaking else Color("aec9c4")
 style.set_corner_radius_all(1)
 for i in range(5):
  var height: float=3.0+absf(sin(elapsed*9.0+float(i)*1.15))*11.0 if speaking else 3.0
  draw_style_box(style,Rect2(float(i)*6.0,(size.y-height)*0.5,3,height))
