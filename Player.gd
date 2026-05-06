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
var invulnerable = false 
var tiene_dash = false
var dasheando = false
var tiene_salto_doble = false
var puede_dashar = true
var saltos_restantes = 1
const DASH_VELOCIDAD = 3000.0
const DASH_DURACION = 0.05

# --- PERSONALIDAD Y EXPRESIONES ---
var direccion_mirada = Vector2.RIGHT 
var expresion_actual = "normal" 
var id_expresion = 0 

# --- SISTEMA VISUAL (NUEVO) ---
var particulas_correr: CPUParticles2D # Nube de polvo continua tipo Sonic

# --- ESCENAS ---
@onready var proyectil_escena        = preload("res://proyectil.tscn")
@onready var proyectil_fuego_escena  = preload("res://proyectil_fuego.tscn")
@onready var proyectil_hielo_escena  = preload("res://proyectil_hielo.tscn")
@onready var proyectil_rayo_escena   = preload("res://proyectil_rayo.tscn")
@onready var proyectil_veneno_escena = preload("res://proyectil_veneno.tscn")

func _ready():
	if has_node("Sprite2D"):
		$Sprite2D.show_behind_parent = true
		
	# --- INICIALIZAMOS EL POLVO CONTINUO DE CORRER ---
	particulas_correr = CPUParticles2D.new()
	particulas_correr.emitting = false
	particulas_correr.amount = 30
	particulas_correr.lifetime = 0.3
	particulas_correr.gravity = Vector2(0, -20) # Sube ligeramente
	particulas_correr.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particulas_correr.emission_rect_extents = Vector2(20, 2)
	# Los pies están a 64 píxeles hacia abajo desde el centro
	particulas_correr.position = Vector2(0, 64) 
	
	var grad_correr = Gradient.new()
	grad_correr.set_color(0, Color(0.9, 0.9, 0.9, 0.6))
	grad_correr.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	particulas_correr.color_ramp = grad_correr
	particulas_correr.scale_amount_min = 4.0
	particulas_correr.scale_amount_max = 10.0
	particulas_correr.z_index = -1
	add_child(particulas_correr)
	# Solo llama a esto cuando REALMENTE quieras abrir el menú
	var p_perks = get_tree().get_first_node_in_group("pantalla_perks")
	if p_perks:
		p_perks.get_parent().show() # Muestra el CanvasLayer raíz

func _process(_delta):
	# EYE TRACKING
	var objetivo = _obtener_objetivo()
	if is_instance_valid(objetivo):
		direccion_mirada = global_position.direction_to(objetivo.global_position)
	else:
		var dir_mov = Input.get_axis("ui_left", "ui_right")
		if dir_mov != 0:
			direccion_mirada = Vector2(dir_mov, 0)
			
	queue_redraw()

# --- SISTEMA DE EMOCIONES ---
func cambiar_expresion(nueva_expresion: String, duracion: float):
	expresion_actual = nueva_expresion
	id_expresion += 1
	var id_actual = id_expresion
	
	queue_redraw() 
	await get_tree().create_timer(duracion).timeout
	
	if id_actual == id_expresion:
		expresion_actual = "normal"
		queue_redraw()

# --- VIDA ---
func recibir_daño(cantidad):
	if invulnerable: return 
		
	salud -= cantidad
	print("DAÑO RECIBIDO: ", cantidad, " - Salud restante: ", salud)
	
	cambiar_expresion("dolor", 0.6)
	
	$Sprite2D.modulate = Color(1, 0, 0) 
	$Sprite2D.scale = Vector2(1.4, 0.6) 
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true) 
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1), 0.3)
	tween.tween_property($Sprite2D, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	if salud <= 0: morir()

func morir():
	get_tree().reload_current_scene()

# --- MOVIMIENTO ---
func _physics_process(delta):
	var estaba_en_aire = !is_on_floor() 
	move_and_slide()
	
	# AL ATERRIZAR (SMASH IMPACT)
	if estaba_en_aire and is_on_floor():
		$Sprite2D.scale = Vector2(1.4, 0.6) 
		var landing_tween = get_tree().create_tween()
		landing_tween.tween_property($Sprite2D, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		crear_polvo("aterrizaje")

	if is_on_floor():
		saltos_restantes = 2 if tiene_salto_doble else 1

	if not is_on_floor() and not dasheando:
		velocity.y += gravedad * delta

	# AL SALTAR (MARIO UP-B)
	if Input.is_action_just_pressed("ui_accept") and saltos_restantes > 0:
		velocity.y = fuerza_salto
		saltos_restantes -= 1
		
		$GPUParticles2D.restart() 
		$GPUParticles2D.emitting = true 
		crear_polvo("salto")
		
		$Sprite2D.scale = Vector2(0.6, 1.4) 
		var tween = get_tree().create_tween()
		tween.tween_property($Sprite2D, "scale", Vector2(1, 1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if tiene_dash and puede_dashar and Input.is_action_just_pressed("dash"):
		var dir = Input.get_axis("ui_left", "ui_right")
		if dir != 0: _ejecutar_dash(dir)

	if not dasheando:
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * velocidad_actual
		else:
			velocity.x = move_toward(velocity.x, 0, velocidad_actual)

	move_and_slide()
	
	# --- ANIMACIONES CONTINUAS (ESTILO SONIC) ---
	var target_rotation = 0.0
	if is_on_floor() and not dasheando:
		# Se inclina hacia adelante al correr
		target_rotation = (velocity.x / velocidad_actual) * 0.25 
		
		# Activa el rastro de polvo de los pies si corre rápido
		if abs(velocity.x) > 10:
			particulas_correr.emitting = true
			particulas_correr.direction = Vector2(-sign(velocity.x), -0.2)
			particulas_correr.initial_velocity_min = 50.0
			particulas_correr.initial_velocity_max = 120.0
		else:
			particulas_correr.emitting = false
	elif dasheando:
		# Inclinación masiva estilo misil durante el dash
		target_rotation = sign(velocity.x) * 0.4 
		particulas_correr.emitting = false
	else:
		# En el aire recupera la compostura, o se inclina un poco hacia donde salta
		target_rotation = (velocity.x / velocidad_actual) * 0.1 
		particulas_correr.emitting = false

	# Aplica la rotación suavemente
	$Sprite2D.rotation = lerp_angle($Sprite2D.rotation, target_rotation, 15.0 * delta)

func _ejecutar_dash(dir: float):
	puede_dashar = false
	dasheando = true
	invulnerable = true
	modulate.a = 0.5 
	velocity.y = 0 
	
	$CollisionShape2D.set_deferred("disabled", true)
	velocity.x = dir * DASH_VELOCIDAD
	
	cambiar_expresion("esquivar", 1.0)
	crear_polvo("dash", dir)
	
	await get_tree().create_timer(DASH_DURACION).timeout
	if not is_inside_tree(): return
		
	for i in range(10):
		crear_fantasma_dash()
		await get_tree().create_timer(DASH_DURACION / 10).timeout
	
	if not is_instance_valid(self): return
		
	dasheando = false
	invulnerable = false 
	modulate.a = 1.0 
	$CollisionShape2D.set_deferred("disabled", false)
	
	await get_tree().create_timer(0.8).timeout
	if not is_instance_valid(self): return
	puede_dashar = true

# --- DIBUJANDO EL CUERPO Y LA INCLINACIÓN (ESTILO PIN ESMALTADO) ---
func _draw():
	draw_set_transform(Vector2.ZERO, $Sprite2D.rotation, $Sprite2D.scale)
	
	var offset_ojos = direccion_mirada * 12.0 
	var direccion_colas = -1 if direccion_mirada.x >= 0 else 1
	var v_caotico_1 = randf_range(-8, 8)
	var v_caotico_2 = randf_range(-8, 8)
	
	var color_cuerpo = Color(0.2, 0.6, 0.86)
	var color_banda = Color(0.9, 0.1, 0.1) 
	
	if expresion_actual == "poder":
		color_cuerpo = Color(1.0, 0.85, 0.0) 
		color_banda = Color(1.0, 0.4, 0.0) 
		v_caotico_1 *= 3.0
		v_caotico_2 *= 3.0
	
	# 1. CUERPO (Borde negro, relleno, brillo y sombra para efecto vector/pin)
	draw_rect(Rect2(-64, -64, 128, 128), Color.BLACK) # Borde grueso
	draw_rect(Rect2(-56, -56, 112, 112), color_cuerpo) # Color base
	draw_rect(Rect2(-56, -56, 112, 16), Color(1, 1, 1, 0.4)) # Brillo superior estilo Pin
	draw_rect(Rect2(-56, 40, 112, 16), Color(0, 0, 0, 0.3)) # Sombra inferior
	
	# 2. COLAS DE LA BANDA (Dibujamos línea negra ancha primero, luego la de color)
	# Cola 1
	draw_line(Vector2(60 * direccion_colas, -35), Vector2((110 * direccion_colas) + v_caotico_1, -55 + v_caotico_2), Color.BLACK, 20.0)
	draw_line(Vector2(60 * direccion_colas, -35), Vector2((110 * direccion_colas) + v_caotico_1, -55 + v_caotico_2), color_banda, 12.0)
	# Cola 2
	draw_line(Vector2(60 * direccion_colas, -35), Vector2((95 * direccion_colas) + v_caotico_2, -15 + v_caotico_1), Color.BLACK, 16.0)
	draw_line(Vector2(60 * direccion_colas, -35), Vector2((95 * direccion_colas) + v_caotico_2, -15 + v_caotico_1), color_banda, 8.0)
	
	# 3. FRENTE DE LA BANDA (Borde negro detrás, color al frente)
	draw_rect(Rect2(-64, -49, 128, 28), Color.BLACK)
	draw_rect(Rect2(-64, -45, 128, 20), color_banda)

	# 4. EXPRESIONES Y CARA
	match expresion_actual:
		"normal":
			draw_rect(Rect2(-42, -17, 28, 28), Color.BLACK) # Borde Ojo L
			draw_rect(Rect2(14, -17, 28, 28), Color.BLACK)  # Borde Ojo R
			draw_rect(Rect2(-40, -15, 24, 24), Color.WHITE)
			draw_rect(Rect2(16, -15, 24, 24), Color.WHITE)
			draw_rect(Rect2(-36 + offset_ojos.x, -11 + offset_ojos.y, 12, 12), Color.BLACK) 
			draw_rect(Rect2(20 + offset_ojos.x, -11 + offset_ojos.y, 12, 12), Color.BLACK) 
			draw_line(Vector2(-44, -25), Vector2(-16, -8), Color.BLACK, 8.0)
			draw_line(Vector2(44, -25), Vector2(16, -8), Color.BLACK, 8.0)
			draw_line(Vector2(-20, 25), Vector2(-8, 15), Color.BLACK, 8.0)
			draw_line(Vector2(-8, 15), Vector2(8, 25), Color.BLACK, 8.0)
			draw_line(Vector2(8, 25), Vector2(20, 15), Color.BLACK, 8.0)
			
		"dolor":
			draw_line(Vector2(-40, -15), Vector2(-20, -5), Color.BLACK, 8.0)
			draw_line(Vector2(-40, 5), Vector2(-20, -5), Color.BLACK, 8.0)
			draw_line(Vector2(40, -15), Vector2(20, -5), Color.BLACK, 8.0)
			draw_line(Vector2(40, 5), Vector2(20, -5), Color.BLACK, 8.0)
			draw_rect(Rect2(-24, 11, 48, 28), Color.BLACK)
			draw_rect(Rect2(-20, 15, 40, 20), Color(0.4, 0, 0)) # Boca abierta dolor
			
		"poder":
			draw_rect(Rect2(-42, -17, 28, 28), Color.BLACK)
			draw_rect(Rect2(14, -17, 28, 28), Color.BLACK)
			draw_rect(Rect2(-40, -15, 24, 24), Color.WHITE)
			draw_rect(Rect2(16, -15, 24, 24), Color.WHITE)
			draw_line(Vector2(-48, -30), Vector2(-12, -4), Color.BLACK, 12.0)
			draw_line(Vector2(48, -30), Vector2(12, -4), Color.BLACK, 12.0)
			draw_rect(Rect2(-29, 6, 58, 38), Color.BLACK)
			draw_rect(Rect2(-25, 10, 50, 30), Color(0.2, 0, 0)) 
			draw_rect(Rect2(-20, 15, 40, 20), Color.WHITE) 
			
		"esquivar":
			draw_rect(Rect2(-42, -17, 28, 28), Color.BLACK)
			draw_rect(Rect2(-40, -15, 24, 24), Color.WHITE)
			draw_rect(Rect2(-36 + offset_ojos.x, -11 + offset_ojos.y, 12, 12), Color.BLACK)
			draw_line(Vector2(-40, -25), Vector2(-20, -20), Color.BLACK, 8.0)
			draw_line(Vector2(16, -3), Vector2(40, -3), Color.BLACK, 8.0)
			draw_line(Vector2(16, -15), Vector2(40, -10), Color.BLACK, 8.0)
			draw_line(Vector2(-15, 30), Vector2(10, 25), Color.BLACK, 8.0)
			draw_line(Vector2(10, 25), Vector2(25, 10), Color.BLACK, 8.0)

# --- FÁBRICA DE POLVO DINÁMICO (SMASH BROS) ---
func crear_polvo(tipo: String, dir_x: float = 0.0):
	var polvo = CPUParticles2D.new()
	polvo.emitting = false
	polvo.one_shot = true
	# Base del personaje (128 de altura, pies en +64)
	polvo.global_position = global_position + Vector2(0, 64) 
	
	var grad = Gradient.new()
	grad.set_color(0, Color(0.9, 0.9, 0.9, 0.8))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	polvo.color_ramp = grad
	
	match tipo:
		"dash":
			polvo.explosiveness = 0.9
			polvo.amount = 25
			polvo.lifetime = 0.4
			polvo.direction = Vector2(-dir_x, -0.2)
			polvo.initial_velocity_min = 250.0
			polvo.initial_velocity_max = 500.0
			polvo.spread = 15.0
			polvo.scale_amount_min = 6.0
			polvo.scale_amount_max = 12.0
			
		"aterrizaje": # Nube de polvo gruesa y pesada 
			polvo.explosiveness = 0.95
			polvo.amount = 40
			polvo.lifetime = 0.5
			polvo.direction = Vector2(0, -1) # Dispara hacia arriba
			polvo.spread = 85.0 # Apertura lateral masiva
			polvo.initial_velocity_min = 150.0
			polvo.initial_velocity_max = 450.0
			polvo.scale_amount_min = 8.0
			polvo.scale_amount_max = 16.0
			polvo.gravity = Vector2(0, 300) # Cae agresivamente abrazando el piso
			
		"salto": # Impacto Mario Up-B
			polvo.explosiveness = 1.0
			polvo.amount = 15
			polvo.lifetime = 0.25
			polvo.direction = Vector2(0, 1) # Rebota contra el suelo
			polvo.spread = 30.0 # Ráfaga concentrada
			polvo.initial_velocity_min = 200.0
			polvo.initial_velocity_max = 400.0
			polvo.scale_amount_min = 5.0
			polvo.scale_amount_max = 10.0

	get_tree().current_scene.call_deferred("add_child", polvo)
	polvo.call_deferred("set_emitting", true)
	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(polvo.queue_free)

# --- SISTEMAS DE XP, MEJORAS Y DISPARO (IGUAL) ---
func activar_perk(nombre: String):
	match nombre:
		"dash": tiene_dash = true
		"salto_doble": tiene_salto_doble = true
		"vida_doble": salud = 200
		"rango":
			var forma = $RangoAtaque/CollisionShape2D.shape
			if forma is CircleShape2D: forma.radius *= 2.0

func _obtener_objetivo() -> Node2D:
	var enemigos = $RangoAtaque.get_overlapping_areas()
	if enemigos.size() == 0: return null
	var objetivo = enemigos[0]
	for e in enemigos:
		if global_position.distance_to(e.global_position) < global_position.distance_to(objetivo.global_position):
			objetivo = e
	return objetivo

func _disparar(escena: PackedScene, objetivo: Node2D, dano: int):
	var bala = escena.instantiate()
	bala.dano = dano
	get_tree().current_scene.add_child(bala)
	bala.global_position = global_position
	bala.lanzar(global_position.direction_to(objetivo.global_position))

func _on_weapon_timer_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo: _disparar(proyectil_escena, objetivo, dano_ataque)

func _on_timer_fuego_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo: _disparar(proyectil_fuego_escena, objetivo, 2)

func _on_timer_hielo_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo: _disparar(proyectil_hielo_escena, objetivo, 0)

func _on_timer_rayo_timeout():
	var objetivo = _obtener_objetivo()
	if not objetivo: return
	var rayo = proyectil_rayo_escena.instantiate()
	get_tree().current_scene.add_child(rayo)
	rayo.global_position = Vector2(objetivo.global_position.x, objetivo.global_position.y - 300)
	rayo.lanzar(Vector2.DOWN)

func _on_timer_veneno_timeout():
	var objetivo = _obtener_objetivo()
	if objetivo: _disparar(proyectil_veneno_escena, objetivo, 0)

func ganar_xp(cantidad):
	xp_actual += cantidad
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud: hud.actualizar_xp(xp_actual, xp_necesaria)
	if xp_actual >= xp_necesaria:
		subir_nivel()

func subir_nivel():
	nivel += 1
	xp_actual = 0
	xp_necesaria += 2
	
	cambiar_expresion("poder", 2.0)
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.actualizar_xp(0, xp_necesaria)
		hud.actualizar_nivel(nivel)
	if nivel == 10:
		var mundo = get_tree().get_first_node_in_group("mundo")
		if mundo: mundo.spawner_jefe_pentagono()
		return
		
	get_tree().paused = true
	var menu = get_tree().get_first_node_in_group("menu_nivel")
	if menu:
		menu.get_parent().show() # Mostramos el CanvasLayer (el padre)
		menu.configurar_modo_atributos() # Llamamos a la función en el Contenedor
	if nivel == 5 or nivel == 15:
		if hud: hud.mostrar_mensaje("¡Nueva habilidad desbloqueada!")
		menu.configurar_modo_habilidades()
	else:
		menu.configurar_modo_atributos()
	menu.show()

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

func mejorar_velocidad(): velocidad_actual = min(velocidad_actual + 50.0, 600.0)
func mejorar_salto(): fuerza_salto = max(fuerza_salto - 25.0, -1200.0)
func mejorar_ataque(): dano_ataque = min(dano_ataque + 1, 20)
func mejorar_cadencia():
	tiempo_disparo = max(tiempo_disparo - 0.042, 0.2)
	$WeaponTimer.wait_time = tiempo_disparo

func crear_fantasma_dash():
	# 1. Creamos un sprite temporal para el efecto
	var fantasma = Sprite2D.new()
	fantasma.texture = $Sprite2D.texture # Usamos la textura actual del player
	fantasma.global_position = global_position
	fantasma.modulate = Color(0.5, 0.5, 1.0, 0.6) # Color azulado semi-transparente
	# 2. Lo añadimos al mundo (no al player, para que se quede atrás)
	get_parent().add_child(fantasma)
	# 3. Lo desvanecemos y eliminamos automáticamente
	var tween = create_tween()
	tween.tween_property(fantasma, "modulate:a", 0.0, 0.4)
	tween.tween_callback(fantasma.queue_free)
# Cuando el jugador deba elegir un Perk:
	var p_perks = get_tree().get_first_node_in_group("pantalla_perks")
	if p_perks:
		p_perks.show()
