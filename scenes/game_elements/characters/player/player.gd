class_name Player
extends CharacterBody2D

@export var speed: float = 200.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Variable para rastrear la última dirección
var last_direction: Vector2 = Vector2.DOWN

# Función para obtener el sufijo de dirección basado en el vector
func get_direction_suffix(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return ""
	
	# Normalizar el vector para determinar la dirección principal
	var angle = direction.angle()
	
	# Determinar la dirección basándose en ángulos
	# RIGHT: -45° a 45° (-PI/4 a PI/4)
	# DOWN: 45° a 135° (PI/4 a 3PI/4)
	# LEFT: 135° a 225° (3PI/4 a -3PI/4) 
	# UP: 225° a 315° (-3PI/4 a -PI/4)
	
	if angle >= -PI/4 and angle < PI/4:
		return "_right"
	elif angle >= PI/4 and angle < 3*PI/4:
		return "_down"
	elif angle >= 3*PI/4 or angle < -3*PI/4:
		return "_left"
	else:  # angle >= -3*PI/4 and angle < -PI/4
		return "_up"

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
