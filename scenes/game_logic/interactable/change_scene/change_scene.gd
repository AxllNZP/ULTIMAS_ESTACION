extends Interactable

@export_file("*.tscn")
var target_scene_path: String = ""

func interact(user: Node2D) -> void:
	if target_scene_path == "":
		return
	
	get_tree().change_scene_to_file.bind(target_scene_path).call_deferred()


func stop_interaction(user: Node2D) -> void:
	pass
