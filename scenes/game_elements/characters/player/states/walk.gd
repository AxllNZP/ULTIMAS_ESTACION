extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/player/states/StateNames.tres")

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player

func enter(_previous_state_path: String) -> void:
	pass

func physics_update(_delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		player.velocity = direction * player.speed
		# Reproduce la animación walk en la dirección actual
		player.play_animation("walk", direction)
	else:
		finished.emit(STATE_NAMES.IDLE)
	
	player.move_and_slide()
