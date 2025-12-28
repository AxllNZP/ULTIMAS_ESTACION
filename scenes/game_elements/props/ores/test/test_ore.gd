class_name Ore
extends StaticBody2D

@export var life : int = 3:
	set(value):
		life = value
		print(life)

@export var animation_player: AnimationPlayer

func destroy():
	queue_free()

func hit():
	pass

func on_hit():
	life -= 1
	if life > 0:
		hit()
	else:
		destroy()
