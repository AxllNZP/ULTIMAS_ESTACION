extends Area2D

var enemy: Enemy

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy

func get_player() -> Enemy:
	return enemy

func damage(damage :float) -> void:
	enemy.life -= damage
	print("Vida del enemigo disminuida: ", enemy.life)
	if enemy.life < 0:
		enemy.queue_free()

func heal(heal: float) -> void:
	enemy.life += heal
	print("Vida del enemigo aumentada: ", enemy.life)
