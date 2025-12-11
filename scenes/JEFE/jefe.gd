extends CharacterBody2D

# ===== CONFIGURACIÓN EXPORTABLE =====
@export_group("Movement")
@export var speed: float = 150.0
@export var stop_distance: float = 50.0
@export var step_duration: float = 0.3
@export var pause_duration: float = 0.5

@export_group("Melee Attack")
@export var attack_damage: int = 15
@export var attack_duration: float = 0.6
@export var attack_cooldown: float = 2.0

@export_group("Ranged Attack")
@export var ranged_marker_scene: PackedScene
@export var ranged_hitbox_scene: PackedScene
@export var ranged_charge_time: float = 3.0
@export var ranged_hitbox_duration: float = 0.3
@export var ranged_hitbox_radius: float = 90.0
@export var ranged_attack_damage: int = 20
@export var ranged_blink_start_time: float = 0.5

# ===== ESTADOS =====
enum State { IDLE, CHASING, ATTACKING, RANGED_ATTACK }
var current_state = State.IDLE

# ===== REFERENCIAS A NODOS =====
@onready var health_component = $Health
@onready var hurtbox = $Hurtbox
@onready var health_bar = $HealthBar
@onready var idle_sprite = $Idle
@onready var walk_sprite = $Walk
@onready var attack_sprite = $Attack
@onready var detection_zone = $DetectionZone
@onready var attack_zone = $AttackZone
@onready var attack_hitbox = $AttackHitbox
@onready var attack_hitbox_collision = $AttackHitbox/CollisionShape2D
@onready var ranged_zone = $RangedZone
@onready var ranged_timer = $RangedTimer

# ===== VARIABLES DE JUEGO =====
var player: Node2D = null
var last_direction = Vector2.DOWN
var is_dead = false

# Movimiento pesado
var is_stepping = false
var step_timer = 0.0
var pause_timer = 0.0

# Ataque cuerpo a cuerpo
var attack_timer = 0.0
var is_attacking = false
var attack_hitbox_active = false

# Control de zonas
var player_in_detection = false
var player_in_attack_range = false
var player_in_ranged_zone = false

# Ataque a distancia
var ranged_attack_active: bool = false
var ranged_marker_instance: Node2D = null
var ranged_target_position: Vector2 = Vector2.ZERO

func _ready():
	# ===== BUSCAR JUGADOR =====
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error("❌ No se encontró al jugador en el grupo 'player'")
		return
	
	# ===== VERIFICAR NODOS CRÍTICOS =====
	if idle_sprite == null:
		push_error("❌ No se encontró AnimatedSprite2D 'Idle'")
	if walk_sprite == null:
		push_error("❌ No se encontró AnimatedSprite2D 'Walk'")
	if attack_sprite == null:
		push_error("❌ No se encontró AnimatedSprite2D 'Attack'")
	if ranged_zone == null:
		push_error("❌ No se encontró Area2D 'RangedZone'")
	if ranged_timer == null:
		push_error("❌ No se encontró Timer 'RangedTimer'")
	
	# ===== CONFIGURAR SPRITES =====
	if idle_sprite:
		idle_sprite.visible = true
	if walk_sprite:
		walk_sprite.visible = false
	if attack_sprite:
		attack_sprite.visible = false
	
	# ===== CONECTAR SEÑALES DE VIDA =====
	if health_component:
		if health_component.has_signal("died"):
			health_component.died.connect(_on_health_died)
		if health_component.has_signal("damaged"):
			health_component.damaged.connect(_on_health_damaged)
		print("✅ Señales de vida conectadas")
	
	# ===== CONFIGURAR BARRA DE VIDA =====
	if health_bar and health_component:
		var max_hp = get_max_health()
		health_bar.max_value = max_hp
		
		var current_hp = health_component.get("health")
		if current_hp != null:
			health_bar.value = current_hp
		else:
			health_bar.value = max_hp
		
		print("✅ Barra de vida configurada: " + str(health_bar.value) + "/" + str(max_hp))
	
	# ===== AÑADIR HURTBOX AL GRUPO =====
	if hurtbox:
		hurtbox.add_to_group("hurtbox")
	
	# ===== CONECTAR SEÑALES DE ZONAS EXISTENTES =====
	if detection_zone:
		detection_zone.body_entered.connect(_on_detection_zone_entered)
		detection_zone.body_exited.connect(_on_detection_zone_exited)
	
	if attack_zone:
		attack_zone.body_entered.connect(_on_attack_zone_entered)
		attack_zone.body_exited.connect(_on_attack_zone_exited)
	
	# ===== CONECTAR SEÑALES DE ATAQUE A DISTANCIA =====
	if ranged_zone:
		ranged_zone.body_entered.connect(_on_ranged_zone_body_entered)
		ranged_zone.body_exited.connect(_on_ranged_zone_body_exited)
		print("✅ Señales de RangedZone conectadas")
	
	if ranged_timer:
		ranged_timer.wait_time = ranged_charge_time
		ranged_timer.timeout.connect(_on_ranged_timer_timeout)
		print("✅ Señal de RangedTimer conectada")
	
	# ===== DESACTIVAR HITBOX DE ATAQUE =====
	if attack_hitbox and attack_hitbox_collision:
		attack_hitbox.monitoring = false
		attack_hitbox_collision.disabled = true

func _physics_process(delta):
	# ===== ACTUALIZAR BARRA DE VIDA =====
	if health_bar and health_component:
		var current_hp = health_component.get("health")
		if current_hp != null and health_bar.value != current_hp:
			health_bar.value = current_hp
			
			var max_hp = health_bar.max_value
			if current_hp <= max_hp * 0.3:
				health_bar.modulate = Color(1, 0, 0)
			elif current_hp <= max_hp * 0.6:
				health_bar.modulate = Color(1, 1, 0)
			else:
				health_bar.modulate = Color(0, 1, 0)
	
	if player == null or is_dead:
		return
	
	# ===== ACTUALIZAR MARCADOR DE ATAQUE A DISTANCIA =====
	if ranged_attack_active and ranged_marker_instance and is_instance_valid(ranged_marker_instance):
		ranged_target_position = player.global_position
		ranged_marker_instance.global_position = ranged_target_position
		
		var time_left = ranged_timer.time_left
		if time_left <= ranged_blink_start_time:
			var blink_speed = 10.0
			ranged_marker_instance.visible = fmod(time_left * blink_speed, 1.0) > 0.5
	
	# ===== ACTUALIZAR TEMPORIZADOR DE ATAQUE CUERPO A CUERPO =====
	if attack_timer > 0:
		attack_timer -= delta
	
	# ===== MÁQUINA DE ESTADOS =====
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.CHASING:
			handle_chasing_state(delta)
		State.ATTACKING:
			handle_attacking_state()
		State.RANGED_ATTACK:
			handle_ranged_attack_state()
	
	move_and_slide()

# ===== FUNCIONES DE ESTADOS =====

func handle_idle_state():
	velocity = Vector2.ZERO
	show_idle_animation(last_direction)
	
	if player_in_ranged_zone and not ranged_attack_active and not player_in_attack_range:
		start_ranged_attack()
	elif player_in_detection and not player_in_attack_range:
		current_state = State.CHASING
	elif player_in_attack_range and attack_timer <= 0 and not is_attacking:
		current_state = State.ATTACKING

func handle_chasing_state(delta):
	if player_in_ranged_zone and not ranged_attack_active and not player_in_attack_range:
		start_ranged_attack()
		return
	
	if player_in_attack_range and attack_timer <= 0 and not is_attacking:
		current_state = State.ATTACKING
		return
	
	if not player_in_detection:
		current_state = State.IDLE
		return
	
	var direction = (player.global_position - global_position).normalized()
	last_direction = direction
	
	if is_stepping:
		step_timer += delta
		velocity = direction * speed
		show_walk_animation(direction)
		
		if step_timer >= step_duration:
			is_stepping = false
			step_timer = 0.0
			pause_timer = 0.0
	else:
		pause_timer += delta
		velocity = Vector2.ZERO
		show_idle_animation(last_direction)
		
		if pause_timer >= pause_duration:
			is_stepping = true
			pause_timer = 0.0
			step_timer = 0.0

func handle_attacking_state():
	if not is_attacking:
		start_attack()
	
	if player:
		var direction_to_player = (player.global_position - global_position).normalized()
		last_direction = direction_to_player
		
		if attack_hitbox_active:
			update_attack_hitbox_position()
	
	velocity = Vector2.ZERO

func handle_ranged_attack_state():
	velocity = Vector2.ZERO
	
	if player:
		last_direction = (player.global_position - global_position).normalized()
		show_idle_animation(last_direction)

# ===== ATAQUE CUERPO A CUERPO =====

func start_attack():
	is_attacking = true
	velocity = Vector2.ZERO
	
	if player:
		last_direction = (player.global_position - global_position).normalized()
	
	if attack_sprite and idle_sprite and walk_sprite:
		idle_sprite.visible = false
		walk_sprite.visible = false
		attack_sprite.visible = true
	
	await get_tree().create_timer(0.2).timeout
	
	if is_dead:
		return
	
	attack_hitbox_active = true
	activate_attack_hitbox()
	
	await get_tree().create_timer(attack_duration).timeout
	
	attack_hitbox_active = false
	deactivate_attack_hitbox()
	
	is_attacking = false
	attack_timer = attack_cooldown
	
	if player_in_attack_range:
		current_state = State.IDLE
	elif player_in_detection:
		current_state = State.CHASING
	else:
		current_state = State.IDLE
	
	if attack_sprite:
		attack_sprite.visible = false
	show_idle_animation(last_direction)

func activate_attack_hitbox():
	if attack_hitbox and attack_hitbox_collision:
		attack_hitbox.monitoring = true
		attack_hitbox_collision.disabled = false
		update_attack_hitbox_position()

func update_attack_hitbox_position():
	if attack_hitbox and last_direction != Vector2.ZERO:
		var dir = last_direction.normalized()
		attack_hitbox.position = dir * 60
		attack_hitbox.rotation = dir.angle()
		
		if attack_sprite and attack_sprite.visible:
			var animation_name = get_animation_name(dir)
			if attack_sprite.sprite_frames.has_animation(animation_name):
				if attack_sprite.animation != animation_name:
					attack_sprite.play(animation_name)

func deactivate_attack_hitbox():
	if attack_hitbox and attack_hitbox_collision:
		attack_hitbox.monitoring = false
		attack_hitbox_collision.disabled = true

# ===== SISTEMA DE ATAQUE A DISTANCIA =====

func start_ranged_attack():
	if ranged_attack_active:
		print("⚠️ Ya hay un ataque a distancia activo")
		return
	
	if ranged_marker_scene == null:
		push_error("❌ ranged_marker_scene no está asignado en el inspector")
		return
	
	print("🎯 Iniciando ataque a distancia")
	
	current_state = State.RANGED_ATTACK
	ranged_attack_active = true
	
	velocity = Vector2.ZERO
	is_stepping = false
	step_timer = 0.0
	pause_timer = 0.0
	
	ranged_marker_instance = ranged_marker_scene.instantiate()
	ranged_target_position = player.global_position
	
	get_tree().root.add_child(ranged_marker_instance)
	ranged_marker_instance.global_position = ranged_target_position
	
	ranged_timer.start()
	print("⏰ Timer iniciado: " + str(ranged_charge_time) + " segundos")

func cancel_ranged_attack():
	if not ranged_attack_active:
		return
	
	print("❌ Ataque a distancia cancelado")
	
	if ranged_timer and not ranged_timer.is_stopped():
		ranged_timer.stop()
	
	if ranged_marker_instance and is_instance_valid(ranged_marker_instance):
		ranged_marker_instance.queue_free()
	ranged_marker_instance = null
	
	ranged_attack_active = false
	
	if player_in_attack_range:
		current_state = State.ATTACKING
	elif player_in_detection:
		current_state = State.CHASING
	else:
		current_state = State.IDLE

func execute_ranged_attack():
	if ranged_hitbox_scene == null:
		push_error("❌ ranged_hitbox_scene no está asignado en el inspector")
		cleanup_ranged_attack()
		return
	
	print("💥 Ejecutando impacto de ataque a distancia en: " + str(ranged_target_position))
	
	var hitbox_instance = ranged_hitbox_scene.instantiate()
	get_tree().root.add_child(hitbox_instance)
	hitbox_instance.global_position = ranged_target_position
	
	if hitbox_instance is Area2D:
		var collision_shape = hitbox_instance.get_node_or_null("CollisionShape2D")
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = ranged_hitbox_radius
		
		hitbox_instance.body_entered.connect(_on_ranged_hitbox_body_entered.bind(hitbox_instance))
	
	await get_tree().create_timer(ranged_hitbox_duration).timeout
	if is_instance_valid(hitbox_instance):
		hitbox_instance.queue_free()
	
	cleanup_ranged_attack()

func cleanup_ranged_attack():
	if ranged_marker_instance and is_instance_valid(ranged_marker_instance):
		ranged_marker_instance.queue_free()
	ranged_marker_instance = null
	
	ranged_attack_active = false
	
	if is_dead:
		return
	
	if player_in_attack_range:
		current_state = State.ATTACKING
	elif player_in_detection:
		current_state = State.CHASING
	else:
		current_state = State.IDLE
	
	print("✅ Ataque a distancia completado y limpiado")

# ===== SEÑALES DE ATAQUE A DISTANCIA =====

func _on_ranged_zone_body_entered(body):
	if body == player:
		player_in_ranged_zone = true
		print("🎯 Jugador entró en zona de ataque a distancia")

func _on_ranged_zone_body_exited(body):
	if body == player:
		player_in_ranged_zone = false
		print("🚪 Jugador salió de zona de ataque a distancia")
		
		if ranged_attack_active:
			cancel_ranged_attack()

func _on_ranged_timer_timeout():
	print("⏰ Timer completado - ejecutando impacto")
	execute_ranged_attack()

func _on_ranged_hitbox_body_entered(body, hitbox_instance):
	if body == player:
		var player_health = null
		
		if body.has_node("Health"):
			player_health = body.get_node("Health")
		elif body.get("health_component") != null:
			player_health = body.get("health_component")
		
		if player_health and player_health.has_method("damage"):
			player_health.damage(ranged_attack_damage)
			print("💥 ¡Ataque a distancia impactó al jugador! Daño: " + str(ranged_attack_damage))
		else:
			print("⚠️ El jugador no tiene componente Health o método damage()")

# ===== SEÑALES DE ZONAS EXISTENTES =====

func _on_detection_zone_entered(body):
	if body == player:
		player_in_detection = true
		if current_state == State.IDLE:
			current_state = State.CHASING

func _on_detection_zone_exited(body):
	if body == player:
		player_in_detection = false
		if current_state == State.CHASING:
			current_state = State.IDLE

func _on_attack_zone_entered(body):
	if body == player:
		player_in_attack_range = true

func _on_attack_zone_exited(body):
	if body == player:
		player_in_attack_range = false
		if current_state == State.ATTACKING and not is_attacking:
			current_state = State.IDLE

# ===== ANIMACIONES =====

func show_walk_animation(direction: Vector2):
	if walk_sprite == null or idle_sprite == null or attack_sprite == null:
		return
	
	idle_sprite.visible = false
	walk_sprite.visible = true
	attack_sprite.visible = false
	
	var animation_name = get_animation_name(direction)
	
	if walk_sprite.sprite_frames.has_animation(animation_name):
		if walk_sprite.animation != animation_name:
			walk_sprite.play(animation_name)

func show_idle_animation(direction: Vector2):
	if walk_sprite == null or idle_sprite == null or attack_sprite == null:
		return
	
	walk_sprite.visible = false
	idle_sprite.visible = true
	attack_sprite.visible = false
	
	var animation_name = get_animation_name(direction)
	
	if idle_sprite.sprite_frames.has_animation(animation_name):
		if idle_sprite.animation != animation_name:
			idle_sprite.play(animation_name)

func get_animation_name(direction: Vector2) -> String:
	var animation_name = ""
	var angle = direction.angle()
	var degrees = rad_to_deg(angle)
	
	if degrees < 0:
		degrees += 360
	
	if degrees >= 337.5 or degrees < 22.5:
		animation_name = "right"
	elif degrees >= 22.5 and degrees < 67.5:
		animation_name = "down_right"
	elif degrees >= 67.5 and degrees < 112.5:
		animation_name = "down"
	elif degrees >= 112.5 and degrees < 157.5:
		animation_name = "down_left"
	elif degrees >= 157.5 and degrees < 202.5:
		animation_name = "left"
	elif degrees >= 202.5 and degrees < 247.5:
		animation_name = "up_left"
	elif degrees >= 247.5 and degrees < 292.5:
		animation_name = "up"
	elif degrees >= 292.5 and degrees < 337.5:
		animation_name = "up_right"
	
	return animation_name

# ===== UTILIDADES =====

func get_max_health() -> float:
	# ... (código simplificado)
	var max_hp = health_component.get_indexed("max_health")
	if max_hp == null:
		max_hp = health_component.get_indexed("MAX_HEALTH")
	
	if max_hp != null and typeof(max_hp) in [TYPE_FLOAT, TYPE_INT]:
		return float(max_hp)
	
	return 100.0

# ===== SEÑALES DE VIDA =====

func _on_health_damaged(entity, type, amount, incrementer, multiplier, applied, current):
	print("🩸 Jefe recibió " + str(applied) + " de daño. Vida: " + str(current))

func _on_health_died(entity: Node):
	if is_dead:
		return
	
	is_dead = true
	print("💀 ¡El jefe ha sido derrotado!")
	
	if ranged_attack_active:
		cancel_ranged_attack()
	
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		hurtbox.remove_from_group("hurtbox")
	
	velocity = Vector2.ZERO
	set_physics_process(false)
	
	if health_bar:
		health_bar.visible = false
	
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	queue_free()
