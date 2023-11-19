extends Node

const BLOCK_TEXTURE_PATH : String = "res://assets/blocks/"

const SEA_LEVEL: int = 64
const SEA_FLOOR_LEVEL: int = 35
const MAX_HEIGHT: int = 128
const MIN_TEMP: int = -40
const MAX_TEMP: int = 60

const TEMP_SEED: int = 441
const HUMD_SEED: int = 1241251

var ground_level: int = 32
var noise : FastNoiseLite
var block_texture_array := Texture2DArray.new()
var block_material : ShaderMaterial = preload("res://resources/texture_array_material.tres")
var gen_seed: int =  Time.get_ticks_usec()



func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	
	_load_block_textures()


func _load_block_textures():
	var dir_access := DirAccess.open(BLOCK_TEXTURE_PATH)
	dir_access.list_dir_begin()
	
	
	var file_path: String = dir_access.get_next()
	
	var array: Array[Image] = []
	
	
	
	while (not file_path.is_empty()):
		
		if (file_path.ends_with(".png")):
			var image: Image = (load("%s%s" % [BLOCK_TEXTURE_PATH, file_path]) as Texture2D).get_image()
			array.append(image)
		
		file_path = dir_access.get_next()
	
	block_texture_array.create_from_images(array)
	block_material.set_shader_parameter('texture_array', block_texture_array)
	block_material.set_shader_parameter('material_count', array.size())


func get_biome_height_map(x: int, z:int) -> int:
	noise.seed = gen_seed
	noise.fractal_octaves = 3
	noise.frequency = 0.005
	
	var seed_value: float = noise.get_noise_2d(x,z)
	seed_value *= seed_value * sign(seed_value)
	if (seed_value >= 0.0):
		return SEA_LEVEL + floori(seed_value * (MAX_HEIGHT-SEA_LEVEL))
	else:
		return SEA_LEVEL + floori(seed_value * (SEA_LEVEL-SEA_FLOOR_LEVEL))
	

func get_biome_temp_map(x: int, z:int) -> int:
	noise.fractal_octaves = 1
	noise.frequency = 0.005
	noise.seed = gen_seed + TEMP_SEED
	var seed_value: float = noise.get_noise_2d(x,z)
	seed_value += 1.0
	seed_value /= 2.0
	
	return floori(lerp(MIN_TEMP, MAX_TEMP, seed_value))

func get_biome_humdity_map(x:int, z:int) -> int:
	noise.fractal_octaves = 5
	noise.frequency = 0.005
	noise.seed = gen_seed + HUMD_SEED
	var seed_value: float = noise.get_noise_2d(x,z)
	seed_value += 1.0
	seed_value /= 2.0
	return floori(seed_value*100)


func get_cave_map(index: Vector3) -> float:
	noise.seed = gen_seed
	noise.fractal_octaves = 3
	noise.frequency = 0.05
	return noise.get_noise_3dv(index)


func get_block(index: Vector3i) -> int:
	var height: int = get_biome_height_map(index.x, index.z)
	
	var dirt_level: int = height - 2
	
	if (index.y > dirt_level && index.y <= height && height >= SEA_LEVEL):
		return 2
	elif (index.y > height):
		return 0
	else:
		return 1 if get_cave_map(index) > -0.5 else 0
	

