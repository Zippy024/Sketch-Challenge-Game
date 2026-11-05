extends PanelContainer
# Decorative stage-navigation ribbon. Stage labels are never interactive:
# this preserves the original level unlock / Q&A progression rules.
const TEAL := Color("87d3ae")
const TEXT := Color("f4f1e9")
const COPPER := Color("d7ab78")
const DIM := Color("a3b6ae")
var stage: int = 1

func _init(stage_index: int = 1) -> void:
	stage = clampi(stage_index, 1, 3)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color(0.035, 0.085, 0.075, 0.95)
	surface.border_color = Color(0.54, 0.64, 0.57, 0.50)
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(13)
	surface.set_content_margin_all(6)
	add_theme_stylebox_override("panel", surface)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 13)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	var heading := Label.new()
	heading.text = "KITCHEN  /  TRAINING CONSOLE"
	heading.custom_minimum_size.x = 270
	heading.add_theme_color_override("font_color", COPPER)
	heading.add_theme_font_size_override("font_size", 15)
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(heading)
	var stretch := Control.new()
	stretch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stretch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(stretch)
	for index in range(1, 4):
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("225a49") if index == stage else Color("223832")
		style.border_color = TEAL if index == stage else Color("4b625a")
		style.set_corner_radius_all(16)
		style.set_border_width_all(1)
		style.set_content_margin_all(5)
		pill.add_theme_stylebox_override("panel", style)
		row.add_child(pill)
		var caption := Label.new()
		caption.text = ("%02d  SKETCH" % index) if index == 1 else (("%02d  Q&A" % index) if index == 2 else ("%02d  MATERIALS" % index))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.custom_minimum_size.x = 128
		caption.add_theme_color_override("font_color", TEXT if index == stage else DIM)
		caption.add_theme_font_size_override("font_size", 13)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(caption)
