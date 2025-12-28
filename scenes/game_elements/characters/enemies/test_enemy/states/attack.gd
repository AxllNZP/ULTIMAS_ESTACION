extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/enemies/test_enemy/states/StateNames.tres")

var enemy: Enemy

enum target_states {
	IDLE,
	FOLLOW,
	RANGED_ATTACK,
	ATTACK
}

var actual_target_state = target_states.ATTACK

@onready var attack_area : Area2D = $"../../AttackArea"
@onready var follow_area : Area2D = $"../../FollowArea"
@onready var ranged_attack_area : Area2D = $"../../DistanceAttackArea"

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	attack_area.area_exited.connect(_on_attack_area_exited)
	attack_area.area_entered.connect(_on_attack_area_entered)
	follow_area.area_exited.connect(_on_follow_area_exited)
	follow_area.area_entered.connect(_on_follow_area_entered)
	ranged_attack_area.area_exited.connect(_on_ranged_attack_area_exited)
	ranged_attack_area.area_entered.connect(_on_ranged_attack_area_entered)
	
	enemy.animation_player.animation_finished.connect(_on_animation_player_finished)

func enter(_previous_state_path: String) -> void:
	start_attack()

func physics_update(_delta: float) -> void:
	pass

func start_attack() -> void:
	enemy.last_direction = (enemy.target_player.global_position - enemy.global_position).normalized()
	enemy.damage_pivot.set_direction(enemy.last_direction)
	enemy.play_animation("attack",enemy.last_direction)

func _on_attack_area_exited(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.ATTACK:
		actual_target_state = target_states.FOLLOW

func _on_attack_area_entered(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.ATTACK:
		actual_target_state = target_states.ATTACK

func _on_follow_area_exited(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.ATTACK:
		actual_target_state = target_states.RANGED_ATTACK
 
func _on_follow_area_entered(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.ATTACK:
		actual_target_state = target_states.FOLLOW

func _on_ranged_attack_area_exited(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.ATTACK:
		actual_target_state = target_states.IDLE

func _on_ranged_attack_area_entered(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.ATTACK:
		actual_target_state = target_states.RANGED_ATTACK

func _on_animation_player_finished(anim_name: StringName) -> void:
	if anim_name.contains("attack"):
		match actual_target_state:
			target_states.IDLE:
				finished.emit(STATE_NAMES.IDLE)
			target_states.FOLLOW:
				finished.emit(STATE_NAMES.FOLLOW)
			target_states.RANGED_ATTACK:
				finished.emit(STATE_NAMES.RANGED_ATTACK)
			target_states.ATTACK:
				start_attack()
