extends Area2D

var dano = 0
var velocidad = 500
var dano_veneno = 2
var direccion_vector = Vector2.ZERO
var tiempo = 0.0
var impactado = false
var rastro_veneno: CPUParticles2D

# Gota Ácida Pixel Art
var pixel_art = [
	"........BBB.....",
	"......BBECEB....",
	".....BEMCCCEB...",
	"....BEMCCCCCEB..",
	"...BEMCCCCCCCEB.",
	"..BEMCCCCCCCCMB.",
	".BEMCCCCCCCCCMB.",
	"BEMCCCCCCCCCCMB.",
	"BEMCCCCCCCCCCMEB",
	"BEMCCCCCCCCCCMEB",
	".BEEMCCCCCCCMEB.",
	"..BEEMMCCCCMEB..",
	"...BEEEMMMEEEB..",
	".....BBBBBBBB..."
]

func _ready():
	# --- ESTELA DE GOTAS TÓXICAS ---
	rastro_veneno = CPUParticles2D.new()
	rastro_veneno.amount = 100 
	rastro_veneno.lifetime = 1.0 
	
	# Gravedad hacia abajo para que parezca que el veneno escurre y cae al piso
	rastro_veneno.gravity = Vector2(0, 80) 
	
	rastro_veneno.direction = Vector2(-1, 0)
	rastro_veneno.spread = 15.0 
	rastro_veneno.initial_velocity_min = 10.0
	rastro_veneno.initial_velocity_max = 30.0
	rastro_veneno.scale_amount_min = 6.0
	rastro_veneno.scale_amount_max = 10.0
	
	# Gradiente: De verde ácido brillante a verde oscuro transparente
	var gradiente = Gradient.new()
	gradiente.set_color(0, Color(0.4, 1.0, 0.2, 0.8)) 
	gradiente.set_color(1, Color(0.1, 0.5, 0.0, 0.0)) 
	rastro_veneno.color_ramp = gradiente
	
	rastro_veneno.z_index = -1
	add_child(rastro_veneno)

func lanzar(dir):
	direccion_vector = dir
	# Hacemos que la gota gire para apuntar siempre en la dirección en la que viaja
	rotation = dir.angle()

func _process(delta):
	if impactado:
		return
		
	tiempo += delta
	# Movimiento ondulante perpendicular a la dirección
	var perp = Vector2(-direccion_vector.y, direccion_vector.x)
	global_position += direccion_vector * velocidad * delta
	global_position += perp * sin(tiempo * 15) * 2
	
	# Pulsación gelatinosa (se infla y desinfla rápido)
	scale = Vector2.ONE * (1.0 + sin(tiempo * 30) * 0.15)
	
	queue_redraw()

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
				"E": color = Color(0.1, 0.5, 0.1) # Verde Pantano
				"M": color = Color(0.4, 0.9, 0.1) # Verde Ácido
				"C": color = Color(0.8, 1.0, 0.4) # Brillo Toxico
			
			draw_rect(Rect2(offset_x + (x * pixel_size), offset_y + (y * pixel_size), pixel_size, pixel_size), color)

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impactado:
		return
		
	var enemigo = area.get_parent()
	if not is_instance_valid(enemigo) or not enemigo.is_in_group("enemigos"):
		return
		
	if enemigo.has_method("envenenar"):
		enemigo.envenenar(dano_veneno)
		
	_explotar()

# --- EXPLOSIÓN DE ÁCIDO (Salpicadura) ---
func _explotar():
	impactado = true
	$CollisionShape2D.set_deferred("disabled", true)
	
	if is_instance_valid(rastro_veneno):
		rastro_veneno.emitting = false
		
	queue_redraw()
	
	# Creamos una salpicadura de ácido en todas direcciones
	var splash = CPUParticles2D.new()
	splash.emitting = false
	splash.one_shot = true
	splash.explosiveness = 0.9 # Explota casi de golpe
	splash.amount = 30
	splash.lifetime = 0.9
	splash.spread = 180.0
	splash.initial_velocity_min = 50.0
	splash.initial_velocity_max = 160.0 # Salpica lejos
	splash.scale_amount_min = 2.0
	splash.scale_amount_max = 6.0
	
	# El líquido salpicado cae al suelo
	splash.gravity = Vector2(0, 200)
	
	var grad_splash = Gradient.new()
	grad_splash.set_color(0, Color(0.4, 1.0, 0.2, 1.0))
	grad_splash.set_color(1, Color(0.1, 0.5, 0.0, 0.0))
	splash.color_ramp = grad_splash
	
	add_child(splash)
	splash.emitting = true
	
	await get_tree().create_timer(0.5).timeout
	queue_free()
