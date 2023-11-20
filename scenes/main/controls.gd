extends Control


@onready
var height_map_rect: TextureRect = $HeightMapRect
@onready
var temp_map_rect: TextureRect = $TempMapRect
@onready
var rain_map_rect: TextureRect = $RainMapRect
@onready
var biome_map_rect: TextureRect = $BiomeMapRect

@onready
var gen_button: Button = $UIParent/ButtonParent/Button
var width: int
var height: int

var chunk_size: int = 8

# Called when the node enters the scene tree for the first time.
func _ready():
	width = floori(size.x)
	height = floori(size.y)
	gen_button.button_down.connect(_do_gen)
	
	_do_gen()

func _do_gen():
	generate(chunk_size)




func generate(p_chunk_size:int) -> void:
	var height_map: Image = WorldGen.get_island_height_map(p_chunk_size, Vector2(width,height)/2, Vector2(width, height))
	
	height_map_rect.texture = ImageTexture.create_from_image(height_map)
	
	var temp_map: Image = WorldGen.get_island_temp_map(height_map, p_chunk_size)
	
	temp_map_rect.texture = ImageTexture.create_from_image(temp_map)
	
	var rain_map: Image = WorldGen.get_island_rainfall_map(height_map, p_chunk_size)
	
	rain_map_rect.texture = ImageTexture.create_from_image(rain_map)
	
	var biome_map: Image = WorldGen.get_island_biome_map(height_map, temp_map, rain_map)
	
	biome_map_rect.texture = ImageTexture.create_from_image(biome_map)
