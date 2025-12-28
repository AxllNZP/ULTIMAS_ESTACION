extends State

const STATE_NAMES = preload("res://scenes/game_elements/characters/player/states/StateNames.tres")

var player: Player

enum sub_states {
	IN,
	ON,
	OUT
}
var actual_substate = sub_states.IN

@export var dash_speed: float = 800.0
@onready var dash_duration_timer: Timer = $DashDuration

func _ready() -> void:
	await owner.ready
	player = owner as Player
	dash_duration_timer.connect("timeout",_on_dash_duration_timeout)
	player.animation_player.animation_finished.connect(_on_animation_player_finished)

func enter(_previous_state_path: String) -> void:
	dash_duration_timer.start()
	player.play_animation("dash_in",player.last_direction)
	actual_substate = sub_states.IN

func physics_update(_delta: float) -> void:
	match(actual_substate):
		sub_states.IN:
			dash_in()
		sub_states.ON:
			dash_on()
		sub_states.OUT:
			dash_out()
	player.move_and_slide()

func exit() -> void:
	pass

func dash_in() -> void:
	player.velocity = Vector2.ZERO

func dash_on() -> void:
	player.velocity = player.last_direction.normalized() * dash_speed

func dash_out() -> void:
	player.velocity = Vector2.ZERO
	
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		finished.emit(STATE_NAMES.WALK)

func _on_dash_duration_timeout() -> void:
	player.play_animation("dash_out",player.last_direction)
	actual_substate = sub_states.OUT

func _on_animation_player_finished(anim_name : StringName) -> void:
	if anim_name.contains("dash_in"):
		player.play_animation("dash",player.last_direction)
		actual_substate = sub_states.ON
	elif anim_name.contains("dash_out"):
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		
		if direction != Vector2.ZERO:
			finished.emit(STATE_NAMES.WALK)
		else:
			finished.emit(STATE_NAMES.IDLE)
