extends Area2D

func _on_body_entered(body):
	# Verificamos si el cuerpo que entró tiene la variable 'en_escalera'
	if "en_escalera" in body:
		body.en_escalera = true

func _on_body_exited(body):
	if "en_escalera" in body:
		body.en_escalera = false
