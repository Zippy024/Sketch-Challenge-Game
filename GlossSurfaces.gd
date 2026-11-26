extends RefCounted
# Shared, size-aware vector surfaces. Text remains native Godot controls.
static var _surfaces: Dictionary={}

static func vector(source: String) -> Texture2D:
	var texture=DPITexture.create_from_string(source,1.0)
	texture.set_size_override(Vector2i(texture.get_size()))
	return texture

static func surface(kind: String,width: int,height: int) -> Texture2D:
	var w=clampi(width,24,2048);var h=clampi(height,24,1024);var key="%s/%d/%d"%[kind,w,h]
	if _surfaces.has(key):return _surfaces[key]
	var top="#e7f5ff";var bottom="#c7e5fb";var edge="#f6fcff";var radius=18.0;var shadow=.20
	if kind=="header":top="#eaf8ff";bottom="#b9e0fb";edge="#f5fcff";radius=(h-5)*.5;shadow=.25
	elif kind=="speech":top="#e4f4ff";bottom="#b8defa";edge="#ffffff";radius=14
	elif kind=="tab":top="#f6fcff";bottom="#d0eaff";edge="#9ac7e9";radius=9;shadow=.08
	elif kind=="name":top="#f6fcff";bottom="#c7e5fb";edge="#9ec9eb";radius=9;shadow=.18
	elif kind=="danger":top="#fff9fa";bottom="#ffdce2";edge="#f5a5b3";radius=9
	elif kind=="button":top="#ffffff";bottom="#e7f3ff";edge="#79a9d6";radius=9;shadow=.16
	elif kind=="primary":top="#1b90ff";bottom="#0065df";edge="#4ca5f6";radius=9;shadow=.18
	elif kind=="round":top="#ffffff";bottom="#dcefff";edge="#9ec7eb";radius=(h-5)*.5;shadow=.20
	elif kind=="locked":top="#c9e2f6";bottom="#93bbdf";edge="#88afd1";radius=8;shadow=.16
	elif kind=="navy":top="#2b568a";bottom="#123562";edge="#7a9fc3";radius=7;shadow=.04
	elif kind=="reference":top="#f5fbff";bottom="#e3f2ff";edge="#b1d6f2";radius=16
	var defs='<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient><radialGradient id="light" cx=".32" cy=".22" r=".8"><stop stop-color="#ffffff" stop-opacity=".78"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient></defs>'%[top,bottom]
	var body='<rect x="1" y="4" width="%d" height="%d" rx="%s" fill="#1465aa" opacity="%s"/><rect x="1" y="1" width="%d" height="%d" rx="%s" fill="url(#g)" stroke="%s" stroke-width="1"/>'%[w-2,h-5,str(radius),str(shadow),w-2,h-5,str(radius),edge]
	if kind=="speech":
		body='<path d="M17 2H%dQ%d 2 %d 15V%dQ%d %d %d %dH17Q5 %d 5 %dV%dL1 %sL5 %dV15Q5 2 17 2Z" fill="url(#g)" stroke="%s" stroke-width="1"/>'%[w-15,w-2,w-2,h-16,w-2,h-5,w-15,h-5,h-5,h-16,roundi(h*.5)+6,str(h*.5),roundi(h*.5)-6,edge]
	elif kind=="folded_tab":
		body='<path d="M2 %dV9Q2 2 10 2H%dL%d 8H%dQ%d 8 %d 15V%dZ" fill="url(#g)" stroke="%s" stroke-width=".8"/>'%[h-4,w-24,w-17,w-10,w-2,w-2,h-4,edge]
	elif kind=="preview":
		body+='<rect x="3" y="3" width="%d" height="%d" rx="11" fill="url(#light)"/>'%[w-6,h-9]
	elif kind=="header":
		var scale=float(w)/1070.0
		body+='<path d="M%s 11V%dM%s 11V%d" stroke="#6f9ecb" stroke-width="1.2"/><path d="M%s %sH%s" stroke="#7faad0" stroke-width="2"/><path d="M%s %sH%s" stroke="#edf9ff" stroke-width="1"/>'%[str(roundf(151*scale)),h-14,str(roundf(839*scale)),h-14,str(roundf(164*scale)),str(roundf(25*scale)),str(roundf(828*scale)),str(roundf(164*scale)),str(roundf(24*scale)),str(roundf(828*scale))]
	if kind in ["frame","header","panel","reference","button","primary","name","tab"]:body+='<rect x="3" y="3" width="%d" height="%d" rx="%s" fill="none" stroke="#efffff" stroke-width="1"/>'%[w-6,h-9,str(radius-2)]
	if _surfaces.size()>24:_surfaces.clear()
	var texture=vector('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">'%[w,h]+defs+body+'</svg>')
	_surfaces[key]=texture
	return texture


static func bind_panel(panel: PanelContainer,kind: String,original: StyleBox) -> void:
	panel.set_meta("gloss_kind",kind)
	var margins=[]
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:margins.append(original.get_content_margin(side))
	panel.set_meta("gloss_margins",margins)
	if not panel.has_meta("gloss_panel_bound"):
		panel.set_meta("gloss_panel_bound",true)
		panel.resized.connect(queue_panel_refresh.bind(panel))
	queue_panel_refresh(panel)

static func queue_panel_refresh(panel: PanelContainer) -> void:
	# Layout can briefly report an oversized text column before word wrapping.
	# Rasterize only its final size instead of allocating a texture per resize.
	if not is_instance_valid(panel) or bool(panel.get_meta("gloss_refresh_pending",false)):return
	panel.set_meta("gloss_refresh_pending",true)
	refresh_panel.call_deferred(panel)

static func refresh_panel(panel: PanelContainer) -> void:
	if not is_instance_valid(panel):return
	panel.set_meta("gloss_refresh_pending",false)
	if panel.size.x<1 or panel.size.y<1:return
	var kind=str(panel.get_meta("gloss_kind",""))
	if kind.is_empty():return
	var style=StyleBoxTexture.new()
	style.texture=surface(kind,maxi(24,roundi(panel.size.x)),maxi(24,roundi(panel.size.y)))
	var margins=panel.get_meta("gloss_margins")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,margins[side])
	panel.add_theme_stylebox_override("panel",style)

static func bind_button(button: Button,primary: bool,warning: bool=false) -> void:
	button.set_meta("gloss_button",true)
	button.set_meta("gloss_primary",primary)
	button.set_meta("gloss_warning",warning)
	if not button.has_meta("gloss_button_bound"):
		button.set_meta("gloss_button_bound",true)
		button.resized.connect(refresh_button.bind(button))
	refresh_button(button)

static func disable_button(button: Button) -> void:button.set_meta("gloss_button",false)

static func refresh_button(button: Button) -> void:
	if not bool(button.get_meta("gloss_button",false)) or bool(button.get_meta("gloss_button_busy",false)):return
	button.set_meta("gloss_button_busy",true)
	var primary=bool(button.get_meta("gloss_primary"));var warning=bool(button.get_meta("gloss_warning"))
	var texture=surface("primary" if primary else ("danger" if warning else "button"),maxi(24,roundi(button.size.x)),maxi(24,roundi(button.size.y)))
	for state in ["normal","hover","pressed","disabled"]:
		var original=button.get_theme_stylebox(state)
		var style=StyleBoxTexture.new();style.texture=texture
		for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,original.get_content_margin(side))
		if state=="hover":style.modulate_color=Color("f1fbff")
		elif state=="pressed":style.modulate_color=Color("cceaf9")
		elif state=="disabled":style.modulate_color=Color("dcecf5")
		button.add_theme_stylebox_override(state,style)
	button.set_meta("gloss_button_busy",false)
