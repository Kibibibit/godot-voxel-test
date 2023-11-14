extends MeshInstance3D
class_name VoxelMeshInstance


const SOUTH: int = 0
const NORTH: int = 1
const EAST: int = 2
const WEST: int = 3
const TOP: int = 4
const BOTTOM: int = 5

const DIM_WE: int = 0
const DIM_BT: int = 1
const DIM_SN: int = 2

const NOT_TRANSPARENT: int = 0
const TRANSPARENT: int = 1

const FACE_TRANSPARENT: int = 0
const FACE_TYPE: int = 1
const FACE_SIDE: int = 2

const CHUNK_SIZE: int = 16

const SIDE_MAP: Dictionary = {
	SOUTH: Vector3(0, 0, -1),
	NORTH: Vector3(0, 0, 1),
	EAST: Vector3(1, 0, 0),
	WEST: Vector3(-1, 0, 0),
	TOP: Vector3(0,1,0),
	BOTTOM: Vector3(0,-1,0)
}

var data: Array[Array]

var angle: float = 0.0

func _get_voxel(x: int, y: int, z:int) -> int:
	return data[y][z][x]

func _get_face(x: int, y:int, z:int, side: int) -> Array[int]:
	return _face(NOT_TRANSPARENT, _get_voxel(x,y,z), side)

func _face(transparent: int = 0, type: int = 0, side: int = 0) -> Array[int]:
	return [
		transparent if type != 0 else TRANSPARENT,
		type,
		side
	]

func _null_face() -> Array[int]:
	return [-1, -1, -1]

func _face_is_null(face: Array[int]) -> bool:
	return face[FACE_TRANSPARENT] == -1

func _face_equals(face_a: Array[int], face_b: Array[int]) -> bool:
	return face_a[FACE_TRANSPARENT] == face_b[FACE_TRANSPARENT] && face_a[FACE_TYPE] == face_b[FACE_TYPE]


func _ready():
	mesh = ArrayMesh.new()
	


func greedy():
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	var mask: Array[Array] = []
	mask.resize(CHUNK_SIZE*CHUNK_SIZE)
	
	var i: int = 0
	var j: int = 0
	var k: int = 0
	var l: int = 0
	var w: int = 0
	var h: int = 0
	var u: int = 0
	var v: int = 0
	var n: int = 0 
	var side: int = 0
	
	var x: Array[int] = [0,0,0]
	var q: Array[int] = [0,0,0]
	var du: Array[int] = [0,0,0]
	var dv: Array[int] = [0,0,0]
	
	var iters: int = 1
	var back_face: bool = true
	
	var face_a: Array[int] = _face()
	var face_b: Array[int] = _face()
	
	while (iters >= 0):
		
		for dimension in 3:
			u = (dimension + 1) % 3
			v = (dimension + 2) % 3
			
			x[0] = 0
			x[1] = 0
			x[2] = 0
			
			q[0] = 0
			q[1] = 0
			q[2] = 0
			q[dimension] = 1
			
			if (dimension == DIM_WE):
				side = WEST if back_face else EAST
			elif (dimension == DIM_BT):
				side = BOTTOM if back_face else TOP
			elif (dimension == DIM_SN):
				side = SOUTH if back_face else NORTH
		
			x[dimension] = -1
			
			while (x[dimension] < CHUNK_SIZE):
				
				# Mask computation
				n = 0
				
				x[v] = 0
				while (x[v] < CHUNK_SIZE):
					
					x[u] = 0
					while (x[u] < CHUNK_SIZE):
						
						if (x[dimension] >= 0):
							face_a = _get_face(x[0], x[1], x[2], side)
						else:
							face_a = _null_face()
						
						if (x[dimension] < CHUNK_SIZE - 1):
							face_b = _get_face(x[0] + q[0], x[1] + q[1], x[2] + q[2], side)
						else:
							face_b = _null_face()
						
						if (!_face_is_null(face_a) && !_face_is_null(face_b) && _face_equals(face_a, face_b)):
							mask[n] = _null_face()
						else:
							mask[n] = face_b if back_face else face_a
						
						n += 1
						
						x[u] += 1
					x[v] += 1
				x[dimension] += 1
				n = 0
				
				j = 0
				
				while (j < CHUNK_SIZE):
					i = 0
					while (i < CHUNK_SIZE):
						if (!_face_is_null(mask[n])):
							
							w = 1
							while (i + w < CHUNK_SIZE && !_face_is_null(mask[n+w]) && _face_equals(mask[n+w], mask[n])):
								w +=1
							
							var done: bool = false
							
							h = 1
							while (j+h < CHUNK_SIZE):
								
								k = 0
								while (k < w):
									if (
										_face_is_null(mask[n+k+h*CHUNK_SIZE]) ||
										!_face_equals(mask[n+k+h*CHUNK_SIZE], mask[n])
									):
										done = true
										break
									k+= 1
								
								if (done):
									break
								
								h+=1
							
							if (mask[n][FACE_TRANSPARENT] != TRANSPARENT):
								
								x[u] = i
								x[v] = j
								du[0] = 0
								du[1] = 0
								du[2] = 0
								du[u] = w
								
								dv[0] = 0
								dv[1] = 0
								dv[2] = 0
								dv[v] = h
								
								var index_offset: int = verts.size()
								verts.push_back(Vector3(x[0], x[1], x[2]))
								verts.push_back(Vector3(x[0] + du[0], x[1] + du[1], x[2]+du[2]))
								verts.push_back(Vector3(x[0] + du[0] + dv[0], x[1] + du[1] + dv[1], x[2]+du[2]+dv[2]))
								verts.push_back(Vector3(x[0] + dv[0], x[1] + dv[1], x[2] + dv[2]))
								uvs.push_back(Vector2(0,0))
								uvs.push_back(Vector2(0,0))
								uvs.push_back(Vector2(0,0))
								uvs.push_back(Vector2(0,0))
								
								
								normals.append(SIDE_MAP[side])
								normals.append(SIDE_MAP[side])
								normals.append(SIDE_MAP[side])
								normals.append(SIDE_MAP[side])
								if (back_face):
									indices.append_array([index_offset+1, index_offset+3, index_offset, index_offset+1, index_offset+2, index_offset+3])
								else:
									indices.append_array([index_offset, index_offset+3, index_offset+1, index_offset+3, index_offset+2, index_offset+1])
							l = 0
							while (l < h):
								k = 0
								
								while (k < w):
									
									mask[n+k+l*CHUNK_SIZE] = _null_face()
									
									k += 1
								
								l += 1
							
							i += w
							n += w
						else:
							i += 1
							n += 1
						
					j += 1
				
				
		
		
		back_face = false
		iters -= 1
	
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	mesh.clear_surfaces()
	# No blendshapes, lods, or compression used.
	if (verts.size() > 0):
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)



