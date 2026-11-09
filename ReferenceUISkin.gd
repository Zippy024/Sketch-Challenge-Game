extends RefCounted
# Nine-patch capsule keeps the rounded ends crisp at different button widths.
static func primary_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = preload("res://MenuAssets/PrimaryCapsule.svg")
	style.texture_margin_left = 32
	style.texture_margin_right = 32
	style.texture_margin_top = 24
	style.texture_margin_bottom = 24
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
