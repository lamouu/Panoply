extends CenterContainer

@export var DOT_RADIUS: float = 2.0
@export var DOT_COLOUR: Color = Color.WHITE
@onready var animation_player = $"../../Player/AnimationTree"

var mouse_movement_array : Array
var mouse_angle

func _ready() -> void:
	queue_redraw()
	
	mouse_movement_array.resize(cons.ANGLE_BUFFER)
	mouse_movement_array.fill(Vector2.ZERO)

	animation_player.connect("animation_started", _new_animation)

func _process(_delta: float) -> void:
	_fade_indicator()

func _input(event):
	if event is InputEventMouseMotion and event.relative != null:
		mouse_movement_array.push_front(event.screen_relative)
		mouse_movement_array.resize(cons.ANGLE_BUFFER)
		
		var sum := Vector2.ZERO
		for i in range(0, cons.ANGLE_BUFFER):
			sum += mouse_movement_array[i]
		
		mouse_angle = sum
		
		$DirectionIndicator.set_rotation(mouse_angle.angle() + PI/2)
	
	if event is InputEventMouseButton and event.is_pressed() and mouse_angle != null and mouse_angle.angle() != null and event.button_index == MOUSE_BUTTON_LEFT:
		$ComboIndicator.set_rotation(mouse_angle.angle() + 3 * PI / 2)
		$ComboFade.stop()

		
func _new_animation(animation):
	if animation == "swinger":
		$ComboIndicator.modulate = Color(1.0, 1.0, 1.0, 0.0)
		$ComboFade.start(1.5)

func _fade_indicator():
	var weight = $ComboFade.time_left / 3
	$ComboIndicator.modulate = Color(1.0, 1.0, 1.0, weight)

func _draw():
	draw_circle(Vector2(0,0), DOT_RADIUS, DOT_COLOUR)
