extends Node3D

enum COMPONENT_TYPES {
	BLADES,
	GUARDS,
	HANDLES,
	POMMELS,
}

@export var outline_material: Resource

@export var state_machine: Node


func _ready() -> void:
	create_sword()


func _unhandled_input(event) -> void:
	if event is InputEventKey:
		if event.pressed and event.is_action("swap") and state_machine["parameters/playback"].get_current_node() == "idle":
			state_machine["parameters/playback"].travel("sheath")


func switch_sword() -> void:
	delete_sword()
	create_sword()

func create_sword() -> void:
	for component_type in COMPONENT_TYPES:
		var component = _pick_component(component_type)
		var component_resource = load(component)
		var component_instance = component_resource.instantiate()
		component_instance.get_child(0).material_overlay = outline_material
		add_child(component_instance)

func delete_sword() -> void:
	var child_components = get_children()
	
	for child in child_components:
		remove_child(child)

func _pick_component(type) -> String:
	var folder_name = _component_folder_name(type)
	var asset_path = "res://art/swords/" + folder_name
	var asset_array = Array(DirAccess.get_files_at(asset_path))
	var filtered_asset_array = asset_array.filter(is_glb)
	
	var chosen_asset = filtered_asset_array.pick_random()
	
	var chosen_path = asset_path + "/" + chosen_asset
	
	return chosen_path

func is_glb(entry) -> bool:
	return not ".import" in entry
	
	
func _component_folder_name(enum_type) -> String:
	var folder_name = enum_type.to_lower()
	
	return folder_name
