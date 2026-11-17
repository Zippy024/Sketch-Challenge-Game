extends "res://Stage3Assets/Model/KitchenModel.gd"
# Home-only visual rewards. Never alters the assessed Stage 3 installation.
var completed_stages: int=0
func _ready() -> void:
 super._ready()
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_physics_process(false)
 scene.get_child(0).environment.background_color=Color("fffdf6")
func _build_pointers() -> void:
 pass
func _update_camera() -> void:
 super._update_camera()
 if completed_stages!=1 or not is_instance_valid(camera):return
 # Fill the home preview with the short foundation, rather than reserving
 # empty space for the hood that has not been earned yet.
 var target:=Vector3(0,0.48,0)
 camera.position=target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*6.0
 camera.look_at(target,Vector3.UP)
 var bounds:=AABB(Vector3(-1.32,0,-0.50),Vector3(2.64,1.02,0.90))
 var aspect:=float(viewport.size.x)/maxf(1.0,float(viewport.size.y))
 var tangent: float=0.0
 for i in range(8):
  var point:=camera.to_local(bounds.get_endpoint(i))
  var depth:=maxf(0.1,-point.z)
  tangent=maxf(tangent,maxf(absf(point.y)/depth,absf(point.x)/(depth*aspect)))
 camera.fov=rad_to_deg(2.0*atan(tangent*1.12))
func _build_kitchen() -> void:
 super._build_kitchen()
 var floor:=scene.get_node("RoomOakFloor") as Node3D
 floor.scale=Vector3(0.65,1,0.39)
 floor.position.z=0.0
 if completed_stages==0:
  for child in scene.get_children():
   if child is MeshInstance3D and child!=floor:child.hide()
  for group in _groups:group.hide()
  _wire_box(Vector3(-1.285,0.08,-0.32),Vector3(1.285,0.85,0.32))
  _wire_box(Vector3(-1.21,1.73,-0.33),Vector3(-0.44,2.38,0.18))
  _wire_box(Vector3(-1.275,0.85,-0.395),Vector3(-0.375,2.41,-0.34))
  for x in [-0.54,0.20]:_wire_box(Vector3(x-0.015,0.10,0.305),Vector3(x+0.015,0.81,0.32))
 elif completed_stages<3:
  for index in [2,4,5,6]:_groups[index].hide()
  if completed_stages==1:_groups[1].hide()
  for child in scene.get_children():
   if child is MeshInstance3D and child.position.y>0.86:child.hide()
 if completed_stages>=4:
  for entry in _materials[7]:entry.color=Color("d8e0d1")
 if completed_stages>=6:
  for entry in _materials[0]:entry.color=Color("eee8dc")
 if completed_stages>=7:
  _box(scene,Vector3(0.23,0.014,0.32),Vector3(0.05,0.877,0.06),Color("b69462"),-1,0,false)
 if completed_stages>=8:_plant()
 if completed_stages>=9:
  _cylinder(scene,Vector3(-0.35,0.90,0.10),0.08,0.06,Color("e9e4d7"))
 if completed_stages>=10:
  _box(scene,Vector3(0.12,0.19,0.12),Vector3(-0.38,0.97,-0.18),Color("d6b47a"),-1,0,false)
func _wire_box(low: Vector3, high: Vector3) -> void:
 var bounds:=AABB(low,high-low)
 var lines:=ImmediateMesh.new()
 var material:=StandardMaterial3D.new()
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color=Color("439e96")
 lines.surface_begin(Mesh.PRIMITIVE_LINES,material)
 for i in range(8):
  for bit in [1,2,4]:
   var other: int=i^bit
   if i<other:
    lines.surface_add_vertex(bounds.get_endpoint(i))
    lines.surface_add_vertex(bounds.get_endpoint(other))
 lines.surface_end()
 var instance:=MeshInstance3D.new()
 instance.mesh=lines
 instance.name="JourneyBlueprint"
 scene.add_child(instance)
func _plant() -> void:
 _cylinder(scene,Vector3(0.15,0.94,-0.16),0.065,0.15,Color("eeeadf"))
 for i in range(7):
  var leaf:=MeshInstance3D.new()
  var sphere:=SphereMesh.new()
  sphere.radius=0.045
  sphere.height=0.20
  sphere.radial_segments=12
  sphere.rings=6
  leaf.mesh=sphere
  leaf.position=Vector3(0.15+sin(float(i))*0.055,1.08+float(i%3)*0.028,-0.16+cos(float(i))*0.04)
  leaf.rotation.z=sin(float(i))*0.8
  leaf.material_override=_material(Color("71966c"))
  scene.add_child(leaf)
