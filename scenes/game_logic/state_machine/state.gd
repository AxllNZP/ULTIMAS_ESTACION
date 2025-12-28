class_name State
extends Node

# Señal para cambiar a otro estado
signal finished(next_state_path: String)

# Llamado por la state machine al recibir input
func handle_input(_event: InputEvent) -> void:
	pass

# Llamado por la state machine en cada frame
func update(_delta: float) -> void:
	pass

# Llamado por la state machine en cada physics frame
func physics_update(_delta: float) -> void:
	pass

# Llamado al entrar al estado
func enter(_previous_state_path: String) -> void:
	pass

# Llamado al salir del estado
func exit() -> void:
	pass
