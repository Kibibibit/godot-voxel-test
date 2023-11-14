extends Node3D




func _ready():
	$Camera3D.look_at($CameraTarget.position)
	
	do_mesh()
	

func do_mesh():
	
	var start: int = Time.get_ticks_usec()
	
	
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = Time.get_ticks_usec()
	noise.fractal_octaves = 1
	noise.frequency = 0.1
	
	
	var output: Array[Array] = []
	
	for y in VoxelMeshInstance.CHUNK_SIZE:
		var slice_y: Array[Array] = []
		for z in VoxelMeshInstance.CHUNK_SIZE:
			var slice_z: Array[int] = []
			for x in VoxelMeshInstance.CHUNK_SIZE:
				var cell = 1 if noise.get_noise_3d(x,y,z) > 0.0 else 0
				slice_z.append(cell)
			slice_y.append(slice_z)
		output.append(slice_y)
		
	
	var end: int = Time.get_ticks_usec()
	
	print("Generate Time: ", float(end-start)/1000, "ms")
	
	$VoxelMeshInstance.data = output
	start = Time.get_ticks_usec()
	$VoxelMeshInstance.greedy()
	end = Time.get_ticks_usec()
	
	print("Mesh Time: ", float(end-start)/1000, "ms")


func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_P):
		var vp = get_viewport()
		if (vp.debug_draw == Viewport.DEBUG_DRAW_WIREFRAME):
			vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED
		else:
			vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
	if event is InputEventKey and Input.is_key_pressed(KEY_SPACE):
		do_mesh()
