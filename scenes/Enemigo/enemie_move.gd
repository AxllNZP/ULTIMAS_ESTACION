extends CharacterBody2D

# Velocidad del enemigo
@export var speed: float = 60.0

# Referencia al jugador (se asigna cuando entra en el área de detección)
var player: CharacterBody2D = null

# Última dirección para las animaciones
var last_direction: String = "down"

# Referencias a los nodos
@onready var move_sprite = $MOVE
@onready var idle_sprite = $IDLE
@onready var detection_area = $DetectionArea

func _ready():
	# Conectar las señales del Area2D
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Asegurar que el sprite idle esté oculto y el de movimiento visible
	idle_sprite.visible = false
	move_sprite.visible = true
	
	# Iniciar en animación idle
	move_sprite.play("walk_down")

func _physics_process(_delta):
	# Si no hay jugador detectado, quedarse quieto
	if player == null:
		velocity = Vector2.ZERO
		# Cambiar a sprite idle
		show_idle_animation()
		move_and_slide()
		return
	
	# Calcular la dirección hacia el jugador
	var direction = (player.global_position - global_position).normalized()
	
	# Aplicar velocidad
	velocity = direction * speed
	
	# Obtener la dirección para las animaciones
	last_direction = get_direction_from_vector(direction)
	
	# Mostrar animación de movimiento
	show_move_animation()
	
	# Mover al enemigo
	move_and_slide()

# Función cuando un cuerpo entra en el área de detección
func _on_detection_area_body_entered(body):
	# Verificar que sea el jugador
	if body.name == "Player":
		player = body

# Función cuando un cuerpo sale del área de detección
func _on_detection_area_body_exited(body):
	# Verificar que sea el jugador
	if body.name == "Player":
		player = null

# Función que muestra la animación de movimiento
func show_move_animation():
	# Ocultar idle, mostrar move
	idle_sprite.visible = false
	move_sprite.visible = true
	
	# Reproducir animación de caminar
	move_sprite.play("walk_" + last_direction)

# Función que muestra la animación idle
func show_idle_animation():
	# Ocultar move, mostrar idle
	move_sprite.visible = false
	idle_sprite.visible = true
	
	# Reproducir animación idle
	idle_sprite.play("idle_" + last_direction)

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
