extends Node


var ground_level: int = 32

var noise : FastNoiseLite


func _ready():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.fractal_octaves = 2
	noise.frequency = 0.05
	noise.seed = Time.get_ticks_usec()


func get_block(index: Vector3i) -> int:
	var height: int = ground_level + floori(4.0*noise.get_noise_2d(index.x, index.z))
	
	var block: int = 1 if noise.get_noise_3dv(index) > -0.5 else 0
	
	if (index.y < height+2 && index.y >= height):
		return 2
	elif (index.y < height):
		return block
	else:
		return 0
