extends Interactable

var ore : Ore

func _ready() -> void:
	await owner.ready
	ore = owner 

func interact(user : Node2D) -> void:
	ore.on_hit()

func destroy():
	ore.destroy()

func show_button():
	ore.show_button()

func hide_button():
	ore.hide_button()

func stop_interaction(user : Node2D) -> void:
	pass
