extends StaticBody2D

@onready var colision = $CollisionShape2D

# Variables de dimensiones originales
var ancho_plataforma = 0.0
var grosor = 120.0 # Ajustado un poco para que se vea como plataforma flotante

func configurar(ancho: float):
	ancho_plataforma = ancho
	
	# La colisión se mantiene plana y perfecta
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ancho, grosor)
	colision.shape = shape
	
	# Centramos la caja de colisión para que coincida con nuestro dibujo
	colision.position = Vector2(0, 0)
	
	queue_redraw() # Pide a Godot que dibuje todo

func _draw():
	if ancho_plataforma == 0: return
	
	# Usamos la posición X global de la plataforma como "semilla" matemática.
	# Así las enredaderas y pétalos no parpadean en cada frame y son únicos por bloque.
	seed(int(global_position.x)) 
	
	var offset_x = -ancho_plataforma / 2.0
	var pos_y = -grosor / 2.0
	
	# --- PALETA DE COLORES JAPONESA / PIXEL ART ---
	var color_piedra_base = Color(0.65, 0.68, 0.70)
	var color_piedra_sombra = Color(0.48, 0.52, 0.55)
	var color_borde = Color(0.25, 0.28, 0.30)
	var color_musgo_base = Color(0.20, 0.60, 0.30)
	var color_musgo_brillo = Color(0.45, 0.85, 0.45)
	var color_hiedra = Color(0.15, 0.45, 0.25)
	var color_cerezo = Color(1.0, 0.65, 0.80)
	
	# 1. Contorno oscuro general (silueta base)
	draw_rect(Rect2(offset_x - 4, pos_y - 4, ancho_plataforma + 8, grosor + 8), color_borde)
	
	# 2. Base de roca principal
	draw_rect(Rect2(offset_x, pos_y, ancho_plataforma, grosor), color_piedra_base)
	
	# 3. Textura de Ladrillos de templo
	var tile_w = 48.0
	var tile_h = 24.0
	for y in range(int(pos_y), int(pos_y + grosor), int(tile_h)):
		for x in range(int(offset_x), int(offset_x + ancho_plataforma), int(tile_w)):
			var desfase = (tile_w / 2.0) if int((y - pos_y) / tile_h) % 2 != 0 else 0.0
			var px = x + desfase
			if px < offset_x + ancho_plataforma:
				# Dibujo del bloque
				draw_rect(Rect2(px, y, tile_w, tile_h), color_piedra_sombra, false, 2.0)
				# Sombra interior (efecto de profundidad en 3D)
				draw_rect(Rect2(px + 2, y + tile_h - 6, tile_w - 4, 6), color_piedra_sombra)

	# 4. Hiedra flotando por debajo de las plataformas
	var ancho_hiedra = 12.0
	for x in range(int(offset_x), int(offset_x + ancho_plataforma), int(ancho_hiedra)):
		if randf() > 0.4:
			var largo_hiedra = randf_range(20.0, 80.0)
			draw_rect(Rect2(x, pos_y + grosor, 6.0, largo_hiedra), color_hiedra)
			draw_rect(Rect2(x + 2, pos_y + grosor, 2.0, largo_hiedra - 10.0), color_musgo_base)

	# 5. Césped superior y flores de cerezo esparcidas
	var ancho_musgo = 16.0
	for x in range(int(offset_x), int(offset_x + ancho_plataforma), int(ancho_musgo)):
		# Irregularidad en la altura del césped
		var alto_musgo = 20.0 if int(floor(float(x) / ancho_musgo)) % 3 == 0 else 12.0
		draw_rect(Rect2(x, pos_y - 2, ancho_musgo, alto_musgo), color_musgo_base)
		draw_rect(Rect2(x, pos_y - 4, ancho_musgo, 6), color_musgo_brillo)
		
		# Pétalos esparcidos al azar
		if randf() > 0.65:
			draw_rect(Rect2(x + randf_range(2, 10), pos_y + randf_range(-2, 6), 4, 4), color_cerezo)
			if randf() > 0.5:
				draw_rect(Rect2(x + randf_range(2, 10), pos_y + randf_range(-2, 6), 4, 4), color_cerezo)

	# 6. Linternas japonesas (Tōrō)
	var separacion_linternas = 350.0
	for x in range(int(offset_x + 100), int(offset_x + ancho_plataforma), int(separacion_linternas)):
		# Evitamos que la linterna se dibuje flotando fuera del borde derecho
		if x > offset_x + ancho_plataforma - 50: 
			continue
			
		var bx = float(x)
		var by = pos_y - 4.0
		var luz_linterna = Color(1.0, 0.9, 0.4)
		
		# Dibujado pieza por pieza de la linterna
		draw_rect(Rect2(bx - 12, by - 10, 24, 10), color_piedra_sombra)
		draw_rect(Rect2(bx - 6, by - 30, 12, 20), color_piedra_base)
		draw_rect(Rect2(bx - 16, by - 38, 32, 8), color_piedra_sombra)
		draw_rect(Rect2(bx - 10, by - 58, 20, 20), color_piedra_base)
		draw_rect(Rect2(bx - 6, by - 54, 12, 12), luz_linterna) 
		draw_rect(Rect2(bx - 24, by - 66, 48, 8), color_piedra_sombra)
		draw_rect(Rect2(bx - 18, by - 74, 36, 8), color_piedra_sombra)
		draw_rect(Rect2(bx - 4, by - 82, 8, 8), color_piedra_base)
