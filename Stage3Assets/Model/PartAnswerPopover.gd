extends PanelContainer
signal answer_submitted(value: String)
signal draft_changed(value: String)
signal close_requested
const UI=preload("res://KitchenUI.gd")
const Parts=preload("res://Stage3Assets/Model/JapaneseParts.gd")
var part_index: int=-1
var input: LineEdit
var _title: Label
var _notice: Label
var _candidates: FlowContainer
var _check: Button
var _convert: Button
var _notice_revision: int=0
var _fit_pending: bool=false

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
 _notice=UI.label("",12,false,UI.MUTED)
 _notice.custom_minimum_size=Vector2(270,28)
 _notice.size=Vector2(270,48)
 stack.add_child(_notice)
 hide()

func configure(index: int, draft: String, solved: bool) -> void:
 part_index=index
 _notice_revision+=1
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
 _notice.text=UI.text("Correct" if state=="correct" else "Incorrect")
 _notice.add_theme_color_override("font_color",UI.TEAL if state=="correct" else Color("b32741"))
 input.editable=state!="correct"
 _sync_buttons()
 get_tree().create_timer(1.0,false).timeout.connect(_expire_notice.bind(revision))

func _expire_notice(revision: int) -> void:
 if revision==_notice_revision:_notice.text=""

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
