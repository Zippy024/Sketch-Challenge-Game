extends Control
signal levels_requested
signal replay_requested
signal home_requested
const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")
func _ready() -> void:
	name = "TrainingResults"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	UI.background(self,true)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card := PanelContainer.new()
	card.name = "ResultsCard"
	card.custom_minimum_size = Vector2(1000,650)
	card.add_theme_stylebox_override("panel",UI.box(Color(0.96,0.99,1,0.94),Color.WHITE,24,26))
	center.add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",18)
	card.add_child(stack)
	var brand := HBoxContainer.new()
	brand.add_child(UI.logo(180,65))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(spacer)
	var language := UI.language_switcher(func(lang: String):
		Progress.set_language(lang)
		_build()
	)
	brand.add_child(language)
	stack.add_child(brand)
	var title := UI.label("Training complete!" if Progress.completed_count()==3 else "Stage 3 complete!",32,true)
	title.name = "ResultsTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var sub := UI.label("Your kitchen design journey, one mission at a time.",16,false,UI.MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(sub)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation",14)
	stack.add_child(cards)
	var outcomes := ["Read the plan and draw the LDK boundary.","Explain PS and its renovation constraints.","Select a kitchen and identify its components."]
	var titles := ["LDK Boundary Drawing","Pipe Shaft Q&A","S-Class Kitchen Selection"]
	for i in range(3):
		var col := UI.card_stack(cards)
		col.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.get_parent().custom_minimum_size.y = 200
		col.add_child(UI.label(UI.text("Stage %d")%(i+1),15,true,UI.TEAL))
		col.add_child(UI.label(titles[i],18,true))
		col.add_child(UI.label(outcomes[i],14,false,UI.MUTED))
		var status := UI.label("Completed" if Progress.is_completed(i+1) else "Not yet completed",14,true,UI.TEAL if Progress.is_completed(i+1) else UI.MUTED)
		status.name = "ResultsStage%dStatus"%(i+1)
		col.add_child(status)
	var customer := HBoxContainer.new()
	customer.add_theme_constant_override("separation",16)
	stack.add_child(customer)
	var portrait := UI.portrait()
	portrait.custom_minimum_size = Vector2(110,110)
	customer.add_child(portrait)
	var thanks := UI.label("Thank you for helping me plan my kitchen renovation.",20,true)
	thanks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	customer.add_child(thanks)
	stack.add_child(UI.progress_strip())
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation",14)
	stack.add_child(actions)
	actions.add_child(UI.button("View Levels",func():levels_requested.emit(),true,200,16))
	actions.add_child(UI.button("Replay Stage 3",func():replay_requested.emit(),false,180))
	actions.add_child(UI.button("Back to Home",func():home_requested.emit(),false,180))
