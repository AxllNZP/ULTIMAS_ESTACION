extends Node2D

@onready var interact_area: Area2D = $InteractArea

func get_direction_angle(direction: Vector2) -> float:
	if direction == Vector2.ZERO:
		return 0
	
	# Normalizar el vector para determinar la dirección principal
	var angle = direction.angle()
	
	# Determinar la dirección basándose en ángulos
	# RIGHT: -45° a 45° (-PI/4 a PI/4)
	# DOWN: 45° a 135° (PI/4 a 3PI/4)
	# LEFT: 135° a 225° (3PI/4 a -3PI/4) 
	# UP: 225° a 315° (-3PI/4 a -PI/4)
	
	if angle >= -PI/4 and angle < PI/4:
		return 0
	elif angle >= PI/4 and angle < 3*PI/4:
		return PI/2
	elif angle >= 3*PI/4 or angle < -3*PI/4:
		return PI
	else:  # angle >= -3*PI/4 and angle < -PI/4
		return 3*PI/2

func set_direction(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		rotation = get_direction_angle(direction) - PI/2

func get_interactable() -> Node2D:
	var bodies = interact_area.get_overlapping_bodies()
	if bodies.size() > 0:
		return bodies[0]  # O lógica más compleja
	return null
