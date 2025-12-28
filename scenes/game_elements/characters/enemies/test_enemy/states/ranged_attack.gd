extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/enemies/test_enemy/states/StateNames.tres")

var enemy: Enemy

@onready var distante_attack_area : Area2D = $"../../DistanceAttackArea"
@onready var follow_area : Area2D = $"../../FollowArea"
@onready var ranged_attack_cd : Timer = $RangedAttackCd

@export var projectile_scene : PackedScene

func _ready() -> void:
	await owner.ready
	enemy = owner as Enemy
	ranged_attack_cd.timeout.connect(_on_ranged_attack_cd_timeout)
	distante_attack_area.area_exited.connect(_on_distance_attack_area_exited)
	follow_area.area_entered.connect(_on_follow_area_entered)

func enter(_previous_state_path: String) -> void:
	enemy.velocity = Vector2.ZERO
	if ranged_attack_cd.is_stopped():
		spawn_projectile()
		ranged_attack_cd.start()

func physics_update(_delta: float) -> void:
	enemy.last_direction = (enemy.target_player.global_position - enemy.global_position).normalized()
	
	enemy.play_animation("idle", enemy.last_direction)

func exit() -> void:
	pass

func _on_ranged_attack_cd_timeout() -> void:
	if enemy.state_machine.state.name == STATE_NAMES.RANGED_ATTACK:
		spawn_projectile()
	ranged_attack_cd.start()

func spawn_projectile() -> void:
	var projectile_intantiate = projectile_scene.instantiate()
	
	enemy.get_tree().root.call_deferred("add_child",projectile_intantiate)
	projectile_intantiate.global_position = enemy.target_player.global_position

func _on_distance_attack_area_exited(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.RANGED_ATTACK:
		finished.emit(STATE_NAMES.IDLE)

func _on_follow_area_entered(area: Area2D) -> void:
	if enemy.state_machine.state.name == STATE_NAMES.RANGED_ATTACK:
		finished.emit(STATE_NAMES.FOLLOW)
