extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/enemies/test_enemy/states/StateNames.tres")

var enemy: Enemy

@onready var follow_area : Area2D = $"../../FollowArea"
@onready var attack_area : Area2D = $"../../AttackArea"

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	follow_area.area_exited.connect(_on_follow_area_exited)
	attack_area.area_entered.connect(_on_attack_area_entered)

func enter(_previous_state_path: String) -> void:
	pass

func physics_update(_delta: float) -> void:
	if enemy.target_player:
		enemy.velocity = enemy.speed * enemy.last_direction.normalized()
		enemy.last_direction = (enemy.target_player.global_position - enemy.global_position).normalized()
		enemy.play_animation("walk",enemy.last_direction)
	
	enemy.move_and_slide()

func _on_follow_area_exited(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.FOLLOW:
		finished.emit(STATE_NAMES.RANGED_ATTACK)

func _on_attack_area_entered(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.FOLLOW:
		finished.emit(STATE_NAMES.ATTACK)
