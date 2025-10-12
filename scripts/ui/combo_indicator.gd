extends Node2D

func _ready() -> void:
	queue_redraw()

func _draw():
	draw_arc(Vector2(0,0), 11.0, PI, 2 * PI, 30, Color(1, 1, 1, 1), 3, true)
