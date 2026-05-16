extends Node2D

var nubes = []
var player = null
var chunk_ancho = 3000.0 # Ancho del bucle de las montañas

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# Generamos las nubes iniciales con tamaños y velocidades aleatorias
	for i in range(18):
		nubes.append({
			"x": randf_range(0, 3000),
			"y": randf_range(20, 350),
			"vel": randf_range(10.0, 35.0),
			"escala": randf_range(1.5, 4.0)
		})

func _process(delta):
	# Movemos las nubes con el viento
	for nube in nubes:
		nube.x -= nube.vel * delta
		if nube.x < -300: # Si salen de la pantalla por la izquierda, reaparecen a la derecha
			nube.x = 3000
			nube.y = randf_range(20, 350)
			
	# Actualizamos el dibujo cada frame para que se mueva suave
	queue_redraw()

func _draw():
	var scroll_x = 0.0
	if is_instance_valid(player):
		scroll_x = player.global_position.x

	var w = 3000.0
	var h = 1500.0
	
	# --- 1. CIELO DEGRADADO (Fijo, no se mueve con la cámara) ---
	var color_alto = Color(0.15, 0.35, 0.8) # Azul profundo
	var color_bajo = Color(1.0, 0.8, 0.6)   # Rosa/Naranja amanecer
	var franjas = 30
	for i in range(franjas):
		var t = float(i) / float(franjas)
		draw_rect(Rect2(0, i * (h / franjas), w, (h / franjas) + 1), color_alto.lerp(color_bajo, t))
		
	# --- 2. EL SOL NACIENTE ---
	draw_circle(Vector2(500, 350), 120, Color(0.9, 0.2, 0.3))
	
	# --- 3. MONTAÑAS LEJANAS (Parallax Lento) ---
	var offset_lejos = wrapf(scroll_x * 0.05, 0.0, chunk_ancho)
	var color_lejos = Color(0.4, 0.45, 0.65) # Tonos azulados/morados por la atmósfera
	_dibujar_cadena_montañosa(-offset_lejos, color_lejos, 400.0, 900.0)
	_dibujar_cadena_montañosa(-offset_lejos + chunk_ancho, color_lejos, 400.0, 900.0)

	# --- 4. MONTAÑAS CERCANAS (Parallax Medio, Bosques) ---
	var offset_cerca = wrapf(scroll_x * 0.15, 0.0, chunk_ancho)
	var color_cerca = Color(0.25, 0.45, 0.35) # Verdes de pino oscurecidos
	_dibujar_cadena_montañosa_cercana(-offset_cerca, color_cerca, 550.0, 1000.0)
	_dibujar_cadena_montañosa_cercana(-offset_cerca + chunk_ancho, color_cerca, 550.0, 1000.0)

	# --- 5. NUBES PIXEL ART FLOTANTES ---
	var color_nube = Color(1.0, 1.0, 1.0, 0.95)
	var color_sombra = Color(0.9, 0.8, 0.85, 0.95) # Sombra rosada
	
	for nube in nubes:
		var nx = nube.x
		var ny = nube.y
		var s = nube.escala * 10.0 # Tamaño de bloque pixel art
		
		# Sombra de la nube
		draw_rect(Rect2(nx + s, ny + s*2, s*5, s*2), color_sombra)
		# Forma de nube pixel art
		draw_rect(Rect2(nx + s, ny + s, s*5, s*2), color_nube)
		draw_rect(Rect2(nx, ny + s*1.5, s*7, s*1.5), color_nube)
		draw_rect(Rect2(nx + s*2, ny, s*3, s), color_nube)

# Matemáticas para dibujar los picos de las montañas lejanas
func _dibujar_cadena_montañosa(x_ini: float, c: Color, alt_min: float, alt_base: float):
	var puntos = PackedVector2Array([
		Vector2(x_ini, alt_base),
		Vector2(x_ini + 300, alt_min),
		Vector2(x_ini + 650, alt_min + 200),
		Vector2(x_ini + 1100, alt_min - 50),
		Vector2(x_ini + 1500, alt_min + 300),
		Vector2(x_ini + 1900, alt_min + 100),
		Vector2(x_ini + 2400, alt_min + 350),
		Vector2(x_ini + 2800, alt_min + 150),
		Vector2(x_ini + 3000, alt_base)
	])
	draw_colored_polygon(puntos, c)

# Matemáticas para dibujar los picos de las montañas más cercanas
func _dibujar_cadena_montañosa_cercana(x_ini: float, c: Color, alt_min: float, alt_base: float):
	var puntos = PackedVector2Array([
		Vector2(x_ini, alt_base),
		Vector2(x_ini + 200, alt_min + 150),
		Vector2(x_ini + 500, alt_min),
		Vector2(x_ini + 900, alt_min + 250),
		Vector2(x_ini + 1300, alt_min - 20),
		Vector2(x_ini + 1800, alt_min + 200),
		Vector2(x_ini + 2200, alt_min + 50),
		Vector2(x_ini + 2600, alt_min + 300),
		Vector2(x_ini + 3000, alt_base)
	])
	draw_colored_polygon(puntos, c)
