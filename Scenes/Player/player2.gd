extends CharacterBody2D

# 1. VARIABLES CONFIGURABLES
@export var velocidad_caminar : float = 300.0 
@export var fuerza_salto : float = -700.0
@export var fuerza_dash : float = 800.0
@export var tiempo_dash_maximo : float = 0.2

# NUEVAS VARIABLES PARA MECÁNICAS
@export var velocidad_escalar : float = 200.0
@export var fuerza_lanzamiento : float = 600.0

# 2. VARIABLES INTERNAS
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity") 
var saltos_permitidos : int = 2 
var saltos_realizados : int = 0

var esta_haciendo_dash : bool = false 
var tiempo_dash_actual : float = 0.0
var direccion_dash : float = 0.0

# NUEVAS VARIABLES DE ESTADO
var en_escalera : bool = false
var objeto_cercano : Node2D = null 
var objeto_agarrado : Node2D = null

@export var fuerza_repulsion : float = 800.0
var tiempo_aturdimiento : float = 0.5

# 3. EL MOTOR DEL JUEGO
func _physics_process(delta): 
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
		# Si estamos en la escalera, anulamos la gravedad y nos movemos en Y
		var direccion_vertical = Input.get_axis("ui_up2", "ui_down2") # O "mover_arriba", "mover_abajo"
		velocity.y = direccion_vertical * velocidad_escalar
		saltos_realizados = 0 # Permite saltar para soltarse de la escalera
	elif not is_on_floor():
		velocity.y += gravedad * delta 
	else:
		saltos_realizados = 0 

	# --- SECCIÓN C: EL SALTO Y DOBLE SALTO ---
	if Input.is_action_just_pressed("saltar2"): 
		if is_on_floor() or en_escalera:
			velocity.y = fuerza_salto
			saltos_realizados = 1
			en_escalera = false # Nos soltamos al saltar
		elif saltos_realizados < saltos_permitidos:
			velocity.y = fuerza_salto
			saltos_realizados += 1

	# --- SECCIÓN D: MOVIMIENTO LATERAL ---
	var direccion = Input.get_axis("mover_izquierda2", "mover_derecha2") 
	
	if direccion != 0:
		velocity.x = direccion * velocidad_caminar 
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_caminar) 

	# --- SECCIÓN E: INICIAR EL DASH ---
	if Input.is_action_just_pressed("dash2") and direccion != 0: 
		esta_haciendo_dash = true
		tiempo_dash_actual = tiempo_dash_maximo
		direccion_dash = direccion 
		velocity.y = 0 

	# --- NUEVA SECCIÓN: AGARRAR Y LANZAR ---
	# Configura una acción "interactuar" en el Mapa de Entrada (ej: tecla E)
	if Input.is_action_just_pressed("interactuar2"):
		if objeto_agarrado:
			# Si tenemos algo, lo lanzamos hacia donde miramos (o derecha por defecto)
			var dir_lanzamiento = direccion_dash if direccion_dash != 0 else 1
			objeto_agarrado.ser_lanzado(dir_lanzamiento, fuerza_lanzamiento)
			objeto_agarrado = null
		elif objeto_cercano and objeto_cercano.has_method("ser_agarrado"):
			# Si no tenemos nada y hay algo cerca, lo agarramos
			objeto_cercano.ser_agarrado(self)
			objeto_agarrado = objeto_cercano

	# --- SECCIÓN F: APLICAR MOVIMIENTO ---
	move_and_slide()

# Funciones para que los objetos interactivos notifiquen a Nana
func registrar_objeto_cercano(objeto):
	objeto_cercano = objeto

func quitar_objeto_cercano(objeto):
	if objeto_cercano == objeto:
		objeto_cercano = null

# Función para recibir el impacto
func recibir_danio(_cantidad, origen_del_golpe: Vector2):
	# Usamos _cantidad con un guion bajo porque no nos importa el número de daño, 
	# solo querías el efecto de repulsión.
	
	# 1. Calculamos la dirección del empuje (desde la explosión hacia Nana)
	var direccion_empuje = (global_position - origen_del_golpe).normalized()
	
	# 2. Le sumamos un poco de fuerza hacia arriba para que el vuelo sea en parábola
	direccion_empuje.y -= 0.5 
	direccion_empuje = direccion_empuje.normalized()

	# 3. Aplicamos la fuerza y le quitamos el control un instante
	velocity = direccion_empuje * fuerza_repulsion
	tiempo_aturdimiento = 0.3 # 0.3 segundos sin control
	
	# 4. Por seguridad, si estaba en la escalera o haciendo dash, lo cancelamos
	en_escalera = false
	esta_haciendo_dash = false
