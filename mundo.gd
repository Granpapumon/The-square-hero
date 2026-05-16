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
@onready var escena_jefe_decagono  = preload("res://jefe_decagono.tscn")
@onready var escena_jefe_cubo      = preload("res://jefe_cubo.tscn")
@onready var escena_jefe_cubo_no_hit    = preload("res://jefe_cubo_no_hit.tscn")
@onready var escena_jefe_cubo_verdadero = preload("res://jefe_cubo_verdadero.tscn")

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
		elif player.nivel == 30: # NUEVO JEFE
			spawnear_jefe_3()

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
	if player.nivel == 30:
		# Detenemos todo para la aparición del jefe final
		jefe_activo = true
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud: hud.mostrar_mensaje("C A R G A N D O   A N O M A L Í A   3 D . . .")
		
		# Esperamos 3 segundos de suspenso antes de spawnearlo
		await get_tree().create_timer(3.0).timeout
		spawnear_jefe_final()

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
	# Fijamos la semilla para que los adornos aleatorios no "parpadeen" en cada frame
	seed(12345) 
	
	var ancho_total = 3200.0
	var alto_total = 120.0 # Más delgado para parecer plataforma flotante
	var offset_x = -ancho_total / 2.0
	var y_suelo = 16.0
	
	# --- PALETA DE COLORES JAPONESA / PIXEL ART ---
	var color_piedra_base = Color(0.65, 0.68, 0.70) # Gris piedra claro
	var color_piedra_sombra = Color(0.48, 0.52, 0.55) # Gris oscuro para profundidad
	var color_borde = Color(0.25, 0.28, 0.30) # Contorno inferior muy oscuro
	var color_musgo_base = Color(0.20, 0.60, 0.30) # Verde intenso del musgo
	var color_musgo_brillo = Color(0.45, 0.85, 0.45) # Brillo superior del pasto
	var color_hiedra = Color(0.15, 0.45, 0.25) # Enredaderas colgantes oscuras
	var color_cerezo = Color(1.0, 0.65, 0.80) # Rosa de los pétalos caídos
	
	# 1. Borde oscuro que envuelve toda la plataforma flotante
	draw_rect(Rect2(offset_x - 4, y_suelo - 4, ancho_total + 8, alto_total + 8), color_borde)
	
	# 2. Base sólida de la plataforma de piedra
	draw_rect(Rect2(offset_x, y_suelo, ancho_total, alto_total), color_piedra_base)
	
	# 3. Ladrillos de piedra labrada (Efecto muro de templo)
	var tile_w = 48.0
	var tile_h = 24.0
	for y in range(int(y_suelo), int(y_suelo + alto_total), int(tile_h)):
		for x in range(int(offset_x), int(offset_x + ancho_total), int(tile_w)):
			var desfase = (tile_w / 2.0) if int((y - y_suelo) / tile_h) % 2 != 0 else 0.0
			var px = x + desfase
			if px < offset_x + ancho_total:
				# Contorno del bloque
				draw_rect(Rect2(px, y, tile_w, tile_h), color_piedra_sombra, false, 2.0)
				# Sombra interior (efecto de profundidad en 3D)
				draw_rect(Rect2(px + 2, y + tile_h - 6, tile_w - 4, 6), color_piedra_sombra)

	# 4. Hiedra colgando por debajo de la plataforma
	var ancho_hiedra = 12.0
	for x in range(int(offset_x), int(offset_x + ancho_total), int(ancho_hiedra)):
		if randf() > 0.4: # 60% de probabilidad de generar hiedra aquí
			var largo_hiedra = randf_range(20.0, 80.0)
			draw_rect(Rect2(x, y_suelo + alto_total, 6.0, largo_hiedra), color_hiedra)
			draw_rect(Rect2(x + 2, y_suelo + alto_total, 2.0, largo_hiedra - 10.0), color_musgo_base)

	# 5. Musgo y césped en la superficie (donde pisan los personajes)
	var ancho_musgo = 16.0
	for x in range(int(offset_x), int(offset_x + ancho_total), int(ancho_musgo)):
		# Variación de altura para que se vea irregular y orgánico
		var alto_musgo = 20.0 if int(floor(float(x) / ancho_musgo)) % 3 == 0 else 12.0
		# Caída del musgo sobre la piedra
		draw_rect(Rect2(x, y_suelo - 2, ancho_musgo, alto_musgo), color_musgo_base)
		# Borde superior brillante
		draw_rect(Rect2(x, y_suelo - 4, ancho_musgo, 6), color_musgo_brillo)
		
		# 6. Flores de Cerezo (Pétalos esparcidos en el suelo)
		if randf() > 0.65:
			draw_rect(Rect2(x + randf_range(2, 10), y_suelo + randf_range(-2, 6), 4, 4), color_cerezo)
			if randf() > 0.5: # Ocasionalmente dibuja pares de pétalos
				draw_rect(Rect2(x + randf_range(2, 10), y_suelo + randf_range(-2, 6), 4, 4), color_cerezo)

	# 7. Linternas Japonesas de Piedra (Tōrō) en el fondo
	var separacion_linternas = 350.0 # Posiciona una linterna cada 350 píxeles
	for x in range(int(offset_x + 100), int(offset_x + ancho_total), int(separacion_linternas)):
		var bx = x
		var by = y_suelo - 4 # Apoyadas sobre la capa de musgo
		var luz_linterna = Color(1.0, 0.9, 0.4) # Luz cálida
		
		# Base y pedestal
		draw_rect(Rect2(bx - 12, by - 10, 24, 10), color_piedra_sombra)
		draw_rect(Rect2(bx - 6, by - 30, 12, 20), color_piedra_base)
		draw_rect(Rect2(bx - 16, by - 38, 32, 8), color_piedra_sombra)
		
		# Caja de luz y la llama
		draw_rect(Rect2(bx - 10, by - 58, 20, 20), color_piedra_base)
		draw_rect(Rect2(bx - 6, by - 54, 12, 12), luz_linterna) 
		
		# Techo tradicional curvo de templo
		draw_rect(Rect2(bx - 24, by - 66, 48, 8), color_piedra_sombra)
		draw_rect(Rect2(bx - 18, by - 74, 36, 8), color_piedra_sombra)
		draw_rect(Rect2(bx - 4, by - 82, 8, 8), color_piedra_base)

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
func spawnear_jefe_3():
	jefe_activo = true
	var jefe = escena_jefe_decagono.instantiate()
	
	# Lo posicionamos un poco más lejos para que el jugador tenga tiempo de reaccionar
	jefe.global_position = player.global_position + Vector2(700, -200)
	add_child(jefe)
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.mostrar_mensaje("🛑 ¡JEFE DECÁGONO DETECTADO! 🛑")

func spawnear_jefe_final():
	var jefe = escena_jefe_cubo.instantiate()
	jefe.global_position = player.global_position + Vector2(600, -100)
	add_child(jefe)

var jefe_no_hit_desbloqueado = false

func desbloquear_jefe_no_hit():
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud: hud.mostrar_mensaje("⚠ ANOMALÍA SUPERIOR DETECTADA ⚠")
	
	# Spawnear el Cubo No-Hit después de un breve momento
	await get_tree().create_timer(2.0).timeout
	var jefe = escena_jefe_cubo_no_hit.instantiate()
	jefe.global_position = player.global_position + Vector2(600, -100)
	add_child(jefe)

func evaluar_cubo_verdadero():
	# Esta función la llamará el Cubo No-Hit al morir
	if not player.recibio_dano_toda_la_partida:
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud: hud.mostrar_mensaje("👁 EL VERDADERO DIOS DE LA FORMA DESPIERTA 👁")
		
		await get_tree().create_timer(3.0).timeout
		var jefe = escena_jefe_cubo_verdadero.instantiate()
		jefe.global_position = player.global_position + Vector2(0, -300) # Aparece desde arriba
		add_child(jefe)
	else:
		# Si recibió daño en algún nivel anterior, el juego simplemente termina aquí
		var hud = get_tree().get_first_node_in_group("HUD")
		if hud: hud.mostrar_mensaje("J U E G O   T E R M I N A D O")
