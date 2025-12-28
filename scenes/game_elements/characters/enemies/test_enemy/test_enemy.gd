class_name  Enemy
extends CharacterBody2D

@export var life : float = 200.0
@export var speed: float = 80.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var state_machine: StateMachine = $StateMachine
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var damage_pivot: Node2D = $DamagePivot

# Variable para rastrear la última dirección
var last_direction: Vector2 = Vector2.DOWN

var target_player: Player = null

# Función para obtener el sufijo de dirección basado en el vector
func get_direction_suffix(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return ""
	
	# Normalizar el vector para determinar la dirección principal
	var angle = direction.angle()
	
	# 8 direcciones de 45° cada una
	# Centrar los sectores sumando PI/8 y luego dividir por PI/4
	var sector := int(floor((angle + PI / 8.0) / (PI / 4.0))) & 7
	
	match sector:
		0:
			sprite_2d.flip_h = true
			return "_left"
		1:
			sprite_2d.flip_h = true
			return "_down_left"
		2:
			sprite_2d.flip_h = false
			return "_down"
		3:
			sprite_2d.flip_h = false
			return "_down_left"
		4:
			sprite_2d.flip_h = false
			return "_left"
		5:
			sprite_2d.flip_h = false
			return "_up_left"
		6:
			sprite_2d.flip_h = false
			return "_up"
		7:
			sprite_2d.flip_h = true
			return "_up_left"
	return ""

# Función para reproducir animación con dirección
func play_animation(animation_name: String, direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		last_direction = direction
	
	var direction_suffix = get_direction_suffix(last_direction)
	var full_animation_name = animation_name + direction_suffix
	
	if animation_player.has_animation(full_animation_name):
		animation_player.play(full_animation_name)
	else:
		push_warning("Animación no encontrada: " + full_animation_name)
