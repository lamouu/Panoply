extends CenterContainer

@export var DOT_RADIUS: float = 1.5
@export var DOT_COLOUR: Color = Color.WHITE

func _ready() -> void:
	queue_redraw()

func _input(event):
	if event is InputEventMouseMotion and event.relative != null:
		$DirectionIndicator.set_rotation(event.relative.angle() + PI/2)

func _draw():
	draw_circle(Vector2(0,0), DOT_RADIUS, DOT_COLOUR)
