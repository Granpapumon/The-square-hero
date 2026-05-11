extends StaticBody2D

@onready var colision = $CollisionShape2D

# Variables de dimensiones
var ancho_plataforma = 0.0
var grosor = 100.0
var grosor_borde = 8.0 # El borde negro grueso de tu estilo

# Colores extraídos aproximados de tu imagen
var color_pasto = Color("6abe30") # Verde vivo
var color_tierra = Color("5a3921") # Marrón tierra
var color_borde = Color.BLACK

func configurar(ancho: float):
	ancho_plataforma = ancho
	
	# La colisión se mantiene plana y perfecta
	var shape = RectangleShape2D.new()
	shape.size = Vector2(ancho, grosor)
	colision.shape = shape
	
	queue_redraw() # Pide a Godot que dibuje todo

func _draw():
	if ancho_plataforma == 0: return
	
	var pos_x = -ancho_plataforma / 2.0
	var pos_y = -grosor / 2.0
	
	# --- 1. DIBUJAR LAS SILUETAS NEGRAS (Bordes) ---
	
	# A) El rectángulo principal negro
	var rect_borde = Rect2(pos_x, pos_y, ancho_plataforma, grosor)
	draw_rect(rect_borde, color_borde)
	
	# B) Los picos negros (la silueta de la yerbita)
	var separacion = 40.0 # Qué tan separadas están las yerbitas
	var num_yerbitas = int(ancho_plataforma / separacion)
	var yerbitas_x = [] # Guardamos las posiciones para pintarlas de verde luego
	
	for i in range(num_yerbitas):
		# Distribuimos el pasto a lo largo del ancho
		var offset_x = pos_x + 20 + (i * separacion)
		yerbitas_x.append(offset_x)
		
		# Dibujamos un triángulo negro hacia arriba (fuera de la plataforma)
		var p_negro = PackedVector2Array([
			Vector2(offset_x - 12, pos_y + 1), # Base izquierda
			Vector2(offset_x, pos_y - 18),     # Punta alta
			Vector2(offset_x + 12, pos_y + 1)  # Base derecha
		])
		draw_colored_polygon(p_negro, color_borde)
		
	# --- 2. DIBUJAR LOS COLORES INTERIORES ---
	
	var pos_interior_x = pos_x + grosor_borde
	var pos_interior_y = pos_y + grosor_borde
	var ancho_interior = ancho_plataforma - (grosor_borde * 2)
	
	# C) La Tierra (Rectángulo marrón que cubre todo el interior)
	var alto_interior = grosor - (grosor_borde * 2)
	var rect_tierra = Rect2(pos_interior_x, pos_interior_y, ancho_interior, alto_interior)
	draw_rect(rect_tierra, color_tierra)
	
	# D) El Pasto Base (Rectángulo verde en la parte superior de la tierra)
	var profundidad_pasto = 25.0
	var rect_pasto = Rect2(pos_interior_x, pos_interior_y, ancho_interior, profundidad_pasto)
	draw_rect(rect_pasto, color_pasto)
	
	# E) Rellenar los picos de pasto de color verde
	for offset_x in yerbitas_x:
		# Dibujamos un triángulo verde más pequeño dentro del triángulo negro
		var p_verde = PackedVector2Array([
			Vector2(offset_x - 7, pos_interior_y), # Base izquierda interior
			Vector2(offset_x, pos_y - 10),         # Punta verde (más baja que la negra)
			Vector2(offset_x + 7, pos_interior_y)  # Base derecha interior
		])
		draw_colored_polygon(p_verde, color_pasto)
