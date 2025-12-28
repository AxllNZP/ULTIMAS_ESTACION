extends Sprite2D

@onready var player: Player = owner

func _process(_delta: float) -> void:
	if not player:
		return
	if not is_zero_approx(player.velocity.x):
		if player.reverse_flip_h:
			flip_h = player.velocity.x <= 0
		else:
			flip_h = player.velocity.x > 0
