extends Control
signal next_requested
signal levels_requested
signal replay_requested
const UI = preload("res://KitchenUI.gd")
var stage_index: int = 1
var title_text: String = "Stage complete!"
var next_text: String = "Next Stage"
var levels_text: String = "View Levels"
var replay_text: String = "Review drawing"
var show_next_button: bool = true
var show_replay_button: bool = false
func configure(title_value: String, _subtitle: String = "", next_value: String = "Next Stage", levels_value: String = "View Levels", replay_value: String = "Replay", allow_next: bool = true, allow_replay: bool = false) -> void:
	title_text=title_value
	next_text=next_value
	levels_text=levels_value
	replay_text=replay_value
	show_next_button=allow_next
	show_replay_button=allow_replay
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color=Color(0.02,0.12,0.20,0.58)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.name="MissionCompleteCard"
	card.custom_minimum_size=Vector2(530,475)
	card.add_theme_stylebox_override("panel",UI.box(Color(0.95,0.99,1,0.98),Color.WHITE,28,24))
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.alignment=BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation",12)
	card.add_child(stack)
	var ribbon := UI.ribbon(UI.text("Stage %d complete!")%stage_index,20)
	ribbon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	stack.add_child(ribbon)
	var art := TextureRect.new()
	art.name="CelebrationArtwork"
	art.texture=preload("res://UIAssets/Celebration.webp")
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size=Vector2(440,275)
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stack.add_child(art)
	if show_next_button:
		var next := UI.button(next_text,func():next_requested.emit(),true,320,20)
		next.name="CompletionNext"
		next.custom_minimum_size.y=48
		next.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		stack.add_child(next)
		next.call_deferred("grab_focus")
	var actions := HBoxContainer.new()
	actions.alignment=BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",12)
	stack.add_child(actions)
	if show_replay_button:
		var review := UI.button(replay_text,func():replay_requested.emit(),false,145,13)
		review.name="CompletionReview"
		actions.add_child(review)
	var levels := UI.button(levels_text,func():levels_requested.emit(),false,145,13)
	levels.name="CompletionLevels"
	actions.add_child(levels)
	# A short entrance gives encouragement without delaying the next action.
	if not OS.has_feature("web") or not bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true)):
		art.modulate.a=0
		create_tween().tween_property(art,"modulate:a",1.0,0.25)
