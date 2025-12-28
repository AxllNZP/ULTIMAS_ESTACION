extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/enemies/test_enemy/states/StateNames.tres")

var enemy: Enemy

@onready var distante_attack_area : Area2D = $"../../DistanceAttackArea"

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	distante_attack_area.area_entered.connect(_on_distance_attack_area_entered)

func enter(_previous_state_path: String) -> void:
	enemy.velocity = Vector2.ZERO
	# Reproduce la animación idle en la última dirección
	enemy.play_animation("idle", enemy.last_direction)

func _on_distance_attack_area_entered(area: Area2D) -> void:
	enemy.target_player = area.get_player()
	if enemy.state_machine.state.name == STATE_NAMES.IDLE:
		finished.emit(STATE_NAMES.RANGED_ATTACK)
