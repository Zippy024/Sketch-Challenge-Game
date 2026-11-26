extends RefCounted
const STEEL=Color("bec7cb")
static func material(color: Color,metal: float=.55) -> StandardMaterial3D:
 var m=StandardMaterial3D.new()
 m.albedo_color=color
 m.metallic=metal
 m.roughness=.26 if metal>.2 else .46
 return m
static func box(parent: Node3D,at: Vector3,dim: Vector3,color: Color=STEEL,metal: float=.55) -> void:
 var node=MeshInstance3D.new()
 var mesh=BoxMesh.new()
 mesh.size=dim
 node.mesh=mesh
 node.material_override=material(color,metal)
 node.position=at
 parent.add_child(node)
static func cylinder(parent: Node3D,at: Vector3,r: float,h: float,color: Color=STEEL) -> void:
 var n=MeshInstance3D.new()
 var mesh=CylinderMesh.new()
 mesh.top_radius=r;mesh.bottom_radius=r;mesh.height=h;mesh.radial_segments=32
 n.mesh=mesh;n.material_override=material(color);n.position=at
 parent.add_child(n)
static func pipe(parent: Node3D,a: Vector3,b: Vector3,r: float=.014,color: Color=STEEL) -> void:
 var node=MeshInstance3D.new()
 var mesh=CylinderMesh.new()
 mesh.top_radius=r;mesh.bottom_radius=r;mesh.height=a.distance_to(b);mesh.radial_segments=24
 node.mesh=mesh;node.material_override=material(color,.85)
 node.position=(a+b)*.5
 node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
 parent.add_child(node)
static func ring(w: float,d: float,r: float,y: float) -> PackedVector3Array:
 var result=PackedVector3Array()
 for k in range(4):
  var center=Vector2((w*.5-r)*(1 if k in [0,3] else -1),(d*.5-r)*(1 if k in [0,1] else -1))
  for j in range(9):
   var angle=k*PI*.5+j*PI/16
   result.append(Vector3(center.x+cos(angle)*r,y,center.y+sin(angle)*r))
 return result
static func bowl(parent: Node3D,offset: Vector3,outer: Vector2,inner: Vector2,round_bowl: bool=false) -> void:
 var rings=[ring(outer.x,outer.y,.035,0),ring(inner.x,inner.y,inner.y*.5 if round_bowl else .045,-.009),ring(inner.x*.82,inner.y*.8,inner.y*.4 if round_bowl else .045,-.14)]
 var vertices=PackedVector3Array();var normals=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array()
 for k in range(3):
  for p in rings[k]:
   vertices.append(p)
   colors.append(Color.WHITE if k==0 else (Color(.83,.88,.91) if k==1 else Color(.52,.61,.68)))
   normals.append(Vector3.UP if k!=1 else Vector3(-p.x*2,.7,-p.z*2).normalized())
 var count=rings[0].size()
 for row in range(2):
  for i in range(count):
   var next=(i+1)%count
   indices.append_array([row*count+i,row*count+next,(row+1)*count+i,row*count+next,(row+1)*count+next,(row+1)*count+i])
 vertices.append(Vector3(0,-.14,0));normals.append(Vector3.UP);colors.append(Color(.52,.61,.68))
 for i in range(count):indices.append_array([vertices.size()-1,2*count+i,2*count+(i+1)%count])
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices
 var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var node=MeshInstance3D.new();node.mesh=mesh;node.position=offset
 var m=material(STEEL,.8);m.cull_mode=BaseMaterial3D.CULL_DISABLED;m.vertex_color_use_as_albedo=true
 node.material_override=m;parent.add_child(node)
 cylinder(parent,offset+Vector3(0,-.137,0),.026,.003,Color("657984"))
