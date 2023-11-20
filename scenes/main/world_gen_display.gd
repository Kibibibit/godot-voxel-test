extends TextureRect
class_name WorldDisplay



var width: int
var height: int

func _ready() -> void:
	width = floori(size.x)
	height = floori(size.y)


func generate(chunk_size:int) -> void:
	var height_map: Image = WorldGen.get_island_height_map(chunk_size, Vector2(width,height)/2, Vector2(width, height))
	
	texture = ImageTexture.create_from_image(height_map)
