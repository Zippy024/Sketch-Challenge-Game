extends Control

signal drawing_status_changed(message: String)

const BASE_MM_PER_PX: float = 100.0 / 12.0
const TOLERANCE_MM: float = 0.0
const CORNER_SNAP_TOLERANCE_MM: float = 25.0

# AutoCAD-style numeric entry: type digits while a wall preview is active.
var typed_length: String = ""
var cursor_position: Vector2 = Vector2.ZERO

var lines: Array[PackedVector2Array] = []
var redo_lines: Array[PackedVector2Array] = []
var line_validation_state: Array[int] = []

var drawing_enabled: bool = false
var connected: bool = true
var drawing: bool = false

var chain_origin: Vector2 = Vector2.ZERO
var line_start: Vector2 = Vector2.ZERO
var line_end: Vector2 = Vector2.ZERO
var hover_mm: Vector2 = Vector2.ZERO

var selected_line_index: int = -1
var dragging_line_index: int = -1
var dragging_endpoint_index: int = -1
var drag_start_mm: Vector2 = Vector2.ZERO
var drag_orig_a: Vector2 = Vector2.ZERO
var drag_orig_b: Vector2 = Vector2.ZERO
var hovered_line_index: int = -1

var zoom_level: float = 1.0
var pan: Vector2 = Vector2(72, 60)
var middle_down: bool = false
var last_mouse: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	resized.connect(queue_redraw)
	# Numeric entry is drawn beside the cursor; no separate input control.

func _commit_typed_length() -> void:
	if not drawing or typed_length.is_empty():
		return
	var length_mm: float = float(typed_length)
	if length_mm <= 0.0:
		return
	var direction: Vector2 = line_end - line_start
	if direction.length_squared() < 0.001:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var end_point: Vector2 = line_start + direction * length_mm
	lines.append(PackedVector2Array([line_start, end_point]))
	redo_lines.clear()
	_clear_validation_highlights()
	line_start = end_point
	line_end = end_point
	typed_length = ""
	queue_redraw()
	drawing_status_changed.emit("%s mm wall drawn. Continue drawing." % _format_num(roundi(length_mm)))

func _clear_validation_highlights() -> void:
	line_validation_state.clear()

func set_drawing_enabled(enabled: bool) -> void:
	drawing_enabled = enabled
	drawing = false
	typed_length = ""
	dragging_line_index = -1
	selected_line_index = -1
	queue_redraw()

func set_chain_mode(enabled: bool) -> void:
	connected = enabled
	drawing = false

func _to_screen(p_mm: Vector2) -> Vector2:
	return p_mm / BASE_MM_PER_PX * zoom_level + pan

func _to_mm(p_px: Vector2) -> Vector2:
	return (p_px - pan) / zoom_level * BASE_MM_PER_PX

func _get_dynamic_snap_step() -> float:
	var effective_scale: float = zoom_level / BASE_MM_PER_PX
	if effective_scale >= 0.35:
		return 1.0
	elif effective_scale >= 0.12:
		return 10.0
	else:
		return 100.0

func _snap_grid(p_mm: Vector2) -> Vector2:
	var step: float = _get_dynamic_snap_step()
	return Vector2(roundf(p_mm.x / step) * step, roundf(p_mm.y / step) * step)

func _get_calibrated_length_mm(a_mm: Vector2, b_mm: Vector2) -> int:
	return roundi(a_mm.distance_to(b_mm))

func _snap(p_mm: Vector2, force_straight: bool = false, ignore_line: int = -1) -> Vector2:
	var snap_dist: float = 16.0 * BASE_MM_PER_PX / zoom_level
	for i in range(lines.size()):
		if i == ignore_line:
			continue
		for ep in lines[i]:
			if p_mm.distance_to(ep) < snap_dist:
				return ep

	var p: Vector2 = _snap_grid(p_mm)
	if not drawing:
		return p

	var raw_d: Vector2 = p_mm - line_start
	var adx: float = absf(raw_d.x)
	var ady: float = absf(raw_d.y)
	var near_horizontal: bool = (ady <= 120.0) or (adx > 0.0 and (ady / adx) < 0.12)
	var near_vertical: bool = (adx <= 120.0) or (ady > 0.0 and (adx / ady) < 0.12)

	if force_straight:
		if adx >= ady:
			near_horizontal = true
			near_vertical = false
		else:
			near_vertical = true
			near_horizontal = false

	var step: float = _get_dynamic_snap_step()
	if near_horizontal:
		p.y = line_start.y
		p.x = line_start.x + roundf((p_mm.x - line_start.x) / step) * step
	elif near_vertical:
		p.x = line_start.x
		p.y = line_start.y + roundf((p_mm.y - line_start.y) / step) * step
	else:
		p = Vector2(roundf(p_mm.x / step) * step, roundf(p_mm.y / step) * step)
	return p

func _find_hit_target(screen_pos: Vector2) -> Vector2i:
	var point_threshold: float = 12.0
	var seg_threshold: float = 12.0
	for i in range(lines.size() - 1, -1, -1):
		var a_px: Vector2 = _to_screen(lines[i][0])
		var b_px: Vector2 = _to_screen(lines[i][1])
		if screen_pos.distance_to(a_px) <= point_threshold:
			return Vector2i(i, 0)
		if screen_pos.distance_to(b_px) <= point_threshold:
			return Vector2i(i, 1)
	for i in range(lines.size() - 1, -1, -1):
		var a_px: Vector2 = _to_screen(lines[i][0])
		var b_px: Vector2 = _to_screen(lines[i][1])
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(screen_pos, a_px, b_px)
		if screen_pos.distance_to(closest) <= seg_threshold:
			return Vector2i(i, -1)
	return Vector2i(-1, -1)

func delete_selected_line() -> void:
	if selected_line_index >= 0 and selected_line_index < lines.size():
		lines.remove_at(selected_line_index)
		selected_line_index = -1
		_clear_validation_highlights()
		queue_redraw()
		drawing_status_changed.emit("Selected wall deleted.")

func _unhandled_input(event: InputEvent) -> void:
	if not drawing_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_DELETE, KEY_BACKSPACE] and selected_line_index >= 0 and not drawing:
			delete_selected_line()
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if drawing and drawing_enabled:
			var key_char: String = char(event.unicode)
			if key_char.length() == 1 and key_char >= "0" and key_char <= "9":
				if typed_length.length() < 10:
					typed_length += key_char
				queue_redraw()
				accept_event()
				return
			if event.keycode == KEY_BACKSPACE and not typed_length.is_empty():
				typed_length = typed_length.substr(0, typed_length.length() - 1)
				queue_redraw()
				accept_event()
				return
			if event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
				if not typed_length.is_empty():
					_commit_typed_length()
				else:
					drawing = false
				queue_redraw()
				accept_event()
				return
			if event.keycode == KEY_ESCAPE:
				if not typed_length.is_empty():
					typed_length = ""
				else:
					drawing = false
				queue_redraw()
				accept_event()
				return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		grab_focus()
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.15)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.15)
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			middle_down = mb.pressed
			last_mouse = mb.position
			accept_event()
			return

		if not drawing_enabled:
			return

		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and not typed_length.is_empty():
			_commit_typed_length()
			accept_event()
			return
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if dragging_line_index >= 0:
				dragging_line_index = -1
				dragging_endpoint_index = -1
				drawing_status_changed.emit("Wall moved.")
				queue_redraw()
				accept_event()
			return

		if not mb.pressed:
			return

		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if drawing:
				typed_length = ""
				drawing = false
				queue_redraw()
				drawing_status_changed.emit("Drawing stopped.")
			accept_event()
			return

		if mb.button_index == MOUSE_BUTTON_LEFT:
			if Input.is_key_pressed(KEY_SPACE):
				middle_down = true
				last_mouse = mb.position
				accept_event()
				return

			_clear_validation_highlights()

			# အစွန်းအမှတ် (Endpoints: hit.y == 0 သို့မဟုတ် 1) ကိုနှိပ်လျှင် Select မဖြစ်စေဘဲ Drawing စတင်ရန် ခွင့်ပြုမည်
			var hit: Vector2i = _find_hit_target(mb.position)
			if hit.x >= 0 and hit.y == -1 and not drawing:
				if selected_line_index == hit.x:
					selected_line_index = -1
					drawing_status_changed.emit("Selection cleared.")
				else:
					selected_line_index = hit.x
					dragging_line_index = hit.x
					dragging_endpoint_index = hit.y
					drag_start_mm = _snap_grid(_to_mm(mb.position))
					drag_orig_a = lines[hit.x][0]
					drag_orig_b = lines[hit.x][1]
					drawing_status_changed.emit("Wall selected & moving.")
				queue_redraw()
				accept_event()
				return
			elif not drawing:
				selected_line_index = -1
				queue_redraw()

			var point: Vector2 = _snap(_to_mm(mb.position), mb.shift_pressed)
			if not drawing:
				drawing = true
				chain_origin = point
				line_start = point
				line_end = point
				drawing_status_changed.emit("Click next point to draw wall.")
			else:
				if line_start.distance_to(point) >= 20.0:
					var seg_len: int = _get_calibrated_length_mm(line_start, point)
					lines.append(PackedVector2Array([line_start, point]))
					redo_lines.clear()
					line_start = point
					line_end = point
					drawing_status_changed.emit("%s mm wall drawn. Click next point." % _format_num(seg_len))
			queue_redraw()
			accept_event()

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if middle_down and not Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			middle_down = false
		if middle_down:
			pan += mm.position - last_mouse
			last_mouse = mm.position
			queue_redraw()
			accept_event()
			return

		if not drawing_enabled:
			return
		cursor_position = mm.position

		if dragging_line_index >= 0:
			var current_mm: Vector2 = _snap_grid(_to_mm(mm.position))
			var delta_mm: Vector2 = current_mm - drag_start_mm
			if dragging_endpoint_index == -1:
				lines[dragging_line_index][0] = drag_orig_a + delta_mm
				lines[dragging_line_index][1] = drag_orig_b + delta_mm
			queue_redraw()
			accept_event()
			return

		hover_mm = _snap(_to_mm(mm.position), mm.shift_pressed)
		if drawing:
			line_end = hover_mm
			hovered_line_index = -1
		else:
			var hit: Vector2i = _find_hit_target(mm.position)
			hovered_line_index = hit.x
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if (hit.x >= 0 and hit.y == -1) else Control.CURSOR_CROSS
		queue_redraw()
		accept_event()

func _zoom_at(focus: Vector2, factor: float) -> void:
	var before: Vector2 = _to_mm(focus)
	zoom_level = clampf(zoom_level * factor, 0.2, 8.0)
	pan = focus - before / BASE_MM_PER_PX * zoom_level
	queue_redraw()

func zoom_in() -> void: _zoom_at(size * 0.5, 1.18)
func zoom_out() -> void: _zoom_at(size * 0.5, 1.0 / 1.18)
func reset_view() -> void:
	zoom_level = 1.0
	pan = Vector2(72, 60)
	queue_redraw()

func clear_canvas() -> void:
	typed_length = ""
	lines.clear()
	redo_lines.clear()
	selected_line_index = -1
	_clear_validation_highlights()
	drawing = false
	typed_length = ""
	dragging_line_index = -1
	queue_redraw()

func undo_line() -> void:
	if not lines.is_empty():
		redo_lines.append(lines.pop_back())
	selected_line_index = -1
	_clear_validation_highlights()
	drawing = false
	typed_length = ""
	dragging_line_index = -1
	queue_redraw()

func redo_line() -> void:
	if not redo_lines.is_empty():
		lines.append(redo_lines.pop_back())
		selected_line_index = -1
		_clear_validation_highlights()
		drawing = false
		dragging_line_index = -1
		queue_redraw()

func delete_last_line() -> void:
	if not lines.is_empty():
		lines.pop_back()
	selected_line_index = -1
	redo_lines.clear()
	_clear_validation_highlights()
	drawing = false
	typed_length = ""
	dragging_line_index = -1
	queue_redraw()

func _format_num(n: int) -> String:
	var s: String = str(abs(n))
	var res: String = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			res += ","
		res += s[i]
	return res

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("ffffff"), true)
	_draw_dynamic_grid()

	for i in range(lines.size()):
		var seg: PackedVector2Array = lines[i]
		var is_selected: bool = (i == selected_line_index)
		var is_active: bool = is_selected or (i == dragging_line_index) or (i == hovered_line_index and not drawing)
		var v_state: int = line_validation_state[i] if i < line_validation_state.size() else 0
		_draw_solid_wall(seg[0], seg[1], is_active, v_state, is_selected)

	if drawing and drawing_enabled:
		_draw_preview_wall(line_start, line_end)
		if not typed_length.is_empty():
			var display_text: String = typed_length + " mm"
			var font: Font = ThemeDB.fallback_font
			var box_size: Vector2 = font.get_string_size(display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15) + Vector2(18, 12)
			var box_pos: Vector2 = cursor_position + Vector2(18, 18)
			box_pos.x = clampf(box_pos.x, 0.0, maxf(0.0, size.x - box_size.x))
			box_pos.y = clampf(box_pos.y, 0.0, maxf(0.0, size.y - box_size.y))
			draw_rect(Rect2(box_pos, box_size), Color("eff6ff"), true)
			draw_rect(Rect2(box_pos, box_size), Color("3b82f6"), false, 1.5)
			draw_string(font, box_pos + Vector2(9, 19), display_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("1e40af"))
	elif drawing_enabled:
		draw_circle(_to_screen(hover_mm), 3.8, Color("111827"))

func _draw_dynamic_grid() -> void:
	var minor_mm: float = 100.0
	var major_mm: float = 1000.0
	var minor_px: float = minor_mm / BASE_MM_PER_PX * zoom_level
	var major_px: float = major_mm / BASE_MM_PER_PX * zoom_level

	if minor_px >= 8.0:
		var sub_mm: float = 10.0 if minor_px >= 80.0 else 100.0
		var sub_px: float = sub_mm / BASE_MM_PER_PX * zoom_level

		var x: float = fposmod(pan.x, sub_px)
		while x < size.x:
			var col: Color = Color(0.9, 0.93, 0.97, 0.5) if is_zero_approx(fposmod(x - pan.x, major_px)) else Color(0.94, 0.96, 0.98, 0.7)
			draw_line(Vector2(x, 0), Vector2(x, size.y), col, 1.0)
			x += sub_px

		var y: float = fposmod(pan.y, sub_px)
		while y < size.y:
			var col: Color = Color(0.9, 0.93, 0.97, 0.5) if is_zero_approx(fposmod(y - pan.y, major_px)) else Color(0.94, 0.96, 0.98, 0.7)
			draw_line(Vector2(0, y), Vector2(size.x, y), col, 1.0)
			y += sub_px

	var mx: float = fposmod(pan.x, major_px)
	while mx < size.x:
		draw_line(Vector2(mx, 0), Vector2(mx, size.y), Color("cbd5e1"), 1.2)
		mx += major_px
	var my: float = fposmod(pan.y, major_px)
	while my < size.y:
		draw_line(Vector2(0, my), Vector2(size.x, my), Color("cbd5e1"), 1.2)
		my += major_px

func _draw_solid_wall(a_mm: Vector2, b_mm: Vector2, highlight: bool, v_state: int, is_selected: bool) -> void:
	var a: Vector2 = _to_screen(a_mm)
	var b: Vector2 = _to_screen(b_mm)

	var glow_col: Color = Color(0.06, 0.09, 0.16, 0.22 if is_selected else (0.16 if highlight else 0.05))
	var line_col: Color = Color("2563eb") if is_selected else (Color("000000") if not highlight else Color("1e293b"))
	var text_col: Color = Color("1d4ed8") if is_selected else Color("0f172a")

	if v_state == -1:
		glow_col = Color(0.94, 0.27, 0.27, 0.28)
		line_col = Color("dc2626")
		text_col = Color("b91c1c")
	elif v_state == 1:
		glow_col = Color(0.13, 0.77, 0.37, 0.20)
		line_col = Color("16a34a")
		text_col = Color("15803d")

	draw_line(a, b, glow_col, 9.0 if is_selected else 8.0, true)
	draw_line(a, b, line_col, 4.2 if is_selected else 3.8, true)
	draw_circle(a, 5.0 if is_selected else 4.2, line_col)
	draw_circle(b, 5.0 if is_selected else 4.2, line_col)

	var length: int = _get_calibrated_length_mm(a_mm, b_mm)
	if length <= 0:
		return

	var direction: Vector2 = (b - a).normalized()
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	if absf(direction.y) > absf(direction.x):
		if normal.x > 0:
			normal = -normal
	elif normal.y > 0:
		normal = -normal

	var label: String = _format_num(length)
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var center_pos: Vector2 = (a + b) * 0.5 + normal * 18.0

	var pad: Vector2 = Vector2(4, 2)
	var bg_rect: Rect2 = Rect2(
		center_pos - Vector2(text_size.x * 0.5, text_size.y * 0.5) - pad,
		text_size + pad * 2.0
	)
	var badge_bg: Color = Color(0.9, 0.95, 1.0, 0.95) if is_selected else (Color(1.0, 0.93, 0.93, 0.94) if v_state == -1 else Color(1, 1, 1, 0.90))
	draw_rect(bg_rect, badge_bg, true)
	if is_selected:
		draw_rect(bg_rect, Color("2563eb"), false, 1.4)
	elif v_state == -1:
		draw_rect(bg_rect, Color("ef4444"), false, 1.2)

	draw_string(
		font,
		Vector2(center_pos.x - text_size.x * 0.5, center_pos.y + text_size.y * 0.32),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		text_col
	)

func _draw_preview_wall(a_mm: Vector2, b_mm: Vector2) -> void:
	var a: Vector2 = _to_screen(a_mm)
	var b: Vector2 = _to_screen(b_mm)
	var preview_col: Color = Color("1f2937")
	draw_line(a, b, Color(0.12, 0.16, 0.22, 0.15), 7.0, true)
	draw_line(a, b, preview_col, 3.4, true)
	draw_circle(a, 4.0, preview_col)
	draw_circle(b, 4.5, preview_col)

	var length: int = _get_calibrated_length_mm(a_mm, b_mm)
	if length <= 0:
		return
	var label: String = _format_num(length)

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(
		font,
		b + Vector2(-text_size.x * 0.5, 22),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color("0f172a")
	)

func analyze_reference() -> bool:
	# Each wall is checked independently. A 1 mm difference is WRONG.
	_clear_validation_highlights()
	drawing = false
	typed_length = ""
	selected_line_index = -1
	line_validation_state.resize(lines.size())
	for i in range(lines.size()):
		line_validation_state[i] = -1

	if lines.size() != 6:
		queue_redraw()
		return false

	# Role order: TOP, RIGHT UPPER, STEP, RIGHT LOWER, BOTTOM, LEFT.
	var target_lengths: Array[int] = [7380, 2360, 300, 1040, 7680, 3400]
	var roles: Array[int] = [-1, -1, -1, -1, -1, -1]
	var horizontal: Array[int] = []
	var vertical: Array[int] = []
	var all_valid: bool = true

	for i in range(lines.size()):
		var seg: PackedVector2Array = lines[i]
		var dx: float = absf(seg[1].x - seg[0].x)
		var dy: float = absf(seg[1].y - seg[0].y)
		# Classify by dominant axis so a slightly angled wall does not
		# prevent all the OTHER walls from receiving their own results.
		if dx >= dy:
			horizontal.append(i)
		else:
			vertical.append(i)

	if horizontal.size() != 3 or vertical.size() != 3:
		queue_redraw()
		return false

	# Assign wall roles by location, NOT by exact endpoint coordinates.
	# Thus an error on LEFT does not make BOTTOM appear wrong.
	var step_i: int = horizontal[0]
	for idx in horizontal:
		if _get_calibrated_length_mm(lines[idx][0], lines[idx][1]) < _get_calibrated_length_mm(lines[step_i][0], lines[step_i][1]):
			step_i = idx
	roles[step_i] = 2
	var other_h: Array[int] = []
	for idx in horizontal:
		if idx != step_i:
			other_h.append(idx)
	var y0: float = (lines[other_h[0]][0].y + lines[other_h[0]][1].y) * 0.5
	var y1: float = (lines[other_h[1]][0].y + lines[other_h[1]][1].y) * 0.5
	roles[other_h[0]] = 0 if y0 < y1 else 4
	roles[other_h[1]] = 4 if y0 < y1 else 0

	var left_i: int = vertical[0]
	for idx in vertical:
		var cx: float = (lines[idx][0].x + lines[idx][1].x) * 0.5
		var lx: float = (lines[left_i][0].x + lines[left_i][1].x) * 0.5
		if cx < lx:
			left_i = idx
	roles[left_i] = 5
	var other_v: Array[int] = []
	for idx in vertical:
		if idx != left_i:
			other_v.append(idx)
	var cy0: float = (lines[other_v[0]][0].y + lines[other_v[0]][1].y) * 0.5
	var cy1: float = (lines[other_v[1]][0].y + lines[other_v[1]][1].y) * 0.5
	roles[other_v[0]] = 1 if cy0 < cy1 else 3
	roles[other_v[1]] = 3 if cy0 < cy1 else 1

	var by_role: Array[int] = [-1, -1, -1, -1, -1, -1]
	for i in range(lines.size()):
		var role: int = roles[i]
		if role < 0:
			all_valid = false
			continue
		by_role[role] = i
		var measured_mm: int = _get_calibrated_length_mm(lines[i][0], lines[i][1])
		var dx_mm: float = absf(lines[i][1].x - lines[i][0].x)
		var dy_mm: float = absf(lines[i][1].y - lines[i][0].y)
		# Display a green wall only when BOTH its length and axis are exact
		# to the nearest whole millimetre.
		var axis_ok: bool = roundi(dy_mm) == 0 if role in [0, 2, 4] else roundi(dx_mm) == 0
		if measured_mm == target_lengths[role] and axis_ok:
			line_validation_state[i] = 1
		else:
			line_validation_state[i] = -1
			all_valid = false

	# Also require a single connected, correctly ordered six-wall outline.
	# This global shape check affects PASS/FAIL, but does not turn
	# individually correct wall lengths red.
	for role in range(6):
		var next_role: int = (role + 1) % 6
		if by_role[role] < 0 or by_role[next_role] < 0:
			all_valid = false
			continue
		var first: PackedVector2Array = lines[by_role[role]]
		var second: PackedVector2Array = lines[by_role[next_role]]
		var joined: bool = false
		for a in first:
			for b in second:
				if a.distance_to(b) < 0.5:
					joined = true
		if not joined:
			all_valid = false

	# The small step must project outward to the right.
	var top: PackedVector2Array = lines[by_role[0]]
	var bottom: PackedVector2Array = lines[by_role[4]]
	var step: PackedVector2Array = lines[by_role[2]]
	var top_right_x: float = maxf(top[0].x, top[1].x)
	var bottom_right_x: float = maxf(bottom[0].x, bottom[1].x)
	var step_left_x: float = minf(step[0].x, step[1].x)
	var step_right_x: float = maxf(step[0].x, step[1].x)
	if not (step_left_x >= top_right_x - 0.5 and step_right_x <= bottom_right_x + 0.5 and bottom_right_x > top_right_x):
		all_valid = false

	queue_redraw()
	return all_valid
