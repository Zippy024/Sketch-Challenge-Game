extends Control
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")

func _ready() -> void:
	name="HomeStageProgress"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var total:=0
	for stage in range(1,4):total+=int(Rating.best(stage).get("stars",0))
	var stage:=Progress.resume_stage() if Progress.has_session() else 0
	var surface:=Panel.new()
	surface.name="HomeProgressSummary"
	surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=UI.box(Color("e6f7ff"),Color("a5dbfa"),21,0)
	style.set_border_width_all(2)
	style.shadow_color=Color(0.06,0.28,0.43,0.12)
	style.shadow_size=5
	surface.add_theme_stylebox_override("panel",style)
	add_child(surface)
	surface.position=Vector2.ZERO
	surface.size=Vector2(505,86)
	var divider:=ColorRect.new()
	divider.color=Color("b3d5ea")
	divider.mouse_filter=Control.MOUSE_FILTER_IGNORE
	surface.add_child(divider)
	divider.position=Vector2(252,19)
	divider.size=Vector2(2,48)
	for i in range(2):
		var tile:=Control.new()
		tile.name="HomeBestStars" if i==0 else "HomeLastPlayed"
		tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		surface.add_child(tile)
		tile.position=Vector2(0 if i==0 else 256,0)
		tile.size=Vector2(249,86)
		var icon:=TextureRect.new()
		icon.texture=UI.icon("star" if i==0 else "plan")
		icon.modulate=Color("e2a625") if i==0 else Color("087bbb")
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
		icon.position=Vector2(15,25)
		icon.size=Vector2(38,36)
		var label:=UI.label("",18,true)
		label.add_theme_color_override("font_color",Color("0e3567"))
		label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(label)
		label.position=Vector2(60,9)
		label.size=Vector2(188,68)
		if i==0:
			tile.set_meta("stars",total)
			label.name="HomeStarCount"
			label.text=UI.text("%d / 9 stars")%total
		else:
			tile.set_meta("stage",stage)
			label.text=UI.text("Last played:")
			label.add_theme_font_size_override("font_size",13)
			label.position.y=10
			label.size.y=26
			var value:=UI.label("",19,true)
			value.name="HomeLastPlayedValue"
			value.add_theme_color_override("font_color",Color("0e3567"))
			value.mouse_filter=Control.MOUSE_FILTER_IGNORE
			tile.add_child(value)
			value.position=Vector2(60,39)
			value.size=Vector2(183,35)
			value.text=UI.text("Stage %d")%stage if stage>0 else UI.text("Not started")
