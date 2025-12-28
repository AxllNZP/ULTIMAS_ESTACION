extends Node2D

@onready var damage_area: Area2D = $DamageArea

func _ready() -> void:
	damage_area.area_entered.connect(_on_damage_area_entered)

func get_direction_angle(direction: Vector2) -> float:
	if direction == Vector2.ZERO:
		return 0
	
	var rotated = direction.rotated(0)
	var closest_dir = Vector2.RIGHT.rotated(rotated.angle())
	return closest_dir.angle()


func set_direction(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		rotation = get_direction_angle(direction) - PI/2

func _on_damage_area_entered(area: Area2D) -> void:
	area.damage(20)
