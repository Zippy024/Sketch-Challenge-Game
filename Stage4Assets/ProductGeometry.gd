extends RefCounted
const G=preload("res://Stage4Assets/FixtureGeometry.gd")
const STEEL=Color("c2c9cb")
const PARTS=[4,5,2,6]
const ORIGINS=[Vector3(.75,.866,.02),Vector3(.75,.872,-.252),Vector3(-.825,1.75,0),Vector3(-.92,.875,-.018)]

static func create(category: int,index: int) -> Node3D:
	var root=Node3D.new();root.name="Product_%d_%d"%[category,index]
	if category==0:_sink(root,index)
	elif category==1:_faucet(root,index)
	elif category==2:_hood(root,index)
	else:_cooktop(root,index)
	return root

static func _sink(root: Node3D,index: int) -> void:
	var inner=Vector2(.56,.38) if index!=1 else Vector2(.47,.35)
	G.bowl(root,Vector3.ZERO,Vector2(.65,.46),inner)
	if index>=3:
		var color=Color("fcfcf8") if index==3 else Color("e9e5d8")
		for node in root.get_children():
			if node is MeshInstance3D:
				var material=G.material(color,.02);material.vertex_color_use_as_albedo=true;material.cull_mode=BaseMaterial3D.CULL_DISABLED
				node.material_override=material
	if index==2:
		# The G basin has sculpted rear shoulders and a raised drain recess.
		for sign_x in [-1,1]:
			G.box(root,Vector3(sign_x*.20,-.006,-.15),Vector3(.14,.018,.085),STEEL)
		G.cylinder(root,Vector3(0,-.126,-.12),.044,.009,STEEL)
		G.box(root,Vector3(0,-.117,-.12),Vector3(.012,.007,.055),Color("5b6468"))
	elif index<2:
		G.cylinder(root,Vector3(0,-.126,-.10),.04,.007,STEEL)
		G.box(root,Vector3(0,-.12,-.11),Vector3(.038,.006,.012),Color("434c50"))
	if index>=3:
		# Rear accessory rack belongs to the basin, independent of the faucet.
		for z in [-.17,-.13,-.09]:G.pipe(root,Vector3(-.16,.012,z),Vector3(.16,.012,z),.003)
		for x in [-.16,-.08,0,.08,.16]:G.pipe(root,Vector3(x,.012,-.17),Vector3(x,.012,-.09),.0026)
		G.box(root,Vector3(.04,-.025,-.15),Vector3(.13,.015,.055),Color("777e7d"))

static func _faucet(root: Node3D,index: int) -> void:
	G.cylinder(root,Vector3(0,.006,0),.038,.012)
	G.cylinder(root,Vector3(0,.08,0),.029,.15)
	if index==2:
		var previous=Vector3(0,.11,0)
		for j in range(1,49):
			var t=j/48.0;var k=1-t
			var point=Vector3(0,.11,0)*k*k*k+Vector3(0,.54,0)*3*k*k*t+Vector3(0,.55,.22)*3*k*t*t+Vector3(0,.28,.22)*t*t*t
			G.pipe(root,previous,point,.012);previous=point
		G.cylinder(root,Vector3(0,.265,.22),.015,.038)
		G.box(root,Vector3(0,.05,.029),Vector3(.014,.025,.004),Color("1c2931"),.05)
		G.pipe(root,Vector3(.035,.11,0),Vector3(.075,.11,0),.015)
		G.pipe(root,Vector3(.075,.11,0),Vector3(.075,.23,0),.005)
	elif index==1:
		G.pipe(root,Vector3(0,.10,0),Vector3(0,.25,.22),.015)
		G.pipe(root,Vector3(0,.25,.22),Vector3(0,.25,.28),.015)
		G.cylinder(root,Vector3(0,.237,.28),.018,.035)
		G.box(root,Vector3(0,.17,.065),Vector3(.043,.012,.13))
	else:
		var end=.255 if index==0 else (.235 if index==3 else .205)
		var height=.10 if index!=3 else .115
		G.pipe(root,Vector3(0,.10,0),Vector3(0,height,end),.021)
		G.cylinder(root,Vector3(0,height-.017,end),.026,.04)
		G.cylinder(root,Vector3(0,height-.039,end),.022,.004,Color("273138"))
		G.cylinder(root,Vector3(0,.167,0),.031,.023)
		G.box(root,Vector3(0,.18,.065),Vector3(.038,.009,.15))
		if index==3:
			G.box(root,Vector3(0,.125,end),Vector3(.025,.006,.025),Color("626f77"))

static func _hood(root: Node3D,index: int) -> void:
	var silver=Color("bfc4c5");var black=Color("242c30")
	var color=black if index==1 else silver
	if index in [0,1,3]:
		var high=.60 if index!=3 else .40
		G.box(root,Vector3(0,.07+high*.5,-.20),Vector3(.77,high,.065),color)
		G.box(root,Vector3(0,.065,0),Vector3(.82,.055 if index!=3 else .085,.53),color)
		G.box(root,Vector3(0,.025,.015),Vector3(.74,.012,.44),Color("343c40"))
		G.box(root,Vector3(0,.016,.015),Vector3(.65,.01,.32),color)
		G.box(root,Vector3(0,.063,.268),Vector3(.16,.015,.004),Color("194a70") if index==0 else Color("434e55"))
	elif index==2:
		G.box(root,Vector3(0,.44,-.16),Vector3(.29,.83,.22),silver)
		G.box(root,Vector3(0,.72,-.047),Vector3(.29,.003,.003),Color("7b8588"))
		G.box(root,Vector3(0,.035,0),Vector3(.84,.045,.53),silver)
		G.box(root,Vector3(0,.01,.035),Vector3(.55,.008,.095),Color("242b30"))
	else:
		var vertices=PackedVector3Array([Vector3(-.40,0,.27),Vector3(.40,0,.27),Vector3(.40,.48,-.09),Vector3(-.40,.48,-.09),Vector3(-.40,0,-.25),Vector3(.40,0,-.25),Vector3(.40,.48,-.25),Vector3(-.40,.48,-.25)])
		var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in [0,1,2,0,2,3,1,5,6,1,6,2,5,4,7,5,7,6,4,0,3,4,3,7,3,2,6,3,6,7,4,5,1,4,1,0]:surface.add_vertex(vertices[i])
		surface.generate_normals();var mesh=MeshInstance3D.new();mesh.mesh=surface.commit();mesh.material_override=G.material(silver,.3);root.add_child(mesh)
		G.box(root,Vector3(0,.55,-.20),Vector3(.77,.14,.10),silver)
		for x in range(12):G.box(root,Vector3(-.31+x*.055,.57,-.147),Vector3(.032,.009,.003),Color("5d6568"))
		G.box(root,Vector3(0,-.008,.035),Vector3(.70,.018,.35),Color("182227"))
		G.box(root,Vector3(.26,.07,.225),Vector3(.10,.016,.004),Color("4f5e65"))

static func _cooktop(root: Node3D,index: int) -> void:
	var colors=[Color("b8bec0"),Color("302b2b"),Color("9ca9af"),Color("f5f5ee"),Color("303b4a")]
	var front=Color("302b2b") if index==1 else Color("c8cbcb")
	var width=.70 if index<3 else .61
	G.box(root,Vector3.ZERO,Vector3(width,.016,.49),colors[index],.35)
	G.box(root,Vector3(0,.018,-.21),Vector3(width-.025,.008,.05),Color("4c565c"))
	for j in range(16):G.box(root,Vector3(-width*.43+j*width*.057,.023,-.21),Vector3(.012,.005,.035),Color("222a2f"))
	for p in [Vector2(-width*.26,.10),Vector2(width*.26,.10),Vector2(0,-.13)]:
		G.cylinder(root,Vector3(p.x,.025,p.y),.056,.028,Color("50595c"))
		G.cylinder(root,Vector3(p.x,.043,p.y),.048,.009,Color("222b31"))
		for j in range(6):
			var angle=j*TAU/6;var a=Vector3(p.x+cos(angle)*.055,.052,p.y+sin(angle)*.055);var b=Vector3(p.x+cos(angle)*.096,.052,p.y+sin(angle)*.096)
			G.pipe(root,a,b,.005,Color("4b5559") if index==2 else Color("222b31"))
	# Match each catalog's front control family. This covers the old Stage3 fascia.
	G.box(root,Vector3(0,-.16,.385),Vector3(.67,.19,.025),front)
	G.box(root,Vector3(0,-.14,.404),Vector3(.30,.09,.015),Color("18232a"))
	G.box(root,Vector3(0,-.212,.414),Vector3(.30,.012,.025),front)
	for side in [-1,1]:
		if index>=3:
			for dx in [-.035,.035]:
				G.box(root,Vector3(side*.245+dx,-.13,.405),Vector3(.055,.025,.016),front)
				G.box(root,Vector3(side*.245+dx,-.095,.405),Vector3(.048,.006,.016),Color("414b52"))
		else:
			for dx in [-.035,.035]:
				var knob=Node3D.new();root.add_child(knob);knob.position=Vector3(side*.245+dx,-.145,.413);knob.rotation.x=PI/2
				G.cylinder(knob,Vector3.ZERO,.016,.014,front)
