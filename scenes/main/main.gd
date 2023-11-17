extends Node3D

var world_size: int = 5

func _ready():
	var dim_count = world_size*2 + 1
	var total = dim_count*dim_count*dim_count
	var i = 0
	$CameraTarget/Camera3D.look_at($CameraTarget.position)
	for x in range(-world_size,world_size+1):
		for y in range(-world_size,world_size+1):
			for z in range(-world_size,world_size+1):
				#var start: int = Time.get_ticks_usec()
				add_child(Chunk.new(16, Vector3i(x,y,z)))
				#var end: int = Time.get_ticks_usec()
				#print(float(end-start)/1000.0,"ms")
				i += 1
				
		print(i,"/",total)


func _process(delta):
	$CameraTarget.rotation.y += delta*0.5

func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp = get_viewport()
		if (vp.debug_draw == Viewport.DEBUG_DRAW_WIREFRAME):
			vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED
		else:
			vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME

