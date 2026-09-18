extends Area2D

# Definimos la posición a la que queremos que el cuerpo reaparezca (respawn)
# Podés cambiar estos valores en el inspector de Godot
@export var posicion_de_respawn: Vector2 = Vector2(0, 0) 

# Esta función se ejecuta automáticamente cuando un cuerpo entra en el área.
# Recordá conectar la señal "body_entered" de tu nodo Area2D a este script.
func _on_body_entered(body: Node2D) -> void:
	# Comprobamos si el cuerpo que entró es el que queremos (por ejemplo, el Jugador)
	# Podés verificarlo por nombre o por si pertenece a un grupo ("Player")
	if body.name == "CharacterBody2D":
		# Cambiamos la posición global del cuerpo a la nueva posición
		body.global_position = posicion_de_respawn
		
		# Nota: En Godot 4, si usas CharacterBody2D, a veces es mejor resetear 
		# la velocidad a cero para evitar que siga moviéndose por inercia:
		# body.velocity = Vector2.ZERO
