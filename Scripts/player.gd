extends CharacterBody3D

@onready var state_machine = $AnimationTree["parameters/playback"]

var player_speed : float
var headbob_t := 0.0
var	mouse_movement_angle : Vector2
var mouse_movement_array : Array
var last_swing_angle := 0.0
var comboing := false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	mouse_movement_array.resize(cons.ANGLE_BUFFER)
	mouse_movement_array.fill(Vector2.ZERO)


func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = cons.JUMP_VELOCITY
	
	if Input.is_action_pressed("shift"):
		player_speed = cons.RUN_SPEED
	elif Input.is_action_pressed("ctrl"):
		player_speed = cons.CROUCH_SPEED
		$CollisionShape3D.shape.height = cons.CROUCH_HEIGHT
	else:
		player_speed = cons.WALK_SPEED
		$CollisionShape3D.shape.height = cons.STANDING_HEIGHT
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * player_speed
			velocity.z = direction.z * player_speed
		else:
			velocity.x = lerp(velocity.x, direction.x * player_speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * player_speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * player_speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * player_speed, delta * 2.0)
	
	headbob_t += delta * velocity.length() * float(is_on_floor())
	$Camera3D.transform.origin = _headbob(headbob_t)
	
	var velocity_clamped = clamp(velocity.length(), 0.5, cons.RUN_SPEED * 2)
	var target_fov = cons.BASE_FOV + cons.FOV_CHANGE * velocity_clamped
	$Camera3D.fov = lerp($Camera3D.fov, target_fov, delta * 8.0)

	move_and_slide()


func _process(_delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_move_camera(event)
		mouse_movement_angle = _get_mouse_movement(event.screen_relative)

	if event is InputEventMouseButton and event.is_pressed() and mouse_movement_angle != null and event.button_index == MOUSE_BUTTON_LEFT:
		var current_swing_angle: float = - PI / 2 - mouse_movement_angle.angle()
		
		match state_machine.get_current_node():
			"idle":
				_set_swing_params()
				state_machine.travel("windup")
			"windup":
				pass
			"swinger":
				_set_swing_params()
				_combo(current_swing_angle)
			"combo":
				pass
			"winddown":
				pass
		
		last_swing_angle = - PI / 2 - mouse_movement_angle.angle()


func _combo(current_swing_angle):
	var combo_direction = last_swing_angle + PI
	var angle_to_combo_direction = angle_difference(combo_direction, current_swing_angle)

	if rad_to_deg(abs(angle_to_combo_direction)) < 40:
		state_machine.travel("combo")


func normalize_rotation(angle):
	if angle < -180.1:
		angle = angle + 360
	elif angle > 180.1:
		angle = angle - 360
	
	return angle


func _set_swing_params():
	var swingAngle = Vector3(0.0, 0.0, - PI/2 - mouse_movement_angle.angle())

	if swingAngle[2] >= deg_to_rad(-271) and swingAngle[2] <= deg_to_rad(-180):
		$AnimationPlayer.get_animation("windup").track_set_key_value(3, 1, swingAngle + Vector3(0,0,2 * PI))
		$AnimationPlayer.get_animation("winddown").track_set_key_value(4, 0, swingAngle + Vector3(0,0,2 * PI))
		$AnimationPlayer.get_animation("combo").track_set_key_value(4, 0, swingAngle + Vector3(0,0,2 * PI))
	else:
		$AnimationPlayer.get_animation("windup").track_set_key_value(3, 1, swingAngle)
		$AnimationPlayer.get_animation("winddown").track_set_key_value(4, 0, swingAngle)
		$AnimationPlayer.get_animation("combo").track_set_key_value(4, 0, swingAngle)


func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * cons.BOB_FREQUENCY) * cons.BOB_AMPLITUDE
	pos.x = cos(time * cons.BOB_FREQUENCY / 2) * cons.BOB_AMPLITUDE / 2
	return pos


func _move_camera(event):
	var y_rotation
	var y_sensitivity = cons.Y_SENS
	var x_rotation
	var x_sensitivity = cons.X_SENS

	y_rotation = -event.relative.x * x_sensitivity
	x_rotation = -event.relative.y * y_sensitivity

	if state_machine.get_current_node() == "swinger" or state_machine.get_current_node() == "winddown":
		y_rotation = clamp(y_rotation, - cons.TURN_CAP, cons.TURN_CAP)
		x_rotation = clamp(x_rotation, - cons.TURN_CAP, cons.TURN_CAP)
	else:
		y_rotation = -event.relative.x * x_sensitivity
		x_rotation = -event.relative.y * y_sensitivity
		
	rotate_y(y_rotation)
	$Camera3D.rotate_x(x_rotation)


func _get_mouse_movement(angle):
	var sum = Vector2.ZERO
	
	if angle != Vector2.ZERO:

		mouse_movement_array.push_front(angle)
		mouse_movement_array.resize(cons.ANGLE_BUFFER)
		
		
		for i in range(0, cons.ANGLE_BUFFER):
			sum += mouse_movement_array[i]
		
	return sum
