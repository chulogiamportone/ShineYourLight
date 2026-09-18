extends CharacterBody2D
#Extiende de un Nodo CharacterBody2D

# 1. VARIABLES CONFIGURABLES
@export var velocidad_caminar : float = 300.0
@export var fuerza_salto : float = -700.0
@export var fuerza_dash : float = 800.0
@export var tiempo_dash_maximo : float = 0.2

# 2. VARIABLES INTERNAS Y NODOS
# Obtenemos la gravedad que Godot trae por defecto.
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variables para controlar el doble salto.
var saltos_permitidos : int = 2
var saltos_realizados : int = 0

# Variables para controlar el dash (el impulso rápido).
var esta_haciendo_dash : bool = false
var tiempo_dash_actual : float = 0.0
var direccion_dash : float = 0.0

# --- NUEVO: REFERENCIA AL SPRITE ---
# El "@onready" le dice a Godot que espere a que el juego arranque para buscar este nodo.
# IMPORTANTE: Asegurate de que el nodo de tu imagen se llame "Sprite2D". 
# Si usas animaciones, cambialo por "$AnimatedSprite2D".
@onready var sprite =  $AnimatedSprite2D

# 3. EL MOTOR DEL JUEGO
func _physics_process(delta):
	
	# --- SECCIÓN A: EL DASH ---
	if esta_haciendo_dash:
		tiempo_dash_actual -= delta
		if tiempo_dash_actual <= 0:
			esta_haciendo_dash = false
		else:
			velocity.x = direccion_dash * fuerza_dash
			move_and_slide() 
			return 
			
	# --- SECCIÓN B: LA GRAVEDAD ---
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		saltos_realizados = 0

	# --- SECCIÓN C: EL SALTO Y DOBLE SALTO ---
	if Input.is_action_just_pressed("saltar1"):
		if is_on_floor():
			velocity.y = fuerza_salto
			saltos_realizados = 1
		elif saltos_realizados < saltos_permitidos:
			velocity.y = fuerza_salto
			saltos_realizados += 1

	# --- SECCIÓN D: MOVIMIENTO LATERAL Y FLIP ---
	var direccion = Input.get_axis("mover_izquierda1", "mover_derecha1")
	
	if direccion != 0:
		velocity.x = direccion * velocidad_caminar
		
		# --- NUEVO: VOLTEAR EL SPRITE (FLIP HORIZONTAL) ---
		# Si la dirección es menor a 0 (izquierda), activamos el flip.
		if direccion < 0:
			sprite.flip_h = true
		# Si la dirección es mayor a 0 (derecha), desactivamos el flip.
		elif direccion > 0:
			sprite.flip_h = false
			
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_caminar)

	# --- SECCIÓN E: INICIAR EL DASH ---
	if Input.is_action_just_pressed("dash1") and direccion != 0:
		esta_haciendo_dash = true
		tiempo_dash_actual = tiempo_dash_maximo
		direccion_dash = direccion 
		velocity.y = 0 

	# --- SECCIÓN F: APLICAR TODO EL MOVIMIENTO ---
	move_and_slide()
