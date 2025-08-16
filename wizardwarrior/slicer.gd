extends Node3D

@onready var slicemesh = $mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	slice(null)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func slice(mesh: MeshInstance3D):
	
	var kelly := RenderingServer
	var john := RenderingServer.get_rendering_device()
	print("buffer data:")
	var mesh_rid = slicemesh.get_base()
	var data = john.vertex_array_create(32,1,[mesh_rid]) 
	print(data)
	
	#var data = john.buffer_get_data(RenderingServer.multimesh_get_buffer_rd_rid(slicemesh.get_multimesh().get_rid())) 
	print("end")
	
	
	pass
