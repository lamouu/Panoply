extends Node2D


func _ready() -> void:
	queue_redraw()

func _draw():
	draw_arc(Vector2(0,0), 12, 0, 2 * PI, 30, Color(1, 1, 1, 1), 16, true)
