extends CharacterBody2D

# Velocidad del personaje
@export var speed: float = 100.0
@export var attack_impulse: float = 50.0  # Impulso al atacar

# Variable para recordar la última dirección
var last_direction: String = "down"

# Variable de estado de ataque
var is_attacking: bool = false

# Referencias
@onready var animated_sprite = $AnimatedSprite2D
@onready var attacks_sprite = $Attacks

func _ready():
	# Conectar la señal de animación terminada del sprite de ataques
	attacks_sprite.animation_finished.connect(_on_attack_animation_finished)
	
	# Asegurar que el sprite de ataques esté oculto al inicio
	attacks_sprite.visible = false

func _physics_process(_delta):
	# Si está atacando, no procesar movimiento
	if is_attacking:
		move_and_slide()
		return
	
	# Detectar si se presiona el botón de ataque
	if Input.is_action_just_pressed("attack"):
		attack()
		return
	
	# Obtener el input del jugador
	var input_vector = Vector2.ZERO
	
	# Detectar todas las teclas presionadas simultáneamente
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	# Normalizar el vector para que la velocidad diagonal no sea mayor
	input_vector = input_vector.normalized()
	
	# Aplicar movimiento
	if input_vector != Vector2.ZERO:
		# Hay movimiento
		velocity = input_vector * speed
		
		# Obtener la dirección basada en el ángulo del vector
		last_direction = get_direction_from_vector(input_vector)
		
		# Reproducir animación de caminar
		animated_sprite.play("walk_" + last_direction)
	else:
		# No hay movimiento
		velocity = Vector2.ZERO
		
		# Reproducir animación idle de la última dirección
		animated_sprite.play("idle_" + last_direction)
	
	# Mover al personaje
	move_and_slide()

# Función de ataque
func attack():
	# Marcar que está atacando
	is_attacking = true
	
	# Ocultar el sprite de movimiento y mostrar el de ataque
	animated_sprite.visible = false
	attacks_sprite.visible = true
	
	# Reproducir la animación de ataque en la última dirección
	attacks_sprite.play("Attack_" + last_direction)
	
	# Aplicar un pequeño impulso en la dirección del ataque
	var impulse_vector = get_impulse_vector_from_direction(last_direction)
	velocity = impulse_vector * attack_impulse

# Función que se ejecuta cuando termina la animación de ataque
func _on_attack_animation_finished():
	# Volver al estado normal
	is_attacking = false
	
	# Ocultar sprite de ataque y mostrar el de movimiento
	attacks_sprite.visible = false
	animated_sprite.visible = true
	
	# Detener el movimiento
	velocity = Vector2.ZERO
	
	# Volver a la animación idle
	animated_sprite.play("idle_" + last_direction)

# Función que convierte un vector de movimiento en una dirección (string)
func get_direction_from_vector(vector: Vector2) -> String:
	# Obtener el ángulo del vector en radianes
	var angle = vector.angle()
	
	# Convertir el ángulo a grados y normalizarlo (0 a 360)
	var degree = rad_to_deg(angle)
	if degree < 0:
		degree += 360
	
	# Mapear el ángulo a una de las 8 direcciones
	if degree >= 337.5 or degree < 22.5:
		return "right"
	elif degree >= 22.5 and degree < 67.5:
		return "down_right"
	elif degree >= 67.5 and degree < 112.5:
		return "down"
	elif degree >= 112.5 and degree < 157.5:
		return "down_left"
	elif degree >= 157.5 and degree < 202.5:
		return "left"
	elif degree >= 202.5 and degree < 247.5:
		return "up_left"
	elif degree >= 247.5 and degree < 292.5:
		return "up"
	elif degree >= 292.5 and degree < 337.5:
		return "up_right"
	
	return "down"  # Fallback

# Función que convierte una dirección en un vector de impulso
func get_impulse_vector_from_direction(direction: String) -> Vector2:
	match direction:
		"right":
			return Vector2(1, 0)
		"down_right":
			return Vector2(1, 1).normalized()
		"down":
			return Vector2(0, 1)
		"down_left":
			return Vector2(-1, 1).normalized()
		"left":
			return Vector2(-1, 0)
		"up_left":
			return Vector2(-1, -1).normalized()
		"up":
			return Vector2(0, -1)
		"up_right":
			return Vector2(1, -1).normalized()
	
	return Vector2.ZERO  # Fallback
