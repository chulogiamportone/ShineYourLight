extends Node2D

@export var player1: Node2D
@export var player2: Node2D

# Configuración de zoom y márgenes
@export var zoom_minimo: float = 0.3
@export var zoom_maximo: float = 0.5
@export var margen: Vector2 = Vector2(150, 150)
@export var velocidad_zoom: float = 5.0

# Referencias a los nodos
@onready var camara_principal = $Camera2D
@onready var canvas_split = $SplitScreen

@onready var viewport1 = $SplitScreen/HBoxContainer/SubViewportContainer/SubViewport
@onready var camera1 = $SplitScreen/HBoxContainer/SubViewportContainer/SubViewport/Camera2D

@onready var viewport2 = $SplitScreen/HBoxContainer/SubViewportContainer2/SubViewport
@onready var camera2 = $SplitScreen/HBoxContainer/SubViewportContainer2/SubViewport/Camera2D

var pantalla_dividida: bool = false

func _ready():
	# Sincronizamos los mundos de los viewports secundarios para que vean 
	# el mismo mundo principal sin duplicar nodos.
	var mundo_principal = get_viewport().world_2d
	viewport1.world_2d = mundo_principal
	viewport2.world_2d = mundo_principal
	
	# Empezamos ocultando el canvas de pantalla dividida
	desactivar_pantalla_dividida()

func _process(delta):
	if not is_instance_valid(player1) or not is_instance_valid(player2):
		return

	var diff = player1.global_position - player2.global_position
	var distancia_x = abs(diff.x)
	var distancia_y = abs(diff.y)

	# Tamaño de la ventana para calcular el zoom
	var tamaño_pantalla = get_viewport().get_visible_rect().size

	# Calcular zoom objetivo de la cámara principal
	var zoom_x = tamaño_pantalla.x / (distancia_x + margen.x * 2)
	var zoom_y = tamaño_pantalla.y / (distancia_y + margen.y * 2)
	var zoom_objetivo = min(zoom_x, zoom_y)

	# Transición entre unificado y dividido
	if not pantalla_dividida and zoom_objetivo < zoom_minimo - 0.01:
		activar_pantalla_dividida()
	elif pantalla_dividida and zoom_objetivo > zoom_minimo + 0.03:
		desactivar_pantalla_dividida()

	# Comportamiento de las cámaras según el estado
	if pantalla_dividida:
		# Cámaras individuales siguen a sus jugadores
		camera1.global_position = camera1.global_position.lerp(player1.global_position, 10 * delta)
		camera2.global_position = camera2.global_position.lerp(player2.global_position, 10 * delta)
		
		# Opcional: mantengo un zoom máximo fijo para la pantalla dividida (podés cambiarlo)
		camera1.zoom = camera1.zoom.lerp(Vector2(zoom_maximo, zoom_maximo), velocidad_zoom * delta)
		camera2.zoom = camera2.zoom.lerp(Vector2(zoom_maximo, zoom_maximo), velocidad_zoom * delta)
	else:
		# Cámara principal unificada
		var punto_medio = (player1.global_position + player2.global_position) / 2.0
		camara_principal.global_position = camara_principal.global_position.lerp(punto_medio, 10 * delta)
		
		var zoom_final = clamp(zoom_objetivo, zoom_minimo, zoom_maximo)
		camara_principal.zoom = camara_principal.zoom.lerp(Vector2(zoom_final, zoom_final), velocidad_zoom * delta)

func activar_pantalla_dividida():
	pantalla_dividida = true
	canvas_split.show()
	# Opcional: Apagamos la principal para ahorrar recursos de renderizado
	camara_principal.enabled = false 

func desactivar_pantalla_dividida():
	pantalla_dividida = false
	canvas_split.hide()
	# Volvemos a encender la principal
	camara_principal.enabled = true
