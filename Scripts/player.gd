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

@export var swing_curve: Curve

# movement variables
var player_speed : float
var headbob_t := 0.0

# sword variables
var sword_state := SwordState.IDLE
var	mouse_movement_angle : Vector2
var swingRotations : Dictionary
var windupRotations : Dictionary
var windup_timer := 0.0
var swing_timer := 0.0

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
			_start_windup()
		SwordState.SWING:
			_slerp_swing(delta)
		SwordState.PULLBACK:
			pass
		SwordState.STAB:
			pass
		SwordState.PARRY:
			pass
		SwordState.FLOURISH:
			pass


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_move_camera(event)

	if event is InputEventMouseButton and event.is_pressed() and mouse_movement_angle != null and event.button_index == MOUSE_BUTTON_LEFT:
		_start_swing()


func _headbob(time):
	var pos = Vector3.ZERO
	pos.y = sin(time * cons.BOB_FREQUENCY) * cons.BOB_AMPLITUDE
	pos.x = cos(time * cons.BOB_FREQUENCY / 2) * cons.BOB_AMPLITUDE / 2
	return pos


func _move_camera(event):
	var yRotation
	var ySens
	var xRotation
	var xSens
	
	if sword_state == SwordState.SWING:
		ySens = cons.ySensitivity * cons.TURN_CAP
		xSens = cons.xSensitivity * cons.TURN_CAP
	else:
		ySens = cons.ySensitivity
		xSens = cons.xSensitivity
	
	yRotation = -event.relative.x * xSens
	xRotation = -event.relative.y * ySens

	rotate_y(yRotation)
	$Camera3D.rotate_x(xRotation)
	
	mouse_movement_angle = event.relative

func _start_idle():
	$AnimationPlayer.play("idle")

func _start_windup():
	sword_state = SwordState.WINDUP
	$AnimationPlayer.stop()
	
	swingRotations = calc_swing(mouse_movement_angle)
	windupRotations = calc_windup(swingRotations["start"])
	windup_timer = 0

func _start_swing():
	sword_state = SwordState.SWING
	$AnimationPlayer.stop()
	
	swingRotations = calc_swing(mouse_movement_angle) # remove when windup is working
	swing_timer = 0


func _slerp_swing(delta):
	swing_timer += delta
	var progress = clamp(swing_timer / cons.SWING_TIME, 0.0, 1.0)
	var swing_angle = cons.SWING_END_ROTATIION - cons.SWING_START_ROTATIION
	var current_rotation = swing_angle * progress * swing_curve.sample(progress)
	# hey dumbass, progress' scaling means that swing_curve.sample(progress) has very little weight at the start
	
	%WeaponPivot.quaternion = (
			swingRotations["start"].slerp(swingRotations["end"],
			min(1.0, current_rotation / swingRotations["start"].angle_to(swingRotations["end"]))))
	
	if progress >= 1.0:
		swing_timer = 0
		sword_state = SwordState.IDLE


func calc_swing(screenAngle):
	var swingDirection = Quaternion(Vector3.FORWARD, screenAngle.angle() - PI/2)
	swingDirection = swingDirection.normalized()
	
	var swingStart = swingDirection*Quaternion(Vector3.MODEL_RIGHT, cons.SWING_START_ROTATIION)
	swingStart = swingStart.normalized()
	
	var swingEnd = swingDirection*Quaternion(Vector3.MODEL_RIGHT, cons.SWING_END_ROTATIION)
	swingEnd = swingEnd.normalized()
	
	return {"start": swingStart, "end": swingEnd}


func calc_windup(startQuaternion):
	pass
	#return {"start": windup_start, "end": windup_end}
