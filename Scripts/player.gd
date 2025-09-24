extends CharacterBody3D

enum SwordState {
	IDLE,
	WINDUP,
	SWING,
	PULLBACK,
	STAB,
	PARRY,
	FLOURISH,
}

# sword animation curves
@export var windup_curve: Curve
@export var swing_curve: Curve
@export var pullback_curve: Curve
@export var stab_curve: Curve

# movement variables
var player_speed : float
var headbob_t := 0.0

# animation variables
var animation_library : AnimationLibrary = load("res://art/animation_libs/idle_lib.tres")

# sword variables
var sword_state := SwordState.IDLE
var	mouse_movement_angle : Vector2
var mouse_movement_array : Array
var mordhau := false
var attack_transitions : Dictionary
var swing_timer := 0.0
var mouse_timer := 0.0

var raycast_array := [
	$Camera3D/WeaponPivot/TipCast,
	$Camera3D/WeaponPivot/MidCast,
	$Camera3D/WeaponPivot/BaseCast,
]

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


func _process(delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	
	mouse_movement_angle = _get_mouse_movement()
	
	match sword_state:
		SwordState.IDLE:
			_start_idle()
		SwordState.WINDUP:
			_slerp_windup(delta)
		SwordState.SWING:
			_slerp_swing(delta)
		SwordState.PULLBACK:
			_slerp_pullback(delta)
		SwordState.STAB:
			pass
		SwordState.PARRY:
			pass
		SwordState.FLOURISH:
			pass


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_move_camera(event)
		mouse_movement_angle = event.screen_relative

	if event is InputEventMouseButton and event.is_pressed() and mouse_movement_angle != null and event.button_index == MOUSE_BUTTON_LEFT and sword_state == SwordState.IDLE:
		_start_windup()


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
	
	if sword_state == SwordState.SWING or sword_state == SwordState.WINDUP:
		y_rotation = clamp(y_rotation, - cons.TURN_CAP, cons.TURN_CAP)
		x_rotation = clamp(x_rotation, - cons.TURN_CAP, cons.TURN_CAP)
	else:
		y_rotation = -event.relative.x * x_sensitivity
		x_rotation = -event.relative.y * y_sensitivity
		
	rotate_y(y_rotation)
	$Camera3D.rotate_x(x_rotation)


func _get_mouse_movement():
	var sum = Vector2.ZERO
	
	if mouse_movement_angle != Vector2.ZERO:

		mouse_movement_array.push_front(mouse_movement_angle)
		mouse_movement_array.resize(cons.ANGLE_BUFFER)
		
		for i in cons.ANGLE_BUFFER:
			sum += mouse_movement_array[i]
		
	return sum


func _start_idle():
	$AnimationPlayer.play("idle")


func _start_windup():
	sword_state = SwordState.WINDUP
	$AnimationPlayer.stop()
	
	attack_transitions = _calc_attack(mouse_movement_angle)
	swing_timer = 0


func _start_swing():
	sword_state = SwordState.SWING

	swing_timer = 0


func _start_pullback():
	sword_state = SwordState.PULLBACK
	
	swing_timer = 0


func _slerp_windup(delta):
	swing_timer += delta
	var progress = clamp(swing_timer / cons.WINDUP_TIME, 0.0, 1.0)
	
	%WeaponPivot.basis = attack_transitions["windup_start"].slerp(attack_transitions["swing_start"], progress)
	
	if progress >= 1.0:
		swing_timer = 0
		_start_swing()


func _slerp_swing(delta):
	swing_timer += delta
	var progress = clamp(swing_timer / cons.SWING_TIME, 0.0, 1.0)
	var swing_angle = cons.SWING_END_ROTATIION - cons.SWING_START_ROTATIION
	var current_rotation = swing_angle * progress * swing_curve.sample(progress)
	# hey dumbass, progress' scaling means that swing_curve.sample(progress) has very little weight at the start
	
	%WeaponPivot.quaternion = (
			attack_transitions["swing_start"].slerp(attack_transitions["pullback_start"],
			min(1.0, current_rotation / attack_transitions["swing_start"].
			get_rotation_quaternion().angle_to(attack_transitions["pullback_start"].get_rotation_quaternion())))
			)
	
	if progress >= 1.0:
		swing_timer = 0
		_start_pullback()


func _slerp_pullback(delta):
	swing_timer += delta
	var progress = clamp(swing_timer / cons.PULLBACK_TIME, 0.0, 1.0)
	
	%WeaponPivot.basis = attack_transitions["pullback_start"].slerp(attack_transitions["idle_start"], progress)

	if progress >= 1.0:
		swing_timer = 0
		sword_state = SwordState.IDLE


func _calc_attack(mouse_angle):
	var windup_start: Basis = %WeaponPivot.basis
	
	var swing_direction = Quaternion(Vector3.FORWARD, mouse_angle.angle() - PI/2)
	swing_direction = swing_direction.normalized()
	
	var swing_start = Basis(swing_direction*Quaternion(Vector3.MODEL_RIGHT, cons.SWING_START_ROTATIION))
	
	var pullback_start = Basis(swing_direction*Quaternion(Vector3.MODEL_RIGHT, cons.SWING_END_ROTATIION))
	
	var idle_start = _get_idle_start()
	
	return {"windup_start": windup_start, "swing_start": swing_start, "pullback_start": pullback_start, "idle_start": idle_start}


func _get_idle_start():
	var idle_animation = animation_library.get_animation("idle")
	var idle_pos := Basis(idle_animation.track_get_key_value(0, 0), 0.0)
	var idle_rot: Vector3 = idle_animation.track_get_key_value(1, 0)
	@warning_ignore("static_called_on_instance")
	var idle_end = idle_pos.from_euler(idle_rot)
	
	return idle_end
