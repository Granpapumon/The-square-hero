extends Area2D

var velocidad = 800
var porcentaje_ralentizacion = 0.60
var tiempo_efecto = 1.0
var tiempo = 0.0
var impactado = false

# Relámpago Pixel Art (Diseño Vertical)
var pixel_art = [
	".....BBB......",
	"....BCMEB.....",
	"...BCMMEB.....",
	"..BCMMMEB.....",
	".BCMMMMEB.....",
	"BCMMMMEB......",
	"BCCEEEEBBBBB..",
	".BCCCCCCCMMEB.",
	"..BBBBBBCCMMEB",
	".......BCMMEB.",
	"......BCMMEB..",
	".....BCMMEB...",
	"....BCMMEB....",
	"...BCMMEB.....",
	"..BCMMEB......",
	".BCMMEB.......",
	"BCCEEBBBBB....",
	".BCCCCCMMEB...",
	"..BBBBCCMMEB..",
	".....BCMMEB...",
	"....BCMMEB....",
	"...BCMMEB.....",
	"..BCMMEB......",
	".BCEEB........",
	".BEB..........",
	"..B..........."
]

func lanzar(_dir):
	# Ahora sí, rotación en 0 para que caiga verticalmente
	rotation = 0

func _process(delta):
	if impactado:
		return
		
	tiempo += delta
	global_position.y += velocidad * delta
	queue_redraw()
	
	# AUTODESTRUCCIÓN: Si falla y no toca a nadie, se borra después de 1.5 seg
	if tiempo > 1.5:
		queue_free()

func _draw():
	if impactado: return
	
	var pixel_size = 3.5
	var offset_x = - (pixel_art[0].length() * pixel_size) / 2.0
	var offset_y = - (pixel_art.size() * pixel_size) / 2.0
	
	for y in range(pixel_art.size()):
		var row = pixel_art[y]
		for x in range(row.length()):
			var letra = row[x]
			if letra == ".": continue
			
			var color = Color.TRANSPARENT
			match letra:
				"B": color = Color.BLACK
				"E": color = Color(0.8, 0.5, 0.0) # Naranja Oscuro
				"M": color = Color(1.0, 0.9, 0.0) # Amarillo Eléctrico
				"C": color = Color(1.0, 1.0, 1.0) # Rayo Blanco
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	# ¡LA SOLUCIÓN! Dejamos esto vacío. 
	# Evitamos que el notificador lo borre al nacer en el cielo.
	pass

func _on_area_entered(area: Area2D) -> void:
	if impactado:
		return
		
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
		
	if enemigo.has_method("ralentizar"):
		enemigo.ralentizar(porcentaje_ralentizacion, tiempo_efecto)
		
	_explotar()

# --- EXPLOSIÓN ESTÁTICA (Chispas) ---
func _explotar():
	impactado = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Borramos el dibujo del rayo principal
	queue_redraw()
	
	# Creamos un estallido de chispas eléctricas súper rápidas
	var chispas = CPUParticles2D.new()
	chispas.emitting = false
	chispas.one_shot = true
	chispas.explosiveness = 1.0 
	chispas.amount = 40
	chispas.lifetime = 0.5 
	chispas.spread = 180.0
	chispas.initial_velocity_min = 200.0
	chispas.initial_velocity_max = 500.0 
	chispas.scale_amount_min = 1.0
	chispas.scale_amount_max = 5.0
	
	var grad_chispa = Gradient.new()
	grad_chispa.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad_chispa.set_color(1, Color(1.0, 1.0, 0.0, 0.0))
	chispas.color_ramp = grad_chispa
	
	add_child(chispas)
	chispas.emitting = true
	
	await get_tree().create_timer(0.3).timeout
	queue_free()
