extends Node2D

func iniciar(cantidad: int, critico: bool = false):
	# 1. Configuración del texto (Mantenemos tu estilo estético)
	var label = Label.new()
	label.text = str(cantidad)
	label.add_theme_font_size_override("font_size", 40 if not critico else 55)
	label.add_theme_color_override("font_color", Color(1, 0.2, 0.2) if not critico else Color(1, 0.8, 0))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 14)
	# Centramos el texto
	label.position = Vector2(-20, -20) 
	add_child(label)
	
	# 2. ANIMACIÓN PRO CON TWEENS (Reemplaza al _process)
	scale = Vector2.ZERO # Empieza invisible
	var tween = create_tween()
	tween.set_parallel(true) # Ejecuta múltiples animaciones al mismo tiempo
	
	# Efecto Pop-up (Crece y rebota un poco)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1) # Vuelve al tamaño normal
	
	# Movimiento en Arco (Sube y luego cae a los lados)
	var dir_x = randf_range(-40.0, 40.0) # Salta a la izquierda o derecha aleatoriamente
	tween.parallel().tween_property(self, "position", position + Vector2(dir_x, -60), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position:y", position.y - 30, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN) # Gravedad
	
	# Desvanecimiento y eliminación
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3).set_delay(0.4)
	tween.chain().tween_callback(queue_free)
