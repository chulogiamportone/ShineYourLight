extends Area2D

var dueno_actual : Node2D = null
var valor_antorcha : int = 1

@onready var sprite_base = $"../TorchOff"
@onready var sprite_animado = $"../AnimatedSprite2D"

func _on_body_entered(body):
	# Identificamos si el que entra es uno de los jugadores permitidos
	if body.name == "CharacterBody2D" or body.name == "CharacterBody2D2":
		
		# Si el jugador que toca el área ya es el dueño, ignoramos
		if body == dueno_actual:
			return
			
		# Si ya había un dueño previo (el otro player), le descontamos el valor
		if dueno_actual:
			# Chequeamos que la variable exista en el jugador usando tu lógica
			if "cantidad_antorchas" in dueno_actual:
				dueno_actual.cantidad_antorchas -= valor_antorcha
		
		# Le sumamos el valor al nuevo jugador que entró
		if "cantidad_antorchas" in body:
			body.cantidad_antorchas += valor_antorcha
			
		# Guardamos la referencia del nuevo dueño
		dueno_actual = body
		
		# Cambiamos los sprites
		sprite_base.hide()
		sprite_animado.show()
		
		# Reproducimos la animación que corresponda según quién entró
		if body.name == "CharacterBody2D":
			sprite_animado.play("animacion_2")
		elif body.name == "CharacterBody2D2":
			sprite_animado.play("animacion_1")
			
		print("Antorcha capturada por: ", body.name)
