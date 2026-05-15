extends Area2D

var tipo_fusion = ""
var dano_base = 10
var hits_restantes = 5 
var enemigos_golpeados = [] 

var direccion = Vector2.RIGHT
var velocidad = 500.0

var pixel_art = []

func lanzar(dir, tipo, color):
	direccion = dir
	tipo_fusion = tipo
	modulate = color # Aplica el color del diccionario automáticamente
	_definir_forma()

func _definir_forma():
	# Asignamos una forma visual única según la fusión
	match tipo_fusion:
		"fuego_hielo": # VAPOR (Nube densa)
			pixel_art = [
				"....BBBB....",
				"..BBCCCCBB..",
				".BCCCCCCCCB.",
				"BCCCCCCCCCCB",
				"BCCCCCCCCCCB",
				".BBCCCCCCBB.",
				"...BBBBBB..."
			]
		"fuego_rayo": # AURORA (Destello/Estrella)
			pixel_art = [
				"...B..B...",
				".B.BCCB.B.",
				"..BCCCCB..",
				"BBCCCCCCBB",
				"..BCCCCB..",
				".B.BCCB.B.",
				"...B..B..."
			]
		"fuego_veneno": # TOXINA (Gota inestable)
			pixel_art = [
				"....BB....",
				"...BCCB...",
				"..BCCCCB..",
				".BCCCCCCB.",
				"BCCCCCCCCB",
				"BCCCCCCCCB",
				".BBBBBBBB."
			]
		"hielo_rayo": # PLASMA (Shuriken filoso)
			pixel_art = [
				"....BB....",
				"...BCCB...",
				"..BCCCCB..",
				".BCCCCCCB.",
				"BBCCCCCCBB",
				".BCCCCCCB.",
				"..BCCCCB..",
				"...BCCB...",
				"....BB...."
			]
		"hielo_veneno": # DEGRADACIÓN (Fragmento corrosivo roto)
			pixel_art = [
				"...BB...",
				"..BCCB..",
				".BCCCCBB",
				"BBCCCCCB",
				"BCCCCCBB",
				"BBCCCB..",
				".BCCB...",
				"..BB...."
			]
		"rayo_veneno": # CONDUCTOR (Rayo/Chispa errática)
			pixel_art = [
				"....BB....",
				"...BCCB...",
				"..BCCCCB..",
				".BCCCCBB..",
				"..BBCCCCB.",
				"...BCCCCB.",
				"....BCCB..",
				".....BB..."
			]
		_: # Forma por defecto por si acaso
			pixel_art = [
				".BB.",
				"BCCB",
				"BCCB",
				".BB."
			]

func _physics_process(delta):
	position += direccion * velocidad * delta

func _on_area_entered(area):
	if hits_restantes <= 0: return
	
	if area.name == "Hurtbox":
		var enemigo = area.get_parent()
		
		if enemigo in enemigos_golpeados: return
		enemigos_golpeados.append(enemigo)
		
		if enemigo.has_method("recibir_daño"):
			aplicar_logica_tabla(enemigo)
			hits_restantes -= 1
			_gestionar_persistencia()

func aplicar_logica_tabla(enemigo):
	match tipo_fusion:
		"fuego_hielo": # VAPOR
			enemigo.recibir_daño(10)
			enemigo.aplicar_estado("detener", 10.0)
		"fuego_rayo": # AURORA
			enemigo.recibir_daño(10)
			enemigo.aplicar_estado("ralentizar", 2.0, 0.5)
		"fuego_veneno": # TOXINA
			enemigo.recibir_daño(10)
			enemigo.aplicar_estado("envenenar", 10.0, 10)
		"hielo_rayo": # PLASMA
			enemigo.aplicar_estado("detener", 10.0)
			_rebotar()
		"hielo_veneno": # DEGRADACIÓN
			enemigo.aplicar_estado("detener", 10.0)
			enemigo.aplicar_estado("envenenar", 10.0, 10)
		"rayo_veneno": # CONDUCTOR
			enemigo.aplicar_estado("ralentizar", 10.0, 0.5)
			enemigo.aplicar_estado("envenenar", 10.0, 10)
			_rebotar()

func _gestionar_persistencia():
	var es_rebote = ["hielo_rayo", "rayo_veneno"]
	var es_atraviesa = ["fuego_hielo", "fuego_rayo", "fuego_veneno"]
	
	if hits_restantes <= 0:
		queue_free()
	elif not tipo_fusion in es_atraviesa and not tipo_fusion in es_rebote:
		queue_free()

func _rebotar():
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	var mejor_objetivo = null
	var distancia_minima = 1000.0
	
	for e in enemigos:
		if e in enemigos_golpeados: continue
		var dist = global_position.distance_to(e.global_position)
		if dist < distancia_minima:
			distancia_minima = dist
			mejor_objetivo = e
			
	if mejor_objetivo:
		direccion = global_position.direction_to(mejor_objetivo.global_position)
	else:
		direccion = direccion.rotated(randf_range(1.0, 2.0))

# --- SISTEMA DE DIBUJO ---
func _process(_delta):
	queue_redraw()

func _draw():
	if pixel_art.is_empty(): return
	
	var pixel_size = 5.0 # Ajusta esto si quieres balas más grandes o pequeñas
	var offset_x = -(pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = -(pixel_art.size() * pixel_size) / 2.0
	
	# Rotamos la bala para que apunte hacia donde se mueve
	draw_set_transform(Vector2.ZERO, direccion.angle(), Vector2.ONE)
	
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK
				"C": color = Color.WHITE # El blanco se teñirá con el modulate
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)
