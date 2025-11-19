extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/player/states/StateNames.tres")

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player

func enter(_previous_state_path: String) -> void:
	player.velocity = Vector2.ZERO
	# Reproduce la animación idle en la última dirección
	player.play_animation("idle", player.last_direction)

func physics_update(_delta: float) -> void:
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		finished.emit(STATE_NAMES.WALK)
	
	player.move_and_slide()
