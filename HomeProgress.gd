extends Control
const UI=preload("res://KitchenUI.gd")
const Progress=preload("res://GameProgress.gd")
const Rating=preload("res://StageRating.gd")
var _current: int=0
var _centers=[Vector2(58,24),Vector2(209,24),Vector2(360,24)]

func _ready() -> void:
	name="HomeStageProgress"
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	_current=Progress.resume_stage() if Progress.has_session() else Progress.next_stage()
	if Progress.is_completed(_current):_current=Progress.next_stage()
	if Progress.completed_count()==3:_current=0
	for stage in range(1,4):
		var marker:=Control.new()
		marker.name="HomeProgressStage%d"%stage
		marker.mouse_filter=Control.MOUSE_FILTER_IGNORE
		marker.set_meta("completed",Progress.is_completed(stage))
		marker.set_meta("current",stage==_current)
		marker.set_meta("stars",int(Rating.best(stage).get("stars",0)))
		add_child(marker)
		marker.position=_centers[stage-1]-Vector2(56,22)
		marker.size=Vector2(112,104)
		var number:=UI.label("",14,true)
		number.add_theme_font_override("font",UI.font(true,"en"))
		number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		marker.add_child(number)
		number.position=Vector2(34,0)
		number.size=Vector2(44,44)
		number.text="" if Progress.is_completed(stage) else str(stage)
		number.add_theme_color_override("font_color",UI.TEAL if stage==_current else UI.MUTED)
		var caption:=UI.label("",12,true)
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		marker.add_child(caption)
		caption.position=Vector2(0,43)
		caption.size=Vector2(112,36)
		caption.text=UI.text("Stage %d")%stage

func _draw() -> void:
	for i in range(2):
		draw_line(_centers[i]+Vector2(20,0),_centers[i+1]-Vector2(20,0),UI.TEAL if Progress.is_completed(i+1) else Color("c7d7d5"),2,true)
	for stage in range(1,4):
		var center: Vector2=_centers[stage-1]
		var completed:=Progress.is_completed(stage)
		var current:=stage==_current
		draw_circle(center,16,UI.TEAL if completed else Color("fafffc"))
		draw_arc(center,16,0,TAU,48,UI.TEAL if current or completed else Color("b4cbc8"),1.5,true)
		if current:draw_arc(center,21,0,TAU,48,Color("87bab6"),1,true)
		if completed:draw_polyline(PackedVector2Array([center+Vector2(-6,0),center+Vector2(-1,5),center+Vector2(7,-5)]),Color.WHITE,2.5,true)
		var earned:=int(Rating.best(stage).get("stars",0))
		for i in range(3):
			var star:=PackedVector2Array()
			var point:=center+Vector2((i-1)*18,70)
			for n in range(10):
				var angle: float=-PI/2+float(n)*PI/5
				star.append(point+Vector2(cos(angle),sin(angle))*(7 if n%2==0 else 3.2))
			draw_colored_polygon(star,Color("e4b753") if i<earned else Color("e3eae7"))
			star.append(star[0])
			draw_polyline(star,Color("b5944e") if i<earned else Color("b5c7c1"),0.8,true)
