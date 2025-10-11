extends Area3D

@onready var interactable: Area3D = $Interactable
@onready var player: CharacterBody3D = %Player

var main_spawn := Vector3(0, -0.5, 0)

func _ready() -> void:
	interactable.interact = _on_interact

func _on_interact():
	%Player.global_position = main_spawn
