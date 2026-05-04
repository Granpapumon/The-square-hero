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
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.actualizar_xp(xp_actual, xp_necesaria)
	if xp_actual >= xp_necesaria:
		subir_nivel()

func subir_nivel():
	nivel += 1
	xp_actual = 0
	xp_necesaria += 2
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.actualizar_xp(0, xp_necesaria)
		hud.actualizar_nivel(nivel)
	get_tree().paused = true
	var menu = get_tree().get_first_node_in_group("menu_nivel")
	if nivel == 5 or nivel == 15:
		menu.configurar_modo_habilidades()
	else:
		menu.configurar_modo_atributos()
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
