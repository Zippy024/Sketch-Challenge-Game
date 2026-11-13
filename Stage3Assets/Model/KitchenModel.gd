extends Control
# Reference-built, real 3D geometry. Distances are metres from the supplied elevation.
signal part_selected(index: int)
signal part_hovered(index: int)
signal number_hovered(index: int)
signal view_changed
signal interaction_started
const UI=preload("res://KitchenUI.gd")
var viewport: SubViewport
var camera: Camera3D
var scene: Node3D
var selected: int=-1
var hovered: int=-1
var yaw: float=0.62
var pitch: float=0.34
var zoom: float=3.15
var _pressed: bool=false
var _travel: float=0.0
var _pending_pick: Vector2=Vector2(-1,-1)
var _pending_hover: Vector2=Vector2(-1,-1)
var _groups: Array[Node3D]=[]
var _materials: Array=[]
var _markers: Array[Button]=[]
var _solved: Array[bool]=[false,false,false,false,false]
var _anchors: Array[Vector3]=[Vector3(0.15,0.87,0.36),Vector3(-0.85,1.28,-0.345),Vector3(-0.84,1.98,0.18),Vector3(1.31,0.56,-0.44),Vector3(0.74,0.84,0.03),Vector3(0.75,1.20,-0.18),Vector3(-0.92,0.87,0.07),Vector3(0.70,0.71,0.34)]
var _label_offsets: Array[Vector2]=[Vector2(-30,-22),Vector2(32,0),Vector2(-30,-18),Vector2(24,16),Vector2(28,-19),Vector2(42,-37),Vector2(-42,20),Vector2(37,26)]

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
 settings.background_color=Color("edf5f2")
 settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 settings.ambient_light_color=Color("ffffff")
 settings.ambient_light_energy=0.42
 environment.environment=settings
 scene.add_child(environment)
 var light:=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-48,-32,0)
 light.light_energy=0.85
 light.shadow_enabled=true
 light.directional_shadow_max_distance=15
 scene.add_child(light)
 var fill:=DirectionalLight3D.new()
 fill.rotation_degrees=Vector3(-30,145,0)
 fill.light_energy=0.18
 scene.add_child(fill)
 camera=Camera3D.new()
 camera.name="KitchenOrbitCamera"
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.near=0.05
 camera.far=40
 viewport.add_child(camera)
 camera.current=true
 for i in range(8):
  var group:=Node3D.new()
  group.name="NumberedPart%d"%(i+1)
  group.set_meta("part",i)
  scene.add_child(group)
  _groups.append(group)
  _materials.append([])
 _build_kitchen()
 for i in range(8):
  var marker:=Button.new()
  marker.text=""
  marker.tooltip_text=UI.text("Number %d")%(i+1)
  marker.add_theme_font_override("font",UI.font(true,"en"))
  marker.add_theme_font_size_override("font_size",13)
  marker.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  marker.name="PartMarker%d"%(i+1)
  marker.custom_minimum_size=Vector2(30,30)
  marker.size=Vector2(30,30)
  marker.set_meta("part",i)
  marker.pressed.connect(_choose.bind(i))
  marker.mouse_entered.connect(_number_hover.bind(i))
  marker.focus_entered.connect(_number_hover.bind(i))
  marker.mouse_exited.connect(set_hovered.bind(-1))
  add_child(marker)
  var number:=UI.label(str(i+1),13,true)
  number.name="MarkerNumber"
  number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  marker.add_child(number)
  number.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  _markers.append(marker)
 resized.connect(_resize_view)
 mouse_exited.connect(set_hovered.bind(-1))
 _resize_view()
 _update_camera()
 _update_materials()

func _material(color: Color, metallic: float=0.0, roughness: float=0.65) -> StandardMaterial3D:
 var material:=StandardMaterial3D.new()
 material.albedo_color=color
 material.metallic=metallic
 material.roughness=roughness
 return material

func _box(parent: Node3D, dimensions: Vector3, center: Vector3, color: Color, part: int=-1, metallic: float=0.0) -> MeshInstance3D:
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

func _build_kitchen() -> void:
 var white:=Color("f3f3ee")
 var ivory:=Color("faf8e9")
 var silver:=Color("aeb6b8")
 var floor_mesh:=_box(scene,Vector3(4.15,0.035,2.7),Vector3(0,-0.03,0.1),Color("c3a06b"))
 var wood:=ShaderMaterial.new()
 wood.shader=preload("res://Stage3Assets/Model/wood-floor.gdshader")
 floor_mesh.material_override=wood
 # 2573 mm worktop, 850 mm finished height, 750/750/1050 mm front bays.
 _box(scene,Vector3(2.55,0.09,0.58),Vector3(0,0.045,0),Color("858986"))
 _box(scene,Vector3(2.55,0.025,0.61),Vector3(0,0.105,0),white)
 for x in [-1.281,1.281]:_box(scene,Vector3(0.0115,0.71,0.62),Vector3(x,0.455,0),white)
 _box(scene,Vector3(2.55,0.7,0.018),Vector3(0,0.46,-0.305),Color("d9ddda"))
 var left: float=-1.275
 for width in [0.75,0.75,1.05]:
  for row in range(3):
   var height: float=[0.20,0.23,0.25][row]
   var y: float=[0.705,0.485,0.24][row]
   # The upper drawer in the right bay is selectable as part 8.
   var drawer_part: bool=row==0 and left>0
   var door:=_box(_groups[7] if drawer_part else scene,Vector3(width-0.007,height,0.025),Vector3(left+width*0.5,y,0.316),white,7 if drawer_part else -1)
   var cabinet_wood:=ShaderMaterial.new()
   cabinet_wood.shader=preload("res://Stage3Assets/Model/cabinet-wood.gdshader")
   door.material_override=cabinet_wood
   _box(scene,Vector3(width-0.06,0.012,0.018),Vector3(left+width*0.5,y+height*0.5-0.025,0.335),Color("8c9493"),-1,0.4)
  left+=width
 # Cut a genuine opening in the worktop for the recessed sink.
 var counter:=_groups[0]
 _box(counter,Vector3(1.7365,0.04,0.70),Vector3(-0.41825,0.83,0),ivory,0)
 _box(counter,Vector3(0.2365,0.04,0.70),Vector3(1.16825,0.83,0),ivory,0)
 _box(counter,Vector3(0.60,0.04,0.16),Vector3(0.75,0.83,-0.27),ivory,0)
 _box(counter,Vector3(0.60,0.04,0.12),Vector3(0.75,0.83,0.29),ivory,0)
 # Full-height 900 mm support, with the kitchen board between hob and hood.
 _box(scene,Vector3(0.90,2.4,0.11),Vector3(-0.8365,1.2,-0.425),white)
 _box(_groups[1],Vector3(0.88,0.80,0.014),Vector3(-0.8365,1.25,-0.362),Color("e3e5df"),1)
 var hood:=_groups[2]
 _box(hood,Vector3(0.88,0.68,0.54),Vector3(-0.8365,2.0,-0.105),Color("b0b5b6"),2,0.55)
 _box(hood,Vector3(0.90,0.035,0.58),Vector3(-0.8365,1.647,-0.10),Color("c6cdcd"),2,0.6)
 _box(hood,Vector3(0.76,0.009,0.40),Vector3(-0.8365,1.626,-0.10),Color("666e70"),2,0.3)
 for x in [-1.1,-0.56]:_cylinder(hood,Vector3(x,1.619,0.08),0.025,0.008,Color("fff5ce"))
 # Waist-height back panel; orbiting reveals its full rear face.
 _box(_groups[3],Vector3(2.573,0.85,0.075),Vector3(0,0.425,-0.405),white,3)
 # Black hob, simple rings and recessed front controls match the reference.
 var hob:=_groups[6]
 _box(hob,Vector3(0.63,0.009,0.48),Vector3(-0.91,0.856,0),Color("202726"),6,0.15)
 for p in [Vector3(-1.06,0.863,0.09),Vector3(-0.77,0.863,0.08),Vector3(-0.92,0.863,-0.12)]:
  var ring:=MeshInstance3D.new()
  var torus:=TorusMesh.new()
  torus.inner_radius=0.073
  torus.outer_radius=0.077
  torus.rings=24
  torus.ring_segments=8
  ring.mesh=torus
  ring.position=p
  ring.material_override=_material(Color("727a77"),0.3)
  hob.add_child(ring)
 _box(scene,Vector3(0.63,0.10,0.016),Vector3(-0.90,0.74,0.339),Color("838b8a"),-1,0.4)
 # Stainless basin, rim, drain and a clearly visible mixer faucet.
 var sink:=_groups[4]
 _rounded_sink(sink,silver)
 _cylinder(sink,Vector3(0.75,0.722,0.06),0.035,0.006,Color("777f80"))
 var faucet:=_groups[5]
 _box(faucet,Vector3(0.075,0.16,0.075),Vector3(0.75,0.925,-0.265),silver,5,0.7)
 var previous:=Vector3(0.75,0.86,-0.265)
 for i in range(1,17):
  var t: float=float(i)/16
  var q: float=1.0-t
  var point:=Vector3(0.75,0.86,-0.265)*q*q*q+Vector3(0.75,1.28,-0.265)*3*q*q*t+Vector3(0.75,1.28,-0.06)*3*q*t*t+Vector3(0.75,1.04,-0.06)*t*t*t
  _pipe(faucet,previous,point,0.012,silver)
  previous=point
 _box(faucet,Vector3(0.07,0.012,0.018),Vector3(0.80,0.94,-0.265),silver,5,0.6)

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
 _position_markers()
 view_changed.emit()

func set_view(which: String) -> void:
 yaw={"front":0.0,"rear":PI,"perspective":0.62}.get(which,0.62)
 pitch=0.15 if which=="front" else (0.30 if which=="rear" else 0.34)
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
   entry.material.albedo_color=entry.color.lerp(Color("5bc4b5"),0.18) if active else entry.color
  if i<_markers.size():
   var marker: Button=_markers[i]
   var style:=UI.box(Color("008f98") if active else (Color("e4f6e8") if _solved[i] else Color("fffdf0")),Color("008f98") if active else Color("8fb6ab"),18,0)
   style.shadow_size=2
   for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:marker.add_theme_stylebox_override(state,style)
   marker.get_node("MarkerNumber").add_theme_color_override("font_color",Color.WHITE if active else UI.INK)

func _position_markers() -> void:
 if not is_instance_valid(camera):return
 for i in range(_markers.size()):
  var point:=camera.unproject_position(_anchors[i])*size/Vector2(viewport.size)
  var center:=point+_label_offsets[i]
  center=center.clamp(Vector2(18,18),size-Vector2(18,18))
  _markers[i].position=center-Vector2(15,15)
 queue_redraw()

func _draw() -> void:
 if not is_instance_valid(camera):return
 for i in range(_markers.size()):
  var point:=camera.unproject_position(_anchors[i])*size/Vector2(viewport.size)
  draw_line(point,_markers[i].position+Vector2(15,15),Color("368d82"),1.2,true)

func _choose(index: int) -> void:
 set_selected(index)
 part_selected.emit(index)

func _ray_part(position: Vector2) -> int:
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
 if event is InputEventMouseButton:
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
  yaw-=event.relative.x*0.009
  pitch=clampf(pitch+event.relative.y*0.007,0.08,1.20)
  _update_camera()
  accept_event()
 elif event is InputEventMouseMotion:
  _pending_hover=event.position

func view_state() -> Dictionary:
 return {"yaw":yaw,"pitch":pitch,"zoom":zoom}

func apply_view_state(state: Dictionary) -> void:
 yaw=float(state.get("yaw",yaw))
 pitch=clampf(float(state.get("pitch",pitch)),0.08,1.2)
 zoom=clampf(float(state.get("zoom",zoom)),2.55,4.8)
 _update_camera()

func marker_center(index: int) -> Vector2:
 return _markers[index].position+_markers[index].size*0.5 if index>=0 and index<_markers.size() else size*0.5

func _number_hover(index: int) -> void:
 set_hovered(index)
 if not _pressed:number_hovered.emit(index)

func _pipe(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
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
