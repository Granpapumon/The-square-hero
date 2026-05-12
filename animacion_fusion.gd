extends Control

var color_habilidad_1 = Color.RED # Ejemplo: Habilidad 1
var color_habilidad_2 = Color.BLUE # Ejemplo: Habilidad 2
var color_fusionado = Color.WHITE

var pos_1 = Vector2.ZERO
var pos_2 = Vector2.ZERO
var pos_centro = Vector2.ZERO

var radio_1 = 30.0
var radio_2 = 30.0
var radio_fusion = 0.0

var fase = 0 # 0: inicio, 1: fusionando, 2: explosion
var destello = 0.0

func _ready():
	# ¡CRUCIAL! Esto permite que la animación se mueva aunque el mundo esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	# Mezclamos los dos colores matemáticamente al 50%
	color_fusionado = color_habilidad_1.lerp(color_habilidad_2, 0.5)
	
	# Preparamos las posiciones basadas en el tamaño de la pantalla
	var pantalla = get_viewport().get_visible_rect().size
	pos_centro = pantalla / 2.0
	pos_1 = Vector2(pantalla.x * 0.2, pos_centro.y) # Izquierda
	pos_2 = Vector2(pantalla.x * 0.8, pos_centro.y) # Derecha
	
	animar_secuencia()

func animar_secuencia():
	var tween = create_tween()
	
	# Fase 1: Las esferas se acercan lentamente al centro
	tween.tween_property(self, "pos_1", pos_centro, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "pos_2", pos_centro, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	# Fase 2: Chocan, desaparecen las originales y crece la nueva esfera mezclada
	tween.tween_callback(func(): fase = 1)
	tween.tween_property(self, "radio_fusion", 70.0, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Fase 3: Destello final (Flash blanco)
	tween.tween_callback(func(): fase = 2)
	tween.tween_property(self, "destello", 1.0, 0.3)
	tween.tween_property(self, "destello", 0.0, 0.5)
	
	# Finalizar: Reactivar el juego y avisar al jugador
	tween.tween_callback(finalizar_evento)

func finalizar_evento():
	# 1. Aplicamos la habilidad al jugador (Aquí conectaremos la lógica real de disparo luego)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("activar_fusion"):
		player.activar_fusion(color_fusionado)
	
	# 2. Despausamos el mundo y reactivamos los spawns
	var mundo = get_tree().get_first_node_in_group("mundo")
	if mundo: mundo.jefe_activo = false 
	get_tree().paused = false
	
	# 3. Borramos la animación
	queue_free()

func _process(_delta):
	queue_redraw() # Actualiza el dibujo 60 veces por segundo

func _draw():
	# Dibujamos un fondo semitransparente para ocultar un poco el caos del nivel
	draw_rect(get_viewport().get_visible_rect(), Color(0, 0, 0, 0.7))
	
	if fase == 0:
		# Dibujamos las dos habilidades originales acercándose
		draw_circle(pos_1, radio_1, color_habilidad_1)
		draw_circle(pos_2, radio_2, color_habilidad_2)
	elif fase >= 1:
		# Dibujamos la nueva habilidad fusionada
		var color_actual = color_fusionado
		if fase == 2:
			# Aplicamos el destello blanco
			color_actual = color_fusionado.lerp(Color.WHITE, destello)
		draw_circle(pos_centro, radio_fusion, color_actual)

# En animacion_fusion.gd, añade esto arriba:
var color_final_definido = Color.WHITE

# Añade esta función para recibir los datos desde el mundo
func configurar_colores(c1: Color, c2: Color, cf: Color):
	color_habilidad_1 = c1
	color_habilidad_2 = c2
	color_final_definido = cf
	# Actualizamos el color_fusionado para que sea el de tu tabla
	color_fusionado = cf
