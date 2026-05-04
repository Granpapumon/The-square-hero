extends CharacterBody2D

# --- ESTADÍSTICAS ---
var velocidad_actual = 300.0
var fuerza_salto = -600.0
var dano_ataque = 1
var tiempo_disparo = 1.0
var gravedad = 2000.0
var salud = 1
var invulnerable = false

# --- PROGRESIÓN ---
var nivel = 0
var xp_actual = 0
var xp_necesaria = 2

# --- HABILIDADES ---
var habilidad_1 = ""
var habilidad_2 = ""
var nivel_habilidad_1 = 0
var nivel_habilidad_2 = 0

@onready var proyectil_escena = preload("res://proyectil.tscn")
@onready var proyectil_fuego_escena = preload("res://proyectil_fuego.tscn")
@onready var proyectil_hielo_escena = preload("res://proyectil_hielo.tscn")
@onready var proyectil_rayo_escena = preload("res://proyectil_rayo.tscn")
@onready var proyectil_veneno_escena = preload("res://proyectil_veneno.tscn")

# --- VIDA ---
func recibir_daño(cantidad):
	salud -= cantidad
	if salud <= 0:
		morir()

func morir():
	get_tree().call_deferred("reload_current_scene")

# --- MOVIMIENTO ---
func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravedad * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = fuerza_salto

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)

	move_and_slide()

# --- DISPARO BASE ---
func _on_weapon_timer_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() == 0:
		return
	var objetivo_cercano = enemigos[0]
	for enemigo in enemigos:
		if global_position.distance_to(enemigo.global_position) < global_position.distance_to(objetivo_cercano.global_position):
			objetivo_cercano = enemigo

	var bala = proyectil_escena.instantiate()
	bala.dano = dano_ataque
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	bala.lanzar(global_position.direction_to(objetivo_cercano.global_position))

# --- XP Y NIVELES ---
func ganar_xp(cantidad):
	xp_actual += cantidad
	
	# Buscamos la pantalla (HUD) y le avisamos que la barra debe moverse
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("actualizar_xp"):
		hud.actualizar_xp(xp_actual, xp_necesaria)
		
	# Si nos pasamos del límite, subimos de nivel
	if xp_actual >= xp_necesaria:
		subir_nivel()

func subir_nivel():
	nivel += 1
	xp_actual = 0
	xp_necesaria += 2
	print("NUEVO NIVEL: ", nivel)
	
	# Le avisamos al HUD que cambie el texto y reinicie la barra
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.actualizar_nivel(nivel)
		hud.actualizar_xp(xp_actual, xp_necesaria)
	
	# Mostramos el menú correcto
	var menu = get_tree().get_first_node_in_group("menu_nivel")
	# Si no usas grupo para el menú, cambia la línea de arriba por: var menu = get_parent().get_node("MenuNivel")
	
	if menu:
		if nivel == 5:
			menu.configurar_modo_habilidades()
		elif nivel == 15:
			menu.configurar_modo_habilidades()
		else:
			menu.configurar_modo_atributos()
		# --- SISTEMA DE AUTO-MEJORA DE HABILIDADES ---
		if nivel in [7, 9, 11, 13]:
			nivel_habilidad_1 += 1
			print("¡La Habilidad 1 subió a nivel ", nivel_habilidad_1, "!")
		elif nivel in [17, 19, 21, 23]:
			nivel_habilidad_2 += 1
			print("¡La Habilidad 2 subió a nivel ", nivel_habilidad_2, "!")
		get_tree().paused = true
		menu.show()

# --- DESBLOQUEAR HABILIDAD ---
func desbloquear_habilidad(nombre: String):
	if habilidad_1 == "":
		habilidad_1 = nombre
		nivel_habilidad_1 = 1
	elif habilidad_2 == "":
		habilidad_2 = nombre
		nivel_habilidad_2 = 1
		# --- ENCENDER EL RELOJ DE LA MAGIA ---
	if nombre == "fuego":
		$TimerFuego.start()
	elif nombre == "hielo":
		$TimerHielo.start()
	elif nombre == "rayo":
		$TimerRayo.start()
	elif nombre == "veneno":
		$TimerVeneno.start()
func obtener_nivel_magia(nombre_magia: String) -> int:
	if habilidad_1 == nombre_magia:
		return nivel_habilidad_1
	elif habilidad_2 == nombre_magia:
		return nivel_habilidad_2
	return 1 # Por defecto siempre es mínimo nivel 1
# --- MEJORAS DE ATRIBUTOS ---
func mejorar_velocidad():
	velocidad_actual = min(velocidad_actual + 50.0, 600.0)

func mejorar_salto():
	fuerza_salto = max(fuerza_salto - 25.0, -1200.0)

func mejorar_ataque():
	dano_ataque = min(dano_ataque + 1, 20)

func mejorar_cadencia():
	tiempo_disparo = max(tiempo_disparo - 0.042, 0.2)
	$WeaponTimer.wait_time = tiempo_disparo
	
# ==========================================
# RELOJES DE MAGIA (COPIAR Y PEGAR ESTO)
# ==========================================

func _on_timer_fuego_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			if global_position.distance_to(enemigo.global_position) < global_position.distance_to(objetivo_cercano.global_position):
				objetivo_cercano = enemigo
				
		var bola_fuego = proyectil_fuego_escena.instantiate()
		
		# --- MATEMÁTICA FUEGO ---
		var nivel_magia = obtener_nivel_magia("fuego")
		bola_fuego.dano = nivel_magia * 2 
		
		get_tree().current_scene.add_child(bola_fuego)
		bola_fuego.global_position = global_position
		bola_fuego.lanzar(global_position.direction_to(objetivo_cercano.global_position))


func _on_timer_hielo_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			if global_position.distance_to(enemigo.global_position) < global_position.distance_to(objetivo_cercano.global_position):
				objetivo_cercano = enemigo
				
		var estalactita = proyectil_hielo_escena.instantiate()
		
		# --- MATEMÁTICA HIELO ---
		var nivel_magia = obtener_nivel_magia("hielo")
		estalactita.tiempo_congelacion = 1.5 + (nivel_magia * 0.5) 
		
		get_tree().current_scene.add_child(estalactita)
		estalactita.global_position = global_position
		estalactita.lanzar(global_position.direction_to(objetivo_cercano.global_position))


func _on_timer_rayo_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			if global_position.distance_to(enemigo.global_position) < global_position.distance_to(objetivo_cercano.global_position):
				objetivo_cercano = enemigo
				
		var rayo = proyectil_rayo_escena.instantiate()
		
		# --- MATEMÁTICA RAYO ---
		var nivel_magia = obtener_nivel_magia("rayo")
		rayo.porcentaje_ralentizacion = 0.50 + (nivel_magia * 0.10) 
		
		get_tree().current_scene.add_child(rayo)
		rayo.global_position = global_position
		rayo.lanzar(global_position.direction_to(objetivo_cercano.global_position))


func _on_timer_veneno_timeout():
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() > 0:
		var objetivo_cercano = enemigos[0]
		for enemigo in enemigos:
			if global_position.distance_to(enemigo.global_position) < global_position.distance_to(objetivo_cercano.global_position):
				objetivo_cercano = enemigo
				
		var gota_veneno = proyectil_veneno_escena.instantiate()
		
		# --- MATEMÁTICA VENENO ---
		var nivel_magia = obtener_nivel_magia("veneno")
		gota_veneno.dano_veneno = nivel_magia * 2 
		
		get_tree().current_scene.add_child(gota_veneno)
		gota_veneno.global_position = global_position
		gota_veneno.lanzar(global_position.direction_to(objetivo_cercano.global_position))
