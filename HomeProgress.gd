extends Control
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")

func _ready() -> void:
	name="HomeStageProgress"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var pill:=Panel.new()
	pill.name="HomeProgressCombinedPill"
	var style:=UI.box(Color("e7f7ff"),Color("8dcfff"),40,8)
	style.set_border_width_all(2)
	style.shadow_size=9
	style.shadow_color=Color(0.05,0.27,0.59,0.22)
	style.shadow_offset=Vector2(0,5)
	pill.add_theme_stylebox_override("panel",style)
	add_child(pill)
	pill.position=Vector2.ZERO
	pill.size=Vector2(456,80)
	var divider:=ColorRect.new()
	divider.color=Color("88b8d6")
	divider.mouse_filter=Control.MOUSE_FILTER_IGNORE
	pill.add_child(divider)
	divider.position=Vector2(224,13)
	divider.size=Vector2(2,54)
	var total:=0
	for stage in range(1,4):
		total+=int(Rating.best(stage).get("stars",0))
	for i in range(2):
		var tile:=Control.new()
		tile.name="HomeBestStars" if i==0 else "HomeLastPlayed"
		tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		pill.add_child(tile)
		tile.position=Vector2(0 if i==0 else 227,0)
		tile.size=Vector2(223,80)
		var icon:=TextureRect.new()
		icon.texture=UI.icon("star" if i==0 else "plan")
		icon.modulate=Color("f4b71b") if i==0 else Color("078ce7")
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
		icon.position=Vector2(20,20)
		icon.size=Vector2(38,38)
		var label:=UI.label("",21,true,Color("103274"))
		tile.add_child(label)
		label.position=Vector2(67,6)
		label.size=Vector2(146,67)
		if i==0:
			label.text="%d / 9 Stars"%total
			tile.set_meta("stars",total)
		else:
			var stage:=Progress.resume_stage() if Progress.has_session() else 0
			tile.set_meta("stage",stage)
			label.text=UI.text("Last Played:")
			label.add_theme_font_size_override("font_size",12)
			label.position.y=13
			label.size.y=25
			var value:=UI.label("",20,true,Color("09266a"))
			tile.add_child(value)
			value.position=Vector2(67,35)
			value.size=Vector2(146,32)
			value.text=UI.text("Stage %d")%stage if stage>0 else UI.text("Not started")
