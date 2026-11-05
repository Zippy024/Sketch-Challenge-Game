extends RefCounted
# Presentation-only animation helper. No drawing, quiz, unlock or score logic.
# Used by the menu and each stage after its controls are constructed.

static func animate_screen(root: Control) -> void:
	if not is_instance_valid(root):
		return
	root.modulate.a = 0.0
	var intro := root.create_tween()
	intro.set_trans(Tween.TRANS_SINE)
	intro.set_ease(Tween.EASE_OUT)
	intro.tween_property(root, "modulate:a", 1.0, 0.50)
	for node in root.find_children("*", "Button", true, false):
		if node is Button:
			animate_button(node as Button)


static func animate_button(button: Button) -> void:
	if not is_instance_valid(button) or button.has_meta("concept_c_animated"):
		return
	button.set_meta("concept_c_animated", true)
	button.pivot_offset = button.size * 0.5
	button.resized.connect(func() -> void:
		if is_instance_valid(button):
			button.pivot_offset = button.size * 0.5
	)
	button.mouse_entered.connect(func() -> void:
		if is_instance_valid(button) and not button.disabled:
			var pulse := button.create_tween()
			pulse.set_trans(Tween.TRANS_BACK)
			pulse.set_ease(Tween.EASE_OUT)
			pulse.tween_property(button, "scale", Vector2(1.026, 1.026), 0.16)
	)
	button.mouse_exited.connect(func() -> void:
		if is_instance_valid(button):
			var settle := button.create_tween()
			settle.set_trans(Tween.TRANS_SINE)
			settle.tween_property(button, "scale", Vector2.ONE, 0.14)
	)
	button.button_down.connect(func() -> void:
		if is_instance_valid(button) and not button.disabled:
			button.scale = Vector2(0.985, 0.985)
	)
	button.button_up.connect(func() -> void:
		if is_instance_valid(button):
			var reset := button.create_tween()
			reset.tween_property(button, "scale", Vector2(1.026, 1.026) if button.is_hovered() else Vector2.ONE, 0.14)
	)
