extends CharacterBody2D

# Velocidad del personaje
@export var speed: float = 100.0

# Variable para recordar la última dirección
var last_direction: String = "down"

# Referencias
@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(_delta):
	# Obtener el input del jugador
	var input_vector = Vector2.ZERO
	
	# Detectar las teclas presionadas
	var up = Input.is_action_pressed("move_up")
	var down = Input.is_action_pressed("move_down")
	var left = Input.is_action_pressed("move_left")
	var right = Input.is_action_pressed("move_right")
	
	# Sistema de priorización (vertical tiene prioridad sobre horizontal)
	if up:
		input_vector.y = -1
		last_direction = "up"
	elif down:
		input_vector.y = 1
		last_direction = "down"
	elif left:
		input_vector.x = -1
		last_direction = "left"
	elif right:
		input_vector.x = 1
		last_direction = "right"
	
	# Aplicar movimiento
	if input_vector != Vector2.ZERO:
		# Hay movimiento - reproducir animación de caminar
		velocity = input_vector * speed
		animated_sprite.play("walk_" + last_direction)
	else:
		# No hay movimiento - reproducir animación idle
		velocity = Vector2.ZERO
		animated_sprite.play("idle_" + last_direction)
	
	# Mover al personaje
	move_and_slide()
