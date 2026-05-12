extends Node2D

@onready var player = get_tree().get_first_node_in_group("player")

@onready var escena_triangulo      = preload("res://enemigo_triangulo.tscn")
@onready var escena_rectangulo     = preload("res://enemigo_rectangulo.tscn")
@onready var escena_pentagono      = preload("res://enemigo_pentagono.tscn")
@onready var escena_hexagono       = preload("res://enemigo_hexagono.tscn")
@onready var escena_heptagono      = preload("res://enemigo_heptagono.tscn")
@onready var escena_octagono       = preload("res://enemigo_octagono.tscn")
@onready var escena_jefe_pentagono = preload("res://jefe_pentagono.tscn")
@onready var escena_estrella       = preload("res://enemigo_estrella.tscn")
@onready var escena_rombo          = preload("res://enemigo_rombo.tscn")
@onready var escena_trapecio       = preload("res://enemigo_trapecio.tscn")
@onready var escena_jefe_heptagono = preload("res://jefe_heptagono.tscn")
@onready var escena_circulo        = preload("res://enemigo_circulo.tscn")




const MAX_ENEMIGOS = 25
var jefe_activo = false
var estrella_spawneada = false
var ultimo_nivel_visto = 0
var estrellas_creadas_en_este_nivel = 0

func _ready():
	add_to_group("mundo")

func _obtener_escena_enemigo() -> PackedScene:
	var nivel = player.nivel
	if nivel <= 5:    return escena_triangulo
	elif nivel <= 10: return escena_rectangulo
	elif nivel <= 15: return escena_pentagono
	elif nivel <= 20: return escena_hexagono
	elif nivel <= 25: return escena_heptagono
	else:             return escena_octagono

func _on_spawner_timeout() -> void:
	if not is_instance_valid(player) or jefe_activo:
		return

	# --- RESETEAR CONTADOR AL SUBIR DE NIVEL ---
	if player.nivel != ultimo_nivel_visto:
		ultimo_nivel_visto = player.nivel
		estrellas_creadas_en_este_nivel = 0
		
		# --- DETECTAR JEFES Y EVENTOS ESPECIALES ---
		if player.nivel == 20:
			spawnear_jefe_2()
		elif player.nivel == 25:
			iniciar_evento_fusion() # Dispara la fusión de habilidades

	# --- CONTROL DE ÉLITES POR TRAMOS ---
	var niveles_estrella = [4, 6]
	var niveles_rombo = [12, 14]
	var niveles_trapecio = [17, 19]
	var niveles_circulo = [22, 24] # NUEVO TRAMO
	
	if player.nivel in niveles_estrella or player.nivel in niveles_rombo or player.nivel in niveles_trapecio or player.nivel in niveles_circulo:
		if estrellas_creadas_en_este_nivel < 2:
			if get_tree().get_nodes_in_group("elites").size() < 1:
				var nuevo_elite = null
				var nombre_alerta = ""
				
				if player.nivel in niveles_estrella:
					nuevo_elite = escena_estrella.instantiate()
					nombre_alerta = "⚠ ¡ELITE: ESTRELLA ("
				elif player.nivel in niveles_rombo:
					nuevo_elite = escena_rombo.instantiate()
					nombre_alerta = "⚠ ¡ELITE: ROMBO ("
				elif player.nivel in niveles_trapecio:
					nuevo_elite = escena_trapecio.instantiate()
					nombre_alerta = "⚠ ¡ELITE: TRAPECIO ("
				elif player.nivel in niveles_circulo:
					# Asegúrate de agregar @onready var escena_circulo = preload("res://enemigo_circulo.tscn") arriba
					nuevo_elite = escena_circulo.instantiate() 
					nombre_alerta = "⭕ ¡ELITE: CÍRCULO ("
				
				if nuevo_elite:
					nuevo_elite.add_to_group("elites")
					nuevo_elite.global_position = $GeneradorSuelo.obtener_posicion_segura(player.global_position.x)
					add_child(nuevo_elite)
					estrellas_creadas_en_este_nivel += 1
					
					var hud = get_tree().get_first_node_in_group("HUD")
					if hud:
						hud.mostrar_mensaje(nombre_alerta + str(estrellas_creadas_en_este_nivel) + "/2)!")

	# --- SPAWN DE HORDAS ---
	if get_tree().get_nodes_in_group("enemigos").size() >= MAX_ENEMIGOS:
		return
		
	var nuevo_enemigo = _obtener_escena_enemigo().instantiate()
	nuevo_enemigo.global_position = $GeneradorSuelo.obtener_posicion_segura(player.global_position.x)
	add_child(nuevo_enemigo)

func spawner_jefe_pentagono():
	jefe_activo = true
	for e in get_tree().get_nodes_in_group("enemigos"):
		e.queue_free()
	var jefe = escena_jefe_pentagono.instantiate()
	jefe.global_position = $GeneradorSuelo.obtener_posicion_segura(player.global_position.x)
	add_child(jefe)
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.mostrar_mensaje("⚠ ¡JEFE APARECE!")

func jefe_derrotado():
	jefe_activo = false
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.mostrar_mensaje("¡JEFE DERROTADO!")

func spawnear_jefe_2():
	jefe_activo = true
	var jefe = escena_heptagono.instantiate()
	# Lo posicionamos a una distancia justa del jugador
	jefe.global_position = player.global_position + Vector2(600, -200)
	add_child(jefe)
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.mostrar_mensaje("🛑 ¡JEFE HEPTÁGONO DETECTADO! 🛑")

func _process(_delta):
	queue_redraw()

func _draw():
	var ancho_total = 3200.0
	var alto_total = 200.0
	var offset_x = -ancho_total / 2.0
	var y_suelo = 16.0
	draw_rect(Rect2(offset_x - 4, y_suelo - 4, ancho_total + 8, alto_total + 8), Color.BLACK)
	draw_rect(Rect2(offset_x, y_suelo, ancho_total, alto_total), Color(0.12, 0.1, 0.15))
	var tile_size = 64.0
	for x in range(int(offset_x), int(offset_x + ancho_total), int(tile_size)):
		if int(floor(float(x) / tile_size)) % 3 == 0:
			draw_circle(Vector2(x + 32, y_suelo + 60), 10, Color(0.2, 0.18, 0.25))
			draw_circle(Vector2(x + 10, y_suelo + 120), 15, Color(0.18, 0.15, 0.22))
	var pixel_hierba = 16.0
	for x in range(int(offset_x), int(offset_x + ancho_total), int(pixel_hierba)):
		var altura_h = 24.0 if int(floor(float(x) / pixel_hierba)) % 2 == 0 else 16.00
		draw_rect(Rect2(x, y_suelo, pixel_hierba, altura_h + 4), Color(0.05, 0.3, 0.1))
		draw_rect(Rect2(x, y_suelo, pixel_hierba, altura_h), Color(0.1, 0.7, 0.2))
		draw_rect(Rect2(x, y_suelo, pixel_hierba, 6), Color(0.4, 0.9, 0.3))

func iniciar_evento_fusion():
	# 1. Pausamos el mundo y activamos el estado de jefe (detiene spawns)
	get_tree().paused = true 
	jefe_activo = true 
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud: 
		hud.mostrar_mensaje("✨ ¡FUSIÓN DE HABILIDADES! ✨")
	
	# 2. Obtenemos la referencia al jugador para leer sus habilidades
	if is_instance_valid(player):
		# Creamos la clave para buscar en el diccionario (ej: "fuego_hielo")
		var clave = player.habilidad_slot_1 + "_" + player.habilidad_slot_2
		
		# Buscamos el color resultante en el diccionario del jugador
		# .get() nos permite dar un color por defecto (Blanco) si la clave no existe
		var color_resultado = player.diccionario_colores_fusion.get(clave, Color.WHITE)
		
		# 3. Instanciamos la animación
		var animacion_escena = preload("res://animacion_fusion.tscn")
		var animacion = animacion_escena.instantiate()
		
		# Pasamos los datos dinámicos a la animación antes de añadirla al mundo
		animacion.color_habilidad_1 = player.color_slot_1
		animacion.color_habilidad_2 = player.color_slot_2
		
		# Si quieres que la animación use el color exacto del diccionario para el resultado final:
		if animacion.has_method("configurar_colores"):
			animacion.configurar_colores(player.color_slot_1, player.color_slot_2, color_resultado)
		else:
			# Si no tienes esa función, solo asignamos los colores base
			animacion.color_habilidad_1 = player.color_slot_1
			animacion.color_habilidad_2 = player.color_slot_2
			# Opcionalmente, puedes añadir una variable en el script de la animación para el color final
			# animacion.color_final_definido = color_resultado
		
		# Pegamos la animación directamente en el HUD para que siga la cámara
		if hud:
			hud.add_child(animacion)
		else:
			add_child(animacion)
