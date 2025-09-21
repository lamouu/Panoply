extends CenterContainer

@export var DOT_RADIUS: float = 1.5
@export var DOT_COLOUR: Color = Color.WHITE

var mouse_movement_array : Array

func _ready() -> void:
	queue_redraw()
	
	mouse_movement_array.resize(cons.ANGLE_BUFFER)
	mouse_movement_array.fill(Vector2.ZERO)

func _input(event):
	if event is InputEventMouseMotion and event.relative != null:
		var sum: Vector2
		
		mouse_movement_array.push_front(event.screen_relative)
		mouse_movement_array.resize(cons.ANGLE_BUFFER)
	
		for i in cons.ANGLE_BUFFER:
			sum += mouse_movement_array[i]
		

		$DirectionIndicator.set_rotation(sum.angle() + PI/2)

func _draw():
	draw_circle(Vector2(0,0), DOT_RADIUS, DOT_COLOUR)
