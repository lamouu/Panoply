extends Path3D

const DEBUG = true
var tracerCurve

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tracerCurve = Curve3D.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if DEBUG:
		if $"../../../..".sword_state == 2:
			tracerCurve.add_point($"..".global_position)
			set_curve(tracerCurve)
		else:
			tracerCurve.clear_points()
