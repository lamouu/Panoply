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
var swing_rotations : Dictionary
var windup_basis : Dictionary
var pullback_basis : Dictionary
var windup_timer := 0.0
var swing_timer := 0.0
var pullback_timer := 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
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

	if sword_state == SwordState.SWING:
		y_sensitivity *= cons.TURN_CAP
		x_sensitivity *= cons.TURN_CAP

	y_rotation = -event.relative.x * x_sensitivity
	x_rotation = -event.relative.y * y_sensitivity

	rotate_y(y_rotation)
	$Camera3D.rotate_x(x_rotation)
	
	mouse_movement_angle = event.relative


func _start_idle():
	$AnimationPlayer.play("idle")


func _start_windup():
	sword_state = SwordState.WINDUP
	$AnimationPlayer.stop()
	
	swing_rotations = _calc_swing(mouse_movement_angle)
	windup_basis = _calc_windup(swing_rotations["start"])
	windup_timer = 0


func _start_swing():
	sword_state = SwordState.SWING

	swing_timer = 0


func _start_pullback():
	sword_state = SwordState.PULLBACK
	
	pullback_basis = _calc_pullback()
	pullback_timer = 0


func _slerp_windup(delta):
	windup_timer += delta
	var progress = clamp(windup_timer / cons.WINDUP_TIME, 0.0, 1.0)
	
	%WeaponPivot.basis = windup_basis["start"].slerp(windup_basis["end"], progress)
	
	if progress >= 1.0:
		windup_timer = 0
		_start_swing()


func _slerp_swing(delta):
	swing_timer += delta
	var progress = clamp(swing_timer / cons.SWING_TIME, 0.0, 1.0)
	var swing_angle = cons.SWING_END_ROTATIION - cons.SWING_START_ROTATIION
	var current_rotation = swing_angle * progress * swing_curve.sample(progress)
	# hey dumbass, progress' scaling means that swing_curve.sample(progress) has very little weight at the start
	
	%WeaponPivot.quaternion = (
			swing_rotations["start"].slerp(swing_rotations["end"],
			min(1.0, current_rotation / swing_rotations["start"].angle_to(swing_rotations["end"]))))
	
	if progress >= 1.0:
		swing_timer = 0
		_start_pullback()


func _slerp_pullback(delta):
	pullback_timer += delta
	var progress = clamp(pullback_timer / cons.PULLBACK_TIME, 0.0, 1.0)
	
	%WeaponPivot.basis = pullback_basis["start"].slerp(pullback_basis["end"], progress)

	if progress >= 1.0:
		pullback_timer = 0
		sword_state = SwordState.IDLE


func _calc_windup(start_quat):
	var windup_start: Basis = %WeaponPivot.basis
	
	var windup_end := Basis(start_quat)

	return {"start": windup_start, "end": windup_end}


func _calc_swing(screen_angle):
	var swing_direction = Quaternion(Vector3.FORWARD, screen_angle.angle() - PI/2)
	swing_direction = swing_direction.normalized()
	
	var swing_start = swing_direction*Quaternion(Vector3.MODEL_RIGHT, cons.SWING_START_ROTATIION)
	swing_start = swing_start.normalized()
	
	var swing_end = swing_direction*Quaternion(Vector3.MODEL_RIGHT, cons.SWING_END_ROTATIION)
	swing_end = swing_end.normalized()
	
	return {"start": swing_start, "end": swing_end}


func _calc_pullback():
	var pullback_start = %WeaponPivot.basis
	
	# kinda fucking scuffed
	var idle_animation = animation_library.get_animation("idle")
	var pullback_pos := Basis(idle_animation.track_get_key_value(0, 0), 0.0)
	var pullback_rot: Vector3 = idle_animation.track_get_key_value(1, 0)
	var pullback_end = pullback_pos.from_euler(pullback_rot)
	
	return {"start": pullback_start, "end": pullback_end}
