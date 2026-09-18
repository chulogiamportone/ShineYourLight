extends RigidBody2D

var portador: Node2D = null
var fue_lanzado=false
func _process(_delta):
	# Si Nana nos tiene agarrados, anulamos la física y nos posicionamos sobre ella
	if portador:
		# Posicionamos el objeto 50 píxeles arriba del centro de Nana
		global_position = portador.global_position + Vector2(0, -50)

func ser_agarrado(nuevo_portador):
	portador = nuevo_portador
	freeze = true # Desactiva las físicas mientras se sostiene

func ser_lanzado(direccion_x, fuerza):
	portador = null
	fue_lanzado=true
	freeze = false # Reactiva las físicas
	# Aplica un impulso: fuerza horizontal y un poco de fuerza vertical para la parábola
	apply_central_impulse(Vector2(direccion_x * fuerza, -fuerza * 0.5))

# Señales del Area2D interno para avisarle a Nana que estamos cerca
func _on_area_2d_body_entered(body):
	#if fue_lanzado:
		
	if body.has_method("registrar_objeto_cercano"):
		body.registrar_objeto_cercano(self)

func _on_area_2d_body_exited(body):
	if body.has_method("quitar_objeto_cercano"):
		body.quitar_objeto_cercano(self)
