extends SubViewport
# Small real-time 3D kitchen mission stations, replacing flat image-card lists.
# Decorative only; game entry, answers and stage scripts remain unchanged.
var mission: int = 1
var _group: Node3D

func _ready() -> void:
	size = Vector2i(320, 190)
	transparent_bg = true
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ONCE
	_build()

func _mat(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.56
	m.metallic = metal
	return m

func _block(parent: Node3D, p: Vector3, dimensions: Vector3, color: Color, metal: float = 0.0) -> void:
	var obj := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	obj.mesh = mesh
	obj.material_override = _mat(color, metal)
	obj.position = p
	parent.add_child(obj)

func _plant(parent: Node3D, x: float, z: float, h: float = 0.55) -> void:
	_block(parent, Vector3(x, 0.58, z), Vector3(0.22, 0.27, 0.22), Color("e5d1b7"))
	_block(parent, Vector3(x, 0.74, z), Vector3(0.055, h, 0.055), Color("61987f"))
	for i in range(4):
		var leaf := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.18
		m.height = 0.29
		leaf.mesh = m
		leaf.material_override = _mat(Color("5aa87b") if i % 2 == 0 else Color("2d8d73"))
		leaf.position = Vector3(x + (float(i)-1.5)*0.12, 0.98+float(i%2)*0.17, z+float(i%3-1)*0.12)
		parent.add_child(leaf)

func _pendant(parent: Node3D, x: float, z: float) -> void:
	_block(parent, Vector3(x, 2.13, z), Vector3(0.018,0.42,0.018), Color("aabdc7"), 0.6)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.07
	mesh.bottom_radius = 0.23
	mesh.height = 0.20
	cone.mesh = mesh
	cone.position = Vector3(x,1.86,z)
	cone.material_override = _mat(Color("d8a775"),0.52)
	parent.add_child(cone)

func _build() -> void:
	var w := Node3D.new()
	add_child(w)
	_group = w
	var locked := mission > 3
	var cabinet := Color("f3f6f3") if mission == 1 else (Color("e2e9ec") if mission == 2 else Color("b0d7dc"))
	if mission == 4: cabinet = Color("afbfc5")
	if mission == 5: cabinet = Color("d4d5d5")
	if mission == 6: cabinet = Color("d0d6de")
	var floor_color := Color("d6d4cd") if not locked else Color("b6bdc7")
	var wall_color := Color("f8f7f3") if not locked else Color("c4ccd6")
	# Open-top room cutaway and marble display base.
	_block(w, Vector3(0.0,-0.65,0.0),Vector3(4.9,0.16,3.75),Color("d2e8ef"))
	_block(w, Vector3(0.0,-0.49,0.0),Vector3(4.72,0.13,3.52),floor_color)
	_block(w, Vector3(0.0,0.77,-1.65),Vector3(4.73,2.56,0.12),wall_color)
	_block(w, Vector3(-2.30,0.77,0.0),Vector3(0.12,2.56,3.48),wall_color)
	# Light architectural wall tiles, diagonal trim/crown.
	_block(w, Vector3(0.0,0.57,-1.56),Vector3(4.4,0.63,0.045),Color("edf6f7"))
	for x in [-1.4,-0.7,0.0,0.7,1.4]:
		_block(w,Vector3(x,1.80,-1.59),Vector3(0.020,0.74,0.035),Color("c4d5db"))
	# Back kitchen cabinetry.
	for i in range(5):
		var x := -1.50 + float(i)*0.74
		_block(w,Vector3(x,0.04,-1.02),Vector3(0.69,0.87,0.73),cabinet)
		_block(w,Vector3(x,0.33,-0.64),Vector3(0.46,0.018,0.026),Color("adc0c7"),0.6)
	_block(w,Vector3(-0.05,0.51,-1.01),Vector3(4.08,0.12,0.90),Color("fffdf5"))
	# L-return island/counter on the left side.
	for i in range(3):
		var z := -0.73 + float(i)*0.72
		_block(w,Vector3(-1.70,0.06,z),Vector3(0.77,0.87,0.69),cabinet)
		_block(w,Vector3(-1.28,0.35,z),Vector3(0.026,0.025,0.37),Color("879fa9"),0.6)
	_block(w,Vector3(-1.70,0.52,-0.06),Vector3(1.0,0.10,2.18),Color("fafafa"))
	# Sink and silver faucet.
	_block(w,Vector3(-1.70,0.59,-0.68),Vector3(0.48,0.024,0.55),Color("7c9faf"),0.72)
	_block(w,Vector3(-1.70,0.60,-0.68),Vector3(0.36,0.026,0.44),Color("3d596b"),0.67)
	_block(w,Vector3(-1.86,0.78,-0.94),Vector3(0.035,0.38,0.034),Color("b2cbd6"),0.86)
	_block(w,Vector3(-1.70,0.97,-0.94),Vector3(0.28,0.034,0.034),Color("b2cbd6"),0.86)
	# Black induction hob to the right.
	_block(w,Vector3(1.12,0.60,-1.03),Vector3(0.82,0.035,0.63),Color("293946"),0.55)
	for x in [0.91,1.31]:
		for z in [-1.21,-0.87]:
			var burn := MeshInstance3D.new()
			var m := CylinderMesh.new()
			m.top_radius = 0.11
			m.bottom_radius = 0.11
			m.height = 0.007
			burn.mesh = m
			burn.material_override = _mat(Color("6c8491"))
			burn.position = Vector3(x,0.63,z)
			w.add_child(burn)
	# Upper cabinets and an accent shelf.
	_block(w,Vector3(-0.63,1.58,-1.49),Vector3(0.95,0.64,0.35),cabinet)
	_block(w,Vector3(0.47,1.58,-1.49),Vector3(0.95,0.64,0.35),cabinet)
	_block(w,Vector3(1.60,1.65,-1.49),Vector3(0.65,0.83,0.34),Color("cbd5d8"))
	_block(w,Vector3(1.62,1.63,-1.29),Vector3(0.48,0.42,0.025),Color("1d2936"))
	_plant(w,-2.02,-1.04,0.40)
	_plant(w,1.73,-0.73,0.47)
	_pendant(w,-0.28,0.56)
	if mission == 3:
		# S-Class material selection: horizontal swatches above the counter.
		_block(w,Vector3(0.12,0.71,0.94),Vector3(0.82,0.05,0.59),Color("d7ab76"))
		_block(w,Vector3(0.99,0.71,0.94),Vector3(0.72,0.05,0.59),Color("e7e5df"))
		_block(w,Vector3(1.79,0.71,0.94),Vector3(0.72,0.05,0.59),Color("6d7f89"))
	if mission == 4 or mission == 6:
		# Island and breakfast stools.
		_block(w,Vector3(0.34,0.19,0.69),Vector3(1.56,0.85,0.72),cabinet)
		_block(w,Vector3(0.34,0.66,0.69),Vector3(1.86,0.12,1.03),Color("f9f7f4"))
		for x in [-0.10,0.71]:
			_block(w,Vector3(x,-0.09,1.39),Vector3(0.28,0.08,0.27),Color("bfa48f"))
	if mission == 5:
		_pendant(w,0.70,0.63)
		_pendant(w,1.12,0.78)
	# Soft neutral showroom lighting; no model file download required.
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-38,-34,0)
	w.add_child(light)
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("144d76")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("f8fbff")
	env.ambient_light_energy = 0.72
	ambient.environment = env
	w.add_child(ambient)
	var cam := Camera3D.new()
	w.add_child(cam)
	cam.position = Vector3(5.8,5.3,7.7)
	cam.look_at(Vector3(0,0.25,0),Vector3.UP)
	cam.fov = 39.0
	cam.current = true
