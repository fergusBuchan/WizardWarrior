extends Node

#child object
@export var character_node:Node
@export var physics_node:CharacterBody3D

#controller settings
@export var sensitivity = 0.01

func _init():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pass

func _process(delta: float):
	
	pass

# input events
func _input(event: InputEvent) -> void:
	
	# strafe movement
	
	# pressing the button adds movement
	if event.is_action_pressed("move_forward"):
		physics_node.strafe_input.z -= 1.0
	# releacing the button adds the opposite movement
	if event.is_action_released("move_forward"):
		physics_node.strafe_input.z += 1.0
	
	if event.is_action_pressed("move_backward"):
		physics_node.strafe_input.z += 1.0
	if event.is_action_released("move_backward"):
		physics_node.strafe_input.z -= 1.0
	
	if event.is_action_pressed("move_right"):
		physics_node.strafe_input.x += 1.0
	if event.is_action_released("move_right"):
		physics_node.strafe_input.x -= 1.0
	
	if event.is_action_pressed("move_left"):
		physics_node.strafe_input.x -= 1.0
	if event.is_action_released("move_left"):
		physics_node.strafe_input.x += 1.0
	
	# rotate camera/player
	if event is InputEventMouseMotion:
		physics_node.turn_view(event.relative.x * sensitivity,event.relative.y * sensitivity)
	
	#fire
	if event is InputEventMouseButton and event.pressed:
		character_node.fire()
	
	#jump
	if event.is_action_pressed("jump"):
		physics_node.jump()
	
	#crouch
	if event.is_action_pressed("prone"):
		physics_node.crouch(true)
	if event.is_action_released("prone"):
		physics_node.crouch(false)
		
	pass
