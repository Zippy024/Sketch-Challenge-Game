extends Control
# Reference-built, real 3D geometry. Distances are metres from the supplied elevation.
signal part_selected(index: int)
signal part_hovered(index: int)
signal view_changed
signal interaction_started
const UI=preload("res://KitchenUI.gd")
const Parts=preload("res://Stage3Assets/Model/JapaneseParts.gd")
var viewport: SubViewport
var camera: Camera3D
var scene: Node3D
var selected: int=-1
var hovered: int=-1
var yaw: float=0.62
var pitch: float=0.45
var zoom: float=3.15
var _pressed: bool=false
var _travel: float=0.0
var _pending_pick: Vector2=Vector2(-1,-1)
var _pending_hover: Vector2=Vector2(-1,-1)
var _groups: Array[Node3D]=[]
var _materials: Array=[]
var _pointers: Array[Button]=[]
var _pointer_offsets: Array[Vector2]=[Vector2(-38,-26),Vector2(40,-18),Vector2(-38,-20),Vector2(44,14),Vector2(40,-14),Vector2(46,-35),Vector2(-42,-18),Vector2(40,28)]
var _solved: Array[bool]=[false,false,false,false,false,false,false,false]
var _anchors: Array[Vector3]=[Vector3(0.15,0.87,0.36),Vector3(0.28,1.08,-0.325),Vector3(-0.84,1.98,0.18),Vector3(0.45,0.5,-0.49),Vector3(0.74,0.84,0.03),Vector3(0.75,1.12,-0.15),Vector3(-0.91,0.86,0),Vector3(0.71,0.65,0.34)]

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_STOP
 clip_contents=true
 viewport=SubViewport.new()
 viewport.name="Kitchen3DViewport"
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 viewport.msaa_3d=Viewport.MSAA_2X
 add_child(viewport)
 var image:=TextureRect.new()
 image.texture=viewport.get_texture()
 image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 image.mouse_filter=Control.MOUSE_FILTER_IGNORE
 image.show_behind_parent=true
 add_child(image)
 image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scene=Node3D.new()
 scene.name="ReferenceKitchenScene"
 viewport.add_child(scene)
 var environment:=WorldEnvironment.new()
 var settings:=Environment.new()
 settings.background_mode=Environment.BG_COLOR
 settings.background_color=Color("eeede7")
 settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 settings.ambient_light_color=Color("ffffff")
 settings.ambient_light_energy=0.58
 environment.environment=settings
 scene.add_child(environment)
 var light:=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-32,0)
 light.light_energy=0.38
 light.shadow_enabled=false
 light.directional_shadow_max_distance=15
 scene.add_child(light)
 var fill:=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-30,145,0)
 fill.light_energy=0.16
 scene.add_child(fill)
 camera=Camera3D.new()
 camera.name="KitchenOrbitCamera"
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.near=0.05
 camera.far=40
 viewport.add_child(camera)
 camera.current=true
 for i in range(Parts.COUNT):
  var group:=Node3D.new()
  group.name="KitchenPart%d"%(i+1)
  group.set_meta("part",i)
  scene.add_child(group)
  _groups.append(group)
  _materials.append([])
 _build_kitchen()
 _build_pointers()
 resized.connect(_resize_view)
 mouse_exited.connect(set_hovered.bind(-1))
 _resize_view()
 _update_camera()
 _update_materials()

func _build_pointers() -> void:
 for i in range(Parts.COUNT):
  var pointer:=Button.new()
  pointer.name="PartPointer%d"%(i+1)
  pointer.custom_minimum_size=Vector2(32,32)
  pointer.size=Vector2(32,32)
  pointer.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  pointer.tooltip_text=UI.text("Part %d")%(i+1)
  pointer.pressed.connect(_choose.bind(i))
  pointer.mouse_entered.connect(set_hovered.bind(i))
  pointer.mouse_exited.connect(set_hovered.bind(-1))
  pointer.focus_entered.connect(set_hovered.bind(i))
  add_child(pointer)
  var number:=UI.label(str(i+1),13,true)
  number.name="PointerNumber"
  number.autowrap_mode=TextServer.AUTOWRAP_OFF
  number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  pointer.add_child(number)
  number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  _pointers.append(pointer)

func _position_pointers() -> void:
 if not is_instance_valid(camera) or not camera.is_inside_tree():return
 var centers: Array[Vector2]=[]
 for i in range(_pointers.size()):
  var center: Vector2=(part_center(i)+_pointer_offsets[i]).clamp(Vector2(20,20),size-Vector2(20,20))
  for other in centers:
   if center.distance_to(other)<40:
    center.y+=42 if center.y>=other.y else -42
  center=center.clamp(Vector2(20,20),size-Vector2(20,20))
  centers.append(center)
  _pointers[i].position=center-Vector2(16,16)
 queue_redraw()

func _draw() -> void:
 if not is_instance_valid(camera) or not camera.is_inside_tree():return
 for i in range(_pointers.size()):
  draw_line(part_center(i),_pointers[i].position+Vector2(16,16),Color("549d94"),1.3,true)
  draw_circle(part_center(i),2.3,Color("549d94"))

func _material(color: Color, metallic: float=0.0, roughness: float=0.65) -> StandardMaterial3D:
 var material:=StandardMaterial3D.new()
 material.albedo_color=color
 material.metallic=metallic
 material.roughness=roughness
 return material

func _box(parent: Node3D, dimensions: Vector3, center: Vector3, color: Color, part: int=-1, metallic: float=0.0, collidable: bool=true) -> MeshInstance3D:
 var instance:=MeshInstance3D.new()
 var mesh:=BoxMesh.new()
 mesh.size=dimensions
 instance.mesh=mesh
 instance.position=center
 var material:=_material(color,metallic)
 instance.material_override=material
 if part==0:material.roughness=0.32
 if part in [2,4]:material.roughness=0.38
 parent.add_child(instance)
 if part>=0:
  _materials[part].append({"material":material,"color":color})
 if collidable:
  var body:=StaticBody3D.new()
  body.set_meta("part",part)
  var collision:=CollisionShape3D.new()
  var shape:=BoxShape3D.new()
  shape.size=dimensions
  collision.shape=shape
  body.add_child(collision)
  instance.add_child(body)
 return instance

func _cylinder(parent: Node3D, center: Vector3, radius: float, height: float, color: Color, rotate_z: float=0.0) -> void:
 var instance:=MeshInstance3D.new()
 var mesh:=CylinderMesh.new()
 mesh.top_radius=radius
 mesh.bottom_radius=radius
 mesh.height=height
 mesh.radial_segments=24
 instance.mesh=mesh
 instance.material_override=_material(color,0.55,0.3)
 instance.position=center
 instance.rotation.x=rotate_z
 parent.add_child(instance)

func _detail(parent: Node3D, dim: Vector3, pos: Vector3, color: Color, metallic: float=0.0) -> void:
 # Unpickable detail geometry must not block the eight selectable components.
 _box(parent,dim,pos,color,-1,metallic,false)

func _stone(parent: Node3D, dim: Vector3, pos: Vector3) -> void:
 var tile:=_box(_groups[1],dim,pos,Color("c3bfb8"),1)
 tile.name="GrayStoneBacksplash"
 var material:=ShaderMaterial.new()
 material.shader=preload("res://Stage3Assets/Model/stone-backsplash.gdshader")
 tile.material_override=material
 _materials[1][-1]={"material":material}

func _handle(parent: Node3D, x: float, y: float, width: float=0.17) -> void:
 var ink:=Color("303536")
 _detail(parent,Vector3(width,0.013,0.016),Vector3(x,y,0.378),ink,0.35)
 _detail(parent,Vector3(0.013,0.025,0.034),Vector3(x-width*0.43,y,0.365),ink,0.35)
 _detail(parent,Vector3(0.013,0.025,0.034),Vector3(x+width*0.43,y,0.365),ink,0.35)

func _build_kitchen() -> void:
 # Panasonic-inspired straight kitchen reconstructed from the supplied photo.
 # 2.57m wide, approx. 650mm deep, 850mm counter height, 900mm hood bay.
 # All geometry is real 3D and the eight assessed mesh groups retain their saved indices.
 var white:=Color("f7f7f3")
 var cabinet:=Color("e1e3e0")
 var steel:=Color("a9b5b8")
 var dark:=Color("313839")

 # Natural light-oak parquet on an open, softly lit background.
 var floor:=_box(scene,Vector3(5.0,0.045,3.42),Vector3(0,-0.07,0.59),Color("d7b988"),-1,0.0,false)
 floor.name="RoomOakFloor"
 var wood:=ShaderMaterial.new()
 wood.shader=preload("res://Stage3Assets/Model/wood-floor.gdshader")
 floor.material_override=wood
 # Cabinet plinth and carcass; three distinct front zones with satin-white
 # drawers and small black horizontal handles like the reference.
 _detail(scene,Vector3(2.58,0.09,0.58),Vector3(0,0.065,0),Color("3d4543"))
 _detail(scene,Vector3(2.55,0.71,0.59),Vector3(0,0.459,0),cabinet)
 _detail(scene,Vector3(2.56,0.725,0.020),Vector3(0,0.46,-0.300),Color("d5d8d5"))
 for x in [-1.283,1.283]:
  _detail(scene,Vector3(0.023,0.71,0.64),Vector3(x,0.47,0),white)
 var bays: Array[Dictionary]=[
  {"left":-1.276,"width":0.71},
  {"left":-0.566,"width":0.55},
  {"left":-0.016,"width":0.33},
  {"left":0.314,"width":0.959}
 ]
 for b in bays:
  var left: float=float(b["left"])
  var width: float=float(b["width"])
  var center_x: float=left+width*0.5
  var right_drawer: bool=center_x>0.40
  if right_drawer:
   # Part 8 is the large sink-side pullout drawer.
   _box(_groups[7],Vector3(width-0.01,0.31,0.027),Vector3(center_x,0.65,0.319),white,7)
   _box(_groups[7],Vector3(width-0.01,0.33,0.028),Vector3(center_x,0.323,0.317),white,7)
   _handle(scene,center_x,0.734,0.25)
   _handle(scene,center_x,0.456,0.27)
  elif center_x < -0.60:
   _detail(scene,Vector3(width-0.014,0.17,0.03),Vector3(center_x,0.71,0.318),Color("c1c8c8"))
   _detail(scene,Vector3(width-0.014,0.38,0.03),Vector3(center_x,0.35,0.318),white)
   _handle(scene,center_x,0.519,0.19)
  else:
   _box(_groups[7],Vector3(width-0.012,0.27,0.028),Vector3(center_x,0.685,0.317),white,7)
   _box(_groups[7],Vector3(width-0.012,0.31,0.028),Vector3(center_x,0.383,0.317),white,7)
   _handle(scene,center_x,0.745,0.16)
   _handle(scene,center_x,0.47,0.17)
  _detail(scene,Vector3(0.006,0.62,0.011),Vector3(left+width,0.47,0.334),Color("c8cbc7"))

 # Countertop has an actual sink opening, not a sink painted onto a solid slab.
 # The four surrounding worktop pieces are part 1.
 var counter:=_groups[0]
 _box(counter,Vector3(1.73,0.043,0.67),Vector3(-0.42,0.843,0),white,0)
 _box(counter,Vector3(0.235,0.043,0.67),Vector3(1.1675,0.843,0),white,0)
 _box(counter,Vector3(0.605,0.043,0.157),Vector3(0.75,0.843,-0.258),white,0)
 _box(counter,Vector3(0.605,0.043,0.126),Vector3(0.75,0.843,0.270),white,0)
 _detail(scene,Vector3(2.57,0.018,0.022),Vector3(0,0.822,0.323),Color("e4e6e4"))

 # Gray stone backsplash and the tall hood backing, matching the photo.
 _detail(scene,Vector3(0.905,2.41,0.10),Vector3(-0.825,1.205,-0.395),Color("d8d7d2"))
 _stone(scene,Vector3(0.90,1.40,0.016),Vector3(-0.825,1.50,-0.338))
 _stone(scene,Vector3(1.67,0.48,0.017),Vector3(0.43,1.08,-0.340))
 var kitchen_board:=_groups[1]
 _box(kitchen_board,Vector3(0.95,0.47,0.016),Vector3(0.28,1.08,-0.325),Color("d0cbc4"),1)
 var hood:=_groups[2]
 _box(hood,Vector3(0.77,0.62,0.45),Vector3(-0.825,2.072,-0.110),Color("d1d3d0"),2,0.12)
 _detail(hood,Vector3(0.79,0.028,0.515),Vector3(-0.825,1.758,0.005),Color("7a8080"),0.3)
 _detail(hood,Vector3(0.72,0.012,0.39),Vector3(-0.825,1.732,0.004),Color("3b4242"),0.3)
 _detail(hood,Vector3(0.70,0.06,0.075),Vector3(-0.825,2.33,0.055),Color("d7d8d5"))
 _detail(scene,Vector3(0.86,0.020,0.52),Vector3(-0.825,1.715,0.005),Color("60686a"))

 # Oven controls under a black three-ring IH panel (part 7).
 var hob:=_groups[6]
 _box(hob,Vector3(0.66,0.012,0.49),Vector3(-0.92,0.874,-0.018),Color("171c1e"),6,0.08)
 for center in [Vector3(-1.09,0.883,0.095),Vector3(-0.81,0.883,0.075),Vector3(-0.92,0.883,-0.132)]:
  var mesh:=MeshInstance3D.new()
  var ring:=TorusMesh.new()
  ring.inner_radius=0.068
  ring.outer_radius=0.073
  ring.rings=24
  ring.ring_segments=10
  mesh.mesh=ring
  mesh.position=center
  mesh.material_override=_material(Color("717776"),0.1,0.5)
  hob.add_child(mesh)
 _detail(scene,Vector3(0.56,0.10,0.037),Vector3(-0.92,0.705,0.363),Color("60696b"),0.4)
 _detail(scene,Vector3(0.34,0.038,0.037),Vector3(-1.02,0.71,0.386),Color("232a2b"))
 for x in [-0.82,-0.745,-0.67]:
  _detail(scene,Vector3(0.027,0.024,0.018),Vector3(x,0.71,0.392),Color("252b2d"))

 # Half wall at rear of counter, preserved as clickable part 4.
 var half_wall:=_groups[3]
 _box(half_wall,Vector3(1.65,0.90,0.078),Vector3(0.45,0.45,-0.449),Color("e7e6e1"),3)
 _detail(half_wall,Vector3(1.65,0.025,0.103),Vector3(0.45,0.899,-0.449),white)

 # Stainless recessed basin, strainer and curved single-lever faucet (5, 6).
 var sink:=_groups[4]
 _rounded_sink(sink,steel)
 _cylinder(sink,Vector3(0.75,0.719,0.028),0.03,0.008,Color("656c6d"))
 var faucet:=_groups[5]
 _box(faucet,Vector3(0.064,0.105,0.065),Vector3(0.75,0.934,-0.252),steel,5,0.65)
 var previous:=Vector3(0.75,0.924,-0.252)
 for i in range(1,19):
  var t: float=float(i)/18
  var k: float=1.0-t
  var pt:=Vector3(0.75,0.924,-0.252)*k*k*k+Vector3(0.75,1.32,-0.252)*3*k*k*t+Vector3(0.75,1.36,-0.04)*3*k*t*t+Vector3(0.75,1.09,-0.04)*t*t*t
  _pipe(faucet,previous,pt,0.012,steel,5)
  previous=pt
 _detail(faucet,Vector3(0.055,0.013,0.019),Vector3(0.796,0.953,-0.252),steel,0.5)

func _resize_view() -> void:
 var scale_factor:=1.75
 viewport.size=Vector2i(clampi(roundi(size.x*scale_factor),1,2048),clampi(roundi(size.y*scale_factor),1,1280))
 _update_camera()

func _update_camera() -> void:
 if not is_instance_valid(camera):return
 # The static model needs a new frame only after interaction or resizing.
 viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 camera.size=zoom
 var target:=Vector3(0,1.08,0)
 camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*6.0
 camera.look_at(target,Vector3.UP)
 _position_pointers()

 view_changed.emit()

func set_view(which: String) -> void:
 interaction_started.emit()
 yaw={"front":0.0,"rear":PI,"perspective":0.62}.get(which,0.62)
 pitch=0.15 if which=="front" else (0.30 if which=="rear" else 0.45)
 zoom=3.15
 _update_camera()

func zoom_by(amount: float) -> void:
 zoom=clampf(zoom+amount,2.55,4.8)
 _update_camera()

func set_selected(index: int) -> void:
 selected=index
 _update_materials()

func set_hovered(index: int) -> void:
 if hovered==index:return
 hovered=index
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if index>=0 else Control.CURSOR_DRAG
 part_hovered.emit(index)
 _update_materials()

func set_solved(values: Array[bool]) -> void:
 _solved=values.duplicate()
 _update_materials()

func _update_materials() -> void:
 if is_instance_valid(viewport):viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
 for i in range(_materials.size()):
  var active: bool=i==selected or i==hovered
  for entry in _materials[i]:
   if entry.material is ShaderMaterial:
    entry.material.set_shader_parameter("highlighted",1.0 if active else 0.0)
    continue
   entry.material.albedo_color=entry.color.lerp(Color("55cabb"),0.32) if active else entry.color
   entry.material.emission_enabled=active
   entry.material.emission=Color("257769")
   entry.material.emission_energy_multiplier=0.24 if active else 0.0
  if i<_pointers.size():
   var style:=UI.box(UI.TEAL if active else (Color("e7f5ea") if _solved[i] else Color("fafff8")),Color("86b7ae"),16,0)
   style.shadow_size=2
   for state in ["normal","hover","pressed","focus"]:_pointers[i].add_theme_stylebox_override(state,style)
   _pointers[i].get_node("PointerNumber").add_theme_color_override("font_color",Color.WHITE if active else UI.INK)

func part_center(index: int) -> Vector2:
 if not is_instance_valid(camera) or not camera.is_inside_tree() or index<0 or index>=_anchors.size():return size*0.5
 return (camera.unproject_position(_anchors[index])*size/Vector2(viewport.size)).clamp(Vector2(18,18),size-Vector2(18,18))

func rotate_by(amount: float) -> void:
 interaction_started.emit()
 set_hovered(-1)
 yaw=wrapf(yaw+amount,-PI,PI)
 _update_camera()

func _choose(index: int) -> void:
 set_selected(index)
 part_selected.emit(index)

func _ray_part(position: Vector2) -> int:
 if size.x<=0 or size.y<=0:return -1
 var point:=position*Vector2(viewport.size)/size
 var origin:=camera.project_ray_origin(point)
 var end:=origin+camera.project_ray_normal(point)*30.0
 var query:=PhysicsRayQueryParameters3D.create(origin,end)
 var world:=viewport.find_world_3d()
 if world==null:return -1
 var hit:=world.direct_space_state.intersect_ray(query)
 return int(hit.collider.get_meta("part",-1)) if not hit.is_empty() else -1

func _physics_process(_delta: float) -> void:
 if _pending_hover.x>=0:
  var index:=_ray_part(_pending_hover)
  _pending_hover=Vector2(-1,-1)
  set_hovered(index)
 if _pending_pick.x>=0:
  var index:=_ray_part(_pending_pick)
  _pending_pick=Vector2(-1,-1)
  if index>=0:_choose(index)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed:
   interaction_started.emit()
   _pressed=true
   _travel=0
  else:
   if _pressed and _travel<6:_pending_pick=event.position
   _pressed=false
  accept_event()
 elif event is InputEventScreenDrag and _pressed:
  _travel+=event.relative.length()
  yaw=wrapf(yaw-event.relative.x*0.009,-PI,PI)
  pitch=clampf(pitch+event.relative.y*0.007,0.08,1.20)
  _update_camera()
  accept_event()
 elif event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:zoom_by(-0.15)
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:zoom_by(0.15)
  elif event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
   if event.pressed:
    interaction_started.emit()
    _pressed=true
    _travel=0
   else:
    if _pressed and _travel<6 and event.button_index==MOUSE_BUTTON_LEFT:_pending_pick=event.position
    _pressed=false
  accept_event()
 elif event is InputEventMouseMotion and _pressed:
  _travel+=event.relative.length()
  yaw=wrapf(yaw-event.relative.x*0.009,-PI,PI)
  pitch=clampf(pitch+event.relative.y*0.007,0.08,1.20)
  _update_camera()
  accept_event()
 elif event is InputEventMouseMotion:
  _pending_hover=event.position

func _unhandled_input(event: InputEvent) -> void:
 # A release outside the model must not leave orbiting latched on.
 if event is InputEventMouseButton and not event.pressed and _pressed:
  _pressed=false

func view_state() -> Dictionary:
 return {"yaw":yaw,"pitch":pitch,"zoom":zoom}

func apply_view_state(state: Dictionary) -> void:
 yaw=float(state.get("yaw",yaw))
 pitch=clampf(float(state.get("pitch",pitch)),0.08,1.2)
 zoom=clampf(float(state.get("zoom",zoom)),2.55,4.8)
 _update_camera()

func _pipe(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, part: int=-1) -> void:
 var instance:=MeshInstance3D.new()
 var mesh:=CylinderMesh.new()
 mesh.top_radius=radius
 mesh.bottom_radius=radius
 mesh.height=a.distance_to(b)
 mesh.radial_segments=16
 instance.mesh=mesh
 instance.material_override=_material(color,0.7,0.25)
 instance.position=(a+b)*0.5
 instance.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
 parent.add_child(instance)
 if part>=0:
  _materials[part].append({"material":instance.material_override,"color":color})
  var body:=StaticBody3D.new()
  body.set_meta("part",part)
  var collision:=CollisionShape3D.new()
  var shape:=CylinderShape3D.new()
  shape.radius=radius*1.5
  shape.height=mesh.height
  collision.shape=shape
  body.add_child(collision)
  instance.add_child(body)

func _rounded_ring(width: float, depth: float, radius: float, y: float) -> PackedVector3Array:
 var points:=PackedVector3Array()
 var centers: Array[Vector2]=[Vector2(width/2-radius,depth/2-radius),Vector2(-width/2+radius,depth/2-radius),Vector2(-width/2+radius,-depth/2+radius),Vector2(width/2-radius,-depth/2+radius)]
 for corner in range(4):
  for i in range(8):
   var angle: float=float(corner)*PI/2+float(i)*PI/14
   var p: Vector2=centers[corner]+Vector2(cos(angle),sin(angle))*radius
   points.append(Vector3(0.75+p.x,y,0.02+p.y))
 return points

func _rounded_sink(parent: Node3D, color: Color) -> void:
 var outer:=_rounded_ring(0.64,0.46,0.04,0.858)
 var inner:=_rounded_ring(0.56,0.38,0.05,0.848)
 var bottom:=_rounded_ring(0.48,0.30,0.055,0.714)
 var vertices:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var indices:=PackedInt32Array()
 for ring in [outer,inner,bottom]:
  for point in ring:
   vertices.append(point)
   normals.append(Vector3.UP if ring==outer or ring==bottom else Vector3((0.75-point.x)*3,0.6,(0.02-point.z)*3).normalized())
 var count: int=outer.size()
 for row in range(2):
  for i in range(count):
   var n: int=(i+1)%count
   indices.append_array([row*count+i,(row+1)*count+i,row*count+n,row*count+n,(row+1)*count+i,(row+1)*count+n])
 vertices.append(Vector3(0.75,0.714,0.02))
 normals.append(Vector3.UP)
 for i in range(count):indices.append_array([vertices.size()-1,2*count+(i+1)%count,2*count+i])
 var arrays:=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_NORMAL]=normals
 arrays[Mesh.ARRAY_INDEX]=indices
 var mesh:=ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var instance:=MeshInstance3D.new()
 instance.mesh=mesh
 # Upward-facing winding keeps the bowl lit in the compatibility renderer.
 for triangle in range(0,indices.size(),3):
  var swap: int=indices[triangle+1]
  indices[triangle+1]=indices[triangle+2]
  indices[triangle+2]=swap
 arrays[Mesh.ARRAY_INDEX]=indices
 mesh.clear_surfaces()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var material:=_material(color,0.28,0.35)
 material.cull_mode=BaseMaterial3D.CULL_DISABLED
 instance.material_override=material
 parent.add_child(instance)
 _materials[4].append({"material":material,"color":color})
 instance.create_trimesh_collision()
 for child in instance.get_children():
  if child is StaticBody3D:child.set_meta("part",4)
