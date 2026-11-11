extends Control

# V8: native interactive menu over a clean kitchen-background photo. Level list is text-only.
# Compatible with the existing Stage 1/2 scenes, saved progression and pause/resume.
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")
const UI = preload("res://KitchenUI.gd")
const Extras = preload("res://MenuExtras.gd")

const BG := Color("f5f5f1")
const WHITE := Color("ffffff")
const INK := Color("152f32")
const MUTED := Color("647780")
const GREEN := Color("008f98")
const GREEN_DARK := Color("007d87")
const GREEN_PALE := Color("e2f2ea")
const BORDER := Color("d6e0e0")
const GOLD := Color("d5ac72")
const LOCKED := Color("a3afb4")

var is_pause_overlay: bool = false
var pause_level: int = 0
var _body: VBoxContainer
var _jp_button: Button
var _mm_button: Button
var _en_button: Button
var _scroll: ScrollContainer
var _home_overlay: Control
var _volume_value: float = 0.85
var _reset_armed: bool = false
var _stats_reset_armed: bool = false


func _ready() -> void:
	theme = UI.make_theme()
	_volume_value = Extras.volume()
	Extras.apply_audio()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame()
	resized.connect(_fit_content)
	_fit_content()
	if Progress.show_home_on_open:
		Progress.show_home_on_open=false
		_show_home()
	elif is_pause_overlay or Progress.show_levels_on_open:
		Progress.show_levels_on_open = false
		_show_levels()
	else:
		if OS.has_feature("web"):
			_show_language_select()
		else:
			var loading := preload("res://LoadingScreen.gd").new()
			loading.finished.connect(_show_language_select)
			add_child(loading)
	if OS.has_feature("web"):
		call_deferred("_notify_loading_ready")


func _show_language_select() -> void:
	_clear()
	var screen := preload("res://LanguageScreen.gd").new()
	screen.language_chosen.connect(func(language: String) -> void:
		_set_language(language)
		_show_home()
	)
	add_child(screen)


func _notify_loading_ready() -> void:
	JavaScriptBridge.eval("window.__kitchenMenuReady = true;", true)


func _style(bg: Color, edge: Color = BORDER, radius: int = 15, padding: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = edge
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(padding)
	return s


func _label(value: String, font_size: int = 16, color: Color = INK, centered: bool = false) -> Label:
	var l := Label.new()
	l.text = LocaleManager.text(value)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(title: String, primary: bool = false, min_w: float = 165.0, min_h: float = 46.0) -> Button:
	var b := Button.new()
	b.text = LocaleManager.text(title)
	if title.to_lower().begins_with("back"):
		b.icon=preload("res://MenuAssets/BackArrow.svg")
		b.add_theme_color_override("icon_normal_color",WHITE if primary else INK)
		b.add_theme_color_override("icon_hover_color",WHITE if primary else GREEN)
	b.custom_minimum_size = Vector2(min_w, min_h)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", WHITE if primary else INK)
	b.add_theme_color_override("font_hover_color", WHITE if primary else GREEN)
	b.add_theme_color_override("font_pressed_color", WHITE if primary else GREEN)
	b.add_theme_stylebox_override("normal", _style(GREEN if primary else WHITE, GREEN if primary else BORDER, 12, 9))
	b.add_theme_stylebox_override("hover", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 9))
	b.add_theme_stylebox_override("pressed", _style(GREEN_DARK if primary else GREEN_PALE, GREEN, 12, 9))
	b.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD, 12, 0))
	UI.style_button(b,primary,15)
	return b


func _build_frame() -> void:
	UI.background(self)
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _style(Color(0.94,0.98,1,0.6), Color.TRANSPARENT, 0))
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	bg.add_child(outer)

	var top := PanelContainer.new()
	top.custom_minimum_size.y = 58
	top.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 0))
	outer.add_child(top)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 28)
	header_margin.add_theme_constant_override("margin_right", 28)
	header_margin.add_theme_constant_override("margin_top", 3)
	header_margin.add_theme_constant_override("margin_bottom", 3)
	top.add_child(header_margin)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header_margin.add_child(header)

	# Single brand mark shared by the in-game header, desktop icon and Web favicon.
	var mark := TextureRect.new()
	mark.custom_minimum_size = Vector2(132, 44)
	mark.texture = preload("res://LoadingAssets/KitchenLogo.webp")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(mark)

	var back := _button("Back",false,90,36)
	back.name="MenuPageBack"
	back.pressed.connect(_show_levels if is_pause_overlay else _show_home)
	header.add_child(back)
	var brand := _label("Kitchen Layout Game", 19, INK)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)

	_jp_button = _button("日本語", false, 69, 36)
	_mm_button = _button("မြန်မာ", false, 69, 36)
	_en_button = _button("English",false,69,36)
	for b in [_jp_button, _mm_button, _en_button]:
		b.add_theme_font_size_override("font_size", 12)
		header.add_child(b)
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
	_en_button.pressed.connect(func() -> void: _set_language("en"))
	_update_lang_buttons()

	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_scroll.add_child(margin)
	# Center horizontally only. A CenterContainer vertically centered the long
	# level list and could hide the page heading above the scroll viewport.
	var aligner := HBoxContainer.new()
	aligner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(aligner)
	var left_gutter := Control.new()
	left_gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aligner.add_child(left_gutter)
	_body = VBoxContainer.new()
	_body.custom_minimum_size.x = 1100
	_body.add_theme_constant_override("separation", 12)
	aligner.add_child(_body)
	var right_gutter := Control.new()
	right_gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aligner.add_child(right_gutter)

	var footer := PanelContainer.new()
	footer.custom_minimum_size.y = 27
	footer.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 0))
	outer.add_child(footer)
	footer.add_child(_label("SKETCH CHALLENGE  •  DRAW  /  DESIGN  /  LEARN", 10, MUTED, true))


func _fit_content() -> void:
	if _body != null:
		_body.custom_minimum_size.x = minf(1320.0, maxf(540.0, size.x - 56.0))


func _set_language(lang: String) -> void:
	Progress.set_language(lang)
	_update_lang_buttons()


func _update_lang_buttons() -> void:
	for b in [_jp_button, _mm_button, _en_button]:
		var selected: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm") or (b == _en_button and Progress.get_language()=="en")
		b.add_theme_stylebox_override("normal", _style(GREEN if selected else WHITE, GREEN if selected else BORDER, 10, 7))
		b.add_theme_color_override("font_color", WHITE if selected else INK)
		b.add_theme_color_override("font_hover_color", WHITE if selected else GREEN)


func _clear() -> void:
	# Remove only the full-screen home presentation when changing to another page.
	# The existing menu/level/game logic and shared frame remain unchanged.
	if is_instance_valid(_home_overlay):
		remove_child(_home_overlay)
		_home_overlay.queue_free()
		_home_overlay = null
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_scroll.scroll_vertical = 0


# Home screen only: visual refresh inspired by the supplied compact menu reference.
# All other pages continue to use the existing menu frame and functions.
func _show_home() -> void:
	_show_presentation(false)

func _show_presentation(levels: bool) -> void:
	_clear()
	var screen := preload("res://MenuScreen.gd").new()
	screen.levels=levels
	screen.paused_game=is_pause_overlay
	screen.stage_requested.connect(_start_level)
	screen.action_requested.connect(func(action: String) -> void:
		match action:
			"levels":_show_levels()
			"new_game":_start_new_game()
			"continue":
				if is_pause_overlay: _resume_paused()
				elif Progress.has_session(): _start_level(Progress.resume_stage(),true)
			"language":_show_language_select()
			"guide":_show_help()
			"settings":_show_settings()
			"profile":_show_profile()
			"back":
				if is_pause_overlay:_resume_paused()
				else:_show_home()
	)
	_home_overlay=screen
	add_child(screen)

func _home_menu_button(caption_text: String, primary: bool) -> Button:
	var button := Button.new()
	button.name = caption_text.replace(" ", "")
	button.text = LocaleManager.text(caption_text)
	button.custom_minimum_size = Vector2(0, 49)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 19)
	var text_color := Color("ffffff") if primary else Color("113b54")
	var hover_text := Color("ffffff") if primary else Color("04527a")
	for state in ["font_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_hover_color", hover_text)
	button.add_theme_color_override("font_hover_pressed_color", hover_text)

	var normal := _style(Color("008c9f") if primary else Color(0.94, 0.98, 1.0, 0.96), Color("6de5ef") if primary else Color("aed5eb"), 27, 8)
	var hover := _style(Color("007d94") if primary else Color("ffffff"), Color("bdffff") if primary else Color("72bfe9"), 27, 8)
	var pressed := _style(Color("006b80") if primary else Color("d9f2ff"), Color("8be0ed") if primary else Color("72bfe9"), 27, 8)
	for style in [normal, hover, pressed]:
		style.set_border_width_all(2)
		style.shadow_color = Color(0.0, 0.15, 0.27, 0.18)
		style.shadow_size = 6
		style.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, Color("d2fbff"), 27))
	return button


func _home_tile(caption_text: String, graphic: Texture2D, primary: bool, action: Callable) -> Button:
	var tile := Button.new()
	tile.text = ""
	tile.custom_minimum_size = Vector2(158, 98)
	tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tile.add_theme_stylebox_override("normal", _tile_style(primary, false))
	tile.add_theme_stylebox_override("hover", _tile_style(primary, true))
	tile.add_theme_stylebox_override("pressed", _tile_style(primary, true))
	tile.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD, 14, 0))
	tile.pressed.connect(action)
	var contents := VBoxContainer.new()
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_theme_constant_override("separation", 4)
	tile.add_child(contents)
	contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contents.offset_top = 8
	contents.offset_bottom = -8
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	var img := TextureRect.new()
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	img.texture = graphic
	img.custom_minimum_size = Vector2(31, 31)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contents.add_child(img)
	var txt := _label(caption_text, 14, WHITE if primary else INK, true)
	txt.autowrap_mode = TextServer.AUTOWRAP_OFF
	contents.add_child(txt)
	return tile


func _tile_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style := _style((GREEN_DARK if hovered else GREEN) if primary else (Color("f5fbf7") if hovered else WHITE), GREEN if primary else Color("ede9e1"), 14, 9)
	# Small shadow and one-pixel border keep the button edge crisp in Web export.
	style.shadow_color = Color(0.25, 0.20, 0.12, 0.10)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 1)
	return style

func _level_row(n: int) -> Button:
	# Stages 3–6 are intentionally unannounced: number + COMING SOON only.
	var unlocked: bool = n <= 3 and Progress.is_level_unlocked(n)
	var is_current: bool = is_pause_overlay and n == pause_level
	var future: bool = n >= 4
	var row_btn := Button.new()
	row_btn.text = ""
	row_btn.custom_minimum_size.y = 72 if not future else 57
	row_btn.disabled = not unlocked
	row_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	row_btn.add_theme_stylebox_override("normal", _style(WHITE, GREEN if is_current else BORDER, 13))
	row_btn.add_theme_stylebox_override("disabled", _style(Color("f7f8f7"), BORDER, 13))
	row_btn.add_theme_stylebox_override("hover", _style(GREEN_PALE, GREEN, 13))
	row_btn.add_theme_stylebox_override("pressed", _style(GREEN_PALE, GREEN, 13))
	row_btn.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, GOLD, 13))
	if unlocked:
		row_btn.pressed.connect(_start_level.bind(n))
	row_btn.tooltip_text = "Open stage" if unlocked else "Coming soon"

	var line := HBoxContainer.new()
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 22
	line.offset_right = -24
	line.add_theme_constant_override("separation", 19)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_btn.add_child(line)
	var no := _label("%02d" % n, 24 if not future else 20, GREEN if unlocked else LOCKED)
	no.custom_minimum_size.x = 42
	no.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(no)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 3)
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(copy)
	if future:
		var soon := _label("COMING SOON", 16, LOCKED)
		soon.autowrap_mode = TextServer.AUTOWRAP_OFF
		copy.add_child(soon)
	else:
		var stage_heading := _label("STAGE %d" % n, 15, INK if unlocked else LOCKED)
		stage_heading.autowrap_mode = TextServer.AUTOWRAP_OFF
		copy.add_child(stage_heading)
		copy.add_child(_label("Customer Request  •  Listen and draw the floor plan" if n == 1 else ("Pipe Shaft Q&A  •  Explain PS to the customer" if n == 2 else "S-Class Kitchen  •  Layout and parts"), 13, MUTED if unlocked else LOCKED))
	if not future:
		var text := "RESTART" if is_current else ("PLAY" if unlocked else "LOCKED")
		var state := _label(text, 13, GREEN if unlocked else LOCKED, true)
		state.custom_minimum_size.x = 95
		state.autowrap_mode = TextServer.AUTOWRAP_OFF
		line.add_child(state)
	return row_btn


func _show_levels() -> void:
	_show_presentation(true)


func _resume_paused() -> void:
	if is_pause_overlay:
		resume_requested.emit()
	else:
		_show_home()


func _show_help() -> void:
	_clear()
	_body.add_child(_label("HOW TO PLAY", 31, INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 18)
	panel.add_child(contents)
	contents.add_child(_label("01  LISTEN TO THE CUSTOMER", 19, GREEN))
	contents.add_child(_label("Choose Japanese or Myanmar, listen to the customer and review the layout request.", 16, MUTED))
	contents.add_child(_label("02  DRAW THE REQUESTED PLAN", 19, GREEN))
	contents.add_child(_label("Use the grid tools to sketch the requested walls and press OK to check your layout.", 16, MUTED))
	contents.add_child(_label("03  ANSWER THE CUSTOMER", 19, GREEN))
	contents.add_child(_label("Stages 1, 2, and 3 are available to play.", 16, MUTED))
	contents.add_child(_label("Progress and language selection are saved on this device.", 14, MUTED))
	var guide := _button("VIEW MISSION GUIDE", false, 206, 42)
	guide.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	guide.pressed.connect(_show_missions)
	contents.add_child(guide)
	var go := _button("BACK TO HOME", true, 190, 46)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_home)
	contents.add_child(go)


func _show_settings() -> void:
	_clear()
	var screen := preload("res://SettingsScreen.gd").new()
	screen.home_requested.connect(_show_home)
	screen.levels_requested.connect(_show_levels)
	screen.language_requested.connect(_set_language)
	screen.fullscreen_requested.connect(_toggle_fullscreen)
	screen.volume_changed.connect(_on_volume_changed)
	_home_overlay=screen
	add_child(screen)


func _on_volume_changed(value: float) -> void:
	_volume_value = value
	Extras.set_volume(value)
	Extras.apply_audio()


func _start_new_game() -> void:
	var current := get_tree().current_scene
	if current.has_method("_suspend_session_save"): current.call("_suspend_session_save")
	Progress.start_new_game()
	_start_level(1)

func _start_level(level: int, resume: bool = false) -> void:
	if level > 3 or not Progress.is_level_unlocked(level):
		return
	var current := get_tree().current_scene
	if current.has_method("_save_session"): current.call("_save_session")
	if current.has_method("_suspend_session_save"): current.call("_suspend_session_save")
	Progress.open_stage(level,resume)
	Progress.launch_from_level_menu = (level == 1)
	if is_pause_overlay:
		get_tree().paused = false
	var target: String = "res://main.tscn" if level == 1 else ("res://stage_2.tscn" if level == 2 else "res://stage_3.tscn")
	var result: Error = get_tree().change_scene_to_file(target)
	if result == OK:
		Extras.record_launch(level)
	if result != OK:
		Progress.launch_from_level_menu = false
		if is_pause_overlay:
			get_tree().paused = true
		push_error("Failed to open level: " + target)

# -----------------------------------------------------------------------------
# V16 MENU HUB. Separate from Stage 1 / Stage 2 / Stage 3 gameplay.
# -----------------------------------------------------------------------------

func _menu_page(page_title: String, subtitle: String) -> VBoxContainer:
	_clear()
	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 14)
	_body.add_child(heading_row)
	var back := _button("BACK TO LEVELS" if is_pause_overlay else "BACK TO HOME", false, 150, 35)
	back.add_theme_font_size_override("font_size", 12)
	if is_pause_overlay:
		back.pressed.connect(_show_levels)
	else:
		back.pressed.connect(_show_home)
	heading_row.add_child(back)
	var title := _label(page_title, 26, INK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(title)
	_body.add_child(_label(subtitle, 13, MUTED))
	return _body


func _info_panel(title_text: String, description: String, marker: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 15, 18))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	card.add_child(content)
	if not marker.is_empty():
		content.add_child(_label(marker, 12, GREEN))
	content.add_child(_label(title_text, 18, INK))
	if not description.is_empty():
		content.add_child(_label(description, 14, MUTED))
	return card


func _show_profile() -> void:
	_menu_page("PLAYER PROFILE", "Optional local display name. No account or password required.")
	var card := _info_panel("Welcome, " + Extras.get_display_name(), "Your display name and game menu statistics are saved locally on this device.", "PLAYER CARD")
	_body.add_child(card)
	var content := card.get_child(0) as VBoxContainer
	content.add_child(_label("DISPLAY NAME", 13, GREEN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var field := LineEdit.new()
	field.text = Extras.get_display_name()
	field.placeholder_text = "Guest"
	field.max_length = 24
	field.custom_minimum_size = Vector2(290, 42)
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(field)
	var save_btn := _button("SAVE NAME", true, 144, 42)
	save_btn.pressed.connect(func() -> void:
		Extras.set_name(field.text)
		_show_profile()
	)
	field.text_submitted.connect(func(_value: String) -> void:
		Extras.set_name(field.text)
		_show_profile()
	)
	row.add_child(save_btn)
	_body.add_child(_info_panel("Privacy", "This is a local guest profile, not online sign-in. Clearing the browser's site data or Godot user data can erase it."))
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	_body.add_child(actions)
	var progress_btn := _button("MY PROGRESS", false, 170, 39)
	progress_btn.pressed.connect(_show_progress)
	actions.add_child(progress_btn)
	var achieve_btn := _button("ACHIEVEMENTS", false, 180, 39)
	achieve_btn.pressed.connect(_show_achievements)
	actions.add_child(achieve_btn)


func _show_progress() -> void:
	_stats_reset_armed = false
	_menu_page("MY PROGRESS", "Verified progress and launch history; available stages remain unlocked.")
	var summary := _info_panel("" + Extras.get_display_name() + "'s Learning Journey", "Stages launched from Level Select: %d" % Extras.total_count(), "PLAYER OVERVIEW")
	_body.add_child(summary)
	var v := summary.get_child(0) as VBoxContainer
	var last_label := "Not yet played"
	if Extras.last_stage() > 0:
		last_label = "Stage %d" % Extras.last_stage()
		if not Extras.last_date().is_empty():
			last_label += "  •  " + Extras.last_date()
	v.add_child(_label(LocaleManager.text("Last selected: %s") % LocaleManager.text(last_label), 13, MUTED))
	_body.add_child(UI.progress_strip())
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 11)
	_body.add_child(grid)
	for n in range(1, 4):
		var text_status := "COMPLETED (VERIFIED)" if Progress.is_completed(n) else "NOT YET VERIFIED"
		var panel := _info_panel("STAGE %d" % n, "Level Menu launches: %d\n%s" % [Extras.count(n), LocaleManager.text(text_status)], "AVAILABLE TO PLAY")
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
	_body.add_child(_info_panel("About progress", "Each mission is saved after its answer checks pass. Launch counts only include starts from Level Select."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_body.add_child(row)
	var go := _button("SELECT LEVEL", true, 155, 41)
	go.pressed.connect(_show_levels)
	row.add_child(go)
	var reset := _button("CLEAR MENU HISTORY", false, 225, 41)
	reset.pressed.connect(func() -> void:
		if not _stats_reset_armed:
			_stats_reset_armed = true
			reset.text = "CONFIRM CLEAR HISTORY"
		else:
			Extras.reset_stats()
			_show_progress()
	)
	row.add_child(reset)


func _achievement_card(title_text: String, requirement: String, earned: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _style(Color("f0faf4") if earned else WHITE, GREEN if earned else BORDER, 14, 16))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(_label("UNLOCKED" if earned else "LOCKED", 12, GREEN if earned else LOCKED))
	v.add_child(_label(title_text, 18, INK))
	v.add_child(_label(requirement, 13, MUTED))
	return panel


func _show_achievements() -> void:
	_menu_page("ACHIEVEMENTS", "Rewards reflect actual menu activity or verified Stage 1 completion.")
	var total := Extras.total_count()
	var all_visited := Extras.count(1) > 0 and Extras.count(2) > 0 and Extras.count(3) > 0
	var completed_count: int = 0
	if total >= 1:
		completed_count += 1
	if all_visited:
		completed_count += 1
	if total >= 5:
		completed_count += 1
	if Extras.stage1_completed():
		completed_count += 1
	_body.add_child(_info_panel("%d / 4 BADGES EARNED" % completed_count, "Keep exploring the available stages to earn menu badges.", "ACHIEVEMENT COLLECTION"))
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 10)
	_body.add_child(row1)
	row1.add_child(_achievement_card("First Steps", "Launch any stage from Level Select.", total >= 1))
	row1.add_child(_achievement_card("Stage Explorer", "Launch Stage 1, 2 and 3 at least once each.", all_visited))
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 10)
	_body.add_child(row2)
	row2.add_child(_achievement_card("Dedicated Learner", "Launch stages 5 times in total from Level Select.", total >= 5))
	row2.add_child(_achievement_card("Drawing Challenge Clear", "Complete and verify Stage 1 drawing.", Extras.stage1_completed()))
	_body.add_child(_label("Stage 2/3 badges will need completion events in those scenes. They are not invented here.", 13, MUTED))
	var go := _button("VIEW MY PROGRESS", true, 190, 42)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_progress)
	_body.add_child(go)


func _show_missions() -> void:
	_menu_page("MISSION GUIDE", "Preview each stage without changing gameplay, answers or customer dialogue.")
	var titles := ["FLOOR PLAN DRAWING", "PIPE SHAFT Q&A", "S-CLASS KITCHEN SELECTION"]
	var details := [
		"Listen to the customer, draw the requested LDK boundary and check the measured layout.",
		"Explain what PS means and why it matters during renovation. Gemini is used when available, with a local fallback.",
		"Choose the kitchen layout and configuration, then identify the kitchen parts. Follow the existing in-stage progress flow."
	]
	for n in range(1, 4):
		var card := _info_panel(LocaleManager.text("STAGE %d  •  %s") % [n, LocaleManager.text(titles[n - 1])], details[n - 1], "MISSION %02d  •  AVAILABLE" % n)
		_body.add_child(card)
		var v := card.get_child(0) as VBoxContainer
		var start := _button("PLAY STAGE %d" % n, false, 154, 37)
		start.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		start.pressed.connect(_start_level.bind(n))
		v.add_child(start)
	_body.add_child(_label("STAGES 4–6  •  COMING SOON", 14, LOCKED))


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
