extends Node2D

var point_array = PackedVector2Array([Vector2(6, 0), Vector2(-6, 0), Vector2(0, -15), Vector2(6, 0)])
var colour_array = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 1.0),Color(1.0, 1.0, 1.0, 1.0)])

func _ready() -> void:
	queue_redraw()

func _draw():
	draw_polyline(point_array, Color(1.0, 1.0, 1.0, 1.0), 1, true)
