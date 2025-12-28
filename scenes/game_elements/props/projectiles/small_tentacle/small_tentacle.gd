extends Area2D

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var appear_cd : Timer = $AppearCd

func _ready() -> void:
	appear_cd.timeout.connect(_on_appear_cd_timeout)
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)
	area_entered.connect(_on_area_entered)
	appear_cd.start()
	animation_player.play("tentacle_in")

func _on_appear_cd_timeout() -> void:
	animation_player.play("tentacle_on")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "tentacle_on":
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	area.damage(20)
