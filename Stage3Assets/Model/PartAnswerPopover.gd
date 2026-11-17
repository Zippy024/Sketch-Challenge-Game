extends PanelContainer
signal answer_submitted(value: String)
signal draft_changed(value: String)
signal close_requested
const UI=preload("res://KitchenUI.gd")
const Parts=preload("res://Stage3Assets/Model/JapaneseParts.gd")
const RESULT_SECONDS: float=2.0
var part_index: int=-1
var input: LineEdit
var _title: Label
var _notice: Label
var _candidates: FlowContainer
var _check: Button
var _convert: Button
var _notice_revision: int=0
var _fit_pending: bool=false
var _form: VBoxContainer
var _result: VBoxContainer
var _result_title: Label
var _result_icon: TextureRect
var _result_name: Label
var _result_reading: Label
var _result_hint: Label
var _result_progress: ProgressBar
var _result_tween: Tween
var anchor_point:=Vector2.ZERO

func _ready() -> void:
 name="PartAnswerPopover"
 z_index=10
 minimum_size_changed.connect(_request_fit)
 custom_minimum_size.x=300
 mouse_filter=Control.MOUSE_FILTER_STOP
 var surface:=UI.box(Color("f8fcf7"),Color("89bdb3"),16,12)
 surface.shadow_size=8
 add_theme_stylebox_override("panel",surface)
 var stack:=VBoxContainer.new()
 _form=stack
 stack.add_theme_constant_override("separation",8)
 add_child(stack)
 var heading:=HBoxContainer.new()
 stack.add_child(heading)
 _title=UI.label("",16,true)
 _title.autowrap_mode=TextServer.AUTOWRAP_OFF
 _title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 heading.add_child(_title)
 var close:=UI.button("×",func():close_requested.emit(),false,28,15)
 close.name="ClosePartAnswer"
 heading.add_child(close)
 input=LineEdit.new()
 input.name="PartReading"
 input.set_meta("locale_ignore",true)
 input.placeholder_text="ひらがなで入力"
 input.max_length=80
 input.custom_minimum_size=Vector2(270,40)
 input.add_theme_font_override("font",UI.font(false,"jp"))
 input.add_theme_font_size_override("font_size",17)
 input.add_theme_color_override("font_color",UI.INK)
 input.add_theme_color_override("font_uneditable_color",UI.INK)
 input.add_theme_color_override("font_placeholder_color",Color("728a8e"))
 input.text_changed.connect(_text_changed)
 input.text_submitted.connect(func(_value: String):
  if Parts.needs_conversion(input.text):request_conversion()
  elif input.editable:answer_submitted.emit(input.text)
 )
 stack.add_child(input)
 _candidates=HFlowContainer.new()
 _candidates.name="JapaneseConversionCandidates"
 _candidates.add_theme_constant_override("h_separation",6)
 _candidates.add_theme_constant_override("v_separation",6)
 stack.add_child(_candidates)
 var actions:=HBoxContainer.new()
 actions.add_theme_constant_override("separation",6)
 stack.add_child(actions)
 _convert=UI.button("Convert",request_conversion,false,90,13)
 _convert.name="ConvertReading"
 actions.add_child(_convert)
 _check=UI.button("Check answer",func():answer_submitted.emit(input.text),true,160,13)
 _check.name="CheckPartAnswer"
 actions.add_child(_check)
 _notice=UI.label("",16,true,UI.MUTED)
 _notice.name="PartAnswerResult"
 _notice.set_meta("locale_ignore",true)
 _notice.custom_minimum_size=Vector2(270,28)
 _notice.size=Vector2(270,48)
 stack.add_child(_notice)
 _build_result()
 hide()

func _build_result() -> void:
 _result=VBoxContainer.new()
 _result.name="PartResultCard"
 _result.add_theme_constant_override("separation",12)
 add_child(_result)
 var heading:=HBoxContainer.new()
 heading.alignment=BoxContainer.ALIGNMENT_CENTER
 heading.add_theme_constant_override("separation",10)
 _result.add_child(heading)
 var circle:=PanelContainer.new()
 circle.name="PartResultStatusCircle"
 circle.custom_minimum_size=Vector2(40,40)
 circle.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 heading.add_child(circle)
 _result_icon=TextureRect.new()
 _result_icon.texture=UI.icon("check")
 _result_icon.custom_minimum_size=Vector2(24,24)
 _result_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 _result_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 _result_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 _result_icon.name="PartResultStatusIcon"
 _result_icon.set_meta("locale_ignore",true)
 circle.add_child(_result_icon)
 _result_title=UI.label("",20,true)
 _result_title.name="PartResultTitle"
 _result_title.autowrap_mode=TextServer.AUTOWRAP_OFF
 _result_title.set_meta("locale_ignore",true)
 heading.add_child(_result_title)
 _result.add_child(HSeparator.new())
 _result_name=UI.label("",27,true)
 _result_name.name="PartResultName"
 _result_name.set_meta("locale_ignore",true)
 _result_name.add_theme_font_override("font",UI.font(true,"jp"))
 _result_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _result.add_child(_result_name)
 _result_reading=UI.label("",14)
 _result_reading.name="PartResultReading"
 _result_reading.set_meta("locale_ignore",true)
 _result_reading.add_theme_font_override("font",UI.font(false,"jp"))
 _result_reading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _result.add_child(_result_reading)
 _result.add_child(HSeparator.new())
 _result_hint=UI.label("",13)
 _result_hint.set_meta("locale_ignore",true)
 _result_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _result.add_child(_result_hint)
 _result_progress=ProgressBar.new()
 _result_progress.name="PartResultCountdown"
 _result_progress.custom_minimum_size.y=5
 _result_progress.show_percentage=false
 var track:=UI.box(Color("e4e8e7"),Color.TRANSPARENT,3,0)
 var fill:=UI.box(Color("38b5a7"),Color.TRANSPARENT,3,0)
 track.shadow_size=0
 fill.shadow_size=0
 _result_progress.add_theme_stylebox_override("background",track)
 _result_progress.add_theme_stylebox_override("fill",fill)
 _result.add_child(_result_progress)
 _result.hide()

func _show_form() -> void:
 if _result_tween and _result_tween.is_valid():_result_tween.kill()
 modulate.a=1.0
 _result.hide()
 _form.show()
 var surface:=UI.box(Color("f8fcf7"),Color("89bdb3"),16,12)
 surface.shadow_size=8
 add_theme_stylebox_override("panel",surface)
 _request_fit()
 queue_redraw()

func is_showing_result() -> bool:
 return _result.visible

func configure(index: int, draft: String, solved: bool) -> void:
 part_index=index
 _notice_revision+=1
 _show_form()
 _title.text=UI.text("Selected part")+("  ✓" if solved else "")
 input.text=draft
 input.editable=not solved
 _clear_candidates()
 _notice.text="" if solved else UI.text("Type in hiragana, then choose a conversion.")
 _notice.add_theme_color_override("font_color",UI.MUTED)
 _set_style("correct" if solved else "neutral")
 _sync_buttons()
 size=Vector2(300,0)
 _request_fit()

func _text_changed(value: String) -> void:
 _notice_revision+=1
 _clear_candidates()
 _notice.text=""
 _set_style("neutral")
 _sync_buttons()
 draft_changed.emit(value)

func _sync_buttons() -> void:
 _convert.disabled=not input.editable or input.text.strip_edges().is_empty()
 _check.disabled=not input.editable or Parts.normalize(input.text).is_empty() or Parts.needs_conversion(input.text)

func _clear_candidates() -> void:
 for child in _candidates.get_children():
  _candidates.remove_child(child)
  child.queue_free()
 _candidates.hide()
 _request_fit()

func request_conversion() -> void:
 if not input.editable:return
 _notice_revision+=1
 _clear_candidates()
 var values:=Parts.conversion_candidates(input.text)
 if values.is_empty():
  _notice.text=UI.text("No candidates. Check the full hiragana reading.")
  return
 _notice.text=UI.text("Choose a conversion.")
 for value in values:
  var candidate:=UI.button(value,choose_candidate.bind(value),false,72,16)
  candidate.text=value
  candidate.name="ConversionCandidate%d"%_candidates.get_child_count()
  candidate.set_meta("locale_ignore",true)
  candidate.add_theme_font_override("font",UI.font(false,"jp"))
  _candidates.add_child(candidate)
 _candidates.show()
 _request_fit()

func choose_candidate(value: String) -> void:
 input.text=value
 _text_changed(value)
 input.grab_focus()
 input.caret_column=input.text.length()

func show_result(state: String) -> void:
 _notice_revision+=1
 var revision:=_notice_revision
 _set_style(state)
 _notice.text=("✓  " if state=="correct" else "✕  ")+UI.text("Correct" if state=="correct" else "Incorrect")
 _notice.add_theme_color_override("font_color",Color("167044") if state=="correct" else Color("a51f38"))
 input.editable=state!="correct"
 _sync_buttons()
 input.release_focus()
 if _result_tween and _result_tween.is_valid():_result_tween.kill()
 var correct:=state=="correct"
 var circle:=_result_icon.get_parent() as PanelContainer
 var circle_style:=UI.box(Color("38b5a7") if correct else Color("d55264"),Color.TRANSPARENT,20,8)
 circle_style.shadow_size=0
 circle_style.set_border_width_all(0)
 circle.add_theme_stylebox_override("panel",circle_style)
 _result_icon.texture=UI.icon("check" if correct else "close")
 _result_icon.set_meta("verdict",state)
 _result_title.text=UI.text("That's correct!" if correct else "That's incorrect.")
 _result_name.text=input.text
 # Incorrect attempts show only the submitted answer, never the solution.
 _result_reading.text=Parts.reading(input.text) if correct else ""
 _result_reading.visible=correct
 _result_hint.text=UI.text("Select the next part." if correct else "Try another name.")
 var surface:=UI.box(Color("fffefd"),Color("d7e6df"),18,18)
 surface.border_width_top=5
 surface.border_color=Color("74cfc2")
 surface.shadow_size=10
 add_theme_stylebox_override("panel",surface)
 _form.hide()
 _result.show()
 modulate.a=1.0
 _result_progress.value=100
 _request_fit()
 queue_redraw()
 _result_tween=create_tween()
 _result_tween.tween_property(_result_progress,"value",0.0,RESULT_SECONDS-0.16)
 _result_tween.tween_property(self,"modulate:a",0.0,0.16)
 get_tree().create_timer(RESULT_SECONDS,false).timeout.connect(_expire_notice.bind(revision))

func _expire_notice(revision: int) -> void:
 if revision!=_notice_revision:return
 _notice.text=""
 if input.editable:
  _show_form()
  if is_visible_in_tree():input.grab_focus()

func _draw() -> void:
 if not is_instance_valid(_result) or not _result.visible:return
 if Rect2(Vector2.ZERO,size).has_point(anchor_point):return
 var edge:=Vector2(0 if anchor_point.x<0 else size.x,clampf(anchor_point.y,24,size.y-24))
 draw_line(anchor_point,edge,Color("359e91"),1.5,true)

func _set_style(state: String) -> void:
 var style:=UI.box(Color("e7f6ee") if state=="correct" else (Color("fff0f2") if state=="incorrect" else Color.WHITE),Color("91c6ac") if state=="correct" else (Color("dda5af") if state=="incorrect" else UI.EDGE),8,7)
 style.shadow_size=0
 input.add_theme_stylebox_override("normal",style)
 input.add_theme_stylebox_override("read_only",style)
 var focus:=UI.box(Color.TRANSPARENT,UI.TEAL,8,7)
 focus.shadow_size=0
 focus.set_border_width_all(2)
 input.add_theme_stylebox_override("focus",focus)

func _unhandled_key_input(event: InputEvent) -> void:
 if visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  close_requested.emit()
  get_viewport().set_input_as_handled()

func _request_fit() -> void:
 if _fit_pending:return
 _fit_pending=true
 _fit_content.call_deferred()

func _fit_content() -> void:
 _fit_pending=false
 size=Vector2(300,get_combined_minimum_size().y)
