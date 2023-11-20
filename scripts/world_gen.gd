extends Node

const BLOCK_TEXTURE_PATH : String = "res://assets/blocks/"


const SEA_LEVEL_FLOAT: float = 0.25
const MOUNTAIN_LEVEL_FLOAT: float = 0.875

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

var gradient: GradientTexture1D = preload("res://resources/gradient.tres")

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
	
	var dirt_level: int = height - 10
	
	
	if (index.y > dirt_level && index.y < height && height >= SEA_LEVEL):
		return 3
	elif (index.y > height-2 && index.y <= height && height < SEA_LEVEL):
		return 4
	elif (index.y == height && height >= SEA_LEVEL):
		return 1
	elif (index.y > height && index.y <= SEA_LEVEL && height < SEA_LEVEL):
		if (index.y == SEA_LEVEL):
			return 6
		return 5
	elif (index.y > height):
		return 0
	else:
		return 2 if get_cave_map(index) > -0.5 else 0
	


func get_island_height_map(chunk_size:int, center: Vector2, size: Vector2) -> Image:
	
	var max_dist = min(size.y-center.y, size.x-center.x)
	
	noise.frequency = 0.05 / chunk_size
	noise.fractal_octaves = 5
	noise.cellular_jitter = 0.1
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.seed = Time.get_ticks_usec()
	
	var starting_image: Image = noise.get_image(floori(size.x), floori(size.y))
	
	var out: Image = Image.create(floori(size.x), floori(size.y), false, Image.FORMAT_R8)
	
	
	for x in ceili(size.x/chunk_size):
		for y in ceili(size.y/chunk_size):
			var mult: float = 1.0-(Vector2(x*chunk_size,y*chunk_size).distance_to(center)/max_dist)
			
			mult = (1.0 - pow(1.0 - mult, 4))
			
			var chunk_x: int = x*chunk_size
			var chunk_y: int = y*chunk_size
			
			if (chunk_x < size.x && chunk_y < size.y):
				var mult_noise: float = (noise.get_noise_2d(chunk_x, chunk_y) / 2) + 1
				var value: float = mult * mult_noise * starting_image.get_pixel(x*chunk_size, y*chunk_size).r 
				for xx in chunk_size:
					for yy in chunk_size:
						var _x: int = x*chunk_size + xx
						var _y: int = y*chunk_size + yy
						
						if (_x >= 0 && _x < size.x && _y >= 0 && _y < size.y):
							out.set_pixel(_x, _y, Color(value, value, value))
	
	return out

func get_island_temp_map(height_map: Image, chunk_size:int) -> Image:
	
	
	noise.frequency = 0.05 / chunk_size
	noise.fractal_octaves = 5
	noise.cellular_jitter = 0.1
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.seed = Time.get_ticks_usec()
	
	var out: Image = Image.create(height_map.get_size().x, height_map.get_size().y, false, Image.FORMAT_R8)
	
	var world_height: int = height_map.get_size().y
	var world_width: int = height_map.get_size().x
	var equator: float = float(world_height)/2
	
	for x in ceili(float(world_width)/chunk_size):
		for y in ceili(float(world_height)/chunk_size):
			var chunk_x: int = x*chunk_size
			var chunk_y: int = y*chunk_size
			var latitude: float = 1 - (2*abs(equator-chunk_y)/world_height)
			if (chunk_x < world_width && chunk_y < world_height):
				var height_at: float = height_map.get_pixel(chunk_x,chunk_y).r
				if (height_at >= SEA_LEVEL_FLOAT):
					
					latitude += noise.get_noise_1d(chunk_x*0.5)*0.1
					
					
					var height_mult: float = 1.0 - (height_at-SEA_LEVEL_FLOAT/(1-SEA_LEVEL_FLOAT))
					latitude *= height_mult
					
					for xx in chunk_size:
						for yy in chunk_size:
							var _x = chunk_x + xx
							var _y = chunk_y + yy
							if (_x >= 0 && _x < world_width && _y >= 0 && _y < world_height):
								out.set_pixel(_x, _y,Color(latitude, latitude, latitude))
			
	return out

func get_island_rainfall_map(height_map: Image, chunk_size: int) -> Image:
	var world_height: int = height_map.get_size().y
	var world_width: int = height_map.get_size().x
	
	noise.frequency = 0.005
	noise.fractal_octaves = 2
	noise.cellular_jitter = 0.1
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.seed = Time.get_ticks_usec()
	
	var out: Image = Image.create(world_width, world_height, false, Image.FORMAT_R8)
	
	for x in ceili(float(world_width)/chunk_size):
		for y in ceili(float(world_height)/chunk_size):
			var chunk_x: int = x*chunk_size
			var chunk_y: int = y*chunk_size
			if (chunk_x < world_width && chunk_y < world_height):
				var height_at: float = height_map.get_pixel(chunk_x,chunk_y).r
				if (height_at >= SEA_LEVEL_FLOAT):
					
					var rainfall = 0.5*(noise.get_noise_2d(chunk_x,chunk_y) + 1) * (1.0-height_at)
					
					
					for xx in chunk_size:
						for yy in chunk_size:
							var _x = chunk_x + xx
							var _y = chunk_y + yy
							if (_x >= 0 && _x < world_width && _y >= 0 && _y < world_height):
								out.set_pixel(_x,_y,Color(rainfall, rainfall, rainfall))

	return out


func get_island_biome_map(height_map, temp_map, rain_map) -> Image:
	var world_height: int = height_map.get_size().y
	var world_width: int = height_map.get_size().x
	
	var out: Image = Image.create(world_width, world_height, false, Image.FORMAT_RGB8)

	
	for x in world_width:
		for y in world_height:
			
			var biome: int = Biomes.OCEAN
			
			var height_at: float = height_map.get_pixel(x,y).r
			var temp_at: float = temp_map.get_pixel(x,y).r
			var rain_at: float = rain_map.get_pixel(x,y).r
			

			
			if (height_at >= 0.1 && height_at < SEA_LEVEL_FLOAT):
				biome = Biomes.COAST
			elif( height_at >= SEA_LEVEL_FLOAT && height_at < MOUNTAIN_LEVEL_FLOAT ):
				biome = Biomes.GRASSLAND
				
				if (temp_at >= 0.6):
					if (rain_at > 0.4):
						biome = Biomes.RAINFOREST
					elif (rain_at > 0.2):
						biome = Biomes.SAVANNA
					else:
						biome = Biomes.DESERT
				
				if (temp_at < 0.6):
					if (rain_at < 0.3):
						biome = Biomes.GRASSLAND
					else:
						biome = Biomes.WOODLAND
				
				if (temp_at < 0.35 && rain_at >= 0.2):
					biome = Biomes.BOREAL
				elif (temp_at < 0.35 && rain_at < 0.2):
					biome = Biomes.GRASSLAND
				
		
				
				if (temp_at < 0.25):
					biome = Biomes.TUNDRA
				
				
				
			elif(height_at >= MOUNTAIN_LEVEL_FLOAT):
				biome = Biomes.MOUNTAIN
			
			var color: Color = Color.BLACK
			
			if (biome == Biomes.OCEAN):
				color = Color.BLUE
			elif (biome == Biomes.COAST):
				color = Color.LIGHT_SKY_BLUE
			elif (biome == Biomes.LAND):
				color = Color.GREEN
			elif (biome == Biomes.MOUNTAIN):
				color = Color.DIM_GRAY
			elif (biome == Biomes.TUNDRA):
				color = Color.WHITE_SMOKE
			elif (biome == Biomes.BOREAL):
				color = Color.DARK_GREEN
			elif (biome == Biomes.GRASSLAND):
				color = Color.LIGHT_GREEN
			elif (biome == Biomes.WOODLAND):
				color = Color.SEA_GREEN
			elif (biome == Biomes.DESERT):
				color = Color.BISQUE
			elif (biome == Biomes.RAINFOREST):
				color = Color.GREEN
			elif (biome == Biomes.SAVANNA):
				color = Color.OLIVE
			
			out.set_pixel(x,y,color)
			
	return out

