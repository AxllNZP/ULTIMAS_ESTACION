extends Node2D

@export var show_indicator = true: 
	set(value):
		if show_indicator == value:
			return
		if value == true:
			animation_player.play("fade")
			animation_player.queue("btn_anim")
		else:
			animation_player.play_backwards("fade")
		show_indicator = value
	get:
		return show_indicator

@export var animation_player : AnimationPlayer

func _ready() -> void:
	animation_player.play("fade")
	animation_player.queue("btn_anim")
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName):
	if anim_name == "fade" and show_indicator == false:
		queue_free()
