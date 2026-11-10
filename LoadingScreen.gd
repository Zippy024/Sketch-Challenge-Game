extends Control
signal finished
var _bar: ProgressBar
var _caption: Label
var _logo: TextureRect
var _elapsed: float = 0.0

func _ready() -> void:
	name = "KitchenLoadingScreen"
	set_meta("locale_ignore",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var photo := TextureRect.new()
	photo.texture = preload("res://LoadingAssets/BlueKitchen.png")
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(photo)
	photo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ring := GlowRing.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.resized.connect(ring.queue_redraw)
	_logo = TextureRect.new()
	_logo.texture = preload("res://LoadingAssets/KitchenLogo.webp")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_logo)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	var track := StyleBoxFlat.new()
	track.bg_color = Color("124d6d")
	track.set_corner_radius_all(10)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("63edff")
	fill.border_color = Color("d0fcff")
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(10)
	fill.shadow_color = Color(0.0, 0.8, 1.0, 0.35)
	fill.shadow_size = 7
	_bar.add_theme_stylebox_override("background", track)
	_bar.add_theme_stylebox_override("fill", fill)
	add_child(_bar)
	_caption = Label.new()
	_caption.name="LoadingCaption"
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.add_theme_color_override("font_color", Color.WHITE)
	_caption.add_theme_color_override("font_shadow_color", Color("12476b"))
	_caption.add_theme_constant_override("shadow_offset_y", 2)
	_caption.add_theme_font_size_override("font_size", 19)
	add_child(_caption)
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	var logo_width := minf(size.x * 0.46, 490.0)
	_logo.position = Vector2((size.x - logo_width) * 0.5, size.y * 0.025)
	_logo.size = Vector2(logo_width, size.y * 0.25)
	var bar_width := minf(size.x * 0.56, 640.0)
	_bar.position = Vector2((size.x - bar_width) * 0.5, size.y * 0.88)
	_bar.size = Vector2(bar_width, 16)
	_caption.position = Vector2((size.x - bar_width) * 0.5, size.y * 0.88 + 22)
	_caption.size = Vector2(bar_width, 32)
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	var fraction := minf(_elapsed / 2.1, 1.0)
	_bar.value = fraction * 100.0
	_caption.text = "Loading... %d%%" % roundi(fraction * 100.0)
	if fraction >= 1.0:
		set_process(false)
		finished.emit()
		queue_free()

class GlowRing extends Control:
	func _draw() -> void:
		var points := PackedVector2Array()
		for i in range(129):
			var angle := PI * float(i) / 128.0
			points.append(Vector2(size.x * 0.5 + cos(angle) * size.x * 0.355, size.y * 0.78 + sin(angle) * size.y * 0.075))
		draw_polyline(points, Color(0.1, 0.8, 1.0, 0.10), 18.0, true)
		draw_polyline(points, Color(0.2, 0.9, 1.0, 0.23), 9.0, true)
		draw_polyline(points, Color(0.7, 1.0, 1.0, 0.9), 2.0, true)
