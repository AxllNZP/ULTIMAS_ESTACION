extends CharacterBody2D

# Velocidad del personaje
@export var speed: float = 300.0

# Variables del dash
@export var dash_speed: float = 800.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

# Variables del ataque
@export var attack_duration: float = 0.4
@export var attack_damage: int = 25  # Daño que hace el jugador
@export var hitbox_distance: float = 50.0  # Distancia del hitbox desde el personaje
@export var hitbox_size: Vector2 = Vector2(40, 40)  # Tamaño del hitbox

# Componente de vida
@onready var health_component = $Health  # Nodo Health del addon

# Referencias a los dos AnimatedSprite2D (ajusta las rutas según tu jerarquía)
@onready var idle_sprite = $Idle
@onready var move_sprite = $move
@onready var attack_sprite = $Attack  # Nuevo sprite para ataques
@onready var hitbox = $Hitbox  # Area2D para detectar colisiones
@onready var hitbox_collision = $Hitbox/CollisionShape2D

# Variable para recordar la última dirección
var last_direction = Vector2.DOWN

# Variables de estado del dash
var is_dashing = false
var can_dash = true
var dash_direction = Vector2.ZERO

# Variables de estado del ataque
var is_attacking = false

func _ready():
	# Verificar que los sprites existen
	if idle_sprite == null:
		push_error("No se encontró el AnimatedSprite2D 'Idle'. Verifica la ruta en el script.")
	if move_sprite == null:
		push_error("No se encontró el AnimatedSprite2D 'Move'. Verifica la ruta en el script.")
	if attack_sprite == null:
		push_error("No se encontró el AnimatedSprite2D 'Attack'. Verifica la ruta en el script.")
	
	# Inicialmente mostrar solo el idle
	if idle_sprite:
		idle_sprite.visible = true
	if move_sprite:
		move_sprite.visible = false
	if attack_sprite:
		attack_sprite.visible = false
	
	# Desactivar hitbox al inicio
	if hitbox:
		hitbox.monitoring = false
		hitbox_collision.disabled = true
		# Conectar la señal para detectar cuando el hitbox golpea algo
		hitbox.area_entered.connect(_on_hitbox_area_entered)
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta):
	# Detectar input del ataque (clic izquierdo o tecla de ataque)
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_dashing:
		start_attack()
	
	# Detectar input del dash (Espacio o Shift)
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing and not is_attacking:
		start_dash()
	
	# Si está atacando, no se puede mover
	if is_attacking:
		velocity = Vector2.ZERO
	# Si está en dash, usar velocidad del dash
	elif is_dashing:
		velocity = dash_direction * dash_speed
	else:
		# Movimiento normal
		var input_x = Input.get_axis("move_left", "move_right")
		var input_y = Input.get_axis("move_up", "move_down")
		var direction = Vector2(input_x, input_y)
		
		# Aplicar la velocidad
		if direction != Vector2.ZERO:
			velocity = direction.normalized() * speed
			last_direction = direction
			show_move_animation(direction)
		else:
			velocity = Vector2.ZERO
			show_idle_animation(last_direction)
	
	# Mover el personaje
	move_and_slide()

func show_move_animation(direction: Vector2):
	if move_sprite == null or idle_sprite == null or attack_sprite == null:
		return
	
	# Ocultar otros y mostrar move
	idle_sprite.visible = false
	move_sprite.visible = true
	attack_sprite.visible = false
	
	# Obtener el nombre de la animación
	var animation_name = get_animation_name(direction)
	
	# Reproducir la animación si existe y es diferente
	if move_sprite.sprite_frames.has_animation(animation_name):
		if move_sprite.animation != animation_name:
			move_sprite.play(animation_name)
	else:
		print("⚠️ Animación NO encontrada en Move: '" + animation_name + "'")

func show_idle_animation(direction: Vector2):
	if move_sprite == null or idle_sprite == null or attack_sprite == null:
		return
	
	# Ocultar otros y mostrar idle
	move_sprite.visible = false
	idle_sprite.visible = true
	attack_sprite.visible = false
	
	# Obtener el nombre de la animación
	var animation_name = get_animation_name(direction)
	
	# Reproducir la animación si existe y es diferente
	if idle_sprite.sprite_frames.has_animation(animation_name):
		if idle_sprite.animation != animation_name:
			idle_sprite.play(animation_name)
	else:
		print("⚠️ Animación NO encontrada en Idle: '" + animation_name + "'")

func get_animation_name(direction: Vector2) -> String:
	var animation_name = ""
	
	# Convertir la dirección a grados (0° = derecha, 90° = abajo, 180° = izquierda, 270° = arriba)
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	
	# Normalizar el ángulo entre 0 y 360
	if degrees < 0:
		degrees += 360
	
	# Determinar la dirección basándose en el ángulo (8 direcciones)
	# Cada dirección tiene un rango de 45 grados
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

func start_dash():
	is_dashing = true
	can_dash = false
	dash_direction = last_direction.normalized()
	
	# Timer para la duración del dash
	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false
	
	# Timer para el cooldown del dash
	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func start_attack():
	if is_attacking: return # Evita spam de ataques
	is_attacking = true
	
	# 1. Configurar Animación
	if attack_sprite:
		idle_sprite.visible = false
		move_sprite.visible = false
		attack_sprite.visible = true
		
		var animation_name = get_animation_name(last_direction)
		if attack_sprite.sprite_frames.has_animation(animation_name):
			attack_sprite.play(animation_name)

	# 2. Posicionar antes de activar
	position_hitbox(last_direction)
	
	# 3. Activar el daño (Usando los métodos del addon)
	activate_hitbox()
	
	# 4. Esperar a que termine la animación
	# Si tu animación dura exactamente 0.4s, el await está bien.
	await get_tree().create_timer(attack_duration).timeout
	
	# 5. Limpieza final
	deactivate_hitbox()
	is_attacking = false
	show_idle_animation(last_direction)

func position_hitbox(direction: Vector2):
	if hitbox == null: return
	
	# Normalizamos para que la distancia sea siempre constante
	var dir = direction.normalized()
	
	# Posición relativa al jugador:
	# Multiplicamos la dirección por la distancia configurada
	hitbox.position = dir * hitbox_distance
	
	# Rotación: Importante si tu hitbox es rectangular (como una espada)
	# para que siempre apunte hacia afuera del jugador.
	hitbox.rotation = direction.angle()

func activate_hitbox():
	# Si es el nodo del addon, activamos su monitoreo
	if hitbox:
		hitbox.monitoring = true
		hitbox_collision.set_deferred("disabled", false)

func deactivate_hitbox():
	if hitbox:
		hitbox.monitoring = false
		hitbox_collision.set_deferred("disabled", true)

# Cuando el hitbox del jugador golpea un área (como el BasicHurtBox2D del jefe)
func _on_hitbox_area_entered(area):
	if area.is_in_group("hurtbox"):
		# Hacer daño al enemigo
		if area.owner.has_node("Health"):
			var enemy_health = area.owner.get_node("Health")
			enemy_health.damage(attack_damage)
			print("¡Golpeaste al enemigo! Daño: " + str(attack_damage))

# Cuando el hitbox del jugador golpea un cuerpo (por si usas otro método)
func _on_hitbox_body_entered(body):
	if body.has_node("Health"):
		var enemy_health = body.get_node("Health")
		enemy_health.damage(attack_damage)
		print("¡Golpeaste al enemigo! Daño: " + str(attack_damage))
