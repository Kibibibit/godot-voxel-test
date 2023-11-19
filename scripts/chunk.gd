extends MeshInstance3D
class_name Chunk

var material_a: Image
var material_b: Image
var texture_array: Texture2DArray = Texture2DArray.new()
static var material: ShaderMaterial = preload("res://resources/texture_array_material.tres")

var chunk_index: Vector3i
var chunk_size:int

func _init(p_chunk_size: int, p_chunk_index: Vector3i):
	
	material_a = load("res://assets/grass.png").get_image()
	material_b = load("res://assets/rock.png").get_image()
	texture_array.create_from_images([material_b, material_a])
	chunk_index = p_chunk_index
	chunk_size = p_chunk_size
	material.set_shader_parameter('texture_array', texture_array)
	material.set_shader_parameter('material_count', 2)

func _ready():
	mesh = VoxelMesh.new()
	
	var voxel_data := PackedByteArray()
	voxel_data.resize(chunk_size*chunk_size*chunk_size)
	
	for x in chunk_size:
		for y in chunk_size:
			for z in chunk_size:
				voxel_data[y*chunk_size*chunk_size + z*chunk_size + x] = WorldGen.get_block((chunk_index*chunk_size) + Vector3i(x,y,z))
	
	mesh.remesh(chunk_size, voxel_data, 2)
	if (mesh.get_surface_count() > 0):
		mesh.surface_set_material(0, material)
	position = chunk_index*chunk_size
