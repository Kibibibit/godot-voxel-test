extends MeshInstance3D
class_name Chunk


var chunk_index: Vector3i
var chunk_size: int

func _init(p_chunk_size: int, p_chunk_index: Vector3i):
	chunk_index = p_chunk_index
	chunk_size = p_chunk_size


func _ready():
	mesh = VoxelMesh.new()
	
	var voxel_data := PackedByteArray()
	voxel_data.resize(chunk_size*chunk_size*chunk_size)
	
	for x in chunk_size:
		for y in chunk_size:
			for z in chunk_size:
				voxel_data[y*chunk_size*chunk_size + z*chunk_size + x] = WorldGen.get_block((chunk_index*chunk_size) + Vector3i(x,y,z))
	
	mesh.remesh(chunk_size, voxel_data, 6)
	if (mesh.get_surface_count() > 0):
		mesh.surface_set_material(0, WorldGen.block_material)
	position = chunk_index*chunk_size
