extends CharacterBody3D

#CONSTS
var G = 9.8

#WRITABLE CONSTS
@export var jump_height:float = 10.0

@export var drag_slide:float = 1.0
@export var rotational_drag_slide:float = 2.0
@export var drag_fall:float = 1.0
@export var rotational_drag_fall:float = 2.0

@export var max_speed:float = 4.0
@export var acceleration:float = 10
@onready var ground_drag_coeff = acceleration / pow(max_speed,2)
@onready var air_drag_coeff = 1 / pow(max_speed,2)
var aileron_efficancy = 1.0


#CHILDREN
@onready var camera = $Camera
@onready var physics_animator = $PhysicsAnimator
@onready var headbang_node = $HeadbangNode
@onready var hitbox = $Hibox
@onready var board = $Board 

#PLAYER INPUTS
var strafe_input:Vector3
var crouch_input:bool

#PROPERTIES
var yaw:float = 0.0
var delta_yaw: = 0.0
var pitch:float = 0.0
var friction:float = 1.0
var traction:float = 1.0


class movement_state_class:
	var walk = false
	var fall = true
	var crouch = false
	var slide = false
@onready var movement_state  = movement_state_class.new()


#init object values
func _ready():
	
	#set yaw/pitch to their inital values
	yaw = transform.basis.get_euler().y
	pitch = transform.basis.get_euler().x
	
	#prevent self-collision
	headbang_node.add_exception(self)
	pass

# update phsysics
func _physics_process(delta):
	
	#save move state from last tick
	var previous_movement_state = movement_state
	
	# DETERMINE CURRENT MOVEMENT STATE:
	
	# FALL
	# true when the player is NOT on the ground
	movement_state.fall = not is_on_floor()
	
	# CROUCH
	# true when the player wants to coruch or there's no room to stand
	movement_state.crouch = crouch_input or headbang_node.is_colliding()
	
	# SLIDE
	# player is crouching and on the floor,
	if(movement_state.crouch and is_on_floor()):
		# and the floor is sloped enough, player will slide
		if(get_floor_angle() > 0.1):
				movement_state.slide = true
		# if they were previously sliding or falling,
		elif(previous_movement_state.slide or previous_movement_state.fall):
			# and they have enough velocity, then player will slide also
			if(velocity.length() > 0.1):
				movement_state.slide = true
		else:
			movement_state.slide = false
	else:
		movement_state.slide = false
	
	# WALK
	# true when player is on ground and not sliding
	movement_state.walk = is_on_floor() and not movement_state.slide
	
	# ROTATE PLAYER

	#rotate player (only right/left)
	self.transform.basis = Basis.IDENTITY
	self.rotate_object_local(Vector3(0.0,1.0,0.0),yaw)
	
	#rotate camera (only up/down, but it will inherit player's left/right rotation)
	camera.transform.basis = Basis.IDENTITY
	camera.rotate_object_local(Vector3(1.0,0.0,0.0),pitch)
	
	# GET WISH VELOCITY (direction player wants to move in)
	
	# normalize input if it's too long
	if abs(strafe_input.x) + abs(strafe_input.y) > 1.0: 
		strafe_input = strafe_input.normalized()
	
	# use right/forward direction of the player to transform input relative to player
	var wish_direction = (basis.x * strafe_input.x + basis.z * strafe_input.z)
	
	# CALULATE VELOCITY
	
	# if player is falling, 
	if(movement_state.fall):
		# apply gravity
		velocity.y -= G * delta

		# isolate xz velocity
		var velocity_xz = velocity
		velocity_xz.y = 0.0
		
		# if no WASD keys are being pressed, we assume the player wants to accelerate 
		# in the oppisite direction of the current velocity to halt their movement
		if(wish_direction.length() == 0):
			wish_direction = -1 * velocity_xz.normalized()
	
		# we use a drag force with direction to manage maximum speed instead of a scalar 
		# so that the player's acceleration is only reduced in the oppisite direction of their 
		# velocity. This means moves perpendicular to the current velocity are more responsive
		var drag_force = velocity_xz * velocity_xz.length() * air_drag_coeff
		
		# we're pretending that the player is like a glider, where any of their acceleration
		# in the air is generated though friction with the air
		var aileron_force = velocity_xz * velocity_xz.length() * aileron_efficancy * -basis.z
		
		
		# add acceleration to velocity
		velocity += delta * (aileron_force -  drag_force)
		
	
	# if player is walking,
	if(movement_state.walk):
		
		# isolate xz velocity
		var velocity_xz = velocity
		velocity_xz.y = 0.0
		
		# if no WASD keys are being pressed, we assume the player wants to accelerate 
		# in the oppisite direction of the current velocity to halt their movement
		if(wish_direction.length() == 0):
			wish_direction = -1 * velocity_xz.normalized()
		
		# combine player's desired movement with current acceleration
		var leg_force = wish_direction * acceleration
		
		# we use a drag force with direction to manage maximum speed instead of a scalar 
		# so that the player's acceleration is only reduced in the oppisite direction of their 
		# velocity. This means moves perpendicular to the current velocity are more responsive
		var drag_force = velocity_xz * velocity_xz.length() * ground_drag_coeff
		
		# add acceleration to velocity
		velocity += delta * (leg_force -  drag_force) 
	
	if(movement_state.slide):
		# isolate xz velocity
		var velocity_xz = velocity
		velocity_xz.y = 0.0
		
		# get the (x/z)force from gravity due to the slope player is on
		var slope_dir = get_floor_normal()
		slope_dir.y = 0.0
		var slope_force = slope_dir * G 
		
		# get froce due to drag
		var drag_force = velocity_xz * velocity_xz.length() * ground_drag_coeff
		
		var board_force = board.basis.z * max(0.0,board.basis.z.dot(slope_force))
		board_force += board.basis.z * max(0.0,board.basis.z.dot(drag_force))
		
		# add acceleration to velocity
		velocity += delta * (board_force -  drag_force) 
	
	# move and slide is a built in function that makes the player move along slopes easier
	move_and_slide()
	pass

#turn player/camera with mouse movement
func turn_view(input_x:float, input_y:float):
	
	delta_yaw = (-1.0) * input_x
	yaw += delta_yaw
	#keep yaw within 0 -> PI range
	if yaw > 2*PI:
		yaw -= 2*PI
	if yaw < 0:
		yaw += 2*PI
	
	pitch += (-1.0) * input_y
	#stop the player from looking too far up
	pitch = clamp(pitch, -PI/2,PI/2)
	
	pass

# add velocity on jump when the player is on the ground
func jump():
	if is_on_floor():
		velocity.y = jump_height
	pass

# crouch when the player presses crouch
func crouch(prone:bool):
	
	crouch_input = prone
	
	#prone/unprone are when the player presses/releaces the crouch button.
	if prone:
		physics_animator.play("crouch", -1.0, 1.0, false)
	else:
		physics_animator.play("crouch", -1.0, -1.0, true)
	pass
