extends Node3D


@onready var mi: MeshInstance3D = $MeshInstance3D

func _ready():
	$Camera3D.look_at($CameraTarget.position)
	
	
	do_fast_mesh()
	
	#do_mesh()

func do_fast_mesh():
	var start: int = Time.get_ticks_usec()
	
	var mesh := VoxelMesh.new()
	
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = Time.get_ticks_usec()
	noise.fractal_octaves = 1
	noise.frequency = 0.1
	
	var data := PackedByteArray()
	data.resize(16*16*16)
	
	for x in 16:
		for y in 16:
			for z in 16:
				var cell = 1 if noise.get_noise_3d(x,y,z) > 0.0 else 0
				data[16*16*y + 16*z + x] = cell
	
	mesh.remesh(16, data)
	
	var end: int = Time.get_ticks_usec()
	
	mi.mesh = mesh
	
	print("Fast Mesh Time: ", float(end-start)/1000, "ms")

func do_mesh():
	
	var start: int = Time.get_ticks_usec()
	
	
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = Time.get_ticks_usec()
	noise.fractal_octaves = 1
	noise.frequency = 0.1
	
	var mesh := VoxelMesh.new()
	
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
		do_fast_mesh()
