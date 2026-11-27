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
	var top="#e5f4ff";var bottom="#b8dcff";var edge="#3a87c6";var radius=18.0;var shadow=.24
	if kind=="header":top="#b6e5ff";bottom="#71baff";edge="#3989c9";radius=(h-5)*.5;shadow=.25
	elif kind=="speech":top="#e1f3ff";bottom="#add7ff";edge="#70a8d4";radius=14
	elif kind=="tab":top="#e9f8ff";bottom="#b5ddff";edge="#397dcc";radius=9;shadow=.08
	elif kind=="name":top="#eaf8ff";bottom="#a9d8ff";edge="#397dcc";radius=9;shadow=.18
	elif kind=="danger":top="#fff3f5";bottom="#ffdee5";edge="#d7798d";radius=9
	elif kind=="button":top="#f0f8ff";bottom="#d8eaff";edge="#4d88be";radius=9;shadow=.14
	elif kind=="start":top="#22ce88";bottom="#0aa970";edge="#087c54";radius=16;shadow=.16
	elif kind=="primary":top="#168eff";bottom="#0766df";edge="#0757bf";radius=9;shadow=.16
	elif kind=="round":top="#ffffff";bottom="#e4efff";edge="#4d80ba";radius=(h-5)*.5;shadow=.20
	elif kind=="locked":top="#d4e7f7";bottom="#9abbdb";edge="#7b99b8";radius=8;shadow=.16
	elif kind=="navy":top="#2b568a";bottom="#123562";edge="#7a9fc3";radius=7;shadow=.04
	elif kind=="reference":top="#f2faff";bottom="#d2eaff";edge="#3a87c6";radius=16
	if kind in ["button","danger","primary","start","round","locked","navy"]:radius=(h-5)*.5
	var defs='<defs><linearGradient id="g" x2="0" y2="1"><stop stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient><radialGradient id="light" cx=".32" cy=".22" r=".8"><stop stop-color="#ffffff" stop-opacity=".78"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient></defs>'%[top,bottom]
	var body='<rect x="1" y="4" width="%d" height="%d" rx="%s" fill="#11375c" opacity="%s"/><rect x="1" y="1" width="%d" height="%d" rx="%s" fill="url(#g)" stroke="%s" stroke-width="1.4"/>'%[w-2,h-5,str(radius),str(shadow),w-2,h-5,str(radius),edge]
	if kind=="speech":
		body='<path d="M17 2H%dQ%d 2 %d 15V%dQ%d %d %d %dH17Q5 %d 5 %dV%dL1 %sL5 %dV15Q5 2 17 2Z" fill="url(#g)" stroke="%s" stroke-width="1"/>'%[w-15,w-2,w-2,h-16,w-2,h-5,w-15,h-5,h-5,h-16,roundi(h*.5)+6,str(h*.5),roundi(h*.5)-6,edge]
	elif kind=="folded_tab":
		body='<path d="M2 %dV9Q2 2 10 2H%dL%d 8H%dQ%d 8 %d 15V%dZ" fill="url(#g)" stroke="%s" stroke-width=".8"/>'%[h-4,w-24,w-17,w-10,w-2,w-2,h-4,edge]
	elif kind=="preview":
		body+='<rect x="3" y="3" width="%d" height="%d" rx="11" fill="url(#light)"/>'%[w-6,h-9]
	elif kind=="header":
		var scale=float(w)/1070.0
		body+='<path d="M%s 11V%dM%s 11V%d" stroke="#6f9ecb" stroke-width="1.2"/><path d="M%s %sH%s" stroke="#7faad0" stroke-width="2"/><path d="M%s %sH%s" stroke="#edf9ff" stroke-width="1"/>'%[str(roundf(151*scale)),h-14,str(roundf(718*scale)),h-14,str(roundf(193*scale)),str(roundf(25*scale)),str(roundf(643*scale)),str(roundf(193*scale)),str(roundf(24*scale)),str(roundf(643*scale))]
	if kind=="heading":
		body='<rect x="0" y="%d" width="66" height="3" rx="1.5" fill="#169cff"/><rect x="70" y="%d" width="14" height="3" rx="1.5" fill="#77d5ff"/><circle cx="90" cy="%s" r="1.5" fill="#ffc958"/>'%[h-4,h-4,str(h-2.5)]
	elif kind=="name":
		body+='<path d="M10 %sL14 %sL10 %sL6 %sZ" fill="#259bff" opacity=".75"/>'%[str(h*.5-4),str(h*.5),str(h*.5+4),str(h*.5)]
	if kind in ["panel","frame","reference"]:
		body+='<path d="M20 8H72" stroke="#54c6ff" stroke-width="3" stroke-linecap="round"/><path d="M%d 8H%dL%d 18" fill="none" stroke="#66c5f4" stroke-width="2" opacity=".7"/><path d="M%d 8L%d 12L%d 8L%d 4Z" fill="#ffc958"/>'%[w-60,w-29,w-19,w-74,w-70,w-66,w-70]
	if kind=="header":
		body+='<path d="M20 %sQ70 %s 142 7" fill="none" stroke="#ffffff" stroke-width="3" opacity=".75"/><path d="M22 %sQ90 %s 154 9" fill="none" stroke="#48b7ef" stroke-width="1" opacity=".5"/>'%[str(h-10),str(h-4),str(h-9),str(h-7)]
	if kind in ["frame","header","panel","reference"]:body+='<rect x="3" y="3" width="%d" height="%d" rx="%s" fill="none" stroke="#efffff" stroke-width="1"/>'%[w-6,h-9,str(radius-2)]
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
		elif state=="disabled":
			style.texture=surface("button",maxi(24,roundi(button.size.x)),maxi(24,roundi(button.size.y)))
			style.modulate_color=Color("edf2f7")
		button.add_theme_stylebox_override(state,style)
	button.set_meta("gloss_button_busy",false)
