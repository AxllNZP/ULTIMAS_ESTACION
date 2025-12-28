extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/player/states/StateNames.tres")

var player: Player

enum attack_states {
	ATTACK1,
	ATTACK2,
	ATTACK3
}
var actual_attack_state = attack_states.ATTACK1

enum act_states {
	NOTHING,
	ONLY_ATTACK,
	ALL
}

var capture_last_direction : Vector2 = Vector2.ZERO

@export var attack_duration: float = 0.4
@export var attack_damage: int = 10  # Daño que hace el jugador (reducido de 25 a 10)
@export var actual_act_state = act_states.NOTHING

@export_group("Attack Sequence")
@export var attack1_velocity: float = 100.0
@export var attack2_velocity: float = 100.0
@export var attack3_velocity: float = 100.0

func _ready() -> void:
	await owner.ready
	player = owner as Player
	player.animation_player.animation_finished.connect(_on_animation_player_finished)

func enter(_previous_state_path: String) -> void:
	player.play_animation("attack1",player.last_direction)
	capture_last_direction = player.last_direction
	actual_attack_state = attack_states.ATTACK1

func exit() -> void:
	player.reverse_flip_h = false

func physics_update(_delta: float) -> void:
	match(actual_attack_state):
		attack_states.ATTACK1:
			attack(attack1_velocity)
		attack_states.ATTACK2:
			attack(attack2_velocity)
		attack_states.ATTACK3:
			attack(attack3_velocity)
	
	if actual_act_state == act_states.ALL:
		act_all()
	
	player.move_and_slide()

func handle_input(_event: InputEvent) -> void:
	if actual_act_state == act_states.ONLY_ATTACK or actual_act_state == act_states.ALL:
		if Input.is_action_just_pressed("attack"):
			match actual_attack_state:
				attack_states.ATTACK1:
					actual_attack_state = attack_states.ATTACK2
					player.play_animation("attack2",player.last_direction)
					player.interact_pivot.set_direction(player.last_direction)
					capture_last_direction = player.last_direction
				attack_states.ATTACK2:
					actual_attack_state = attack_states.ATTACK3
					player.play_animation("attack3",player.last_direction)
					player.interact_pivot.set_direction(player.last_direction)
					capture_last_direction = player.last_direction
					player.reverse_flip_h = true
				attack_states.ATTACK3:
					actual_attack_state = attack_states.ATTACK1
					player.play_animation("attack1",player.last_direction)
					player.interact_pivot.set_direction(player.last_direction)
					capture_last_direction = player.last_direction
					player.reverse_flip_h = false
		elif Input.is_action_just_pressed("dash"):
			finished.emit(STATE_NAMES.DASH)

func attack(velocity: float)-> void:
	player.velocity = capture_last_direction.normalized() * velocity
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		player.last_direction = direction

func act_all() -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		finished.emit(STATE_NAMES.WALK)


func _on_animation_player_finished(anim_name : StringName) -> void:
	if anim_name.contains("attack"):
		finished.emit(STATE_NAMES.IDLE)
