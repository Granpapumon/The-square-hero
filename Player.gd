extends CharacterBody2D

# --- ESTADÍSTICAS ---
var velocidad_actual = 300.0
var fuerza_salto = -600.0
var dano_ataque = 1
var tiempo_disparo = 1.0
var gravedad = 2000.0
var salud = 100

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

# --- VIDA ---
func recibir_daño(cantidad):
	salud -= cantidad
	if salud <= 0:
		morir()

func morir():
	get_tree().reload_current_scene()

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
			menu.configurar_modo_habilidades(1)
		elif nivel == 15:
			menu.configurar_modo_habilidades(2)
		else:
			menu.configurar_modo_atributos()
		
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
