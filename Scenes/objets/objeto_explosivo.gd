extends Area2D

var tiempo_en_area : float = 0.0
var jugador_adentro : Node2D = null
@onready var label: Label = $Label
@onready var bomb: Sprite2D = $Bomb

func _process(delta):
	# Si el jugador está en el área, el cronómetro avanza
	if jugador_adentro:
		bomb.texture=preload("uid://bl6avusyxy8k0")
		tiempo_en_area += delta
		label.text=str(int(3-tiempo_en_area))
		if tiempo_en_area >= 2.0:
			explotar()
	#else:
		## Si querés que la explosión se cancele al salir, dejá esta línea. 
		## Si los 3 segundos son acumulativos, borrala.
		#tiempo_en_area = 0.0 

func _on_body_entered(body):
	if body.name == "Nana" or "en_escalera" in body: 
		jugador_adentro = body

#func _on_body_exited(body):
	#if body == jugador_adentro:
		#jugador_adentro = null

func explotar():
	print("¡BOOM! Explosión activada en Proyecto Co-Nexus")
	
	if jugador_adentro and jugador_adentro.has_method("recibir_danio"):
		# Le pasamos 0 de daño numérico, pero le mandamos nuestra posición exacta
		jugador_adentro.recibir_danio(0, global_position)
	
	# Destruye el objeto explosivo
	queue_free()
