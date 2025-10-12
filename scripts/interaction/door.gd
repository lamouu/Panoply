extends Area3D

@onready var interactable: Area3D = $Interactable

var main_spawn := Vector3(0, -0.5, 0)
var spawn_rotation := Vector3(0, 0, 0)

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact():
	%Player.global_position = main_spawn
	%Player.global_rotation = spawn_rotation
