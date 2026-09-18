extends CharacterBody2D
#Extiende de un Nodo CharacterBody2D


# 1. VARIABLES CONFIGURABLES

# Al usar "@export", estas variables aparecerán en el panel 
# derecho de Godot (el Inspector). Así puedes cambiar la 
# velocidad o el salto sin tener que volver a abrir este código.

@export var velocidad_caminar : float = 300.0
@export var fuerza_salto : float = -700.0
@export var fuerza_dash : float = 800.0
@export var tiempo_dash_maximo : float = 0.2


# 2. VARIABLES INTERNAS , estas no se ven en el inspector pero funcionan igual 

# Obtenemos la gravedad que Godot trae por defecto.
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variables para controlar el doble salto.
var saltos_permitidos : int = 2
var saltos_realizados : int = 0

# Variables para controlar el dash (el impulso rápido).
var esta_haciendo_dash : bool = false
var tiempo_dash_actual : float = 0.0
var direccion_dash : float = 0.0


# 3. EL MOTOR DEL JUEGO (Se ejecuta todo el tiempo)

# La función "_physics_process" se ejecuta unas 60 veces por 
# segundo. Aquí adentro ocurre toda la magia del movimiento.

func _physics_process(delta):
	
	# --- SECCIÓN A: EL DASH ---
	# Si el personaje está haciendo un dash, hacemos esto y nada más.
	if esta_haciendo_dash:
		# Le restamos al reloj el tiempo que pasó (delta)
		tiempo_dash_actual -= delta
		
		# Si el reloj llega a 0, se terminó el dash
		if tiempo_dash_actual <= 0:
			esta_haciendo_dash = false
		else:
			# Si seguimos en dash, movemos al personaje muy rápido
			velocity.x = direccion_dash * fuerza_dash
			move_and_slide() # Aplica el movimiento
			return # Cortamos la función acá para que no caiga ni salte
			
	# --- SECCIÓN B: LA GRAVEDAD ---
	# Si NO estamos tocando el piso, le sumamos gravedad para caer.
	if not is_on_floor():
		velocity.y += gravedad * delta
	else:
		# Si tocamos el piso, reiniciamos la cuenta de los saltos.
		saltos_realizados = 0

	# --- SECCIÓN C: EL SALTO Y DOBLE SALTO ---
	# Detectamos el momento exacto en que se aprieta la tecla de salto.
	if Input.is_action_just_pressed("saltar"):
		if is_on_floor():
			# Salto normal desde el suelo
			velocity.y = fuerza_salto
			saltos_realizados = 1
		elif saltos_realizados < saltos_permitidos:
			# Doble salto en el aire
			velocity.y = fuerza_salto
			saltos_realizados += 1

	# --- SECCIÓN D: MOVIMIENTO LATERAL ---
	# Obtiene la dirección: -1 (izquierda), 1 (derecha) o 0 (quieto).
	var direccion = Input.get_axis("mover_izquierda", "mover_derecha")
	
	if direccion != 0:
		# Si nos movemos, aplicamos la velocidad de caminar.
		velocity.x = direccion * velocidad_caminar
	else:
		# Si soltamos las teclas, frenamos al personaje a cero.
		velocity.x = move_toward(velocity.x, 0, velocidad_caminar)

	# --- SECCIÓN E: INICIAR EL DASH ---
	# Detectamos si se apretó el dash Y si nos estamos moviendo.
	if Input.is_action_just_pressed("dash") and direccion != 0:
		esta_haciendo_dash = true
		tiempo_dash_actual = tiempo_dash_maximo
		direccion_dash = direccion # Guardamos hacia dónde miramos
		velocity.y = 0 # Congelamos la caída un instante para salir rectos

	# --- SECCIÓN F: APLICAR TODO EL MOVIMIENTO ---
	# Esta es la función principal de Godot que agarra todos los 
	# cálculos de arriba y mueve al personaje respetando las paredes.
	move_and_slide()
