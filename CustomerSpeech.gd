extends HBoxContainer
signal dialogue_started
signal dialogue_finished
# Recorded question, stable-layout subtitle reveal, and a quiet speaking meter.
const Meter=preload("res://SpeakingMeter.gd")
var player: AudioStreamPlayer
var caption: Label
var _meter: Control
var _menu_was_paused: bool=false
var _reveal_cues: Array[Dictionary]=[]
# Measured speech windows in the supplied recordings, excluding silent tails.
# Clause breaks follow the recordings' pauses (seconds, -32dB / 180ms silence scan).
const SPEECH_SPANS={
 "eng":[Vector2(0.0,3.405),Vector2(3.652,6.433)],
 "eng2":[Vector2(0.0,3.257)],"eng3":[Vector2(0.0,2.288)],
 "jp":[Vector2(0.0,3.292),Vector2(3.578,5.917)],
 "jp2":[Vector2(0.0,3.160),Vector2(3.386,4.317)],"jp3":[Vector2(0.0,3.021)],
 "mm":[Vector2(0.184,5.617),Vector2(5.797,6.573)],
 "mm2":[Vector2(0.0,4.162)],"mm3":[Vector2(0.0,3.751)]
}
const CLAUSE_END={"eng":",","jp":"、","jp2":"、","mm":"မော်ဒယ်က"}

func _ready() -> void:
	name="CustomerSpeech"
	add_theme_constant_override("separation",6)
	player=AudioStreamPlayer.new()
	player.name="QuestionVoice"
	player.finished.connect(_finished)
	add_child(player)
	_meter=Meter.new()
	add_child(_meter)

static func voice_path(language: String, phase: int) -> String:
	var suffix: String="" if phase==0 else str(phase+1)
	return "res://Stage 3 %s%s.mp3"%[{"en":"eng","mm":"mm","jp":"jp"}.get(language,"jp"),suffix]

func start(target: Label, path: String) -> void:
	caption=target
	if not ResourceLoader.exists(path):
		caption.visible_characters=-1
		dialogue_finished.emit()
		return
	player.stream=load(path) as AudioStream
	caption.visible_characters_behavior=TextServer.VC_CHARS_AFTER_SHAPING
	_build_reveal_cues(path)
	replay_question()

func replay_question() -> void:
	if player.stream==null:return
	dialogue_started.emit()
	caption.visible_characters=mini(2,caption.get_total_character_count())
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

func _build_reveal_cues(path: String) -> void:
	_reveal_cues.clear()
	var key:=path.get_file().get_basename().trim_prefix("Stage 3 ")
	var spans: Array=SPEECH_SPANS.get(key,[Vector2(0.0,player.stream.get_length())])
	var total: int=caption.get_total_character_count()
	var split: int=-1
	if CLAUSE_END.has(key):
		var delimiter: String=CLAUSE_END[key]
		var found: int=caption.text.find(delimiter)
		if found>=0:split=found+delimiter.length()
	var previous: int=mini(2,total) # Keep the bullet stable while the voice starts.
	for i in range(spans.size()):
		var end: int=split if spans.size()==2 and i==0 and split>=0 else total
		_reveal_cues.append({"start":spans[i].x,"end":spans[i].y,"from":previous,"to":end})
		previous=end

func _process(_delta: float) -> void:
	if player==null or not player.playing or player.stream_paused or not is_instance_valid(caption):return
	# Use the audio clock, including mix/output latency, so pause and replay stay aligned.
	var elapsed:=maxf(0.0,player.get_playback_position()+AudioServer.get_time_since_last_mix()-AudioServer.get_output_latency())
	_reveal_at(elapsed+0.06)

func _reveal_at(elapsed: float) -> void:
	var shown: int=mini(2,caption.get_total_character_count())
	for cue in _reveal_cues:
		if elapsed>=float(cue.end):shown=int(cue.to)
		elif elapsed>=float(cue.start):
			var fraction:=clampf((elapsed-float(cue.start))/maxf(float(cue.end)-float(cue.start),0.01),0.0,1.0)
			shown=int(cue.from)+floori(float(int(cue.to)-int(cue.from))*fraction)
			break
		else:break
	caption.visible_characters=shown

func _finished() -> void:
	if is_instance_valid(caption):caption.visible_characters=-1
	_sync()
	dialogue_finished.emit()

func _sync() -> void:
	var active: bool=player.playing and not player.stream_paused
	_meter.speaking=active
	_meter.queue_redraw()
