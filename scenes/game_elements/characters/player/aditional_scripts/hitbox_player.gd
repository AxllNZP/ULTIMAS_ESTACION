extends Area2D

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player

func get_player() -> Player:
	return player

func damage(damage :float) -> void:
	player.life -= damage
	print("Vida del jugador disminuida: ", player.life)

func heal(heal: float) -> void:
	player.life += heal
	print("Vida del jugador aumentada: ", player.life)
