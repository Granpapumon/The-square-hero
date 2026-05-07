class_name EfectoExplosion
extends Node2D

var particulas = []
var forma = "rectangulo" # Puede ser "rectangulo", "triangulo" o "estrella"
var color_base = Color.WHITE
var tiempo_vida = 0.8
var tiempo_actual = 0.0

func iniciar(tipo: String, color: Color):
	forma = tipo
	color_base = color
	
	# Generamos 15 pedacitos que saldrán volando
	for i in range(15):
		particulas.append({
			"pos": Vector2(randf_range(-15, 15), randf_range(-15, 15)),
			"vel": Vector2(randf_range(-350, 350), randf_range(-500, -150)), # Explosión hacia arriba y a los lados
			"rot": randf_range(0, TAU),
			"vel_rot": randf_range(-15, 15),
			"escala": randf_range(0.4, 1.2)
		})

func _process(delta):
	tiempo_actual += delta
	if tiempo_actual >= tiempo_vida:
		queue_free()
		return
	
	# Físicas de las partículas (Gravedad y rotación)
	for p in particulas:
		p["pos"] += p["vel"] * delta
		p["vel"].y += 1200 * delta # Gravedad fuerte para que caigan con peso
		p["rot"] += p["vel_rot"] * delta
	
	queue_redraw()

func _draw():
	var alpha = 1.0 - (tiempo_actual / tiempo_vida)
	var c_base = color_base
	c_base.a = alpha
	var c_borde = Color(0, 0, 0, alpha) # Borde negro que se desvanece
	
	for p in particulas:
		draw_set_transform(p["pos"], p["rot"], Vector2(p["escala"], p["escala"]))
		
		var t = 14.0 # Tamaño de la pieza
		var b = 5.0 # Grosor del borde negro (Estilo Pin)
		
		if forma == "rectangulo":
			draw_rect(Rect2(-t/2, -t/2, t, t), c_borde)
			draw_rect(Rect2(-t/2 + b/2, -t/2 + b/2, t - b, t - b), c_base)
			
		elif forma == "triangulo":
			var pts_borde = PackedVector2Array([Vector2(0, -t), Vector2(t, t), Vector2(-t, t)])
			var pts_base = PackedVector2Array([Vector2(0, -t + b*1.5), Vector2(t - b*1.2, t - b), Vector2(-t + b*1.2, t - b)])
			draw_colored_polygon(pts_borde, c_borde)
			draw_colored_polygon(pts_base, c_base)
			
		elif forma == "estrella":
			var pts_borde = PackedVector2Array()
			var pts_base = PackedVector2Array()
			for i in range(10):
				var r = t if i % 2 == 0 else t / 2.0
				var a = i * TAU / 10.0 - PI/2
				pts_borde.append(Vector2(cos(a) * r, sin(a) * r))
				var r_int = r - (b * 0.8)
				pts_base.append(Vector2(cos(a) * r_int, sin(a) * r_int))
			draw_colored_polygon(pts_borde, c_borde)
			draw_colored_polygon(pts_base, c_base)
			
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
