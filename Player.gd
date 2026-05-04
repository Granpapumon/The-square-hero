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

# --- PERKS ---
var tiene_dash = false
var tiene_salto_doble = false
var puede_dashar = true
var saltos_restantes = 1
const DASH_VELOCIDAD = 900.0
const DASH_DURACION = 0.15

# --- ESCENAS ---
@onready var proyectil_escena        = preload("res://proyectil.tscn")
@onready var proyectil_fuego_escena  = preload("res://proyectil_fuego.tscn")
@onready var proyectil_hielo_escena  = preload("res://proyectil_hielo.tscn")
@onready var proyectil_rayo_escena   = preload("res://proyectil_rayo.tscn")
@onready var proyectil_veneno_escena = preload("res://proyectil_veneno.tscn")

# --- VIDA ---
func recibir_daño(cantidad):
	salud -= cantidad
	if salud <= 0:
		morir()

func morir():
	get_tree().reload_current_scene()

# --- MOVIMIENTO ---
func _physics_process(delta):
	if is_on_floor():
		saltos_restantes = 2 if tiene_salto_doble else 1

	if not is_on_floor():
		velocity.y += gravedad * delta

	# Salto (base + doble salto)
	if Input.is_action_just_pressed("ui_accept") and saltos_restantes > 0:
		velocity.y = fuerza_salto
		saltos_restantes -= 1

	# Dash (tecla Shift — agrégala en InputMap)
	if tiene_dash and puede_dashar and Input.is_action_just_pressed("dash"):
		var dir = Input.get_axis("ui_left", "ui_right")
		if dir != 0:
			_ejecutar_dash(dir)

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)

	move_and_slide()

func _ejecutar_dash(dir: float):
	puede_dashar = false
	# Deshabilitar colisión con enemigos durante el dash
	set_collision_mask_value(1, false)
	velocity.x = dir * DASH_VELOCIDAD
	await get_tree().create_timer(DASH_DURACION).timeout
	if not is_inside_tree():
		return
	set_collision_mask_value(1, true)
	await get_tree().create_timer(0.8).timeout
	if not is_inside_tree():
		return
	puede_dashar = true

# --- PERKS ---
func activar_perk(nombre: String):
	match nombre:
		"dash":
			tiene_dash = true
		"salto_doble":
			tiene_salto_doble = true
		"vida_doble":
			salud = 200
		"rango":
			var forma = $RangoAtaque/CollisionShape2D.shape
			if forma is CircleShape2D:
				forma.radius *= 2.0

# --- FUNCIÓN AUXILIAR: enemigo más cercano ---
func _obtener_objetivo() -> Node2D:
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() == 0:
		return null
	var objetivo = enemigos[0]
	for e in enemigos:
		if global_position.distance_to(e.global_position) < global_position.distance_to(objetivo.global_position):
			objetivo = e
	return objetivo

# --- FUNCIÓN AUXILIAR: disparar proyectil ---
func _disparar(escena: PackedScene, objetivo: Node2D, dano: int):
	var bala = escena.instantiate()
	bala.dano = dano
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	bala.lanzar(global_position.direction_to(objetivo.global_position))

# --- DISPAROS ---
func _on_weapon_timer_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo:
		_disparar(proyectil_escena, objetivo, dano_ataque)

func _on_timer_fuego_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo:
		_disparar(proyectil_fuego_escena, objetivo, 2)

func _on_timer_hielo_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo:
		_disparar(proyectil_hielo_escena, objetivo, 0)

func _on_timer_rayo_timeout():
	var objetivo = _obtener_objetivo()
	if not objetivo:
		return
	var rayo = proyectil_rayo_escena.instantiate()
	get_tree().current_scene.add_child(rayo)
	rayo.global_position = Vector2(objetivo.global_position.x, objetivo.global_position.y - 300)
	rayo.lanzar(Vector2.DOWN)

func _on_timer_veneno_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo:
		_disparar(proyectil_veneno_escena, objetivo, 0)

# --- XP Y NIVELES ---
func ganar_xp(cantidad):
	xp_actual += cantidad
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.actualizar_xp(xp_actual, xp_necesaria)
	if xp_actual >= xp_necesaria:
		subir_nivel()

func subir_nivel():
	nivel += 1
	xp_actual = 0
	xp_necesaria += 2

	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.actualizar_xp(0, xp_necesaria)
		hud.actualizar_nivel(nivel)

	# Jefe en nivel 10
	if nivel == 10:
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo:
			mundo.spawner_jefe_pentagono()
		return  # No mostrar menú en nivel de jefe

	get_tree().paused = true
	var menu = get_tree().get_first_node_in_group("menu_nivel")

	if nivel == 5 or nivel == 15:
		if hud:
			hud.mostrar_mensaje("¡Nueva habilidad desbloqueada!")
		menu.configurar_modo_habilidades()
	else:
		menu.configurar_modo_atributos()

	menu.show()

# --- DESBLOQUEAR HABILIDAD ---
func desbloquear_habilidad(nombre: String):
	if habilidad_1 == "":
		habilidad_1 = nombre
		nivel_habilidad_1 = 1
		_activar_timer_habilidad(nombre)
	elif habilidad_2 == "":
		habilidad_2 = nombre
		nivel_habilidad_2 = 1
		_activar_timer_habilidad(nombre)

func _activar_timer_habilidad(nombre: String):
	match nombre:
		"fuego":  $TimerFuego.start()
		"hielo":  $TimerHielo.start()
		"rayo":   $TimerRayo.start()
		"veneno": $TimerVeneno.start()

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
