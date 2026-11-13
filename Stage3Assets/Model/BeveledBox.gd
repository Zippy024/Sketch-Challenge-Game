extends RefCounted
# Small physical chamfers catch soft light without altering the picking volumes.
static func create(dimensions: Vector3, amount: float) -> ArrayMesh:
 var half:=dimensions*0.5
 var bevel:=minf(amount,minf(half.x,minf(half.y,half.z))*0.35)
 var inner:=half-Vector3.ONE*bevel
 var vertices:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var indices:=PackedInt32Array()
 # Six flat faces.
 for axis in range(3):
  var first: int=(axis+1)%3
  var second: int=(axis+2)%3
  for direction in [-1.0,1.0]:
   var face: Array[Vector3]=[]
   for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
    var point:=Vector3.ZERO
    point[axis]=half[axis]*direction
    point[first]=inner[first]*corner.x
    point[second]=inner[second]*corner.y
    face.append(point)
   var normal:=Vector3.ZERO
   normal[axis]=direction
   _face(face,normal,vertices,normals,indices)
 # Twelve chamfered edges.
 for axis in range(3):
  var first: int=(axis+1)%3
  var second: int=(axis+2)%3
  for side_a in [-1.0,1.0]:
   for side_b in [-1.0,1.0]:
    var face: Array[Vector3]=[]
    for end in [-1.0,1.0]:
     var point:=Vector3.ZERO
     point[axis]=inner[axis]*end
     point[first]=half[first]*side_a
     point[second]=inner[second]*side_b
     face.append(point)
     point[first]=inner[first]*side_a
     point[second]=half[second]*side_b
     face.append(point)
    var ordered: Array[Vector3]=[face[0],face[1],face[3],face[2]]
    var normal:=Vector3.ZERO
    normal[first]=side_a
    normal[second]=side_b
    _face(ordered,normal.normalized(),vertices,normals,indices)
 # Eight small corner facets.
 for x in [-1.0,1.0]:
  for y in [-1.0,1.0]:
   for z in [-1.0,1.0]:
    var sign_vector:=Vector3(x,y,z)
    var face: Array[Vector3]=[]
    for axis in range(3):
     var point:=inner*sign_vector
     point[axis]=half[axis]*sign_vector[axis]
     face.append(point)
    _face(face,sign_vector.normalized(),vertices,normals,indices)
 var arrays:=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=vertices
 arrays[Mesh.ARRAY_NORMAL]=normals
 arrays[Mesh.ARRAY_INDEX]=indices
 var result:=ArrayMesh.new()
 result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 return result

static func _face(points: Array[Vector3], normal: Vector3, vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> void:
 var start: int=vertices.size()
 for point in points:
  vertices.append(point)
  normals.append(normal)
 for i in range(1,points.size()-1):
  var clockwise: bool=(points[i]-points[0]).cross(points[i+1]-points[0]).dot(normal)<0
  indices.append_array([start,start+i,start+i+1] if clockwise else [start,start+i+1,start+i])
