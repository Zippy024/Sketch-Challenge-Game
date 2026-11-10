extends Control

# V8: native interactive menu over a clean kitchen-background photo. Level list is text-only.
# Compatible with the existing Stage 1/2 scenes, saved progression and pause/resume.
signal resume_requested

const Progress = preload("res://GameProgress.gd")
const BilingualTheme: Theme = preload("res://WebBilingualTheme.tres")
const Extras = preload("res://MenuExtras.gd")

const BG := Color("f5f5f1")
const WHITE := Color("ffffff")
const INK := Color("152f32")
const MUTED := Color("647780")
const GREEN := Color("007c5e")
const GREEN_DARK := Color("006448")
const GREEN_PALE := Color("e2f2ea")
const BORDER := Color("d6e0e0")
const GOLD := Color("d5ac72")
const LOCKED := Color("a3afb4")

var is_pause_overlay: bool = false
var pause_level: int = 0
var _body: VBoxContainer
var _jp_button: Button
var _mm_button: Button
var _scroll: ScrollContainer
var _volume_value: float = 0.85
var _reset_armed: bool = false
var _stats_reset_armed: bool = false


func _ready() -> void:
	theme = BilingualTheme
	_volume_value = Extras.volume()
	Extras.apply_audio()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame()
	resized.connect(_fit_content)
	_fit_content()
	if is_pause_overlay or Progress.show_levels_on_open:
		Progress.show_levels_on_open = false
		_show_levels()
	else:
		if OS.has_feature("web"):
			_show_home()
		else:
			var loading := preload("res://LoadingScreen.gd").new()
			loading.finished.connect(_show_home)
			add_child(loading)
	if OS.has_feature("web"):
		call_deferred("_notify_loading_ready")


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
	l.text = value
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(title: String, primary: bool = false, min_w: float = 165.0, min_h: float = 46.0) -> Button:
	var b := Button.new()
	b.text = title
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
	return b


func _build_frame() -> void:
	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", _style(BG, BG, 0))
	add_child(bg)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	bg.add_child(outer)

	var top := PanelContainer.new()
	top.custom_minimum_size.y = 65
	top.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 0))
	outer.add_child(top)
	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 28)
	header_margin.add_theme_constant_override("margin_right", 28)
	header_margin.add_theme_constant_override("margin_top", 8)
	header_margin.add_theme_constant_override("margin_bottom", 8)
	top.add_child(header_margin)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header_margin.add_child(header)

	# Single brand mark shared by the in-game header, desktop icon and Web favicon.
	var mark := TextureRect.new()
	mark.custom_minimum_size = Vector2(45, 45)
	mark.texture = preload("res://Branding/SketchChallengeLogo.png")
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(mark)

	var brand := _label("Kitchen Layout Game", 19, INK)
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)

	_jp_button = _button("日本語", false, 69, 36)
	_mm_button = _button("မြန်မာ", false, 69, 36)
	for b in [_jp_button, _mm_button]:
		b.add_theme_font_size_override("font_size", 12)
		header.add_child(b)
	_jp_button.pressed.connect(func() -> void: _set_language("jp"))
	_mm_button.pressed.connect(func() -> void: _set_language("mm"))
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
	for b in [_jp_button, _mm_button]:
		var selected: bool = (b == _jp_button and Progress.get_language() == "jp") or (b == _mm_button and Progress.get_language() == "mm")
		b.add_theme_stylebox_override("normal", _style(GREEN if selected else WHITE, GREEN if selected else BORDER, 10, 7))
		b.add_theme_color_override("font_color", WHITE if selected else INK)
		b.add_theme_color_override("font_hover_color", WHITE if selected else GREEN)


func _clear() -> void:
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()
	_scroll.scroll_vertical = 0


# V8: The background is only a photograph. All headings, card graphics,
# language buttons and actions are genuine Godot Controls (not screenshot text).
func _show_home() -> void:
	_clear()
	var hero := PanelContainer.new()
	hero.custom_minimum_size.y = 624
	hero.clip_contents = true
	hero.add_theme_stylebox_override("panel", _style(Color("f9f6ef"), Color("e8e4dc"), 17))
	_body.add_child(hero)
	var stage := Control.new()
	stage.custom_minimum_size.y = 624
	hero.add_child(stage)

	var photo := TextureRect.new()
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	photo.texture = preload("res://MenuAssets/KitchenIntroV8.jpg")
	stage.add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The upper-left area is sunlit cream; match the reference typography and spacing.
	var margin := MarginContainer.new()
	stage.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 62)
	margin.add_theme_constant_override("margin_right", 55)
	margin.add_theme_constant_override("margin_top", 57)
	margin.add_theme_constant_override("margin_bottom", 42)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var heading_row := HBoxContainer.new()
	heading_row.add_theme_constant_override("separation", 22)
	content.add_child(heading_row)
	var symbol := TextureRect.new()
	symbol.texture = preload("res://MenuAssets/v8_house_dark.png")
	symbol.custom_minimum_size = Vector2(88, 88)
	symbol.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	symbol.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	symbol.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	symbol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading_row.add_child(symbol)
	var title_stack := VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", 0)
	heading_row.add_child(title_stack)
	var title := _label("Kitchen\nLayout Game", 49, INK)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_stack.add_child(title)
	var sub := _label("Draw  •  Design  •  Learn", 19, INK)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_stack.add_child(sub)

	var description := _label("Learn kitchen planning through real customer requests.\nDraw floor plans, design layouts, and build your skills\nstep by step.", 14, Color("53676d"))
	description.autowrap_mode = TextServer.AUTOWRAP_OFF
	content.add_child(description)
	var flexible_space := Control.new()
	flexible_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(flexible_space)

	# Three compact interactive tiles (icons are actual PNG textures, not glyphs).
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	tiles.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(tiles)
	tiles.add_child(_home_tile("Start Game", preload("res://MenuAssets/v9_play_white.png"), true, Callable(self, "_show_levels")))
	tiles.add_child(_home_tile("How to Play", preload("res://MenuAssets/v9_book_dark.png"), false, Callable(self, "_show_help")))
	tiles.add_child(_home_tile("Settings", preload("res://MenuAssets/v9_gear_dark.png"), false, Callable(self, "_show_settings")))

	# Menu-only features. Stages and their gameplay UI are not changed.
	var quick_actions := HBoxContainer.new()
	quick_actions.add_theme_constant_override("separation", 8)
	quick_actions.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(quick_actions)
	for item in [
		["PLAYER PROFILE", "_show_profile"],
		["MY PROGRESS", "_show_progress"],
		["ACHIEVEMENTS", "_show_achievements"]
	]:
		var action_btn := _button(str(item[0]), false, 144, 33)
		action_btn.add_theme_font_size_override("font_size", 11)
		action_btn.pressed.connect(Callable(self, str(item[1])))
		quick_actions.add_child(action_btn)
	if is_pause_overlay:
		# Optional direct way back when the Home icon was used from a paused level.
		var resume := _button("BACK TO GAME", false, 135, 32)
		resume.add_theme_font_size_override("font_size", 12)
		resume.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		resume.pressed.connect(_resume_paused)
		content.add_child(resume)


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
	_clear()
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	_body.add_child(top_row)
	var back := _button("BACK TO GAME" if is_pause_overlay else "BACK TO HOME", false, 134, 35)
	if is_pause_overlay:
		back.pressed.connect(_resume_paused)
	else:
		back.pressed.connect(_show_home)
	top_row.add_child(back)
	if is_pause_overlay:
		# HOME only changes this pause overlay's visible page. The stage scene
		# remains paused underneath, so BACK TO GAME still resumes the same work.
		var home_button := _button("", false, 43, 35)
		home_button.tooltip_text = "Home menu (game progress stays paused)"
		home_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var icon_holder := CenterContainer.new()
		icon_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		home_button.add_child(icon_holder)
		icon_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var home_img := TextureRect.new()
		home_img.texture = preload("res://MenuAssets/v9_house_dark.png")
		home_img.custom_minimum_size = Vector2(19, 19)
		home_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		home_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		home_img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		home_img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_holder.add_child(home_img)
		home_button.pressed.connect(_show_home)
		top_row.add_child(home_button)
	var heading := _label("SELECT A LEVEL", 25, INK, true)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(heading)
	var unlocked_count: int = Progress.get_highest_unlocked()
	var progress := _label("%d / 3 AVAILABLE" % unlocked_count, 12, GREEN, true)
	progress.custom_minimum_size.x = 125
	top_row.add_child(progress)
	_body.add_child(_label("Choose any available stage to play.", 14, MUTED, true))
	var guide_actions := HBoxContainer.new()
	guide_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(guide_actions)
	var missions_btn := _button("MISSION GUIDE", false, 146, 32)
	missions_btn.add_theme_font_size_override("font_size", 12)
	missions_btn.pressed.connect(_show_missions)
	guide_actions.add_child(missions_btn)
	var track := ProgressBar.new()
	track.custom_minimum_size.y = 7
	track.min_value = 0
	track.max_value = 3
	track.value = unlocked_count
	track.show_percentage = false
	track.add_theme_stylebox_override("background", _style(Color("dfe9e6"), Color("dfe9e6"), 8))
	track.add_theme_stylebox_override("fill", _style(GREEN, GREEN, 8))
	_body.add_child(track)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 9)
	_body.add_child(list)
	for n in range(1, 7):
		list.add_child(_level_row(n))


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
	_reset_armed = false
	_clear()
	_body.add_child(_label("SETTINGS", 31, INK))
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WHITE, BORDER, 18, 30))
	_body.add_child(panel)
	var contents := VBoxContainer.new()
	contents.add_theme_constant_override("separation", 20)
	panel.add_child(contents)
	contents.add_child(_label("LANGUAGE", 18, GREEN))
	var languages := HBoxContainer.new()
	contents.add_child(languages)
	var japanese := _button("日本語", false, 140, 48)
	japanese.pressed.connect(func() -> void: _set_language("jp"))
	languages.add_child(japanese)
	var myanmar := _button("မြန်မာ", false, 140, 48)
	myanmar.pressed.connect(func() -> void: _set_language("mm"))
	languages.add_child(myanmar)
	contents.add_child(_label("GAME VOLUME", 18, GREEN))
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = _volume_value
	volume.custom_minimum_size = Vector2(300, 36)
	volume.value_changed.connect(_on_volume_changed)
	contents.add_child(volume)
	var sound_row := HBoxContainer.new()
	sound_row.add_theme_constant_override("separation", 12)
	contents.add_child(sound_row)
	var sound_lbl := _label("MUTE ALL GAME AUDIO", 15, MUTED)
	sound_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_row.add_child(sound_lbl)
	var mute_toggle := CheckButton.new()
	mute_toggle.text = "OFF" if not Extras.muted() else "ON"
	mute_toggle.button_pressed = Extras.muted()
	mute_toggle.toggled.connect(func(value: bool) -> void:
		Extras.set_muted(value)
		Extras.apply_audio()
		mute_toggle.text = "ON" if value else "OFF"
	)
	sound_row.add_child(mute_toggle)
	contents.add_child(_label("DISPLAY", 18, GREEN))
	var full_row := HBoxContainer.new()
	full_row.add_theme_constant_override("separation", 12)
	contents.add_child(full_row)
	var fullscreen_btn := _button("TOGGLE FULLSCREEN", false, 220, 39)
	fullscreen_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fullscreen_btn.pressed.connect(_toggle_fullscreen)
	full_row.add_child(fullscreen_btn)
	full_row.add_child(_label("Browser fullscreen may require user permission.", 12, MUTED))
	contents.add_child(_label("Volume and mute settings are saved locally.", 12, MUTED))
	contents.add_child(_label("SAVED GAME PROGRESS", 18, GREEN))
	contents.add_child(_label("Reset saved stage progress; all available stages remain playable.", 14, MUTED))
	var reset := _button("RESET LEVEL PROGRESS", false, 255, 45)
	reset.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	reset.pressed.connect(_on_reset_progress_pressed.bind(reset))
	contents.add_child(reset)
	var go := _button("BACK TO HOME", true, 190, 48)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.pressed.connect(_show_home)
	contents.add_child(go)


func _on_reset_progress_pressed(b: Button) -> void:
	if not _reset_armed:
		_reset_armed = true
		b.text = "CONFIRM RESET"
		return
	_reset_armed = false
	Progress.reset_progress()
	_show_levels()


func _on_volume_changed(value: float) -> void:
	_volume_value = value
	Extras.set_volume(value)
	Extras.apply_audio()


func _start_level(level: int) -> void:
	if level > 3 or not Progress.is_level_unlocked(level):
		return
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
	var card := _info_panel("Welcome, " + Extras.get_name(), "Your display name and game menu statistics are saved locally on this device.", "PLAYER CARD")
	_body.add_child(card)
	var content := card.get_child(0) as VBoxContainer
	content.add_child(_label("DISPLAY NAME", 13, GREEN))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	var field := LineEdit.new()
	field.text = Extras.get_name()
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
	var summary := _info_panel("" + Extras.get_name() + "'s Learning Journey", "Stages launched from Level Select: %d" % Extras.total_count(), "PLAYER OVERVIEW")
	_body.add_child(summary)
	var v := summary.get_child(0) as VBoxContainer
	var last_label := "Not yet played"
	if Extras.last_stage() > 0:
		last_label = "Stage %d" % Extras.last_stage()
		if not Extras.last_date().is_empty():
			last_label += "  •  " + Extras.last_date()
	v.add_child(_label("Last selected: " + last_label, 13, MUTED))
	var grid := HBoxContainer.new()
	grid.add_theme_constant_override("separation", 11)
	_body.add_child(grid)
	for n in range(1, 4):
		var text_status := "COMPLETED (VERIFIED)" if n == 1 and Extras.stage1_completed() else ("NOT YET VERIFIED" if n == 1 else "COMPLETION NOT TRACKED")
		var panel := _info_panel("STAGE %d" % n, "Level Menu launches: %d\n%s" % [Extras.count(n), text_status], "AVAILABLE TO PLAY")
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(panel)
	_body.add_child(_info_panel("About progress", "Stage 1 completion is read from the existing verified save file. Stage 2/3 completion is not stored there, so this screen does not claim they were completed. Launch counts only include starts from Level Select."))
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
		var card := _info_panel("STAGE %d  •  %s" % [n, titles[n - 1]], details[n - 1], "MISSION %02d  •  AVAILABLE" % n)
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
