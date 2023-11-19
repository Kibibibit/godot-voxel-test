extends TextureRect


var image: Image
var width: int
var height: int

func _ready() -> void:
	var full_width: int = floori(size.x)
	height = floori(size.y)
	image = Image.create(full_width, height, false, Image.FORMAT_RGB8)
	
	width = floori(float(full_width)/3.0)
	
	_generate_height_map()
	_generate_temp_map()
	_generate_humd_map()
	
	
	texture = ImageTexture.create_from_image(image)
	

func _generate_height_map():
	for x in width:
		for y in height:
			
			var block_height :int = WorldGen.get_biome_height_map(x-floori(float(width)/2),y-floori(float(height)/2))
			
			var green: float = 0.0
			var blue: float = 0.0
			if (block_height < WorldGen.SEA_LEVEL):
				blue = float(block_height)/(WorldGen.SEA_LEVEL)
			else:
				green = float(block_height)/(WorldGen.MAX_HEIGHT)
			image.set_pixel(x,y, Color(0.0, green ,blue))

func _generate_temp_map():
	for x in width:
		for y in height:
			var block_temp : int = WorldGen.get_biome_temp_map(x-floori(float(width)/2),y-floori(float(height)/2))
			var v: float = float(block_temp-WorldGen.MIN_TEMP)/float(WorldGen.MAX_TEMP-WorldGen.MIN_TEMP)
			
			image.set_pixel(x+width, y, Color(v, 0.0, 0.0))
			
func _generate_humd_map():
	for x in width:
		for y in height:
			var block_temp : int = WorldGen.get_biome_humdity_map(x-floori(float(width)/2),y-floori(float(height)/2))
			var v: float = floor(block_temp)/100.0
			
			image.set_pixel(x+width+width, y, Color(0.0, v, v))
