extends CharacterBody2D

# --- CONFIGURACIÓN DEL JUGADOR (MULTIJUGADOR LOCAL) ---
# Exportamos esto como un String ("1" o "2") para armar los inputs dinámicamente
@export_enum("1", "2") var id_jugador : String = "1" 

# --- NUEVAS VARIABLES: ANTORCHAS Y PUNTAJE ---
var cantidad_antorchas : int = 0
var puntaje : float = 0.0
# Multiplicador: ¿Cuántos puntos por segundo da cada antorcha?
@export var multiplicador_antorcha : float = 10.0 

# 1. VARIABLES CONFIGURABLES
@export var velocidad_caminar : float = 300.0 
@export var fuerza_salto : float = -700.0
@export var fuerza_dash : float = 800.0
@export var tiempo_dash_maximo : float = 0.2
@export var velocidad_escalar : float = 200.0
@export var fuerza_lanzamiento : float = 600.0
@export var fuerza_repulsion : float = 800.0

# 2. VARIABLES INTERNAS
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity") 
var saltos_permitidos : int = 2 
var saltos_realizados : int = 0

var esta_haciendo_dash : bool = false 
var tiempo_dash_actual : float = 0.0
var direccion_dash : float = 0.0

var en_escalera : bool = false
var objeto_cercano : Node2D = null 
var objeto_agarrado : Node2D = null
var tiempo_aturdimiento : float = 0.0 # Lo inicializamos en 0 por defecto

# 3. EL MOTOR DEL JUEGO
func _physics_process(delta): 
	
	# --- SISTEMA DE PUNTAJE ---
	# Sumamos puntos constantemente basados en la cantidad de antorchas.
	# Multiplicar por 'delta' garantiza que sea exactamente por segundo real.
	if cantidad_antorchas > 0:
		puntaje += (cantidad_antorchas * multiplicador_antorcha) * delta

	# --- ESTADO DE ATURDIMIENTO ---
	if tiempo_aturdimiento > 0:
		tiempo_aturdimiento -= delta
		if not is_on_floor():
			velocity.y += gravedad * delta
		move_and_slide()
		return # Cortamos la función acá para que no se pueda mover ni hacer dash
	
	# --- SECCIÓN A: EL DASH ---
	if esta_haciendo_dash:
		tiempo_dash_actual -= delta
		if tiempo_dash_actual <= 0:
			esta_haciendo_dash = false
		else:
			velocity.x = direccion_dash * fuerza_dash
			move_and_slide()
			return 
			
	# --- SECCIÓN B: LA GRAVEDAD Y ESCALERAS ---
	if en_escalera:
		# Armamos el input dinámico: "mover_arriba1" o "mover_arriba2"
		var direccion_vertical = Input.get_axis("mover_arriba" + id_jugador, "mover_abajo" + id_jugador) 
		velocity.y = direccion_vertical * velocidad_escalar
		saltos_realizados = 0 
	elif not is_on_floor():
		velocity.y += gravedad * delta 
	else:
		saltos_realizados = 0 

	# --- SECCIÓN C: EL SALTO Y DOBLE SALTO ---
	if Input.is_action_just_pressed("saltar" + id_jugador): 
		if is_on_floor() or en_escalera:
			velocity.y = fuerza_salto
			saltos_realizados = 1
			en_escalera = false 
		elif saltos_realizados < saltos_permitidos:
			velocity.y = fuerza_salto
			saltos_realizados += 1

	# --- SECCIÓN D: MOVIMIENTO LATERAL ---
	var direccion = Input.get_axis("mover_izquierda" + id_jugador, "mover_derecha" + id_jugador) 
	
	if direccion != 0:
		velocity.x = direccion * velocidad_caminar 
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_caminar) 

	# --- SECCIÓN E: INICIAR EL DASH ---
	if Input.is_action_just_pressed("dash" + id_jugador) and direccion != 0: 
		esta_haciendo_dash = true
		tiempo_dash_actual = tiempo_dash_maximo
		direccion_dash = direccion 
		velocity.y = 0 

	# --- NUEVA SECCIÓN: AGARRAR Y LANZAR ---
	if Input.is_action_just_pressed("interactuar" + id_jugador):
		if objeto_agarrado:
			var dir_lanzamiento = direccion_dash if direccion_dash != 0 else 1
			objeto_agarrado.ser_lanzado(dir_lanzamiento, fuerza_lanzamiento)
			objeto_agarrado = null
		elif objeto_cercano and objeto_cercano.has_method("ser_agarrado"):
			objeto_cercano.ser_agarrado(self)
			objeto_agarrado = objeto_cercano

	# --- SECCIÓN F: APLICAR MOVIMIENTO ---
	move_and_slide()

# Funciones para objetos interactivos
func registrar_objeto_cercano(objeto):
	objeto_cercano = objeto

func quitar_objeto_cercano(objeto):
	if objeto_cercano == objeto:
		objeto_cercano = null

# Función para recibir el impacto
func recibir_danio(_cantidad, origen_del_golpe: Vector2):
	var direccion_empuje = (global_position - origen_del_golpe).normalized()
	direccion_empuje.y -= 0.5 
	direccion_empuje = direccion_empuje.normalized()

	velocity = direccion_empuje * fuerza_repulsion
	tiempo_aturdimiento = 0.3 
	
	en_escalera = false
	esta_haciendo_dash = false
