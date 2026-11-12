extends Control
signal next_requested
signal levels_requested
signal home_requested
signal retry_requested

const UI = preload("res://KitchenUI.gd")
const Progress = preload("res://GameProgress.gd")
const Rating = preload("res://StageRating.gd")
const POPUP_SIZE := Vector2(880, 560)
var stage_index: int = 1
var title_text: String = "Stage complete!"
var next_text: String = "Next Stage"
var levels_text: String = "View Levels"
var _design: Control

func configure(title_value: String, _subtitle: String = "", next_value: String = "Next Stage", levels_value: String = "View Levels") -> void:
	title_text = title_value
	next_text = next_value
	levels_text = levels_value

func _tr(en: String, my: String, jp: String) -> String:
	match Progress.get_language():
		"mm": return my
		"jp": return jp
	return en

func _put(parent: Control, node: Control, rect: Rect2) -> void:
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size

func _caption(value: String, rect: Rect2, font_size: int, bold: bool = false, ink: Color = UI.INK, numeric: bool = false) -> Label:
	# Establish the wrapping width before text can raise the label's minimum height.
	var label := UI.label("", font_size, bold, ink)
	if numeric:label.add_theme_font_override("font",UI.font(bold,"en"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_put(_design, label, rect)
	label.text = value
	return label

func _panel(name: String, rect: Rect2, fill: Color, outline: Color, radius: int = 17) -> Panel:
	var panel := Panel.new()
	panel.name = name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UI.box(fill, outline, radius, 0)
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	_put(_design, panel, rect)
	return panel

func _svg(name: String, markup: String, rect: Rect2) -> TextureRect:
	var image := Image.new()
	image.load_svg_from_buffer(markup.to_utf8_buffer())
	var sprite := TextureRect.new()
	sprite.name = name
	sprite.texture = ImageTexture.create_from_image(image)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(_design, sprite, rect)
	return sprite

func _star(earned: bool) -> String:
	var fill := "#ffd457" if earned else "#dae4ec"
	var stroke := "#d8941b" if earned else "#adbecb"
	var shine := "#fff5af" if earned else "#f7fbff"
	return '<svg xmlns="http://www.w3.org/2000/svg" width="92" height="92" viewBox="0 0 92 92"><defs><linearGradient id="a" x1="0" x2="0.2" y1="0" y2="1"><stop stop-color="'+shine+'"/><stop offset="1" stop-color="'+fill+'"/></linearGradient></defs><path d="M46 6L58 31L85 35L66 54L70 82L46 69L22 82L26 54L7 35L34 31Z" stroke="'+stroke+'" stroke-width="3.2" stroke-linejoin="round" fill="url(#a)"/><path d="M46 16L54 35L75 38" stroke="#fff" stroke-opacity=".6" stroke-width="2.5" stroke-linecap="round" fill="none"/></svg>'

func _action(name: String, caption: String, icon: String, rect: Rect2, primary: bool, callback: Callable) -> Button:
	var button := UI.button(caption, callback, primary, 0, 16)
	button.name = name
	button.icon = UI.icon(icon)
	var color := Color.WHITE if primary else Color("008f98")
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		button.add_theme_color_override(state, color)
	_put(_design, button, rect)
	return button

func _ready() -> void:
	theme = UI.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var result: Dictionary = Rating.finish(stage_index)
	var stars: int = int(result["stars"])
	var seconds: int = int(result["seconds"])
	var errors: int = int(result["mistakes"])
	var reduced := OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches", true))
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.08, 0.11, 0.63)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var confetti := preload("res://ConfettiRain.gd").new()
	confetti.name = "CompletionConfetti"
	add_child(confetti)
	_design = Control.new()
	_design.name = "ResultPopupContent"
	_design.size = POPUP_SIZE
	add_child(_design)
	var card := _panel("MissionCompleteCard", Rect2(0, 0, 880, 560), Color("f3fcff"), Color("9cdae2"), 27)
	var border := card.get_theme_stylebox("panel") as StyleBoxFlat
	border.set_border_width_all(2)
	border.shadow_size = 16
	border.shadow_offset = Vector2(0, 7)
	border.shadow_color = Color(0.02, 0.14, 0.2, 0.23)
	_svg("ResultHeaderBackground", '<svg xmlns="http://www.w3.org/2000/svg" width="880" height="111"><defs><linearGradient id="g"><stop stop-color="#006779"/><stop offset=".5" stop-color="#009da6"/><stop offset="1" stop-color="#087988"/></linearGradient></defs><path d="M27 0H853Q880 0 880 27V111H0V27Q0 0 27 0Z" fill="url(#g)"/><path d="M35 7H844" stroke="#a5f8f8" stroke-width="2"/><path d="M760 0L861 107M798 0L879 82" stroke="#b3f8f4" stroke-opacity=".18" stroke-width="23"/></svg>', Rect2(1, 1, 878, 110))
	_svg("CompletionGoldMedal", '<svg xmlns="http://www.w3.org/2000/svg" width="90" height="90"><defs><linearGradient id="g" x2="0.2" y2="1"><stop stop-color="#fff3af"/><stop offset="1" stop-color="#eaa724"/></linearGradient></defs><circle cx="45" cy="45" r="39" fill="url(#g)" stroke="#fff6cc" stroke-width="4"/><path d="M25 45L40 60L66 32" stroke="white" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>', Rect2(400, -28, 80, 80))
	var title := _caption(UI.text("Stage %d complete!") % stage_index, Rect2(42, 42, 796, 56), 27, true, Color.WHITE)
	title.name = "CompletionTitle"
	_panel("CompletionPlanCard", Rect2(46, 141, 276, 238), Color("e9f7fb"), Color("b5e0e9"), 20)
	var blueprint := preload("res://CompletionBlueprint.gd").new()
	blueprint.name = "CompletionBlueprintGraphic"
	blueprint.stage_index = stage_index
	_put(_design, blueprint, Rect2(72, 156, 218, 192))
	var missions := ["LDK Boundary Drawing", "Pipe Shaft Q&A", "S-Class Kitchen Selection"]
	var mission := _caption(UI.text(missions[stage_index-1]), Rect2(344, 128, 482, 38), 17, true)
	mission.name = "CompletionMission"
	for i in range(3):
		var star := _svg("ResultStar%d" % (i+1), _star(i<stars), Rect2(432+i*110, 174, 88, 88))
		star.pivot_offset = star.size*0.5
		if not reduced:
			star.modulate.a = 0.0
			star.scale = Vector2(0.62, 0.62)
			var pop := star.create_tween()
			pop.tween_interval(0.18 + float(i)*0.16)
			pop.tween_property(star, "modulate:a", 1.0, 0.15)
			pop.parallel().tween_property(star, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var compliment := _tr("Excellent!", "အထူးကောင်းမွန်ပါတယ်!", "素晴らしい！") if stars == 3 else (_tr("Great job!", "အရမ်းကောင်းပါတယ်!", "よくできました！") if stars == 2 else _tr("Stage cleared!", "အဆင့်အောင်မြင်ပါပြီ!", "ステージクリア！"))
	_caption(compliment, Rect2(372, 258, 447, 37), 23, true, Color("007d86"))
	var rating_text := _caption(_tr("Score: %d / 3 Stars", "ကြယ်အဆင့် - %d / 3", "評価：%d / 3") % stars, Rect2(389, 297, 414, 28), 16, true)
	rating_text.name = "CompletionRating"
	_panel("CompletionTimeCard", Rect2(361, 329, 207, 76), Color("e5f6fa"), Color("b9dfe6"))
	_panel("CompletionMistakesCard", Rect2(584, 329, 234, 76), Color("fff4f5"), Color("efccd1"))
	_caption(_tr("TIME", "အချိန်", "時間"), Rect2(372, 336, 188, 24), 13, true, Color("387b87"))
	var time_value := _caption("%02d:%02d" % [seconds/60, seconds%60], Rect2(373, 355, 187, 45), 20, true, UI.INK, true)
	time_value.name = "CompletionTime"
	_caption(_tr("MISTAKES", "အမှားအရေအတွက်", "ミス回数"), Rect2(595, 336, 212, 24), 13, true, Color("aa6070"))
	var error_value := _caption(str(errors), Rect2(595, 355, 212, 45), 20, true, Color("af425b"), true)
	error_value.name = "CompletionMistakes"
	var goal: int = int(Rating.TARGET_SECONDS.get(stage_index, 300))
	var description := _tr("3★: 0 mistakes, within %d min   ·   2★: up to 2 mistakes, within %d min", "၃★ - အမှား ၀၊ %d မိနစ်အတွင်း  ·  ၂★ - အမှား ၂ ကြိမ်အထိ၊ %d မိနစ်အတွင်း", "３★：ミス0回・%d分以内　２★：ミス2回以内・%d分以内")
	var rule := _caption(description % [goal/60, goal*2/60], Rect2(41, 411, 798, 31), 13, false, Color("3e7280"))
	rule.name = "CompletionScoringRule"
	_panel("CompletionMessageCard", Rect2(45, 449, 790, 43), Color("def7f0"), Color("a3ddce"), 16)
	_caption(_tr("✓  Your kitchen challenge is complete!", "✓  မီးဖိုချောင်လေ့ကျင့်ခန်း အောင်မြင်ပါပြီ။", "✓  キッチンチャレンジをクリアしました！"), Rect2(58, 454, 763, 32), 16, true, Color("197b60"))
	var retry := _action("CompletionRetry", _tr("Retry", "ပြန်ကစားမည်", "もう一度"), "redo", Rect2(60, 507, 220, 45), false, func(): retry_requested.emit())
	retry.tooltip_text = _tr("Play this stage again", "ဒီအဆင့်ကို အသစ်ပြန်ကစားမည်", "このステージをやり直す")
	var next_label := _tr("Next Stage", "နောက်အဆင့်", "次のステージ") if stage_index<3 else _tr("View Results", "ရလဒ်ကြည့်ရန်", "結果を見る")
	var next := _action("CompletionNext", next_label, "play", Rect2(306, 502, 263, 53), true, func(): next_requested.emit())
	next.call_deferred("grab_focus")
	_action("CompletionHome", _tr("Home", "ပင်မမီနူး", "ホーム"), "home", Rect2(596, 507, 220, 45), false, func(): home_requested.emit())
	var levels := UI.button(levels_text, func(): levels_requested.emit(), false, 0, 12)
	levels.name = "CompletionLevels"
	levels.visible = false
	_design.add_child(levels)
	resized.connect(_fit)
	_fit()
	if not reduced:
		_design.modulate.a = 0
		create_tween().tween_property(_design, "modulate:a", 1.0, 0.27).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _fit() -> void:
	var factor := maxf(0.1, minf(1.0, minf((size.x-32.0)/POPUP_SIZE.x, (size.y-32.0)/POPUP_SIZE.y)))
	_design.scale = Vector2.ONE*factor
	_design.position = ((size-POPUP_SIZE*factor)*0.5).round()
