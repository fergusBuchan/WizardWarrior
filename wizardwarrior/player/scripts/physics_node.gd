extends CharacterBody3D

var G = 9.8
var move_speed:float
@export var move_speed_coruch:float = 0.5
@export var move_speed_standing:float = 1.0
@export var camera:Camera3D
@export var physics_animator:AnimationPlayer
@export var headbang_node:ShapeCast3D

var yaw:float = 0.0
var pitch:float = 0.0

var strafe_input:Vector3
var crouching:bool

enum ms { FALL, SLIDE, WALK }
var movement_state:ms = ms.WALK

#init object values
func _ready():
	
	# set inital move speed
	move_speed = move_speed_standing

	#set yaw/pitch to their inital values
	yaw = transform.basis.get_euler().y
	pitch = transform.basis.get_euler().x
	
	#prevent self-collision
	headbang_node.add_exception(self)
	pass

# update phsysics
func _physics_process(delta):
	
	
	# DETERMINE CURRENT MOVEMENT STATE:
	
	# FALL
	# if the player is on the ground
	if not is_on_floor():
		movement_state = ms.FALL
	# SLIDE
	# if the player is crouching,
	# AND 
	# player is moving fast enough OR player is already sliding AND on a slope
	elif(crouching and (
			(velocity.length() > 1.0) or ( (movement_state == ms.SLIDE) and (get_floor_angle() > 0.1) ) 
			)
		):
		movement_state = ms.SLIDE
	# WALK
	# when it's not anything else
	else:
		movement_state = ms.WALK
	
	
	# ACCELERATE PLAYER ACCORDING TO MOVE STATE:
	
	match movement_state:
		ms.FALL:
			# apply gravity
			velocity.y -= G
			
		ms.SLIDE:
			# slope direction is the surface normal with no y component
			var slope_direction = get_floor_normal() 
			slope_direction.y = 0.0
			
			# change velocity to be equal to the slope direction over time
			velocity += (slope_direction - velocity) * delta
			
		ms.WALK:
			
			# velocity is equal to the players WASD input
			velocity = Vector3(0.0,0.0,0.0)
			velocity += strafe_input.normalized().x * basis.x * move_speed
			velocity += strafe_input.normalized().z * basis.z * move_speed
	
	# MANAGE CROUCH
	
	if(crouching):
		move_speed = move_speed_coruch
	else:
		move_speed = move_speed_standing
	
	# if the player is trying to un-crouch,
	if ( (physics_animator.current_animation == "crouch") and (physics_animator.get_playing_speed() <= 0.0) ):
		
		# and there is nothing above them,
		if not headbang_node.is_colliding():
			# move up (play the animation).
			physics_animator.speed_scale = 1.0
		
		# otherwise,
		else:
			# stop moving up (stop the animation).
			physics_animator.speed_scale = 0.0
	
	# move and slide is a built in function that makes the player move along slopes easier
	move_and_slide()
	pass

#turn player/camera with mouse movement
func turn_view(input_x:float, input_y:float):
	
	yaw += (-1.0) * input_x
	#keep yaw within 0 -> PI range
	if yaw > 2*PI:
		yaw -= 2*PI
	if yaw < 0:
		yaw += 2*PI
	
	pitch += (-1.0) * input_y
	#stop the player from looking too far up
	pitch = clamp(pitch, -PI/2,PI/2)
	
	#rotate player (only right/left)
	self.transform.basis = Basis.IDENTITY
	self.rotate_object_local(Vector3(0.0,1.0,0.0),yaw)
	
	#rotate camera (only up/down, but it will inherit player's left/right rotation)
	camera.transform.basis = Basis.IDENTITY
	camera.rotate_object_local(Vector3(1.0,0.0,0.0),pitch)
	
	pass

# add velocity on jump when the player is on the ground
func jump():
	if is_on_floor():
		velocity.y = 10.0
	pass

# crouch when the player presses crouch
func crouch(prone:bool):
	
	crouching = prone
	
	#prone/unprone are when the player presses/releaces the crouch button.
	if prone:
		physics_animator.play("crouch", -1.0, 1.0, false)
	else:
		physics_animator.play("crouch", -1.0, -1.0, true)
	pass
