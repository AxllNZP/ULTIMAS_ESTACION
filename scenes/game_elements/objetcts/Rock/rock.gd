extends StaticBody2D

# Variables de estado
var player_nearby: bool = false
var is_interacted: bool = false

# Referencias a los nodos
@onready var animated_sprite = $AnimatedSprite2D
@onready var button_prompt = $ButtonPrompt
@onready var interaction_area = $InteractionArea



func _ready():
	# Conectar las señales del Area2D
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Conectar la señal de animación terminada
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Asegurar que el botón esté oculto al inicio
	button_prompt.visible = false
	
	# Iniciar en la animación idle
	animated_sprite.play("idle")

func _process(_delta):
	# Si el jugador está cerca, no ha interactuado, y presiona la tecla
	if player_nearby and not is_interacted and Input.is_action_just_pressed("interact"):
		interact()

func _on_body_entered(body):
	# Verificar que sea el jugador
	if body.name == "Player":
		player_nearby = true
		# Mostrar el indicador solo si aún no se ha interactuado
		if not is_interacted:
			button_prompt.visible = true

func _on_body_exited(body):
	# Verificar que sea el jugador
	if body.name == "Player":
		player_nearby = false
		# Ocultar el indicador
		button_prompt.visible = false

func interact():
	# Marcar como interactuado
	is_interacted = true
	
	# Ocultar el indicador
	button_prompt.visible = false
	
	# Reproducir la animación de destrucción
	animated_sprite.play("breaking")

func _on_animation_finished():
	# Cuando termina la animación de destrucción, cambiar al estado final
	if animated_sprite.animation == "breaking":
		animated_sprite.play("broken")
