extends CharacterBody2D

# --- ESTADÍSTICAS DEL JUGADOR ---
var velocidad_actual = 300.0
var fuerza_salto = -600.0 # Ahora es variable, no constante
var dano_ataque = 1
var tiempo_disparo = 1.0 # Los segundos que tarda en disparar
var gravedad = 2000.0
@onready var proyectil_fuego_escena = preload("res://proyectil_fuego.tscn")
@onready var proyectil_hielo_escena = preload("res://proyectil_hielo.tscn")
@onready var proyectil_rayo_escena = preload("res://proyectil_rayo.tscn")
@onready var proyectil_veneno_escena = preload("res://proyectil_veneno.tscn")
var habilidad_1 = "" # Guardará "fuego", "hielo", etc.
var nivel_habilidad_1 = 0
var habilidad_2 = ""
var nivel_habilidad_2 = 0
# Obtenemos la gravedad definida en la configuración global del proyecto.
#var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var proyectil_escena = preload("res://proyectil.tscn")

var salud = 100

func recibir_daño(cantidad):
	salud -= cantidad
	print("¡Auch! Salud restante: ", salud)
	
	if salud <= 0:
		morir()

func morir():
	print("El jugador ha muerto")
	# Aquí podrías usar get_tree().reload_current_scene() para reiniciar
	get_tree().reload_current_scene()

func _physics_process(delta):
	# Aplicar gravedad REAL para que caiga
	if not is_on_floor():
		velocity.y += gravedad * delta

	# Lógica de salto (esto sí usa la fuerza_salto)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = fuerza_salto
	#else:
		#velocity.y = 0

	# Obtener la dirección del movimiento (-1 para izquierda, 1 para derecha, 0 si no se pulsa)
	# Usa las flechas del teclado o A/D
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * velocidad_actual
	else:
		# Fricción: detenerse cuando no se pulsa nada
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
	#if is_on_floor(): velocity.y = 0
	# Ejecutar el movimiento y manejar colisiones
	move_and_slide()

func _on_weapon_timer_timeout():
	# 1. Obtenemos todos los enemigos dentro del círculo
	var enemigos = $RangoAtaque.get_overlapping_areas()
	
	if enemigos.size() > 0:
		# 2. Lógica para encontrar el más cercano
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			var dist_actual = global_position.distance_to(enemigo.global_position)
			var dist_menor = global_position.distance_to(objetivo_cercano.global_position)
			if dist_actual < dist_menor:
				objetivo_cercano = enemigo
		
		# 3. Instanciar la bala
		# 3. Instanciar la bala
		var bala = proyectil_escena.instantiate()
		
		# ¡AQUÍ ESTÁ LA MAGIA! Le pasamos el daño del jugador a la bala
		bala.dano = dano_ataque 
		
		get_tree().current_scene.add_child(bala)
		bala.global_position = global_position
		
		# 4. Calcular la dirección hacia el enemigo
		# direction_to nos da un vector que apunta exactamente al objetivo
		var direccion = global_position.direction_to(objetivo_cercano.global_position)
		
		# Le pasamos esa dirección a la bala
		bala.lanzar(direccion)
var nivel = 0
var xp_actual = 0
var xp_necesaria = 2 # Fase 1 según TSH.xlsx

func ganar_xp(cantidad):
	xp_actual += cantidad
	print("XP RECOGIDA: ", xp_actual, " / ", xp_necesaria)
	
	# --- NUEVO: Le avisamos al HUD ---
	var hud = get_parent().get_node("HUD")
	if hud:
		hud.actualizar_xp(xp_actual, xp_necesaria)
	# ---------------------------------
	
	if xp_actual >= xp_necesaria:
		subir_nivel()

func subir_nivel():
	nivel += 1
	xp_actual = 0
	xp_necesaria += 2
	print("NUEVO NIVEL: ", nivel)
	
	# 1. ACTUALIZAMOS EL HUD (Lo que faltaba)
	var hud = get_parent().get_node("HUD")
	if hud:
		hud.actualizar_nivel(nivel)
		hud.actualizar_xp(xp_actual, xp_necesaria)
	
	# 2. LOGICA DEL MENU INTELIGENTE
	var menu = get_parent().get_node("MenuNivel")
	
	if nivel == 5:
		menu.configurar_modo_habilidades(1)
	elif nivel == 15:
		menu.configurar_modo_habilidades(2)
	elif nivel == 25:
		pass # Aquí irá el menú de fusión después
	else:
		menu.configurar_modo_atributos()
	
	get_tree().paused = true
	menu.show()

func mejorar_velocidad():
	velocidad_actual += 50.0
	print("¡Velocidad mejorada a: ", velocidad_actual, "!")

func mejorar_salto():
	fuerza_salto -= 25.0 # En Godot, más negativo = salta más alto
	print("¡Salto mejorado a: ", fuerza_salto, "!")

func mejorar_ataque():
	dano_ataque += 1
	print("¡Daño de ataque mejorado a: ", dano_ataque, "!")

func mejorar_cadencia():
	tiempo_disparo -= 0.042
	
	if tiempo_disparo < 0.2:
		tiempo_disparo = 0.2
		print("¡Velocidad de ataque al MÁXIMO!")
		
	# Buscamos el nodo con el nombre exacto por defecto de Godot
	$WeaponTimer.wait_time = tiempo_disparo
	
	print("¡Nueva cadencia: dispara cada ", tiempo_disparo, " segundos!")
func _ready():
	var hud = get_parent().get_node("HUD")
	if hud:
		hud.actualizar_nivel(nivel)
		hud.actualizar_xp(xp_actual, xp_necesaria)


func _on_timer_fuego_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	
	if enemigos.size() > 0:
		# Buscamos al enemigo más cercano
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			var dist_actual = global_position.distance_to(enemigo.global_position)
			var dist_menor = global_position.distance_to(objetivo_cercano.global_position)
			if dist_actual < dist_menor:
				objetivo_cercano = enemigo
		
		# Instanciamos la BOLA DE FUEGO
		var bola_fuego = proyectil_fuego_escena.instantiate()
		get_tree().current_scene.add_child(bola_fuego)
		bola_fuego.global_position = global_position
		
		var direccion = global_position.direction_to(objetivo_cercano.global_position)
		bola_fuego.lanzar(direccion)

func _on_timer_hielo_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		# Buscamos al enemigo más cercano
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			if global_position.distance_to(enemigo.global_position) < global_position.distance_to(objetivo_cercano.global_position):
				objetivo_cercano = enemigo
				
		# Instanciamos el HIELO
		var estalactita = proyectil_hielo_escena.instantiate()
		get_tree().current_scene.add_child(estalactita)
		estalactita.global_position = global_position
		
		# Lo lanzamos hacia el objetivo
		var direccion = global_position.direction_to(objetivo_cercano.global_position)
		estalactita.lanzar(direccion)

func desbloquear_fuego():
	if $TimerFuego.is_stopped():
		$TimerFuego.start()
		print("¡FUEGO INICIADO A 1 SEGUNDO!")

func desbloquear_hielo():
	if $TimerHielo.is_stopped():
		$TimerHielo.start()
		print("¡HIELO INICIADO A 1 SEGUNDO!")
		
func desbloquear_rayo():
	if $TimerRayo.is_stopped():
		$TimerRayo.start()

func desbloquear_veneno():
	if $TimerVeneno.is_stopped():
		$TimerVeneno.start()

# Funciones de Disparo (Copia la lógica de buscar enemigo del Fuego/Hielo):
func _on_timer_rayo_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		var objetivo_cercano = enemigos[0]
		# ... (Tu código para buscar al más cercano) ...
		var rayo = proyectil_rayo_escena.instantiate()
		get_tree().current_scene.add_child(rayo)
		rayo.global_position = global_position
		rayo.lanzar(global_position.direction_to(objetivo_cercano.global_position))

func _on_timer_veneno_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		var objetivo_cercano = enemigos[0]
		# ... (Tu código para buscar al más cercano) ...
		var gota_veneno = proyectil_veneno_escena.instantiate()
		get_tree().current_scene.add_child(gota_veneno)
		gota_veneno.global_position = global_position
		gota_veneno.lanzar(global_position.direction_to(objetivo_cercano.global_position))
