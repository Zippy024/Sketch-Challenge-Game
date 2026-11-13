extends HBoxContainer
# Recorded question, stable-layout subtitle reveal, and a quiet speaking meter.
const UI=preload("res://KitchenUI.gd")
var player: AudioStreamPlayer
var caption: Label
var _pause: Button
var _meter: Control
var _menu_was_paused: bool=false

class SpeechMeter extends Control:
	var speaking: bool=false
	var elapsed: float=0.0
	func _ready() -> void:
		custom_minimum_size=Vector2(22,24)
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _process(delta: float) -> void:
		if speaking:
			elapsed+=delta
			queue_redraw()
	func _draw() -> void:
		for i in range(5):
			var height: float=3.0+absf(sin(elapsed*9.0+float(i)*1.15))*10.0 if speaking else 3.0
			draw_style_box(_bar(),Rect2(float(i)*4.0,(size.y-height)*0.5,2,height))
	func _bar() -> StyleBoxFlat:
		var style:=StyleBoxFlat.new()
		style.bg_color=Color("2a9897") if speaking else Color("aec9c4")
		style.set_corner_radius_all(1)
		return style

func _ready() -> void:
	name="CustomerSpeech"
	add_theme_constant_override("separation",6)
	player=AudioStreamPlayer.new()
	player.name="QuestionVoice"
	player.finished.connect(_finished)
	add_child(player)
	_meter=SpeechMeter.new()
	_meter.name="SpeakingMeter"
	add_child(_meter)
	var replay:=UI.button("",replay_question,false,30,12)
	replay.name="ReplayQuestion"
	replay.icon=preload("res://Stage1Assets/reset.svg")
	replay.expand_icon=true
	replay.add_theme_constant_override("icon_max_width",16)
	replay.tooltip_text=UI.text("Replay")
	add_child(replay)
	_pause=UI.button("Ⅱ",toggle_pause,false,30,12)
	_pause.name="PauseQuestion"
	_pause.tooltip_text=UI.text("Pause")
	add_child(_pause)

static func voice_path(language: String, phase: int) -> String:
	var suffix: String="" if phase==0 else str(phase+1)
	return "res://Stage 3 %s%s.mp3"%[{"en":"eng","mm":"mm","jp":"jp"}.get(language,"jp"),suffix]

func start(target: Label, path: String) -> void:
	caption=target
	if not ResourceLoader.exists(path):
		caption.visible_characters=-1
		_pause.disabled=true
		return
	player.stream=load(path) as AudioStream
	replay_question()

func replay_question() -> void:
	if player.stream==null:return
	caption.visible_characters=0
	player.stream_paused=false
	player.play()
	_sync()

func toggle_pause() -> void:
	if not player.playing:
		replay_question()
		return
	player.stream_paused=not player.stream_paused
	_sync()

func pause_for_menu() -> void:
	_menu_was_paused=player.stream_paused
	if player.playing:player.stream_paused=true
	_sync()

func resume_from_menu() -> void:
	if player.playing:player.stream_paused=_menu_was_paused
	_sync()

func stop() -> void:
	player.stop()
	if is_instance_valid(caption):caption.visible_characters=-1
	_sync()

func _process(_delta: float) -> void:
	if player==null or not player.playing or player.stream_paused or not is_instance_valid(caption):return
	var ratio:=clampf(player.get_playback_position()/maxf(player.stream.get_length(),0.1),0.0,1.0)
	caption.visible_ratio=ratio

func _finished() -> void:
	if is_instance_valid(caption):caption.visible_characters=-1
	_sync()

func _sync() -> void:
	var active: bool=player.playing and not player.stream_paused
	_pause.text="Ⅱ" if active else "▶"
	_pause.tooltip_text=UI.text("Pause" if active else "Replay")
	_meter.speaking=active
	_meter.queue_redraw()
