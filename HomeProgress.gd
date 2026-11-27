extends Control
const UI=preload("res://KitchenUI.gd")
const Aqua=preload("res://AquaStyle.gd")
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")

func _ready() -> void:
	name="HomeStageProgress"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var total: int=0
	for stage in range(1,4):total+=int(Rating.best(stage).get("stars",0))
	for i in range(2):
		var tile:=Panel.new()
		tile.name="HomeBestStars" if i==0 else "HomeLastPlayed"
		tile.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel",Aqua.surface(false,false,80))
		add_child(tile)
		tile.position=Vector2(i*246,0)
		tile.size=Vector2(230,80)
		var icon:=TextureRect.new()
		icon.texture=UI.icon("star" if i==0 else "plan")
		icon.modulate=Color("e8b446") if i==0 else UI.TEAL
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(icon)
		icon.position=Vector2(14,22)
		icon.size=Vector2(34,34)
		var label:=UI.label("",18,true)
		tile.add_child(label)
		label.position=Vector2(58,8)
		label.size=Vector2(160,62)
		if i==0:
			label.text=UI.text("%d / 9 stars")%total
			tile.set_meta("stars",total)
		else:
			var stage:=Progress.resume_stage() if Progress.has_session() else 0
			tile.set_meta("stage",stage)
			label.text=UI.text("Last played:")
			label.add_theme_font_size_override("font_size",12)
			label.position.y=7
			label.size.y=27
			var value:=UI.label("",17,true)
			tile.add_child(value)
			value.position=Vector2(58,32)
			value.size=Vector2(160,38)
			value.text=UI.text("Stage %d")%stage if stage>0 else UI.text("Not started")
