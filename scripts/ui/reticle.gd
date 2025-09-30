extends CenterContainer

@export var DOT_RADIUS: float = 1.5
@export var DOT_COLOUR: Color = Color.WHITE
@onready var animation_player = $"../../Player/AnimationTree"

var mouse_movement_array : Array
var mouse_angle

func _ready() -> void:
	queue_redraw()
	
	mouse_movement_array.resize(cons.ANGLE_BUFFER)
	mouse_movement_array.fill(Vector2.ZERO)

	animation_player.connect("animation_started", _change_transparency)


func _input(event):
	if event is InputEventMouseMotion and event.relative != null:
		mouse_movement_array.push_front(event.screen_relative)
		mouse_movement_array.resize(cons.ANGLE_BUFFER)
		
		var sum := Vector2.ZERO
		for i in cons.ANGLE_BUFFER:
			sum += mouse_movement_array[i]
		
		mouse_angle = sum
		
		$DirectionIndicator.set_rotation(mouse_angle.angle() + PI/2)
	
	if event is InputEventMouseButton and event.is_pressed() and mouse_angle != null and mouse_angle.angle() != null and event.button_index == MOUSE_BUTTON_LEFT:
		$ComboIndicatorL.set_rotation(mouse_angle.angle() + PI/2 - deg_to_rad(120))
		$ComboIndicatorR.set_rotation(mouse_angle.angle() + PI/2 + deg_to_rad(120))
		
		$ComboIndicatorL.default_color = Color(1.0, 1.0, 1.0, 0.0)
		$ComboIndicatorR.default_color = Color(1.0, 1.0, 1.0, 0.0)

		
func _change_transparency(animation):
	$ComboIndicatorL.default_color = Color(1.0, 1.0, 1.0, 0.0)
	$ComboIndicatorR.default_color = Color(1.0, 1.0, 1.0, 0.0)
	match animation:
		"windup":
			$ComboIndicatorL.default_color = Color(1.0, 1.0, 1.0, 0.5)
			$ComboIndicatorR.default_color = Color(1.0, 1.0, 1.0, 0.5)
		"combo":
			$ComboIndicatorL.default_color = Color(1.0, 1.0, 1.0, 0.5)
			$ComboIndicatorR.default_color = Color(1.0, 1.0, 1.0, 0.5)
		"swinger":
			$ComboIndicatorL.default_color = Color(1.0, 1.0, 1.0, 0.5)
			$ComboIndicatorR.default_color = Color(1.0, 1.0, 1.0, 0.5)

func _draw():
	draw_circle(Vector2(0,0), DOT_RADIUS, DOT_COLOUR)
