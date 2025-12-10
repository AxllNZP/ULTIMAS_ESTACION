extends CharacterBody2D

# Velocidad del jefe
@export var speed: float = 150.0

# Distancia mínima para detenerse (evita que se sobreponga al jugador)
@export var stop_distance: float = 50.0

# Referencias a los AnimatedSprite2D
@onready var idle_sprite = $Idle
@onready var walk_sprite = $Walk

# Componente de vida del addon
@onready var health_component = $Health
@onready var hurtbox = $BasicHurtBox2D
@onready var health_bar = $HealthBar  # Barra de vida

# Referencia al jugador
var player: Node2D = null

# Última dirección del movimiento
var last_direction = Vector2.DOWN

# Control de muerte
var is_dead = false

func _ready():
	# 1. Buscar al jugador
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("Jugador no encontrado. Asegúrate de que el jugador esté en el grupo 'player'.")
	
	# 2. Conectar señales del componente Health del addon
	if health_component:
		if health_component.has_signal("died"):
			health_component.died.connect(_on_boss_died)
		if health_component.has_signal("health_changed"):
			health_component.health_changed.connect(_on_health_changed)
		if health_component.has_signal("damaged"):
			health_component.damaged.connect(_on_boss_damaged)
	if health_bar and health_component:
		# Usamos call_deferred para inicializar la barra de vida de forma segura.
		# Esto debe resolver el problema de acceso a 'max_health'.
		call_deferred("initialize_health_bar_safe")
	# 4. Configurar Hurtbox
	if hurtbox:
		hurtbox.add_to_group("hurtbox") # Puedes comentar/eliminar si no lo usas en otro lado
		
		

func _physics_process(_delta):
	if player == null or is_dead:
		return
	
	# Calcular la dirección hacia el jugador
	var direction = (player.global_position - global_position).normalized()
	
	# Calcular la distancia al jugador
	var distance = global_position.distance_to(player.global_position)
	
	# Solo moverse si está lejos del jugador
	if distance > stop_distance:
		velocity = direction * speed
		last_direction = direction
		show_walk_animation(direction)
	else:
		velocity = Vector2.ZERO
		show_idle_animation(last_direction)
	
	# Mover al jefe
	move_and_slide()

# Cuando el jefe recibe daño
func _on_health_changed(_old_health, new_health):
	print("Jefe recibió daño! Vida: " + str(new_health) + "/" + str(health_component.max_health))
	# Actualizar la barra de vida
	update_health_bar()

# Otra forma de detectar daño (si el addon usa esta señal)
func _on_boss_damaged(damage_amount):
	print("Jefe recibió " + str(damage_amount) + " de daño! Vida restante: " + str(health_component.health))
	# Actualizar la barra de vida
	update_health_bar()

# Actualizar la barra de vida visual
func update_health_bar():
	if health_bar and health_component:
		health_bar.value = health_component.health
		
		# Cambiar color según la vida (opcional)
		if health_component.health <= health_component.max_health * 0.3:
			# Vida baja - color rojo
			health_bar.modulate = Color(1, 0, 0)  # Rojo
		elif health_component.health <= health_component.max_health * 0.6:
			# Vida media - color amarillo
			health_bar.modulate = Color(1, 1, 0)  # Amarillo
		else:
			# Vida alta - color verde
			health_bar.modulate = Color(0, 1, 0)  # Verde

# Cuando el jefe muere
func _on_boss_died():
	if is_dead: return
	is_dead = true
	print("¡Misión cumplida: Jefe derrotado!")
	
	velocity = Vector2.ZERO
	if health_bar: health_bar.visible = false
	
	# Efecto de muerte: se pone rojo y desaparece
	modulate = Color(1, 0, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.5) # Desvanecimiento
	
	await tween.finished
	queue_free() # ELIMINACIÓN TOTAL

func show_walk_animation(direction: Vector2):
	if walk_sprite == null or idle_sprite == null:
		return
	
	# Mostrar sprite de caminar
	idle_sprite.visible = false
	walk_sprite.visible = true
	
	# Obtener el nombre de la animación según la dirección
	var animation_name = get_animation_name(direction)
	
	# Reproducir la animación
	if walk_sprite.sprite_frames.has_animation(animation_name):
		if walk_sprite.animation != animation_name:
			walk_sprite.play(animation_name)
	else:
		print("⚠️ Animación NO encontrada en Walk: '" + animation_name + "'")

func show_idle_animation(direction: Vector2):
	if walk_sprite == null or idle_sprite == null:
		return
	
	# Mostrar sprite de idle
	walk_sprite.visible = false
	idle_sprite.visible = true
	
	# Obtener el nombre de la animación según la dirección
	var animation_name = get_animation_name(direction)
	
	# Reproducir la animación
	if idle_sprite.sprite_frames.has_animation(animation_name):
		if idle_sprite.animation != animation_name:
			idle_sprite.play(animation_name)
	else:
		print("⚠️ Animación NO encontrada en Idle: '" + animation_name + "'")

func get_animation_name(direction: Vector2) -> String:
	var animation_name = ""
	
	# Convertir la dirección a grados
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	
	# Normalizar el ángulo entre 0 y 360
	if degrees < 0:
		degrees += 360
	
	# Determinar la dirección basándose en el ángulo (8 direcciones)
	if degrees >= 337.5 or degrees < 22.5:
		animation_name = "right"           # →
	elif degrees >= 22.5 and degrees < 67.5:
		animation_name = "down_right"      # ↘
	elif degrees >= 67.5 and degrees < 112.5:
		animation_name = "down"            # ↓
	elif degrees >= 112.5 and degrees < 157.5:
		animation_name = "down_left"       # ↙
	elif degrees >= 157.5 and degrees < 202.5:
		animation_name = "left"            # ←
	elif degrees >= 202.5 and degrees < 247.5:
		animation_name = "up_left"         # ↖
	elif degrees >= 247.5 and degrees < 292.5:
		animation_name = "up"              # ↑
	elif degrees >= 292.5 and degrees < 337.5:
		animation_name = "up_right"        # ↗
	
	return animation_name
